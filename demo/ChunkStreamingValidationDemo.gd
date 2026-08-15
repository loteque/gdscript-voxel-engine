extends Node3D

## Runtime proof for large single-LOD streaming, hysteresis, scheduling, async loading, and loading analysis.

const DEFAULT_MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const DEFAULT_EXPERIMENT_MATRIX_PATH := "res://demo/experiments/mobile_web_warm_matrix.tres"
const THREAD_SMOKE_TIMEOUT_MSEC := 5000
const RECENT_FRAME_WINDOW := 120
const NARROW_LAYOUT_WIDTH := 900.0
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
@export var experiment_matrix: StreamingExperimentMatrix
@export_file("*.tres") var experiment_matrix_path: String = DEFAULT_EXPERIMENT_MATRIX_PATH
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
@onready var _content: VBoxContainer = $UI/Panel/Margin/Content
@onready var _summary_grid: GridContainer = $UI/Panel/Margin/Content/Summary
@onready var _metrics_grid: GridContainer = $UI/Panel/Margin/Content/Metrics
@onready var _buttons_grid: GridContainer = $UI/Panel/Margin/Content/Buttons
@onready var _thread_value: Label = $UI/Panel/Margin/Content/Summary/ThreadCard/Margin/VBox/Value
@onready var _background_value: Label = $UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/Grid/BackgroundValue
@onready var _residency_value: Label = $UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/Grid/ResidencyValue
@onready var _total_value: Label = $UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/TotalRow/Value
@onready var _completed_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/CompletedValue
@onready var _failed_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/FailedValue
@onready var _frame_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/FrameValue
@onready var _recent_value: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/RecentValue
@onready var _target_label: Label = $UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Target
@onready var _details_scroll: ScrollContainer = $UI/Panel/Margin/Content/DetailsScroll
@onready var _details_label: Label = $UI/Panel/Margin/Content/DetailsScroll/Details
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

var _matrix_panel: VBoxContainer
var _matrix_buttons: GridContainer
var _matrix_status_label: Label
var _matrix_run_button: Button
var _matrix_export_button: Button
var _matrix_running: bool = false
var _matrix_complete: bool = false
var _matrix_results: Array[Dictionary] = []
var _matrix_concurrency_index: int = 0
var _matrix_repetition_index: int = 0
var _matrix_waypoint_index: int = 0
var _matrix_settle_frame_count: int = 0
var _matrix_run_started_usec: int = 0
var _matrix_waypoint_started_usec: int = 0
var _matrix_peak_queued_count: int = 0
var _matrix_peak_loading_count: int = 0
var _matrix_peak_frame_time_msec: float = 0.0
var _matrix_waypoint_results: Array[Dictionary] = []


func _ready() -> void:
	if manifest == null and not manifest_path.is_empty():
		manifest = ResourceLoader.load(manifest_path) as TerrainChunkManifest
	if experiment_matrix == null and not experiment_matrix_path.is_empty():
		experiment_matrix = ResourceLoader.load(experiment_matrix_path) as StreamingExperimentMatrix

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
	get_viewport().size_changed.connect(_update_responsive_layout)
	_configure_experiment_controls()
	_configure_matrix_controls()
	_update_responsive_layout()
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
	if _matrix_running:
		_matrix_peak_frame_time_msec = maxf(_matrix_peak_frame_time_msec, delta * 1000.0)
		_update_matrix_runner()
	elif _can_advance_target():
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


## Returns whether an automated experiment matrix is currently executing.
func is_experiment_matrix_running() -> bool:
	return _matrix_running


## Returns completed matrix-run results without exposing mutable runner storage.
func get_experiment_matrix_results() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for result in _matrix_results:
		results.append(result.duplicate(true))
	return results


## Returns the complete export payload for the current matrix session.
func get_experiment_export_payload() -> Dictionary:
	var matrix_snapshot: Dictionary = {}
	if experiment_matrix != null:
		matrix_snapshot = {
			"name": experiment_matrix.matrix_name,
			"description": experiment_matrix.description,
			"cache_provenance": experiment_matrix.cache_provenance,
			"concurrency_values": Array(experiment_matrix.concurrency_values),
			"repetitions_per_concurrency": experiment_matrix.repetitions_per_concurrency,
			"load_radius": experiment_matrix.load_radius,
			"unload_radius": experiment_matrix.unload_radius,
			"max_load_starts_per_frame": experiment_matrix.max_load_starts_per_frame,
			"settle_frames": experiment_matrix.settle_frames,
			"waypoint_coordinates": experiment_matrix.waypoint_coordinates.map(
				func(value: Vector3i) -> Array[int]: return [value.x, value.y, value.z]
			),
		}
	return {
		"schema_version": 1,
		"experiment": "resource-loading-analysis-web-matrix",
		"matrix": matrix_snapshot,
		"environment": _get_environment_snapshot(),
		"completed_run_count": _matrix_results.size(),
		"expected_run_count": 0 if experiment_matrix == null else experiment_matrix.get_run_count(),
		"complete": experiment_matrix != null and _matrix_results.size() == experiment_matrix.get_run_count(),
		"runs": get_experiment_matrix_results(),
		"limitations": [
			"Cache provenance is operator-supplied; the matrix runner does not clear browser or ResourceLoader caches.",
			"Resource completion timing is polling-cadence observed by ChunkStreamer.",
			"Frame-time observations are validation diagnostics, not laboratory-grade GPU profiling.",
		],
	}


## Starts the configured matrix when the current streaming state is settled.
func start_experiment_matrix() -> bool:
	if experiment_matrix == null:
		_set_streaming_state("matrix unavailable")
		return false
	var validation_error := experiment_matrix.get_validation_error()
	if not validation_error.is_empty():
		_set_streaming_state("matrix invalid: %s" % validation_error)
		return false
	if _matrix_complete:
		_set_streaming_state("matrix already complete; reload the demo to run a new session")
		return false
	if _matrix_running or not _streamer.get_pending_coordinates().is_empty():
		return false

	_matrix_results.clear()
	_matrix_concurrency_index = 0
	_matrix_repetition_index = 0
	_matrix_running = true
	_motion_enabled = false
	_pause_button.text = "Resume Target"
	_cache_provenance = experiment_matrix.cache_provenance
	_streamer.load_radius = experiment_matrix.load_radius
	_streamer.unload_radius = experiment_matrix.unload_radius
	_streamer.max_load_starts_per_frame = experiment_matrix.max_load_starts_per_frame
	_select_cache_label(_cache_provenance)
	_begin_matrix_run()
	return true


## Downloads the accumulated matrix evidence on Web or writes it to user:// elsewhere.
func export_experiment_results() -> bool:
	if _matrix_results.is_empty():
		_set_streaming_state("no matrix results to export")
		return false

	var filename := "streaming-experiment-%s.json" % _safe_filename(
		experiment_matrix.matrix_name if experiment_matrix != null else "results"
	)
	var json_text := JSON.stringify(get_experiment_export_payload(), "\t")
	if OS.has_feature("web"):
		var script := """
const data = %s;
const filename = %s;
const blob = new Blob([data], {type: 'application/json'});
const url = URL.createObjectURL(blob);
const link = document.createElement('a');
link.href = url;
link.download = filename;
document.body.appendChild(link);
link.click();
link.remove();
setTimeout(() => URL.revokeObjectURL(url), 0);
""" % [JSON.stringify(json_text), JSON.stringify(filename)]
		JavaScriptBridge.eval(script, true)
	else:
		var file := FileAccess.open("user://%s" % filename, FileAccess.WRITE)
		if file == null:
			_set_streaming_state("experiment export failed")
			return false
		file.store_string(json_text)
		file.close()
	_set_streaming_state("exported %d matrix runs" % _matrix_results.size())
	return true


func _can_advance_target() -> bool:
	return not _matrix_running and not _matrix_complete and _motion_enabled and _streamer.get_pending_coordinates().is_empty()


func _get_target_motion_state() -> String:
	if _matrix_running:
		return "matrix experiment"
	if _matrix_complete:
		return "matrix complete"
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


func _update_responsive_layout() -> void:
	_apply_responsive_layout(get_viewport().get_visible_rect().size.x)


func _apply_responsive_layout(viewport_width: float) -> void:
	var narrow_layout := viewport_width < NARROW_LAYOUT_WIDTH
	_summary_grid.columns = 1 if narrow_layout else 3
	_metrics_grid.columns = 1 if narrow_layout else 2
	_buttons_grid.columns = 1 if narrow_layout else 2
	if _matrix_buttons != null:
		_matrix_buttons.columns = 1 if narrow_layout else 2


func _toggle_motion() -> void:
	if _matrix_running or _matrix_complete:
		return
	_motion_enabled = not _motion_enabled
	_pause_button.text = "Pause Target" if _motion_enabled else "Resume Target"
	_update_status()


func _toggle_details() -> void:
	_details_scroll.visible = not _details_scroll.visible
	_details_button.text = "Hide streaming details" if _details_scroll.visible else "Show streaming details"


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


func _configure_matrix_controls() -> void:
	_matrix_panel = VBoxContainer.new()
	_matrix_panel.name = "ExperimentMatrix"
	_matrix_panel.add_to_group("demo_overlay")
	_matrix_panel.add_theme_constant_override("separation", 10)

	_matrix_status_label = Label.new()
	_matrix_status_label.name = "Status"
	_matrix_status_label.add_theme_font_size_override("font_size", 22)
	_matrix_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_matrix_panel.add_child(_matrix_status_label)

	_matrix_buttons = GridContainer.new()
	_matrix_buttons.name = "Buttons"
	_matrix_buttons.columns = 2
	_matrix_buttons.add_theme_constant_override("h_separation", 12)
	_matrix_buttons.add_theme_constant_override("v_separation", 12)
	_matrix_panel.add_child(_matrix_buttons)

	_matrix_run_button = Button.new()
	_matrix_run_button.name = "RunMatrix"
	_matrix_run_button.text = "Run Experiment Matrix"
	_matrix_run_button.custom_minimum_size = Vector2(0, 70)
	_matrix_run_button.add_theme_font_size_override("font_size", 24)
	_matrix_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_matrix_run_button.pressed.connect(start_experiment_matrix)
	_matrix_buttons.add_child(_matrix_run_button)

	_matrix_export_button = Button.new()
	_matrix_export_button.name = "ExportMatrix"
	_matrix_export_button.text = "Export Experiment"
	_matrix_export_button.custom_minimum_size = Vector2(0, 70)
	_matrix_export_button.add_theme_font_size_override("font_size", 24)
	_matrix_export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_matrix_export_button.pressed.connect(export_experiment_results)
	_matrix_buttons.add_child(_matrix_export_button)

	_content.add_child(_matrix_panel)
	_content.move_child(_matrix_panel, _details_button.get_index())
	_update_matrix_status()


func _on_concurrency_selected(index: int) -> void:
	if _matrix_running or _matrix_complete or not _streamer.get_pending_coordinates().is_empty():
		return
	_streamer.max_concurrent_loads = _concurrency_selector.get_item_id(index)
	_restart_experiment("concurrency changed to %d" % _streamer.max_concurrent_loads)


func _on_cache_selected(index: int) -> void:
	if _matrix_running or _matrix_complete:
		return
	_cache_provenance = CACHE_PROVENANCE_OPTIONS[index]
	_set_streaming_state("cache provenance labeled %s" % _cache_provenance)


func _reset_experiment() -> void:
	if _matrix_running or _matrix_complete:
		return
	_restart_experiment("experiment reset")


func _restart_experiment(state: String) -> void:
	if _matrix_complete or not _streamer.get_pending_coordinates().is_empty():
		return
	_streamer.clear_chunks()
	_target.position = Vector3(target_min_x, _target.position.y, target_min_z)
	_motion_direction = 1.0
	_streamer.reset_streaming_metrics()
	_streamer.update_residency(_target.position)
	_set_streaming_state(state)


# [b]Experiment Matrix[/b]
# Runs deterministic validation scenarios while leaving production streaming ownership intact.

func _begin_matrix_run() -> void:
	if experiment_matrix == null or not _matrix_running:
		return
	if _matrix_concurrency_index >= experiment_matrix.concurrency_values.size():
		_finish_matrix()
		return

	var concurrency := experiment_matrix.concurrency_values[_matrix_concurrency_index]
	_streamer.clear_chunks()
	_streamer.reset_streaming_metrics()
	_streamer.max_concurrent_loads = concurrency
	_select_concurrency(concurrency)
	_recent_frame_times_msec.clear()
	_matrix_waypoint_results.clear()
	_matrix_waypoint_index = 0
	_matrix_settle_frame_count = 0
	_matrix_peak_queued_count = 0
	_matrix_peak_loading_count = 0
	_matrix_peak_frame_time_msec = 0.0
	_matrix_run_started_usec = Time.get_ticks_usec()
	_move_to_matrix_waypoint(0)
	_set_streaming_state(
		"matrix run %d/%d" % [_matrix_results.size() + 1, experiment_matrix.get_run_count()]
	)


func _update_matrix_runner() -> void:
	if not _matrix_running or experiment_matrix == null:
		return

	_matrix_peak_queued_count = maxi(_matrix_peak_queued_count, _streamer.get_queued_coordinates().size())
	_matrix_peak_loading_count = maxi(_matrix_peak_loading_count, _streamer.get_loading_coordinates().size())
	if not _streamer.get_pending_coordinates().is_empty():
		_matrix_settle_frame_count = 0
		return

	_matrix_settle_frame_count += 1
	if _matrix_settle_frame_count < experiment_matrix.settle_frames:
		return

	_record_matrix_waypoint()
	if _matrix_waypoint_index + 1 < experiment_matrix.waypoint_coordinates.size():
		_matrix_waypoint_index += 1
		_move_to_matrix_waypoint(_matrix_waypoint_index)
		return

	_record_matrix_run()
	_advance_matrix_indices()
	if _matrix_running:
		_begin_matrix_run()


func _move_to_matrix_waypoint(index: int) -> void:
	var coordinate := experiment_matrix.waypoint_coordinates[index]
	_target.position = _coordinate_center(coordinate)
	_matrix_waypoint_started_usec = Time.get_ticks_usec()
	_matrix_settle_frame_count = 0
	_streamer.update_residency(_target.position)
	_update_matrix_status()


func _record_matrix_waypoint() -> void:
	var coordinate := experiment_matrix.waypoint_coordinates[_matrix_waypoint_index]
	var metrics := _streamer.get_streaming_metrics()
	_matrix_waypoint_results.append({
		"coordinate": [coordinate.x, coordinate.y, coordinate.z],
		"settle_duration_msec": float(Time.get_ticks_usec() - _matrix_waypoint_started_usec) / 1000.0,
		"resident_count": metrics["resident_count"],
		"completed_load_count": metrics["completed_load_count"],
		"unload_count": metrics["unload_count"],
		"cancelled_pending_load_count": metrics["cancelled_pending_load_count"],
	})


func _record_matrix_run() -> void:
	var metrics := _streamer.get_streaming_metrics()
	var concurrency := experiment_matrix.concurrency_values[_matrix_concurrency_index]
	_matrix_results.append({
		"run_index": _matrix_results.size() + 1,
		"concurrency": concurrency,
		"repetition": _matrix_repetition_index + 1,
		"cache_provenance": experiment_matrix.cache_provenance,
		"run_duration_msec": float(Time.get_ticks_usec() - _matrix_run_started_usec) / 1000.0,
		"peak_queued_count": _matrix_peak_queued_count,
		"peak_loading_count": _matrix_peak_loading_count,
		"peak_frame_time_msec": _matrix_peak_frame_time_msec,
		"metrics": metrics.duplicate(true),
		"waypoints": _matrix_waypoint_results.duplicate(true),
		"load_observations": _streamer.get_completed_load_observations(),
	})
	_update_matrix_status()


func _advance_matrix_indices() -> void:
	_matrix_repetition_index += 1
	if _matrix_repetition_index >= experiment_matrix.repetitions_per_concurrency:
		_matrix_repetition_index = 0
		_matrix_concurrency_index += 1
	if _matrix_concurrency_index >= experiment_matrix.concurrency_values.size():
		_finish_matrix()


func _finish_matrix() -> void:
	_matrix_running = false
	_matrix_complete = true
	_motion_enabled = false
	_matrix_run_button.disabled = true
	_concurrency_selector.disabled = true
	_cache_selector.disabled = true
	_pause_button.disabled = true
	_reset_button.disabled = true
	_set_streaming_state("matrix complete: %d runs; execution stopped, export is preserved" % _matrix_results.size())
	_update_matrix_status()


func _coordinate_center(coordinate: Vector3i) -> Vector3:
	var extent := Vector3(manifest.chunk_cell_dimensions) * manifest.sample_spacing
	return Vector3(coordinate) * extent + extent * 0.5


func _select_concurrency(concurrency: int) -> void:
	for index in _concurrency_selector.item_count:
		if _concurrency_selector.get_item_id(index) == concurrency:
			_concurrency_selector.select(index)
			return


func _select_cache_label(label: String) -> void:
	for index in CACHE_PROVENANCE_OPTIONS.size():
		if CACHE_PROVENANCE_OPTIONS[index] == label:
			_cache_selector.select(index)
			return


func _update_matrix_status() -> void:
	if _matrix_status_label == null:
		return
	if experiment_matrix == null:
		_matrix_status_label.text = "Experiment matrix: unavailable"
		return
	if _matrix_running:
		var concurrency := experiment_matrix.concurrency_values[_matrix_concurrency_index]
		_matrix_status_label.text = (
			"Matrix: %s · run %d/%d · %d concurrent · repetition %d/%d · waypoint %d/%d"
			% [
				experiment_matrix.matrix_name,
				_matrix_results.size() + 1,
				experiment_matrix.get_run_count(),
				concurrency,
				_matrix_repetition_index + 1,
				experiment_matrix.repetitions_per_concurrency,
				_matrix_waypoint_index + 1,
				experiment_matrix.waypoint_coordinates.size(),
			]
		)
	elif _matrix_complete:
		_matrix_status_label.text = "Matrix: %s · complete %d/%d · export preserved" % [
			experiment_matrix.matrix_name,
			_matrix_results.size(),
			experiment_matrix.get_run_count(),
		]
	else:
		_matrix_status_label.text = "Matrix: %s · recorded %d/%d runs" % [
			experiment_matrix.matrix_name,
			_matrix_results.size(),
			experiment_matrix.get_run_count(),
		]


func _safe_filename(value: String) -> String:
	var safe := value.to_lower().strip_edges().replace(" ", "-")
	for character in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		safe = safe.replace(character, "-")
	return safe


func _get_environment_snapshot() -> Dictionary:
	var version := Engine.get_version_info()
	var user_agent := "unknown"
	if OS.has_feature("web"):
		user_agent = str(JavaScriptBridge.eval("navigator.userAgent", true))
	return {
		"godot_version": str(version.get("string", "unknown")),
		"os_name": OS.get_name(),
		"distribution_name": OS.get_distribution_name(),
		"processor_count": OS.get_processor_count(),
		"display_server": DisplayServer.get_name(),
		"rendering_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
		"mobile_rendering_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "unknown")),
		"web_thread_prerequisites": _thread_smoke_web_prerequisites,
		"user_agent": user_agent,
	}


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

	var metrics := _streamer.get_streaming_metrics()
	_background_value.text = "%.2f ms" % metrics["average_background_load_msec"]
	_residency_value.text = "%.2f ms" % metrics["average_residency_msec"]
	_total_value.text = "%.2f ms" % metrics["average_total_load_msec"]
	_completed_value.text = str(metrics["completed_load_count"])
	_failed_value.text = str(metrics["failed_load_count"])
	_frame_value.text = "%.2f ms" % metrics["max_frame_time_msec"]
	_recent_value.text = "%.2f ms" % get_recent_max_frame_time_msec()
	_target_label.text = "Target: (%.1f, %.1f, %.1f) · %s" % [
		_target.position.x,
		_target.position.y,
		_target.position.z,
		_get_target_motion_state(),
	]
	_details_label.text = (
		"Web thread prerequisites: %s\n"
		+ "Streaming state: %s\n"
		+ "Resident: %d · Queued: %d · Loading: %d\n"
		+ "Started: %d · Completed: %d · Failed: %d · Unloaded: %d\n"
		+ "Cancelled pending: %d\n"
		+ "Average queue wait: %.2f ms\n"
		+ "Average loader/background wait: %.2f ms\n"
		+ "Average resource_get(): %.3f ms\n"
		+ "Average validation: %.3f ms\n"
		+ "Average instance setup: %.3f ms\n"
		+ "Average scene attachment: %.3f ms\n"
		+ "Average residency total: %.3f ms\n"
		+ "Average active load total: %.2f ms\n"
		+ "Average desired-to-resident total: %.2f ms\n"
		+ "Peak queued: %d · Peak loading: %d"
	) % [
		_thread_smoke_web_prerequisites,
		_streaming_state,
		metrics["resident_count"],
		metrics["queued_count"],
		metrics["loading_count"],
		metrics["started_load_count"],
		metrics["completed_load_count"],
		metrics["failed_load_count"],
		metrics["unload_count"],
		metrics["cancelled_pending_load_count"],
		metrics["average_queue_wait_msec"],
		metrics["average_loader_wait_msec"],
		metrics["average_resource_get_msec"],
		metrics["average_validation_msec"],
		metrics["average_instance_setup_msec"],
		metrics["average_scene_attachment_msec"],
		metrics["average_residency_msec"],
		metrics["average_total_load_msec"],
		metrics["average_desired_to_resident_msec"],
		metrics["peak_queued_count"],
		metrics["peak_loading_count"],
	]


func _update_thread_status() -> void:
	_thread_value.text = _thread_smoke_state
	if _thread_smoke_state.begins_with("PASS"):
		_thread_value.add_theme_color_override("font_color", COLOR_SUCCESS)
	elif _thread_smoke_state.begins_with("FAIL"):
		_thread_value.add_theme_color_override("font_color", COLOR_FAILURE)
	else:
		_thread_value.add_theme_color_override("font_color", COLOR_PENDING)
