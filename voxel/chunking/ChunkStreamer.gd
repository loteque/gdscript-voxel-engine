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
	var desired_usec: int = 0
	var queued_usec: int = 0
	var started_usec: int = 0
	var first_status_poll_usec: int = 0
	var completion_observed_usec: int = 0
	var desired_frame: int = 0
	var queued_frame: int = 0
	var started_frame: int = 0
	var first_status_poll_frame: int = 0
	var completion_observed_frame: int = 0
	var in_progress_poll_count: int = 0
	var queued_state: Dictionary = {}
	var started_state: Dictionary = {}
	var completion_observed_state: Dictionary = {}

	func _init(request_coordinate: Vector3i, request_asset_path: String, request_desired_usec: int, request_desired_frame: int) -> void:
		coordinate = request_coordinate
		asset_path = request_asset_path
		desired_usec = request_desired_usec
		desired_frame = request_desired_frame


const MAX_COMPLETED_LOAD_OBSERVATIONS := 512

signal chunk_load_queued(coordinate: Vector3i)
signal chunk_load_started(coordinate: Vector3i)
signal chunk_loaded(coordinate: Vector3i, instance: MeshInstance3D)
signal chunk_unloaded(coordinate: Vector3i)
signal chunk_load_failed(coordinate: Vector3i, error: Error)

@export var manifest: TerrainChunkManifest
@export var lod_level: int = 0
@export_range(0, 16, 1) var load_radius: int = 1:
	set(value):
		load_radius = clampi(value, 0, 16)
		if unload_radius < load_radius:
			unload_radius = load_radius
@export_range(0, 16, 1) var unload_radius: int = 2:
	set(value):
		unload_radius = maxi(clampi(value, 0, 16), load_radius)
var residency_radius: int:
	get: return load_radius
	set(value):
		var radius := clampi(value, 0, 16)
		load_radius = radius
		unload_radius = radius
@export_range(1, 64, 1) var max_load_starts_per_frame: int = 2
@export_range(1, 256, 1) var max_concurrent_loads: int = 8
@export var target: Node3D

var _loaded_chunks: Dictionary[Vector3i, MeshInstance3D] = {}
var _load_requests: Dictionary[Vector3i, ChunkLoadRequest] = {}
var _priority_origin: Vector3i = Vector3i.ZERO
var _has_priority_origin := false
var _process_frame_index := 0

var _peak_resident_count := 0
var _completed_load_count := 0
var _failed_load_count := 0
var _unload_count := 0
var _cancelled_pending_load_count := 0
var _total_load_latency_usec := 0
var _maximum_load_latency_usec := 0
var _total_background_wait_usec := 0
var _maximum_background_wait_usec := 0
var _total_residency_completion_usec := 0
var _maximum_residency_completion_usec := 0
var _total_queue_wait_usec := 0
var _maximum_queue_wait_usec := 0
var _total_resource_get_usec := 0
var _maximum_resource_get_usec := 0
var _total_asset_validation_usec := 0
var _maximum_asset_validation_usec := 0
var _total_instance_setup_usec := 0
var _maximum_instance_setup_usec := 0
var _total_scene_attach_usec := 0
var _maximum_scene_attach_usec := 0
var _total_resident_commit_usec := 0
var _maximum_resident_commit_usec := 0
var _in_progress_poll_count := 0
var _completed_load_observations: Array[Dictionary] = []


func _process(_delta: float) -> void:
	_process_frame_index += 1
	if target != null:
		update_residency(to_local(target.global_position))
	_poll_loading_requests()
	_start_queued_loads()


func is_chunk_loaded(coordinate: Vector3i) -> bool:
	return _loaded_chunks.has(coordinate)

func is_chunk_pending(coordinate: Vector3i) -> bool:
	return _load_requests.has(coordinate)

func get_chunk_load_state(coordinate: Vector3i) -> ChunkLoadState:
	if is_chunk_loaded(coordinate): return ChunkLoadState.RESIDENT
	var request := _load_requests.get(coordinate) as ChunkLoadRequest
	return request.state if request != null else ChunkLoadState.UNLOADED

func get_chunk_instance(coordinate: Vector3i) -> MeshInstance3D:
	return _loaded_chunks.get(coordinate) as MeshInstance3D

func get_loaded_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_loaded_chunks.keys())
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates

func get_pending_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_load_requests.keys())
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates

func get_queued_coordinates() -> Array[Vector3i]:
	return _get_prioritized_queued_coordinates()

func get_loading_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	for coordinate in _load_requests:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.LOADING:
			coordinates.append(coordinate)
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates

## Returns a read-only snapshot of cumulative and current streaming observations.
func get_streaming_metrics() -> Dictionary:
	var divisor := float(_completed_load_count) if _completed_load_count > 0 else 1.0
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
		"average_load_latency_msec": _usec_to_msec(_total_load_latency_usec) / divisor,
		"maximum_load_latency_msec": _usec_to_msec(_maximum_load_latency_usec),
		"average_background_wait_msec": _usec_to_msec(_total_background_wait_usec) / divisor,
		"maximum_background_wait_msec": _usec_to_msec(_maximum_background_wait_usec),
		"average_residency_completion_msec": _usec_to_msec(_total_residency_completion_usec) / divisor,
		"maximum_residency_completion_msec": _usec_to_msec(_maximum_residency_completion_usec),
		"average_queue_wait_msec": _usec_to_msec(_total_queue_wait_usec) / divisor,
		"maximum_queue_wait_msec": _usec_to_msec(_maximum_queue_wait_usec),
		"average_loader_wait_msec": _usec_to_msec(_total_background_wait_usec) / divisor,
		"maximum_loader_wait_msec": _usec_to_msec(_maximum_background_wait_usec),
		"average_resource_get_msec": _usec_to_msec(_total_resource_get_usec) / divisor,
		"maximum_resource_get_msec": _usec_to_msec(_maximum_resource_get_usec),
		"average_asset_validation_msec": _usec_to_msec(_total_asset_validation_usec) / divisor,
		"maximum_asset_validation_msec": _usec_to_msec(_maximum_asset_validation_usec),
		"average_instance_setup_msec": _usec_to_msec(_total_instance_setup_usec) / divisor,
		"maximum_instance_setup_msec": _usec_to_msec(_maximum_instance_setup_usec),
		"average_scene_attach_msec": _usec_to_msec(_total_scene_attach_usec) / divisor,
		"maximum_scene_attach_msec": _usec_to_msec(_maximum_scene_attach_usec),
		"average_resident_commit_msec": _usec_to_msec(_total_resident_commit_usec) / divisor,
		"maximum_resident_commit_msec": _usec_to_msec(_maximum_resident_commit_usec),
		"in_progress_poll_count": _in_progress_poll_count,
		"completed_observation_count": _completed_load_observations.size(),
		"approximate_mesh_memory_bytes": _get_approximate_mesh_memory_bytes(),
	}

func get_completed_load_observations() -> Array[Dictionary]:
	var observations: Array[Dictionary] = []
	for observation in _completed_load_observations:
		observations.append(observation.duplicate(true))
	return observations

func reset_streaming_metrics() -> void:
	_peak_resident_count = _loaded_chunks.size()
	_completed_load_count = 0
	_failed_load_count = 0
	_unload_count = 0
	_cancelled_pending_load_count = 0
	_total_load_latency_usec = 0
	_maximum_load_latency_usec = 0
	_total_background_wait_usec = 0
	_maximum_background_wait_usec = 0
	_total_residency_completion_usec = 0
	_maximum_residency_completion_usec = 0
	_total_queue_wait_usec = 0
	_maximum_queue_wait_usec = 0
	_total_resource_get_usec = 0
	_maximum_resource_get_usec = 0
	_total_asset_validation_usec = 0
	_maximum_asset_validation_usec = 0
	_total_instance_setup_usec = 0
	_maximum_instance_setup_usec = 0
	_total_scene_attach_usec = 0
	_maximum_scene_attach_usec = 0
	_total_resident_commit_usec = 0
	_maximum_resident_commit_usec = 0
	_in_progress_poll_count = 0
	_completed_load_observations.clear()

func position_to_chunk_coordinate(local_position: Vector3) -> Vector3i:
	if not _has_valid_manifest_geometry(): return Vector3i.ZERO
	var extent := _get_chunk_extent()
	return Vector3i(floori(local_position.x / extent.x), floori(local_position.y / extent.y), floori(local_position.z / extent.z))

func update_residency(target_position: Vector3) -> void:
	if not _has_valid_manifest_geometry(): return
	var target_coordinate := position_to_chunk_coordinate(target_position)
	_priority_origin = target_coordinate
	_has_priority_origin = true
	var admission := _get_available_coordinates_in_radius(target_coordinate, load_radius)
	var retention := _get_available_coordinates_in_radius(target_coordinate, unload_radius)
	var active_coordinates: Array[Vector3i] = get_loaded_coordinates()
	for coordinate in get_pending_coordinates():
		if not active_coordinates.has(coordinate): active_coordinates.append(coordinate)
	active_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in active_coordinates:
		if not retention.has(coordinate): unload_chunk(coordinate)
	var admission_coordinates: Array[Vector3i] = []
	admission_coordinates.assign(admission.keys())
	admission_coordinates.sort_custom(_coordinate_less_than)
	for coordinate in admission_coordinates:
		if not is_chunk_loaded(coordinate) and not is_chunk_pending(coordinate): load_chunk(coordinate)

func load_chunk(coordinate: Vector3i) -> Error:
	if is_chunk_loaded(coordinate) or is_chunk_pending(coordinate): return OK
	var desired_usec := Time.get_ticks_usec()
	var desired_frame := _process_frame_index
	if manifest == null: return _report_load_failure(coordinate, ERR_UNCONFIGURED)
	var entry := manifest.find_entry(coordinate, lod_level)
	if entry == null or not entry.is_valid(): return _report_load_failure(coordinate, ERR_DOES_NOT_EXIST)
	if not ResourceLoader.exists(entry.asset_path): return _report_load_failure(coordinate, ERR_CANT_OPEN)
	var request := ChunkLoadRequest.new(coordinate, entry.asset_path, desired_usec, desired_frame)
	request.queued_usec = Time.get_ticks_usec()
	request.queued_frame = _process_frame_index
	_load_requests[coordinate] = request
	request.queued_state = _capture_state_counts()
	chunk_load_queued.emit(coordinate)
	return OK

func unload_chunk(coordinate: Vector3i) -> bool:
	if _load_requests.erase(coordinate):
		_cancelled_pending_load_count += 1
		return true
	var instance := get_chunk_instance(coordinate)
	if instance == null: return false
	_loaded_chunks.erase(coordinate)
	_unload_count += 1
	instance.queue_free()
	chunk_unloaded.emit(coordinate)
	return true

func clear_chunks() -> void:
	for coordinate in get_pending_coordinates(): unload_chunk(coordinate)
	for coordinate in get_loaded_coordinates(): unload_chunk(coordinate)

func _poll_loading_requests() -> void:
	for coordinate in get_loading_coordinates():
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request == null: continue
		if request.first_status_poll_usec <= 0:
			request.first_status_poll_usec = Time.get_ticks_usec()
			request.first_status_poll_frame = _process_frame_index
		var status := ResourceLoader.load_threaded_get_status(request.asset_path)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				request.in_progress_poll_count += 1
				_in_progress_poll_count += 1
			ResourceLoader.THREAD_LOAD_LOADED:
				request.completion_observed_usec = Time.get_ticks_usec()
				request.completion_observed_frame = _process_frame_index
				request.completion_observed_state = _capture_state_counts()
				_complete_load_request(request)
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fail_load_request(request.coordinate, ERR_CANT_OPEN)

func _start_queued_loads() -> void:
	var available_capacity := maxi(max_concurrent_loads - _get_loading_count(), 0)
	var start_budget := mini(max_load_starts_per_frame, available_capacity)
	if start_budget <= 0: return
	var started := 0
	for coordinate in _get_prioritized_queued_coordinates():
		if started >= start_budget: break
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request == null or request.state != ChunkLoadState.QUEUED: continue
		var error := ResourceLoader.load_threaded_request(request.asset_path)
		if error != OK:
			_fail_load_request(coordinate, error)
			continue
		request.state = ChunkLoadState.LOADING
		request.started_usec = Time.get_ticks_usec()
		request.started_frame = _process_frame_index
		request.started_state = _capture_state_counts()
		started += 1
		chunk_load_started.emit(coordinate)

func _get_loading_count() -> int:
	var count := 0
	for request_value in _load_requests.values():
		var request := request_value as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.LOADING: count += 1
	return count

func _get_queued_count() -> int:
	var count := 0
	for request_value in _load_requests.values():
		var request := request_value as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.QUEUED: count += 1
	return count

func _capture_state_counts() -> Dictionary:
	return {
		"queued_count": _get_queued_count(),
		"loading_count": _get_loading_count(),
		"resident_count": _loaded_chunks.size(),
	}

func _get_prioritized_queued_coordinates() -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	for coordinate in _load_requests:
		var request := _load_requests.get(coordinate) as ChunkLoadRequest
		if request != null and request.state == ChunkLoadState.QUEUED: coordinates.append(coordinate)
	coordinates.sort_custom(_queued_coordinate_less_than)
	return coordinates

func _queued_coordinate_less_than(a: Vector3i, b: Vector3i) -> bool:
	if _has_priority_origin:
		var distance_a := _chunk_distance_squared(a, _priority_origin)
		var distance_b := _chunk_distance_squared(b, _priority_origin)
		if distance_a != distance_b: return distance_a < distance_b
	return _coordinate_less_than(a, b)

func _chunk_distance_squared(a: Vector3i, b: Vector3i) -> int:
	var delta := a - b
	return delta.x * delta.x + delta.y * delta.y + delta.z * delta.z

func _complete_load_request(request: ChunkLoadRequest) -> void:
	var completion_observed_usec := request.completion_observed_usec
	if completion_observed_usec <= 0: completion_observed_usec = Time.get_ticks_usec()
	var resource_get_started_usec := Time.get_ticks_usec()
	var resource := ResourceLoader.load_threaded_get(request.asset_path)
	var resource_get_finished_usec := Time.get_ticks_usec()
	var validation_started_usec := resource_get_finished_usec
	var asset := resource as TerrainChunkAsset
	if asset == null or not asset.is_valid() or asset.chunk_coordinate != request.coordinate or asset.lod_level != lod_level:
		_fail_load_request(request.coordinate, ERR_INVALID_DATA)
		return
	var validation_finished_usec := Time.get_ticks_usec()
	_load_requests.erase(request.coordinate)
	var instance_setup_started_usec := validation_finished_usec
	var instance := MeshInstance3D.new()
	instance.name = "StreamedChunk_%d_%d_%d_L%d" % [request.coordinate.x, request.coordinate.y, request.coordinate.z, lod_level]
	instance.mesh = asset.mesh
	instance.position = asset.local_origin
	var instance_setup_finished_usec := Time.get_ticks_usec()
	var scene_attach_started_usec := instance_setup_finished_usec
	add_child(instance)
	var scene_attach_finished_usec := Time.get_ticks_usec()
	var resident_commit_started_usec := scene_attach_finished_usec
	_loaded_chunks[request.coordinate] = instance
	_completed_load_count += 1
	_peak_resident_count = maxi(_peak_resident_count, _loaded_chunks.size())
	var resident_commit_finished_usec := Time.get_ticks_usec()
	var resident_state := _capture_state_counts()
	_record_completed_load_observation(request, completion_observed_usec, resource_get_started_usec, resource_get_finished_usec, validation_started_usec, validation_finished_usec, instance_setup_started_usec, instance_setup_finished_usec, scene_attach_started_usec, scene_attach_finished_usec, resident_commit_started_usec, resident_commit_finished_usec, resident_state)
	chunk_loaded.emit(request.coordinate, instance)

func _record_completed_load_observation(request: ChunkLoadRequest, completion_observed_usec: int, resource_get_started_usec: int, resource_get_finished_usec: int, validation_started_usec: int, validation_finished_usec: int, instance_setup_started_usec: int, instance_setup_finished_usec: int, scene_attach_started_usec: int, scene_attach_finished_usec: int, resident_commit_started_usec: int, resident_commit_finished_usec: int, resident_state: Dictionary) -> void:
	var desired_to_queued_usec := maxi(request.queued_usec - request.desired_usec, 0)
	var queue_wait_usec := maxi(request.started_usec - request.queued_usec, 0)
	var request_to_first_poll_usec := maxi(request.first_status_poll_usec - request.started_usec, 0)
	var first_poll_to_completion_usec := maxi(completion_observed_usec - request.first_status_poll_usec, 0)
	var loader_wait_usec := maxi(completion_observed_usec - request.started_usec, 0)
	var resource_get_usec := maxi(resource_get_finished_usec - resource_get_started_usec, 0)
	var asset_validation_usec := maxi(validation_finished_usec - validation_started_usec, 0)
	var instance_setup_usec := maxi(instance_setup_finished_usec - instance_setup_started_usec, 0)
	var scene_attach_usec := maxi(scene_attach_finished_usec - scene_attach_started_usec, 0)
	var resident_commit_usec := maxi(resident_commit_finished_usec - resident_commit_started_usec, 0)
	var residency_completion_usec := maxi(resident_commit_finished_usec - completion_observed_usec, 0)
	var aggregate_latency_usec := maxi(resident_commit_finished_usec - request.started_usec, 0)
	var total_request_usec := maxi(resident_commit_finished_usec - request.queued_usec, 0)
	var total_desired_to_resident_usec := maxi(resident_commit_finished_usec - request.desired_usec, 0)
	_total_queue_wait_usec += queue_wait_usec
	_maximum_queue_wait_usec = maxi(_maximum_queue_wait_usec, queue_wait_usec)
	_total_load_latency_usec += aggregate_latency_usec
	_maximum_load_latency_usec = maxi(_maximum_load_latency_usec, aggregate_latency_usec)
	_total_background_wait_usec += loader_wait_usec
	_maximum_background_wait_usec = maxi(_maximum_background_wait_usec, loader_wait_usec)
	_total_residency_completion_usec += residency_completion_usec
	_maximum_residency_completion_usec = maxi(_maximum_residency_completion_usec, residency_completion_usec)
	_total_resource_get_usec += resource_get_usec
	_maximum_resource_get_usec = maxi(_maximum_resource_get_usec, resource_get_usec)
	_total_asset_validation_usec += asset_validation_usec
	_maximum_asset_validation_usec = maxi(_maximum_asset_validation_usec, asset_validation_usec)
	_total_instance_setup_usec += instance_setup_usec
	_maximum_instance_setup_usec = maxi(_maximum_instance_setup_usec, instance_setup_usec)
	_total_scene_attach_usec += scene_attach_usec
	_maximum_scene_attach_usec = maxi(_maximum_scene_attach_usec, scene_attach_usec)
	_total_resident_commit_usec += resident_commit_usec
	_maximum_resident_commit_usec = maxi(_maximum_resident_commit_usec, resident_commit_usec)
	var entry := manifest.find_entry(request.coordinate, lod_level) if manifest != null else null
	var observation := {
		"coordinate": request.coordinate,
		"desired_usec": request.desired_usec,
		"queued_usec": request.queued_usec,
		"started_usec": request.started_usec,
		"first_status_poll_usec": request.first_status_poll_usec,
		"completion_observed_usec": request.completion_observed_usec,
		"resource_get_started_usec": resource_get_started_usec,
		"resident_commit_usec": resident_commit_finished_usec,
		"desired_frame": request.desired_frame,
		"queued_frame": request.queued_frame,
		"started_frame": request.started_frame,
		"first_status_poll_frame": request.first_status_poll_frame,
		"completion_observed_frame": request.completion_observed_frame,
		"resident_frame": _process_frame_index,
		"desired_to_queued_msec": _usec_to_msec(desired_to_queued_usec),
		"queue_wait_msec": _usec_to_msec(queue_wait_usec),
		"request_to_first_poll_msec": _usec_to_msec(request_to_first_poll_usec),
		"first_poll_to_completion_msec": _usec_to_msec(first_poll_to_completion_usec),
		"loader_wait_msec": _usec_to_msec(loader_wait_usec),
		"resource_get_msec": _usec_to_msec(resource_get_usec),
		"asset_validation_msec": _usec_to_msec(asset_validation_usec),
		"instance_setup_msec": _usec_to_msec(instance_setup_usec),
		"scene_attach_msec": _usec_to_msec(scene_attach_usec),
		"resident_commit_msec": _usec_to_msec(resident_commit_usec),
		"residency_completion_msec": _usec_to_msec(residency_completion_usec),
		"aggregate_latency_msec": _usec_to_msec(aggregate_latency_usec),
		"total_request_msec": _usec_to_msec(total_request_usec),
		"total_desired_to_resident_msec": _usec_to_msec(total_desired_to_resident_usec),
		"in_progress_poll_count": request.in_progress_poll_count,
		"queued_state": request.queued_state.duplicate(true),
		"started_state": request.started_state.duplicate(true),
		"completion_observed_state": request.completion_observed_state.duplicate(true),
		"resident_state": resident_state.duplicate(true),
		"serialized_size_bytes": 0,
		"mesh_vertex_count": 0,
		"mesh_index_count": 0,
	}
	if entry != null:
		observation["serialized_size_bytes"] = entry.serialized_size_bytes
		observation["mesh_vertex_count"] = entry.mesh_vertex_count
		observation["mesh_index_count"] = entry.mesh_index_count
	_completed_load_observations.append(observation)
	if _completed_load_observations.size() > MAX_COMPLETED_LOAD_OBSERVATIONS: _completed_load_observations.pop_front()

func _fail_load_request(coordinate: Vector3i, error: Error) -> void:
	_load_requests.erase(coordinate)
	_report_load_failure(coordinate, error)

func _get_approximate_mesh_memory_bytes() -> int:
	var bytes := 0
	for instance in _loaded_chunks.values():
		var mesh_instance := instance as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null: continue
		var mesh := mesh_instance.mesh
		for surface_index in mesh.get_surface_count():
			bytes += mesh.surface_get_array_len(surface_index) * 24
			bytes += mesh.surface_get_array_index_len(surface_index) * 4
	return bytes

func _has_valid_manifest_geometry() -> bool:
	return manifest != null and manifest.chunk_cell_dimensions.x > 0 and manifest.chunk_cell_dimensions.y > 0 and manifest.chunk_cell_dimensions.z > 0 and manifest.sample_spacing > 0.0

func _get_chunk_extent() -> Vector3:
	return Vector3(manifest.chunk_cell_dimensions) * manifest.sample_spacing

func _get_available_coordinates_in_radius(center: Vector3i, radius: int) -> Dictionary[Vector3i, bool]:
	var coordinates: Dictionary[Vector3i, bool] = {}
	for z_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			for x_offset in range(-radius, radius + 1):
				var coordinate := center + Vector3i(x_offset, y_offset, z_offset)
				if manifest.has_entry(coordinate, lod_level): coordinates[coordinate] = true
	return coordinates

func _coordinate_less_than(a: Vector3i, b: Vector3i) -> bool:
	if a.x != b.x: return a.x < b.x
	if a.y != b.y: return a.y < b.y
	return a.z < b.z

func _report_load_failure(coordinate: Vector3i, error: Error) -> Error:
	_failed_load_count += 1
	chunk_load_failed.emit(coordinate, error)
	return error

func _usec_to_msec(value: int) -> float:
	return float(value) / 1000.0
