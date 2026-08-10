@tool
class_name PointFieldVisualizer
extends Node3D

## Visualizes a [PointFieldResource] as billboarded sample points.
##
## Rendering state is derived from the resource. Generated field freshness is
## owned explicitly by PointFieldResource through its dirty flags.


# [b]Visualization Settings[/b]

@export var field: PointFieldResource:
	set(value):
		if field == value:
			return
		_disconnect_field()
		field = value
		_connect_field()
		call_deferred("_synchronize_with_field")

@export var auto_regenerate_field: bool = true:
	set(value):
		if auto_regenerate_field == value:
			return
		auto_regenerate_field = value
		if value and is_inside_tree():
			call_deferred("_synchronize_with_field")

@export var visualize_density: bool = false:
	set(value):
		if visualize_density == value:
			return
		visualize_density = value
		call_deferred("_update_point_colors")

@export_range(0.01, 2.0, 0.01, "or_greater")
var point_size: float = 0.1:
	set(value):
		var sanitized_value := maxf(value, 0.01)
		if is_equal_approx(point_size, sanitized_value):
			return
		point_size = sanitized_value
		call_deferred("_update_point_size")

@export_range(-2.0, 2.0, 0.01, "or_greater", "or_less")
var iso_level: float = 0.0:
	set(value):
		if is_equal_approx(iso_level, value):
			return
		iso_level = value
		call_deferred("_update_point_colors")

@export_range(0.0, 1.0, 0.001, "or_greater")
var iso_highlight_width: float = 0.05:
	set(value):
		var sanitized_value := maxf(value, 0.0)
		if is_equal_approx(iso_highlight_width, sanitized_value):
			return
		iso_highlight_width = sanitized_value
		call_deferred("_update_point_colors")


# [b]Rendering State[/b]

var _point_mesh: MultiMeshInstance3D
var _field_regeneration_queued: bool = false
var _density_regeneration_queued: bool = false


# [b]Lifecycle[/b]

func _enter_tree() -> void:
	_ensure_field()
	_connect_field()
	call_deferred("_synchronize_with_field")


func _exit_tree() -> void:
	_disconnect_field()


# [b]Field Synchronization[/b]

func _ensure_field() -> void:
	if field == null:
		field = PointFieldResource.new()


func _connect_field() -> void:
	if field == null:
		return

	if not field.data_state_changed.is_connected(_on_data_state_changed):
		field.data_state_changed.connect(_on_data_state_changed)
	if not field.positions_changed.is_connected(_on_positions_changed):
		field.positions_changed.connect(_on_positions_changed)
	if not field.densities_changed.is_connected(_on_densities_changed):
		field.densities_changed.connect(_on_densities_changed)


func _disconnect_field() -> void:
	if field == null:
		return

	if field.data_state_changed.is_connected(_on_data_state_changed):
		field.data_state_changed.disconnect(_on_data_state_changed)
	if field.positions_changed.is_connected(_on_positions_changed):
		field.positions_changed.disconnect(_on_positions_changed)
	if field.densities_changed.is_connected(_on_densities_changed):
		field.densities_changed.disconnect(_on_densities_changed)


func _synchronize_with_field() -> void:
	_ensure_field()
	_ensure_visualizer()

	if auto_regenerate_field:
		if field.positions_dirty or not field.validate_data():
			_queue_field_regeneration()
			return
		if field.densities_dirty:
			_queue_density_regeneration()
			return

	_rebuild_from_positions()
	_update_point_colors()


func _queue_field_regeneration() -> void:
	if field == null or _field_regeneration_queued:
		return
	_field_regeneration_queued = true
	call_deferred("_regenerate_field")


func _queue_density_regeneration() -> void:
	if field == null or _density_regeneration_queued:
		return
	_density_regeneration_queued = true
	call_deferred("_regenerate_densities")


func _regenerate_field() -> void:
	_field_regeneration_queued = false
	if field == null:
		return
	if not field.positions_dirty and field.is_data_current():
		return
	field.regenerate()


func _regenerate_densities() -> void:
	_density_regeneration_queued = false
	if field == null or not field.densities_dirty:
		return
	if field.positions_dirty or field.positions.size() != field.sample_count:
		_queue_field_regeneration()
		return
	field.generate_density_field()


func _on_data_state_changed() -> void:
	if not auto_regenerate_field or field == null:
		return
	if field.positions_dirty:
		_queue_field_regeneration()
	elif field.densities_dirty:
		_queue_density_regeneration()


func _on_positions_changed() -> void:
	call_deferred("_rebuild_from_positions")


func _on_densities_changed() -> void:
	call_deferred("_update_point_colors")


# [b]Visualizer Construction[/b]

func _ensure_visualizer() -> void:
	if is_instance_valid(_point_mesh):
		return

	_point_mesh = get_node_or_null("PointFieldDisplay") as MultiMeshInstance3D
	if _point_mesh == null:
		_point_mesh = MultiMeshInstance3D.new()
		_point_mesh.name = "PointFieldDisplay"
		add_child(_point_mesh)

	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * point_size

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.65)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	quad.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	_point_mesh.multimesh = multimesh


# [b]Position Rendering[/b]

func _rebuild_from_positions() -> void:
	_ensure_visualizer()
	if field == null or _point_mesh.multimesh == null:
		return

	var multimesh := _point_mesh.multimesh
	multimesh.instance_count = field.positions.size()

	for index in field.positions.size():
		var instance_transform := Transform3D.IDENTITY
		instance_transform.origin = field.positions[index]
		multimesh.set_instance_transform(index, instance_transform)

	_update_point_colors()


func _update_point_size() -> void:
	_ensure_visualizer()
	if _point_mesh.multimesh == null:
		return

	var quad := _point_mesh.multimesh.mesh as QuadMesh
	if quad != null:
		quad.size = Vector2.ONE * point_size


# [b]Density Rendering[/b]

func _update_point_colors() -> void:
	_ensure_visualizer()
	if field == null or _point_mesh.multimesh == null:
		return

	var multimesh := _point_mesh.multimesh
	if not visualize_density:
		for index in multimesh.instance_count:
			multimesh.set_instance_color(index, Color.SKY_BLUE)
		return

	if field.densities.size() != multimesh.instance_count:
		for index in multimesh.instance_count:
			multimesh.set_instance_color(index, Color.MEDIUM_VIOLET_RED)
		return

	for index in multimesh.instance_count:
		var density := field.densities[index]
		multimesh.set_instance_color(index, _density_to_color(density))


func _density_to_color(density: float) -> Color:
	if absf(density - iso_level) <= iso_highlight_width:
		return Color.WHITE

	var normalized_density := clampf(
		(density - iso_level + 1.0) * 0.5,
		0.0,
		1.0
	)

	if normalized_density < 0.5:
		return Color.BLUE.lerp(Color.WHITE, normalized_density * 2.0)

	return Color.WHITE.lerp(
		Color.RED,
		(normalized_density - 0.5) * 2.0
	)
