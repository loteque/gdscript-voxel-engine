extends Node3D

## Runtime proof for large single-LOD streaming, hysteresis, scheduling, and async loading.

const DEFAULT_MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const THREAD_SMOKE_TIMEOUT_MSEC := 5000
const RECENT_FRAME_WINDOW := 120

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

@onready var _streamer: ChunkStreamer = $ChunkStreamer
@onready var _target: Node3D = $ResidencyTarget
@onready var _camera: Camera3D = $Camera
@onready var _status_label: Label = $UI/Panel/Margin/Content/Status
@onready var _pause_button: Button = $UI/Panel/Margin/Content/Buttons/Load
@onready var _reset_button: Button = $UI/Panel/Margin/Content/Buttons/Unload

var _motion_direction: float = 1.0
var _motion_enabled: bool = true
var _streaming_state: String = "not configured"
var _thread_smoke_task_id: int = -1
var _thread_smoke_started_msec: int = 0
var _thread_smoke_state: String = "not started"
var _thread_smoke_web_prerequisites: String = "not checked"
var _thread_smoke_timed_out: bool = false
var _recent_frame_times_msec: Array[float] = []


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
	_reset_button.pressed.connect(_reset_target)
	_start_thread_smoke_test()
	_streamer.update_residency(_target.position)
	_set_streaming_state("large single-LOD streaming active")


func _process(delta: float) -> void:
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
	_pause_button.text = "Pause Target" if _motion_enabled else "Resume Target"
	_update_status()


func _reset_target() -> void:
	_target.position = Vector3(target_min_x, _target.position.y, target_min_z)
	_motion_direction = 1.0
	_streamer.reset_streaming_metrics()
	_streamer.update_residency(_target.position)
	_set_streaming_state("target and metrics reset")


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
	if manifest == null:
		_status_label.text = (
			"Manifest: missing\nWeb thread prerequisites: %s\nThread smoke: %s\nStreaming state: %s"
			% [_thread_smoke_web_prerequisites, _thread_smoke_state, _streaming_state]
		)
		return

	var target_coordinate := _streamer.position_to_chunk_coordinate(_target.position)
	var queued_coordinates := _streamer.get_queued_coordinates()
	var loading_coordinates := _streamer.get_loading_coordinates()
	var loaded_coordinates := _streamer.get_loaded_coordinates()
	var metrics := _streamer.get_streaming_metrics()
	var surface_count := 0
	for coordinate in loaded_coordinates:
		var instance := _streamer.get_chunk_instance(coordinate)
		if instance != null and instance.mesh != null:
			surface_count += instance.mesh.get_surface_count()
	var current_frame_msec := 0.0 if _recent_frame_times_msec.is_empty() else _recent_frame_times_msec.back()
	var approximate_mesh_mib := float(metrics["approximate_mesh_memory_bytes"]) / (1024.0 * 1024.0)
	_status_label.text = (
		"Dataset: %d single-LOD chunks, %s cells/chunk, %.1f spacing\nWeb thread prerequisites: %s\nThread smoke: %s\nTarget chunk: %s\nTarget motion: %s\nLoad radius: %d\nUnload radius: %d\nLoad budget: %d starts/frame, %d concurrent\nQueued chunks: %d\nQueued priority: %s\nLoading chunks: %d\nLoading coordinates: %s\nResident chunks: %d\nPeak resident chunks: %d\nResident surfaces: %d\nCompleted loads: %d\nFailed loads: %d\nUnloads: %d\nCancelled pending: %d\nResidency churn: %d\nAverage load latency: %.2f ms\nMaximum load latency: %d ms\nApprox. resident mesh memory: %.2f MiB\nFrame time: %.2f ms\nRecent max frame time: %.2f ms\nResident coordinates: %s\nStreaming state: %s"
		% [
			manifest.entries.size(),
			manifest.chunk_cell_dimensions,
			manifest.sample_spacing,
			_thread_smoke_web_prerequisites,
			_thread_smoke_state,
			target_coordinate,
			_get_target_motion_state(),
			_streamer.load_radius,
			_streamer.unload_radius,
			_streamer.max_load_starts_per_frame,
			_streamer.max_concurrent_loads,
			queued_coordinates.size(),
			queued_coordinates,
			loading_coordinates.size(),
			loading_coordinates,
			loaded_coordinates.size(),
			metrics["peak_resident_count"],
			surface_count,
			metrics["completed_load_count"],
			metrics["failed_load_count"],
			metrics["unload_count"],
			metrics["cancelled_pending_load_count"],
			metrics["residency_churn_count"],
			metrics["average_load_latency_msec"],
			metrics["maximum_load_latency_msec"],
			approximate_mesh_mib,
			current_frame_msec,
			get_recent_max_frame_time_msec(),
			loaded_coordinates,
			_streaming_state,
		]
	)


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
