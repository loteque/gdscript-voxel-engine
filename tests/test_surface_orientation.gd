extends SceneTree

const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")
const SURFACE_NETS_MESHER := preload("res://voxel/meshing/SurfaceNetsMesher.gd")

var _failed: bool = false


func _initialize() -> void:
	_test_height_field_density_convention()
	_test_flat_ground_normals_point_up()
	_test_x_plane_normals_point_right()
	_test_z_plane_normals_point_back()
	_test_sphere_normals_point_outward()

	if _failed:
		quit(1)
	else:
		print("Surface orientation tests passed.")
		quit(0)


func _test_height_field_density_convention() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.sample_spacing = 1.0
	field.noise = null
	field.terrain_base_height = 0.25
	field.terrain_height_scale = 0.0
	field.regenerate()

	_assert_true(
		field.get_density(Vector3i(2, 0, 2)) > 0.0,
		"Samples below terrain must be solid (positive density)."
	)
	_assert_true(
		field.get_density(Vector3i(2, 4, 2)) < 0.0,
		"Samples above terrain must be empty (negative density)."
	)


func _test_flat_ground_normals_point_up() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.sample_spacing = 1.0
	field.noise = null
	field.terrain_base_height = 0.25
	field.terrain_height_scale = 0.0
	field.regenerate()

	_assert_mesh_normals_face(field, Vector3.UP, "Flat ground normals must point upward.")


func _test_x_plane_normals_point_right() -> void:
	var field := _make_manual_field(Vector3i(4, 4, 4))
	for index in field.sample_count:
		var position := field.positions[index]
		field.densities[index] = 0.25 - position.x

	_assert_mesh_normals_face(field, Vector3.RIGHT, "X-plane normals must point toward +X.")


func _test_z_plane_normals_point_back() -> void:
	var field := _make_manual_field(Vector3i(4, 4, 4))
	for index in field.sample_count:
		var position := field.positions[index]
		field.densities[index] = 0.25 - position.z

	_assert_mesh_normals_face(field, Vector3.BACK, "Z-plane normals must point toward +Z.")


func _test_sphere_normals_point_outward() -> void:
	var field := _make_manual_field(Vector3i(6, 6, 6))

	# Keep the iso-surface away from exact lattice samples. Exact endpoint hits are
	# a separate Surface Nets degeneracy case and should not muddy orientation.
	var radius := 2.25
	for index in field.sample_count:
		var position := field.positions[index]
		field.densities[index] = radius - position.length()

	var mesher := SURFACE_NETS_MESHER.new()
	var mesh: ArrayMesh = mesher.generate_mesh(field, 0.0)
	_assert_true(mesh.get_surface_count() == 1, "Sphere field must generate a mesh surface.")
	if mesh.get_surface_count() == 0:
		return

	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]

	for index in vertices.size():
		if vertices[index].is_zero_approx():
			continue
		var outward := vertices[index].normalized()
		_assert_true(
			normals[index].dot(outward) > 0.5,
			"Closed-volume normals must point out of solid material."
		)


func _make_manual_field(dimensions: Vector3i) -> PointFieldResource:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = dimensions
	field.sample_spacing = 1.0
	field.generate_positions()
	field.densities.resize(field.sample_count)
	return field


func _assert_mesh_normals_face(
	field: PointFieldResource,
	expected_direction: Vector3,
	message: String
) -> void:
	var mesher := SURFACE_NETS_MESHER.new()
	var mesh: ArrayMesh = mesher.generate_mesh(field, 0.0)
	_assert_true(mesh.get_surface_count() == 1, "%s Mesh surface was not generated." % message)
	if mesh.get_surface_count() == 0:
		return

	var arrays: Array = mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	_assert_true(not normals.is_empty(), "%s Normals were not generated." % message)

	for normal in normals:
		_assert_true(
			normal.dot(expected_direction) > 0.99,
			"%s Got %s" % [message, normal]
		)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
