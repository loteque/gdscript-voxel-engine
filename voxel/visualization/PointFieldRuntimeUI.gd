@tool
class_name PointFieldRuntimeUI
extends CanvasLayer

## Hosts the runtime point-field controls and exposes their visualization targets.
##
## Assign [member visualizer] and [member surface_nets_display] on this node when
## instancing the runtime UI. The values are forwarded to the child
## [SurfaceNetsRuntimePanel] when the panel is ready.

const LOADING_LABELS: PackedStringArray = [
	"loading.",
	"loading..",
	"loading...",
]
const MINIMUM_LOADING_DISPLAY_TIME := 0.25

@export var visualizer: PointFieldVisualizer:
	get:
		return _visualizer
	set(value):
		set_visualizer(value)

@export var surface_nets_display: SurfaceNetsMeshDisplay:
	get:
		return _surface_nets_display
	set(value):
		set_surface_nets_display(value)

var _visualizer: PointFieldVisualizer
var _surface_nets_display: SurfaceNetsMeshDisplay
var _visualizer_loading: bool = false
var _surface_nets_loading: bool = false
var _loading_frame: int = 0
var _loading_started_at_msec: int = 0
var _loading_hide_generation: int = 0

@onready var _runtime_panel: SurfaceNetsRuntimePanel = %PointFieldRuntimePanel
@onready var _loading_panel: PanelContainer = %LoadingPanel
@onready var _loading_label: Label = %LoadingLabel
@onready var _loading_timer: Timer = %LoadingTimer

func _ready() -> void:
	_loading_timer.timeout.connect(_advance_loading_animation)
	_connect_loading_targets()
	_apply_targets()
	_update_loading_indicator()

func _exit_tree() -> void:
	_disconnect_loading_targets()

func set_visualizer(value: PointFieldVisualizer) -> void:
	if _visualizer == value:
		_apply_targets()
		return
	if is_node_ready():
		_disconnect_visualizer_loading()
	_visualizer = value
	if is_node_ready():
		_connect_visualizer_loading()
		_visualizer_loading = _visualizer != null and _visualizer.is_loading
		_update_loading_indicator()
	_apply_targets()

func set_surface_nets_display(value: SurfaceNetsMeshDisplay) -> void:
	if _surface_nets_display == value:
		_apply_targets()
		return
	if is_node_ready():
		_disconnect_surface_nets_loading()
	_surface_nets_display = value
	if is_node_ready():
		_connect_surface_nets_loading()
		_surface_nets_loading = _surface_nets_display != null and _surface_nets_display.is_loading
		_update_loading_indicator()
	_apply_targets()

func _apply_targets() -> void:
	if not is_node_ready() or _runtime_panel == null:
		return
	_runtime_panel.set_visualizer(_visualizer)
	_runtime_panel.surface_nets_display = _surface_nets_display

func _connect_loading_targets() -> void:
	_connect_visualizer_loading()
	_connect_surface_nets_loading()
	_visualizer_loading = _visualizer != null and _visualizer.is_loading
	_surface_nets_loading = _surface_nets_display != null and _surface_nets_display.is_loading

func _disconnect_loading_targets() -> void:
	_disconnect_visualizer_loading()
	_disconnect_surface_nets_loading()

func _connect_visualizer_loading() -> void:
	if _visualizer == null:
		return
	if not _visualizer.loading_state_changed.is_connected(_on_visualizer_loading_state_changed):
		_visualizer.loading_state_changed.connect(_on_visualizer_loading_state_changed)

func _disconnect_visualizer_loading() -> void:
	if _visualizer == null:
		return
	if _visualizer.loading_state_changed.is_connected(_on_visualizer_loading_state_changed):
		_visualizer.loading_state_changed.disconnect(_on_visualizer_loading_state_changed)

func _connect_surface_nets_loading() -> void:
	if _surface_nets_display == null:
		return
	if not _surface_nets_display.loading_state_changed.is_connected(_on_surface_nets_loading_state_changed):
		_surface_nets_display.loading_state_changed.connect(_on_surface_nets_loading_state_changed)

func _disconnect_surface_nets_loading() -> void:
	if _surface_nets_display == null:
		return
	if _surface_nets_display.loading_state_changed.is_connected(_on_surface_nets_loading_state_changed):
		_surface_nets_display.loading_state_changed.disconnect(_on_surface_nets_loading_state_changed)

func _on_visualizer_loading_state_changed(is_loading: bool) -> void:
	_visualizer_loading = is_loading
	_update_loading_indicator()

func _on_surface_nets_loading_state_changed(is_loading: bool) -> void:
	_surface_nets_loading = is_loading
	_update_loading_indicator()

func _update_loading_indicator() -> void:
	if _visualizer_loading or _surface_nets_loading:
		_show_loading_indicator()
	else:
		_request_loading_indicator_hide()

func _show_loading_indicator() -> void:
	_loading_hide_generation += 1
	if not _loading_panel.visible:
		_loading_started_at_msec = Time.get_ticks_msec()
		_loading_frame = 0
		_loading_label.text = LOADING_LABELS[_loading_frame]
	_loading_panel.visible = true
	if _loading_timer.is_stopped():
		_loading_timer.start()

func _request_loading_indicator_hide() -> void:
	if not _loading_panel.visible:
		return
	_loading_hide_generation += 1
	var request_generation := _loading_hide_generation
	_hide_loading_indicator_after_minimum_time(request_generation)

func _hide_loading_indicator_after_minimum_time(request_generation: int) -> void:
	var elapsed_seconds := (Time.get_ticks_msec() - _loading_started_at_msec) / 1000.0
	var remaining_seconds := maxf(MINIMUM_LOADING_DISPLAY_TIME - elapsed_seconds, 0.0)
	if remaining_seconds > 0.0:
		await get_tree().create_timer(remaining_seconds).timeout
	if request_generation != _loading_hide_generation:
		return
	if _visualizer_loading or _surface_nets_loading:
		return
	_loading_panel.visible = false
	_loading_timer.stop()
	_loading_frame = 0
	_loading_label.text = LOADING_LABELS[0]

func _advance_loading_animation() -> void:
	_loading_frame = (_loading_frame + 1) % LOADING_LABELS.size()
	_loading_label.text = LOADING_LABELS[_loading_frame]
