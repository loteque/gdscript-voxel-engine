extends SceneTree

const RUNTIME_UI_SCENE := preload("res://voxel/visualization/PointFieldRuntimeUI.tscn")
const POINT_FIELD_VISUALIZER := preload("res://voxel/visualization/PointFieldVisualizer.gd")
const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")

var _failed: bool = false


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_loading_indicator_tracks_visualizer_work()

	if _failed:
		quit(1)
	else:
		print("Loading indicator UI tests passed.")
		quit(0)


func _test_loading_indicator_tracks_visualizer_work() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.noise = FastNoiseLite.new()

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


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
