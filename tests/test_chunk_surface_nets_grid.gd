extends SceneTree

const CHUNK_MANAGER := preload("res://voxel/chunking/ChunkManager.gd")
const CHUNK_SURFACE_NETS_DISPLAY := preload("res://voxel/chunking/ChunkSurfaceNetsDisplay.gd")
const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_three_by_one_by_three_grid_generates_meshes()

	if _failed:
		quit(1)
	else:
		print("Chunk Surface Nets grid tests passed.")
		quit(0)


func _test_three_by_one_by_three_grid_generates_meshes() -> void:
	var template := POINT_FIELD_RESOURCE.new()
	template.noise = null
	template.terrain_base_height = 8.0
	template.terrain_height_scale = 0.0

	var manager := CHUNK_MANAGER.new()
	manager.chunk_cell_dimensions = Vector3i(16, 16, 16)
	manager.sample_spacing = 1.0
	manager.field_template = template
	root.add_child(manager)

	var chunk_display := CHUNK_SURFACE_NETS_DISPLAY.new()
	chunk_display.chunk_manager = manager
	chunk_display.display_meshes = true
	root.add_child(chunk_display)

	var chunks := manager.create_centered_grid(Vector3i(3, 1, 3))
	_assert_equal(chunks.size(), 9, "A 3x1x3 grid must create nine chunks.")
	_assert_equal(manager.get_chunk_count(), 9, "ChunkManager must own nine grid chunks.")

	for z in range(-1, 2):
		for x in range(-1, 2):
			_assert_true(
				manager.has_chunk(Vector3i(x, 0, z)),
				"Centered grid must contain coordinate (%d, 0, %d)." % [x, z]
			)

	manager.regenerate_all_chunks()
	chunk_display.rebuild_all_meshes()

	_assert_equal(
		chunk_display.get_display_count(),
		9,
		"Chunk Surface Nets display must create one consumer per chunk."
	)

	for coordinate in manager.get_chunk_coordinates():
		var chunk := manager.get_chunk(coordinate)
		var display := chunk_display.get_display(coordinate)
		_assert_true(display != null, "Every managed chunk must have a mesh display.")
		if display == null:
			continue
		_assert_true(display.get_parent() == chunk, "Chunk mesh displays must remain spatial children of their chunks.")
		_assert_true(display.field == chunk.point_field, "Chunk mesh displays must consume the chunk's authoritative point field.")
		_assert_true(display.mesh != null, "Every flat-terrain chunk must generate an ArrayMesh.")
		if display.mesh != null:
			_assert_true(
				display.mesh.get_surface_count() > 0,
				"Every flat-terrain chunk mesh must contain a rendered surface."
			)

	_test_shared_x_boundary(manager, Vector3i(0, 0, 0), Vector3i(1, 0, 0))
	_test_shared_z_boundary(manager, Vector3i(0, 0, 0), Vector3i(0, 0, 1))

	chunk_display.queue_free()
	manager.queue_free()
	await process_frame


func _test_shared_x_boundary(
	manager: ChunkManager,
	left_coordinate: Vector3i,
	right_coordinate: Vector3i
) -> void:
	var left := manager.get_chunk(left_coordinate).point_field
	var right := manager.get_chunk(right_coordinate).point_field
	var left_sample := Vector3i(left.cell_dimensions.x, 8, 8)
	var right_sample := Vector3i(0, 8, 8)

	_assert_vector3_equal(
		left.get_sampling_position(left_sample),
		right.get_sampling_position(right_sample),
		"X-neighbor chunks must address the same shared sample position."
	)
	_assert_float_equal(
		left.get_density(left_sample),
		right.get_density(right_sample),
		"X-neighbor chunks must agree on shared density."
	)


func _test_shared_z_boundary(
	manager: ChunkManager,
	front_coordinate: Vector3i,
	back_coordinate: Vector3i
) -> void:
	var front := manager.get_chunk(front_coordinate).point_field
	var back := manager.get_chunk(back_coordinate).point_field
	var front_sample := Vector3i(8, 8, front.cell_dimensions.z)
	var back_sample := Vector3i(8, 8, 0)

	_assert_vector3_equal(
		front.get_sampling_position(front_sample),
		back.get_sampling_position(back_sample),
		"Z-neighbor chunks must address the same shared sample position."
	)
	_assert_float_equal(
		front.get_density(front_sample),
		back.get_density(back_sample),
		"Z-neighbor chunks must agree on shared density."
	)


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


func _assert_float_equal(actual: float, expected: float, message: String) -> void:
	if is_equal_approx(actual, expected):
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])


func _assert_vector3_equal(actual: Vector3, expected: Vector3, message: String) -> void:
	if actual.is_equal_approx(expected):
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])
