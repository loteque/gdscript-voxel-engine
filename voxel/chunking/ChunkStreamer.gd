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
	var started_msec: int = 0

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
# Selects the precomputed asset catalog, residency policy, and loading budgets.

## Manifest used to resolve chunk coordinates to serialized assets.
@export var manifest: TerrainChunkManifest

## LOD requested by coordinate-only load calls.
@export var lod_level: int = 0

## Radius, in chunk coordinates, inside which available chunks are admitted.
## A radius of one considers a 3 x 3 x 3 coordinate neighborhood.
@export_range(0, 16, 1) var load_radius: int = 1:
	set(value):
		load_radius = clampi(value, 0, 16)
		if unload_radius < load_radius:
			unload_radius = load_radius

## Radius, in chunk coordinates, inside which resident or pending chunks are retained.
## Values below [member load_radius] are normalized up to the load radius.
@export_range(0, 16, 1) var unload_radius: int = 2:
	set(value):
		unload_radius = maxi(clampi(value, 0, 16), load_radius)

## Compatibility alias for the former single-radius residency policy.
## Setting this property assigns both [member load_radius] and [member unload_radius]
## to the same value, reproducing the previous admission/eviction behavior.
var residency_radius: int:
	get:
		return load_radius
	set(value):
		var radius := clampi(value, 0, 16)
		load_radius = radius
		unload_radius = radius

## Maximum number of queued requests that may begin loading in one process update.
@export_range(1, 64, 1) var max_load_starts_per_frame: int = 2

## Maximum number of requests that may simultaneously occupy LOADING state.
@export_range(1, 256, 1) var max_concurrent_loads: int = 8

## Optional runtime target whose position drives automatic residency updates.
@export var target: Node3D


# [b]Runtime Storage[/b]
# Separates pending loading work from currently resident scene instances.

var _loaded_chunks: Dictionary[Vector3i, MeshInstance3D] = {}
var _load_requests: Dictionary[Vector3i, ChunkLoadRequest] = {}
var _priority_origin: Vector3i = Vector3i.ZERO
var _has_priority_origin: bool = false

var _peak_resident_count: int = 0
var _completed_load_count: int = 0
var _failed_load_count: int = 0
var _unload_count: int = 0
var _cancelled_pending_load_count: int = 0
var _total_load_latency_msec: int = 0
var _maximum_load_latency_msec: int = 0


# [b]Runtime Update[/b]
# Runs residency policy and loading execution as separate stages each frame.

func _process(_delta: float) -> void:
	if target != null:
		update_residency(to_local(target.global_position))

	_poll_loading_requests()
	_start_queued_loads()


# [b]Queries[/b]
# Exposes residency, scheduler state, deterministic chunk-space conversion, and metrics.

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


## Returns queued coordinates in the order the scheduler would currently prefer them.
func get_queued_coordinates() -> Array[Vector3i]:
	return _get_prioritized_queued_coordinates()


## Returns all active LOADING coordinates in deterministic x/y/z order.
func get_loading_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	for coordinate in _load_requests:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.LOADING:
			coordinates.append(coordinate)
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates


## Returns a read-only snapshot of cumulative and current streaming observations.
##
## Latency values measure threaded load execution from request start until the
## serialized chunk asset is accepted as resident. Approximate mesh memory is a
## lightweight estimate derived from resident ArrayMesh vertex/index counts; it
## is intended for comparative validation rather than allocator-precise profiling.
func get_streaming_metrics() -> Dictionary:
	var average_latency_msec := 0.0
	if _completed_load_count > 0:
		average_latency_msec = float(_total_load_latency_msec) / float(_completed_load_count)
	return {
		"resident_count": _loaded_chunks.size(),
		"queued_count": get_queued_coordinates().size(),
		"loading_count": get_loading_coordinates().size(),
		"peak_resident_count": _peak_resident_count,
		"completed_load_count": _completed_load_count,
		"failed_load_count": _failed_load_count,
		"unload_count": _unload_count,
		"cancelled_pending_load_count": _cancelled_pending_load_count,
		"residency_churn_count": _unload_count + _cancelled_pending_load_count,
		"average_load_latency_msec": average_latency_msec,
		"maximum_load_latency_msec": _maximum_load_latency_msec,
		"approximate_mesh_memory_bytes": _get_approximate_mesh_memory_bytes(),
	}


## Resets cumulative streaming metrics without changing residency or pending work.
func reset_streaming_metrics() -> void:
	_peak_resident_count = _loaded_chunks.size()
	_completed_load_count = 0
	_failed_load_count = 0
	_unload_count = 0
	_cancelled_pending_load_count = 0
	_total_load_latency_msec = 0
	_maximum_load_latency_msec = 0


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
# Separates admission from retention while reusing the explicit chunk APIs.

## Updates available baked-chunk residency around [param target_position].
##
## [param target_position] is expressed in this streamer's local terrain space.
## Available chunks inside [member load_radius] are admitted. Existing resident or
## pending chunks remain retained until they leave [member unload_radius]. Missing
## manifest coordinates are skipped cleanly. Loading priority and budgets are not
## changed by the hysteresis policy.
func update_residency(target_position: Vector3) -> void:
	if not _has_valid_manifest_geometry():
		return

	var target_coordinate := position_to_chunk_coordinate(target_position)
	_priority_origin = target_coordinate
	_has_priority_origin = true

	var admission := _get_available_coordinates_in_radius(target_coordinate, load_radius)
	var retention := _get_available_coordinates_in_radius(target_coordinate, unload_radius)

	var active_coordinates: Array[Vector3i] = get_loaded_coordinates()
	for coordinate in get_pending_coordinates():
		if not active_coordinates.has(coordinate):
			active_coordinates.append(coordinate)
	active_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in active_coordinates:
		if not retention.has(coordinate):
			unload_chunk(coordinate)

	var admission_coordinates: Array[Vector3i] = []
	admission_coordinates.assign(admission.keys())
	admission_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in admission_coordinates:
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
		_cancelled_pending_load_count += 1
		return true

	var instance := get_chunk_instance(coordinate)
	if instance == null:
		return false

	_loaded_chunks.erase(coordinate)
	_unload_count += 1
	instance.queue_free()
	chunk_unloaded.emit(coordinate)
	return true


## Cancels pending requests and unloads every resident chunk.
func clear_chunks() -> void:
	var pending_coordinates := get_pending_coordinates()
	for coordinate in pending_coordinates:
		unload_chunk(coordinate)
	var coordinates := get_loaded_coordinates()
	for coordinate in coordinates:
		unload_chunk(coordinate)


# [b]Loading Execution[/b]
# Owns threaded loading lifecycle and bounded scheduler execution.

func _poll_loading_requests() -> void:
	var coordinates := get_loading_coordinates()
	for coordinate in coordinates:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request == null:
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
	var available_capacity := maxi(max_concurrent_loads - _get_loading_count(), 0)
	var start_budget := mini(max_load_starts_per_frame, available_capacity)
	if start_budget <= 0:
		return

	var started := 0
	for coordinate in _get_prioritized_queued_coordinates():
		if started >= start_budget:
			break

		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request == null or request.state != ChunkLoadState.QUEUED:
			continue

		var error := ResourceLoader.load_threaded_request(request.asset_path)
		if error != OK:
			_fail_load_request(coordinate, error)
			continue

		request.state = ChunkLoadState.LOADING
		request.started_msec = Time.get_ticks_msec()
		started += 1
		chunk_load_started.emit(coordinate)


func _get_loading_count() -> int:
	var count := 0
	for request_value in _load_requests.values():
		var request := request_value as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.LOADING:
			count += 1
	return count


func _get_prioritized_queued_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	for coordinate in _load_requests:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.QUEUED:
			coordinates.append(coordinate)
	coordinates.sort_custom(_queued_coordinate_less_than)
	return coordinates


func _queued_coordinate_less_than(a: Vector3i, b: Vector3i) -> bool:
	if _has_priority_origin:
		var distance_a := _chunk_distance_squared(a, _priority_origin)
		var distance_b := _chunk_distance_squared(b, _priority_origin)
		if distance_a != distance_b:
			return distance_a < distance_b
	return _coordinate_less_than(a, b)


func _chunk_distance_squared(a: Vector3i, b: Vector3i) -> int:
	var delta := a - b
	return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z


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

	_completed_load_count += 1
	_peak_resident_count = maxi(_peak_resident_count, _loaded_chunks.size())
	if request.started_msec > 0:
		var latency_msec := maxi(Time.get_ticks_msec() - request.started_msec, 0)
		_total_load_latency_msec += latency_msec
		_maximum_load_latency_msec = maxi(_maximum_load_latency_msec, latency_msec)
	chunk_loaded.emit(request.coordinate, instance)


func _fail_load_request(coordinate: Vector3i, error: Error) -> void:
	_load_requests.erase(coordinate)
	_report_load_failure(coordinate, error)


# [b]Metrics[/b]
# Provides lightweight comparative observability without exposing mutable storage.

func _get_approximate_mesh_memory_bytes() -> int:
	var bytes := 0
	for instance in _loaded_chunks.values():
		var mesh_instance := instance as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var mesh := mesh_instance.mesh
		for surface_index in mesh.get_surface_count():
			# Position + normal are guaranteed by the current Surface Nets path. The
			# estimate intentionally stays simple and stable for comparative QA.
			bytes += mesh.surface_get_array_len(surface_index) * 24
			bytes += mesh.surface_get_array_index_len(surface_index) * 4
	return bytes


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


func _get_available_coordinates_in_radius(
	center: Vector3i,
	radius: int
) -> Dictionary[Vector3i, bool]:
	var coordinates: Dictionary[Vector3i, bool] = {}
	for z_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			for x_offset in range(-radius, radius + 1):
				var coordinate := center + Vector3i(x_offset, y_offset, z_offset)
				if manifest.has_entry(coordinate, lod_level):
					coordinates[coordinate] = true
	return coordinates


func _coordinate_less_than(a: Vector3i, b: Vector3i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	if a.y != b.y:
		return a.y < b.y
	return a.z < b.z


func _report_load_failure(coordinate: Vector3i, error: Error) -> Error:
	_failed_load_count += 1
	chunk_load_failed.emit(coordinate, error)
	return error
