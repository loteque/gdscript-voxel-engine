extends SceneTree

const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")

var _failed: bool = false


func _initialize() -> void:
	_test_initial_and_generated_state()
	_test_density_configuration_marks_only_densities_dirty()
	_test_geometry_configuration_marks_both_channels_dirty()
	_test_generation_clears_channel_flags_incrementally()
	_test_noise_change_preserves_stale_density_data()

	if _failed:
		quit(1)
	else:
		print("Point field state tests passed.")
		quit(0)


func _test_initial_and_generated_state() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	_assert_true(field.positions_dirty, "New fields must start with dirty positions.")
	_assert_true(field.densities_dirty, "New fields must start with dirty densities.")

	field.regenerate()
	_assert_true(not field.positions_dirty, "Generated positions must be current.")
	_assert_true(not field.densities_dirty, "Generated densities must be current.")
	_assert_true(field.is_data_current(), "Fully generated data must report current.")


func _test_density_configuration_marks_only_densities_dirty() -> void:
	var field := _make_generated_field()
	var old_positions := field.positions.duplicate()
	var old_densities := field.densities.duplicate()

	field.terrain_height_scale += 1.0

	_assert_true(not field.positions_dirty, "Density settings must not dirty positions.")
	_assert_true(field.densities_dirty, "Density settings must dirty densities.")
	_assert_true(field.positions == old_positions, "Dirtying densities must preserve positions.")
	_assert_true(field.densities == old_densities, "Dirtying densities must preserve stale density data.")


func _test_geometry_configuration_marks_both_channels_dirty() -> void:
	var field := _make_generated_field()
	var old_positions := field.positions.duplicate()
	var old_densities := field.densities.duplicate()

	field.sample_spacing += 0.5

	_assert_true(field.positions_dirty, "Geometry settings must dirty positions.")
	_assert_true(field.densities_dirty, "Geometry settings must dirty densities.")
	_assert_true(field.positions == old_positions, "Dirtying geometry must preserve stale positions.")
	_assert_true(field.densities == old_densities, "Dirtying geometry must preserve stale densities.")


func _test_generation_clears_channel_flags_incrementally() -> void:
	var field := _make_generated_field()
	field.sample_spacing += 0.5

	field.generate_positions()
	_assert_true(not field.positions_dirty, "Generating positions must clear positions_dirty.")
	_assert_true(field.densities_dirty, "Generating positions must not clear densities_dirty.")

	field.generate_density_field()
	_assert_true(not field.densities_dirty, "Generating densities must clear densities_dirty.")
	_assert_true(field.is_data_current(), "Both regenerated channels must report current.")


func _test_noise_change_preserves_stale_density_data() -> void:
	var field := _make_generated_field()
	var old_densities := field.densities.duplicate()

	field.noise.seed += 1

	_assert_true(field.densities_dirty, "Noise changes must dirty densities.")
	_assert_true(field.densities == old_densities, "Noise changes must not destroy stale densities.")


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
