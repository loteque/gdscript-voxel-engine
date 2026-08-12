extends Node3D

## Runtime proof for large single-LOD streaming, hysteresis, scheduling, async loading, and loading analysis.

const DEFAULT_MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const THREAD_SMOKE_TIMEOUT_MSEC := 5000
const RECENT_FRAME_WINDOW := 120
const CONCURRENCY_OPTIONS := [1, 2, 4, 8]
const CACHE_PROVENANCE_OPTIONS := [
	"unknown",
	"first-load / cold-ish",
	"repeated / warm",
]
const COLOR_SUCCESS := Color(0.36, 0.9, 0.43, 1.0)
const COLOR_FAILURE := Color(1.0, 0.28, 0.3, 1.0)
const COLOR_PENDING := Color(0.24, 0.56, 1.0, 1.0)

@export var manifest: TerrainChunkManifest
@export_file("*.tres") var manifest_path: String = DEFAULT_MANIFEST_PATH
@export_range(0, 16, 1) var load_radius: int = 2
@export_range(0, 16, 1) var unload_radius: int = 3
@export var target_speed: float = 18.0
@export var target_min_x: float = -42.0
@export var target_max_x: float = 42.0
@export var target_min_z: float = -42.0
@export var target_max_z: float = 42.0
@export var lane_step: float = 12.0
@export var thread_smoke_enabled: bool = true

@onready var _streamer: ChunkStreamer = $ChunkStreamer
@onready var _target: Node3D = $ResidencyTarget
@onready var _camera: Camera3D = $Camera
@onready var _thread_value: Label = $UI/Panel/Margin/Content/Summary/ThreadCard/Margin/VBox/Value
@onready var _background_value: Label = $UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/Grid/BackgroundValue
@onready var _residency_value: Label = $UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/Grid/ResidencyValue
@onready var _total_value: Label = $UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/TotalRow/Value
@onready var _completed_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/CompletedValue
@onready var _failed_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/FailedValue
@onready var _frame_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/FrameValue
@onready var _recent_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/RecentValue
@onready var _target_label: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Target
@onready var _details_label: Label = $UI/Panel/Margin/Content/Details
@onready var _details_button: Button = $UI/Panel/Margin/Content/DetailsToggle
@onready var _pause_button: Button = $UI/Panel/Margin/Content/Buttons/Load
@onready var _reset_button: Button = $UI/Panel/Margin/Content/Buttons/Unload
@onready var _concurrency_selector: OptionButton = $UI/Panel/Margin/Content/Summary/ConcurrencyCard/Margin/VBox/Concurrency
@onready var _cache_selector: OptionButton = $UI/Panel/Margin/Content/Summary/CacheCard/Margin/VBox/Cache

var _motion_direction: float = 1.0
var _motion_enabled: bool = true
var _streaming_state: String = "not configured"
var _thread_smoke_task_id: int = -1
var _thread_smoke_started_msec: int = 0
var _thread_smoke_state: String = "not started"
var _thread_smoke_web_prerequisites: String = "not checked"
var _thread_smoke_timed_out: bool = false
var _recent_frame_times_msec: Array[float] = []
var _cache_provenance: String = "unknown"


func _ready() -> void:
	if manifest == null and not manifest_path.is_empty():
		manifest = ResourceLoader.load(manifest_path) as TerrainChunkManifest

	_streamer.manifest = manifest
	_streamer.load_radius = load_radius
	_streamer.unload_radius = unload_radius
	_streamer.target = _target
	_streamer.chunk_load_queued.connect(_on_chunk_load_queued)
	_streamer.chunk_load_started.connect(_on_chunk_load_started)
	_streamer.chunk_loaded.connect(_on_residency_changed)
	_streamer.chunk_unloaded.connect(_on_chunk_unloaded)
	_streamer.chunk_load_failed.connect(_on_chunk_load_failed)
	_pause_button.pressed.connect(_toggle_motion)
	_reset_button.pressed.connect(_reset_experiment)
	_details_button.pressed.connect(_toggle_details)
	_configure_experiment_controls()
	if thread_smoke_enabled:
		_start_thread_smoke_test()
	else:
		_thread_smoke_state = "disabled"
		_thread_smoke_web_prerequisites = "disabled"
	_streamer.update_residency(_target.position)
	_set_streaming_state("resource-loading analysis active")


func _process(delta: float) -> void:
	if thread_smoke_enabled:
		_poll_thread_smoke_test()
	_record_frame_time(delta)
	if _can_advance_target():
		_advance_target(delta)
	_follow_target_with_camera()
	_update_status()


## Returns whether the validation thread smoke test reached a terminal state.
func is_thread_smoke_complete() -> bool:
	return _thread_smoke_state.begins_with("PASS") or _thread_smoke_state.begins_with("FAIL")


## Returns the current validation thread smoke-test state.
func get_thread_smoke_state() -> String:
	return _thread_smoke_state


## Returns the recent maximum frame time observed by this validation scene.
func get_recent_max_frame_time_msec() -> float:
	var maximum := 0.0
	for frame_time in _recent_frame_times_msec:
		maximum = maxf(maximum, frame_time)
	return maximum


## Returns the manually recorded cache-provenance label for this validation run.
func get_cache_provenance() -> String:
	return _cache_provenance


func _can_advance_target() -> bool:
	return _motion_enabled and _streamer.get_pending_coordinates().is_empty()


func _get_target_motion_state() -> String:
	if not _motion_enabled:
		return "paused"
	if not _streamer.get_pending_coordinates().is_empty():
		return "waiting for streaming"
	return "moving"


func _advance_target(delta: float) -> void:
	_target.position.x += target_speed * _motion_direction * delta
	if _target.position.x >= target_max_x:
		_target.position.x = target_max_x
		_motion_direction = -1.0
		_advance_lane()
	elif _target.position.x <= target_min_x:
		_target.position.x = target_min_x
		_motion_direction = 1.0
		_advance_lane()


func _advance_lane() -> void:
	_target.position.z += lane_step
	if _target.position.z > target_max_z:
		_target.position.z = target_min_z


func _follow_target_with_camera() -> void:
	_camera.position.x = _target.position.x + 36.0
	_camera.position.z = _target.position.z + 48.0


func _record_frame_time(delta: float) -> void:
	_recent_frame_times_msec.append(delta * 1000.0)
	if _recent_frame_times_msec.size() > RECENT_FRAME_WINDOW:
		_recent_frame_times_msec.pop_front()


func _toggle_motion() -> void:
	_motion_enabled = not _motion_enabled
	_pause_button.text = "⏸  Pause Target" if _motion_enabled else "▶  Resume Target"
	_update_status()


func _toggle_details() -> void:
	_details_label.visible = not _details_label.visible
	_details_button.text = "⌃  Hide streaming details" if _details_label.visible else "⌄  Show streaming details"


func _configure_experiment_controls() -> void:
	_concurrency_selector.clear()
	var selected_concurrency_index := 0
	for option_index in CONCURRENCY_OPTIONS.size():
		var concurrency: int = CONCURRENCY_OPTIONS[option_index]
		_concurrency_selector.add_item("%d concurrent" % concurrency, concurrency)
		if concurrency == _streamer.max_concurrent_loads:
			selected_concurrency_index = option_index
	_concurrency_selector.select(selected_concurrency_index)
	_concurrency_selector.item_selected.connect(_on_concurrency_selected)

	_cache_selector.clear()
	for option_index in CACHE_PROVENANCE_OPTIONS.size():
		_cache_selector.add_item(CACHE_PROVENANCE_OPTIONS[option_index], option_index)
	_cache_selector.select(0)
	_cache_selector.item_selected.connect(_on_cache_selected)


func _on_concurrency_selected(index: int) -> void:
	if not _streamer.get_pending_coordinates().is_empty():
		return
	_streamer.max_concurrent_loads = _concurrency_selector.get_item_id(index)
	_restart_experiment("concurrency changed to %d" % _streamer.max_concurrent_loads)


func _on_cache_selected(index: int) -> void:
	_cache_provenance = CACHE_PROVENANCE_OPTIONS[index]
	_set_streaming_state("cache provenance labeled %s" % _cache_provenance)


func _reset_experiment() -> void:
	_restart_experiment("experiment reset")


func _restart_experiment(state: String) -> void:
	if not _streamer.get_pending_coordinates().is_empty():
		return
	_streamer.clear_chunks()
	_target.position = Vector3(target_min_x, _target.position.y, target_min_z)
	_motion_direction = 1.0
	_streamer.reset_streaming_metrics()
	_streamer.update_residency(_target.position)
	_set_streaming_state(state)


func _set_streaming_state(state: String) -> void:
	_streaming_state = state
	_update_status()


# [b]Thread Smoke Test[/b]
# Proves browser thread prerequisites and actual WorkerThreadPool task execution.

func _start_thread_smoke_test() -> void:
	if OS.has_feature("web"):
		var browser_ready := bool(JavaScriptBridge.eval(
			"globalThis.crossOriginIsolated === true && typeof SharedArrayBuffer !== 'undefined'",
			true
		))
		_thread_smoke_web_prerequisites = "PASS" if browser_ready else "FAIL"
	else:
		_thread_smoke_web_prerequisites = "N/A (non-Web)"

	_thread_smoke_state = "RUNNING"
	_thread_smoke_started_msec = Time.get_ticks_msec()
	_thread_smoke_task_id = WorkerThreadPool.add_task(
		_run_thread_smoke_worker,
		false,
		"Chunk streaming validation thread smoke"
	)


func _poll_thread_smoke_test() -> void:
	if _thread_smoke_task_id < 0:
		return

	if WorkerThreadPool.is_task_completed(_thread_smoke_task_id):
		var completion_error := WorkerThreadPool.wait_for_task_completion(_thread_smoke_task_id)
		_thread_smoke_task_id = -1
		if completion_error != OK:
			_thread_smoke_state = "FAIL worker completion: %s" % error_string(completion_error)
		elif _thread_smoke_timed_out:
			_thread_smoke_state = "FAIL worker timeout"
		elif OS.has_feature("web") and _thread_smoke_web_prerequisites != "PASS":
			_thread_smoke_state = "FAIL browser prerequisites"
		else:
			_thread_smoke_state = "PASS"
		return

	if not _thread_smoke_timed_out \
		and Time.get_ticks_msec() - _thread_smoke_started_msec > THREAD_SMOKE_TIMEOUT_MSEC:
		_thread_smoke_timed_out = true
		_thread_smoke_state = "FAIL worker timeout"


func _run_thread_smoke_worker() -> void:
	var checksum := 0
	for index in range(100000):
		checksum = (checksum + index * 17) % 104729
	if checksum < 0:
		push_error("Unreachable thread smoke checksum state.")


func _update_status() -> void:
	_update_thread_status()
	if manifest == null:
		_background_value.text = "—"
		_residency_value.text = "—"
		_total_value.text = "—"
		_completed_value.text = "0"
		_failed_value.text = "0"
		_frame_value.text = "—"
		_recent_value.text = "—"
		_target_label.text = "Target: manifest missing"
		_details_label.text = "Web thread prerequisites: %s\nStreaming state: %s" % [
			_thread_smoke_web_prerequisites,
			_streaming_state,
		]
		return

	var target_coordinate := _streamer.position_to_chunk_coordinate(_target.position)
	var queued_coordinates := _streamer.get_queued_coordinates()
	var loading_coordinates := _streamer.get_loading_coordinates()
	var loaded_coordinates := _streamer.get_loaded_coordinates()
	var metrics := _streamer.get_streaming_metrics()
	var observations := _streamer.get_completed_load_observations()
	var last_observation: Dictionary = {} if observations.is_empty() else observations.back()
	var surface_count := 0
	for coordinate in loaded_coordinates:
		var instance := _streamer.get_chunk_instance(coordinate)
		if instance != null and instance.mesh != null:
			surface_count += instance.mesh.get_surface_count()
	var current_frame_msec: float = 0.0 if _recent_frame_times_msec.is_empty() else float(_recent_frame_times_msec.back())
	var approximate_mesh_mib := float(metrics["approximate_mesh_memory_bytes"]) / (1024.0 * 1024.0)
	var last_asset_summary := "none"
	if not last_observation.is_empty():
		last_asset_summary = "%s | %d B | %d verts | %d indices | %d/%d/%d ms" % [
			last_observation["coordinate"],
			last_observation["serialized_size_bytes"],
			last_observation["mesh_vertex_count"],
			last_observation["mesh_index_count"],
			last_observation["aggregate_latency_msec"],
			last_observation["background_wait_msec"],
			last_observation["residency_completion_msec"],
		]
	var has_pending := not _streamer.get_pending_coordinates().is_empty()
	_reset_button.disabled = has_pending
	_concurrency_selector.disabled = has_pending

	_background_value.text = "%.2f ms" % float(metrics["average_background_wait_msec"])
	_residency_value.text = "%.2f ms" % float(metrics["average_residency_completion_msec"])
	_total_value.text = "%.2f ms" % float(metrics["average_load_latency_msec"])
	_completed_value.text = str(metrics["completed_load_count"])
	_failed_value.text = str(metrics["failed_load_count"])
	_frame_value.text = "%.2f ms" % current_frame_msec
	_recent_value.text = "%.2f ms" % get_recent_max_frame_time_msec()
	_target_label.text = "Target: %s (%s)" % [target_coordinate, _get_target_motion_state()]

	_details_label.text = (
		"Dataset: %d single-LOD chunks, %s cells/chunk, %.1f spacing\nWeb thread prerequisites: %s\nRun cache label: %s\nLoad radius: %d | Unload radius: %d\nLoad budget: %d starts/frame, %d concurrent\nQueued chunks: %d | Loading chunks: %d | Resident chunks: %d\nPeak resident chunks: %d | Resident surfaces: %d\nCompleted loads: %d | Failed loads: %d | Unloads: %d\nCancelled pending: %d | Residency churn: %d\nMaximum aggregate latency: %d ms\nMaximum background wait: %d ms\nMaximum residency completion: %d ms\nCompleted observations: %d\nLast load: %s\nTiming boundary: polling-cadence observed\nApprox. resident mesh memory: %.2f MiB\nQueued coordinates: %s\nLoading coordinates: %s\nResident coordinates: %s\nStreaming state: %s"
		% [
			manifest.entries.size(),
			manifest.chunk_cell_dimensions,
			manifest.sample_spacing,
			_thread_smoke_web_prerequisites,
			_cache_provenance,
			_streamer.load_radius,
			_streamer.unload_radius,
			_streamer.max_load_starts_per_frame,
			_streamer.max_concurrent_loads,
			queued_coordinates.size(),
			loading_coordinates.size(),
			loaded_coordinates.size(),
			metrics["peak_resident_count"],
			surface_count,
			metrics["completed_load_count"],
			metrics["failed_load_count"],
			metrics["unload_count"],
			metrics["cancelled_pending_load_count"],
			metrics["residency_churn_count"],
			metrics["maximum_load_latency_msec"],
			metrics["maximum_background_wait_msec"],
			metrics["maximum_residency_completion_msec"],
			metrics["completed_observation_count"],
			last_asset_summary,
			approximate_mesh_mib,
			queued_coordinates,
			loading_coordinates,
			loaded_coordinates,
			_streaming_state,
		]
	)


func _update_thread_status() -> void:
	_thread_value.text = _thread_smoke_state.to_upper()
	if _thread_smoke_state.begins_with("PASS") or _thread_smoke_state == "disabled":
		_thread_value.add_theme_color_override("font_color", COLOR_SUCCESS)
	elif _thread_smoke_state.begins_with("FAIL"):
		_thread_value.add_theme_color_override("font_color", COLOR_FAILURE)
	else:
		_thread_value.add_theme_color_override("font_color", COLOR_PENDING)


func _on_chunk_load_queued(_coordinate: Vector3i) -> void:
	_set_streaming_state("chunk queued")


func _on_chunk_load_started(coordinate: Vector3i) -> void:
	_set_streaming_state("chunk loading %s" % coordinate)


func _on_residency_changed(coordinate: Vector3i, _instance: MeshInstance3D) -> void:
	_set_streaming_state("chunk resident %s" % coordinate)


func _on_chunk_unloaded(coordinate: Vector3i) -> void:
	_set_streaming_state("chunk unloaded %s" % coordinate)


func _on_chunk_load_failed(coordinate: Vector3i, error: Error) -> void:
	_set_streaming_state("load failed %s: %s" % [coordinate, error_string(error)])
