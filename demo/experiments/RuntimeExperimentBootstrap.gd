extends "res://demo/experiments/RuntimeExperimentShell.gd"

## Isolates whether inheriting RuntimeExperimentShell prevents Web startup.
##
## The parent script and its transitive dependencies have already been proven to
## preload successfully in the Web export. This probe adds inheritance without
## restoring the experiment UI or resource-loading startup path.

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	_probe_label.text = (
		"GDScript startup confirmed with shell inheritance\n\n"
		+ "RuntimeExperimentBootstrap inherited RuntimeExperimentShell.gd and reached _ready().\n\n"
		+ "If this message appears, inheritance is healthy and the failure is inside the original bootstrap _ready() body."
	)
