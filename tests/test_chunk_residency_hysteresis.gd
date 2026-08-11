extends SceneTree

const TERRAIN_CHUNK_ASSET := preload("res://voxel/chunking/TerrainChunkAsset.gd")
const TERRAIN_CHUNK_MANIFEST := preload("res://voxel/chunking/TerrainChunkManifest.gd")
const TERRAIN_CHUNK_MANIFEST_ENTRY := preload("res://voxel/chunking/TerrainChunkManifestEntry.gd")
const CHUNK_STREAMER := preload("res://voxel/chunking/ChunkStreamer.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_equal_radii_preserve_previous_policy()
	_test_invalid_radius_ordering_is_normalized()
	await _test_admission_and_loaded_retention()
	await _test_pending_request_is_retained_in_hysteresis_band()
	await _test_outside_unload_radius_is_removed()
	await _test_load_boundary_crossing_does_not_churn()
	await _test_unload_boundary_crossing_evicts_deterministically()
	await _test_scheduler_priority_and_budgets_are_unchanged()
	await _test_duplicate_residency_updates_are_idempotent()
	await _test_sparse_manifest_hysteresis()
	_test_runtime_streamer_does_not_depend_on_generation()
	_cleanup_fixture_files()
	quit(1 if _failed else 0)
	if not _failed:
		print("Chunk residency hysteresis tests passed.")


func _test_equal_radii_preserve_previous_policy() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "equal_radius"))
	streamer.residency_radius = 0
	_assert_equal(streamer.load_radius, 0, "Legacy residency_radius must set the admission radius.")
	_assert_equal(streamer.unload_radius, 0, "Legacy residency_radius must reproduce the old single-radius eviction policy.")

	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_equal(streamer.get_pending_coordinates(), [Vector3i.ZERO], "Equal-radius policy must admit only the target chunk at radius zero.")
	streamer.update_residency(_chunk_position(Vector3i(1, 0, 0)))
	_assert_true(not streamer.is_chunk_pending(Vector3i.ZERO), "Equal load/unload radii must immediately remove a chunk after it leaves the admission radius.")
	_assert_equal(streamer.get_pending_coordinates(), [Vector3i(1, 0, 0)], "Equal-radius policy must match the previous target replacement behavior.")
	await _dispose_streamer(streamer)


func _test_invalid_radius_ordering_is_normalized() -> void:
	var streamer := CHUNK_STREAMER.new()
	streamer.load_radius = 3
	streamer.unload_radius = 1
	_assert_equal(streamer.load_radius, 3, "Load radius assignment must remain explicit.")
	_assert_equal(streamer.unload_radius, 3, "Unload radius below load radius must normalize up to the load radius.")

	streamer.unload_radius = 1
	streamer.load_radius = 4
	_assert_equal(streamer.load_radius, 4, "Increasing load radius must apply the requested admission threshold.")
	_assert_equal(streamer.unload_radius, 4, "Increasing load radius past unload radius must preserve the invariant automatically.")
	streamer.free()


func _test_admission_and_loaded_retention() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "loaded_retention"))
	streamer.load_radius = 0
	streamer.unload_radius = 1
	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_equal(streamer.get_pending_coordinates(), [Vector3i.ZERO], "Chunks inside load radius must be admitted.")
	_assert_true(await _wait_for_idle(streamer), "Initial admitted chunk must become resident.")
	_assert_true(streamer.is_chunk_loaded(Vector3i.ZERO), "Initial admitted chunk must become resident.")

	streamer.update_residency(_chunk_position(Vector3i(1, 0, 0)))
	_assert_true(streamer.is_chunk_loaded(Vector3i.ZERO), "Loaded chunks outside load radius but inside unload radius must be retained.")
	_assert_true(streamer.is_chunk_pending(Vector3i(1, 0, 0)), "New target chunk inside load radius must be admitted.")
	await _dispose_streamer(streamer)


func _test_pending_request_is_retained_in_hysteresis_band() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "pending_retention"))
	streamer.load_radius = 0
	streamer.unload_radius = 1
	streamer.max_load_starts_per_frame = 1
	streamer.max_concurrent_loads = 1
	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_equal(streamer.get_chunk_load_state(Vector3i.ZERO), CHUNK_STREAMER.ChunkLoadState.QUEUED, "Fixture must begin with queued work.")

	streamer.update_residency(_chunk_position(Vector3i(1, 0, 0)))
	_assert_true(streamer.is_chunk_pending(Vector3i.ZERO), "Queued chunks entering the hysteresis band must not be cancelled.")
	_assert_true(streamer.is_chunk_pending(Vector3i(1, 0, 0)), "Current target chunk must also be admitted.")
	_assert_equal(streamer.get_pending_coordinates().size(), 2, "Hysteresis must retain old pending work while admitting new work.")
	await _dispose_streamer(streamer)


func _test_outside_unload_radius_is_removed() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(2, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "outside_unload"))
	streamer.load_radius = 0
	streamer.unload_radius = 1
	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_true(await _wait_for_idle(streamer), "Eviction fixture must load its initial chunk.")

	streamer.update_residency(_chunk_position(Vector3i(2, 0, 0)))
	_assert_true(not streamer.is_chunk_loaded(Vector3i.ZERO), "Chunks outside unload radius must be removed.")
	_assert_true(streamer.is_chunk_pending(Vector3i(2, 0, 0)), "New target chunk must be admitted after eviction.")
	await _dispose_streamer(streamer)


func _test_load_boundary_crossing_does_not_churn() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(1, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "load_boundary"))
	streamer.load_radius = 0
	streamer.unload_radius = 1
	var unloaded: Array[Vector3i] = []
	streamer.chunk_unloaded.connect(func(coordinate: Vector3i) -> void: unloaded.append(coordinate))

	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_true(await _wait_for_idle(streamer), "Boundary fixture must load its initial chunk.")
	streamer.update_residency(_chunk_position(Vector3i(1, 0, 0)))
	_assert_true(await _wait_for_idle(streamer), "Adjacent target chunk must settle while the old chunk is retained.")

	for _iteration in range(4):
		streamer.update_residency(_chunk_position(Vector3i.ZERO))
		streamer.update_residency(_chunk_position(Vector3i(1, 0, 0)))

	_assert_true(unloaded.is_empty(), "Repeated movement across the load boundary must not unload chunks still inside the retention radius.")
	_assert_equal(streamer.get_loaded_coordinates(), [Vector3i.ZERO, Vector3i(1, 0, 0)], "Both boundary chunks must remain resident without churn.")
	await _dispose_streamer(streamer)


func _test_unload_boundary_crossing_evicts_deterministically() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(2, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "unload_boundary"))
	streamer.load_radius = 0
	streamer.unload_radius = 1
	var unloaded: Array[Vector3i] = []
	streamer.chunk_unloaded.connect(func(coordinate: Vector3i) -> void: unloaded.append(coordinate))
	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_true(await _wait_for_idle(streamer), "Unload-boundary fixture must load its initial chunk.")

	for _iteration in range(3):
		streamer.update_residency(_chunk_position(Vector3i(2, 0, 0)))
		streamer.update_residency(_chunk_position(Vector3i.ZERO))

	_assert_true(unloaded.has(Vector3i.ZERO), "Crossing beyond unload radius must evict the old resident chunk.")
	_assert_true(streamer.is_chunk_pending(Vector3i.ZERO) or streamer.is_chunk_loaded(Vector3i.ZERO), "Returning inside load radius must coherently re-admit an evicted chunk.")
	await _dispose_streamer(streamer)


func _test_scheduler_priority_and_budgets_are_unchanged() -> void:
	var coordinates: Array[Vector3i] = [
		Vector3i.ZERO,
		Vector3i(-1, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(2, 0, 0),
	]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "scheduler"))
	streamer.load_radius = 2
	streamer.unload_radius = 3
	streamer.max_load_starts_per_frame = 1
	streamer.max_concurrent_loads = 1
	streamer.update_residency(_chunk_position(Vector3i.ZERO))

	_assert_equal(
		streamer.get_queued_coordinates(),
		[Vector3i.ZERO, Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)],
		"Hysteresis must not change nearest-first scheduler ordering."
	)
	streamer._process(0.0)
	_assert_equal(streamer.get_loading_coordinates(), [Vector3i.ZERO], "Per-frame start budget must remain respected with hysteresis enabled.")
	_assert_equal(streamer.get_queued_coordinates().size(), 3, "Work beyond the per-frame budget must remain queued.")
	streamer._process(0.0)
	_assert_true(streamer.get_loading_coordinates().size() <= 1, "Maximum concurrent loading capacity must remain respected with hysteresis enabled.")
	await _dispose_streamer(streamer)


func _test_duplicate_residency_updates_are_idempotent() -> void:
	var coordinate := Vector3i.ZERO
	var streamer := _make_streamer(_make_saved_manifest([coordinate], "duplicate"))
	streamer.load_radius = 0
	streamer.unload_radius = 1
	for _iteration in range(5):
		streamer.update_residency(_chunk_position(coordinate))
	_assert_equal(streamer.get_pending_coordinates(), [coordinate], "Repeated hysteretic residency updates must not duplicate queued work.")
	_assert_true(await _wait_for_idle(streamer), "Duplicate update fixture must settle.")
	for _iteration in range(5):
		streamer.update_residency(_chunk_position(coordinate))
	_assert_equal(streamer.get_loaded_coordinates(), [coordinate], "Repeated settled updates must not duplicate resident instances.")
	await _dispose_streamer(streamer)


func _test_sparse_manifest_hysteresis() -> void:
	var coordinates: Array[Vector3i] = [Vector3i.ZERO, Vector3i(2, 0, 0)]
	var streamer := _make_streamer(_make_saved_manifest(coordinates, "sparse"))
	streamer.load_radius = 1
	streamer.unload_radius = 2
	streamer.update_residency(_chunk_position(Vector3i.ZERO))
	_assert_equal(streamer.get_pending_coordinates(), [Vector3i.ZERO], "Sparse manifests must admit only available entries inside load radius.")
	_assert_true(await _wait_for_idle(streamer), "Sparse hysteresis fixture must settle.")
	streamer.update_residency(_chunk_position(Vector3i(1, 0, 0)))
	_assert_true(streamer.is_chunk_loaded(Vector3i.ZERO), "Sparse manifest residents inside retention radius must remain resident.")
	_assert_true(streamer.is_chunk_pending(Vector3i(2, 0, 0)), "Sparse manifest entries entering admission radius must queue normally.")
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
	_assert_true(source.contains("load_threaded_request"), "Runtime streaming must retain Godot threaded resource loading.")
	_assert_true(source.contains("max_load_starts_per_frame"), "Hysteresis must preserve scheduler start budgets.")
	_assert_true(source.contains("max_concurrent_loads"), "Hysteresis must preserve concurrent loading budgets.")


func _make_streamer(manifest: TerrainChunkManifest) -> ChunkStreamer:
	var streamer := CHUNK_STREAMER.new()
	streamer.manifest = manifest
	get_root().add_child(streamer)
	return streamer


func _make_saved_manifest(coordinates: Array[Vector3i], tag: String) -> TerrainChunkManifest:
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manifest.sample_spacing = 1.0
	for coordinate in coordinates:
		var path := "user://chunk_hysteresis_%s_%d_%d_%d.tres" % [
			tag,
			coordinate.x,
			coordinate.y,
			coordinate.z,
		]
		_assert_true(ResourceSaver.save(_make_valid_asset(coordinate), path) == OK, "Hysteresis fixture asset must save.")
		manifest.set_entry(_make_entry(coordinate, path))
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


func _chunk_position(coordinate: Vector3i) -> Vector3:
	return Vector3(coordinate) * 4.0 + Vector3.ONE * 0.5


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 180) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		if streamer.get_pending_coordinates().is_empty():
			return true
		await process_frame
	return streamer.get_pending_coordinates().is_empty()


func _dispose_streamer(streamer: ChunkStreamer) -> void:
	streamer.clear_chunks()
	streamer.queue_free()
	await process_frame


func _cleanup_fixture_files() -> void:
	var directory := DirAccess.open("user://")
	if directory == null:
		return
	for filename in directory.get_files():
		if filename.begins_with("chunk_hysteresis_"):
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
