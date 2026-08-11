extends Node3D

## Runtime proof for target-relative residency and asynchronous baked-chunk loading.

const DEFAULT_MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"

@export var manifest: TerrainChunkManifest
@export_file("*.tres") var manifest_path: String = DEFAULT_MANIFEST_PATH
@export_range(0, 16, 1) var residency_radius: int = 1
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


func _ready() -> void:
	if manifest == null and not manifest_path.is_empty():
		manifest = ResourceLoader.load(manifest_path) as TerrainChunkManifest

	_streamer.manifest = manifest
	_streamer.residency_radius = residency_radius
	_streamer.target = _target
	_streamer.chunk_load_queued.connect(_on_chunk_load_queued)
	_streamer.chunk_load_started.connect(_on_chunk_load_started)
	_streamer.chunk_loaded.connect(_on_residency_changed)
	_streamer.chunk_unloaded.connect(_on_chunk_unloaded)
	_streamer.chunk_load_failed.connect(_on_chunk_load_failed)
	_pause_button.pressed.connect(_toggle_motion)
	_reset_button.pressed.connect(_reset_target)
	_streamer.update_residency(_target.position)
	_update_status("residency active")


func _process(delta: float) -> void:
	if _motion_enabled:
		_target.position.x += target_speed * _motion_direction * delta
		if _target.position.x >= target_max_x:
			_target.position.x = target_max_x
			_motion_direction = -1.0
		elif _target.position.x <= target_min_x:
			_target.position.x = target_min_x
			_motion_direction = 1.0
	_update_status("moving" if _motion_enabled else "paused")


func _toggle_motion() -> void:
	_motion_enabled = not _motion_enabled
	_pause_button.text = "Pause Target" if _motion_enabled else "Resume Target"


func _reset_target() -> void:
	_target.position.x = target_min_x
	_motion_direction = 1.0
	_streamer.update_residency(_target.position)
	_update_status("target reset")


func _update_status(state: String) -> void:
	if manifest == null:
		_status_label.text = "Manifest: missing\nState: %s" % state
		return

	var target_coordinate := _streamer.position_to_chunk_coordinate(_target.position)
	var loaded_coordinates := _streamer.get_loaded_coordinates()
	var pending_coordinates := _streamer.get_pending_coordinates()
	_status_label.text = (
		"Target chunk: %s\nResidency radius: %d\nPending chunks: %d\nPending coordinates: %s\nResident chunks: %d\nResident coordinates: %s\nState: %s"
		% [
			target_coordinate,
			residency_radius,
			pending_coordinates.size(),
			pending_coordinates,
			loaded_coordinates.size(),
			loaded_coordinates,
			state,
		]
	)


func _on_chunk_load_queued(_coordinate: Vector3i) -> void:
	_update_status("chunk queued")


func _on_chunk_load_started(_coordinate: Vector3i) -> void:
	_update_status("chunk loading")


func _on_residency_changed(_coordinate: Vector3i, _instance: MeshInstance3D) -> void:
	_update_status("chunk resident")


func _on_chunk_unloaded(_coordinate: Vector3i) -> void:
	_update_status("chunk unloaded")


func _on_chunk_load_failed(coordinate: Vector3i, error: Error) -> void:
	_update_status("load failed %s: %s" % [coordinate, error_string(error)])
