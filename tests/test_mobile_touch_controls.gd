extends SceneTree

const MOBILE_TOUCH_CONTROLS := preload("res://voxel/visualization/MobileTouchControls.tscn")
const NO_CLIP_CAMERA := preload("res://common/input/NoClipCameraController.gd")

var _failed: bool = false


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_controls_drive_shared_input_actions()
	await _test_touch_look_uses_active_camera()
	await _test_touchscreen_only_visibility()

	if _failed:
		quit(1)
	else:
		print("Mobile touch control tests passed.")
		quit(0)


func _test_controls_drive_shared_input_actions() -> void:
	var controls := MOBILE_TOUCH_CONTROLS.instantiate() as MobileTouchControls
	controls.show_on_touchscreen_only = false
	root.add_child(controls)
	await process_frame

	var action_buttons := {
		"move_forward": controls.get_node("%ForwardButton") as Button,
		"move_backward": controls.get_node("%BackwardButton") as Button,
		"move_left": controls.get_node("%LeftButton") as Button,
		"move_right": controls.get_node("%RightButton") as Button,
		"move_up": controls.get_node("%UpButton") as Button,
		"move_down": controls.get_node("%DownButton") as Button,
		"move_fast": controls.get_node("%FastButton") as Button,
	}

	for action: String in action_buttons:
		var button := action_buttons[action] as Button
		_assert_true(button != null, "%s touch control must exist." % action)
		_assert_true(button.visible, "%s touch control must be visible when touch-only filtering is disabled." % action)
		button.button_down.emit()
		_assert_true(Input.is_action_pressed(action), "%s touch control must press its shared input action." % action)
		button.button_up.emit()
		_assert_true(not Input.is_action_pressed(action), "%s touch control must release its shared input action." % action)

	controls.queue_free()
	await process_frame


func _test_touch_look_uses_active_camera() -> void:
	var camera := NO_CLIP_CAMERA.new() as NoClipCameraController
	root.add_child(camera)
	camera.make_current()
	await process_frame

	var controls := MOBILE_TOUCH_CONTROLS.instantiate() as MobileTouchControls
	controls.show_on_touchscreen_only = false
	root.add_child(controls)
	await process_frame

	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	controls._handle_look_touch(touch)

	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.screen_relative = Vector2(20.0, -10.0)
	controls._handle_look_drag(drag)

	_assert_true(not is_zero_approx(camera.rotation.y), "Touch drag must rotate the active no-clip camera yaw.")
	_assert_true(not is_zero_approx(camera.rotation.x), "Touch drag must rotate the active no-clip camera pitch.")

	touch.pressed = false
	controls._handle_look_touch(touch)

	controls.queue_free()
	camera.queue_free()
	await process_frame


func _test_touchscreen_only_visibility() -> void:
	var controls := MOBILE_TOUCH_CONTROLS.instantiate() as MobileTouchControls
	controls.show_on_touchscreen_only = true
	root.add_child(controls)
	await process_frame

	_assert_true(
		controls.visible == controls._is_touch_input_available(),
		"Touch controls visibility must follow the shared touch capability check."
	)

	controls.queue_free()
	await process_frame


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
