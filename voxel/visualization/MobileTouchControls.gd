class_name MobileTouchControls
extends Control

## Provides touch-first controls for the runtime free-fly camera.
##
## Movement buttons drive the existing Input Map actions so touch, keyboard,
## and future input devices share the same movement contract. Touch look is
## forwarded to the active [NoClipCameraController] through its public API.


# [b]Touch Configuration[/b]
# Controls automatic visibility and touch-look sensitivity.

## Hides the controls when the active display does not report touch support.
@export var show_on_touchscreen_only: bool = true

## Scales touch drag distance before applying camera look.
@export_range(0.1, 4.0, 0.05, "or_greater")
var look_sensitivity_scale: float = 1.0


# [b]Touch State[/b]
# Tracks the finger currently assigned to camera look.

var _look_touch_index: int = -1

@onready var _look_area: Control = %LookArea
@onready var _forward_button: Button = %ForwardButton
@onready var _backward_button: Button = %BackwardButton
@onready var _left_button: Button = %LeftButton
@onready var _right_button: Button = %RightButton
@onready var _up_button: Button = %UpButton
@onready var _down_button: Button = %DownButton
@onready var _fast_button: Button = %FastButton


# [b]Lifecycle[/b]
# Configures visibility and connects touch controls to the shared input actions.

func _ready() -> void:
	if show_on_touchscreen_only:
		visible = _is_touch_input_available()

	_bind_action(_forward_button, &"move_forward")
	_bind_action(_backward_button, &"move_backward")
	_bind_action(_left_button, &"move_left")
	_bind_action(_right_button, &"move_right")
	_bind_action(_up_button, &"move_up")
	_bind_action(_down_button, &"move_down")
	_bind_action(_fast_button, &"move_fast")
	_look_area.gui_input.connect(_on_look_area_gui_input)


func _exit_tree() -> void:
	_release_movement_actions()
	_look_touch_index = -1


func _is_touch_input_available() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if not OS.has_feature("web"):
		return false

	# Some mobile browsers do not surface Godot's touchscreen capability during
	# startup even though the browser itself reports touch input. Use the browser
	# as a Web-only fallback so desktop/native behavior remains unchanged.
	var browser_touch := JavaScriptBridge.eval(
		"navigator.maxTouchPoints > 0 || window.matchMedia('(pointer: coarse)').matches"
	)
	return browser_touch is bool and browser_touch


# [b]Action Binding[/b]
# Translates UI button state into the project's existing Input Map actions.

func _bind_action(button: Button, action: StringName) -> void:
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))


func _press_action(action: StringName) -> void:
	Input.action_press(action)


func _release_action(action: StringName) -> void:
	Input.action_release(action)


func _release_movement_actions() -> void:
	for action: StringName in [
		&"move_forward",
		&"move_backward",
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down",
		&"move_fast",
	]:
		Input.action_release(action)


# [b]Touch Look[/b]
# Reserves one finger in the look region and forwards drag motion to the camera.

func _on_look_area_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_look_touch(event)
	elif event is InputEventScreenDrag:
		_handle_look_drag(event)


func _handle_look_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _look_touch_index == -1:
			_look_touch_index = event.index
			accept_event()
		return

	if event.index == _look_touch_index:
		_look_touch_index = -1
		accept_event()


func _handle_look_drag(event: InputEventScreenDrag) -> void:
	if event.index != _look_touch_index:
		return

	var camera := get_viewport().get_camera_3d() as NoClipCameraController
	if camera == null:
		return

	camera.apply_look_delta(event.screen_relative * look_sensitivity_scale)
	accept_event()
