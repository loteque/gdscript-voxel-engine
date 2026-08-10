@tool
class_name ChunkValidationDemo
extends Node3D

## Validation harness for the chunked terrain stack in both editor and runtime.
##
## Editor mode builds the real chunk fields and Surface Nets geometry at the
## configured chunk resolution, using the display layer's cheap wireframe
## material. Runtime stages the same expensive work across frames and enables
## camera interaction separately.

signal generation_completed


# [b]Scene References[/b]

@export var chunk_manager: ChunkManager
@export var chunk_surface_display: ChunkSurfaceNetsDisplay
@export var chunk_visualizer: ChunkVisualizer
@export var camera_controller: NoClipCameraController


# [b]Validation Configuration[/b]

@export var grid_dimensions: Vector3i = Vector3i(3, 1, 3):
	set(value):
		var sanitized := Vector3i(
			maxi(value.x, 1),
			maxi(value.y, 1),
			maxi(value.z, 1)
		)
		if grid_dimensions == sanitized:
			return
		grid_dimensions = sanitized
		_queue_editor_preview_refresh()

@export var regenerate_on_ready: bool = true
@export var frame_camera_on_ready: bool = true


# [b]Editor Preview[/b]

## Generates the actual per-chunk point fields and Surface Nets meshes in the
## editor. Disable this when editing unrelated scene content to avoid tool-time
## generation work.
@export var editor_preview_enabled: bool = true:
	set(value):
		if editor_preview_enabled == value:
			return
		editor_preview_enabled = value
		_queue_editor_preview_refresh()


# [b]Runtime State[/b]

var generation_complete: bool = false
var _editor_preview_refresh_queued: bool = false


# [b]Lifecycle[/b]

func _ready() -> void:
	if Engine.is_editor_hint():
		_queue_editor_preview_refresh()
		return

	await _run_runtime_validation()


func _run_runtime_validation() -> void:
	if chunk_manager == null:
		push_error("ChunkValidationDemo requires a ChunkManager.")
		return

	_configure_consumers()

	if frame_camera_on_ready:
		_frame_camera()

	# Allow the environment, instructions, camera, and preview bounds to render
	# before any synchronous terrain generation begins.
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame

	chunk_manager.create_centered_grid(grid_dimensions)

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()

	if regenerate_on_ready:
		await _regenerate_and_mesh_chunks_staged()

	generation_complete = true
	generation_completed.emit()
	_report_validation_state()


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

	_configure_consumers()

	if not editor_preview_enabled:
		chunk_manager.clear_chunks()
		if chunk_visualizer != null:
			chunk_visualizer.rebuild()
		return

	# Preview uses the real configured chunk dimensions by default. This keeps
	# seam/topology inspection representative of runtime rather than substituting
	# a cheaper but structurally different mesh.
	chunk_manager.clear_chunks()
	chunk_manager.create_centered_grid(grid_dimensions)

	var coordinates := chunk_manager.get_chunk_coordinates()
	coordinates.sort()
	for coordinate in coordinates:
		var chunk := chunk_manager.get_chunk(coordinate)
		if chunk == null:
			continue
		chunk.regenerate_field()
		if chunk_surface_display != null:
			var display := chunk_surface_display.get_display(coordinate)
			if display != null:
				display.rebuild_mesh()

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()


func _configure_consumers() -> void:
	if chunk_surface_display != null:
		chunk_surface_display.chunk_manager = chunk_manager

	if chunk_visualizer != null:
		chunk_visualizer.chunk_manager = chunk_manager
		chunk_visualizer.preview_grid_dimensions = grid_dimensions
		chunk_visualizer.rebuild()


# [b]Staged Generation[/b]

## Regenerates and meshes one chunk at a time, yielding a frame between chunks.
##
## This is intentionally demo-level orchestration. ChunkManager remains free of
## frame scheduling so a future terrain work queue can replace this harness.
func _regenerate_and_mesh_chunks_staged() -> void:
	var coordinates := chunk_manager.get_chunk_coordinates()
	coordinates.sort()

	for coordinate in coordinates:
		var chunk := chunk_manager.get_chunk(coordinate)
		if chunk == null:
			continue

		chunk.regenerate_field()

		if chunk_surface_display != null:
			var display := chunk_surface_display.get_display(coordinate)
			if display != null:
				display.rebuild_mesh()

		# Present progress and give the renderer/event loop time between chunks.
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame


# [b]Camera Framing[/b]

func get_grid_center() -> Vector3:
	var minimum_coordinate := Vector3i(
		-floori(float(grid_dimensions.x) * 0.5),
		-floori(float(grid_dimensions.y) * 0.5),
		-floori(float(grid_dimensions.z) * 0.5)
	)
	var maximum_coordinate := minimum_coordinate + grid_dimensions - Vector3i.ONE
	var minimum_corner := chunk_manager.chunk_coordinate_to_local_origin(minimum_coordinate)
	var maximum_corner := (
		chunk_manager.chunk_coordinate_to_local_origin(maximum_coordinate)
		+ chunk_manager.chunk_extent
	)
	return (minimum_corner + maximum_corner) * 0.5


func _frame_camera() -> void:
	# Camera control is runtime-only even though this scene script is a tool.
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
	var expected_chunk_count := (
		grid_dimensions.x
		* grid_dimensions.y
		* grid_dimensions.z
	)
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
