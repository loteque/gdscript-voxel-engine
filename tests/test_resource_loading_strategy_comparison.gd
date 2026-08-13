extends SceneTree

var _failed := false

func _initialize() -> void:
	var scene := load("res://demo/experiments/ResourceLoadingStrategyComparison.tscn") as PackedScene
	_expect(scene != null, "Strategy comparison scene loads.")
	var source := FileAccess.get_file_as_string("res://demo/experiments/ResourceLoadingStrategyComparison.gd")
	_expect("CACHE_MODE_IGNORE" in source, "Comparison bypasses resource-under-test cache.")
	_expect("terrain_sync" in source and "terrain_threaded" in source, "Comparison covers terrain sync and threaded paths.")
	_expect("control_sync" in source and "control_threaded" in source, "Comparison covers trivial control sync and threaded paths.")
	_expect("THREADED_CONCURRENCY_VALUES: Array[int] = [1, 4]" in source, "Threaded comparison uses controlled concurrency 1 and 4.")
	var docs := FileAccess.get_file_as_string("res://docs/performance/mobile-resource-loading-strategy-comparison.md")
	_expect("# Mobile Resource-Loading Strategy Comparison" in docs, "Comparison rationale is documented.")
	if not _failed: print("Resource loading strategy comparison contract test passed.")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)
