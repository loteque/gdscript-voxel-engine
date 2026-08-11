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
	var reset_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Unload") as Button

	_assert_true(streamer != null, "Streaming validation scene must contain ChunkStreamer.")
	_assert_true(target != null, "Streaming validation scene must contain an explicit Node3D target.")
	_assert_true(status_label != null, "Streaming validation UI must expose runtime status separately from ChunkStreamer.")
	_assert_true(pause_button != null and reset_button != null, "Streaming validation scene must expose its target controls.")

	if streamer == null or target == null:
		await _finish(scene)
		return

	_assert_true(streamer.manifest != null, "Streaming validation scene must load its baked TerrainChunkManifest.")
	_assert_equal(streamer.target, target, "ChunkStreamer must use the scene target through its public target property.")
	_assert_equal(streamer.load_radius, 1, "Validation scene must exercise load radius 1.")
	_assert_equal(streamer.unload_radius, 2, "Validation scene must exercise unload radius 2.")
	_assert_equal(streamer.max_load_starts_per_frame, 1, "Validation scene must make the per-frame start budget visible.")
	_assert_equal(streamer.max_concurrent_loads, 2, "Validation scene must make concurrent loading capacity visible.")
	_assert_equal(streamer.position_to_chunk_coordinate(target.position), Vector3i(-1, 0, 0), "Initial target position must resolve to chunk (-1, 0, 0).")

	if pause_button != null:
		pause_button.pressed.emit()

	_assert_equal(streamer.get_queued_coordinates().size(), 9, "Initial validation admission set must queue nine available baked chunks.")
	_assert_equal(streamer.get_loading_coordinates().size(), 0, "No validation load should start before the loading execution stage runs.")
	_assert_equal(streamer.get_queued_coordinates()[0], Vector3i(-1, 0, 0), "The target chunk must be the highest-priority initial request.")
	streamer._process(0.0)
	_assert_equal(streamer.get_loading_coordinates(), [Vector3i(-1, 0, 0)], "The one-per-frame validation budget must start only the target chunk first.")
	_assert_equal(streamer.get_queued_coordinates().size(), 8, "Farther validation chunks must remain queued after the first scheduling update.")

	_assert_true(await _wait_for_thread_smoke(scene), "Validation scene thread smoke task must reach a terminal state.")
	_assert_equal(scene.call("get_thread_smoke_state"), "PASS", "Headless validation must prove WorkerThreadPool task execution.")

	_assert_true(await _wait_for_idle(streamer), "Initial asynchronous validation residency must settle under bounded scheduling.")

	var initial_expected := _expected_coordinates(-2, 0)
	_assert_coordinates_equal(
		streamer.get_loaded_coordinates(),
		initial_expected,
		"Initial validation residency must contain the admitted 3 x 1 x 3 neighborhood after loading."
	)
	_assert_equal(streamer.get_loaded_coordinates().size(), 9, "Initial validation residency must load nine baked chunks.")

	var initial_instances: Dictionary[Vector3i, MeshInstance3D] = {}
	for coordinate in streamer.get_loaded_coordinates():
		var instance := streamer.get_chunk_instance(coordinate)
		initial_instances[coordinate] = instance
		_assert_true(instance != null, "Every resident validation coordinate must own a MeshInstance3D.")
		if instance != null:
			_assert_true(instance.mesh != null, "Every resident validation instance must own a mesh.")
			if instance.mesh != null:
				_assert_true(instance.mesh.get_surface_count() > 0, "Every resident validation mesh must contain renderable surfaces.")

	target.position = Vector3(13.0, target.position.y, target.position.z)
	streamer.update_residency(target.position)

	_assert_equal(streamer.position_to_chunk_coordinate(target.position), Vector3i(1, 0, 0), "Moved target must resolve to chunk (1, 0, 0).")
	_assert_true(not streamer.is_chunk_loaded(Vector3i(-2, 0, 0)), "Chunks beyond the unload radius must be evicted immediately when residency changes.")
	_assert_true(streamer.is_chunk_loaded(Vector3i(-1, 0, 0)), "Loaded chunks outside load radius but on the unload-radius boundary must remain retained.")
	_assert_true(streamer.is_chunk_pending(Vector3i(2, 0, 0)), "Newly admitted baked chunks must enter pending state before residency.")
	_assert_equal(streamer.get_queued_coordinates()[0], Vector3i(1, 0, 0), "The moved target chunk must lead newly queued scheduler work.")
	_assert_true(await _wait_for_idle(streamer), "Moved validation residency must settle asynchronously under scheduler budgets.")

	var moved_expected := _expected_coordinates(-1, 2)
	_assert_coordinates_equal(
		streamer.get_loaded_coordinates(),
		moved_expected,
		"Moved residency must retain the trailing hysteresis band while admitting the new load-radius neighborhood."
	)
	_assert_equal(streamer.get_loaded_coordinates().size(), 12, "Hysteresis must retain one trailing chunk column in the validation fixture.")
	_assert_true(streamer.is_chunk_loaded(Vector3i(2, 0, 0)), "Newly admitted baked chunks must become resident after loading.")

	for coordinate in _expected_coordinates(-1, 0):
		_assert_equal(
			streamer.get_chunk_instance(coordinate),
			initial_instances.get(coordinate),
			"Chunks retained through the hysteresis band must keep their existing instances."
		)

	await process_frame
	_assert_equal(streamer.get_child_count(), 12, "Only chunks beyond the retention radius should be freed after one frame.")

	streamer.update_residency(target.position)
	_assert_true(streamer.get_pending_coordinates().is_empty(), "Duplicate settled residency updates must not create new queued work.")
	_assert_coordinates_equal(streamer.get_loaded_coordinates(), moved_expected, "Duplicate hysteretic residency updates must remain idempotent.")
	_assert_equal(streamer.get_child_count(), 12, "Duplicate validation updates must not create duplicate MeshInstance3D nodes.")

	if status_label != null:
		scene.call("_update_status")
		_assert_true(status_label.text.contains("Thread smoke: PASS"), "Validation UI must display successful worker-thread smoke state.")
		_assert_true(status_label.text.contains("Target chunk: (1, 0, 0)"), "Validation UI must display the current target chunk coordinate.")
		_assert_true(status_label.text.contains("Load radius: 1"), "Validation UI must display the admission radius.")
		_assert_true(status_label.text.contains("Unload radius: 2"), "Validation UI must display the retention radius.")
		_assert_true(status_label.text.contains("Hysteresis band:"), "Validation UI must explain the retention band.")
		_assert_true(status_label.text.contains("Load budget: 1 starts/frame, 2 concurrent"), "Validation UI must display scheduler budgets.")
		_assert_true(status_label.text.contains("Queued chunks: 0"), "Validation UI must display queued load count.")
		_assert_true(status_label.text.contains("Loading chunks: 0"), "Validation UI must display active loading count.")
		_assert_true(status_label.text.contains("Resident chunks: 12"), "Validation UI must display hysteretically retained resident count.")
		_assert_true(status_label.text.contains("Resident surfaces: 12"), "Validation UI must display resident mesh surface count.")

	await _finish(scene)


func _wait_for_thread_smoke(scene: Node, max_frames: int = 180) -> bool:
	for _frame in range(max_frames):
		scene.call("_process", 0.0)
		if bool(scene.call("is_thread_smoke_complete")):
			return true
		await process_frame
	return bool(scene.call("is_thread_smoke_complete"))


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 240) -> bool:
	for _frame in range(max_frames):
		streamer._process(0.0)
		if streamer.get_pending_coordinates().is_empty():
			return true
		await process_frame
	return streamer.get_pending_coordinates().is_empty()


func _expected_coordinates(minimum_x: int, maximum_x: int) -> Array[Vector3i]:
	var coordinates: Array[Vector3i] = []
	for z in range(-1, 2):
		for x in range(minimum_x, maximum_x + 1):
			coordinates.append(Vector3i(x, 0, z))
	coordinates.sort()
	return coordinates


func _assert_coordinates_equal(
	actual: Array[Vector3i],
	expected: Array[Vector3i],
	message: String
) -> void:
	var sorted_actual := actual.duplicate()
	sorted_actual.sort()
	var sorted_expected := expected.duplicate()
	sorted_expected.sort()
	_assert_equal(sorted_actual, sorted_expected, message)


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
