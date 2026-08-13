extends Node3D

## Runs the mobile-first runtime workload comparison against production ChunkStreamer.

const TITLE := "Chunk Streamer Runtime Workload " + "Isolation"
const MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const MATRIX_PATH := "res://demo/experiments/mobile_web_warm_matrix.tres"
const REVISION_PATH := "res://demo/generated/build_revision.txt"
const REPETITIONS := 3
const RUN_TIMEOUT_MSEC := 300000
const MODE_KEYS := ["normal_runtime", "hidden_geometry", "no_scene_integration", "loader_only_control"]
const MODE_LABELS := ["Normal Runtime", "Hidden Geometry", "No Scene Integration", "Loader-Only Control"]
const MODE_DESCRIPTIONS := [
	"Production ChunkStreamer in the rendered world",
	"Same streamer and scene integration with geometry hidden",
	"Production ChunkStreamer progressed off-tree; no World3D integration",
	"Exact observed asset sequence through threaded ResourceLoader only",
]

@onready var _target: Node3D = $ResidencyTarget
@onready var _camera: Camera3D = $Camera

var _manifest: TerrainChunkManifest
var _matrix: StreamingExperimentMatrix
var _ui: RuntimeWorkloadExperimentUI
var _loader_control := RuntimeWorkloadLoaderControl.new()
var _results: Array[Dictionary] = []
var _reference_paths: Array[String] = []
var _running := false
var _stop_requested := false
var _completed_runs := 0
var _current_mode := 0
var _current_repetition := 0
var _experiment_started_usec := 0
var _capture_frames := false
var _frame_times_msec: Array[float] = []
var _failure := ""


func _ready() -> void:
	_manifest = ResourceLoader.load(MANIFEST_PATH) as TerrainChunkManifest
	_matrix = ResourceLoader.load(MATRIX_PATH) as StreamingExperimentMatrix
	_ui = RuntimeWorkloadExperimentUI.new()
	add_child(_ui)
	_ui.configure(TITLE, _setup_text(), MODE_LABELS, MODE_DESCRIPTIONS)
	_ui.run_requested.connect(_on_run_requested)
	_ui.stop_requested.connect(func() -> void: _stop_requested = true)
	_ui.export_requested.connect(_export_evidence)
	var validation_error := _validation_error()
	if validation_error.is_empty():
		_ui.set_ready()
	else:
		_failure = validation_error
		_ui.set_complete(0, get_expected_run_count(), false, validation_error)
	_update_results_ui()


func _process(delta: float) -> void:
	if _capture_frames:
		_frame_times_msec.append(delta * 1000.0)
	_camera.global_position = _target.global_position + Vector3(0.0, 50.0, 58.0)
	_camera.look_at(_target.global_position, Vector3.UP)
	if _running:
		_ui.set_running(_completed_runs, get_expected_run_count(), MODE_LABELS[_current_mode], _current_repetition, _live_text())


func get_experiment_title() -> String:
	return TITLE


func get_expected_run_count() -> int:
	return MODE_KEYS.size() * REPETITIONS


func get_results() -> Array[Dictionary]:
	return _results.duplicate(true)


func get_export_payload() -> Dictionary:
	return {
		"schema_version": 1,
		"experiment": "chunk-streamer-runtime-workload-comparison",
		"title": TITLE,
		"configuration": {
			"modes": MODE_KEYS.duplicate(),
			"repetitions_per_mode": REPETITIONS,
			"total_runs": get_expected_run_count(),
			"concurrency": 1,
			"cache_provenance": _matrix.cache_provenance if _matrix != null else "unknown",
			"load_radius": _matrix.load_radius if _matrix != null else -1,
			"unload_radius": _matrix.unload_radius if _matrix != null else -1,
			"max_load_starts_per_frame": _matrix.max_load_starts_per_frame if _matrix != null else -1,
			"waypoint_coordinates": Array(_matrix.waypoint_coordinates) if _matrix != null else [],
			"loader_control_source": "asset path order captured from first normal-runtime repetition",
		},
		"environment": {
			"godot_version": str(Engine.get_version_info().get("string", "unknown")),
			"os_name": OS.get_name(),
			"display_server": DisplayServer.get_name(),
			"processor_count": OS.get_processor_count(),
			"revision": _read_revision(),
			"user_agent": str(JavaScriptBridge.eval("navigator.userAgent", true)) if OS.has_feature("web") else "n/a",
		},
		"measured": {
			"total_duration_msec": float(Time.get_ticks_usec() - _experiment_started_usec) / 1000.0 if _experiment_started_usec > 0 else 0.0,
			"runs": _results.duplicate(true),
		},
		"success": _failure.is_empty() and _completed_runs == get_expected_run_count(),
		"failure": _failure,
		"limitations": [
			"The no-scene mode retains MeshInstance3D construction but keeps the production streamer off-tree, so nodes never enter SceneTree or World3D.",
			"The loader-only mode is an explicit control endpoint, not a ChunkStreamer implementation; it replays the observed production asset sequence.",
			"Cache provenance is operator evidence only; this experiment does not clear browser or ResourceLoader caches.",
		],
	}


func _on_run_requested() -> void:
	if _running or not _validation_error().is_empty():
		return
	_run_experiment()


func _run_experiment() -> void:
	_running = true
	_stop_requested = false
	_completed_runs = 0
	_results.clear()
	_reference_paths.clear()
	_failure = ""
	_experiment_started_usec = Time.get_ticks_usec()
	for mode_index in MODE_KEYS.size():
		for repetition in range(1, REPETITIONS + 1):
			if _stop_requested:
				_failure = "Experiment stopped by operator."
				break
			_current_mode = mode_index
			_current_repetition = repetition
			var result: Dictionary
			if mode_index == 3:
				result = await _run_loader_only(repetition)
			else:
				result = await _run_streamer_mode(mode_index, repetition)
			_results.append(result)
			_completed_runs += 1
			_update_results_ui()
			if not bool(result.get("success", false)):
				_failure = str(result.get("failure", "Run failed."))
				break
		if _stop_requested or not _failure.is_empty():
			break
	_running = false
	_capture_frames = false
	var success := _failure.is_empty() and _completed_runs == get_expected_run_count()
	var message := "Experiment Complete!" if success else "Stopped after %d / %d runs: %s" % [_completed_runs, get_expected_run_count(), _failure]
	_ui.set_complete(_completed_runs, get_expected_run_count(), success, message)
	_update_results_ui()


func _run_streamer_mode(mode_index: int, repetition: int) -> Dictionary:
	var streamer := ChunkStreamer.new()
	streamer.manifest = _manifest
	streamer.load_radius = _matrix.load_radius
	streamer.unload_radius = _matrix.unload_radius
	streamer.max_load_starts_per_frame = _matrix.max_load_starts_per_frame
	streamer.max_concurrent_loads = 1
	var off_tree := mode_index == 2
	if not off_tree:
		streamer.target = _target
		streamer.visible = mode_index != 1
		add_child(streamer)
		await get_tree().process_frame
	else:
		streamer.target = null
	streamer.reset_streaming_metrics()
	_frame_times_msec.clear()
	_capture_frames = true
	var started_usec := Time.get_ticks_usec()
	var completed_waypoints := 0
	for coordinate in _matrix.waypoint_coordinates:
		_target.position = _coordinate_to_position(coordinate)
		streamer.update_residency(_target.position)
		var settled_frames := 0
		while settled_frames < _matrix.settle_frames:
			if _stop_requested:
				var stopped := _streamer_result(streamer, mode_index, repetition, started_usec, completed_waypoints, false, "Stopped by operator.")
				_cleanup_streamer(streamer, off_tree)
				_capture_frames = false
				return stopped
			if Time.get_ticks_usec() - started_usec > RUN_TIMEOUT_MSEC * 1000:
				var timed_out := _streamer_result(streamer, mode_index, repetition, started_usec, completed_waypoints, false, "Run exceeded five-minute safety timeout.")
				_cleanup_streamer(streamer, off_tree)
				_capture_frames = false
				return timed_out
			if off_tree:
				streamer._process(0.0)
			await get_tree().process_frame
			if streamer.get_pending_coordinates().is_empty():
				settled_frames += 1
			else:
				settled_frames = 0
		completed_waypoints += 1
	_capture_frames = false
	var metrics := streamer.get_streaming_metrics()
	var success := int(metrics.get("failed_load_count", 0)) == 0
	var result := _streamer_result(streamer, mode_index, repetition, started_usec, completed_waypoints, success, "" if success else "ChunkStreamer reported failed loads.")
	if mode_index == 0 and repetition == 1 and success:
		_reference_paths = _asset_paths_from_observations(result.get("load_observations", []))
	_cleanup_streamer(streamer, off_tree)
	if not off_tree:
		await get_tree().process_frame
	return result


func _streamer_result(streamer: ChunkStreamer, mode_index: int, repetition: int, started_usec: int, completed_waypoints: int, success: bool, failure: String) -> Dictionary:
	var duration_msec := float(Time.get_ticks_usec() - started_usec) / 1000.0
	var metrics := streamer.get_streaming_metrics()
	var observations := streamer.get_completed_load_observations()
	var load_count := int(metrics.get("completed_load_count", 0))
	return {
		"mode": MODE_KEYS[mode_index],
		"mode_label": MODE_LABELS[mode_index],
		"repetition": repetition,
		"success": success,
		"failure": failure,
		"duration_msec": duration_msec,
		"waypoints_completed": completed_waypoints,
		"completed_loads": load_count,
		"loads_per_second": float(load_count) * 1000.0 / maxf(duration_msec, 0.001),
		"streaming_metrics": metrics,
		"load_observations": observations,
		"frame_timing": _frame_stats(_frame_times_msec),
	}


func _run_loader_only(repetition: int) -> Dictionary:
	if _reference_paths.is_empty():
		return {"mode": MODE_KEYS[3], "mode_label": MODE_LABELS[3], "repetition": repetition, "success": false, "failure": "Normal-runtime reference path sequence is unavailable."}
	_frame_times_msec.clear()
	_capture_frames = true
	var result := await _loader_control.run(get_tree(), _reference_paths)
	_capture_frames = false
	result["mode"] = MODE_KEYS[3]
	result["mode_label"] = MODE_LABELS[3]
	result["repetition"] = repetition
	result["frame_timing"] = _frame_stats(_frame_times_msec)
	return result


func _cleanup_streamer(streamer: ChunkStreamer, off_tree: bool) -> void:
	if off_tree:
		streamer.free()
		return
	streamer.clear_chunks()
	remove_child(streamer)
	streamer.free()


func _asset_paths_from_observations(observations: Array) -> Array[String]:
	var paths: Array[String] = []
	for observation_value in observations:
		var observation := observation_value as Dictionary
		var coordinate: Vector3i = observation.get("coordinate", Vector3i.ZERO)
		var entry := _manifest.find_entry(coordinate, 0)
		if entry != null and not entry.asset_path.is_empty():
			paths.append(entry.asset_path)
	return paths


func _coordinate_to_position(coordinate: Vector3i) -> Vector3:
	var extent := Vector3(_manifest.chunk_cell_dimensions) * _manifest.sample_spacing
	return Vector3(coordinate) * extent + extent * 0.5


func _frame_stats(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"mean_msec": 0.0, "p95_msec": 0.0, "p99_msec": 0.0, "max_msec": 0.0, "sample_count": 0}
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted:
		total += value
	return {
		"mean_msec": total / float(sorted.size()),
		"p95_msec": sorted[clampi(ceili(float(sorted.size()) * 0.95) - 1, 0, sorted.size() - 1)],
		"p99_msec": sorted[clampi(ceili(float(sorted.size()) * 0.99) - 1, 0, sorted.size() - 1)],
		"max_msec": sorted[sorted.size() - 1],
		"sample_count": sorted.size(),
	}


func _setup_text() -> String:
	var cache := _matrix.cache_provenance if _matrix != null else "unknown"
	var waypoints := _matrix.waypoint_coordinates.size() if _matrix != null else 0
	return "Device / Browser: %s\nGodot Version: %s\nConcurrency: 1\nCache State: %s\nWaypoint Path: %d coordinates\nTotal Modes: 4\nRepetitions / Mode: 3\nTotal Runs: 12" % [OS.get_name(), str(Engine.get_version_info().get("string", "unknown")), cache, waypoints]


func _live_text() -> String:
	return "Elapsed %.0f s" % [float(Time.get_ticks_usec() - _experiment_started_usec) / 1000000.0]


func _update_results_ui() -> void:
	if _ui == null:
		return
	var lines: Array[String] = []
	for mode_index in MODE_KEYS.size():
		var count := 0
		var throughput := 0.0
		var loader_wait := 0.0
		var queue_wait := 0.0
		for result in _results:
			if result.get("mode", "") != MODE_KEYS[mode_index] or not result.get("success", false):
				continue
			count += 1
			throughput += float(result.get("loads_per_second", 0.0))
			var metrics := result.get("streaming_metrics", {}) as Dictionary
			loader_wait += float(metrics.get("average_loader_wait_msec", 0.0))
			queue_wait += float(metrics.get("average_queue_wait_msec", 0.0))
		if count == 0:
			lines.append("%s  %s: pending" % [String.chr(65 + mode_index), MODE_LABELS[mode_index]])
		else:
			lines.append("%s  %s\n    Loads/sec %.2f  •  Loader %.0f ms  •  Queue %.0f ms" % [String.chr(65 + mode_index), MODE_LABELS[mode_index], throughput / count, loader_wait / count, queue_wait / count])
	var details := "All streamer modes use production ChunkStreamer request scheduling. Mode C keeps that streamer off-tree to remove SceneTree/World3D integration while retaining instance construction. Mode D is an explicit loader control that replays the first normal run's exact asset sequence.\n\nRevision: %s\nCache provenance: %s" % [_read_revision(), _matrix.cache_provenance if _matrix != null else "unknown"]
	_ui.set_results("\n\n".join(lines), details)


func _validation_error() -> String:
	if _manifest == null or not _manifest.is_valid():
		return "Streaming fixture manifest is missing or invalid."
	if _matrix == null:
		return "Experiment matrix is missing."
	var matrix_error := _matrix.get_validation_error()
	if not matrix_error.is_empty():
		return "Experiment matrix is invalid: %s" % matrix_error
	return ""


func _read_revision() -> String:
	if not FileAccess.file_exists(REVISION_PATH):
		return "unknown"
	var file := FileAccess.open(REVISION_PATH, FileAccess.READ)
	return file.get_as_text().strip_edges() if file != null else "unknown"


func _export_evidence() -> void:
	RuntimeWorkloadEvidenceExporter.export_payload(get_export_payload())
