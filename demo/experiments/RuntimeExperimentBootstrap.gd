extends "res://demo/experiments/RuntimeExperimentShell.gd"

## Isolates whether loading the experiment matrix blocks mobile Web startup.
##
## UI configuration and manifest loading have already been proven healthy. This
## probe performs those known-good steps and then loads the matrix separately.

const UI_SCRIPT := preload("res://demo/experiments/RuntimeWorkloadExperimentUI.gd")

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	var startup_ui := UI_SCRIPT.new() as RuntimeWorkloadExperimentUI
	add_child(startup_ui)
	startup_ui.configure(
		"Runtime Workload Isolation",
		"Experiment matrix resource-load probe.",
		["Mode A", "Mode B", "Mode C", "Mode D"],
		[
			"Matrix probe description A.",
			"Matrix probe description B.",
			"Matrix probe description C.",
			"Matrix probe description D.",
		]
	)

	_probe_label.text = "Loading known-good streaming manifest…"
	await get_tree().process_frame
	var manifest := ResourceLoader.load(MANIFEST_PATH) as TerrainChunkManifest
	if manifest == null:
		_probe_label.text = "Manifest unexpectedly returned null."
		return

	_probe_label.text = "Manifest loaded. Loading mobile_web_warm_matrix.tres…"
	await get_tree().process_frame
	var matrix := ResourceLoader.load(MATRIX_PATH) as StreamingExperimentMatrix
	if matrix == null:
		_probe_label.text = "Experiment matrix load returned null."
		return

	_probe_label.text = (
		"Experiment matrix load confirmed\n\n"
		+ "Both startup resources loaded successfully on mobile Web.\n\n"
		+ "The remaining original startup boundary is validation, signal wiring, and ready-state initialization."
	)
