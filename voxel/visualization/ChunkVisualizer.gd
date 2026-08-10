@tool
class_name ChunkVisualizer
extends MeshInstance3D

## Draws chunk-space diagnostics for a [ChunkManager] in the editor and runtime.
##
## This visualizer never creates chunks, generates density fields, or meshes
## terrain. It consumes only chunk layout information and lifecycle signals.
## A preview grid can be shown before runtime chunks exist, making planned chunk
## extents visible directly in the Godot editor.


# [b]Visualization Configuration[/b]

@export var chunk_manager: ChunkManager:
	set(value):
		if chunk_manager == value:
			return
		_disconnect_manager()
		chunk_manager = value
		_connect_manager()
		_queue_rebuild()

## Draws bounds for chunk instances currently owned by the manager.
@export var show_loaded_chunks: bool = true:
	set(value):
		if show_loaded_chunks == value:
			return
		show_loaded_chunks = value
		_queue_rebuild()

## Draws the intended centered grid even when those chunks do not exist yet.
@export var show_preview_grid: bool = true:
	set(value):
		if show_preview_grid == value:
			return
		show_preview_grid = value
		_queue_rebuild()

## Preview dimensions expressed in chunks, not cells or samples.
@export var preview_grid_dimensions: Vector3i = Vector3i(3, 1, 3):
	set(value):
		var sanitized := Vector3i(
			maxi(value.x, 1),
			maxi(value.y, 1),
			maxi(value.z, 1)
		)
		if preview_grid_dimensions == sanitized:
			return
		preview_grid_dimensions = sanitized
		_queue_rebuild()

## Draws a small cross through the center of each loaded chunk.
@export var show_chunk_centers: bool = true:
	set(value):
		if show_chunk_centers == value:
			return
		show_chunk_centers = value
		_queue_rebuild()

@export var loaded_chunk_color: Color = Color(0.2, 0.85, 1.0, 1.0):
	set(value):
		loaded_chunk_color = value
		_queue_rebuild()

@export var preview_chunk_color: Color = Color(0.45, 0.55, 0.7, 0.55):
	set(value):
		preview_chunk_color = value
		_queue_rebuild()

## Keeps diagnostic lines readable through terrain surfaces.
@export var xray_bounds: bool = true:
	set(value):
		if xray_bounds == value:
			return
		xray_bounds = value
		_queue_rebuild()


# [b]Visualization State[/b]

var _rebuild_queued: bool = false
var _visualized_loaded_chunk_count: int = 0
var _visualized_preview_cell_count: int = 0


# [b]Lifecycle[/b]

func _enter_tree() -> void:
	_connect_manager()
	_queue_rebuild()


func _exit_tree() -> void:
	_disconnect_manager()


# [b]Public API[/b]

## Immediately rebuilds all chunk diagnostic geometry.
func rebuild() -> void:
	_rebuild_queued = false
	_visualized_loaded_chunk_count = 0
	_visualized_preview_cell_count = 0

	if chunk_manager == null:
		mesh = null
		return

	var immediate_mesh := ImmediateMesh.new()

	if show_preview_grid:
		var preview_coordinates := _get_preview_coordinates()
		_draw_chunk_set(
			immediate_mesh,
			preview_coordinates,
			_create_line_material(preview_chunk_color),
			false
		)
		_visualized_preview_cell_count = preview_coordinates.size()

	if show_loaded_chunks:
		var loaded_coordinates := chunk_manager.get_chunk_coordinates()
		_draw_chunk_set(
			immediate_mesh,
			loaded_coordinates,
			_create_line_material(loaded_chunk_color),
			show_chunk_centers
		)
		_visualized_loaded_chunk_count = loaded_coordinates.size()

	mesh = immediate_mesh if immediate_mesh.get_surface_count() > 0 else null


func get_visualized_loaded_chunk_count() -> int:
	return _visualized_loaded_chunk_count


func get_visualized_preview_cell_count() -> int:
	return _visualized_preview_cell_count


# [b]Manager Synchronization[/b]

func _connect_manager() -> void:
	if chunk_manager == null:
		return
	if not chunk_manager.chunk_added.is_connected(_on_chunk_layout_changed):
		chunk_manager.chunk_added.connect(_on_chunk_layout_changed)
	if not chunk_manager.chunk_removed.is_connected(_on_chunk_removed):
		chunk_manager.chunk_removed.connect(_on_chunk_removed)
	if not chunk_manager.chunk_layout_changed.is_connected(_on_chunk_layout_changed):
		chunk_manager.chunk_layout_changed.connect(_on_chunk_layout_changed)


func _disconnect_manager() -> void:
	if chunk_manager == null:
		return
	if chunk_manager.chunk_added.is_connected(_on_chunk_layout_changed):
		chunk_manager.chunk_added.disconnect(_on_chunk_layout_changed)
	if chunk_manager.chunk_removed.is_connected(_on_chunk_removed):
		chunk_manager.chunk_removed.disconnect(_on_chunk_removed)
	if chunk_manager.chunk_layout_changed.is_connected(_on_chunk_layout_changed):
		chunk_manager.chunk_layout_changed.disconnect(_on_chunk_layout_changed)


func _on_chunk_layout_changed(_chunk: TerrainChunk = null) -> void:
	_queue_rebuild()


func _on_chunk_removed(_coordinate: Vector3i) -> void:
	_queue_rebuild()


# [b]Deferred Rebuilds[/b]

func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("rebuild")


# [b]Preview Layout[/b]

func _get_preview_coordinates() -> Array[Vector3i]:
	var minimum := Vector3i(
		-floori(float(preview_grid_dimensions.x) * 0.5),
		-floori(float(preview_grid_dimensions.y) * 0.5),
		-floori(float(preview_grid_dimensions.z) * 0.5)
	)
	var coordinates: Array[Vector3i] = []

	for z in preview_grid_dimensions.z:
		for y in preview_grid_dimensions.y:
			for x in preview_grid_dimensions.x:
				coordinates.append(minimum + Vector3i(x, y, z))

	return coordinates


# [b]Line Geometry[/b]

func _draw_chunk_set(
	immediate_mesh: ImmediateMesh,
	coordinates: Array[Vector3i],
	material: Material,
	draw_centers: bool
) -> void:
	if coordinates.is_empty():
		return

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for coordinate in coordinates:
		_draw_chunk_bounds(immediate_mesh, coordinate)
		if draw_centers:
			_draw_chunk_center(immediate_mesh, coordinate)
	immediate_mesh.surface_end()


func _draw_chunk_bounds(immediate_mesh: ImmediateMesh, coordinate: Vector3i) -> void:
	var origin := chunk_manager.chunk_coordinate_to_local_origin(coordinate)
	var extent := chunk_manager.chunk_extent
	var corners: Array[Vector3] = [
		origin,
		origin + Vector3(extent.x, 0.0, 0.0),
		origin + Vector3(0.0, extent.y, 0.0),
		origin + Vector3(extent.x, extent.y, 0.0),
		origin + Vector3(0.0, 0.0, extent.z),
		origin + Vector3(extent.x, 0.0, extent.z),
		origin + Vector3(0.0, extent.y, extent.z),
		origin + extent,
	]

	const EDGES: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(4, 5), Vector2i(4, 6), Vector2i(5, 7), Vector2i(6, 7),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7),
	]

	for edge in EDGES:
		_add_manager_local_line(immediate_mesh, corners[edge.x], corners[edge.y])


func _draw_chunk_center(immediate_mesh: ImmediateMesh, coordinate: Vector3i) -> void:
	var center := chunk_manager.chunk_coordinate_to_local_center(coordinate)
	var radius := minf(
		chunk_manager.chunk_extent.x,
		minf(chunk_manager.chunk_extent.y, chunk_manager.chunk_extent.z)
	) * 0.08

	_add_manager_local_line(
		immediate_mesh,
		center - Vector3(radius, 0.0, 0.0),
		center + Vector3(radius, 0.0, 0.0)
	)
	_add_manager_local_line(
		immediate_mesh,
		center - Vector3(0.0, radius, 0.0),
		center + Vector3(0.0, radius, 0.0)
	)
	_add_manager_local_line(
		immediate_mesh,
		center - Vector3(0.0, 0.0, radius),
		center + Vector3(0.0, 0.0, radius)
	)


func _add_manager_local_line(
	immediate_mesh: ImmediateMesh,
	from: Vector3,
	to: Vector3
) -> void:
	var local_from := from
	var local_to := to
	if chunk_manager.is_inside_tree() and is_inside_tree():
		local_from = to_local(chunk_manager.to_global(from))
		local_to = to_local(chunk_manager.to_global(to))

	immediate_mesh.surface_add_vertex(local_from)
	immediate_mesh.surface_add_vertex(local_to)


# [b]Materials[/b]

func _create_line_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.no_depth_test = xray_bounds
	return material
