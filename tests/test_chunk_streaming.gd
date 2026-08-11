extends SceneTree

const TERRAIN_CHUNK_ASSET := preload("res://voxel/chunking/TerrainChunkAsset.gd")
const TERRAIN_CHUNK_MANIFEST := preload("res://voxel/chunking/TerrainChunkManifest.gd")
const TERRAIN_CHUNK_MANIFEST_ENTRY := preload("res://voxel/chunking/TerrainChunkManifestEntry.gd")
const CHUNK_STREAMER := preload("res://voxel/chunking/ChunkStreamer.gd")
const STREAMING_DEMO_FIXTURE_BAKER := preload("res://demo/tools/StreamingDemoFixtureBaker.gd")

const VALID_ASSET_PATH := "user://chunk_streaming_valid.tres"
const BROKEN_ASSET_PATH := "user://chunk_streaming_broken.tres"
const DEMO_MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const DEMO_SCENE_PATH := "res://demo/ChunkStreamingValidationDemo.tscn"

var _failed: bool = false


func _initialize() -> void:
	_test_manifest_lookup_contract()
	_test_load_duplicate_unload_and_reload()
	_test_missing_and_broken_assets_fail_cleanly()
	_test_runtime_streamer_does_not_depend_on_generation()
	_test_noise_baked_demo_fixture()
	_cleanup_fixture_files()
	quit(1 if _failed else 0)
	if not _failed:
		print("Chunk streaming tests passed.")


func _test_manifest_lookup_contract() -> void:
	var manifest := _make_manifest(Vector3i(3, -2, 7), VALID_ASSET_PATH)
	_assert_true(manifest.find_entry(Vector3i(3, -2, 7)) != null, "Manifest lookup must resolve exact Vector3i chunk coordinates.")
	_assert_true(manifest.find_entry(Vector3i(3, -2, 8)) == null, "Manifest lookup must return null for missing chunk coordinates.")


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
	_assert_true(streamer.load_chunk(coordinate) == OK, "Duplicate loads must be idempotent.")
	_assert_true(streamer.get_child_count() == 1, "Duplicate loads must not create duplicate instances.")
	_assert_true(streamer.unload_chunk(coordinate), "Loaded chunk must unload.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Reload after unload must succeed.")
	streamer.clear_chunks()
	streamer.queue_free()


func _test_missing_and_broken_assets_fail_cleanly() -> void:
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = _make_manifest(Vector3i.ZERO, VALID_ASSET_PATH)
	get_root().add_child(streamer)
	_assert_true(streamer.load_chunk(Vector3i(9, 0, 0)) != OK, "Missing manifest coordinates must fail cleanly.")
	var generic_resource := Resource.new()
	_assert_true(ResourceSaver.save(generic_resource, BROKEN_ASSET_PATH) == OK, "Broken fixture must serialize.")
	streamer.manifest = _make_manifest(Vector3i(10, 0, 0), BROKEN_ASSET_PATH)
	_assert_true(streamer.load_chunk(Vector3i(10, 0, 0)) != OK, "Wrong resource types must fail cleanly.")
	streamer.queue_free()


func _test_runtime_streamer_does_not_depend_on_generation() -> void:
	var file := FileAccess.open("res://voxel/chunking/ChunkStreamer.gd", FileAccess.READ)
	_assert_true(file != null, "ChunkStreamer source must be readable for architecture guard.")
	if file == null:
		return
	var source := file.get_as_text()
	file.close()
	_assert_true(not source.contains("PointFieldResource"), "Runtime streaming must not depend on PointFieldResource generation.")
	_assert_true(not source.contains("SurfaceNetsMesher"), "Runtime streaming must not invoke Surface Nets.")
	_assert_true(not source.contains("generate_mesh("), "Runtime streaming must not regenerate meshes.")


func _test_noise_baked_demo_fixture() -> void:
	var fixture_baker := STREAMING_DEMO_FIXTURE_BAKER.new()
	_assert_true(fixture_baker.bake() == OK, "Streaming fixture must bake deterministically from noise.")
	var manifest := ResourceLoader.load(DEMO_MANIFEST_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as TerrainChunkManifest
	_assert_true(manifest != null and manifest.is_valid(), "Streaming demo must produce a valid manifest.")
	if manifest == null:
		return
	_assert_true(manifest.chunk_cell_dimensions == STREAMING_DEMO_FIXTURE_BAKER.CELL_DIMENSIONS, "Manifest must describe the noise-baked chunk geometry.")
	var entry := manifest.find_entry(Vector3i.ZERO)
	_assert_true(entry != null, "Noise-baked manifest must contain chunk (0, 0, 0).")
	if entry == null:
		return
	var asset := ResourceLoader.load(entry.asset_path, "", ResourceLoader.CACHE_MODE_REPLACE) as TerrainChunkAsset
	_assert_true(asset != null and asset.is_valid(), "Manifest must resolve a valid baked terrain asset.")
	if asset != null:
		_assert_true(asset.mesh != null and asset.mesh.get_surface_count() > 0, "Baked terrain must contain Surface Nets geometry.")
		_assert_true(asset.mesh.get_faces().size() > 24, "Streaming fixture must be terrain rather than the previous toy box mesh.")
	var packed_scene := ResourceLoader.load(DEMO_SCENE_PATH) as PackedScene
	_assert_true(packed_scene != null, "Streaming validation scene must load.")
	if packed_scene != null:
		var demo := packed_scene.instantiate()
		_assert_true(demo.manifest_path == DEMO_MANIFEST_PATH, "Streaming demo must point at the generated terrain manifest.")
		demo.free()
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = manifest
	get_root().add_child(streamer)
	_assert_true(streamer.load_chunk(Vector3i.ZERO) == OK, "Noise-baked terrain must load through ChunkStreamer.")
	_assert_true(streamer.is_chunk_loaded(Vector3i.ZERO), "Noise-baked terrain chunk must become resident.")
	streamer.clear_chunks()
	streamer.queue_free()


func _make_manifest(coordinate: Vector3i, asset_path: String) -> TerrainChunkManifest:
	var entry := TERRAIN_CHUNK_MANIFEST_ENTRY.new()
	entry.chunk_coordinate = coordinate
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
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var asset := TERRAIN_CHUNK_ASSET.new()
	asset.chunk_coordinate = coordinate
	asset.local_origin = Vector3(12.0, -8.0, 28.0)
	asset.cell_dimensions = Vector3i(4, 4, 4)
	asset.sample_spacing = 1.0
	asset.mesh = mesh
	asset.bounds = AABB(asset.local_origin, Vector3(4.0, 4.0, 4.0))
	return asset


func _cleanup_fixture_files() -> void:
	for path in [VALID_ASSET_PATH, BROKEN_ASSET_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
