extends SceneTree

const MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const STREAMER_SCRIPT := preload("res://voxel/chunking/ChunkStreamer.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest := ResourceLoader.load(MANIFEST_PATH) as TerrainChunkManifest
	_assert_true(manifest != null, "Large streaming manifest must load after the deterministic bake step.")
	if manifest == null:
		quit(1)
		return

	_test_manifest_scale(manifest)
	_test_generated_assets(manifest)
	await _test_large_runtime_streaming(manifest)
	_test_runtime_generation_separation()
	quit(1 if _failed else 0)
	if not _failed:
		print("Large single-LOD streaming validation tests passed.")


func _test_manifest_scale(manifest: TerrainChunkManifest) -> void:
	_assert_true(manifest.is_valid(), "Large streaming manifest must be structurally valid.")
	_assert_equal(manifest.entries.size(), 169, "Large validation dataset must contain the deterministic 13 x 1 x 13 region.")
	_assert_equal(manifest.chunk_cell_dimensions, Vector3i(12, 12, 12), "Large validation must preserve production chunk cell dimensions.")
	_assert_equal(manifest.sample_spacing, 1.0, "Large validation must preserve deterministic sample spacing.")
	for coordinate in [Vector3i(-6, 0, -6), Vector3i.ZERO, Vector3i(6, 0, 6)]:
		_assert_true(manifest.has_entry(coordinate, 0), "Large manifest must contain expected coordinate %s." % coordinate)
	_assert_true(not manifest.has_entry(Vector3i(7, 0, 0), 0), "Large manifest bounds must remain deterministic.")


func _test_generated_assets(manifest: TerrainChunkManifest) -> void:
	for entry in manifest.entries:
		_assert_true(entry != null and entry.is_valid(), "Every large validation manifest entry must be valid.")
		if entry == null:
			continue
		_assert_true(ResourceLoader.exists(entry.asset_path), "Every large validation chunk asset must exist: %s" % entry.asset_path)
		_assert_true(entry.serialized_size_bytes > 0, "Baked entries must record serialized asset size for loading analysis.")
		_assert_true(entry.mesh_vertex_count > 0, "Baked entries must record mesh vertex count for loading analysis.")
		_assert_true(entry.mesh_index_count > 0, "Baked entries must record mesh index count for loading analysis.")
		var asset := ResourceLoader.load(entry.asset_path) as TerrainChunkAsset
		_assert_true(asset != null and asset.is_valid(), "Every large validation chunk asset must deserialize as a valid TerrainChunkAsset.")
		if asset != null:
			_assert_equal(asset.lod_level, 0, "Large validation dataset must remain single LOD.")
			_assert_equal(entry.mesh_vertex_count, _get_mesh_vertex_count(asset.mesh), "Manifest vertex metadata must match the baked mesh.")
			_assert_equal(entry.mesh_index_count, _get_mesh_index_count(asset.mesh), "Manifest index metadata must match the baked mesh.")


func _test_large_runtime_streaming(manifest: TerrainChunkManifest) -> void:
	var streamer := STREAMER_SCRIPT.new() as ChunkStreamer
	streamer.manifest = manifest
	streamer.load_radius = 2
	streamer.unload_radius = 3
	streamer.max_load_starts_per_frame = 2
	streamer.max_concurrent_loads = 4
	root.add_child(streamer)

	var initial_metrics := streamer.get_streaming_metrics()
	_assert_equal(initial_metrics["resident_count"], 0, "Streaming metrics must begin with zero residents.")
	_assert_equal(initial_metrics["completed_load_count"], 0, "Streaming metrics must begin with zero completed loads.")
	_assert_equal(initial_metrics["failed_load_count"], 0, "Streaming metrics must begin with zero failures.")
	_assert_equal(initial_metrics["unload_count"], 0, "Streaming metrics must begin with zero unloads.")
	_assert_equal(initial_metrics["completed_observation_count"], 0, "Loading observations must begin empty.")
	_assert_equal(streamer.get_completed_load_observations().size(), 0, "Per-load observations must begin empty.")
	_assert_equal(initial_metrics, streamer.get_streaming_metrics(), "Repeated metric snapshots must not mutate runtime state.")

	streamer.update_residency(Vector3(0.5, 0.5, 0.5))
	_assert_equal(streamer.get_queued_coordinates().size(), 25, "Load radius two must create a substantial 25-chunk queue in the planar fixture.")
	_assert_equal(streamer.get_queued_coordinates()[0], Vector3i.ZERO, "Large queue must remain nearest-first.")
	streamer._process(0.0)
	_assert_true(streamer.get_loading_coordinates().size() <= 2, "One execution update must respect the two-start frame budget.")
	_assert_true(streamer.get_loading_coordinates().size() <= 4, "Large queue must respect maximum concurrent loading.")
	_assert_true(streamer.get_queued_coordinates().size() >= 23, "Farther large-dataset work must remain queued after one bounded update.")
	_assert_true(await _wait_for_idle(streamer), "Large initial residency must settle through the asynchronous scheduler.")

	var settled := streamer.get_streaming_metrics()
	_assert_equal(settled["resident_count"], 25, "Initial large residency must settle 25 chunks.")
	_assert_equal(settled["peak_resident_count"], 25, "Peak resident tracking must record the settled initial region.")
	_assert_equal(settled["completed_load_count"], 25, "Completed load metrics must count successful initial loads exactly.")
	_assert_equal(settled["completed_observation_count"], 25, "Each successful initial load must produce one analysis observation.")
	_assert_equal(settled["failed_load_count"], 0, "Valid large fixture loading must not report failures.")
	_assert_true(int(settled["approximate_mesh_memory_bytes"]) > 0, "Resident mesh memory estimate must be positive for rendered terrain.")
	_assert_true(float(settled["average_load_latency_msec"]) >= 0.0, "Average aggregate latency must be structurally non-negative.")
	_assert_true(int(settled["maximum_load_latency_msec"]) >= 0, "Maximum aggregate latency must be structurally non-negative.")
	_assert_true(float(settled["average_background_wait_msec"]) >= 0.0, "Average background wait must be structurally non-negative.")
	_assert_true(float(settled["average_residency_completion_msec"]) >= 0.0, "Average residency completion must be structurally non-negative.")
	_test_completed_observations(streamer, manifest, 25)
	print("Large streaming settled metrics: %s" % settled)

	streamer.update_residency(Vector3(12.5, 0.5, 0.5))
	_assert_true(await _wait_for_idle(streamer), "Hysteretic movement across one chunk must settle.")
	var retained := streamer.get_streaming_metrics()
	_assert_equal(retained["resident_count"], 30, "Hysteresis must retain the trailing five-chunk column while admitting the next column.")
	_assert_equal(retained["peak_resident_count"], 30, "Peak resident count must grow with the hysteresis band.")
	_assert_equal(retained["completed_load_count"], 30, "Five newly admitted chunks must increase completed load count exactly.")
	_assert_equal(retained["completed_observation_count"], 30, "Five newly admitted chunks must add five load observations.")
	_assert_equal(retained["unload_count"], 0, "Crossing only the load boundary must not evict retained chunks.")
	print("Large streaming retained metrics: %s" % retained)

	streamer.update_residency(Vector3(48.5, 0.5, 0.5))
	_assert_true(int(streamer.get_streaming_metrics()["unload_count"]) > 0, "Moving beyond the unload radius must record resident eviction.")
	_assert_true(await _wait_for_idle(streamer), "Large residency after eviction must settle.")
	var moved := streamer.get_streaming_metrics()
	_assert_true(int(moved["completed_load_count"]) > 30, "Traversal must accumulate completed loads beyond the resident set size.")
	_assert_equal(moved["completed_observation_count"], streamer.get_completed_load_observations().size(), "Observation count must match the read-only observation surface.")
	_assert_true(int(moved["residency_churn_count"]) >= int(moved["unload_count"]), "Residency churn must include unload activity.")
	print("Large streaming moved metrics: %s" % moved)

	var failures_before := int(moved["failed_load_count"])
	_assert_true(streamer.load_chunk(Vector3i(99, 0, 99)) != OK, "Missing explicit load must fail coherently.")
	_assert_equal(streamer.get_streaming_metrics()["failed_load_count"], failures_before + 1, "Intentional failures must increment failure metrics.")
	_assert_equal(streamer.get_streaming_metrics()["completed_observation_count"], moved["completed_observation_count"], "Failures must not create successful load observations.")

	var resident_before_reset := streamer.get_loaded_coordinates().size()
	streamer.reset_streaming_metrics()
	var reset := streamer.get_streaming_metrics()
	_assert_equal(reset["resident_count"], resident_before_reset, "Metrics reset must not change residency.")
	_assert_equal(reset["peak_resident_count"], resident_before_reset, "Reset peak must begin from current residency.")
	_assert_equal(reset["completed_load_count"], 0, "Metrics reset must clear completed-load history.")
	_assert_equal(reset["failed_load_count"], 0, "Metrics reset must clear failure history.")
	_assert_equal(reset["unload_count"], 0, "Metrics reset must clear unload history.")
	_assert_equal(reset["completed_observation_count"], 0, "Metrics reset must clear per-load observation history.")
	_assert_equal(streamer.get_completed_load_observations().size(), 0, "Reset must clear bounded analysis observations.")
	_assert_equal(reset, streamer.get_streaming_metrics(), "Observing reset metrics repeatedly must remain side-effect free.")

	streamer.clear_chunks()
	await process_frame
	streamer.queue_free()
	await process_frame


func _test_completed_observations(
	streamer: ChunkStreamer,
	manifest: TerrainChunkManifest,
	expected_count: int
) -> void:
	var observations := streamer.get_completed_load_observations()
	_assert_equal(observations.size(), expected_count, "Successful loads must produce the expected observation count.")
	for observation in observations:
		var aggregate := int(observation["aggregate_latency_msec"])
		var background := int(observation["background_wait_msec"])
		var completion := int(observation["residency_completion_msec"])
		_assert_true(aggregate >= 0 and background >= 0 and completion >= 0, "All loading analysis timings must be non-negative.")
		_assert_equal(aggregate, background + completion, "Aggregate latency must equal observed background wait plus residency completion.")
		var coordinate := observation["coordinate"] as Vector3i
		var entry := manifest.find_entry(coordinate, 0)
		_assert_true(entry != null, "Each completed observation must map back to a manifest entry.")
		if entry != null:
			_assert_equal(observation["serialized_size_bytes"], entry.serialized_size_bytes, "Observation size must come from immutable baked metadata.")
			_assert_equal(observation["mesh_vertex_count"], entry.mesh_vertex_count, "Observation vertices must come from immutable baked metadata.")
			_assert_equal(observation["mesh_index_count"], entry.mesh_index_count, "Observation indices must come from immutable baked metadata.")

	if not observations.is_empty():
		observations[0]["serialized_size_bytes"] = -1
		var fresh := streamer.get_completed_load_observations()
		_assert_true(int(fresh[0]["serialized_size_bytes"]) >= 0, "Observation snapshots must not expose mutable internal storage.")


func _get_mesh_vertex_count(mesh: ArrayMesh) -> int:
	var count := 0
	for surface_index in mesh.get_surface_count():
		count += mesh.surface_get_array_len(surface_index)
	return count


func _get_mesh_index_count(mesh: ArrayMesh) -> int:
	var count := 0
	for surface_index in mesh.get_surface_count():
		count += mesh.surface_get_array_index_len(surface_index)
	return count


func _test_runtime_generation_separation() -> void:
	var source := FileAccess.get_file_as_string("res://voxel/chunking/ChunkStreamer.gd")
	_assert_true(not source.contains("PointFieldResource"), "Runtime ChunkStreamer must not depend on PointFieldResource generation.")
	_assert_true(not source.contains("SurfaceNetsMesher"), "Runtime ChunkStreamer must not depend on Surface Nets.")
	_assert_true(not source.contains("build_mesh"), "Runtime ChunkStreamer must not contain a procedural mesh-generation fallback.")
	_assert_true(not source.contains("FileAccess.open"), "Runtime loading analysis must not introduce asset file I/O for measurement.")


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 600) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		if streamer.get_pending_coordinates().is_empty():
			return true
		await process_frame
	return streamer.get_pending_coordinates().is_empty()


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
