class_name RuntimeWorkloadLoaderControl
extends RefCounted

## Loader-only control used as the endpoint of the runtime workload experiment.
## It consumes the exact asset path sequence observed from the production streamer.

const PATH_TIMEOUT_MSEC := 120000


func run(tree: SceneTree, paths: Array[String]) -> Dictionary:
	var started_usec := Time.get_ticks_usec()
	var observations: Array[Dictionary] = []
	for path in paths:
		var request_started_usec := Time.get_ticks_usec()
		var error := ResourceLoader.load_threaded_request(path)
		if error != OK:
			return _failed(started_usec, "Request failed for %s: %s" % [path, error_string(error)], observations)
		await tree.process_frame
		var first_poll_usec := Time.get_ticks_usec()
		var in_progress_polls := 0
		while true:
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var completion_usec := Time.get_ticks_usec()
				var get_started_usec := Time.get_ticks_usec()
				var resource := ResourceLoader.load_threaded_get(path)
				var get_finished_usec := Time.get_ticks_usec()
				if resource == null:
					return _failed(started_usec, "Loaded resource was null for %s." % path, observations)
				observations.append({
					"path": path,
					"request_to_first_poll_msec": _msec(first_poll_usec - request_started_usec),
					"first_poll_to_completion_msec": _msec(completion_usec - first_poll_usec),
					"loader_wait_msec": _msec(completion_usec - request_started_usec),
					"resource_get_msec": _msec(get_finished_usec - get_started_usec),
					"queue_wait_msec": 0.0,
					"residency_completion_msec": 0.0,
					"in_progress_poll_count": in_progress_polls,
				})
				break
			if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				return _failed(started_usec, "Background load failed for %s." % path, observations)
			in_progress_polls += 1
			if Time.get_ticks_usec() - request_started_usec > PATH_TIMEOUT_MSEC * 1000:
				return _failed(started_usec, "Background load timed out for %s." % path, observations)
			await tree.process_frame
	return _complete(started_usec, observations)


func _complete(started_usec: int, observations: Array[Dictionary]) -> Dictionary:
	var duration_msec := _msec(Time.get_ticks_usec() - started_usec)
	var average_loader_wait := 0.0
	var average_resource_get := 0.0
	var total_polls := 0
	for observation in observations:
		average_loader_wait += float(observation["loader_wait_msec"])
		average_resource_get += float(observation["resource_get_msec"])
		total_polls += int(observation["in_progress_poll_count"])
	var divisor := maxf(float(observations.size()), 1.0)
	return {
		"success": true,
		"failure": "",
		"duration_msec": duration_msec,
		"completed_loads": observations.size(),
		"loads_per_second": float(observations.size()) * 1000.0 / maxf(duration_msec, 0.001),
		"streaming_metrics": {
			"completed_load_count": observations.size(),
			"failed_load_count": 0,
			"average_loader_wait_msec": average_loader_wait / divisor,
			"average_queue_wait_msec": 0.0,
			"average_resource_get_msec": average_resource_get / divisor,
			"average_residency_completion_msec": 0.0,
			"in_progress_poll_count": total_polls,
		},
		"load_observations": observations,
	}


func _failed(started_usec: int, message: String, observations: Array[Dictionary]) -> Dictionary:
	return {
		"success": false,
		"failure": message,
		"duration_msec": _msec(Time.get_ticks_usec() - started_usec),
		"completed_loads": observations.size(),
		"loads_per_second": 0.0,
		"streaming_metrics": {"completed_load_count": observations.size(), "failed_load_count": 1},
		"load_observations": observations,
	}


func _msec(usec: int) -> float:
	return float(usec) / 1000.0
