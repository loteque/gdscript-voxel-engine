@tool
class_name PointFieldResource
extends Resource

## Represents a regularly sampled scalar field used by terrain meshing.
##
## Owns field configuration, packed sample channels, indexing rules, density
## generation, and explicit channel freshness state. Configuration changes mark
## generated channels dirty without destroying the previous sample data.
##
## Positions are stored in field-local space centered around the field origin.
## Density generation can offset those positions into a continuous sampling
## space through [member sampling_origin]. This lets independently generated
## chunks share identical boundary samples without placing mesh vertices in
## global coordinates.
##
## Density convention:
## - values greater than the iso-level represent solid material,
## - values lower than the iso-level represent empty space,
## - values equal to the iso-level lie on the surface.


# [b]Signals[/b]
# Reports configuration, freshness, and packed-channel changes.

## Emitted when field dimensions or sample spacing change.
signal geometry_configuration_changed

## Emitted when either generated channel changes between current and dirty.
signal data_state_changed

## Emitted after the packed sample positions actually change.
signal positions_changed

## Emitted after the packed density values actually change.
signal densities_changed


# [b]Constants[/b]
# Defines stable cell-corner and face-neighbor ordering.

const CELL_CORNER_OFFSETS: Array[Vector3i] = [
	Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 0),
	Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(0, 1, 1), Vector3i(1, 1, 1),
]

const FACE_NEIGHBOR_OFFSETS: Array[Vector3i] = [
	Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, -1, 0),
	Vector3i(0, 1, 0), Vector3i(0, 0, -1), Vector3i(0, 0, 1),
]


# [b]Field Configuration[/b]
# Describes regular-lattice geometry and the built-in density generator.

@export var cell_dimensions: Vector3i = Vector3i(16, 16, 16):
	set(value):
		var sanitized_value := Vector3i(maxi(value.x, 1), maxi(value.y, 1), maxi(value.z, 1))
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

## Offset from field-local coordinates into the continuous density-sampling space.
@export var sampling_origin: Vector3 = Vector3.ZERO:
	set(value):
		if sampling_origin.is_equal_approx(value):
			return
		sampling_origin = value
		_mark_densities_dirty()

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
# Stores the authoritative packed sample channels and freshness flags.

@export_storage var positions: PackedVector3Array
@export_storage var densities: PackedFloat32Array
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
# Exposes cell and sample extents without duplicating stored state.

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
# Restores noise change tracking for newly constructed resources.

func _init() -> void:
	_connect_noise()


# [b]Generation[/b]
# Generates regular-lattice positions and the built-in height-field densities.

## Regenerates both sample channels from the current configuration.
func regenerate() -> void:
	generate_positions()
	generate_density_field()

## Regenerates field-local sample positions in x-fastest storage order.
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
				positions[flatten_index(coordinates)] = Vector3(coordinates) * sample_spacing - half_size

	_set_positions_dirty(false)
	positions_changed.emit()
	emit_changed()

## Regenerates the complete density channel from current generation settings.
func generate_density_field() -> void:
	if positions_dirty or positions.size() != sample_count:
		generate_positions()
	if positions_dirty or positions.size() != sample_count:
		return

	densities.resize(sample_count)
	for index in sample_count:
		var sampling_position := sampling_origin + positions[index]
		var terrain_height := terrain_base_height
		if noise != null:
			terrain_height += noise.get_noise_2d(
				sampling_position.x * density_scale,
				sampling_position.z * density_scale
			) * terrain_height_scale
		densities[index] = terrain_height - sampling_position.y

	_set_densities_dirty(false)
	densities_changed.emit()
	emit_changed()


# [b]Validation and State[/b]
# Separates configuration validity, structural completeness, and freshness.

## Returns whether the regular-lattice configuration is valid.
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

## Returns whether [param coordinates] address a valid sample.
func is_sample_in_bounds(coordinates: Vector3i) -> bool:
	return coordinates.x >= 0 and coordinates.y >= 0 and coordinates.z >= 0 \
		and coordinates.x < sample_dimensions.x and coordinates.y < sample_dimensions.y \
		and coordinates.z < sample_dimensions.z

## Returns whether [param coordinates] address a valid cell.
func is_cell_in_bounds(coordinates: Vector3i) -> bool:
	return coordinates.x >= 0 and coordinates.y >= 0 and coordinates.z >= 0 \
		and coordinates.x < cell_dimensions.x and coordinates.y < cell_dimensions.y \
		and coordinates.z < cell_dimensions.z


# [b]Lifecycle[/b]
# Resizes or clears field data while preserving the resource contract.

## Resizes the logical cell lattice and regenerates both channels.
func resize(new_cell_dimensions: Vector3i) -> void:
	cell_dimensions = new_cell_dimensions
	regenerate()

## Clears generated sample channels and marks them dirty.
func clear() -> void:
	positions.clear()
	densities.clear()
	_set_positions_dirty(true)
	_set_densities_dirty(true)
	positions_changed.emit()
	densities_changed.emit()
	emit_changed()


# [b]Sampling[/b]
# Provides controlled access to field samples and complete density replacement.

## Returns the field-local generated position for [param coordinates].
func get_position(coordinates: Vector3i) -> Vector3:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return Vector3.ZERO
	var index := flatten_index(coordinates)
	if index >= positions.size():
		push_error("PointFieldResource positions have not been generated.")
		return Vector3.ZERO
	return positions[index]

## Returns a generated sample position in the continuous density-sampling space.
func get_sampling_position(coordinates: Vector3i) -> Vector3:
	return sampling_origin + get_position(coordinates)

## Returns the stored density for [param coordinates].
func get_density(coordinates: Vector3i) -> float:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return 0.0
	var index := flatten_index(coordinates)
	if index >= densities.size():
		push_error("PointFieldResource densities have not been generated.")
		return 0.0
	return densities[index]

## Sets one density sample without changing the channel's existing freshness state.
func set_density(coordinates: Vector3i, value: float) -> void:
	if not is_sample_in_bounds(coordinates):
		push_error("Sample coordinates are outside the point field: %s" % coordinates)
		return
	if densities.size() != sample_count:
		densities.resize(sample_count)
	densities[flatten_index(coordinates)] = value
	densities_changed.emit()
	emit_changed()

## Replaces the complete density channel and marks it current.
##
## Positions must already be current because densities correspond to the current
## regular-lattice geometry. The input is duplicated so callers retain ownership.
func set_density_data(values: PackedFloat32Array) -> bool:
	if positions_dirty or positions.size() != sample_count:
		push_error("PointFieldResource requires current positions before replacing density data.")
		return false
	if values.size() != sample_count:
		push_error("Density data size %d does not match sample count %d." % [values.size(), sample_count])
		return false

	densities = values.duplicate()
	_set_densities_dirty(false)
	densities_changed.emit()
	emit_changed()
	return true


# [b]Indexing[/b]
# Converts between field coordinates and compact x-fastest array indices.

## Returns the x-fastest flat sample index, or -1 when out of bounds.
func flatten_index(coordinates: Vector3i) -> int:
	if not is_sample_in_bounds(coordinates):
		return -1
	return coordinates.x + coordinates.y * sample_dimensions.x \
		+ coordinates.z * sample_dimensions.x * sample_dimensions.y

## Returns sample coordinates represented by [param index].
func coordinates_from_index(index: int) -> Vector3i:
	if index < 0 or index >= sample_count:
		return Vector3i(-1, -1, -1)
	var layer_size := sample_dimensions.x * sample_dimensions.y
	var z := index / layer_size
	var remainder := index % layer_size
	var y := remainder / sample_dimensions.x
	var x := remainder % sample_dimensions.x
	return Vector3i(x, y, z)

## Returns the x-fastest flat cell index, or -1 when out of bounds.
func flatten_cell_index(coordinates: Vector3i) -> int:
	if not is_cell_in_bounds(coordinates):
		return -1
	return coordinates.x + coordinates.y * cell_dimensions.x \
		+ coordinates.z * cell_dimensions.x * cell_dimensions.y

## Returns the cell coordinates represented by [param index].
func cell_coordinates_from_index(index: int) -> Vector3i:
	if index < 0 or index >= cell_count:
		return Vector3i(-1, -1, -1)
	var layer_size := cell_dimensions.x * cell_dimensions.y
	var z := index / layer_size
	var remainder := index % layer_size
	var y := remainder / cell_dimensions.x
	var x := remainder % cell_dimensions.x
	return Vector3i(x, y, z)


# [b]Cell Queries[/b]
# Exposes stable cell-corner sample ordering for meshing algorithms.

## Returns the eight sample coordinates for a cell in stable corner order.
func get_cell_sample_coordinates(cell_coordinates: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if not is_cell_in_bounds(cell_coordinates):
		return result
	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		result[corner_index] = cell_coordinates + CELL_CORNER_OFFSETS[corner_index]
	return result

## Returns the eight field-local sample positions for a cell.
func get_cell_positions(cell_coordinates: Vector3i) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not is_cell_in_bounds(cell_coordinates):
		return result
	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		result[corner_index] = get_position(cell_coordinates + CELL_CORNER_OFFSETS[corner_index])
	return result

## Returns the eight sample densities for a cell.
func get_cell_densities(cell_coordinates: Vector3i) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if not is_cell_in_bounds(cell_coordinates):
		return result
	result.resize(CELL_CORNER_OFFSETS.size())
	for corner_index in CELL_CORNER_OFFSETS.size():
		result[corner_index] = get_density(cell_coordinates + CELL_CORNER_OFFSETS[corner_index])
	return result


# [b]Neighbor Queries[/b]
# Returns valid face-adjacent samples without embedding mesher policy.

## Returns valid face neighbors for [param coordinates].
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
# Tracks built-in generator resource changes without exposing them to consumers.

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
# Centralizes transitions between generated and stale sample channels.

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
