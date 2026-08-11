extends Node3D

## Runtime proof for hysteretic residency, bounded scheduling, and asynchronous loading.

const DEFAULT_MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const THREAD_SMOKE_TIMEOUT_MSEC := 5000

@export var manifest: TerrainChunkManifest
@export_file("*.tres") var manifest_path: String = DEFAULT_MANIFEST_PATH
@export_range(0, 16, 1) var load_radius: int = 1
@export_range(0, 16, 1) var unload_radius: int = 2
@export var target_speed: float = 4.0
@export var target_min_x: float = -6.0
@export var target_max_x: float = 18.0

@onready var _streamer: ChunkStreamer = $ChunkStreamer
@onready var _target: Node3D = $ResidencyTarget
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
	_set_streaming_state("hysteretic residency active")


func _process(delta: float) -> void:
	_poll_thread_smoke_test()
	if _motion_enabled:
		_target.position.x += target_speed * _motion_direction * delta
		if _target.position.x >= target_max_x:
			_target.position.x = target_max_x
			_motion_direction = -1.0
		elif _target.position.x <= target_min_x:
			_target.position.x = target_min_x
			_motion_direction = 1.0
	_update_status()


## Returns whether the validation thread smoke test reached a terminal state.
func is_thread_smoke_complete() -> bool:
	return _thread_smoke_state.begins_with("PASS") or _thread_smoke_state.begins_with("FAIL")


## Returns the current validation thread smoke-test state.
func get_thread_smoke_state() -> String:
	return _thread_smoke_state


func _toggle_motion() -> void:
	_motion_enabled = not _motion_enabled
	_pause_button.text = "Pause Target" if _motion_enabled else "Resume Target"
	_update_status()


func _reset_target() -> void:
	_target.position.x = target_min_x
	_motion_direction = 1.0
	_streamer.update_residency(_target.position)
	_set_streaming_state("target reset")


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
	var surface_count := 0
	for coordinate in loaded_coordinates:
		var instance := _streamer.get_chunk_instance(coordinate)
		if instance != null and instance.mesh != null:
			surface_count += instance.mesh.get_surface_count()
	_status_label.text = (
		"Web thread prerequisites: %s\nThread smoke: %s\nTarget chunk: %s\nTarget motion: %s\nLoad radius: %d\nUnload radius: %d\nHysteresis band: retain active chunks outside load radius until unload radius\nLoad budget: %d starts/frame, %d concurrent\nQueued chunks: %d\nQueued priority: %s\nLoading chunks: %d\nLoading coordinates: %s\nResident chunks: %d\nResident surfaces: %d\nResident coordinates: %s\nStreaming state: %s"
		% [
			_thread_smoke_web_prerequisites,
			_thread_smoke_state,
			target_coordinate,
			"moving" if _motion_enabled else "paused",
			_streamer.load_radius,
			_streamer.unload_radius,
			_streamer.max_load_starts_per_frame,
			_streamer.max_concurrent_loads,
			queued_coordinates.size(),
			queued_coordinates,
			loading_coordinates.size(),
			loading_coordinates,
			loaded_coordinates.size(),
			surface_count,
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
