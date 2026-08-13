class_name RuntimeWorkloadIsolationChunkStreamer
extends ChunkStreamer

## Validation-only streamer for workload isolation measurements.

enum WorkloadMode {
	NORMAL_RUNTIME,
	HIDDEN_GEOMETRY,
	NO_SCENE_INTEGRATION,
	MINIMAL_RESIDENCY,
}

var workload_mode: WorkloadMode = WorkloadMode.NORMAL_RUNTIME
var _diagnostic_resident: Dictionary[Vector3i, bool] = {}

func set_workload_mode(mode: WorkloadMode) -> void:
	clear_chunks()
	workload_mode = mode
	_diagnostic_resident.clear()

func get_workload_mode_name() -> String:
	match workload_mode:
		WorkloadMode.NORMAL_RUNTIME: return "normal_runtime"
		WorkloadMode.HIDDEN_GEOMETRY: return "hidden_geometry"
		WorkloadMode.NO_SCENE_INTEGRATION: return "no_scene_integration"
		WorkloadMode.MINIMAL_RESIDENCY: return "minimal_residency"
	return "unknown"

func is_chunk_loaded(coordinate: Vector3i) -> bool:
	if workload_mode <= WorkloadMode.HIDDEN_GEOMETRY:
		return super(coordinate)
	return _diagnostic_resident.has(coordinate)

func get_loaded_coordinates() -> Array[Vector3i]:
	if workload_mode <= WorkloadMode.HIDDEN_GEOMETRY:
		return super()
	var coordinates: Array[Vector3i] = []
	coordinates.assign(_diagnostic_resident.keys())
	coordinates.sort_custom(_coordinate_less_than)
	return coordinates

func get_chunk_instance(coordinate: Vector3i) -> MeshInstance3D:
	if workload_mode <= WorkloadMode.HIDDEN_GEOMETRY:
		return super(coordinate)
	return null

func _complete_load_request(request) -> void:
	super(request)
	if workload_mode == WorkloadMode.HIDDEN_GEOMETRY:
		var instance := get_chunk_instance(request.coordinate)
		if instance != null:
			instance.visible = false
