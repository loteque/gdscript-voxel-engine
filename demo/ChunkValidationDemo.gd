@tool
class_name ChunkValidationDemo
extends Node3D

## Validation harness for the chunked terrain stack in both editor and runtime.
##
## This scene intentionally acts as a discoverable facade over the engine's
## independently owned configuration. The top-level inspector forwards settings
## to ChunkManager, PointFieldResource, ChunkSurfaceNetsDisplay,
## ChunkVisualizer, and the validation camera without moving ownership out of
## those components.

signal startup_preview_ready
signal generation_completed


# [b]Scene References[/b]

@export var chunk_manager: ChunkManager
@export var chunk_surface_display: ChunkSurfaceNetsDisplay
@export var chunk_visualizer: ChunkVisualizer
@export var camera_controller: NoClipCameraController


# [b]Terrain Layout[/b]

@export_group("Terrain Layout")

@export var grid_dimensions: Vector3i = Vector3i(3, 1, 3):
	set(value):
		var sanitized := Vector3i(maxi(value.x, 1), maxi(value.y, 1), maxi(value.z, 1))
		if grid_dimensions == sanitized:
			return
		grid_dimensions = sanitized
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()

@export var chunk_cell_dimensions: Vector3i = Vector3i(16, 16, 16):
	set(value):
		chunk_cell_dimensions = Vector3i(maxi(value.x, 1), maxi(value.y, 1), maxi(value.z, 1))
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()

@export_range(0.001, 1000.0, 0.001, "or_greater")
var sample_spacing: float = 1.0:
	set(value):
		sample_spacing = maxf(value, 0.001)
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()


# [b]Density Generation[/b]

@export_group("Density Generation")

## Expand this resource in the inspector to discover the FastNoiseLite controls.
@export var terrain_noise: FastNoiseLite:
	set(value):
		terrain_noise = value
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()

@export_range(0.0001, 1000.0, 0.0001, "or_greater")
var density_scale: float = 1.0:
	set(value):
		density_scale = maxf(value, 0.0001)
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()

@export_range(-10000.0, 10000.0, 0.01, "or_greater", "or_less")
var terrain_base_height: float = 0.0:
	set(value):
		terrain_base_height = value
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()

@export_range(0.0, 10000.0, 0.01, "or_greater")
var terrain_height_scale: float = 7.0:
	set(value):
		terrain_height_scale = maxf(value, 0.0)
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()


# [b]Surface Nets[/b]

@export_group("Surface Nets")

@export_range(-2.0, 2.0, 0.01, "or_greater", "or_less")
var iso_level: float = 0.0:
	set(value):
		iso_level = value
		_apply_top_level_configuration()
		_queue_editor_preview_refresh()

@export var surface_material: Material:
	set(value):
		surface_material = value
		_apply_top_level_configuration()

@export var display_meshes: bool = true:
	set(value):
		display_meshes = value
		_apply_top_level_configuration()


# [b]Chunk Visualization[/b]

@export_group("Chunk Visualization")

@export var show_preview_grid: bool = true:
	set(value):
		show_preview_grid = value
		_apply_top_level_configuration()

@export var show_loaded_chunks: bool = true:
	set(value):
		show_loaded_chunks = value
		_apply_top_level_configuration()

@export var show_chunk_centers: bool = true:
	set(value):
		show_chunk_centers = value
		_apply_top_level_configuration()

@export var xray_bounds: bool = true:
	set(value):
		xray_bounds = value
		_apply_top_level_configuration()

@export var preview_chunk_color: Color = Color(0.45, 0.55, 0.7, 0.55):
	set(value):
		preview_chunk_color = value
		_apply_top_level_configuration()

@export var loaded_chunk_color: Color = Color(0.2, 0.85, 1.0, 1.0):
	set(value):
		loaded_chunk_color = value
		_apply_top_level_configuration()

@export var editor_wireframe_preview: bool = true:
	set(value):
		editor_wireframe_preview = value
		_apply_top_level_configuration()

@export var editor_wireframe_color: Color = Color(0.3, 0.9, 1.0, 1.0):
	set(value):
		editor_wireframe_color = value
		_apply_top_level_configuration()


# [b]Runtime Generation[/b]

@export_group("Runtime Generation")

@export var regenerate_on_ready: bool = true
@export var frame_camera_on_ready: bool = true

@export_range(0.5, 33.0, 0.5, "or_greater")
var runtime_generation_budget_ms: float = 6.0


# [b]Editor Preview[/b]

@export_group("Editor Preview")

@export var editor_preview_enabled: bool = true:
	set(value):
		editor_preview_enabled = value
		_queue_editor_preview_refresh()

@export_tool_button("Regenerate Terrain", "Callable")
var regenerate_terrain_action: Callable = regenerate_terrain


# [b]Camera[/b]

@export_group("Camera")

@export_range(0.0, 1000.0, 0.1, "or_greater")
var camera_move_speed: float = 14.0:
	set(value):
		camera_move_speed = maxf(value, 0.0)
		_apply_top_level_configuration()

@export_range(1.0, 100.0, 0.1, "or_greater")
var camera_sprint_multiplier: float = 4.0:
	set(value):
		camera_sprint_multiplier = maxf(value, 1.0)
		_apply_top_level_configuration()

@export_range(0.0001, 0.02, 0.0001, "or_greater")
var camera_mouse_sensitivity: float = 0.002:
	set(value):
		camera_mouse_sensitivity = maxf(value, 0.0001)
		_apply_top_level_configuration()


# [b]Runtime State[/b]

var startup_preview_presented: bool = false
var generation_complete: bool = false
var _editor_preview_refresh_queued: bool = false


# [b]Lifecycle[/b]

func _ready() -> void:
	_apply_top_level_configuration()
	if Engine.is_editor_hint():
		_queue_editor_preview_refresh()
		return

	await _run_runtime_validation()


# [b]Public Actions[/b]

## Explicitly regenerates the validation terrain from the top-level settings.
## In the editor this rebuilds immediately. Runtime uses the normal budgeted path.
func regenerate_terrain() -> void:
	_apply_top_level_configuration()
	if Engine.is_editor_hint():
		_refresh_editor_preview()
		return

	if not is_inside_tree() or chunk_manager == null:
		return
	generation_complete = false
	chunk_manager.clear_chunks()
	chunk_manager.create_centered_grid(grid_dimensions)
	if chunk_visualizer != null:
		chunk_visualizer.rebuild()
	await _regenerate_and_mesh_chunks_budgeted()
	generation_complete = true
	generation_completed.emit()


func _run_runtime_validation() -> void:
	if chunk_manager == null:
		push_error("ChunkValidationDemo requires a ChunkManager.")
		return

	_configure_consumers()

	if frame_camera_on_ready:
		_frame_camera()

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()

	startup_preview_presented = true
	startup_preview_ready.emit()

	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame

	chunk_manager.create_centered_grid(grid_dimensions)

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()

	if regenerate_on_ready:
		await _regenerate_and_mesh_chunks_budgeted()

	generation_complete = true
	generation_completed.emit()
	_report_validation_state()


# [b]Configuration Facade[/b]

func _apply_top_level_configuration() -> void:
	if chunk_manager != null:
		chunk_manager.chunk_cell_dimensions = chunk_cell_dimensions
		chunk_manager.sample_spacing = sample_spacing
		if chunk_manager.field_template == null:
			chunk_manager.field_template = PointFieldResource.new()
		var field_template := chunk_manager.field_template
		field_template.noise = terrain_noise
		field_template.density_scale = density_scale
		field_template.terrain_base_height = terrain_base_height
		field_template.terrain_height_scale = terrain_height_scale

	if chunk_surface_display != null:
		chunk_surface_display.iso_level = iso_level
		chunk_surface_display.display_meshes = display_meshes
		chunk_surface_display.editor_wireframe_preview = editor_wireframe_preview
		chunk_surface_display.editor_wireframe_color = editor_wireframe_color
		if surface_material != null:
			chunk_surface_display.surface_material = surface_material

	if chunk_visualizer != null:
		chunk_visualizer.preview_grid_dimensions = grid_dimensions
		chunk_visualizer.show_preview_grid = show_preview_grid
		chunk_visualizer.show_loaded_chunks = show_loaded_chunks
		chunk_visualizer.show_chunk_centers = show_chunk_centers
		chunk_visualizer.xray_bounds = xray_bounds
		chunk_visualizer.preview_chunk_color = preview_chunk_color
		chunk_visualizer.loaded_chunk_color = loaded_chunk_color

	if camera_controller != null:
		camera_controller.move_speed = camera_move_speed
		camera_controller.sprint_multiplier = camera_sprint_multiplier
		camera_controller.mouse_sensitivity = camera_mouse_sensitivity


# [b]Editor Preview Generation[/b]

func _queue_editor_preview_refresh() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or _editor_preview_refresh_queued:
		return
	_editor_preview_refresh_queued = true
	call_deferred("_refresh_editor_preview")


func _refresh_editor_preview() -> void:
	_editor_preview_refresh_queued = false
	if not Engine.is_editor_hint() or not is_inside_tree() or chunk_manager == null:
		return

	_apply_top_level_configuration()
	_configure_consumers()

	if not editor_preview_enabled:
		chunk_manager.clear_chunks()
		if chunk_visualizer != null:
			chunk_visualizer.rebuild()
		return

	chunk_manager.clear_chunks()
	chunk_manager.create_centered_grid(grid_dimensions)

	var coordinates := chunk_manager.get_chunk_coordinates()
	coordinates.sort()
	for coordinate in coordinates:
		_generate_and_mesh_chunk(coordinate)

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()


func _configure_consumers() -> void:
	if chunk_surface_display != null:
		chunk_surface_display.chunk_manager = chunk_manager

	if chunk_visualizer != null:
		chunk_visualizer.chunk_manager = chunk_manager
		chunk_visualizer.preview_grid_dimensions = grid_dimensions


# [b]Budgeted Generation[/b]

func _regenerate_and_mesh_chunks_budgeted() -> void:
	var coordinates := chunk_manager.get_chunk_coordinates()
	coordinates.sort()
	var budget_usec := int(maxf(runtime_generation_budget_ms, 0.5) * 1000.0)
	var frame_started_usec := Time.get_ticks_usec()

	for index in coordinates.size():
		_generate_and_mesh_chunk(coordinates[index])

		var has_more_work := index < coordinates.size() - 1
		if not has_more_work:
			continue
		if Time.get_ticks_usec() - frame_started_usec < budget_usec:
			continue

		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
		frame_started_usec = Time.get_ticks_usec()


func _generate_and_mesh_chunk(coordinate: Vector3i) -> void:
	var chunk := chunk_manager.get_chunk(coordinate)
	if chunk == null:
		return

	var display: SurfaceNetsMeshDisplay = null
	if chunk_surface_display != null:
		display = chunk_surface_display.get_display(coordinate)

	if display != null:
		display.automatic_rebuild_enabled = false

	chunk.regenerate_field()

	if display != null:
		display.rebuild_mesh()
		display.automatic_rebuild_enabled = true


# [b]Camera Framing[/b]

func get_grid_center() -> Vector3:
	var minimum_coordinate := Vector3i(
		-floori(float(grid_dimensions.x) * 0.5),
		-floori(float(grid_dimensions.y) * 0.5),
		-floori(float(grid_dimensions.z) * 0.5)
	)
	var maximum_coordinate := minimum_coordinate + grid_dimensions - Vector3i.ONE
	var minimum_corner := chunk_manager.chunk_coordinate_to_local_origin(minimum_coordinate)
	var maximum_corner := chunk_manager.chunk_coordinate_to_local_origin(maximum_coordinate) + chunk_manager.chunk_extent
	return (minimum_corner + maximum_corner) * 0.5


func _frame_camera() -> void:
	if Engine.is_editor_hint() or camera_controller == null:
		return

	var center := get_grid_center()
	var span := Vector3(grid_dimensions) * chunk_manager.chunk_extent
	var horizontal_span := maxf(span.x, span.z)

	camera_controller.position = center + Vector3(
		horizontal_span * 0.72,
		maxf(span.y * 1.5, horizontal_span * 0.55),
		horizontal_span * 0.72
	)
	camera_controller.look_at(center, Vector3.UP)
	camera_controller.sync_rotation_from_transform()


# [b]Validation Reporting[/b]

func _report_validation_state() -> void:
	var expected_chunk_count := grid_dimensions.x * grid_dimensions.y * grid_dimensions.z
	var mesh_count := 0
	if chunk_surface_display != null:
		mesh_count = chunk_surface_display.get_display_count()

	print(
		"Chunk validation scene ready: %d/%d chunks, %d mesh displays." % [
			chunk_manager.get_chunk_count(),
			expected_chunk_count,
			mesh_count,
		]
	)
