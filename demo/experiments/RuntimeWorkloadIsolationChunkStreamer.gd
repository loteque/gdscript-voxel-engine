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

func get_workload_mode_name() -> String:
	match workload_mode:
		WorkloadMode.NORMAL_RUNTIME: return "normal_runtime"
		WorkloadMode.HIDDEN_GEOMETRY: return "hidden_geometry"
		WorkloadMode.NO_SCENE_INTEGRATION: return "no_scene_integration"
		WorkloadMode.MINIMAL_RESIDENCY: return "minimal_residency"
	return "unknown"
