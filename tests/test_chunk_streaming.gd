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
	await _test_nearest_chunks_start_first_with_frame_budget()
	await _test_priority_ties_are_deterministic()
	await _test_concurrent_loading_budget()
	await _test_freed_capacity_is_reused()
	await _test_duplicate_requests_are_idempotent()
	await _test_unload_removes_queued_request()
	await _test_unload_cancels_loading_request()
	await _test_failed_load_frees_capacity()
	await _test_residency_updates_while_pending()
	await _test_sparse_manifest_residency()
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

	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.UNLOADED, "Chunks must begin unloaded.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Valid baked chunk request must be accepted.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.QUEUED, "Accepted requests must enter queued state before I/O starts.")
	streamer._process(0.0)
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.LOADING, "The execution stage must advance queued requests to loading.")
	_assert_true(await _wait_for_idle(streamer), "Threaded loading must complete within the test frame budget.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.RESIDENT, "Successful threaded loads must become resident.")
	_assert_true(streamer.get_chunk_instance(coordinate) != null, "Resident state must own a MeshInstance3D.")
	await _dispose_streamer(streamer)


func _test_nearest_chunks_start_first_with_frame_budget() -> void:
	var coordinates: Array[Vector3i] = [
		Vector3i(2, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i.ZERO,
		Vector3i(-1, 0, 0),
	]
	var manifest := _make_saved_manifest(coordinates, "priority_nearest")
	var streamer := _make_streamer(manifest)
	streamer.residency_radius = 2
	streamer.max_load_starts_per_frame = 2
	streamer.max_concurrent_loads = 8
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))

	_assert_equal(streamer.get_queued_coordinates(), [Vector3i.ZERO, Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)], "Queued residency work must be ordered nearest-first with deterministic coordinate ties.")
	streamer._process(0.0)
	_assert_equal(streamer.get_loading_coordinates(), [Vector3i(-1, 0, 0), Vector3i.ZERO], "Only the two nearest chunks may start when the per-frame budget is two.")
	_assert_equal(streamer.get_queued_coordinates(), [Vector3i(1, 0, 0), Vector3i(2, 0, 0)], "Farther chunks must remain queued while the frame budget is exhausted.")
	await _dispose_streamer(streamer)


func _test_priority_ties_are_deterministic() -> void:
	var coordinates: Array[Vector3i] = [
		Vector3i(1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, -1),
	]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "priority_ties"))
	streamer.residency_radius = 1
	streamer.max_load_starts_per_frame = 1
	streamer.max_concurrent_loads = 4
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))

	var expected := [
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, -1),
		Vector3i(0, 0, 1),
		Vector3i(1, 0, 0),
	]
	_assert_equal(streamer.get_queued_coordinates(), expected, "Equal-distance chunks must use stable coordinate ordering.")
	await _dispose_streamer(streamer)


func _test_concurrent_loading_budget() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "concurrent_budget"))
	streamer.max_load_starts_per_frame = 4
	streamer.max_concurrent_loads = 2
	for coordinate in coordinates:
		_assert_true(streamer.load_chunk(coordinate) == OK, "Concurrent-budget fixture requests must queue.")
	streamer._process(0.0)
	_assert_equal(streamer.get_loading_coordinates().size(), 2, "Simultaneous LOADING requests must respect max_concurrent_loads.")
	_assert_equal(streamer.get_queued_coordinates().size(), 2, "Requests beyond concurrent capacity must remain queued.")
	await _dispose_streamer(streamer)


func _test_freed_capacity_is_reused() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "reuse_capacity"))
	streamer.max_load_starts_per_frame = 1
	streamer.max_concurrent_loads = 1
	for coordinate in coordinates:
		streamer.load_chunk(coordinate)
	streamer._process(0.0)
	_assert_equal(streamer.get_loading_coordinates().size(), 1, "One request must initially consume the only loading slot.")
	_assert_equal(streamer.get_queued_coordinates().size(), 1, "Second request must wait for capacity.")
	_assert_true(await _wait_until_loaded_or_loading(streamer, Vector3i(1, 0, 0)), "Freed loading capacity must be reused by queued work.")
	await _dispose_streamer(streamer)


func _test_duplicate_requests_are_idempotent() -> void:
	var coordinate := Vector3i.ZERO
	_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), VALID_ASSET_PATH) == OK, "Duplicate-request fixture must save.")
	var streamer := _make_streamer(_make_manifest(coordinate, VALID_ASSET_PATH))
	_assert_true(streamer.load_chunk(coordinate) == OK, "First request must be accepted.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Duplicate pending request must remain idempotent.")
	_assert_equal(streamer.get_pending_coordinates(), [coordinate], "Duplicate requests must not duplicate queued work.")
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	_assert_equal(streamer.get_pending_coordinates(), [coordinate], "Repeated residency updates must not duplicate queued work.")
	_assert_true(await _wait_for_idle(streamer), "Duplicate-request fixture must finish loading.")
	_assert_true(streamer.load_chunk(coordinate) == OK, "Duplicate resident request must remain idempotent.")
	_assert_equal(streamer.get_loaded_coordinates(), [coordinate], "Duplicate resident requests must not duplicate instances.")
	await _dispose_streamer(streamer)


func _test_unload_removes_queued_request() -> void:
	var coordinate := Vector3i(1, 0, 0)
	var path := _save_asset(coordinate, "cancel_queued")
	var streamer := _make_streamer(_make_manifest(coordinate, path))
	streamer.load_chunk(coordinate)
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.QUEUED, "Fixture must begin queued.")
	_assert_true(streamer.unload_chunk(coordinate), "Unloading queued work must cancel it immediately.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.UNLOADED, "Cancelled queued work must return to unloaded state.")
	_assert_true(streamer.get_pending_coordinates().is_empty(), "Cancelled queued work must leave no pending request.")
	await _dispose_streamer(streamer)


func _test_unload_cancels_loading_request() -> void:
	var coordinate := Vector3i(1, 0, 0)
	var path := _save_asset(coordinate, "cancel_loading")
	var streamer := _make_streamer(_make_manifest(coordinate, path))
	streamer.load_chunk(coordinate)
	streamer._process(0.0)
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.LOADING, "Cancellation test must reach loading state before cancellation.")
	_assert_true(streamer.unload_chunk(coordinate), "Unloading a loading chunk must logically cancel its request.")
	_assert_equal(streamer.get_chunk_load_state(coordinate), CHUNK_STREAMER.ChunkLoadState.UNLOADED, "Cancelled loading chunks must immediately return to unloaded state.")
	for _frame in range(4):
		streamer._process(0.0)
		await process_frame
	_assert_true(not streamer.is_chunk_loaded(coordinate), "Cancelled threaded results must never create resident instances.")
	await _dispose_streamer(streamer)


func _test_failed_load_frees_capacity() -> void:
	var broken := Vector3i.ZERO
	var valid := Vector3i(1, 0, 0)
	var broken_path := "user://chunk_streaming_priority_broken.tres"
	_assert_true(ResourceSaver.save(Resource.new(), broken_path) == OK, "Broken scheduling fixture must save.")
	var valid_path := _save_asset(valid, "after_failure")
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	manifest.set_entry(_make_entry(broken, broken_path))
	manifest.set_entry(_make_entry(valid, valid_path))
	var streamer := _make_streamer(manifest)
	streamer.max_load_starts_per_frame = 1
	streamer.max_concurrent_loads = 1
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	streamer._process(0.0)
	_assert_equal(streamer.get_chunk_load_state(broken), CHUNK_STREAMER.ChunkLoadState.LOADING, "Nearest broken request must initially consume loading capacity.")
	_assert_equal(streamer.get_chunk_load_state(valid), CHUNK_STREAMER.ChunkLoadState.QUEUED, "Valid request must wait behind occupied capacity.")
	_assert_true(await _wait_until_loaded_or_loading(streamer, valid), "A failed active load must free capacity for the next queued request.")
	_assert_true(not streamer.is_chunk_pending(broken) and not streamer.is_chunk_loaded(broken), "Failed loads must leave coherent unloaded state.")
	await _dispose_streamer(streamer)


func _test_residency_updates_while_pending() -> void:
	var first := Vector3i.ZERO
	var second := Vector3i(1, 0, 0)
	var first_path := _save_asset(first, "residency_first")
	var second_path := _save_asset(second, "residency_second")
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	manifest.set_entry(_make_entry(first, first_path))
	manifest.set_entry(_make_entry(second, second_path))
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
	await _dispose_streamer(streamer)


func _test_sparse_manifest_residency() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(0, 0, 1)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "sparse"))
	streamer.residency_radius = 1
	streamer.max_load_starts_per_frame = 1
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	_assert_equal(streamer.get_pending_coordinates().size(), 3, "Sparse residency must queue only manifest-backed coordinates.")
	_assert_equal(streamer.get_queued_coordinates()[0], Vector3i.ZERO, "Sparse scheduling must still prioritize the nearest available chunk.")
	_assert_true(await _wait_for_idle(streamer), "Sparse manifest residency must settle under scheduler budgets.")
	_assert_equal(streamer.get_loaded_coordinates().size(), 3, "Sparse manifest residency must preserve all available desired chunks.")
	await _dispose_streamer(streamer)


func _test_residency_radius_one() -> void:
	var coordinates: Array[Vector3i] = []
	for z in range(-1, 2):
		for x in range(-1, 2):
			coordinates.append(Vector3i(x, 0, z))
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "radius_one"))
	streamer.residency_radius = 1
	streamer.max_load_starts_per_frame = 2
	streamer.max_concurrent_loads = 3
	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	_assert_equal(streamer.get_pending_coordinates().size(), 9, "Radius-one sparse manifest must queue the available 3 x 1 x 3 neighborhood.")
	_assert_true(await _wait_for_idle(streamer), "Radius-one asynchronous residency must settle under bounded scheduling.")
	_assert_equal(streamer.get_loaded_coordinates().size(), 9, "Scheduler budgets must not change final residency correctness.")
	await _dispose_streamer(streamer)


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


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 240) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		if streamer.get_pending_coordinates().is_empty():
			return true
		await process_frame
	return streamer.get_pending_coordinates().is_empty()


func _wait_until_loaded_or_loading(streamer: ChunkStreamer, coordinate: Vector3i, max_frames: int = 120) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		var state := streamer.get_chunk_load_state(coordinate)
		if state == CHUNK_STREAMER.ChunkLoadState.LOADING or state == CHUNK_STREAMER.ChunkLoadState.RESIDENT:
			return true
		await process_frame
	return false


func _make_streamer(manifest: TerrainChunkManifest) -> ChunkStreamer:
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = manifest
	get_root().add_child(streamer)
	return streamer


func _dispose_streamer(streamer: ChunkStreamer) -> void:
	streamer.clear_chunks()
	streamer.queue_free()
	await process_frame


func _make_manifest(coordinate: Vector3i, asset_path: String) -> TerrainChunkManifest:
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	manifest.set_entry(_make_entry(coordinate, asset_path))
	return manifest


func _make_saved_manifest(coordinates: Array[Vector3i], prefix: String) -> TerrainChunkManifest:
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	for coordinate in coordinates:
		manifest.set_entry(_make_entry(coordinate, _save_asset(coordinate, prefix)))
	return manifest


func _save_asset(coordinate: Vector3i, prefix: String) -> String:
	var path := "user://chunk_streaming_%s_%d_%d_%d.tres" % [prefix, coordinate.x, coordinate.y, coordinate.z]
	_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), path) == OK, "Streaming fixture asset must save: %s" % path)
	return path


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
