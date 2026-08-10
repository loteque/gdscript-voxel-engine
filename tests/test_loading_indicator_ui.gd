extends SceneTree

const RUNTIME_UI_SCENE := preload("res://voxel/visualization/PointFieldRuntimeUI.tscn")
const POINT_FIELD_VISUALIZER := preload("res://voxel/visualization/PointFieldVisualizer.gd")
const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")
const SURFACE_NETS_DISPLAY := preload("res://voxel/meshing/SurfaceNetsMeshDisplay.gd")

var _failed: bool = false


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_loading_indicator_tracks_visualizer_work()
	await _test_runtime_controls_report_automatic_regeneration()
	await _test_surface_nets_checkbox_reports_mesh_loading()
	await _test_numeric_text_edits_commit_on_submit()

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


func _test_surface_nets_checkbox_reports_mesh_loading() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.noise = FastNoiseLite.new()
	field.regenerate()

	var visualizer := POINT_FIELD_VISUALIZER.new()
	visualizer.field = field
	root.add_child(visualizer)

	var surface_nets_display := SURFACE_NETS_DISPLAY.new()
	surface_nets_display.field = field
	root.add_child(surface_nets_display)

	var runtime_ui := RUNTIME_UI_SCENE.instantiate()
	runtime_ui.visualizer = visualizer
	runtime_ui.surface_nets_display = surface_nets_display
	root.add_child(runtime_ui)
	await process_frame

	var runtime_panel = runtime_ui.get_node("%PointFieldRuntimePanel")
	var loading_panel := runtime_ui.get_node("%LoadingPanel") as PanelContainer

	_assert_true(not loading_panel.visible, "Loading indicator must start hidden before Surface Nets is enabled.")

	runtime_panel._on_display_surface_nets_mesh_toggled(true)
	_assert_true(surface_nets_display.is_loading, "Enabling Surface Nets with a dirty mesh must report mesh loading.")
	_assert_true(loading_panel.visible, "Enabling Surface Nets must show the loading indicator while the mesh rebuild is queued.")

	await process_frame
	_assert_true(loading_panel.visible, "Surface Nets loading indicator must remain visible long enough to render.")
	await create_timer(0.3).timeout
	_assert_true(not surface_nets_display.is_loading, "Surface Nets display must finish mesh generation.")
	_assert_true(not loading_panel.visible, "Surface Nets loading indicator must hide after mesh generation finishes.")

	runtime_ui.queue_free()
	surface_nets_display.queue_free()
	visualizer.queue_free()
	await process_frame


func _test_numeric_text_edits_commit_on_submit() -> void:
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
	var spin_box: SpinBox = runtime_panel._terrain_height_scale
	var line_edit := spin_box.get_line_edit()
	var original_value := field.terrain_height_scale
	var edited_value := original_value + 2.0

	_assert_true(not spin_box.update_on_text_changed, "Numeric text edits must not update terrain values while the user is typing.")
	_assert_true(line_edit.focus_exited.is_connected(spin_box.apply), "Numeric text edits must commit when the input loses focus.")

	line_edit.text = str(edited_value)
	_assert_true(is_equal_approx(field.terrain_height_scale, original_value), "Typing into a numeric input must not commit the terrain value before submission.")
	_assert_true(not visualizer.is_loading, "Typing an uncommitted numeric value must not start terrain regeneration.")

	spin_box.apply()
	_assert_true(is_equal_approx(field.terrain_height_scale, edited_value), "Submitting a numeric input must commit the terrain value.")
	_assert_true(visualizer.is_loading, "Submitting a generation-affecting numeric value must start regeneration.")
	await _wait_for_loading_to_finish(visualizer)

	var arrow_value := edited_value + spin_box.step
	spin_box.value = arrow_value
	_assert_true(is_equal_approx(field.terrain_height_scale, arrow_value), "Spinner arrow-style value changes must remain immediate.")
	_assert_true(visualizer.is_loading, "Immediate spinner changes must still report regeneration as loading.")
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
