extends SceneTree

const NO_CLIP_CAMERA := preload("res://common/input/NoClipCameraController.gd")

var _failed: bool = false


func _initialize() -> void:
	_run_tests.call_deferred()


func _run_tests() -> void:
	await _test_public_look_api()
	await _test_pitch_clamping()
	await _test_forward_movement_contract()

	if _failed:
		quit(1)
	else:
		print("Common no-clip camera tests passed.")
		quit(0)


func _test_public_look_api() -> void:
	var camera := NO_CLIP_CAMERA.new() as NoClipCameraController
	root.add_child(camera)
	await process_frame

	camera.rotation = Vector3(0.25, 0.5, 0.0)
	camera.sync_rotation_from_transform()
	camera.apply_look_delta(Vector2(10.0, -10.0))

	_assert_true(is_equal_approx(camera.rotation.y, 0.48), "Look delta must update yaw from the synchronized transform.")
	_assert_true(is_equal_approx(camera.rotation.x, 0.27), "Look delta must update pitch from the synchronized transform.")

	camera.queue_free()
	await process_frame


func _test_pitch_clamping() -> void:
	var camera := NO_CLIP_CAMERA.new() as NoClipCameraController
	root.add_child(camera)
	await process_frame

	camera.apply_look_delta(Vector2(0.0, 1000000.0))
	_assert_true(
		is_equal_approx(camera.rotation.x, deg_to_rad(-89.9)),
		"Look input must clamp pitch at the documented lower limit."
	)

	camera.queue_free()
	await process_frame


func _test_forward_movement_contract() -> void:
	var added_action := false
	if not InputMap.has_action("move_forward"):
		InputMap.add_action("move_forward")
		added_action = true

	var camera := NO_CLIP_CAMERA.new() as NoClipCameraController
	camera.move_speed = 3.0
	root.add_child(camera)
	await process_frame

	Input.action_press("move_forward")
	camera._process(1.0)
	Input.action_release("move_forward")

	_assert_true(
		camera.global_position.is_equal_approx(Vector3(0.0, 0.0, -3.0)),
		"Forward input must move the camera along its local negative Z axis at move_speed."
	)

	camera.queue_free()
	await process_frame

	if added_action:
		InputMap.erase_action("move_forward")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
