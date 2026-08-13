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

	var streamer_source := FileAccess.get_file_as_string("res://voxel/chunking/ChunkStreamer.gd")
	for field_name in [
		"desired_usec",
		"queued_usec",
		"started_usec",
		"first_status_poll_usec",
		"completion_observed_usec",
		"resource_get_started_usec",
		"resident_commit_usec",
		"desired_to_queued_msec",
		"request_to_first_poll_msec",
		"first_poll_to_completion_msec",
		"total_desired_to_resident_msec",
		"queued_state",
		"started_state",
		"completion_observed_state",
		"resident_state",
	]:
		_assert_true(field_name in streamer_source, "Lifecycle trace exposes %s." % field_name)

	var demo_source := FileAccess.get_file_as_string("res://demo/ChunkStreamingValidationDemo.gd")
	_assert_true("get_completed_load_observations" in demo_source, "Streaming matrix exports production lifecycle observations.")
	var timing_doc_source := FileAccess.get_file_as_string("res://docs/performance/chunk-streamer-lifecycle-timing-experiment.md")
	_assert_true("# ChunkStreamer Lifecycle Timing Experiment" in timing_doc_source, "Lifecycle experiment rationale is documented.")
	_assert_true("ResourceLoader does not expose the exact instant" in timing_doc_source, "Polling-boundary limitation is documented.")
	var trace_doc_source := FileAccess.get_file_as_string("res://docs/performance/chunk-streamer-request-lifecycle-trace.md")
	_assert_true("# ChunkStreamer Request Lifecycle Trace" in trace_doc_source, "Expanded request trace is documented.")
	_assert_true("The state snapshots are observational" in trace_doc_source, "Trace documentation explains why no completed-resource holding queue is added.")

	if not _failed:
		print("ChunkStreamer lifecycle timing contract test passed.")
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
