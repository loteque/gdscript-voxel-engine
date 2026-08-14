extends "res://demo/experiments/RuntimeExperimentShell.gd"

## Makes experiment startup observable before loading runtime fixture resources.

const UI_SCRIPT := preload("res://demo/experiments/RuntimeWorkloadExperimentUI.gd")


func _ready() -> void:
	var startup_ui := UI_SCRIPT.new() as RuntimeWorkloadExperimentUI
	add_child(startup_ui)
	startup_ui.configure(TITLE, "Initializing runtime workload experiment…", MODE_LABELS, MODE_DESCRIPTIONS)
	startup_ui.set_ready("Startup 1/3: UI ready. Loading streaming fixture manifest…")
	await get_tree().process_frame

	_manifest = ResourceLoader.load(MANIFEST_PATH) as TerrainChunkManifest
	startup_ui.set_ready("Startup 2/3: Manifest loaded. Loading experiment matrix…")
	await get_tree().process_frame

	_matrix = ResourceLoader.load(MATRIX_PATH) as StreamingExperimentMatrix
	startup_ui.set_ready("Startup 3/3: Validating experiment configuration…")
	await get_tree().process_frame

	startup_ui.queue_free()
	_ui = UI_SCRIPT.new() as RuntimeWorkloadExperimentUI
	add_child(_ui)
	_ui.configure(TITLE, _setup_text(), MODE_LABELS, MODE_DESCRIPTIONS)
	_ui.run_requested.connect(_on_run_requested)
	_ui.stop_requested.connect(func() -> void: _stop_requested = true)
	_ui.export_requested.connect(_export_evidence)

	var validation_error := _validation_error()
	if validation_error.is_empty():
		_ui.set_ready()
	else:
		_failure = validation_error
		_ui.set_complete(0, get_expected_run_count(), false, validation_error)
	_update_results_ui()
