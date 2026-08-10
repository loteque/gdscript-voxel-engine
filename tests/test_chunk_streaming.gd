extends SceneTree

const TERRAIN_CHUNK_ASSET := preload("res://voxel/chunking/TerrainChunkAsset.gd")
const TERRAIN_CHUNK_MANIFEST := preload("res://voxel/chunking/TerrainChunkManifest.gd")
const TERRAIN_CHUNK_MANIFEST_ENTRY := preload("res://voxel/chunking/TerrainChunkManifestEntry.gd")
const CHUNK_STREAMER := preload("res://voxel/chunking/ChunkStreamer.gd")

const VALID_ASSET_PATH := "user://chunk_streaming_valid.tres"
const BROKEN_ASSET_PATH := "user://chunk_streaming_broken.tres"

var _failed: bool = false


func _initialize() -> void:
	_test_manifest_lookup_contract()
	_test_load_duplicate_unload_and_reload()
	_test_missing_and_broken_assets_fail_cleanly()
	_test_runtime_streamer_does_not_depend_on_generation()
	_cleanup_fixture_files()

	if _failed:
		quit(1)
	else:
		print("Chunk streaming tests passed.")
		quit(0)


func _test_manifest_lookup_contract() -> void:
	var manifest := _make_manifest(Vector3i(3, -2, 7), VALID_ASSET_PATH)
	_assert_true(
		manifest.find_entry(Vector3i(3, -2, 7)) != null,
		"Manifest lookup must resolve exact Vector3i chunk coordinates."
	)
	_assert_true(
		manifest.find_entry(Vector3i(3, -2, 8)) == null,
		"Manifest lookup must return null for missing chunk coordinates."
	)


func _test_load_duplicate_unload_and_reload() -> void:
	var coordinate := Vector3i(3, -2, 7)
	var asset := _make_valid_asset(coordinate)
	_assert_true(ResourceSaver.save(asset, VALID_ASSET_PATH) == OK, "Streaming fixture asset must save.")

	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = _make_manifest(coordinate, VALID_ASSET_PATH)
	get_root().add_child(streamer)

	_assert_true(streamer.load_chunk(coordinate) == OK, "Valid baked chunk must load.")
	_assert_true(streamer.is_chunk_loaded(coordinate), "Loaded state must become observable.")
	_assert_true(streamer.get_child_count() == 1, "One load must create one MeshInstance3D.")

	var first_instance := streamer.get_chunk_instance(coordinate)
	_assert_true(first_instance != null, "Loaded chunk must expose its resident instance.")
	if first_instance != null:
		_assert_true(
			first_instance.mesh != null and first_instance.mesh.get_surface_count() == 1,
			"Streamer must display the mesh contained by the serialized chunk asset."
		)
		_assert_true(
			first_instance.position.is_equal_approx(asset.local_origin),
			"Streamer must preserve baked terrain-local placement."
		)

	_assert_true(streamer.load_chunk(coordinate) == OK, "Duplicate loads must be idempotent.")
	_assert_true(streamer.get_child_count() == 1, "Duplicate loads must not create duplicate instances.")

	_assert_true(streamer.unload_chunk(coordinate), "Loaded chunk must unload.")
	_assert_true(not streamer.is_chunk_loaded(coordinate), "Unload must clear residency state immediately.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Reload after unload must succeed.")
	_assert_true(streamer.is_chunk_loaded(coordinate), "Reload must restore residency state.")

	streamer.clear_chunks()
	streamer.queue_free()


func _test_missing_and_broken_assets_fail_cleanly() -> void:
	var missing_coordinate := Vector3i(9, 0, 0)
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = _make_manifest(Vector3i.ZERO, VALID_ASSET_PATH)
	get_root().add_child(streamer)

	_assert_true(
		streamer.load_chunk(missing_coordinate) != OK,
		"Missing manifest coordinates must fail without creating instances."
	)
	_assert_true(not streamer.is_chunk_loaded(missing_coordinate), "Failed loads must not become resident.")

	var generic_resource := Resource.new()
	_assert_true(
		ResourceSaver.save(generic_resource, BROKEN_ASSET_PATH) == OK,
		"Broken-type fixture must serialize."
	)
	var broken_coordinate := Vector3i(10, 0, 0)
	streamer.manifest = _make_manifest(broken_coordinate, BROKEN_ASSET_PATH)
	_assert_true(
		streamer.load_chunk(broken_coordinate) != OK,
		"Non-TerrainChunkAsset resources must fail cleanly."
	)
	_assert_true(streamer.get_child_count() == 0, "Failed asset loads must not create scene nodes.")
	streamer.queue_free()


func _test_runtime_streamer_does_not_depend_on_generation() -> void:
	var file := FileAccess.open("res://voxel/chunking/ChunkStreamer.gd", FileAccess.READ)
	_assert_true(file != null, "ChunkStreamer source must be readable for architecture guard.")
	if file == null:
		return

	var source := file.get_as_text()
	file.close()
	_assert_true(
		not source.contains("PointFieldResource"),
		"Runtime streaming must not depend on PointFieldResource generation."
	)
	_assert_true(
		not source.contains("SurfaceNetsMesher"),
		"Runtime streaming must not invoke Surface Nets."
	)
	_assert_true(
		not source.contains("generate_mesh("),
		"Runtime streaming must not regenerate meshes."
	)


func _make_manifest(coordinate: Vector3i, asset_path: String) -> TerrainChunkManifest:
	var entry := TERRAIN_CHUNK_MANIFEST_ENTRY.new()
	entry.chunk_coordinate = coordinate
	entry.lod_level = 0
	entry.asset_path = asset_path
	entry.bounds = AABB(Vector3(coordinate) * 4.0, Vector3(4.0, 4.0, 4.0))

	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	manifest.set_entry(entry)
	return manifest


func _make_valid_asset(coordinate: Vector3i) -> TerrainChunkAsset:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Vector3(0.0, 1.0, 0.0),
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var asset := TERRAIN_CHUNK_ASSET.new()
	asset.chunk_coordinate = coordinate
	asset.lod_level = 0
	asset.local_origin = Vector3(12.0, -8.0, 28.0)
	asset.cell_dimensions = Vector3i(4, 4, 4)
	asset.sample_spacing = 1.0
	asset.mesh = mesh
	asset.bounds = AABB(asset.local_origin, Vector3(4.0, 4.0, 4.0))
	return asset


func _cleanup_fixture_files() -> void:
	for path in [VALID_ASSET_PATH, BROKEN_ASSET_PATH]:
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute_path)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
