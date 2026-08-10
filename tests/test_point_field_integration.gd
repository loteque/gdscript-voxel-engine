extends SceneTree

const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")
const POINT_FIELD_VISUALIZER := preload("res://voxel/visualization/PointFieldVisualizer.gd")
const SURFACE_NETS_DISPLAY := preload("res://voxel/meshing/SurfaceNetsMeshDisplay.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_auto_regeneration_resumes_from_dirty_state()
	await _test_surface_nets_preserves_mesh_while_field_is_dirty()

	if _failed:
		quit(1)
	else:
		print("Point field integration tests passed.")
		quit(0)


func _test_auto_regeneration_resumes_from_dirty_state() -> void:
	var field := _make_generated_field()
	var visualizer := POINT_FIELD_VISUALIZER.new()
	visualizer.auto_regenerate_field = false
	visualizer.field = field
	root.add_child(visualizer)
	await process_frame
	await process_frame

	field.terrain_height_scale += 1.0
	await process_frame
	_assert_true(field.densities_dirty, "Field must remain dirty while auto regeneration is disabled.")

	visualizer.auto_regenerate_field = true
	await process_frame
	await process_frame
	await process_frame

	_assert_true(
		field.is_data_current(),
		"Re-enabling auto regeneration must consume already-dirty field state."
	)
	visualizer.queue_free()
	await process_frame


func _test_surface_nets_preserves_mesh_while_field_is_dirty() -> void:
	var field := _make_generated_field()
	var display := SURFACE_NETS_DISPLAY.new()
	display.field = field
	display.display_surface_nets_mesh = true
	root.add_child(display)
	await process_frame
	await process_frame

	var current_mesh := display.mesh
	_assert_true(current_mesh != null, "Surface Nets display must generate an initial mesh.")
	if current_mesh == null:
		display.queue_free()
		await process_frame
		return

	field.sample_spacing += 0.5
	await process_frame
	await process_frame

	_assert_true(field.positions_dirty and field.densities_dirty, "Geometry changes must leave field channels dirty before regeneration.")
	_assert_true(
		display.mesh == current_mesh,
		"Surface Nets display must preserve the current mesh while source field data is dirty."
	)

	field.regenerate()
	await process_frame
	await process_frame

	_assert_true(field.is_data_current(), "Explicit regeneration must restore current field state.")
	_assert_true(
		display.mesh != null and display.mesh != current_mesh,
		"Surface Nets display must replace the mesh after current field data is regenerated."
	)
	display.queue_free()
	await process_frame


func _make_generated_field() -> PointFieldResource:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.noise = FastNoiseLite.new()
	field.regenerate()
	return field


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
