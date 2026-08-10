class_name ChunkValidationDemo
extends Node3D

## Runtime harness for validating the chunked terrain stack as one scene.
##
## The editor-visible ChunkVisualizer owns preview diagnostics. At runtime this
## controller creates a fixed chunk grid, regenerates its fields, and asks the
## independent Surface Nets display layer to build one mesh per chunk.


# [b]Scene References[/b]

@export var chunk_manager: ChunkManager
@export var chunk_surface_display: ChunkSurfaceNetsDisplay
@export var chunk_visualizer: ChunkVisualizer
@export var camera_controller: NoClipCameraController


# [b]Validation Configuration[/b]

@export var grid_dimensions: Vector3i = Vector3i(3, 1, 3)
@export var regenerate_on_ready: bool = true
@export var frame_camera_on_ready: bool = true


# [b]Lifecycle[/b]

func _ready() -> void:
	if chunk_manager == null:
		push_error("ChunkValidationDemo requires a ChunkManager.")
		return

	if chunk_surface_display != null:
		chunk_surface_display.chunk_manager = chunk_manager

	if chunk_visualizer != null:
		chunk_visualizer.chunk_manager = chunk_manager
		chunk_visualizer.preview_grid_dimensions = grid_dimensions

	chunk_manager.create_centered_grid(grid_dimensions)

	if regenerate_on_ready:
		chunk_manager.regenerate_all_chunks()

	if chunk_surface_display != null:
		chunk_surface_display.rebuild_all_meshes()

	if chunk_visualizer != null:
		chunk_visualizer.rebuild()

	if frame_camera_on_ready:
		_frame_camera()

	_report_validation_state()


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
	if camera_controller == null:
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
