@tool
class_name PointFieldResource
extends Resource

## Represents a regularly sampled scalar field used by terrain meshing.
##
## Owns the field geometry, packed sample channels, indexing rules, density
## generation, and topology queries. Visualization and meshing systems consume
## this resource without owning or duplicating its field data.
##
## A field with [member cell_dimensions] cells contains one additional sample
## along each axis. Therefore, [member sample_dimensions] is always equal to
## [code]cell_dimensions + Vector3i.ONE[/code].


# [b]Signals[/b] Reports granular field changes so consumers update only the data they use.

## Emitted when field dimensions or sample spacing change.
signal geometry_configuration_changed

## Emitted after the packed sample positions change.
signal positions_changed

## Emitted after the packed density values change.
signal densities_changed


# [b]Constants[/b] Defines reusable lattice offsets for cell and neighbor queries.

const CELL_CORNER_OFFSETS: Array[Vector3i] = [
	Vector3i(0, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(1, 1, 0),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 1),
	Vector3i(0, 1, 1),
	Vector3i(1, 1, 1),
]

const FACE_NEIGHBOR_OFFSETS: Array[Vector3i] = [
	Vector3i(-1, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, 0, -1),
	Vector3i(0, 0, 1),
]


# [b]Field Configuration[/b] Stores authoritative geometry and density-generation settings.

## The number of cells along each field axis.
##
## Each component must be at least [code]1[/code]. The number of samples along
## each axis is one greater than the corresponding cell count.
@export var cell_dimensions: Vector3i = Vector3i(16, 16, 16):
	set(value):
		var sanitized_value := Vector3i(
			maxi(value.x, 1),
			maxi(value.y, 1),
			maxi(value.z, 1)
		)
		if cell_dimensions == sanitized_value:
			return
		cell_dimensions = sanitized_value
		_invalidate_geometry()

## The world-space distance between adjacent samples.
@export_range(0.001, 1000.0, 0.001, "or_greater")
var sample_spacing: float = 1.0:
	set(value):
		var sanitized_value := maxf(value, 0.001)
		if is_equal_approx(sample_spacing, sanitized_value):
			return
		sample_spacing = sanitized_value
		_invalidate_geometry()

## The noise resource used to generate sample densities.
@export var noise: FastNoiseLite:
	set(value):
		if noise == value:
			return
		_disconnect_noise()
		noise = value
		_connect_noise()
		_invalidate_densities()

## Scales sample positions before they are evaluated by [member noise].
@export_range(0.0001, 1000.0, 0.0001, "or_greater")
var density_scale: float = 1.0:
	set(value):
		var sanitized_value := maxf(value, 0.0001)
		if is_equal_approx(density_scale, sanitized_value):
			return
		density_scale = sanitized_value
		_invalidate_densities()


# [b]Sample Data[/b] Stores packed channels shared by visualizers and mesh generators.

## World-space position of every sample in x-fastest array order.
@export_storage var positions: PackedVector3Array

## Scalar density of every sample in the same order as [member positions].
@export_storage var densities: PackedFloat32Array


# [b]Derived Geometry[/b] Computes field properties from the authoritative configuration.

## The world-space size covered by all field cells.
var size: Vector3:
	get:
		return Vector3(cell_dimensions) * sample_spacing

## The number of samples along each field axis.
var sample_dimensions: Vector3i:
	get:
		return cell_dimensions + Vector3i.ONE

## The total number of samples stored by the field.
var sample_count: int:
	get:
		return (
			sample_dimensions.x
			* sample_dimensions.y
			* sample_dimensions.z
		)

## The total number of cells in the field.
var cell_count: int:
	get:
		return (
			cell_dimensions.x
			* cell_dimensions.y
			* cell_dimensions.z
		)


# [b]Initialization[/b] Establishes subresource signal connections after construction.

func _init() -> void:
	_connect_noise()


# [b]Generation[/b] Rebuilds authoritative sample channels from the current configuration.

## Regenerates sample positions and densities.
func regenerate() -> void:
	generate_positions()
	generate_density_field()


## Generates all sample positions on a centered, regularly spaced lattice.
func generate_positions() -> void:
	if not validate_configuration():
		positions.clear()
		positions_changed.emit()
		emit_changed()
		return

	positions.resize(sample_count)
	var half_size := size * 0.5

	for z in sample_dimensions.z:
		for y in sample_dimensions.y:
			for x in sample_dimensions.x:
				var coordinates := Vector3i(x, y, z)
				var index := flatten_index(coordinates)
				positions[index] = (
					Vector3(coordinates) * sample_spacing
					- half_size
				)

	positions_changed.emit()
	emit_changed()


## Generates one density value for every sample position.
##
## When no noise resource is assigned, the density channel is filled with
## zeroes so it remains structurally valid.
func generate_density_field() -> void:
	if positions.size() != sample_count:
		generate_positions()

	densities.resize(sample_count)

	if noise == null:
		densities.fill(0.0)
	else:
		for index in sample_count:
			var position := positions[index] * density_scale
			densities[index] = noise.get_noise_3dv(position)

	densities_changed.emit()
	emit_changed()


# [b]Validation[/b] Verifies configuration, storage, coordinates, and cell bounds.

## Returns [code]true[/code] when the field configuration can generate a lattice.
func validate_configuration() -> bool:
	if cell_dimensions.x < 1 or cell_dimensions.y < 1 or cell_dimensions.z < 1:
		push_warning("PointFieldResource cell_dimensions must be at least one on every axis.")
		return false

	if sample_spacing <= 0.0:
		push_warning("PointFieldResource sample_spacing must be greater than zero.")
		return false

	return true


## Returns [code]true[/code] when both packed sample channels match the field geometry.
func validate_data() -> bool:
	return positions.size() == sample_count and densities.size() == sample_count


## Returns [code]true[/code] when the sample coordinates lie inside the field.
func is_sample_in_bounds(coordinates: Vector3i) -> bool:
	return (
		coordinates.x >= 0
		and coordinates.y >= 0
		and coordinates.z >= 0
		and coordinates.x < sample_dimensions.x
		and coordinates.y < sample_dimensions.y
		and coordinates.z < sample_dimensions.z
	)


## Returns [code]true[/code] when the cell coordinates lie inside the field.
func is_cell_in_bounds(coordinates: Vector3i) -> bool:
	return (
		coordinates.x >= 0
		and coordinates.y >= 0
		and coordinates.z >= 0
		and coordinates.x < cell_dimensions.x
		and coordinates.y < cell_dimensions.y
		and coordinates.z < cell_dimensions.z
	)


# [b]Lifecycle[/b] Resizes, clears, and invalidates packed field data safely.

## Changes the field cell dimensions and regenerates all sample data.
func resize(new_cell_dimensions: Vector3i) -> void:
	cell_dimensions = new_cell_dimensions
	regenerate()


## Removes all generated sample positions and densities.
func clear() -> void:
	positions.clear()
	densities.clear()
	positions_changed.emit()
	densities_changed.emit()
	emit_changed()


# [b]Sampling[/b] Provides coordinate-based access to packed position and density channels.

## Returns the position at the given sample coordinates.
##
## Returns [constant Vector3.ZERO] and reports an error when the coordinates are
## outside the field or positions have not been generated.
func get_position(coordinates: Vector3i) -> Vector3:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return Vector3.ZERO

	var index := flatten_index(coordinates)
	if index >= positions.size():
		push_error("PointFieldResource positions have not been generated.")
		return Vector3.ZERO

	return positions[index]


## Returns the density at the given sample coordinates.
##
## Returns [code]0.0[/code] and reports an error when the coordinates are outside
## the field or densities have not been generated.
func get_density(coordinates: Vector3i) -> float:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return 0.0

	var index := flatten_index(coordinates)
	if index >= densities.size():
		push_error("PointFieldResource densities have not been generated.")
		return 0.0

	return densities[index]


## Assigns a density at the given sample coordinates.
func set_density(coordinates: Vector3i, value: float) -> void:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return

	if densities.size() != sample_count:
		densities.resize(sample_count)

	densities[flatten_index(coordinates)] = value
	densities_changed.emit()
	emit_changed()


# [b]Indexing[/b] Converts between 3D sample coordinates and x-fastest packed indices.

## Converts sample coordinates into an x-fastest packed array index.
##
## Returns [code]-1[/code] when the coordinates are outside the sample lattice.
func flatten_index(coordinates: Vector3i) -> int:
	if not is_sample_in_bounds(coordinates):
		return -1

	return (
		coordinates.x
		+ coordinates.y * sample_dimensions.x
		+ coordinates.z * sample_dimensions.x * sample_dimensions.y
	)


## Converts a packed sample index into 3D sample coordinates.
##
## Returns [code]Vector3i(-1, -1, -1)[/code] when the index is outside the
## sample channel.
func coordinates_from_index(index: int) -> Vector3i:
	if index < 0 or index >= sample_count:
		return Vector3i(-1, -1, -1)

	var layer_size := sample_dimensions.x * sample_dimensions.y
	var z := index / layer_size
	var remainder := index % layer_size
	var y := remainder / sample_dimensions.x
	var x := remainder % sample_dimensions.x

	return Vector3i(x, y, z)


# [b]Cell Queries[/b] Retrieves the eight ordered corner samples that bound a field cell.

## Returns the eight sample coordinates that bound the specified cell.
func get_cell_sample_coordinates(cell_coordinates: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if not is_cell_in_bounds(cell_coordinates):
		return result

	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		result[corner_index] = cell_coordinates + CELL_CORNER_OFFSETS[corner_index]

	return result


## Returns the eight sample positions that bound the specified cell.
func get_cell_positions(cell_coordinates: Vector3i) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not is_cell_in_bounds(cell_coordinates):
		return result

	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		var sample_coordinates := cell_coordinates + CELL_CORNER_OFFSETS[corner_index]
		result[corner_index] = get_position(sample_coordinates)

	return result


## Returns the eight sample densities that bound the specified cell.
func get_cell_densities(cell_coordinates: Vector3i) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if not is_cell_in_bounds(cell_coordinates):
		return result

	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		var sample_coordinates := cell_coordinates + CELL_CORNER_OFFSETS[corner_index]
		result[corner_index] = get_density(sample_coordinates)

	return result


# [b]Neighbor Queries[/b] Finds valid face-adjacent samples without exposing storage details.

## Returns all valid face-adjacent sample coordinates around a sample.
func get_neighbors(coordinates: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	if not is_sample_in_bounds(coordinates):
		return neighbors

	for offset in FACE_NEIGHBOR_OFFSETS:
		var neighbor := coordinates + offset
		if is_sample_in_bounds(neighbor):
			neighbors.append(neighbor)

	return neighbors


# [b]Noise Management[/b] Keeps density data synchronized with changes to the noise subresource.

func _connect_noise() -> void:
	if noise == null:
		return
	if not noise.changed.is_connected(_on_noise_changed):
		noise.changed.connect(_on_noise_changed)


func _disconnect_noise() -> void:
	if noise == null:
		return
	if noise.changed.is_connected(_on_noise_changed):
		noise.changed.disconnect(_on_noise_changed)


func _on_noise_changed() -> void:
	generate_density_field()


# [b]Invalidation[/b] Clears stale channels and broadcasts configuration changes to consumers.

func _invalidate_geometry() -> void:
	positions.clear()
	densities.clear()
	geometry_configuration_changed.emit()
	positions_changed.emit()
	densities_changed.emit()
	emit_changed()


func _invalidate_densities() -> void:
	densities.clear()
	densities_changed.emit()
	emit_changed()
