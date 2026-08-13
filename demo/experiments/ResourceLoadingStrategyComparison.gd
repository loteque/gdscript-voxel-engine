extends Node

## Compares synchronous/threaded loading for real terrain assets and trivial controls.

const MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const CONTROL_DIR := "res://demo/generated/resource_loader_controls"
const SAMPLE_COUNT := 24
const REPETITIONS := 3
const THREADED_CONCURRENCY_VALUES: Array[int] = [1, 4]
const LOAD_TIMEOUT_MSEC := 120000

var _results: Array[Dictionary] = []
var _failed := false
var _failure_message := ""
var _started_usec := 0


func _ready() -> void:
	_started_usec = Time.get_ticks_usec()
	call_deferred("_run")


func _run() -> void:
	var manifest := ResourceLoader.load(MANIFEST_PATH) as TerrainChunkManifest
	if manifest == null or not manifest.is_valid():
		_fail("Valid streaming manifest unavailable.")
		_finish()
		return
	var terrain_paths := _select_terrain_paths(manifest)
	var control_paths := _control_paths()
	if terrain_paths.size() != SAMPLE_COUNT or control_paths.size() != SAMPLE_COUNT:
		_fail("Expected %d terrain and control resources." % SAMPLE_COUNT)
		_finish()
		return

	for repetition in range(1, REPETITIONS + 1):
		_results.append(await _run_sync_batch(terrain_paths, "terrain_sync", repetition))
		_results.append(await _run_sync_batch(control_paths, "control_sync", repetition))
		for concurrency in THREADED_CONCURRENCY_VALUES:
			_results.append(await _run_threaded_batch(terrain_paths, "terrain_threaded", concurrency, repetition))
			_results.append(await _run_threaded_batch(control_paths, "control_threaded", concurrency, repetition))
		if _results.any(func(result: Dictionary) -> bool: return not result.get("success", false)):
			_fail("One or more strategy runs failed.")
			break
	_finish()


func _select_terrain_paths(manifest: TerrainChunkManifest) -> Array[String]:
	var entries: Array[TerrainChunkManifestEntry] = []
	for entry in manifest.entries:
		if entry != null and entry.lod_level == 0 and not entry.asset_path.is_empty():
			entries.append(entry)
	entries.sort_custom(func(a: TerrainChunkManifestEntry, b: TerrainChunkManifestEntry) -> bool:
		if a.chunk_coordinate.x != b.chunk_coordinate.x: return a.chunk_coordinate.x < b.chunk_coordinate.x
		if a.chunk_coordinate.y != b.chunk_coordinate.y: return a.chunk_coordinate.y < b.chunk_coordinate.y
		return a.chunk_coordinate.z < b.chunk_coordinate.z
	)
	var paths: Array[String] = []
	for index in mini(SAMPLE_COUNT, entries.size()):
		paths.append(entries[index].asset_path)
	return paths


func _control_paths() -> Array[String]:
	var paths: Array[String] = []
	for index in SAMPLE_COUNT:
		paths.append("%s/control_%02d.tres" % [CONTROL_DIR, index])
	return paths


func _run_sync_batch(paths: Array[String], strategy: String, repetition: int) -> Dictionary:
	var started_usec := Time.get_ticks_usec()
	var observations: Array[Dictionary] = []
	for path in paths:
		var load_started_usec := Time.get_ticks_usec()
		var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var elapsed_msec := float(Time.get_ticks_usec() - load_started_usec) / 1000.0
		if resource == null:
			return _failed_result(strategy, 1, repetition, started_usec, "Synchronous load failed for %s." % path)
		observations.append({"path": path, "latency_msec": elapsed_msec})
		await get_tree().process_frame
	return _complete_result(strategy, 1, repetition, started_usec, observations, 1)


func _run_threaded_batch(paths: Array[String], strategy: String, concurrency: int, repetition: int) -> Dictionary:
	var started_usec := Time.get_ticks_usec()
	var next_index := 0
	var active: Dictionary = {}
	var observations: Array[Dictionary] = []
	var peak_active := 0
	while next_index < paths.size() or not active.is_empty():
		while next_index < paths.size() and active.size() < concurrency:
			var path := paths[next_index]
			var error := ResourceLoader.load_threaded_request(path, "", false, ResourceLoader.CACHE_MODE_IGNORE)
			if error != OK:
				return _failed_result(strategy, concurrency, repetition, started_usec, "Threaded request failed for %s: %s" % [path, error_string(error)])
			active[path] = Time.get_ticks_usec()
			next_index += 1
			peak_active = maxi(peak_active, active.size())
		var completed: Array[String] = []
		for path: String in active.keys():
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var resource := ResourceLoader.load_threaded_get(path)
				if resource == null:
					return _failed_result(strategy, concurrency, repetition, started_usec, "Threaded get returned null for %s." % path)
				observations.append({"path": path, "latency_msec": float(Time.get_ticks_usec() - int(active[path])) / 1000.0})
				completed.append(path)
			elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				return _failed_result(strategy, concurrency, repetition, started_usec, "Threaded load failed for %s." % path)
			elif Time.get_ticks_usec() - int(active[path]) > LOAD_TIMEOUT_MSEC * 1000:
				return _failed_result(strategy, concurrency, repetition, started_usec, "Threaded load timed out for %s." % path)
		for path in completed:
			active.erase(path)
		await get_tree().process_frame
	return _complete_result(strategy, concurrency, repetition, started_usec, observations, peak_active)


func _complete_result(strategy: String, concurrency: int, repetition: int, started_usec: int, observations: Array[Dictionary], peak_active: int) -> Dictionary:
	var duration_msec := float(Time.get_ticks_usec() - started_usec) / 1000.0
	var total_latency := 0.0
	var maximum_latency := 0.0
	for observation in observations:
		var latency := float(observation["latency_msec"])
		total_latency += latency
		maximum_latency = maxf(maximum_latency, latency)
	return {
		"strategy": strategy,
		"concurrency": concurrency,
		"repetition": repetition,
		"asset_count": observations.size(),
		"duration_msec": duration_msec,
		"throughput_assets_per_second": float(observations.size()) * 1000.0 / maxf(duration_msec, 0.001),
		"average_latency_msec": total_latency / maxf(float(observations.size()), 1.0),
		"maximum_latency_msec": maximum_latency,
		"peak_active": peak_active,
		"observations": observations,
		"success": true,
		"failure": "",
	}


func _failed_result(strategy: String, concurrency: int, repetition: int, started_usec: int, message: String) -> Dictionary:
	return {"strategy": strategy, "concurrency": concurrency, "repetition": repetition, "duration_msec": float(Time.get_ticks_usec() - started_usec) / 1000.0, "success": false, "failure": message}


func _finish() -> void:
	var payload := {
		"schema_version": 1,
		"experiment": "mobile-resource-loading-strategy-comparison",
		"configuration": {
			"sample_count": SAMPLE_COUNT,
			"repetitions": REPETITIONS,
			"threaded_concurrency_values": THREADED_CONCURRENCY_VALUES,
			"cache_mode": "CACHE_MODE_IGNORE for resource under test",
			"sync_yield_policy": "one process frame between synchronous loads",
		},
		"environment": {
			"godot_version": str(Engine.get_version_info().get("string", "unknown")),
			"os_name": OS.get_name(),
			"display_server": DisplayServer.get_name(),
			"processor_count": OS.get_processor_count(),
			"user_agent": str(JavaScriptBridge.eval("navigator.userAgent", true)) if OS.has_feature("web") else "n/a",
		},
		"measured": {"total_duration_msec": float(Time.get_ticks_usec() - _started_usec) / 1000.0, "runs": _results},
		"limitations": [
			"CACHE_MODE_IGNORE bypasses the resource-under-test cache, while external dependencies may still reuse Godot cache state.",
			"Threaded completion is observed once per Godot process frame.",
			"Synchronous loads yield one frame between assets, but each ResourceLoader.load call itself executes synchronously on the main thread.",
			"The trivial control resources have no mesh dependency and are intended to isolate generic resource-format and threaded scheduling overhead.",
		],
		"success": not _failed,
		"failure": _failure_message,
	}
	var json := JSON.stringify(payload)
	print("RESOURCE_LOADING_STRATEGY_COMPARISON_JSON=" + json)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__voxelResourceLoadingStrategyComparison = %s;" % json)
	get_tree().quit(1 if _failed else 0)


func _fail(message: String) -> void:
	_failed = true
	_failure_message = message
	push_error(message)
