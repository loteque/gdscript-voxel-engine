extends SceneTree

## Validates the workload-isolation experiment contract without running measurements.

const SCENE_PATH := "res://demo/RuntimeWorkloadExperiment.tscn"
const RUNNER_PATH := "res://demo/experiments/RuntimeExperimentShell.gd"
const LOADER_CONTROL_PATH := "res://demo/experiments/RuntimeWorkloadLoaderControl.gd"
const EXPORTER_PATH := "res://demo/experiments/RuntimeWorkloadEvidenceExporter.gd"
const EXPECTED_TITLE := "Chunk Streamer Runtime Workload Isolation"
const EXPECTED_EXPERIMENT := "chunk-streamer-runtime-workload-comparison"

var _failed := false


func _init() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	_check(scene != null, "Runtime workload validation scene must load.")
	if scene != null:
		var instance := scene.instantiate()
		_check(instance != null, "Runtime workload validation scene must instantiate.")
		if instance != null:
			_check(instance.has_method("get_experiment_title"), "Experiment must expose its title.")
			_check(instance.has_method("get_expected_run_count"), "Experiment must expose its run count.")
			if instance.has_method("get_experiment_title"):
				_check(instance.get_experiment_title() == EXPECTED_TITLE, "Experiment title must match the approved UI title.")
			if instance.has_method("get_expected_run_count"):
				_check(instance.get_expected_run_count() == 12, "Experiment must contain four modes with three repetitions each.")
			instance.free()

	var runner_source := _read_text(RUNNER_PATH)
	_check(runner_source.contains(EXPECTED_EXPERIMENT), "Evidence identity must be stable.")
	for mode in ["normal_runtime", "hidden_geometry", "no_scene_integration", "loader_only_control"]:
		_check(runner_source.contains(mode), "Experiment runner must contain workload mode %s." % mode)
	for field in ["load_observations", "frame_timing", "p95_msec", "p99_msec", "revision"]:
		_check(runner_source.contains(field), "Evidence runner must expose %s." % field)
	_check(FileAccess.file_exists(LOADER_CONTROL_PATH), "Loader-only control must exist.")
	_check(FileAccess.file_exists(EXPORTER_PATH), "Evidence exporter must exist.")

	if _failed:
		quit(1)
	else:
		print("Runtime workload isolation contract tests passed.")
		quit(0)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
