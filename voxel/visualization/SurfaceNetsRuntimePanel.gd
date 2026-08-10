@tool
class_name SurfaceNetsRuntimePanel
extends PointFieldRuntimePanel

## Extends the existing point-field runtime controls with Surface Nets display
## settings without making PointFieldVisualizer responsible for mesh generation.

@export var surface_nets_display: SurfaceNetsMeshDisplay:
	set(value):
		surface_nets_display = value
		if is_node_ready():
			_synchronize_controls()

var _display_surface_nets_mesh: CheckBox

func _build_visualization_section(parent: VBoxContainer) -> void:
	super._build_visualization_section(parent)

	var grid := _create_property_grid()
	parent.add_child(grid)

	_display_surface_nets_mesh = CheckBox.new()
	_display_surface_nets_mesh.text = "Enabled"
	_add_property_row(grid, "Surface Nets Mesh", _display_surface_nets_mesh)
	_display_surface_nets_mesh.toggled.connect(_on_display_surface_nets_mesh_toggled)

func _synchronize_controls() -> void:
	super._synchronize_controls()
	if _display_surface_nets_mesh == null:
		return

	_display_surface_nets_mesh.disabled = surface_nets_display == null
	if surface_nets_display != null:
		_is_synchronizing = true
		_display_surface_nets_mesh.button_pressed = surface_nets_display.display_surface_nets_mesh
		_is_synchronizing = false

func _on_display_surface_nets_mesh_toggled(is_enabled: bool) -> void:
	if _is_synchronizing or surface_nets_display == null:
		return
	surface_nets_display.display_surface_nets_mesh = is_enabled

func _on_iso_level_changed(value: float) -> void:
	super._on_iso_level_changed(value)
	if not _is_synchronizing and surface_nets_display != null:
		surface_nets_display.iso_level = value

# Generation-affecting runtime edits explicitly enter the observable request
# path. Resource dirty-state signals remain authoritative for external edits;
# the visualizer's queue coalescing prevents duplicate work here.
func _on_cell_dimensions_changed(value: float) -> void:
	super._on_cell_dimensions_changed(value)
	_request_field_regeneration_if_enabled()

func _on_sample_spacing_changed(value: float) -> void:
	super._on_sample_spacing_changed(value)
	_request_field_regeneration_if_enabled()

func _on_density_scale_changed(value: float) -> void:
	super._on_density_scale_changed(value)
	_request_density_regeneration_if_enabled()

func _on_terrain_base_height_changed(value: float) -> void:
	super._on_terrain_base_height_changed(value)
	_request_density_regeneration_if_enabled()

func _on_terrain_height_scale_changed(value: float) -> void:
	super._on_terrain_height_scale_changed(value)
	_request_density_regeneration_if_enabled()

func _on_noise_type_selected(index: int) -> void:
	super._on_noise_type_selected(index)
	_request_density_regeneration_if_enabled()

func _on_noise_offset_changed(value: float) -> void:
	super._on_noise_offset_changed(value)
	_request_density_regeneration_if_enabled()

func _on_noise_seed_changed(value: float) -> void:
	super._on_noise_seed_changed(value)
	_request_density_regeneration_if_enabled()

func _on_noise_frequency_changed(value: float) -> void:
	super._on_noise_frequency_changed(value)
	_request_density_regeneration_if_enabled()

func _request_field_regeneration_if_enabled() -> void:
	if _is_synchronizing or visualizer == null or not visualizer.auto_regenerate_field:
		return
	visualizer.request_field_regeneration()

func _request_density_regeneration_if_enabled() -> void:
	if _is_synchronizing or visualizer == null or not visualizer.auto_regenerate_field:
		return
	visualizer.request_density_regeneration()

# Route explicit generation through the visualizer so manual work reports busy state.
func _on_regenerate_pressed() -> void:
	if visualizer != null:
		visualizer.request_field_regeneration()

func _on_generate_positions_pressed() -> void:
	if visualizer != null:
		visualizer.request_position_regeneration()

func _on_generate_densities_pressed() -> void:
	if visualizer != null:
		visualizer.request_density_regeneration()

func _on_load_file_selected(path: String) -> void:
	super._on_load_file_selected(path)
	if surface_nets_display != null and visualizer != null:
		surface_nets_display.field = visualizer.field
