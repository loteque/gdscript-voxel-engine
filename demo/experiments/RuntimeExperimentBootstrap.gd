extends "res://demo/experiments/RuntimeExperimentShell.gd"

## Isolates whether RuntimeWorkloadExperimentUI.configure() prevents Web startup.

const UI_SCRIPT := preload("res://demo/experiments/RuntimeWorkloadExperimentUI.gd")

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	var startup_ui := UI_SCRIPT.new() as RuntimeWorkloadExperimentUI
	add_child(startup_ui)

	_probe_label.text = "Runtime UI added. Calling configure()…"
	await get_tree().process_frame

	startup_ui.configure(
		"Runtime Workload Isolation",
		"UI configure probe only. No manifest or matrix resources are loaded.",
		["Mode A", "Mode B", "Mode C", "Mode D"],
		[
			"Configure probe description A.",
			"Configure probe description B.",
			"Configure probe description C.",
			"Configure probe description D.",
		]
	)

	_probe_label.text = (
		"Runtime UI configure confirmed\n\n"
		+ "RuntimeWorkloadExperimentUI.configure() and _build() returned successfully.\n\n"
		+ "No experiment resources were loaded by this probe."
	)
