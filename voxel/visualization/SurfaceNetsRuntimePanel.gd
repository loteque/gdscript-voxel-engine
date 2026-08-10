@tool
class_name SurfaceNetsRuntimePanel
extends PointFieldRuntimePanel

## Extends the existing point-field runtime controls with Surface Nets display
## settings without making PointFieldVisualizer responsible for mesh generation.


# [b]Constants[/b] Defines the visible loading animation frames.

const LOADING_LABELS: PackedStringArray = [
	"loading.",
	"loading..",
	"loading...",
]


# [b]Target[/b] Identifies the mesh display controlled alongside the point visualizer.

@export var surface_nets_display: SurfaceNetsMeshDisplay:
	set(value):
		if surface_nets_display == value:
			return
		_disconnect_surface_nets_display()
		surface_nets_display = value
		_connect_surface_nets_display()
		if is_node_ready():
			_synchronize_controls()


# [b]Interface State[/b] Stores the Surface Nets visibility control and loading animation.

var _display_surface_nets_mesh: CheckBox
var _loading_animation_timer: Timer
var _loading_animation_frame: int = 0


# [b]Interface Construction[/b] Appends mesh visibility to the existing visualization section.

func _build_visualization_section(parent: VBoxContainer) -> void:
	super._build_visualization_section(parent)

	var grid := _create_property_grid()
	parent.add_child(grid)

	_display_surface_nets_mesh = CheckBox.new()
	_display_surface_nets_mesh.text = "enabled"
	_add_property_row(grid, "Surface Nets Mesh", _display_surface_nets_mesh)
	_display_surface_nets_mesh.toggled.connect(
		_on_display_surface_nets_mesh_toggled
	)

	_loading_animation_timer = Timer.new()
	_loading_animation_timer.wait_time = 0.35
	_loading_animation_timer.timeout.connect(_advance_loading_animation)
	add_child(_loading_animation_timer)


# [b]Synchronization[/b] Mirrors mesh-display state without feeding UI changes back.

func _synchronize_controls() -> void:
	super._synchronize_controls()

	if _display_surface_nets_mesh == null:
		return

	_display_surface_nets_mesh.disabled = surface_nets_display == null
	if surface_nets_display == null:
		_set_loading_indicator(false)
		return

	_is_synchronizing = true
	_display_surface_nets_mesh.button_pressed = (
		surface_nets_display.display_surface_nets_mesh
	)
	_is_synchronizing = false
	_set_loading_indicator(surface_nets_display.is_loading)


# [b]Mesh Display Editing[/b] Applies shared iso-level and visibility settings.

func _on_display_surface_nets_mesh_toggled(is_enabled: bool) -> void:
	if _is_synchronizing or surface_nets_display == null:
		return

	surface_nets_display.display_surface_nets_mesh = is_enabled


func _on_iso_level_changed(value: float) -> void:
	super._on_iso_level_changed(value)

	if not _is_synchronizing and surface_nets_display != null:
		surface_nets_display.iso_level = value


# [b]Loading State[/b] Reflects mesh generation without making the panel own meshing work.

func _connect_surface_nets_display() -> void:
	if surface_nets_display == null:
		return

	if not surface_nets_display.loading_state_changed.is_connected(
		_on_surface_nets_loading_state_changed
	):
		surface_nets_display.loading_state_changed.connect(
			_on_surface_nets_loading_state_changed
		)


func _disconnect_surface_nets_display() -> void:
	if surface_nets_display == null:
		return

	if surface_nets_display.loading_state_changed.is_connected(
		_on_surface_nets_loading_state_changed
	):
		surface_nets_display.loading_state_changed.disconnect(
			_on_surface_nets_loading_state_changed
		)


func _on_surface_nets_loading_state_changed(is_loading: bool) -> void:
	_set_loading_indicator(is_loading)


func _set_loading_indicator(is_loading: bool) -> void:
	if _display_surface_nets_mesh == null:
		return

	if not is_loading:
		if _loading_animation_timer != null:
			_loading_animation_timer.stop()
		_loading_animation_frame = 0
		_display_surface_nets_mesh.text = "enabled"
		return

	_loading_animation_frame = 0
	_display_surface_nets_mesh.text = LOADING_LABELS[_loading_animation_frame]
	if _loading_animation_timer != null:
		_loading_animation_timer.start()


func _advance_loading_animation() -> void:
	if _display_surface_nets_mesh == null:
		return

	_loading_animation_frame = (
		(_loading_animation_frame + 1) % LOADING_LABELS.size()
	)
	_display_surface_nets_mesh.text = LOADING_LABELS[_loading_animation_frame]


# [b]Field Replacement[/b] Keeps the mesh consumer on the field loaded by the viewer.

func _on_load_file_selected(path: String) -> void:
	super._on_load_file_selected(path)

	if surface_nets_display != null and visualizer != null:
		surface_nets_display.field = visualizer.field
