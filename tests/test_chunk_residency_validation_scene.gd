extends SceneTree

const VALIDATION_SCENE := preload("res://demo/ChunkStreamingValidationDemo.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := VALIDATION_SCENE.instantiate() as Node3D
	scene.thread_smoke_enabled = false
	root.add_child(scene)

	var streamer := scene.get_node("ChunkStreamer") as ChunkStreamer
	var target := scene.get_node("ResidencyTarget") as Node3D
	var status_label := scene.get_node("UI/Panel/Margin/Content/Status") as Label
	var pause_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Load") as Button
	var reset_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Unload") as Button
	var concurrency_selector := scene.get_node("UI/Panel/Margin/Content/Experiment/Concurrency") as OptionButton
	var cache_selector := scene.get_node("UI/Panel/Margin/Content/Experiment/Cache") as OptionButton

	_assert_true(streamer != null, "Streaming validation scene must contain ChunkStreamer.")
	_assert_true(target != null, "Streaming validation scene must contain an explicit Node3D target.")
	_assert_true(status_label != null, "Streaming validation UI must expose runtime scaling state.")
	_assert_true(concurrency_selector != null, "Streaming validation UI must expose controlled concurrency selection.")
	_assert_true(cache_selector != null, "Streaming validation UI must expose cache-provenance labeling.")
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
	_assert_equal(scene.call("get_cache_provenance"), "unknown", "Validation cache provenance must default to unknown rather than imply a cache state.")
	if concurrency_selector != null:
		_assert_equal(concurrency_selector.item_count, 4, "Validation concurrency selector must expose the controlled 1/2/4/8 matrix.")
		_assert_equal(concurrency_selector.get_item_id(concurrency_selector.selected), 4, "Validation concurrency selector must begin at the production demo default of four.")
	if cache_selector != null:
		_assert_equal(cache_selector.item_count, 3, "Validation cache selector must expose unknown, cold-ish, and warm provenance labels.")

	streamer.process_mode = Node.PROCESS_MODE_DISABLED
	_assert_equal(streamer.get_queued_coordinates().size(), 25, "Initial large validation admission must create a 25-chunk queue.")
	_assert_equal(streamer.get_queued_coordinates()[0], Vector3i(-4, 0, -4), "Nearest-first scheduling must prioritize the target chunk.")
	_assert_equal(streamer.get_loading_coordinates().size(), 0, "Scene wiring test must not start background loading; the dedicated scale test owns async execution proof.")

	var target_before_pending_update := target.position
	scene.call("_process", 1.0)
	_assert_equal(target.position, target_before_pending_update, "Automatic validation traversal must wait while residency work is pending.")
	if reset_button != null:
		_assert_true(reset_button.disabled, "Experiment reset must be disabled while pending work exists.")
	if concurrency_selector != null:
		_assert_true(concurrency_selector.disabled, "Concurrency changes must be disabled while pending work exists.")

	if status_label != null:
		scene.call("_update_status")
		_assert_true(status_label.text.contains("Dataset: 169 single-LOD chunks"), "Validation UI must identify the large dataset.")
		_assert_true(status_label.text.contains("Thread smoke: disabled"), "Headless scene wiring test must not depend on WorkerThreadPool completion.")
		_assert_true(status_label.text.contains("Run cache label: unknown"), "Validation UI must preserve explicit unknown cache provenance by default.")
		_assert_true(status_label.text.contains("Target motion: waiting for streaming"), "Validation UI must expose loader-gated automatic traversal.")
		_assert_true(status_label.text.contains("Load radius: 2"), "Validation UI must display the admission radius.")
		_assert_true(status_label.text.contains("Unload radius: 3"), "Validation UI must display the retention radius.")
		_assert_true(status_label.text.contains("Load budget: 2 starts/frame, 4 concurrent"), "Validation UI must display scheduler budgets.")
		_assert_true(status_label.text.contains("Peak resident chunks:"), "Validation UI must expose peak residency.")
		_assert_true(status_label.text.contains("Completed loads:"), "Validation UI must expose completed load count.")
		_assert_true(status_label.text.contains("Average aggregate latency:"), "Validation UI must expose aggregate load latency.")
		_assert_true(status_label.text.contains("Average background wait:"), "Validation UI must expose polling-observed background wait.")
		_assert_true(status_label.text.contains("Average residency completion:"), "Validation UI must expose post-background residency completion.")
		_assert_true(status_label.text.contains("Completed observations:"), "Validation UI must expose bounded load-observation count.")
		_assert_true(status_label.text.contains("Last load:"), "Validation UI must expose asset-size and mesh-complexity correlation context.")
		_assert_true(status_label.text.contains("Timing boundary: polling-cadence observed"), "Validation UI must state the timing-resolution limitation.")
		_assert_true(status_label.text.contains("Approx. resident mesh memory:"), "Validation UI must expose approximate mesh memory.")
		_assert_true(status_label.text.contains("Recent max frame time:"), "Validation UI must expose recent frame-time observation.")

	if pause_button != null:
		pause_button.pressed.emit()
		scene.call("_update_status")
		_assert_true(status_label.text.contains("Target motion: paused"), "Manual pause must remain distinct from streaming backpressure.")

	await _finish(scene)


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
