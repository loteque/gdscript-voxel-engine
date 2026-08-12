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
	var details_label := scene.get_node("UI/Panel/Margin/Content/Details") as Label
	var details_button := scene.get_node("UI/Panel/Margin/Content/DetailsToggle") as Button
	var pause_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Load") as Button
	var reset_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Unload") as Button
	var concurrency_selector := scene.get_node("UI/Panel/Margin/Content/Experiment/Concurrency") as OptionButton
	var cache_selector := scene.get_node("UI/Panel/Margin/Content/Experiment/Cache") as OptionButton

	_assert_true(streamer != null, "Streaming validation scene must contain ChunkStreamer.")
	_assert_true(target != null, "Streaming validation scene must contain an explicit Node3D target.")
	_assert_true(status_label != null, "Streaming validation UI must expose primary experiment state.")
	_assert_true(details_label != null, "Streaming validation UI must retain expandable diagnostics.")
	_assert_true(details_button != null, "Streaming validation UI must expose a diagnostics toggle.")
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
		_assert_true(status_label.text.contains("Threading: disabled"), "Primary dashboard must expose thread-smoke state.")
		_assert_true(status_label.text.contains("Cache: unknown"), "Primary dashboard must expose cache provenance.")
		_assert_true(status_label.text.contains("Concurrency: 4"), "Primary dashboard must expose current concurrency.")
		_assert_true(status_label.text.contains("LOAD TIMING"), "Primary dashboard must foreground load timing.")
		_assert_true(status_label.text.contains("Background:"), "Primary dashboard must expose background wait.")
		_assert_true(status_label.text.contains("Residency:"), "Primary dashboard must expose residency completion.")
		_assert_true(status_label.text.contains("Total:"), "Primary dashboard must expose aggregate latency.")
		_assert_true(status_label.text.contains("Completed:"), "Primary dashboard must expose completed loads.")
		_assert_true(status_label.text.contains("Failed:"), "Primary dashboard must expose failed loads.")
		_assert_true(status_label.text.contains("Frame:"), "Primary dashboard must expose current frame time.")
		_assert_true(not status_label.text.contains("Resident coordinates:"), "Primary mobile dashboard must not be dominated by verbose coordinate lists.")

	if details_label != null:
		_assert_true(not details_label.visible, "Verbose streaming diagnostics must be collapsed by default.")
		_assert_true(details_label.text.contains("Dataset: 169 single-LOD chunks"), "Expanded diagnostics must identify the large dataset.")
		_assert_true(details_label.text.contains("Load radius: 2 | Unload radius: 3"), "Expanded diagnostics must display residency policy.")
		_assert_true(details_label.text.contains("Load budget: 2 starts/frame, 4 concurrent"), "Expanded diagnostics must display scheduler budgets.")
		_assert_true(details_label.text.contains("Peak resident chunks:"), "Expanded diagnostics must retain peak residency.")
		_assert_true(details_label.text.contains("Completed observations:"), "Expanded diagnostics must retain observation count.")
		_assert_true(details_label.text.contains("Last load:"), "Expanded diagnostics must retain asset-size and mesh-complexity context.")
		_assert_true(details_label.text.contains("Timing boundary: polling-cadence observed"), "Expanded diagnostics must state the timing-resolution limitation.")
		_assert_true(details_label.text.contains("Resident coordinates:"), "Expanded diagnostics must retain coordinate-level debugging.")

	if details_button != null and details_label != null:
		details_button.pressed.emit()
		_assert_true(details_label.visible, "Details control must reveal verbose streaming diagnostics.")
		_assert_equal(details_button.text, "Hide streaming details", "Details control must clearly describe the expanded state.")
		details_button.pressed.emit()
		_assert_true(not details_label.visible, "Details control must collapse verbose streaming diagnostics again.")

	if pause_button != null:
		pause_button.pressed.emit()
		scene.call("_update_status")
		_assert_true(status_label.text.contains("paused"), "Manual pause must remain visible in primary target state.")

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