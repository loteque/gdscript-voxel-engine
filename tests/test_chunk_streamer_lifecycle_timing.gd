extends SceneTree

const CHUNK_STREAMER := preload("res://voxel/chunking/ChunkStreamer.gd")

var _failed := false


func _initialize() -> void:
	var streamer := CHUNK_STREAMER.new()
	var metrics := streamer.get_streaming_metrics()
	_assert_true(metrics.has("average_queue_wait_msec"), "Streaming metrics expose queue-wait timing.")
	_assert_true(metrics.has("average_loader_wait_msec"), "Streaming metrics expose loader-wait timing.")
	_assert_true(metrics.has("average_resource_get_msec"), "Streaming metrics expose resource-get timing.")
	_assert_true(metrics.has("average_asset_validation_msec"), "Streaming metrics expose asset-validation timing.")
	_assert_true(metrics.has("average_instance_setup_msec"), "Streaming metrics expose instance-setup timing.")
	_assert_true(metrics.has("average_scene_attach_msec"), "Streaming metrics expose scene-attach timing.")
	_assert_true(metrics.has("average_resident_commit_msec"), "Streaming metrics expose resident-commit timing.")
	_assert_true(metrics.has("in_progress_poll_count"), "Streaming metrics expose polling cadence observations.")
	_assert_true(streamer.get_completed_load_observations().is_empty(), "Lifecycle observations begin empty.")
	streamer.free()

	var demo_source := FileAccess.get_file_as_string("res://demo/ChunkStreamingValidationDemo.gd")
	_assert_true("get_completed_load_observations" in demo_source, "Streaming matrix exports production lifecycle observations.")
	var doc_source := FileAccess.get_file_as_string("res://docs/performance/chunk-streamer-lifecycle-timing-experiment.md")
	_assert_true("# ChunkStreamer Lifecycle Timing Experiment" in doc_source, "Lifecycle experiment rationale is documented.")
	_assert_true("ResourceLoader does not expose the exact instant" in doc_source, "Polling-boundary limitation is documented.")

	if not _failed:
		print("ChunkStreamer lifecycle timing contract test passed.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
