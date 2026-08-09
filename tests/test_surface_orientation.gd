extends SceneTree

const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")
const SURFACE_NETS_MESHER := preload("res://voxel/meshing/SurfaceNetsMesher.gd")

var _failed: bool = false


func _initialize() -> void:
	_test_height_field_density_convention()
	_test_flat_ground_normals_point_up()
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

	var mesher := SURFACE_NETS_MESHER.new()
	var mesh: ArrayMesh = mesher.generate_mesh(field, 0.0)
	_assert_true(mesh.get_surface_count() == 1, "Flat ground must generate a mesh surface.")
	if mesh.get_surface_count() == 0:
		return

	var arrays: Array = mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	_assert_true(not normals.is_empty(), "Flat ground must generate normals.")

	for normal in normals:
		_assert_true(
			normal.dot(Vector3.UP) > 0.99,
			"Flat ground normals must point upward. Got %s" % normal
		)


func _test_sphere_normals_point_outward() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(6, 6, 6)
	field.sample_spacing = 1.0
	field.generate_positions()
	field.densities.resize(field.sample_count)

	var radius := 2.0
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


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
