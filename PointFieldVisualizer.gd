@tool
class_name PointFieldVisualizer
extends Node3D

## Visualizes a [PointFieldResource] as billboarded sample points.
##
## This node owns rendering only. Field geometry, positions, densities, indexing,
## and noise generation remain authoritative responsibilities of the assigned
## [member field].


# [b]Visualization Settings[/b] Controls how field samples appear without modifying field data.

## The point field displayed by this visualizer.
@export var field: PointFieldResource:
	set(value):
		if field == value:
			return
		_disconnect_field()
		field = value
		_connect_field()
		call_deferred("_synchronize_with_field")

## Regenerates invalidated field channels when resource configuration changes.
@export var auto_regenerate_field: bool = true

## Colors points from blue through white to red according to sample density.
## Density visualization:
## - [color=blue]Blue[/color]: Density < iso_level
## - [color=white]White[/color]: Density = iso_level
## - [color=red]Red[/color]: Density > iso_level
@export var visualize_density: bool = false:
	set(value):
		if visualize_density == value:
			return
		visualize_density = value
		call_deferred("_update_point_colors")

## The rendered width and height of each billboarded sample point.
@export_range(0.01, 2.0, 0.01, "or_greater")
var point_size: float = 0.1:
	set(value):
		var sanitized_value := maxf(value, 0.01)
		if is_equal_approx(point_size, sanitized_value):
			return
		point_size = sanitized_value
		call_deferred("_update_point_size")

## The density value at which the isosurface is extracted.
## Density visualization:
## - [color=blue]Blue[/color]: Density < iso_level
## - [color=white]White[/color]: Density = iso_level
## - [color=red]Red[/color]: Density > iso_level
@export_range(-2.0, 2.0, 0.01, "or_greater", "or_less")
var iso_level: float = 0.0:
	set(value):
		if is_equal_approx(iso_level, value):
			return
		iso_level = value
		call_deferred("_update_point_colors")

## Density distance from [member iso_level] highlighted as the surface band.
@export_range(0.0, 1.0, 0.001, "or_greater")
var iso_highlight_width: float = 0.05:
	set(value):
		var sanitized_value := maxf(value, 0.0)
		if is_equal_approx(iso_highlight_width, sanitized_value):
			return
		iso_highlight_width = sanitized_value
		call_deferred("_update_point_colors")


# [b]Rendering State[/b] Stores transient scene objects used to draw the resource.

var _point_mesh: MultiMeshInstance3D


# [b]Lifecycle[/b] Creates rendering state and synchronizes it with the assigned resource.

func _enter_tree() -> void:
	_ensure_field()
	_connect_field()
	call_deferred("_synchronize_with_field")


func _exit_tree() -> void:
	_disconnect_field()


# [b]Field Synchronization[/b] Reacts to resource changes without duplicating field state.

func _ensure_field() -> void:
	if field == null:
		field = PointFieldResource.new()


func _connect_field() -> void:
	if field == null:
		return

	if not field.geometry_configuration_changed.is_connected(
		_on_geometry_configuration_changed
	):
		field.geometry_configuration_changed.connect(
			_on_geometry_configuration_changed
		)

	if not field.positions_changed.is_connected(_on_positions_changed):
		field.positions_changed.connect(_on_positions_changed)

	if not field.densities_changed.is_connected(_on_densities_changed):
		field.densities_changed.connect(_on_densities_changed)


func _disconnect_field() -> void:
	if field == null:
		return

	if field.geometry_configuration_changed.is_connected(
		_on_geometry_configuration_changed
	):
		field.geometry_configuration_changed.disconnect(
			_on_geometry_configuration_changed
		)

	if field.positions_changed.is_connected(_on_positions_changed):
		field.positions_changed.disconnect(_on_positions_changed)

	if field.densities_changed.is_connected(_on_densities_changed):
		field.densities_changed.disconnect(_on_densities_changed)


func _synchronize_with_field() -> void:
	_ensure_field()
	_ensure_visualizer()

	if auto_regenerate_field and not field.validate_data():
		field.regenerate()
		return

	_rebuild_from_positions()
	_update_point_colors()


func _regenerate_field() -> void:
	if field == null:
		return
	field.regenerate()


func _regenerate_densities() -> void:
	if field == null or field.positions.size() != field.sample_count:
		return
	field.generate_density_field()


func _on_geometry_configuration_changed() -> void:
	if auto_regenerate_field:
		call_deferred("_regenerate_field")
	else:
		call_deferred("_rebuild_from_positions")


func _on_positions_changed() -> void:
	call_deferred("_rebuild_from_positions")


func _on_densities_changed() -> void:
	if (
		auto_regenerate_field
		and field != null
		and field.positions.size() == field.sample_count
		and field.densities.size() != field.sample_count
	):
		call_deferred("_regenerate_densities")
		return

	call_deferred("_update_point_colors")


# [b]Visualizer Construction[/b] Builds the billboard mesh and MultiMesh used for sample rendering.

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


# [b]Position Rendering[/b] Converts packed sample positions into MultiMesh transforms.

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


# [b]Density Rendering[/b] Maps scalar density values to per-instance debug colors.

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
		var color := _density_to_color(density)
		multimesh.set_instance_color(index, color)


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
