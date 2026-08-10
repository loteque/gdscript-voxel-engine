@tool
class_name PointFieldResource
extends Resource

## Represents a regularly sampled scalar field used by terrain meshing.
##
## Owns field configuration, packed sample channels, indexing rules, density
## generation, and explicit channel freshness state. Configuration changes mark
## generated channels dirty without destroying the previous sample data.
##
## Density convention:
## - values greater than the iso-level represent solid material,
## - values lower than the iso-level represent empty space,
## - values equal to the iso-level lie on the surface.


# [b]Signals[/b]

## Emitted when field dimensions or sample spacing change.
signal geometry_configuration_changed

## Emitted when either generated channel changes between current and dirty.
signal data_state_changed

## Emitted after the packed sample positions actually change.
signal positions_changed

## Emitted after the packed density values actually change.
signal densities_changed


# [b]Constants[/b]

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


# [b]Field Configuration[/b]

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
		_mark_geometry_dirty()

@export_range(0.001, 1000.0, 0.001, "or_greater")
var sample_spacing: float = 1.0:
	set(value):
		var sanitized_value := maxf(value, 0.001)
		if is_equal_approx(sample_spacing, sanitized_value):
			return
		sample_spacing = sanitized_value
		_mark_geometry_dirty()

@export var noise: FastNoiseLite:
	set(value):
		if noise == value:
			return
		_disconnect_noise()
		noise = value
		_connect_noise()
		_mark_densities_dirty()

@export_range(0.0001, 1000.0, 0.0001, "or_greater")
var density_scale: float = 1.0:
	set(value):
		var sanitized_value := maxf(value, 0.0001)
		if is_equal_approx(density_scale, sanitized_value):
			return
		density_scale = sanitized_value
		_mark_densities_dirty()

@export_range(-10000.0, 10000.0, 0.01, "or_greater", "or_less")
var terrain_base_height: float = 0.0:
	set(value):
		if is_equal_approx(terrain_base_height, value):
			return
		terrain_base_height = value
		_mark_densities_dirty()

@export_range(0.0, 10000.0, 0.01, "or_greater")
var terrain_height_scale: float = 4.0:
	set(value):
		var sanitized_value := maxf(value, 0.0)
		if is_equal_approx(terrain_height_scale, sanitized_value):
			return
		terrain_height_scale = sanitized_value
		_mark_densities_dirty()


# [b]Sample Data[/b]

@export_storage var positions: PackedVector3Array
@export_storage var densities: PackedFloat32Array

## Stored so a saved generated field retains whether its channels are current.
@export_storage var _positions_dirty: bool = true
@export_storage var _densities_dirty: bool = true

## True when stored positions no longer represent the current geometry settings.
var positions_dirty: bool:
	get:
		return _positions_dirty

## True when stored densities no longer represent the current density settings.
var densities_dirty: bool:
	get:
		return _densities_dirty


# [b]Derived Geometry[/b]

var size: Vector3:
	get:
		return Vector3(cell_dimensions) * sample_spacing

var sample_dimensions: Vector3i:
	get:
		return cell_dimensions + Vector3i.ONE

var sample_count: int:
	get:
		return sample_dimensions.x * sample_dimensions.y * sample_dimensions.z

var cell_count: int:
	get:
		return cell_dimensions.x * cell_dimensions.y * cell_dimensions.z


# [b]Initialization[/b]

func _init() -> void:
	_connect_noise()


# [b]Generation[/b]

func regenerate() -> void:
	generate_positions()
	generate_density_field()


func generate_positions() -> void:
	if not validate_configuration():
		positions.clear()
		_set_positions_dirty(true)
		_set_densities_dirty(true)
		positions_changed.emit()
		emit_changed()
		return

	_set_densities_dirty(true)
	positions.resize(sample_count)
	var half_size := size * 0.5

	for z in sample_dimensions.z:
		for y in sample_dimensions.y:
			for x in sample_dimensions.x:
				var coordinates := Vector3i(x, y, z)
				var index := flatten_index(coordinates)
				positions[index] = Vector3(coordinates) * sample_spacing - half_size

	_set_positions_dirty(false)
	positions_changed.emit()
	emit_changed()


func generate_density_field() -> void:
	if positions_dirty or positions.size() != sample_count:
		generate_positions()

	if positions_dirty or positions.size() != sample_count:
		return

	densities.resize(sample_count)
	for index in sample_count:
		var position := positions[index]
		var terrain_height := terrain_base_height
		if noise != null:
			terrain_height += noise.get_noise_2d(
				position.x * density_scale,
				position.z * density_scale
			) * terrain_height_scale
		densities[index] = terrain_height - position.y

	_set_densities_dirty(false)
	densities_changed.emit()
	emit_changed()


# [b]Validation and State[/b]

func validate_configuration() -> bool:
	if cell_dimensions.x < 1 or cell_dimensions.y < 1 or cell_dimensions.z < 1:
		push_warning("PointFieldResource cell_dimensions must be at least one on every axis.")
		return false
	if sample_spacing <= 0.0:
		push_warning("PointFieldResource sample_spacing must be greater than zero.")
		return false
	return true


## Structural validation only. Freshness is reported by the dirty flags.
func validate_data() -> bool:
	return positions.size() == sample_count and densities.size() == sample_count


## Returns true only when both channels are structurally complete and current.
func is_data_current() -> bool:
	return validate_data() and not positions_dirty and not densities_dirty


func is_sample_in_bounds(coordinates: Vector3i) -> bool:
	return (
		coordinates.x >= 0
		and coordinates.y >= 0
		and coordinates.z >= 0
		and coordinates.x < sample_dimensions.x
		and coordinates.y < sample_dimensions.y
		and coordinates.z < sample_dimensions.z
	)


func is_cell_in_bounds(coordinates: Vector3i) -> bool:
	return (
		coordinates.x >= 0
		and coordinates.y >= 0
		and coordinates.z >= 0
		and coordinates.x < cell_dimensions.x
		and coordinates.y < cell_dimensions.y
		and coordinates.z < cell_dimensions.z
	)


# [b]Lifecycle[/b]

func resize(new_cell_dimensions: Vector3i) -> void:
	cell_dimensions = new_cell_dimensions
	regenerate()


func clear() -> void:
	positions.clear()
	densities.clear()
	_set_positions_dirty(true)
	_set_densities_dirty(true)
	positions_changed.emit()
	densities_changed.emit()
	emit_changed()


# [b]Sampling[/b]

func get_position(coordinates: Vector3i) -> Vector3:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return Vector3.ZERO
	var index := flatten_index(coordinates)
	if index >= positions.size():
		push_error("PointFieldResource positions have not been generated.")
		return Vector3.ZERO
	return positions[index]


func get_density(coordinates: Vector3i) -> float:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return 0.0
	var index := flatten_index(coordinates)
	if index >= densities.size():
		push_error("PointFieldResource densities have not been generated.")
		return 0.0
	return densities[index]


func set_density(coordinates: Vector3i, value: float) -> void:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return
	if densities.size() != sample_count:
		densities.resize(sample_count)
	densities[flatten_index(coordinates)] = value
	densities_changed.emit()
	emit_changed()


# [b]Indexing[/b]

func flatten_index(coordinates: Vector3i) -> int:
	if not is_sample_in_bounds(coordinates):
		return -1
	return (
		coordinates.x
		+ coordinates.y * sample_dimensions.x
		+ coordinates.z * sample_dimensions.x * sample_dimensions.y
	)


func coordinates_from_index(index: int) -> Vector3i:
	if index < 0 or index >= sample_count:
		return Vector3i(-1, -1, -1)
	var layer_size := sample_dimensions.x * sample_dimensions.y
	var z := index / layer_size
	var remainder := index % layer_size
	var y := remainder / sample_dimensions.x
	var x := remainder % sample_dimensions.x
	return Vector3i(x, y, z)


# [b]Cell Queries[/b]

func get_cell_sample_coordinates(cell_coordinates: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if not is_cell_in_bounds(cell_coordinates):
		return result
	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		result[corner_index] = cell_coordinates + CELL_CORNER_OFFSETS[corner_index]
	return result


func get_cell_positions(cell_coordinates: Vector3i) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not is_cell_in_bounds(cell_coordinates):
		return result
	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		var sample_coordinates := cell_coordinates + CELL_CORNER_OFFSETS[corner_index]
		result[corner_index] = get_position(sample_coordinates)
	return result


func get_cell_densities(cell_coordinates: Vector3i) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if not is_cell_in_bounds(cell_coordinates):
		return result
	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		var sample_coordinates := cell_coordinates + CELL_CORNER_OFFSETS[corner_index]
		result[corner_index] = get_density(sample_coordinates)
	return result


# [b]Neighbor Queries[/b]

func get_neighbors(coordinates: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	if not is_sample_in_bounds(coordinates):
		return neighbors
	for offset in FACE_NEIGHBOR_OFFSETS:
		var neighbor := coordinates + offset
		if is_sample_in_bounds(neighbor):
			neighbors.append(neighbor)
	return neighbors


# [b]Noise Management[/b]

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
	_mark_densities_dirty()


# [b]Freshness State[/b]

func _mark_geometry_dirty() -> void:
	var state_changed := not _positions_dirty or not _densities_dirty
	_positions_dirty = true
	_densities_dirty = true
	geometry_configuration_changed.emit()
	if state_changed:
		data_state_changed.emit()
	emit_changed()


func _mark_densities_dirty() -> void:
	var state_changed := not _densities_dirty
	_densities_dirty = true
	if state_changed:
		data_state_changed.emit()
	emit_changed()


func _set_positions_dirty(value: bool) -> void:
	if _positions_dirty == value:
		return
	_positions_dirty = value
	data_state_changed.emit()


func _set_densities_dirty(value: bool) -> void:
	if _densities_dirty == value:
		return
	_densities_dirty = value
	data_state_changed.emit()
