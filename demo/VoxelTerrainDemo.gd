@tool
extends Node3D

## Initializes and coordinates the primary nodes in the voxel terrain scene.
##
## This node discovers its child [PointFieldVisualizer], [SurfaceNetsMeshDisplay],
## [PointFieldRuntimeUI], and [NoClipCameraController] instances. It assigns
## shared references without taking ownership of field generation, rendering,
## camera movement, or runtime interface behavior.


# [b]Scene References[/b] Identifies the child systems coordinated by this node.

## The visualizer that owns the active point-field reference.
@export var point_field_visualizer: PointFieldVisualizer:
	set(value):
		point_field_visualizer = value
		_queue_initialization()

## The Surface Nets mesh consumer displaying the active field.
@export var surface_nets_display: SurfaceNetsMeshDisplay:
	set(value):
		if surface_nets_display == value:
			return
		surface_nets_display = value
		_queue_initialization()

## The runtime interface used to edit the active visualizer and mesh display.
@export var point_field_runtime_ui: PointFieldRuntimeUI:
	set(value):
		point_field_runtime_ui = value
		_queue_initialization()

## The free-flying camera used to inspect the field.
@export var camera_controller: NoClipCameraController:
	set(value):
		camera_controller = value
		_queue_initialization()


# [b]Initialization Settings[/b] Controls automatic scene setup.

## Searches descendants for missing scene references.
@export var discover_child_nodes: bool = true:
	set(value):
		discover_child_nodes = value
		_queue_initialization()

## Creates a point-field resource when the visualizer has no assigned field.
@export var create_missing_field: bool = true:
	set(value):
		create_missing_field = value
		_queue_initialization()

## Creates the Surface Nets mesh display at runtime when the scene lacks one.
@export var create_missing_surface_nets_display: bool = true:
	set(value):
		create_missing_surface_nets_display = value
		_queue_initialization()

## Regenerates the field when its generated channels are invalid.
@export var regenerate_invalid_field: bool = true:
	set(value):
		regenerate_invalid_field = value
		_queue_initialization()


# [b]Initialization State[/b] Prevents redundant deferred setup requests.

var _initialization_queued: bool = false


# [b]Lifecycle[/b] Initializes scene dependencies in the editor and at runtime.

func _enter_tree() -> void:
	_queue_initialization()


func _ready() -> void:
	initialize_children()


# [b]Scene Initialization[/b] Discovers children and connects their shared dependencies.

## Initializes all supported child systems beneath this node.
func initialize_children() -> void:
	_initialization_queued = false

	if discover_child_nodes:
		_discover_children()

	_initialize_visualizer()
	_initialize_surface_nets_display()
	_initialize_runtime_ui()
	_initialize_camera_controller()


func _queue_initialization() -> void:
	if not is_inside_tree() or _initialization_queued:
		return

	_initialization_queued = true
	call_deferred("initialize_children")


# [b]Child Discovery[/b] Finds missing references by their registered class types.

func _discover_children() -> void:
	if point_field_visualizer == null:
		point_field_visualizer = _find_descendant_by_type(
			self,
			PointFieldVisualizer
		) as PointFieldVisualizer

	if surface_nets_display == null:
		var discovered_surface_nets_display := _find_descendant_by_type(
			self,
			SurfaceNetsMeshDisplay
		) as SurfaceNetsMeshDisplay
		if discovered_surface_nets_display != null:
			surface_nets_display = discovered_surface_nets_display

	if point_field_runtime_ui == null:
		point_field_runtime_ui = _find_descendant_by_type(
			self,
			PointFieldRuntimeUI
		) as PointFieldRuntimeUI

	if camera_controller == null:
		camera_controller = _find_descendant_by_type(
			self,
			NoClipCameraController
		) as NoClipCameraController


func _find_descendant_by_type(root: Node, script_type: Variant) -> Node:
	for child in root.get_children():
		if is_instance_of(child, script_type):
			return child

		var match := _find_descendant_by_type(child, script_type)
		if match != null:
			return match

	return null


# [b]Visualizer Initialization[/b] Ensures the renderer has authoritative field data.

func _initialize_visualizer() -> void:
	if point_field_visualizer == null:
		return

	if create_missing_field and point_field_visualizer.field == null:
		point_field_visualizer.field = PointFieldResource.new()

	var field := point_field_visualizer.field
	if (
		regenerate_invalid_field
		and field != null
		and not field.validate_data()
	):
		field.regenerate()


# [b]Surface Nets Initialization[/b] Creates and configures the independent mesh consumer.

func _initialize_surface_nets_display() -> void:
	if (
		surface_nets_display == null
		and create_missing_surface_nets_display
		and not Engine.is_editor_hint()
	):
		surface_nets_display = SurfaceNetsMeshDisplay.new()
		surface_nets_display.name = "SurfaceNetsMeshDisplay"
		add_child(surface_nets_display)

	if surface_nets_display == null or point_field_visualizer == null:
		return

	surface_nets_display.field = point_field_visualizer.field
	surface_nets_display.iso_level = point_field_visualizer.iso_level


# [b]Runtime UI Initialization[/b] Forwards active rendering targets to the interface.

func _initialize_runtime_ui() -> void:
	if point_field_runtime_ui == null:
		return

	point_field_runtime_ui.set_visualizer(point_field_visualizer)
	point_field_runtime_ui.set_surface_nets_display(surface_nets_display)


# [b]Camera Initialization[/b] Activates the configured inspection camera.

func _initialize_camera_controller() -> void:
	if camera_controller == null or Engine.is_editor_hint():
		return

	camera_controller.current = true
