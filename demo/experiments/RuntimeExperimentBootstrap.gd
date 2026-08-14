extends Node3D

## Isolates Web startup from the runtime experiment dependency graph.
##
## This probe intentionally references no project classes. If this script reaches
## [method _ready] in the Web export, the authored scene label changes visibly.
## That distinguishes general GDScript startup from experiment-script loading.

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	_probe_label.text = (
		"GDScript startup confirmed\n\n"
		+ "RuntimeExperimentBootstrap._ready() executed successfully.\n\n"
		+ "The remaining failure is inside the runtime experiment dependency graph, "
		+ "not scene loading or general GDScript execution."
	)
