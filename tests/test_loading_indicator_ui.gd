extends SceneTree

const RUNTIME_UI_SCENE := preload("res://voxel/visualization/PointFieldRuntimeUI.tscn")
const POINT_FIELD_VISUALIZER := preload("res://voxel/visualization/PointFieldVisualizer.gd")
const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")

var _failed: bool = false


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_loading_indicator_tracks_visualizer_work()
	await _test_runtime_controls_report_automatic_regeneration()

	if _failed:
		quit(1)
	else:
		print("Loading indicator UI tests passed.")
		quit(0)


func _test_loading_indicator_tracks_visualizer_work() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.noise = FastNoiseLite.new()
	field.regenerate()

	var visualizer := POINT_FIELD_VISUALIZER.new()
	visualizer.field = field
	root.add_child(visualizer)

	var runtime_ui := RUNTIME_UI_SCENE.instantiate()
	runtime_ui.visualizer = visualizer
	root.add_child(runtime_ui)
	await process_frame

	var loading_panel := runtime_ui.get_node("%LoadingPanel") as PanelContainer
	var loading_label := runtime_ui.get_node("%LoadingLabel") as Label

	_assert_true(not loading_panel.visible, "Loading indicator must start hidden.")

	visualizer.request_field_regeneration()
	_assert_true(loading_panel.visible, "Loading indicator must become visible when regeneration is queued.")
	_assert_true(loading_label.text.begins_with("loading"), "Loading indicator must display loading text.")

	await process_frame
	_assert_true(loading_panel.visible, "Loading indicator must remain visible long enough to render.")

	await create_timer(0.3).timeout
	_assert_true(not visualizer.is_loading, "Visualizer must eventually finish regeneration.")
	_assert_true(not loading_panel.visible, "Loading indicator must hide after work and minimum display time finish.")

	runtime_ui.queue_free()
	visualizer.queue_free()
	await process_frame


func _test_runtime_controls_report_automatic_regeneration() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.noise = FastNoiseLite.new()
	field.regenerate()

	var visualizer := POINT_FIELD_VISUALIZER.new()
	visualizer.field = field
	root.add_child(visualizer)

	var runtime_ui := RUNTIME_UI_SCENE.instantiate()
	runtime_ui.visualizer = visualizer
	root.add_child(runtime_ui)
	await process_frame

	var runtime_panel = runtime_ui.get_node("%PointFieldRuntimePanel")
	var loading_panel := runtime_ui.get_node("%LoadingPanel") as PanelContainer

	runtime_panel._on_terrain_height_scale_changed(field.terrain_height_scale + 1.0)
	_assert_true(visualizer.is_loading, "Terrain Height Scale edits must report automatic regeneration as loading.")
	_assert_true(loading_panel.visible, "Terrain Height Scale edits must show the loading indicator.")
	await _wait_for_loading_to_finish(visualizer)

	runtime_panel._on_noise_frequency_changed(field.noise.frequency + 0.01)
	_assert_true(visualizer.is_loading, "Noise Frequency edits must report automatic regeneration as loading.")
	_assert_true(loading_panel.visible, "Noise Frequency edits must show the loading indicator.")
	await _wait_for_loading_to_finish(visualizer)

	runtime_panel._cell_x.value = field.cell_dimensions.x + 1
	runtime_panel._on_cell_dimensions_changed(runtime_panel._cell_x.value)
	_assert_true(visualizer.is_loading, "Cell dimension edits must report automatic regeneration as loading.")
	_assert_true(loading_panel.visible, "Cell dimension edits must show the loading indicator.")
	await _wait_for_loading_to_finish(visualizer)

	runtime_ui.queue_free()
	visualizer.queue_free()
	await process_frame


func _wait_for_loading_to_finish(visualizer: Node) -> void:
	var frames := 0
	while visualizer.is_loading and frames < 30:
		await process_frame
		frames += 1
	await create_timer(0.3).timeout


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
