@tool
class_name PointFieldRuntimeUI
extends CanvasLayer

## Hosts the runtime point-field controls and exposes their visualization targets.
##
## Assign [member visualizer] and [member surface_nets_display] on this node when
## instancing the runtime UI. The values are forwarded to the child
## [SurfaceNetsRuntimePanel] when the panel is ready.


# [b]Targets[/b] Exposes the point and mesh displays controlled by the nested panel.

## The point-field visualizer edited by the runtime panel.
@export var visualizer: PointFieldVisualizer:
	get:
		return _visualizer
	set(value):
		set_visualizer(value)

## The Surface Nets mesh display edited by the runtime panel.
@export var surface_nets_display: SurfaceNetsMeshDisplay:
	get:
		return _surface_nets_display
	set(value):
		set_surface_nets_display(value)


# [b]Target State[/b] Retains assignments made before child nodes are ready.

var _visualizer: PointFieldVisualizer
var _surface_nets_display: SurfaceNetsMeshDisplay


# [b]Node References[/b] Locates the nested runtime panel.

@onready var _runtime_panel: SurfaceNetsRuntimePanel = %PointFieldRuntimePanel


# [b]Lifecycle[/b] Applies retained references after the child panel is ready.

func _ready() -> void:
	_apply_targets()


# [b]Target Forwarding[/b] Keeps the panel synchronized with exposed targets.

## Changes the visualizer edited by this runtime interface.
func set_visualizer(value: PointFieldVisualizer) -> void:
	_visualizer = value
	_apply_targets()


## Changes the Surface Nets mesh display edited by this runtime interface.
func set_surface_nets_display(value: SurfaceNetsMeshDisplay) -> void:
	_surface_nets_display = value
	_apply_targets()


func _apply_targets() -> void:
	if not is_node_ready() or _runtime_panel == null:
		return

	_runtime_panel.set_visualizer(_visualizer)
	_runtime_panel.surface_nets_display = _surface_nets_display
