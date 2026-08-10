extends SceneTree

const CHUNK_MANAGER := preload("res://voxel/chunking/ChunkManager.gd")
const CHUNK_VISUALIZER := preload("res://voxel/visualization/ChunkVisualizer.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_preview_and_loaded_chunk_bounds()

	if _failed:
		quit(1)
	else:
		print("Chunk visualizer tests passed.")
		quit(0)


func _test_preview_and_loaded_chunk_bounds() -> void:
	var manager := CHUNK_MANAGER.new()
	manager.chunk_cell_dimensions = Vector3i(4, 2, 6)
	manager.sample_spacing = 2.0
	root.add_child(manager)

	var visualizer := CHUNK_VISUALIZER.new()
	visualizer.chunk_manager = manager
	visualizer.preview_grid_dimensions = Vector3i(3, 1, 3)
	visualizer.show_preview_grid = true
	visualizer.show_loaded_chunks = true
	root.add_child(visualizer)

	visualizer.rebuild()
	_assert_equal(
		visualizer.get_visualized_preview_cell_count(),
		9,
		"A 3x1x3 preview must draw nine planned chunk cells."
	)
	_assert_equal(
		visualizer.get_visualized_loaded_chunk_count(),
		0,
		"No loaded bounds should be drawn before chunks exist."
	)
	_assert_true(visualizer.mesh != null, "Preview bounds must generate line geometry.")
	if visualizer.mesh != null:
		_assert_true(
			visualizer.mesh.get_surface_count() > 0,
			"Preview bounds must produce at least one ImmediateMesh surface."
		)

	manager.create_chunk(Vector3i(1, 0, -1))
	await process_frame
	visualizer.rebuild()
	_assert_equal(
		visualizer.get_visualized_loaded_chunk_count(),
		1,
		"Loaded chunk lifecycle changes must update diagnostic bounds."
	)

	manager.sample_spacing = 3.0
	await process_frame
	visualizer.rebuild()
	_assert_vector3_equal(
		manager.chunk_extent,
		Vector3(12.0, 6.0, 18.0),
		"Visualizer layout updates must follow manager geometry changes."
	)

	manager.remove_chunk(Vector3i(1, 0, -1))
	await process_frame
	visualizer.rebuild()
	_assert_equal(
		visualizer.get_visualized_loaded_chunk_count(),
		0,
		"Removing a chunk must remove its loaded diagnostic bounds."
	)

	visualizer.queue_free()
	manager.queue_free()
	await process_frame


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])


func _assert_vector3_equal(actual: Vector3, expected: Vector3, message: String) -> void:
	if actual.is_equal_approx(expected):
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])
