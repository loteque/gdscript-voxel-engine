extends SceneTree

const VALIDATION_SCENE := preload("res://demo/ChunkStreamingValidationDemo.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := VALIDATION_SCENE.instantiate() as Node3D
	root.add_child(scene)

	var streamer := scene.get_node("ChunkStreamer") as ChunkStreamer
	var target := scene.get_node("ResidencyTarget") as Node3D
	var status_label := scene.get_node("UI/Panel/Margin/Content/Status") as Label
	var pause_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Load") as Button

	_assert_true(streamer != null, "Streaming validation scene must contain ChunkStreamer.")
	_assert_true(target != null, "Streaming validation scene must contain an explicit Node3D target.")
	_assert_true(status_label != null, "Streaming validation UI must expose runtime scaling state.")
	if streamer == null or target == null:
		await _finish(scene)
		return

	_assert_true(streamer.manifest != null, "Streaming validation scene must load the baked production manifest.")
	_assert_equal(streamer.manifest.entries.size(), 169, "Streaming validation scene must use the large 13 x 1 x 13 dataset.")
	_assert_equal(streamer.target, target, "ChunkStreamer must use the scene target through its public target property.")
	_assert_equal(streamer.load_radius, 2, "Large validation must exercise load radius two.")
	_assert_equal(streamer.unload_radius, 3, "Large validation must exercise unload radius three.")
	_assert_equal(streamer.max_load_starts_per_frame, 2, "Large validation must expose the two-start scheduling budget.")
	_assert_equal(streamer.max_concurrent_loads, 4, "Large validation must expose four concurrent loads.")
	_assert_equal(streamer.position_to_chunk_coordinate(target.position), Vector3i(-4, 0, -4), "Initial large validation target must begin in chunk (-4, 0, -4).")

	if pause_button != null:
		pause_button.pressed.emit()

	_assert_equal(streamer.get_queued_coordinates().size(), 25, "Initial large validation admission must create a 25-chunk queue.")
	_assert_equal(streamer.get_queued_coordinates()[0], Vector3i(-4, 0, -4), "Nearest-first scheduling must prioritize the target chunk.")
	streamer._process(0.0)
	_assert_true(streamer.get_loading_coordinates().size() <= 2, "First large-scene update must respect the start budget.")
	_assert_true(streamer.get_loading_coordinates().size() <= 4, "First large-scene update must respect concurrent capacity.")
	_assert_true(streamer.get_queued_coordinates().size() >= 23, "Large-scene queue must remain visibly backlogged after one update.")

	_assert_true(await _wait_for_thread_smoke(scene), "Validation thread smoke task must reach a terminal state.")
	_assert_equal(scene.call("get_thread_smoke_state"), "PASS", "Headless validation must prove WorkerThreadPool execution.")
	_assert_true(await _wait_for_idle(streamer), "Initial large residency must settle under bounded asynchronous scheduling.")
	_assert_equal(streamer.get_loaded_coordinates().size(), 25, "Initial large residency must settle 25 chunks.")

	for coordinate in streamer.get_loaded_coordinates():
		var instance := streamer.get_chunk_instance(coordinate)
		_assert_true(instance != null and instance.mesh != null, "Every resident scale-test coordinate must own a mesh instance.")
		if instance != null and instance.mesh != null:
			_assert_true(instance.mesh.get_surface_count() > 0, "Every resident scale-test mesh must contain renderable surfaces.")

	target.position.x = -29.0
	streamer.update_residency(target.position)
	_assert_equal(streamer.position_to_chunk_coordinate(target.position), Vector3i(-3, 0, -4), "Moved large-scene target must enter the adjacent chunk.")
	_assert_true(await _wait_for_idle(streamer), "Moved large residency must settle under hysteresis and scheduler budgets.")
	_assert_equal(streamer.get_loaded_coordinates().size(), 30, "One-chunk movement must retain the trailing five-chunk hysteresis column.")

	var metrics := streamer.get_streaming_metrics()
	_assert_equal(metrics["resident_count"], 30, "Metrics must report the real resident count.")
	_assert_equal(metrics["peak_resident_count"], 30, "Metrics must report peak hysteretic residency.")
	_assert_equal(metrics["completed_load_count"], 30, "Metrics must count all successful loads in the deterministic scene path.")
	_assert_true(int(metrics["approximate_mesh_memory_bytes"]) > 0, "Metrics must expose positive approximate resident mesh memory.")

	if status_label != null:
		scene.call("_update_status")
		_assert_true(status_label.text.contains("Dataset: 169 single-LOD chunks"), "Validation UI must identify the large dataset.")
		_assert_true(status_label.text.contains("Thread smoke: PASS"), "Validation UI must preserve successful thread smoke diagnostics.")
		_assert_true(status_label.text.contains("Load radius: 2"), "Validation UI must display the admission radius.")
		_assert_true(status_label.text.contains("Unload radius: 3"), "Validation UI must display the retention radius.")
		_assert_true(status_label.text.contains("Load budget: 2 starts/frame, 4 concurrent"), "Validation UI must display scheduler budgets.")
		_assert_true(status_label.text.contains("Peak resident chunks: 30"), "Validation UI must expose peak residency.")
		_assert_true(status_label.text.contains("Completed loads: 30"), "Validation UI must expose completed load count.")
		_assert_true(status_label.text.contains("Average load latency:"), "Validation UI must expose load latency observation.")
		_assert_true(status_label.text.contains("Approx. resident mesh memory:"), "Validation UI must expose approximate mesh memory.")
		_assert_true(status_label.text.contains("Recent max frame time:"), "Validation UI must expose recent frame-time observation.")

	await _finish(scene)


func _wait_for_thread_smoke(scene: Node, max_frames: int = 240) -> bool:
	for _frame in range(max_frames):
		scene.call("_process", 0.0)
		if bool(scene.call("is_thread_smoke_complete")):
			return true
		await process_frame
	return bool(scene.call("is_thread_smoke_complete"))


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 600) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		if streamer.get_pending_coordinates().is_empty():
			return true
		await process_frame
	return streamer.get_pending_coordinates().is_empty()


func _finish(scene: Node) -> void:
	scene.queue_free()
	await process_frame
	quit(1 if _failed else 0)


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
