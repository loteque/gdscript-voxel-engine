extends SceneTree

const TERRAIN_CHUNK_ASSET := preload("res://voxel/chunking/TerrainChunkAsset.gd")
const TERRAIN_CHUNK_MANIFEST := preload("res://voxel/chunking/TerrainChunkManifest.gd")
const TERRAIN_CHUNK_MANIFEST_ENTRY := preload("res://voxel/chunking/TerrainChunkManifestEntry.gd")
const CHUNK_STREAMER := preload("res://voxel/chunking/ChunkStreamer.gd")

const VALID_ASSET_PATH := "user://chunk_streaming_valid.tres"
const SECOND_ASSET_PATH := "user://chunk_streaming_second.tres"
const BROKEN_ASSET_PATH := "user://chunk_streaming_broken.tres"

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_manifest_lookup_contract()
	_test_position_to_chunk_coordinate()
	await _test_request_lifecycle_and_successful_completion()
	await _test_duplicate_requests_are_idempotent()
	await _test_unload_cancels_pending_load()
	await _test_failed_load_does_not_poison_state()
	await _test_residency_updates_while_pending()
	await _test_residency_radius_one()
	_test_runtime_streamer_does_not_depend_on_generation()
	_cleanup_fixture_files()
	quit(1 if _failed else 0)
	if not _failed:
		print("Chunk streaming tests passed.")


func _test_manifest_lookup_contract() -> void:
	var manifest := _make_manifest(Vector3i(3, -2, 7), VALID_ASSET_PATH)
	_assert_true(manifest.find_entry(Vector3i(3, -2, 7)) != null, "Manifest lookup must resolve exact Vector3i chunk coordinates.")
	_assert_true(manifest.find_entry(Vector3i(3, -2, 8)) == null, "Manifest lookup must return null for missing chunk coordinates.")


func _test_position_to_chunk_coordinate() -> void:
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = TERRAIN_CHUNK_MANIFEST.new()
	streamer.manifest.chunk_cell_dimensions = Vector3i(4, 2, 8)
	streamer.manifest.sample_spacing = 2.0
	_assert_equal(streamer.position_to_chunk_coordinate(Vector3(7.99, 3.99, 15.99)), Vector3i.ZERO, "Positions below positive non-cubic boundaries must remain in chunk zero.")
	_assert_equal(streamer.position_to_chunk_coordinate(Vector3(8.0, 4.0, 16.0)), Vector3i.ONE, "Positions exactly on chunk boundaries must enter the next chunk.")
	_assert_equal(streamer.position_to_chunk_coordinate(Vector3(-0.01, -0.01, -0.01)), Vector3i(-1, -1, -1), "Negative positions must use floor conversion instead of truncation.")
	streamer.free()


func _test_request_lifecycle_and_successful_completion() -> void:
	var coordinate := Vector3i(3, -2, 7)
	_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), VALID_ASSET_PATH) == OK, "Streaming fixture asset must save.")
	var streamer := _make_streamer(_make_manifest(coordinate, VALID_ASSET_PATH))
	var start_count := 0
	streamer.chunk_load_started.connect(func(_coordinate: Vector3i) -> void: start_count += 1)

	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.UNLOADED, "Chunks must begin unloaded.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Valid baked chunk request must be accepted.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.QUEUED, "Accepted requests must enter queued state before I/O starts.")
	streamer._process(0.0)
	_assert_equal(start_count, 1, "Each accepted request must start threaded loading exactly once.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.LOADING, "The execution stage must advance queued requests to loading.")
	_assert_true(await _wait_for_idle(streamer), "Threaded loading must complete within the test frame budget.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.RESIDENT, "Successful threaded loads must become resident.")
	_assert_true(streamer.get_chunk_instance(coordinate) != null, "Resident state must own a MeshInstance3D.")
	streamer.clear_chunks()
	streamer.queue_free()
	await process_frame


func _test_duplicate_requests_are_idempotent() -> void:
	var coordinate := Vector3i.ZERO
	_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), VALID_ASSET_PATH) == OK, "Duplicate-request fixture must save.")
	var streamer := _make_streamer(_make_manifest(coordinate, VALID_ASSET_PATH))
	_assert_true(streamer.load_chunk(coordinate) == OK, "First request must be accepted.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Duplicate pending request must remain idempotent.")
	_assert_equal(streamer.get_pending_coordinates(), [coordinate], "Duplicate requests must not duplicate queued work.")
	_assert_true(await _wait_for_idle(streamer), "Duplicate-request fixture must finish loading.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Duplicate resident request must remain idempotent.")
	_assert_equal(streamer.get_loaded_coordinates(), [coordinate], "Duplicate resident requests must not duplicate instances.")
	streamer.clear_chunks()
	streamer.queue_free()
	await process_frame


func _test_unload_cancels_pending_load() -> void:
	var coordinate := Vector3i(1, 0, 0)
	_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), VALID_ASSET_PATH) == OK, "Cancellation fixture must save.")
	var streamer := _make_streamer(_make_manifest(coordinate, VALID_ASSET_PATH))
	_assert_true(streamer.load_chunk(coordinate) == OK, "Cancellation request must be accepted.")
	streamer._process(0.0)
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.LOADING, "Cancellation test must reach loading state before cancellation.")
	_assert_true(streamer.unload_chunk(coordinate), "Unloading a pending chunk must logically cancel its request.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.UNLOADED, "Cancelled pending chunks must immediately return to unloaded state.")
	for _frame in range(4):
		streamer._process(0.0)
		await process_frame
	_assert_true(not streamer.is_chunk_loaded(coordinate), "Cancelled threaded results must never create resident instances.")
	streamer.queue_free()
	await process_frame


func _test_failed_load_does_not_poison_state() -> void:
	var coordinate := Vector3i(2, 0, 0)
	var generic_resource := Resource.new()
	_assert_true(ResourceSaver.save(generic_resource, BROKEN_ASSET_PATH) == OK, "Broken fixture must serialize.")
	var streamer := _make_streamer(_make_manifest(coordinate, BROKEN_ASSET_PATH))
	var failures: Array[Error] = []
	streamer.chunk_load_failed.connect(func(_coordinate: Vector3i, error: Error) -> void: failures.append(error))
	_assert_true(streamer.load_chunk(coordinate) == OK, "Existing but invalid resource should enter asynchronous loading.")
	_assert_true(await _wait_for_idle(streamer), "Failed threaded loads must leave pending state.")
	_assert_true(not streamer.is_chunk_loaded(coordinate), "Invalid resources must never become resident.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.UNLOADED, "Failed loads must return to unloaded state so future requests remain possible.")
	_assert_true(not failures.is_empty(), "Failed asynchronous loads must emit chunk_load_failed.")
	streamer.manifest = _make_manifest(coordinate, "user://missing_chunk_asset.tres")
	_assert_true(streamer.load_chunk(coordinate) != OK, "Missing asset paths must fail before queueing work.")
	_assert_true(not streamer.is_chunk_pending(coordinate), "Immediate request failures must not poison pending state.")
	streamer.queue_free()
	await process_frame


func _test_residency_updates_while_pending() -> void:
	var first := Vector3i.ZERO
	var second := Vector3i(1, 0, 0)
	_assert_true(ResourceSaver.save(_make_valid_asset(first), VALID_ASSET_PATH) == OK, "First residency fixture must save.")
	_assert_true(ResourceSaver.save(_make_valid_asset(second), SECOND_ASSET_PATH) == OK, "Second residency fixture must save.")
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	manifest.set_entry(_make_entry(first, VALID_ASSET_PATH))
	manifest.set_entry(_make_entry(second, SECOND_ASSET_PATH))
	var streamer := _make_streamer(manifest)
	streamer.residency_radius = 0
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	_assert_equal(streamer.get_pending_coordinates(), [first], "Initial residency must queue the first target chunk.")
	streamer._process(0.0)
	streamer.update_residency(Vector3(4.5, 0.5, 0.5))
	_assert_true(not streamer.is_chunk_pending(first), "Pending chunks that stop being desired must be cancelled.")
	_assert_true(not streamer.is_chunk_loaded(first), "Obsolete pending chunks must not become resident.")
	_assert_equal(streamer.get_pending_coordinates(), [second], "New desired chunk must replace obsolete pending work.")
	_assert_true(await _wait_for_idle(streamer), "Updated residency request must complete.")
	_assert_equal(streamer.get_loaded_coordinates(), [second], "Only the latest desired chunk must become resident.")
	streamer.clear_chunks()
	streamer.queue_free()
	await process_frame


func _test_residency_radius_one() -> void:
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	for z in range(-1, 2):
		for x in range(-1, 2):
			var coordinate := Vector3i(x, 0, z)
			var path := "user://chunk_streaming_radius_%d_%d.tres" % [x, z]
			_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), path) == OK, "Radius fixture must save.")
			manifest.set_entry(_make_entry(coordinate, path))
	var streamer := _make_streamer(manifest)
	streamer.residency_radius = 1
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	_assert_equal(streamer.get_pending_coordinates().size(), 9, "Radius-one sparse manifest must queue the available 3 x 1 x 3 neighborhood.")
	_assert_true(await _wait_for_idle(streamer), "Radius-one asynchronous residency must settle.")
	_assert_equal(streamer.get_loaded_coordinates().size(), 9, "Radius-one residency must preserve the complete available neighborhood.")
	streamer.clear_chunks()
	streamer.queue_free()
	await process_frame


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
	_assert_true(source.contains("load_threaded_request"), "Runtime streaming must use Godot threaded resource loading.")
	_assert_true(not source.contains("Thread.new"), "Runtime streaming must not introduce custom threads.")


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 120) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		if streamer.get_pending_coordinates().is_empty():
			return true
		await process_frame
	return streamer.get_pending_coordinates().is_empty()


func _make_streamer(manifest: TerrainChunkManifest) -> ChunkStreamer:
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = manifest
	get_root().add_child(streamer)
	return streamer


func _make_manifest(coordinate: Vector3i, asset_path: String) -> TerrainChunkManifest:
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	manifest.set_entry(_make_entry(coordinate, asset_path))
	return manifest


func _make_entry(coordinate: Vector3i, asset_path: String) -> TerrainChunkManifestEntry:
	var entry := TERRAIN_CHUNK_MANIFEST_ENTRY.new()
	entry.chunk_coordinate = coordinate
	entry.asset_path = asset_path
	entry.bounds = AABB(Vector3(coordinate) * 4.0, Vector3(4.0, 4.0, 4.0))
	return entry


func _make_valid_asset(coordinate: Vector3i) -> TerrainChunkAsset:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var asset := TERRAIN_CHUNK_ASSET.new()
	asset.chunk_coordinate = coordinate
	asset.local_origin = Vector3(coordinate) * 4.0 + Vector3.ONE * 2.0
	asset.cell_dimensions = Vector3i(4, 4, 4)
	asset.sample_spacing = 1.0
	asset.mesh = mesh
	asset.bounds = AABB(Vector3(coordinate) * 4.0, Vector3(4.0, 4.0, 4.0))
	return asset


func _cleanup_fixture_files() -> void:
	var directory := DirAccess.open("user://")
	if directory == null:
		return
	for filename in directory.get_files():
		if filename.begins_with("chunk_streaming_"):
			directory.remove(filename)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])
