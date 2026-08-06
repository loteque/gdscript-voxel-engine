@tool
class_name PointFieldRuntimePanel
extends PanelContainer

## Provides an in-scene control panel for editing a point field and its
## visualization while the project is running.
##
## Assign [member visualizer] to a [PointFieldVisualizer] in the scene. The
## panel edits the visualizer's authoritative [PointFieldResource] rather than
## storing a second copy of field settings.


# [b]Target[/b] Identifies the visualizer and point field controlled by this panel.

## The point-field visualizer controlled by this runtime panel.
@export var visualizer: PointFieldVisualizer:
	get:
		return _visualizer
	set(value):
		set_visualizer(value)

var _visualizer: PointFieldVisualizer

## Whether the panel is visible when the scene starts.
@export var initially_visible: bool = true

## The minimum width of the runtime panel in pixels.
@export_range(200.0, 1000.0, 1.0, "or_greater")
var panel_width: float = 360.0


# [b]Interface State[/b] Stores controls that must be synchronized with field data.

var _cell_x: SpinBox
var _cell_y: SpinBox
var _cell_z: SpinBox
var _sample_spacing: SpinBox
var _density_scale: SpinBox
var _noise_type: OptionButton
var _noise_seed: SpinBox
var _noise_frequency: SpinBox
var _noise_offset_x: SpinBox
var _noise_offset_y: SpinBox
var _noise_offset_z: SpinBox

var _visualize_density: CheckBox
var _auto_regenerate: CheckBox
var _point_size: SpinBox
var _iso_level: SpinBox
var _iso_highlight_width: SpinBox

var _size_value: Label
var _cell_count_value: Label
var _sample_dimensions_value: Label
var _sample_count_value: Label
var _data_state_value: Label
var _save_file_dialog: FileDialog
var _load_file_dialog: FileDialog

var _is_synchronizing: bool = false


# [b]Lifecycle[/b] Builds the runtime interface and connects it to the target resource.

func _ready() -> void:
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	visible = initially_visible
	_build_interface()
	_connect_target()
	_synchronize_controls()


func _exit_tree() -> void:
	_disconnect_target()


# [b]Interface Construction[/b] Creates a compact scrollable editor from standard controls.

func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var margin := 16.0

	position = Vector2(margin, margin)

	size = Vector2(
		minf(viewport_size.x * 0.3, 400.0),
		viewport_size.y - margin * 2.0
	)


func _build_interface() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	
	var scroll_container := ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	margin.add_child(scroll_container)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll_container.add_child(content)

	var title := Label.new()
	title.text = "Point Field Controls"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	content.add_child(HSeparator.new())
	_build_geometry_section(content)
	content.add_child(HSeparator.new())
	_build_density_section(content)
	content.add_child(HSeparator.new())
	_build_visualization_section(content)
	content.add_child(HSeparator.new())
	_build_actions_section(content)
	content.add_child(HSeparator.new())
	_build_status_section(content)


func _build_geometry_section(parent: VBoxContainer) -> void:
	parent.add_child(_create_section_label("Field Geometry"))

	var grid := _create_property_grid()
	parent.add_child(grid)

	_cell_x = _create_spin_box(1.0, 512.0, 1.0, true)
	_cell_y = _create_spin_box(1.0, 512.0, 1.0, true)
	_cell_z = _create_spin_box(1.0, 512.0, 1.0, true)
	_sample_spacing = _create_spin_box(0.001, 1000.0, 0.01)

	_add_property_row(grid, "Cells X", _cell_x)
	_add_property_row(grid, "Cells Y", _cell_y)
	_add_property_row(grid, "Cells Z", _cell_z)
	_add_property_row(grid, "Sample Spacing", _sample_spacing)

	_cell_x.value_changed.connect(_on_cell_dimensions_changed)
	_cell_y.value_changed.connect(_on_cell_dimensions_changed)
	_cell_z.value_changed.connect(_on_cell_dimensions_changed)
	_sample_spacing.value_changed.connect(_on_sample_spacing_changed)


func _build_density_section(parent: VBoxContainer) -> void:
	parent.add_child(_create_section_label("Density Generation"))

	var grid := _create_property_grid()
	parent.add_child(grid)

	_density_scale = _create_spin_box(0.0001, 1000.0, 0.01)
	_noise_type = OptionButton.new()
	_noise_type.add_item("Simplex", FastNoiseLite.TYPE_SIMPLEX)
	_noise_type.add_item("Simplex Smooth", FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	_noise_type.add_item("Cellular", FastNoiseLite.TYPE_CELLULAR)
	_noise_type.add_item("Perlin", FastNoiseLite.TYPE_PERLIN)
	_noise_type.add_item("Value Cubic", FastNoiseLite.TYPE_VALUE_CUBIC)
	_noise_type.add_item("Value", FastNoiseLite.TYPE_VALUE)
	_noise_offset_x = _create_spin_box(-100000.0, 100000.0, 0.1)
	_noise_offset_y = _create_spin_box(-100000.0, 100000.0, 0.1)
	_noise_offset_z = _create_spin_box(-100000.0, 100000.0, 0.1)
	_noise_seed = _create_spin_box(-2147483648.0, 2147483647.0, 1.0, true)
	_noise_frequency = _create_spin_box(0.0001, 10.0, 0.001)

	_add_property_row(grid, "Density Scale", _density_scale)
	_add_property_row(grid, "Noise Type", _noise_type)
	_add_property_row(grid, "Noise Offset X", _noise_offset_x)
	_add_property_row(grid, "Noise Offset Y", _noise_offset_y)
	_add_property_row(grid, "Noise Offset Z", _noise_offset_z)
	_add_property_row(grid, "Noise Seed", _noise_seed)
	_add_property_row(grid, "Noise Frequency", _noise_frequency)

	_density_scale.value_changed.connect(_on_density_scale_changed)
	_noise_type.item_selected.connect(_on_noise_type_selected)
	_noise_offset_x.value_changed.connect(_on_noise_offset_changed)
	_noise_offset_y.value_changed.connect(_on_noise_offset_changed)
	_noise_offset_z.value_changed.connect(_on_noise_offset_changed)
	_noise_seed.value_changed.connect(_on_noise_seed_changed)
	_noise_frequency.value_changed.connect(_on_noise_frequency_changed)


func _build_visualization_section(parent: VBoxContainer) -> void:
	parent.add_child(_create_section_label("Visualization"))

	var grid := _create_property_grid()
	parent.add_child(grid)

	_visualize_density = CheckBox.new()
	_visualize_density.text = "Enabled"
	_auto_regenerate = CheckBox.new()
	_auto_regenerate.text = "Enabled"
	_point_size = _create_spin_box(0.01, 10.0, 0.01)
	_iso_level = _create_spin_box(-1000.0, 1000.0, 0.01)
	_iso_highlight_width = _create_spin_box(0.0, 1000.0, 0.001)

	_add_property_row(grid, "Density Colors", _visualize_density)
	_add_property_row(grid, "Auto Regenerate", _auto_regenerate)
	_add_property_row(grid, "Point Size", _point_size)
	_add_property_row(grid, "Iso Level", _iso_level)
	_add_property_row(grid, "Iso Highlight", _iso_highlight_width)

	_visualize_density.toggled.connect(_on_visualize_density_toggled)
	_auto_regenerate.toggled.connect(_on_auto_regenerate_toggled)
	_point_size.value_changed.connect(_on_point_size_changed)
	_iso_level.value_changed.connect(_on_iso_level_changed)
	_iso_highlight_width.value_changed.connect(_on_iso_highlight_width_changed)


func _build_actions_section(parent: VBoxContainer) -> void:
	parent.add_child(_create_section_label("Generation"))

	var first_row := HBoxContainer.new()
	first_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(first_row)

	var regenerate_button := Button.new()
	regenerate_button.text = "Regenerate All"
	regenerate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	regenerate_button.pressed.connect(_on_regenerate_pressed)
	first_row.add_child(regenerate_button)

	var positions_button := Button.new()
	positions_button.text = "Positions"
	positions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	positions_button.pressed.connect(_on_generate_positions_pressed)
	first_row.add_child(positions_button)

	var second_row := HBoxContainer.new()
	second_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(second_row)

	var densities_button := Button.new()
	densities_button.text = "Densities"
	densities_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	densities_button.pressed.connect(_on_generate_densities_pressed)
	second_row.add_child(densities_button)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_button.pressed.connect(_on_clear_pressed)
	second_row.add_child(clear_button)
	
	var third_row := HBoxContainer.new()
	second_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(third_row)
	
	var save_button = Button.new()
	save_button.text = "Save Field"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save_button_pressed)
	third_row.add_child(save_button)

	var load_button = Button.new()
	load_button.text = "Load Field"
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(_on_load_button_pressed)
	third_row.add_child(load_button)


func _build_status_section(parent: VBoxContainer) -> void:
	parent.add_child(_create_section_label("Field Status"))

	var grid := _create_property_grid()
	parent.add_child(grid)

	_size_value = Label.new()
	_cell_count_value = Label.new()
	_sample_dimensions_value = Label.new()
	_sample_count_value = Label.new()
	_data_state_value = Label.new()

	_add_property_row(grid, "World Size", _size_value)
	_add_property_row(grid, "Cell Count", _cell_count_value)
	_add_property_row(grid, "Sample Dimensions", _sample_dimensions_value)
	_add_property_row(grid, "Sample Count", _sample_count_value)
	_add_property_row(grid, "Data", _data_state_value)


func _create_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	return label


func _create_property_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	return grid


func _create_spin_box(
	minimum: float,
	maximum: float,
	step: float,
	integer_value: bool = false
) -> SpinBox:
	var spin_box := SpinBox.new()
	spin_box.min_value = minimum
	spin_box.max_value = maximum
	spin_box.step = step
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_box.update_on_text_changed = true

	if integer_value:
		spin_box.rounded = true

	return spin_box


func _add_property_row(
	grid: GridContainer,
	property_name: String,
	control: Control
) -> void:
	var label := Label.new()
	label.text = property_name
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid.add_child(label)
	grid.add_child(control)


# [b]Target Connections[/b] Observes authoritative field changes and refreshes runtime controls.

## Changes the visualizer controlled by this panel.
func set_visualizer(value: PointFieldVisualizer) -> void:
	if _visualizer == value:
		if is_node_ready():
			_synchronize_controls()
		return

	if is_node_ready():
		_disconnect_target()

	_visualizer = value

	if is_node_ready():
		_connect_target()
		_synchronize_controls()


func _connect_target() -> void:
	var field := _get_field()
	if field == null:
		return

	if not field.geometry_configuration_changed.is_connected(_on_field_changed):
		field.geometry_configuration_changed.connect(_on_field_changed)

	if not field.positions_changed.is_connected(_on_field_changed):
		field.positions_changed.connect(_on_field_changed)

	if not field.densities_changed.is_connected(_on_field_changed):
		field.densities_changed.connect(_on_field_changed)


func _disconnect_target() -> void:
	var field := _get_field()
	if field == null:
		return

	if field.geometry_configuration_changed.is_connected(_on_field_changed):
		field.geometry_configuration_changed.disconnect(_on_field_changed)

	if field.positions_changed.is_connected(_on_field_changed):
		field.positions_changed.disconnect(_on_field_changed)

	if field.densities_changed.is_connected(_on_field_changed):
		field.densities_changed.disconnect(_on_field_changed)


func _get_field() -> PointFieldResource:
	if visualizer == null:
		return null
	return visualizer.field


func _ensure_noise() -> FastNoiseLite:
	var field := _get_field()
	if field == null:
		return null

	if field.noise == null:
		field.noise = FastNoiseLite.new()

	return field.noise


# [b]Synchronization[/b] Mirrors authoritative values into controls without feeding changes back.

func _select_noise_type(noise_type: FastNoiseLite.NoiseType) -> void:
	for i in _noise_type.item_count:
		if _noise_type.get_item_id(i) == noise_type:
			_noise_type.select(i)
			break


func _synchronize_controls() -> void:
	var field := _get_field()
	if field == null or visualizer == null:
		_set_controls_enabled(false)
		_update_missing_target_status()
		return

	_set_controls_enabled(true)
	_is_synchronizing = true

	_cell_x.value = field.cell_dimensions.x
	_cell_y.value = field.cell_dimensions.y
	_cell_z.value = field.cell_dimensions.z
	_sample_spacing.value = field.sample_spacing
	_density_scale.value = field.density_scale

	var noise := _ensure_noise()
	if noise != null:
		_select_noise_type(noise.noise_type)
		_noise_seed.value = noise.seed
		_noise_frequency.value = noise.frequency
		_noise_offset_x.value = noise.offset.x
		_noise_offset_y.value = noise.offset.y
		_noise_offset_z.value = noise.offset.z
	
	_visualize_density.button_pressed = visualizer.visualize_density
	_auto_regenerate.button_pressed = visualizer.auto_regenerate_field
	_point_size.value = visualizer.point_size
	_iso_level.value = visualizer.iso_level
	_iso_highlight_width.value = visualizer.iso_highlight_width

	_is_synchronizing = false
	_update_status()


func _set_controls_enabled(is_enabled: bool) -> void:
	for spin_box in [
		_cell_x,
		_cell_y,
		_cell_z,
		_sample_spacing,
		_density_scale,
		_noise_seed,
		_noise_frequency,
		_point_size,
		_iso_level,
		_iso_highlight_width,
	]:
		if spin_box != null:
			spin_box.editable = is_enabled

	for check_box in [_visualize_density, _auto_regenerate]:
		if check_box != null:
			check_box.disabled = not is_enabled


func _update_status() -> void:
	var field := _get_field()
	if field == null:
		_update_missing_target_status()
		return

	_size_value.text = _format_vector3(field.size)
	_cell_count_value.text = str(field.cell_count)
	_sample_dimensions_value.text = str(field.sample_dimensions)
	_sample_count_value.text = str(field.sample_count)

	if field.validate_data():
		_data_state_value.text = "Valid"
	elif field.positions.size() == field.sample_count:
		_data_state_value.text = "Densities invalid"
	elif field.positions.is_empty() and field.densities.is_empty():
		_data_state_value.text = "Not generated"
	else:
		_data_state_value.text = "Invalid"


func _update_missing_target_status() -> void:
	if _size_value == null:
		return

	_size_value.text = "No visualizer assigned"
	_cell_count_value.text = "-"
	_sample_dimensions_value.text = "-"
	_sample_count_value.text = "-"
	_data_state_value.text = "Unavailable"


func _format_vector3(value: Vector3) -> String:
	return "(%0.3f, %0.3f, %0.3f)" % [value.x, value.y, value.z]


# [b]Field Editing[/b] Applies runtime geometry and density settings to the resource.

func _on_cell_dimensions_changed(_value: float) -> void:
	if _is_synchronizing:
		return

	var field := _get_field()
	if field == null:
		return

	field.cell_dimensions = Vector3i(
		roundi(_cell_x.value),
		roundi(_cell_y.value),
		roundi(_cell_z.value)
	)
	_update_status()


func _on_sample_spacing_changed(value: float) -> void:
	if _is_synchronizing:
		return

	var field := _get_field()
	if field != null:
		field.sample_spacing = value
		_update_status()


func _on_density_scale_changed(value: float) -> void:
	if _is_synchronizing:
		return

	var field := _get_field()
	if field != null:
		field.density_scale = value
		_update_status()


func _on_noise_type_selected(index: int) -> void:
	if _is_synchronizing:
		return

	var noise := _ensure_noise()
	if noise == null:
		return

	noise.noise_type = _noise_type.get_item_id(index)


func _on_noise_offset_changed(_value: float) -> void:
	if _is_synchronizing:
		return

	var noise := _ensure_noise()
	if noise == null:
		return

	noise.offset = Vector3(
		_noise_offset_x.value,
		_noise_offset_y.value,
		_noise_offset_z.value
	)


func _on_noise_seed_changed(value: float) -> void:
	if _is_synchronizing:
		return

	var noise := _ensure_noise()
	if noise != null:
		noise.seed = roundi(value)


func _on_noise_frequency_changed(value: float) -> void:
	if _is_synchronizing:
		return

	var noise := _ensure_noise()
	if noise != null:
		noise.frequency = value


# [b]Visualizer Editing[/b] Applies runtime rendering settings to the visualizer.

func _on_visualize_density_toggled(is_enabled: bool) -> void:
	if not _is_synchronizing and visualizer != null:
		visualizer.visualize_density = is_enabled


func _on_auto_regenerate_toggled(is_enabled: bool) -> void:
	if not _is_synchronizing and visualizer != null:
		visualizer.auto_regenerate_field = is_enabled


func _on_point_size_changed(value: float) -> void:
	if not _is_synchronizing and visualizer != null:
		visualizer.point_size = value


func _on_iso_level_changed(value: float) -> void:
	if not _is_synchronizing and visualizer != null:
		visualizer.iso_level = value


func _on_iso_highlight_width_changed(value: float) -> void:
	if not _is_synchronizing and visualizer != null:
		visualizer.iso_highlight_width = value


# [b]File Operations[/b]
# Saves the active point field to disk.

func _on_save_field_pressed() -> void:
	_save_file_dialog.popup_centered_ratio(0.6)


func _on_save_button_pressed() -> void:
	_save_file_dialog = FileDialog.new()
	_save_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_save_file_dialog.filters = PackedStringArray([
	"*.tres ; Godot Resource"
	])
	_save_file_dialog.current_file = "point_field.tres"
	
	_save_file_dialog.file_selected.connect(_on_save_file_selected)
	
	add_child(_save_file_dialog)
	_save_file_dialog.popup_centered(Vector2i(900, 600))


func _on_save_file_selected(path: String) -> void:
	if visualizer == null:
		return

	if visualizer.field == null:
		return

	var error := ResourceSaver.save(
		visualizer.field,
		path
	)

	if error != OK:
		push_error("Failed to save field.")


func _on_load_button_pressed() -> void:
	_load_file_dialog = FileDialog.new()
	_load_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_load_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_load_file_dialog.filters = PackedStringArray([
	"*.tres ; Point Field Resource"
])

	_load_file_dialog.file_selected.connect(_on_load_file_selected)

	add_child(_load_file_dialog)
	_load_file_dialog.popup_centered(Vector2i(900, 600))
	
	
func _on_load_file_selected(path: String) -> void:
	var resource := ResourceLoader.load(path)

	if resource == null:
		push_error("Failed to load point field.")
		return

	if resource is not PointFieldResource:
		push_error("Selected resource is not a PointFieldResource.")
		return

	visualizer.field = resource


# [b]Generation Actions[/b] Invokes explicit field lifecycle operations from the panel.

func _on_regenerate_pressed() -> void:
	var field := _get_field()
	if field != null:
		field.regenerate()


func _on_generate_positions_pressed() -> void:
	var field := _get_field()
	if field != null:
		field.generate_positions()


func _on_generate_densities_pressed() -> void:
	var field := _get_field()
	if field != null:
		field.generate_density_field()


func _on_clear_pressed() -> void:
	var field := _get_field()
	if field != null:
		field.clear()


func _on_field_changed() -> void:
	call_deferred("_synchronize_controls")
