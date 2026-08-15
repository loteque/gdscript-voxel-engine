extends "res://demo/experiments/RuntimeExperimentShell.gd"

## Isolates whether creating the runtime experiment UI prevents Web startup.

const UI_SCRIPT := preload("res://demo/experiments/RuntimeWorkloadExperimentUI.gd")

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	_probe_label.text = "Shell inheritance reached _ready(). Instantiating runtime UI…"
	await get_tree().process_frame

	var startup_ui := UI_SCRIPT.new() as RuntimeWorkloadExperimentUI
	_probe_label.text = "Runtime UI instantiated. Adding it to the scene tree…"
	await get_tree().process_frame

	add_child(startup_ui)
	_probe_label.text = (
		"Runtime UI instantiation confirmed\n\n"
		+ "RuntimeWorkloadExperimentUI.new() and add_child() both succeeded.\n\n"
		+ "The next suspect is RuntimeWorkloadExperimentUI.configure() / _build()."
	)
