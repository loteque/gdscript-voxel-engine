extends SceneTree

const VALIDATION_SCENE := preload("res://demo/ChunkStreamingValidationDemo.tscn")
const DEFAULT_MATRIX := preload("res://demo/experiments/mobile_web_warm_matrix.tres")
const TEST_TIMEOUT_MSEC := 10000

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_default_matrix_contract()
	await _test_matrix_runner_contract()
	quit(1 if _failed else 0)


func _test_default_matrix_contract() -> void:
	var matrix := DEFAULT_MATRIX as StreamingExperimentMatrix
	_assert_true(matrix != null, "Default Web experiment matrix must load as StreamingExperimentMatrix.")
	if matrix == null:
		return
	_assert_equal(matrix.get_validation_error(), "", "Default Web experiment matrix must be runnable.")
	_assert_equal(matrix.matrix_name, "mobile-web-warm-resource-loading", "Matrix identity must remain stable for exported evidence.")
	_assert_equal(matrix.cache_provenance, "repeated / warm", "Automated Web matrix must state warm-cache provenance explicitly.")
	_assert_equal(Array(matrix.concurrency_values), [1, 2, 4, 8], "Web matrix must exercise the controlled concurrency sweep.")
	_assert_equal(matrix.repetitions_per_concurrency, 3, "Web matrix must perform three repetitions per concurrency value.")
	_assert_equal(matrix.get_run_count(), 12, "Web matrix must represent twelve controlled runs.")
	_assert_equal(matrix.load_radius, 2, "Web matrix must preserve the established load radius.")
	_assert_equal(matrix.unload_radius, 3, "Web matrix must preserve the established unload radius.")
	_assert_equal(matrix.max_load_starts_per_frame, 2, "Web matrix must preserve the scheduler start budget.")
	_assert_equal(matrix.waypoint_coordinates.size(), 11, "Web matrix must use the same eleven waypoints as the headless experiment.")
	_assert_equal(matrix.waypoint_coordinates[0], Vector3i(-4, 0, -4), "Web matrix must begin at the established first waypoint.")
	_assert_equal(matrix.waypoint_coordinates[-1], Vector3i(4, 0, 4), "Web matrix must finish at the established final waypoint.")


func _test_matrix_runner_contract() -> void:
	var scene := VALIDATION_SCENE.instantiate() as Node3D
	scene.thread_smoke_enabled = false
	var matrix := StreamingExperimentMatrix.new()
	matrix.matrix_name = "headless-matrix-contract"
	matrix.cache_provenance = "repeated / warm"
	matrix.concurrency_values = PackedInt32Array([1])
	matrix.repetitions_per_concurrency = 1
	matrix.load_radius = 0
	matrix.unload_radius = 0
	matrix.max_load_starts_per_frame = 1
	matrix.waypoint_coordinates = [Vector3i(-4, 0, -4)]
	matrix.settle_frames = 1
	scene.experiment_matrix = matrix
	root.add_child(scene)
	await process_frame

	var streamer := scene.get_node("ChunkStreamer") as ChunkStreamer
	var started_wait_msec := Time.get_ticks_msec()
	while not streamer.get_pending_coordinates().is_empty():
		if Time.get_ticks_msec() - started_wait_msec > TEST_TIMEOUT_MSEC:
			_assert_true(false, "Streaming scene did not settle before starting matrix contract run.")
			scene.queue_free()
			await process_frame
			return
		await process_frame

	_assert_true(scene.call("start_experiment_matrix"), "Matrix runner must start once current residency is settled.")
	var run_started_msec := Time.get_ticks_msec()
	while bool(scene.call("is_experiment_matrix_running")):
		if Time.get_ticks_msec() - run_started_msec > TEST_TIMEOUT_MSEC:
			_assert_true(false, "Matrix runner did not complete the tiny production-path experiment.")
			break
		await process_frame

	var results := scene.call("get_experiment_matrix_results") as Array
	_assert_equal(results.size(), 1, "Matrix runner must accumulate one result for the tiny matrix.")
	if not results.is_empty():
		var result := results[0] as Dictionary
		_assert_equal(result["concurrency"], 1, "Recorded matrix result must retain concurrency provenance.")
		_assert_equal(result["repetition"], 1, "Recorded matrix result must retain repetition provenance.")
		_assert_equal(result["cache_provenance"], "repeated / warm", "Recorded matrix result must retain cache provenance.")
		_assert_equal((result["waypoints"] as Array).size(), 1, "Recorded matrix result must include settled waypoint evidence.")
		_assert_true((result["metrics"] as Dictionary)["completed_load_count"] >= 1, "Matrix run must exercise real production chunk loading.")

	var payload := scene.call("get_experiment_export_payload") as Dictionary
	_assert_equal(payload["schema_version"], 1, "Export payload must expose a stable schema version.")
	_assert_equal(payload["experiment"], "resource-loading-analysis-web-matrix", "Export payload must identify the Web matrix experiment.")
	_assert_equal(payload["completed_run_count"], 1, "Export payload must report accumulated run count.")
	_assert_equal(payload["expected_run_count"], 1, "Export payload must report matrix run count.")
	_assert_true(bool(payload["complete"]), "Completed tiny matrix must produce a complete export payload.")
	_assert_equal((payload["runs"] as Array).size(), 1, "Export payload must contain accumulated run evidence.")

	_assert_true(not bool(scene.call("start_experiment_matrix")), "Completed matrix session must reject a second run so evidence cannot be overwritten.")
	var preserved_results := scene.call("get_experiment_matrix_results") as Array
	_assert_equal(preserved_results.size(), 1, "Rejected rerun must preserve completed matrix evidence.")
	var run_button := scene.get_node("UI/Panel/Margin/Content/ExperimentMatrix/Buttons/RunMatrix") as Button
	_assert_true(run_button.disabled, "Completed matrix session must disable the run button.")

	scene.queue_free()
	await process_frame


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])
