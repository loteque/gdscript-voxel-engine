class_name ChunkStreamer
extends Node3D

## Loads and owns precomputed terrain chunk instances at runtime.
##
## The streamer consumes a lightweight manifest and serialized chunk assets. It
## deliberately knows nothing about point-field generation or meshing so those
## systems remain offline concerns for the asteroid pipeline.


enum ChunkLoadState {
	UNLOADED,
	QUEUED,
	LOADING,
	RESIDENT,
}


class ChunkLoadRequest:
	extends RefCounted

	var coordinate: Vector3i
	var asset_path: String
	var state: ChunkLoadState = ChunkLoadState.QUEUED

	func _init(request_coordinate: Vector3i, request_asset_path: String) -> void:
		coordinate = request_coordinate
		asset_path = request_asset_path


# [b]Signals[/b]
# Reports observable loading and residency changes without exposing storage internals.

signal chunk_load_queued(coordinate: Vector3i)
signal chunk_load_started(coordinate: Vector3i)
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
# Separates pending loading work from currently resident scene instances.

var _loaded_chunks: Dictionary[Vector3i, MeshInstance3D] = {}
var _load_requests: Dictionary[Vector3i, ChunkLoadRequest] = {}


# [b]Runtime Update[/b]
# Runs residency policy and loading execution as separate stages each frame.

func _process(_delta: float) -> void:
	if target != null:
		update_residency(to_local(target.global_position))

	_poll_loading_requests()
	_start_queued_loads()


# [b]Queries[/b]
# Exposes residency, pending work, and deterministic chunk-space conversion.

## Returns whether [param coordinate] currently has a resident mesh instance.
func is_chunk_loaded(coordinate: Vector3i) -> bool:
	return _loaded_chunks.has(coordinate)


## Returns whether [param coordinate] currently has queued or loading work.
func is_chunk_pending(coordinate: Vector3i) -> bool:
	return _load_requests.has(coordinate)


## Returns the current loading lifecycle state for [param coordinate].
func get_chunk_load_state(coordinate: Vector3i) -> ChunkLoadState:
	if is_chunk_loaded(coordinate):
		return ChunkLoadState.RESIDENT

	var request := _load_requests.get(coordinate) as ChunkLoadRequest
	if request != null:
		return request.state
	return ChunkLoadState.UNLOADED


## Returns the resident mesh instance for [param coordinate], or null.
func get_chunk_instance(coordinate: Vector3i) -> MeshInstance3D:
	return _loaded_chunks.get(coordinate) as MeshInstance3D


## Returns all currently resident chunk coordinates in deterministic x/y/z order.
func get_loaded_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_loaded_chunks.keys())
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates


## Returns all queued or loading chunk coordinates in deterministic x/y/z order.
func get_pending_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_load_requests.keys())
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
## remain authoritative for requesting and removing chunks.
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

	var active_coordinates: Array[Vector3i] = get_loaded_coordinates()
	for coordinate in get_pending_coordinates():
		if not active_coordinates.has(coordinate):
			active_coordinates.append(coordinate)
	active_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in active_coordinates:
		if not desired.has(coordinate):
			unload_chunk(coordinate)

	var desired_coordinates: Array[Vector3i] = []
	desired_coordinates.assign(desired.keys())
	desired_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in desired_coordinates:
		if not is_chunk_loaded(coordinate) and not is_chunk_pending(coordinate):
			load_chunk(coordinate)


## Requests one precomputed chunk for asynchronous loading.
##
## Duplicate requests are idempotent. A successful return means the request was
## accepted or the chunk is already active; residency becomes observable through
## [method is_chunk_loaded] and [signal chunk_loaded] after threaded loading completes.
func load_chunk(coordinate: Vector3i) -> Error:
	if is_chunk_loaded(coordinate) or is_chunk_pending(coordinate):
		return OK
	if manifest == null:
		return _report_load_failure(coordinate, ERR_UNCONFIGURED)

	var entry := manifest.find_entry(coordinate, lod_level)
	if entry == null or not entry.is_valid():
		return _report_load_failure(coordinate, ERR_DOES_NOT_EXIST)
	if not ResourceLoader.exists(entry.asset_path):
		return _report_load_failure(coordinate, ERR_CANT_OPEN)

	_load_requests[coordinate] = ChunkLoadRequest.new(coordinate, entry.asset_path)
	chunk_load_queued.emit(coordinate)
	return OK


## Removes a resident chunk or cancels its pending residency request.
##
## Godot does not expose cancellation for an already-started threaded resource
## load. Removing the request is therefore a logical cancellation: any eventual
## cached resource result is ignored and no MeshInstance3D is created.
func unload_chunk(coordinate: Vector3i) -> bool:
	if _load_requests.erase(coordinate):
		return true

	var instance := get_chunk_instance(coordinate)
	if instance == null:
		return false

	_loaded_chunks.erase(coordinate)
	instance.queue_free()
	chunk_unloaded.emit(coordinate)
	return true


## Cancels pending requests and unloads every resident chunk.
func clear_chunks() -> void:
	_load_requests.clear()
	var coordinates := get_loaded_coordinates()
	for coordinate in coordinates:
		unload_chunk(coordinate)


# [b]Loading Execution[/b]
# Owns threaded ResourceLoader lifecycle independently of residency policy.

func _poll_loading_requests() -> void:
	var coordinates := get_pending_coordinates()
	for coordinate in coordinates:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request == null or request.state != ChunkLoadState.LOADING:
			continue

		var status := ResourceLoader.load_threaded_get_status(request.asset_path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				continue
			ResourceLoader.THREAD_LOAD_LOADED:
				_complete_load_request(request)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fail_load_request(request.coordinate, ERR_CANT_OPEN)


func _start_queued_loads() -> void:
	var coordinates := get_pending_coordinates()
	for coordinate in coordinates:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request == null or request.state != ChunkLoadState.QUEUED:
			continue

		var error := ResourceLoader.load_threaded_request(
			request.asset_path,
			"TerrainChunkAsset"
		)
		if error != OK:
			_fail_load_request(coordinate, error)
			continue

		request.state = ChunkLoadState.LOADING
		chunk_load_started.emit(coordinate)


func _complete_load_request(request: ChunkLoadRequest) -> void:
	var resource := ResourceLoader.load_threaded_get(request.asset_path)
	var asset := resource as TerrainChunkAsset
	if asset == null:
		_fail_load_request(request.coordinate, ERR_INVALID_DATA)
		return
	if not asset.is_valid():
		_fail_load_request(request.coordinate, ERR_INVALID_DATA)
		return
	if asset.chunk_coordinate != request.coordinate or asset.lod_level != lod_level:
		_fail_load_request(request.coordinate, ERR_INVALID_DATA)
		return

	_load_requests.erase(request.coordinate)
	var instance := MeshInstance3D.new()
	instance.name = "StreamedChunk_%d_%d_%d_L%d" % [
		request.coordinate.x,
		request.coordinate.y,
		request.coordinate.z,
		lod_level,
	]
	instance.mesh = asset.mesh
	instance.position = asset.local_origin
	add_child(instance)
	_loaded_chunks[request.coordinate] = instance
	chunk_loaded.emit(request.coordinate, instance)


func _fail_load_request(coordinate: Vector3i, error: Error) -> void:
	_load_requests.erase(coordinate)
	_report_load_failure(coordinate, error)


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


func _report_load_failure(coordinate: Vector3i, error: Error) -> Error:
	chunk_load_failed.emit(coordinate, error)
	return error
