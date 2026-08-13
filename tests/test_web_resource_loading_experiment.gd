extends SceneTree

const SCENE_PATH := "res://demo/experiments/WebResourceLoadingExperiment.tscn"
const SCRIPT_PATH := "res://demo/experiments/WebResourceLoadingExperiment.gd"
const DOC_PATH := "res://docs/performance/web-resource-loading-microbenchmark.md"

var _failures: Array[String] = []


func _initialize() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	_expect(scene != null, "Web resource-loading experiment scene loads.")
	if scene != null:
		var instance := scene.instantiate()
		_expect(instance != null, "Web resource-loading experiment scene instantiates.")
		if instance != null:
			_expect(instance.get_script() != null, "Experiment scene uses its validation-only runner script.")
			_expect(instance.get_node_or_null("ChunkStreamer") == null, "Microbenchmark scene does not contain a ChunkStreamer node.")
			_expect(_tree_contains_type(instance, "MeshInstance3D") == false, "Microbenchmark scene does not contain MeshInstance3D nodes.")
			instance.free()

	var script_text := FileAccess.get_file_as_string(SCRIPT_PATH)
	_expect(not script_text.is_empty(), "Experiment runner source is readable.")
	_expect("ResourceLoader.load_threaded_request" in script_text, "Experiment exercises threaded ResourceLoader.")
	_expect("CONCURRENCY_VALUES: Array[int] = [1, 2, 4, 8]" in script_text, "Experiment preserves the controlled concurrency sweep.")
	_expect("REPETITIONS := 3" in script_text, "Experiment preserves three repetitions per concurrency value.")

	var doc_text := FileAccess.get_file_as_string(DOC_PATH)
	_expect("# Web Resource-Loading Microbenchmark" in doc_text, "Experiment rationale and interpretation are documented.")
	_expect("Why browser-headless" in doc_text, "Documentation explains why native headless is insufficient.")

	if _failures.is_empty():
		print("Web resource-loading microbenchmark contract test passed.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _tree_contains_type(node: Node, class_name: String) -> bool:
	if node.is_class(class_name):
		return true
	for child in node.get_children():
		if child is Node and _tree_contains_type(child, class_name):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
