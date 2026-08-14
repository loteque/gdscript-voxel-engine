extends Node3D

## Isolates whether the runtime experiment shell dependency graph can load on Web.

const SHELL_SCRIPT := preload("res://demo/experiments/RuntimeExperimentShell.gd")

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	_probe_label.text = (
		"GDScript startup confirmed with shell preload\n\n"
		+ "RuntimeExperimentShell.gd and its transitive parse-time dependencies loaded.\n\n"
		+ "If this message appears, the failure is narrower than shell parsing and we can move to inheritance/bootstrap wiring."
	)
