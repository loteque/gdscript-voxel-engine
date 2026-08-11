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
# Selects the precomputed asset catalog and default detail level.

## Manifest used to resolve chunk coordinates to serialized assets.
@export var manifest: TerrainChunkManifest

## LOD requested by coordinate-only load calls.
@export var lod_level: int = 0


# [b]Runtime Storage[/b]
# Tracks only currently resident scene instances.

var _loaded_chunks: Dictionary[Vector3i, MeshInstance3D] = {}


# [b]Queries[/b]
# Exposes residency without leaking the dictionary itself.

## Returns whether [param coordinate] currently has a resident mesh instance.
func is_chunk_loaded(coordinate: Vector3i) -> bool:
	return _loaded_chunks.has(coordinate)


## Returns the resident mesh instance for [param coordinate], or null.
func get_chunk_instance(coordinate: Vector3i) -> MeshInstance3D:
	return _loaded_chunks.get(coordinate) as MeshInstance3D


## Returns all currently resident chunk coordinates.
func get_loaded_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_loaded_chunks.keys())
	return coordinates


# [b]Residency[/b]
# Loads and unloads precomputed mesh assets synchronously for the first slice.

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


# [b]Resource Loading[/b]
# Isolates synchronous I/O so a threaded loader can replace it later.

func _load_chunk_asset(entry: TerrainChunkManifestEntry) -> TerrainChunkAsset:
	if not ResourceLoader.exists(entry.asset_path):
		return null
	return ResourceLoader.load(entry.asset_path) as TerrainChunkAsset


func _report_load_failure(coordinate: Vector3i, error: Error) -> Error:
	chunk_load_failed.emit(coordinate, error)
	return error
