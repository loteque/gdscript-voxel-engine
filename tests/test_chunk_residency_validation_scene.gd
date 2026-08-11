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
	_assert_equal(streamer.residency_radius, 1, "Validation scene must exercise residency radius 1.")
	_assert_equal(streamer.position_to_chunk_coordinate(target.position), Vector3i(-1, 0, 0), "Initial target position must resolve to chunk (-1, 0, 0).")

	if pause_button != null:
		pause_button.pressed.emit()

	_assert_equal(streamer.get_pending_coordinates().size(), 9, "Initial validation residency must queue nine available baked chunks.")
	await process_frame
	_assert_equal(streamer.get_pending_coordinates().size(), 9, "Queued validation chunks must enter threaded loading without becoming duplicate work.")
	_assert_true(await _wait_for_idle(streamer), "Initial asynchronous validation residency must settle.")

	var initial_expected := _expected_coordinates(-2, 0)
	_assert_coordinates_equal(
		streamer.get_loaded_coordinates(),
		initial_expected,
		"Initial validation residency must contain the available 3 x 1 x 3 neighborhood after loading."
	)
	_assert_equal(streamer.get_loaded_coordinates().size(), 9, "Initial validation residency must load nine baked chunks.")

	var initial_instances: Dictionary[Vector3i, MeshInstance3D] = {}
	for coordinate in streamer.get_loaded_coordinates():
		initial_instances[coordinate] = streamer.get_chunk_instance(coordinate)

	target.position = Vector3(13.0, target.position.y, target.position.z)
	streamer.update_residency(target.position)

	_assert_equal(streamer.position_to_chunk_coordinate(target.position), Vector3i(1, 0, 0), "Moved target must resolve to chunk (1, 0, 0).")
	_assert_true(not streamer.is_chunk_loaded(Vector3i(-2, 0, 0)), "Obsolete resident chunks must unload immediately when residency changes.")
	_assert_true(streamer.is_chunk_pending(Vector3i(2, 0, 0)), "Newly desired baked chunks must enter pending state before residency.")
	_assert_true(await _wait_for_idle(streamer), "Moved validation residency must settle asynchronously.")

	var moved_expected := _expected_coordinates(0, 2)
	_assert_coordinates_equal(
		streamer.get_loaded_coordinates(),
		moved_expected,
		"Crossing into chunk (1, 0, 0) must replace obsolete residents with the new neighborhood."
	)
	_assert_equal(streamer.get_loaded_coordinates().size(), 9, "Moved residency must retain nine available baked chunks.")
	_assert_true(streamer.is_chunk_loaded(Vector3i(2, 0, 0)), "Newly desired baked chunks must become resident after loading.")

	for coordinate in _expected_coordinates(0, 0):
		_assert_equal(
			streamer.get_chunk_instance(coordinate),
			initial_instances.get(coordinate),
			"Chunks shared by consecutive residency sets must keep their existing instances."
		)

	await process_frame
	_assert_equal(streamer.get_child_count(), 9, "Queued obsolete chunk instances must be freed after one frame.")

	streamer.update_residency(target.position)
	_assert_true(streamer.get_pending_coordinates().is_empty(), "Duplicate settled residency updates must not create new queued work.")
	_assert_coordinates_equal(streamer.get_loaded_coordinates(), moved_expected, "Duplicate residency updates must remain idempotent in the validation scene.")
	_assert_equal(streamer.get_child_count(), 9, "Duplicate validation updates must not create duplicate MeshInstance3D nodes.")

	if status_label != null:
		_assert_true(status_label.text.contains("Target chunk: (1, 0, 0)"), "Validation UI must display the current target chunk coordinate.")
		_assert_true(status_label.text.contains("Pending chunks: 0"), "Validation UI must display pending load count.")
		_assert_true(status_label.text.contains("Resident chunks: 9"), "Validation UI must display resident chunk count.")

	await _finish(scene)


func _wait_for_idle(streamer: ChunkStreamer, max_frames: int = 180) -> bool:
	for _frame in range(max_frames):
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
