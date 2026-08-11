class_name ChunkStreamer
extends Node3D

## Loads and owns precomputed terrain chunk instances at runtime.
##
## The streamer consumes a lightweight manifest and serialized chunk assets. It
## deliberately knows nothing about point-field generation or meshing so those
## systems remain offline concerns for the asteroid pipeline.


# [b]Signals[/b]
# Reports observable residency changes without exposing storage internals.

signal chunk_loaded(coordinate: Vector3i, instance: MeshInstance3D)
signal chunk_unloaded(coordinate: Vector3i)
signal chunk_load_failed(coordinate: Vector3i, error: Error)


# [b]Configuration[/b]
# Selects the precomputed asset catalog, detail level, and optional runtime target.

## Manifest used to resolve chunk coordinates to serialized assets.
@export var manifest: TerrainChunkManifest

## LOD requested by coordinate-only load calls.
@export var lod_level: int = 0

## Radius, in chunk coordinates, maintained around the residency target.
## A radius of one considers a 3 x 3 x 3 coordinate neighborhood.
@export_range(0, 16, 1) var residency_radius: int = 1

## Optional runtime target whose position drives automatic residency updates.
@export var target: Node3D


# [b]Runtime Storage[/b]
# Tracks only currently resident scene instances.

var _loaded_chunks: Dictionary[Vector3i, MeshInstance3D] = {}


# [b]Runtime Update[/b]
# Converts an explicit scene target into streamer-local residency updates.

func _process(_delta: float) -> void:
	if target != null:
		update_residency(to_local(target.global_position))


# [b]Queries[/b]
# Exposes residency and deterministic chunk-space conversion.

## Returns whether [param coordinate] currently has a resident mesh instance.
func is_chunk_loaded(coordinate: Vector3i) -> bool:
	return _loaded_chunks.has(coordinate)


## Returns the resident mesh instance for [param coordinate], or null.
func get_chunk_instance(coordinate: Vector3i) -> MeshInstance3D:
	return _loaded_chunks.get(coordinate) as MeshInstance3D


## Returns all currently resident chunk coordinates in deterministic x/y/z order.
func get_loaded_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_loaded_chunks.keys())
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates


## Converts a streamer-local terrain position to its containing chunk coordinate.
##
## Chunk extent is derived exclusively from manifest cell dimensions and sample
## spacing. Floor conversion preserves correct behavior for negative positions.
func position_to_chunk_coordinate(local_position: Vector3) -> Vector3i:
	if not _has_valid_manifest_geometry():
		return Vector3i.ZERO

	var extent := _get_chunk_extent()
	return Vector3i(
		floori(local_position.x / extent.x),
		floori(local_position.y / extent.y),
		floori(local_position.z / extent.z)
	)


# [b]Residency[/b]
# Builds neighborhood policy on the existing explicit load/unload API.

## Updates available baked-chunk residency around [param target_position].
##
## [param target_position] is expressed in this streamer's local terrain space.
## Missing manifest coordinates are skipped cleanly. Existing explicit chunk APIs
## remain authoritative for the actual load and unload operations.
func update_residency(target_position: Vector3) -> void:
	if not _has_valid_manifest_geometry():
		return

	var target_coordinate := position_to_chunk_coordinate(target_position)
	var desired: Dictionary[Vector3i, bool] = {}
	for z_offset in range(-residency_radius, residency_radius + 1):
		for y_offset in range(-residency_radius, residency_radius + 1):
			for x_offset in range(-residency_radius, residency_radius + 1):
				var coordinate := target_coordinate + Vector3i(x_offset, y_offset, z_offset)
				if manifest.has_entry(coordinate, lod_level):
					desired[coordinate] = true

	for coordinate in get_loaded_coordinates():
		if not desired.has(coordinate):
			unload_chunk(coordinate)

	var desired_coordinates: Array[Vector3i] = []
	desired_coordinates.assign(desired.keys())
	desired_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in desired_coordinates:
		if not is_chunk_loaded(coordinate):
			load_chunk(coordinate)


## Loads one precomputed chunk and adds its mesh instance as a child.
##
## Duplicate requests are idempotent. Returns an error when the manifest entry,
## resource, or serialized asset contract is invalid.
func load_chunk(coordinate: Vector3i) -> Error:
	if is_chunk_loaded(coordinate):
		return OK
	if manifest == null:
		return _report_load_failure(coordinate, ERR_UNCONFIGURED)

	var entry := manifest.find_entry(coordinate, lod_level)
	if entry == null or not entry.is_valid():
		return _report_load_failure(coordinate, ERR_DOES_NOT_EXIST)

	var asset := _load_chunk_asset(entry)
	if asset == null:
		return _report_load_failure(coordinate, ERR_CANT_OPEN)
	if not asset.is_valid():
		return _report_load_failure(coordinate, ERR_INVALID_DATA)
	if asset.chunk_coordinate != coordinate or asset.lod_level != lod_level:
		return _report_load_failure(coordinate, ERR_INVALID_DATA)

	var instance := MeshInstance3D.new()
	instance.name = "StreamedChunk_%d_%d_%d_L%d" % [
		coordinate.x,
		coordinate.y,
		coordinate.z,
		lod_level,
	]
	instance.mesh = asset.mesh
	instance.position = asset.local_origin
	add_child(instance)
	_loaded_chunks[coordinate] = instance
	chunk_loaded.emit(coordinate, instance)
	return OK


## Unloads one resident chunk. Returns false when it was not loaded.
func unload_chunk(coordinate: Vector3i) -> bool:
	var instance := get_chunk_instance(coordinate)
	if instance == null:
		return false

	_loaded_chunks.erase(coordinate)
	instance.queue_free()
	chunk_unloaded.emit(coordinate)
	return true


## Unloads every resident chunk.
func clear_chunks() -> void:
	var coordinates := get_loaded_coordinates()
	for coordinate in coordinates:
		unload_chunk(coordinate)


# [b]Manifest Geometry[/b]
# Derives chunk-space geometry without duplicating configuration in the streamer.

func _has_valid_manifest_geometry() -> bool:
	return (
		manifest != null
		and manifest.chunk_cell_dimensions.x > 0
		and manifest.chunk_cell_dimensions.y > 0
		and manifest.chunk_cell_dimensions.z > 0
		and manifest.sample_spacing > 0.0
	)


func _get_chunk_extent() -> Vector3:
	return Vector3(manifest.chunk_cell_dimensions) * manifest.sample_spacing


func _coordinate_less_than(a: Vector3i, b: Vector3i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	if a.y != b.y:
		return a.y < b.y
	return a.z < b.z


# [b]Resource Loading[/b]
# Isolates synchronous I/O so a threaded loader can replace it later.

func _load_chunk_asset(entry: TerrainChunkManifestEntry) -> TerrainChunkAsset:
	if not ResourceLoader.exists(entry.asset_path):
		return null
	return ResourceLoader.load(entry.asset_path) as TerrainChunkAsset


func _report_load_failure(coordinate: Vector3i, error: Error) -> Error:
	chunk_load_failed.emit(coordinate, error)
	return error
