extends SceneTree

## Runs one controlled resource-loading experiment against the production streaming path.
##
## This scenario intentionally uses the real TerrainChunkManifest -> ChunkStreamer ->
## ResourceLoader -> MeshInstance3D path. Headless execution exercises scene-instance
## creation but does not measure GPU draw cost; rendering conclusions require browser or
## native rendered QA.

const MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const DEFAULT_OUTPUT_PATH := "artifacts/performance/resource-loading-run.json"
const LOAD_RADIUS := 2
const UNLOAD_RADIUS := 3
const LOAD_START_BUDGET := 2
const WAYPOINT_TIMEOUT_MSEC := 30000
const WAYPOINTS: Array[Vector3i] = [
	Vector3i(-4, 0, -4),
	Vector3i(-2, 0, -4),
	Vector3i(0, 0, -4),
	Vector3i(2, 0, -4),
	Vector3i(4, 0, -4),
	Vector3i(4, 0, 0),
	Vector3i(0, 0, 0),
	Vector3i(-4, 0, 0),
	Vector3i(-4, 0, 4),
	Vector3i(0, 0, 4),
	Vector3i(4, 0, 4),
]

var _concurrency: int = 4
var _repetition: int = 1
var _output_path: String = DEFAULT_OUTPUT_PATH
var _failed: bool = false
var _failure_message: String = ""


func _initialize() -> void:
	_parse_arguments()
	call_deferred("_run")


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--concurrency="):
			_concurrency = maxi(int(argument.get_slice("=", 1)), 1)
		elif argument.begins_with("--repetition="):
			_repetition = maxi(int(argument.get_slice("=", 1)), 1)
		elif argument.begins_with("--output="):
			_output_path = argument.get_slice("=", 1)


func _run() -> void:
	var manifest := load(MANIFEST_PATH) as TerrainChunkManifest
	if manifest == null:
		_fail("Unable to load production streaming manifest at %s." % MANIFEST_PATH)
		_write_result({})
		quit(1)
		return

	var streamer := ChunkStreamer.new()
	streamer.name = "ExperimentChunkStreamer"
	streamer.manifest = manifest
	streamer.load_radius = LOAD_RADIUS
	streamer.unload_radius = UNLOAD_RADIUS
	streamer.max_load_starts_per_frame = LOAD_START_BUDGET
	streamer.max_concurrent_loads = _concurrency
	root.add_child(streamer)

	var run_started_usec := Time.get_ticks_usec()
	var waypoint_results: Array[Dictionary] = []
	var peak_queued_count := 0
	var peak_loading_count := 0
	var peak_process_gap_msec := 0.0
	var previous_frame_usec := Time.get_ticks_usec()

	for waypoint in WAYPOINTS:
		var waypoint_started_usec := Time.get_ticks_usec()
		streamer.update_residency(_coordinate_center(manifest, waypoint))

		while not streamer.get_pending_coordinates().is_empty():
			var now_usec := Time.get_ticks_usec()
			peak_process_gap_msec = maxf(
				peak_process_gap_msec,
				float(now_usec - previous_frame_usec) / 1000.0
			)
			previous_frame_usec = now_usec
			peak_queued_count = maxi(peak_queued_count, streamer.get_queued_coordinates().size())
			peak_loading_count = maxi(peak_loading_count, streamer.get_loading_coordinates().size())

			if Time.get_ticks_usec() - waypoint_started_usec > WAYPOINT_TIMEOUT_MSEC * 1000:
				_fail("Timed out waiting for waypoint %s to settle." % waypoint)
				break
			await process_frame

		if _failed:
			break

		var metrics := streamer.get_streaming_metrics()
		waypoint_results.append({
			"coordinate": _vector3i_to_array(waypoint),
			"settle_duration_msec": float(Time.get_ticks_usec() - waypoint_started_usec) / 1000.0,
			"resident_count": metrics["resident_count"],
			"completed_load_count": metrics["completed_load_count"],
			"unload_count": metrics["unload_count"],
			"cancelled_pending_load_count": metrics["cancelled_pending_load_count"],
		})

	var metrics := streamer.get_streaming_metrics()
	var result := {
		"schema_version": 1,
		"experiment": "resource-loading-analysis-headless",
		"repetition": _repetition,
		"configuration": {
			"manifest_path": MANIFEST_PATH,
			"chunk_count": manifest.entries.size(),
			"chunk_cell_dimensions": _vector3i_to_array(manifest.chunk_cell_dimensions),
			"sample_spacing": manifest.sample_spacing,
			"lod_level": streamer.lod_level,
			"load_radius": LOAD_RADIUS,
			"unload_radius": UNLOAD_RADIUS,
			"max_load_starts_per_frame": LOAD_START_BUDGET,
			"max_concurrent_loads": _concurrency,
			"waypoints": WAYPOINTS.map(func(value: Vector3i) -> Array: return _vector3i_to_array(value)),
			"cache_provenance": "fresh Godot process; OS filesystem cache uncontrolled",
		},
		"environment": _get_environment_snapshot(),
		"measured": {
			"run_duration_msec": float(Time.get_ticks_usec() - run_started_usec) / 1000.0,
			"peak_queued_count": peak_queued_count,
			"peak_loading_count": peak_loading_count,
			"peak_process_gap_msec": peak_process_gap_msec,
			"metrics": metrics,
			"waypoints": waypoint_results,
			"load_observations": streamer.get_completed_load_observations(),
		},
		"limitations": [
			"Headless execution exercises ResourceLoader and MeshInstance3D creation but does not measure real GPU draw cost.",
			"Process-gap timing includes CI scheduling noise and is not a rendered frame-time benchmark.",
			"Resource completion timing is polling-cadence observed by ChunkStreamer.",
			"Fresh processes avoid in-process ResourceLoader cache reuse; operating-system filesystem cache state is uncontrolled.",
		],
		"success": not _failed,
		"failure": _failure_message,
	}

	_write_result(result)
	streamer.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _coordinate_center(manifest: TerrainChunkManifest, coordinate: Vector3i) -> Vector3:
	var extent := Vector3(manifest.chunk_cell_dimensions) * manifest.sample_spacing
	return Vector3(coordinate) * extent + extent * 0.5


func _get_environment_snapshot() -> Dictionary:
	var version := Engine.get_version_info()
	return {
		"godot_version": str(version.get("string", "unknown")),
		"os_name": OS.get_name(),
		"distribution_name": OS.get_distribution_name(),
		"processor_count": OS.get_processor_count(),
		"display_server": DisplayServer.get_name(),
		"rendering_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
		"mobile_rendering_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "unknown")),
		"headless": DisplayServer.get_name() == "headless",
	}


func _vector3i_to_array(value: Vector3i) -> Array[int]:
	return [value.x, value.y, value.z]


func _write_result(result: Dictionary) -> void:
	var output_directory := _output_path.get_base_dir()
	if not output_directory.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_directory))
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write experiment output to %s." % _output_path)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("RESOURCE_LOADING_EXPERIMENT_OUTPUT=%s" % _output_path)


func _fail(message: String) -> void:
	_failed = true
	_failure_message = message
	push_error(message)
