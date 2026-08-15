extends "res://demo/experiments/RuntimeExperimentShell.gd"

## Isolates whether loading the streaming manifest blocks mobile Web startup.
##
## UI construction/configuration has already been proven healthy. This probe
## loads only the manifest and deliberately does not load the experiment matrix.

const UI_SCRIPT := preload("res://demo/experiments/RuntimeWorkloadExperimentUI.gd")

@onready var _probe_label: Label = $StartupProbe/Panel/Margin/Label


func _ready() -> void:
	var startup_ui := UI_SCRIPT.new() as RuntimeWorkloadExperimentUI
	add_child(startup_ui)
	startup_ui.configure(
		"Runtime Workload Isolation",
		"Manifest resource-load probe. The experiment matrix is not loaded.",
		["Mode A", "Mode B", "Mode C", "Mode D"],
		[
			"Manifest probe description A.",
			"Manifest probe description B.",
			"Manifest probe description C.",
			"Manifest probe description D.",
		]
	)

	_probe_label.text = "UI configured. Loading StreamingDemoManifest.tres…"
	await get_tree().process_frame

	var manifest := ResourceLoader.load(MANIFEST_PATH) as TerrainChunkManifest
	if manifest == null:
		_probe_label.text = "Manifest load returned null."
		return

	_probe_label.text = (
		"Streaming manifest load confirmed\n\n"
		+ "ResourceLoader.load(StreamingDemoManifest.tres) returned successfully.\n\n"
		+ "The experiment matrix has not been loaded by this probe."
	)
