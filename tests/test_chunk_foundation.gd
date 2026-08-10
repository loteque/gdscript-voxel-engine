extends SceneTree

const CHUNK_MANAGER := preload("res://voxel/chunking/ChunkManager.gd")
const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")

var _failed: bool = false


func _initialize() -> void:
	_test_coordinate_mapping()
	_test_chunk_field_dimensions()
	_test_sampling_origin_only_dirties_density()
	_test_adjacent_chunk_boundary_samples_match()

	if _failed:
		quit(1)
	else:
		print("Chunk foundation tests passed.")
		quit(0)


func _test_coordinate_mapping() -> void:
	var manager := CHUNK_MANAGER.new()
	manager.chunk_cell_dimensions = Vector3i(4, 2, 8)
	manager.sample_spacing = 2.0

	_assert_vector3_equal(
		manager.chunk_extent,
		Vector3(8.0, 4.0, 16.0),
		"Chunk extent must derive from cell dimensions and sample spacing."
	)
	_assert_vector3_equal(
		manager.chunk_coordinate_to_local_origin(Vector3i(1, -2, 3)),
		Vector3(8.0, -8.0, 48.0),
		"Chunk coordinates must map to deterministic terrain-local origins."
	)
	_assert_equal(
		manager.local_position_to_chunk_coordinate(Vector3(7.99, 0.0, 15.99)),
		Vector3i(0, 0, 0),
		"Positions below a positive boundary must remain in the current chunk."
	)
	_assert_equal(
		manager.local_position_to_chunk_coordinate(Vector3(8.0, 0.0, 16.0)),
		Vector3i(1, 0, 1),
		"Positions on a positive boundary must enter the next chunk."
	)
	_assert_equal(
		manager.local_position_to_chunk_coordinate(Vector3(-0.01, -0.01, -0.01)),
		Vector3i(-1, -1, -1),
		"Negative positions must use floor-based chunk coordinates."
	)
	manager.free()


func _test_chunk_field_dimensions() -> void:
	var manager := CHUNK_MANAGER.new()
	manager.chunk_cell_dimensions = Vector3i(4, 5, 6)
	manager.sample_spacing = 1.5
	root.add_child(manager)

	var chunk := manager.create_chunk(Vector3i(2, 0, -1))
	_assert_equal(
		chunk.point_field.cell_dimensions,
		Vector3i(4, 5, 6),
		"Managed fields must use chunk dimensions expressed in cells."
	)
	_assert_equal(
		chunk.point_field.sample_dimensions,
		Vector3i(5, 6, 7),
		"A chunk field must contain one more sample than cells on every axis."
	)
	_assert_vector3_equal(
		chunk.position,
		manager.chunk_coordinate_to_local_center(chunk.chunk_coordinate),
		"Chunk nodes must be placed at their terrain-local sampling centers."
	)
	_assert_true(
		manager.create_chunk(chunk.chunk_coordinate) == chunk,
		"Creating an occupied coordinate must return the existing chunk."
	)

	manager.queue_free()


func _test_sampling_origin_only_dirties_density() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.regenerate()
	var old_positions := field.positions.duplicate()

	field.sampling_origin = Vector3(16.0, 0.0, 0.0)

	_assert_true(
		not field.positions_dirty,
		"Changing sampling origin must not invalidate chunk-local positions."
	)
	_assert_true(
		field.densities_dirty,
		"Changing sampling origin must invalidate generated density values."
	)
	_assert_true(
		field.positions == old_positions,
		"Changing sampling origin must preserve existing local positions."
	)


func _test_adjacent_chunk_boundary_samples_match() -> void:
	var template := POINT_FIELD_RESOURCE.new()
	template.noise = FastNoiseLite.new()
	template.noise.seed = 12345
	template.density_scale = 0.07
	template.terrain_base_height = 1.25
	template.terrain_height_scale = 8.0

	var manager := CHUNK_MANAGER.new()
	manager.chunk_cell_dimensions = Vector3i(4, 4, 4)
	manager.sample_spacing = 2.0
	manager.field_template = template
	root.add_child(manager)

	var chunk_a := manager.create_chunk(Vector3i(0, 0, 0))
	var chunk_b := manager.create_chunk(Vector3i(1, 0, 0))
	var field_a := chunk_a.point_field
	var field_b := chunk_b.point_field

	_assert_true(field_a != field_b, "Chunks must own independent PointFieldResource instances.")
	_assert_true(
		field_a.noise == template.noise and field_b.noise == template.noise,
		"Chunks must explicitly share the template noise generator."
	)
	_assert_equal(
		field_a.noise.seed,
		field_b.noise.seed,
		"Adjacent chunks must use the same noise seed."
	)
	_assert_float_equal(
		field_a.density_scale,
		field_b.density_scale,
		"Adjacent chunks must use the same density scale."
	)
	_assert_float_equal(
		field_a.terrain_base_height,
		field_b.terrain_base_height,
		"Adjacent chunks must use the same terrain base height."
	)
	_assert_float_equal(
		field_a.terrain_height_scale,
		field_b.terrain_height_scale,
		"Adjacent chunks must use the same terrain height scale."
	)

	chunk_a.regenerate_field()
	chunk_b.regenerate_field()

	var boundary_a := Vector3i(field_a.cell_dimensions.x, 2, 2)
	var boundary_b := Vector3i(0, 2, 2)
	var sampling_position_a := field_a.get_sampling_position(boundary_a)
	var sampling_position_b := field_b.get_sampling_position(boundary_b)

	_assert_vector3_equal(
		sampling_position_a,
		sampling_position_b,
		"Adjacent chunks must address the same sampling-space point at their shared boundary."
	)
	_assert_float_equal(
		field_a.get_density(boundary_a),
		field_b.get_density(boundary_b),
		"Adjacent chunks must generate identical densities at shared samples."
	)

	manager.queue_free()


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
