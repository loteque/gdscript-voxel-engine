@tool
class_name PointFieldRuntimeUI
extends CanvasLayer

## Hosts the runtime point-field controls and exposes their target visualizer.
##
## Assign [member visualizer] on this node when instancing the runtime UI. The
## value is forwarded to the child [PointFieldRuntimePanel] when the panel is
## ready.


# [b]Target[/b] Exposes the visualizer controlled by the nested runtime panel.

## The point-field visualizer edited by the runtime panel.
@export var visualizer: PointFieldVisualizer:
	get:
		return _visualizer
	set(value):
		set_visualizer(value)


# [b]Target State[/b] Retains assignments made before child nodes are ready.

var _visualizer: PointFieldVisualizer


# [b]Node References[/b] Locates the nested runtime panel.

@onready var _runtime_panel: PointFieldRuntimePanel = %PointFieldRuntimePanel


# [b]Lifecycle[/b] Applies retained references after the child panel is ready.

func _ready() -> void:
	_apply_visualizer()


# [b]Target Forwarding[/b] Keeps the panel synchronized with the exposed target.

## Changes the visualizer edited by this runtime interface.
func set_visualizer(value: PointFieldVisualizer) -> void:
	_visualizer = value
	_apply_visualizer()


func _apply_visualizer() -> void:
	if not is_node_ready() or _runtime_panel == null:
		return

	_runtime_panel.set_visualizer(_visualizer)
