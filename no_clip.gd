class_name NoClipCameraController
extends Camera3D

## Provides free-flying camera movement without collision constraints.
##
## Hold the right mouse button to capture the mouse and rotate the camera.
## Movement requires the following actions in the Input Map:
## - [code]move_forward[/code]
## - [code]move_backward[/code]
## - [code]move_left[/code]
## - [code]move_right[/code]
## - [code]move_up[/code]
## - [code]move_down[/code]
## - [code]move_fast[/code]


# [b]Movement Configuration[/b] Controls the camera's translation speed.

## The camera's normal movement speed in world units per second.
@export_range(0.0, 1000.0, 0.1, "or_greater")
var move_speed: float = 10.0

## The movement-speed multiplier applied while [code]move_fast[/code] is held.
@export_range(1.0, 100.0, 0.1, "or_greater")
var sprint_multiplier: float = 4.0


# [b]Look Configuration[/b] Controls mouse-driven camera rotation.

## The amount of camera rotation applied per pixel of mouse movement.
@export_range(0.0001, 0.02, 0.0001, "or_greater")
var mouse_sensitivity: float = 0.002


# [b]Rotation State[/b] Stores the camera's current Euler rotation components.

const MINIMUM_PITCH := deg_to_rad(-89.9)
const MAXIMUM_PITCH := deg_to_rad(89.9)

var _pitch: float = 0.0
var _yaw: float = 0.0


# [b]Lifecycle[/b] Initializes the controller from the camera's current rotation.

func _ready() -> void:
	_pitch = rotation.x
	_yaw = rotation.y


# [b]Input Handling[/b] Captures the mouse and applies camera rotation.

func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		_set_mouse_captured(event.pressed)

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		_update_look(event.relative)


# [b]Movement[/b] Moves the camera along its local basis axes.

func _process(delta: float) -> void:
	var direction := _get_movement_direction()

	if direction.is_zero_approx():
		return

	var speed := move_speed

	if Input.is_action_pressed("move_fast"):
		speed *= sprint_multiplier

	global_position += direction.normalized() * speed * delta


# [b]Mouse Capture[/b] Updates the operating system's mouse mode.

func _set_mouse_captured(is_captured: bool) -> void:
	if is_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# [b]Camera Look[/b] Converts relative mouse movement into yaw and pitch rotation.

func _update_look(relative_motion: Vector2) -> void:
	_yaw -= relative_motion.x * mouse_sensitivity
	_pitch -= relative_motion.y * mouse_sensitivity
	_pitch = clampf(_pitch, MINIMUM_PITCH, MAXIMUM_PITCH)

	rotation = Vector3(_pitch, _yaw, 0.0)


# [b]Movement Input[/b] Combines configured input actions into a local direction.

func _get_movement_direction() -> Vector3:
	var direction := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z

	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z

	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x

	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	if Input.is_action_pressed("move_up"):
		direction += transform.basis.y

	if Input.is_action_pressed("move_down"):
		direction -= transform.basis.y

	return direction
