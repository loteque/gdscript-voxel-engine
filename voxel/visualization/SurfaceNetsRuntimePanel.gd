@tool
class_name SurfaceNetsRuntimePanel
extends PointFieldRuntimePanel

## Extends the existing point-field runtime controls with Surface Nets display
## settings without making PointFieldVisualizer responsible for mesh generation.


# [b]Target[/b] Identifies the mesh display controlled alongside the point visualizer.

@export var surface_nets_display: SurfaceNetsMeshDisplay:
	set(value):
		surface_nets_display = value
		if is_node_ready():
			_synchronize_controls()


# [b]Interface State[/b] Stores the Surface Nets visibility control.

var _display_surface_nets_mesh: CheckBox


# [b]Interface Construction[/b] Appends mesh visibility to the existing visualization section.

func _build_visualization_section(parent: VBoxContainer) -> void:
	super._build_visualization_section(parent)

	var grid := _create_property_grid()
	parent.add_child(grid)

	_display_surface_nets_mesh = CheckBox.new()
	_display_surface_nets_mesh.text = "Enabled"
	_add_property_row(grid, "Surface Nets Mesh", _display_surface_nets_mesh)
	_display_surface_nets_mesh.toggled.connect(
		_on_display_surface_nets_mesh_toggled
	)


# [b]Synchronization[/b] Mirrors mesh-display state without feeding UI changes back.

func _synchronize_controls() -> void:
	super._synchronize_controls()

	if _display_surface_nets_mesh == null:
		return

	_display_surface_nets_mesh.disabled = surface_nets_display == null
	if surface_nets_display != null:
		_is_synchronizing = true
		_display_surface_nets_mesh.button_pressed = (
			surface_nets_display.display_surface_nets_mesh
		)
		_is_synchronizing = false


# [b]Mesh Display Editing[/b] Applies shared iso-level and visibility settings.

func _on_display_surface_nets_mesh_toggled(is_enabled: bool) -> void:
	if _is_synchronizing or surface_nets_display == null:
		return

	surface_nets_display.display_surface_nets_mesh = is_enabled


func _on_iso_level_changed(value: float) -> void:
	super._on_iso_level_changed(value)

	if not _is_synchronizing and surface_nets_display != null:
		surface_nets_display.iso_level = value


# [b]Field Replacement[/b] Keeps the mesh consumer on the field loaded by the viewer.

func _on_load_file_selected(path: String) -> void:
	super._on_load_file_selected(path)

	if surface_nets_display != null and visualizer != null:
		surface_nets_display.field = visualizer.field
