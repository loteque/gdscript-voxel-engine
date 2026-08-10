@tool
class_name ChunkValidationDemo
extends Node3D

## Validation harness for the chunked terrain stack in both editor and runtime.
##
## Editor mode builds the real chunk fields and Surface Nets geometry at the
## configured chunk resolution, using the display layer's cheap wireframe
## material. Runtime first presents the lightweight instructions and planned
## chunk grid, then processes expensive field generation and meshing within a
## configurable per-frame time budget.

signal startup_preview_ready
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

## Maximum wall-clock time spent generating/meshing chunks before yielding the
## main thread back to the engine. Individual chunks remain atomic, so a single
## expensive chunk may exceed this budget before the next yield.
@export_range(0.5, 33.0, 0.5, "or_greater")
var runtime_generation_budget_ms: float = 6.0


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

var startup_preview_presented: bool = false
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

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()

	startup_preview_presented = true
	startup_preview_ready.emit()

	# Guarantee at least one presentation frame before any chunk allocation,
	# density generation, or Surface Nets work begins.
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

## Processes as many complete chunks as fit within the current frame budget.
##
## Chunk generation remains atomic for now. This is deliberately demo-level
## scheduling and does not move scheduling responsibility into ChunkManager.
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

	# This pass explicitly owns the rebuild. Suppress field-signal-driven rebuild
	# scheduling so each chunk produces exactly one mesh for this generation pass.
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
	var maximum_corner := (
		chunk_manager.chunk_coordinate_to_local_origin(maximum_coordinate)
		+ chunk_manager.chunk_extent
	)
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
