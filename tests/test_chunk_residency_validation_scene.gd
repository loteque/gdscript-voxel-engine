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
	var panel := scene.get_node("UI/Panel") as PanelContainer
	var summary_grid := scene.get_node("UI/Panel/Margin/Content/Summary") as GridContainer
	var metrics_grid := scene.get_node("UI/Panel/Margin/Content/Metrics") as GridContainer
	var buttons_grid := scene.get_node("UI/Panel/Margin/Content/Buttons") as GridContainer
	var thread_value := scene.get_node("UI/Panel/Margin/Content/Summary/ThreadCard/Margin/VBox/Value") as Label
	var background_value := scene.get_node("UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/Grid/BackgroundValue") as Label
	var residency_value := scene.get_node("UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/Grid/ResidencyValue") as Label
	var total_value := scene.get_node("UI/Panel/Margin/Content/Metrics/TimingCard/Margin/VBox/TotalRow/Value") as Label
	var completed_value := scene.get_node("UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/CompletedValue") as Label
	var failed_value := scene.get_node("UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Grid/FailedValue") as Label
	var target_label := scene.get_node("UI/Panel/Margin/Content/Metrics/RunCard/Margin/VBox/Target") as Label
	var details_scroll := scene.get_node("UI/Panel/Margin/Content/DetailsScroll") as ScrollContainer
	var details_label := scene.get_node("UI/Panel/Margin/Content/DetailsScroll/Details") as Label
	var details_button := scene.get_node("UI/Panel/Margin/Content/DetailsToggle") as Button
	var pause_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Load") as Button
	var reset_button := scene.get_node("UI/Panel/Margin/Content/Buttons/Unload") as Button
	var concurrency_selector := scene.get_node("UI/Panel/Margin/Content/Summary/ConcurrencyCard/Margin/VBox/Concurrency") as OptionButton
	var cache_selector := scene.get_node("UI/Panel/Margin/Content/Summary/CacheCard/Margin/VBox/Cache") as OptionButton
	var instructions := scene.get_node("UI/Panel/Margin/Content/InfoCard/Margin/Instructions") as Label

	_assert_true(streamer != null, "Streaming validation scene must contain ChunkStreamer.")
	_assert_true(target != null, "Streaming validation scene must contain an explicit Node3D target.")
	_assert_true(panel != null, "Streaming validation UI must expose its accessible dashboard panel.")
	_assert_true(summary_grid != null and metrics_grid != null and buttons_grid != null, "Streaming validation dashboard must use responsive grid layout containers.")
	_assert_true(thread_value != null, "Streaming validation UI must expose thread-smoke status prominently.")
	_assert_true(background_value != null and residency_value != null and total_value != null, "Streaming validation UI must expose separated loading timings.")
	_assert_true(completed_value != null and failed_value != null, "Streaming validation UI must expose run completion state.")
	_assert_true(target_label != null, "Streaming validation UI must expose target state.")
	_assert_true(details_scroll != null and details_label != null, "Streaming validation UI must retain bounded expandable diagnostics.")
	_assert_true(details_button != null, "Streaming validation UI must expose a diagnostics toggle.")
	_assert_true(concurrency_selector != null, "Streaming validation UI must expose controlled concurrency selection.")
	_assert_true(cache_selector != null, "Streaming validation UI must expose cache-provenance labeling.")
	_assert_true(instructions != null, "Streaming validation UI must retain experiment guidance.")
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

	if panel != null:
		_assert_true(panel.offset_top >= 100.0, "Accessible dashboard must reserve vertical space for the injected Pages selector.")
		_assert_equal(panel.anchor_right, 1.0, "Accessible dashboard must size against the viewport rather than a fixed right edge.")
		_assert_true(panel.offset_right < 0.0, "Accessible dashboard must preserve a viewport-relative right margin.")
	if thread_value != null:
		_assert_true(thread_value.get_theme_font_size("font_size") >= 30, "Primary status values must use accessibility-sized typography.")
	if total_value != null:
		_assert_true(total_value.get_theme_font_size("font_size") >= 30, "Primary timing total must use accessibility-sized typography.")
	if instructions != null:
		_assert_true(instructions.get_theme_font_size("font_size") >= 20, "Experiment guidance must remain readable on mobile.")
	if pause_button != null and reset_button != null:
		_assert_true(pause_button.custom_minimum_size.y >= 70.0, "Primary controls must provide large touch targets.")
		_assert_true(reset_button.custom_minimum_size.y >= 70.0, "Reset control must provide a large touch target.")
	if details_scroll != null:
		_assert_true(details_scroll.custom_minimum_size.y > 0.0 and details_scroll.custom_minimum_size.y <= 300.0, "Expanded diagnostics must remain vertically bounded and scrollable.")
	if concurrency_selector != null and cache_selector != null:
		_assert_true(not concurrency_selector.fit_to_longest_item, "Concurrency selector must not force the dashboard wider than the viewport.")
		_assert_true(not cache_selector.fit_to_longest_item, "Cache selector must not force the dashboard wider than the viewport.")

	if summary_grid != null and metrics_grid != null and buttons_grid != null:
		scene.call("_apply_responsive_layout", 700.0)
		_assert_equal(summary_grid.columns, 1, "Narrow layout must stack summary cards instead of overflowing horizontally.")
		_assert_equal(metrics_grid.columns, 1, "Narrow layout must stack metric cards instead of overflowing horizontally.")
		_assert_equal(buttons_grid.columns, 1, "Narrow layout must stack primary controls instead of overflowing horizontally.")
		scene.call("_apply_responsive_layout", 1200.0)
		_assert_equal(summary_grid.columns, 3, "Wide layout must preserve the three-card summary row.")
		_assert_equal(metrics_grid.columns, 2, "Wide layout must preserve the two-card metric row.")
		_assert_equal(buttons_grid.columns, 2, "Wide layout must preserve paired primary controls.")

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

	scene.call("_update_status")
	if thread_value != null:
		_assert_equal(thread_value.text, "DISABLED", "Primary thread card must expose thread-smoke state.")
	if background_value != null:
		_assert_true(background_value.text.ends_with("ms"), "Load timing card must expose background wait.")
	if residency_value != null:
		_assert_true(residency_value.text.ends_with("ms"), "Load timing card must expose residency completion.")
	if total_value != null:
		_assert_true(total_value.text.ends_with("ms"), "Load timing card must expose aggregate latency.")
	if completed_value != null and failed_value != null:
		_assert_true(completed_value.text.is_valid_int(), "Run card must expose completed load count.")
		_assert_true(failed_value.text.is_valid_int(), "Run card must expose failed load count.")

	if details_scroll != null and details_label != null:
		_assert_true(not details_scroll.visible, "Verbose streaming diagnostics must be collapsed by default.")
		_assert_true(details_label.text.contains("Dataset: 169 single-LOD chunks"), "Expanded diagnostics must identify the large dataset.")
		_assert_true(details_label.text.contains("Load radius: 2 | Unload radius: 3"), "Expanded diagnostics must display residency policy.")
		_assert_true(details_label.text.contains("Load budget: 2 starts/frame, 4 concurrent"), "Expanded diagnostics must display scheduler budgets.")
		_assert_true(details_label.text.contains("Peak resident chunks:"), "Expanded diagnostics must retain peak residency.")
		_assert_true(details_label.text.contains("Completed observations:"), "Expanded diagnostics must retain observation count.")
		_assert_true(details_label.text.contains("Last load:"), "Expanded diagnostics must retain asset-size and mesh-complexity context.")
		_assert_true(details_label.text.contains("Timing boundary: polling-cadence observed"), "Expanded diagnostics must state the timing-resolution limitation.")
		_assert_true(details_label.text.contains("Resident coordinates:"), "Expanded diagnostics must retain coordinate-level debugging.")

	if details_button != null and details_scroll != null:
		details_button.pressed.emit()
		_assert_true(details_scroll.visible, "Details control must reveal bounded streaming diagnostics.")
		_assert_equal(details_button.text, "Hide streaming details", "Details control must clearly describe the expanded state.")
		details_button.pressed.emit()
		_assert_true(not details_scroll.visible, "Details control must collapse verbose streaming diagnostics again.")

	if pause_button != null:
		pause_button.pressed.emit()
		scene.call("_update_status")
		_assert_true(target_label.text.contains("paused"), "Manual pause must remain visible in primary target state.")
		_assert_equal(pause_button.text, "Resume Target", "Pause control must clearly expose its resumed action without unsupported decorative glyphs.")

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
