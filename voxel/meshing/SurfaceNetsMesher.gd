class_name SurfaceNetsMesher
extends RefCounted

## Generates an [ArrayMesh] from a [PointFieldResource] using Surface Nets.
##
## The mesher is a stateless consumer of field data. It places one vertex in
## every cell crossed by the iso-surface, then stitches those cell vertices
## around sign-changing sample edges.
##
## Boundary faces require a layer of cells on both sides of a sign-changing
## sample edge. Fields intended to close at their outer boundary should include
## suitable padding samples/cells around the meshed region.


# [b]Constants[/b] Defines the twelve cell edges using PointFieldResource corner ordering.

const CELL_EDGES: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(2, 3),
	Vector2i(4, 5),
	Vector2i(6, 7),
	Vector2i(0, 2),
	Vector2i(1, 3),
	Vector2i(4, 6),
	Vector2i(5, 7),
	Vector2i(0, 4),
	Vector2i(1, 5),
	Vector2i(2, 6),
	Vector2i(3, 7),
]


# [b]Public API[/b] Converts an authoritative scalar field into a triangle mesh.

## Generates a new mesh for [param field] at [param iso_level].
##
## Surface normals point from densities below the iso-level toward densities
## at or above the iso-level.
func generate_mesh(
	field: PointFieldResource,
	iso_level: float = 0.0
) -> ArrayMesh:
	var mesh := ArrayMesh.new()

	if field == null:
		push_error("SurfaceNetsMesher requires a PointFieldResource.")
		return mesh

	if not field.validate_data():
		push_error("SurfaceNetsMesher requires valid generated point-field data.")
		return mesh

	var vertices := PackedVector3Array()
	var cell_vertex_indices := PackedInt32Array()
	cell_vertex_indices.resize(field.cell_count)
	cell_vertex_indices.fill(-1)

	_generate_cell_vertices(
		field,
		iso_level,
		vertices,
		cell_vertex_indices
	)

	if vertices.is_empty():
		return mesh

	var indices := PackedInt32Array()
	_generate_surface_indices(
		field,
		iso_level,
		cell_vertex_indices,
		indices
	)

	if indices.is_empty():
		return mesh

	var normals := _generate_vertex_normals(vertices, indices)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh


# [b]Cell Vertices[/b] Places one Surface Nets vertex in every active field cell.

func _generate_cell_vertices(
	field: PointFieldResource,
	iso_level: float,
	vertices: PackedVector3Array,
	cell_vertex_indices: PackedInt32Array
) -> void:
	for z in field.cell_dimensions.z:
		for y in field.cell_dimensions.y:
			for x in field.cell_dimensions.x:
				var cell_coordinates := Vector3i(x, y, z)
				var surface_vertex := _calculate_cell_surface_vertex(
					field,
					cell_coordinates,
					iso_level
				)

				if surface_vertex == null:
					continue

				var cell_index := _flatten_cell_index(
					cell_coordinates,
					field.cell_dimensions
				)
				cell_vertex_indices[cell_index] = vertices.size()
				vertices.append(surface_vertex)


func _calculate_cell_surface_vertex(
	field: PointFieldResource,
	cell_coordinates: Vector3i,
	iso_level: float
) -> Variant:
	var positions := field.get_cell_positions(cell_coordinates)
	var densities := field.get_cell_densities(cell_coordinates)

	var has_inside := false
	var has_outside := false
	for density in densities:
		if density < iso_level:
			has_inside = true
		else:
			has_outside = true

	if not has_inside or not has_outside:
		return null

	var intersection_sum := Vector3.ZERO
	var intersection_count := 0

	for edge in CELL_EDGES:
		var corner_a := edge.x
		var corner_b := edge.y
		var density_a := densities[corner_a]
		var density_b := densities[corner_b]

		if not _edge_crosses_iso_surface(density_a, density_b, iso_level):
			continue

		intersection_sum += _interpolate_edge_intersection(
			positions[corner_a],
			positions[corner_b],
			density_a,
			density_b,
			iso_level
		)
		intersection_count += 1

	if intersection_count == 0:
		return null

	return intersection_sum / float(intersection_count)


# [b]Surface Topology[/b] Stitches active cell vertices around sign-changing lattice edges.

func _generate_surface_indices(
	field: PointFieldResource,
	iso_level: float,
	cell_vertex_indices: PackedInt32Array,
	indices: PackedInt32Array
) -> void:
	_generate_x_edge_quads(field, iso_level, cell_vertex_indices, indices)
	_generate_y_edge_quads(field, iso_level, cell_vertex_indices, indices)
	_generate_z_edge_quads(field, iso_level, cell_vertex_indices, indices)


func _generate_x_edge_quads(
	field: PointFieldResource,
	iso_level: float,
	cell_vertex_indices: PackedInt32Array,
	indices: PackedInt32Array
) -> void:
	for z in range(1, field.cell_dimensions.z):
		for y in range(1, field.cell_dimensions.y):
			for x in field.cell_dimensions.x:
				var sample_a := Vector3i(x, y, z)
				var sample_b := sample_a + Vector3i.RIGHT
				var density_a := field.get_density(sample_a)
				var density_b := field.get_density(sample_b)

				if not _edge_crosses_iso_surface(density_a, density_b, iso_level):
					continue

				_append_edge_quad(
					field,
					cell_vertex_indices,
					indices,
					[
						Vector3i(x, y - 1, z - 1),
						Vector3i(x, y, z - 1),
						Vector3i(x, y, z),
						Vector3i(x, y - 1, z),
					],
					density_a >= iso_level
				)


func _generate_y_edge_quads(
	field: PointFieldResource,
	iso_level: float,
	cell_vertex_indices: PackedInt32Array,
	indices: PackedInt32Array
) -> void:
	for z in range(1, field.cell_dimensions.z):
		for x in range(1, field.cell_dimensions.x):
			for y in field.cell_dimensions.y:
				var sample_a := Vector3i(x, y, z)
				var sample_b := sample_a + Vector3i.UP
				var density_a := field.get_density(sample_a)
				var density_b := field.get_density(sample_b)

				if not _edge_crosses_iso_surface(density_a, density_b, iso_level):
					continue

				_append_edge_quad(
					field,
					cell_vertex_indices,
					indices,
					[
						Vector3i(x - 1, y, z - 1),
						Vector3i(x - 1, y, z),
						Vector3i(x, y, z),
						Vector3i(x, y, z - 1),
					],
					density_a >= iso_level
				)


func _generate_z_edge_quads(
	field: PointFieldResource,
	iso_level: float,
	cell_vertex_indices: PackedInt32Array,
	indices: PackedInt32Array
) -> void:
	for y in range(1, field.cell_dimensions.y):
		for x in range(1, field.cell_dimensions.x):
			for z in field.cell_dimensions.z:
				var sample_a := Vector3i(x, y, z)
				var sample_b := sample_a + Vector3i.BACK
				var density_a := field.get_density(sample_a)
				var density_b := field.get_density(sample_b)

				if not _edge_crosses_iso_surface(density_a, density_b, iso_level):
					continue

				_append_edge_quad(
					field,
					cell_vertex_indices,
					indices,
					[
						Vector3i(x - 1, y - 1, z),
						Vector3i(x, y - 1, z),
						Vector3i(x, y, z),
						Vector3i(x - 1, y, z),
					],
					density_a >= iso_level
				)


func _append_edge_quad(
	field: PointFieldResource,
	cell_vertex_indices: PackedInt32Array,
	indices: PackedInt32Array,
	cell_coordinates: Array[Vector3i],
	reverse_winding: bool
) -> void:
	var quad := PackedInt32Array()
	quad.resize(4)

	for corner in 4:
		var cell_index := _flatten_cell_index(
			cell_coordinates[corner],
			field.cell_dimensions
		)
		var vertex_index := cell_vertex_indices[cell_index]
		if vertex_index < 0:
			return
		quad[corner] = vertex_index

	if reverse_winding:
		indices.append_array(
			PackedInt32Array([
				quad[0], quad[3], quad[2],
				quad[0], quad[2], quad[1],
			])
		)
	else:
		indices.append_array(
			PackedInt32Array([
				quad[0], quad[1], quad[2],
				quad[0], quad[2], quad[3],
			])
		)


# [b]Normals[/b] Builds smooth area-weighted normals from the generated triangle topology.

func _generate_vertex_normals(
	vertices: PackedVector3Array,
	indices: PackedInt32Array
) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.ZERO)

	for triangle_start in range(0, indices.size(), 3):
		var index_a := indices[triangle_start]
		var index_b := indices[triangle_start + 1]
		var index_c := indices[triangle_start + 2]
		var edge_ab := vertices[index_b] - vertices[index_a]
		var edge_ac := vertices[index_c] - vertices[index_a]
		var face_normal := edge_ab.cross(edge_ac)

		if face_normal.is_zero_approx():
			continue

		normals[index_a] = normals[index_a] + face_normal
		normals[index_b] = normals[index_b] + face_normal
		normals[index_c] = normals[index_c] + face_normal

	for index in normals.size():
		if not normals[index].is_zero_approx():
			normals[index] = normals[index].normalized()

	return normals


# [b]Interpolation[/b] Finds where an iso-surface crosses a sampled field edge.

func _edge_crosses_iso_surface(
	density_a: float,
	density_b: float,
	iso_level: float
) -> bool:
	return (density_a < iso_level) != (density_b < iso_level)


func _interpolate_edge_intersection(
	position_a: Vector3,
	position_b: Vector3,
	density_a: float,
	density_b: float,
	iso_level: float
) -> Vector3:
	var density_delta := density_b - density_a
	if is_zero_approx(density_delta):
		return (position_a + position_b) * 0.5

	var weight := clampf(
		(iso_level - density_a) / density_delta,
		0.0,
		1.0
	)
	return position_a.lerp(position_b, weight)


# [b]Cell Indexing[/b] Maintains a compact x-fastest lookup for generated cell vertices.

func _flatten_cell_index(
	coordinates: Vector3i,
	dimensions: Vector3i
) -> int:
	return (
		coordinates.x
		+ coordinates.y * dimensions.x
		+ coordinates.z * dimensions.x * dimensions.y
	)
