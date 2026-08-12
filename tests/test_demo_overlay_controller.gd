extends SceneTree

const VALIDATION_SCENE := preload("res://demo/ChunkValidationDemo.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay_controller := root.get_node_or_null("DemoOverlayController")
	_assert_true(overlay_controller != null, "Demo overlay controller autoload must be available.")
	if overlay_controller == null:
		quit(1)
		return

	_assert_true(
		overlay_controller.call("is_demo_scene_path", "res://demo/FutureValidationDemo.tscn"),
		"Every scene under res://demo/ must participate in the collapsible overlay convention."
	)
	_assert_true(
		not overlay_controller.call("is_demo_scene_path", "res://voxel/chunking/ChunkStreamer.gd"),
		"Production/runtime paths must not be treated as demo scenes."
	)

	var scene := VALIDATION_SCENE.instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	var instructions := scene.get_node("Instructions") as CanvasLayer
	var mobile_controls := scene.get_node("MobileControlsLayer") as CanvasLayer
	var toggle_button := overlay_controller.get_node(
		"DemoOverlayToggleLayer/DemoOverlayToggleButton"
	) as Button

	_assert_true(instructions != null, "Chunk validation must expose its instruction overlay layer.")
	_assert_true(mobile_controls != null, "Chunk validation must expose its mobile-controls overlay layer.")
	_assert_true(toggle_button != null, "Demo overlay controller must expose a persistent restore control.")
	if instructions == null or mobile_controls == null or toggle_button == null:
		await _finish(scene)
		return

	_assert_true(toggle_button.visible, "Demo overlay toggle must be visible for demo scenes.")
	_assert_true(toggle_button.custom_minimum_size.y >= 70.0, "Demo overlay toggle must remain accessibility-sized.")
	_assert_equal(toggle_button.text, "Hide UI", "Expanded demos must offer an explicit Hide UI action.")

	overlay_controller.call("set_overlays_visible", false)
	_assert_true(not instructions.visible, "Collapsing demo UI must hide instruction overlays.")
	_assert_true(not mobile_controls.visible, "Collapsing demo UI must hide mobile-control overlays.")
	_assert_true(toggle_button.visible, "Restore control must remain visible while demo overlays are collapsed.")
	_assert_equal(toggle_button.text, "Show UI", "Collapsed demos must expose an explicit Show UI action.")

	overlay_controller.call("set_overlays_visible", true)
	_assert_true(instructions.visible, "Restoring demo UI must restore instruction overlays.")
	_assert_true(mobile_controls.visible, "Restoring demo UI must restore mobile-control overlays.")
	_assert_equal(toggle_button.text, "Hide UI", "Restored demos must return to the Hide UI action.")

	await _finish(scene)


func _finish(scene: Node) -> void:
	current_scene = null
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
