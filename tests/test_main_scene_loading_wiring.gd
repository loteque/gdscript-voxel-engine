extends SceneTree

var _failed: bool = false


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var main_scene_path := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	_assert_true(not main_scene_path.is_empty(), "Project must configure a main scene.")

	var packed_scene := load(main_scene_path) as PackedScene
	_assert_true(packed_scene != null, "Configured main scene must load as a PackedScene.")
	if packed_scene == null:
		quit(1)
		return

	var main_scene := packed_scene.instantiate()
	root.add_child(main_scene)
	await process_frame

	var runtime_ui := _find_runtime_ui(main_scene)
	var surface_nets_display := _find_surface_nets_display(main_scene)

	_assert_true(runtime_ui != null, "Main scene must contain PointFieldRuntimeUI.")
	_assert_true(surface_nets_display != null, "Main scene must contain SurfaceNetsMeshDisplay.")

	if runtime_ui != null and surface_nets_display != null:
		var runtime_panel = runtime_ui.get_node("%PointFieldRuntimePanel")
		var loading_panel := runtime_ui.get_node("%LoadingPanel") as PanelContainer

		_assert_true(
			runtime_ui.surface_nets_display == surface_nets_display,
			"PointFieldRuntimeUI must aggregate loading from the main scene SurfaceNetsMeshDisplay."
		)
		_assert_true(
			runtime_panel.surface_nets_display == surface_nets_display,
			"SurfaceNetsRuntimePanel must control the same SurfaceNetsMeshDisplay observed by PointFieldRuntimeUI."
		)

		await _wait_for_main_scene_idle(runtime_ui, surface_nets_display)

		if surface_nets_display.display_surface_nets_mesh:
			runtime_panel._on_display_surface_nets_mesh_toggled(false)
			await process_frame

		surface_nets_display.invalidate_mesh()
		await create_timer(0.3).timeout
		_assert_true(not loading_panel.visible, "Loading indicator must be hidden before enabling a dirty Surface Nets mesh.")

		runtime_panel._on_display_surface_nets_mesh_toggled(true)
		_assert_true(surface_nets_display.is_loading, "Main scene Surface Nets checkbox must queue mesh loading.")
		_assert_true(loading_panel.visible, "Main scene Surface Nets checkbox must show the loading indicator.")

	main_scene.queue_free()
	await process_frame

	if _failed:
		quit(1)
	else:
		print("Main scene loading wiring test passed.")
		quit(0)


func _wait_for_main_scene_idle(
	runtime_ui: PointFieldRuntimeUI,
	surface_nets_display: SurfaceNetsMeshDisplay
) -> void:
	var frames := 0
	while frames < 120:
		var visualizer_busy := runtime_ui.visualizer != null and runtime_ui.visualizer.is_loading
		var mesh_busy := surface_nets_display.is_loading
		var field_current := (
			surface_nets_display.field != null
			and surface_nets_display.field.is_data_current()
		)
		if not visualizer_busy and not mesh_busy and field_current:
			break
		await process_frame
		frames += 1
	await create_timer(0.3).timeout


func _find_runtime_ui(node: Node) -> PointFieldRuntimeUI:
	if node is PointFieldRuntimeUI:
		return node as PointFieldRuntimeUI
	for child in node.get_children():
		var result := _find_runtime_ui(child)
		if result != null:
			return result
	return null


func _find_surface_nets_display(node: Node) -> SurfaceNetsMeshDisplay:
	if node is SurfaceNetsMeshDisplay:
		return node as SurfaceNetsMeshDisplay
	for child in node.get_children():
		var result := _find_surface_nets_display(child)
		if result != null:
			return result
	return null


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
