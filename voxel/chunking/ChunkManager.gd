@tool
class_name ChunkManager
extends Node3D

## Owns the runtime collection and coordinate mapping for terrain chunks.
##
## Chunk coordinates are integer cell-region coordinates in this node's local
## terrain space. Coordinate (0, 0, 0) spans from local origin to one chunk
## extent on each axis. Negative coordinates extend naturally into negative
## terrain space.
##
## This manager owns chunk lifecycle and spatial mapping only. It does not mesh
## fields, choose streaming policy, or generate density values itself.


# [b]Signals[/b]

signal chunk_added(chunk: TerrainChunk)
signal chunk_removed(coordinate: Vector3i)


# [b]Chunk Configuration[/b]

## Number of cells contained by every managed chunk.
@export var chunk_cell_dimensions: Vector3i = Vector3i(16, 16, 16):
	set(value):
		var sanitized_value := Vector3i(
			maxi(value.x, 1),
			maxi(value.y, 1),
			maxi(value.z, 1)
		)
		if chunk_cell_dimensions == sanitized_value:
			return
		chunk_cell_dimensions = sanitized_value
		_reconfigure_chunks()

## Distance between adjacent field samples.
@export_range(0.001, 1000.0, 0.001, "or_greater")
var sample_spacing: float = 1.0:
	set(value):
		var sanitized_value := maxf(value, 0.001)
		if is_equal_approx(sample_spacing, sanitized_value):
			return
		sample_spacing = sanitized_value
		_reconfigure_chunks()

## Optional field settings copied into newly created chunks.
##
## Generated sample arrays are cleared on the copy. Subresources such as a
## FastNoiseLite instance remain shared so one terrain-generation configuration
## can drive all chunks consistently.
@export var field_template: PointFieldResource


# [b]Chunk Storage[/b]

var _chunks: Dictionary[Vector3i, TerrainChunk] = {}


# [b]Derived Geometry[/b]

## Physical extent of one chunk in terrain-local space.
var chunk_extent: Vector3:
	get:
		return Vector3(chunk_cell_dimensions) * sample_spacing


# [b]Coordinate Mapping[/b]

## Returns the minimum terrain-local corner of a chunk.
func chunk_coordinate_to_local_origin(coordinate: Vector3i) -> Vector3:
	var extent := chunk_extent
	return Vector3(
		coordinate.x * extent.x,
		coordinate.y * extent.y,
		coordinate.z * extent.z
	)


## Returns the terrain-local center used to place a chunk node and sample field.
func chunk_coordinate_to_local_center(coordinate: Vector3i) -> Vector3:
	return chunk_coordinate_to_local_origin(coordinate) + chunk_extent * 0.5


## Converts a terrain-local position to its containing integer chunk coordinate.
func local_position_to_chunk_coordinate(local_position: Vector3) -> Vector3i:
	var extent := chunk_extent
	return Vector3i(
		floori(local_position.x / extent.x),
		floori(local_position.y / extent.y),
		floori(local_position.z / extent.z)
	)


## Converts a global scene position through this manager's transform first.
func global_position_to_chunk_coordinate(world_position: Vector3) -> Vector3i:
	return local_position_to_chunk_coordinate(to_local(world_position))


# [b]Chunk Queries[/b]

func has_chunk(coordinate: Vector3i) -> bool:
	return _chunks.has(coordinate)


func get_chunk(coordinate: Vector3i) -> TerrainChunk:
	return _chunks.get(coordinate) as TerrainChunk


func get_chunk_count() -> int:
	return _chunks.size()


func get_chunk_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_chunks.keys())
	return coordinates


# [b]Chunk Lifecycle[/b]

## Creates a configured chunk, or returns the existing chunk at that coordinate.
## Field generation is deliberately explicit so callers can schedule it later.
func create_chunk(coordinate: Vector3i) -> TerrainChunk:
	var existing := get_chunk(coordinate)
	if existing != null:
		return existing

	var chunk := TerrainChunk.new()
	chunk.name = "TerrainChunk_%d_%d_%d" % [
		coordinate.x,
		coordinate.y,
		coordinate.z,
	]
	add_child(chunk)

	var field := _create_chunk_field()
	chunk.configure(
		coordinate,
		field,
		chunk_coordinate_to_local_center(coordinate)
	)
	_chunks[coordinate] = chunk
	chunk_added.emit(chunk)
	return chunk


## Removes one managed chunk from the scene tree.
func remove_chunk(coordinate: Vector3i) -> bool:
	var chunk := get_chunk(coordinate)
	if chunk == null:
		return false

	_chunks.erase(coordinate)
	chunk.queue_free()
	chunk_removed.emit(coordinate)
	return true


## Removes every managed chunk.
func clear_chunks() -> void:
	var coordinates := get_chunk_coordinates()
	for coordinate in coordinates:
		remove_chunk(coordinate)


# [b]Field Construction[/b]

func _create_chunk_field() -> PointFieldResource:
	var field: PointFieldResource
	if field_template != null:
		field = field_template.duplicate(false) as PointFieldResource
	else:
		field = PointFieldResource.new()

	field.clear()
	field.cell_dimensions = chunk_cell_dimensions
	field.sample_spacing = sample_spacing
	return field


# [b]Reconfiguration[/b]

## Keeps existing chunk geometry aligned when manager-level dimensions change.
## Regeneration remains explicit so this operation can later feed a work queue.
func _reconfigure_chunks() -> void:
	if _chunks == null or _chunks.is_empty():
		return

	for coordinate in _chunks:
		var chunk := _chunks[coordinate]
		if chunk == null or chunk.point_field == null:
			continue

		chunk.point_field.cell_dimensions = chunk_cell_dimensions
		chunk.point_field.sample_spacing = sample_spacing
		chunk.configure(
			coordinate,
			chunk.point_field,
			chunk_coordinate_to_local_center(coordinate)
		)
