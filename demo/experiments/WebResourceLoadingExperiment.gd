extends Node

## Browser-headless diagnostic for isolating the Web resource-loading path.
##
## This intentionally bypasses ChunkStreamer residency and MeshInstance3D creation.
## It loads real TerrainChunkAsset paths from the production streaming manifest so
## the experiment retains Web export, virtual-filesystem, ResourceLoader, and
## resource-deserialization behavior while removing terrain traversal from the timing.

const MANIFEST_PATH := "res://demo/generated/StreamingDemoManifest.tres"
const SAMPLE_COUNT := 24
const REPETITIONS := 3
const CONCURRENCY_VALUES: Array[int] = [1, 2, 4, 8]
const LOAD_TIMEOUT_MSEC := 120000

var _results: Array[Dictionary] = []
var _started_usec: int = 0
var _failed := false
var _failure_message := ""


func _ready() -> void:
	_started_usec = Time.get_ticks_usec()
	call_deferred("_run")


func _run() -> void:
	var manifest := load(MANIFEST_PATH) as TerrainChunkManifest
	if manifest == null or not manifest.is_valid():
		_fail("Unable to load a valid production streaming manifest at %s." % MANIFEST_PATH)
		_finish()
		return

	var paths := _select_asset_paths(manifest)
	if paths.is_empty():
		_fail("Production streaming manifest contains no loadable assets.")
		_finish()
		return

	for concurrency in CONCURRENCY_VALUES:
		for repetition in range(1, REPETITIONS + 1):
			var result := await _run_threaded_batch(paths, concurrency, repetition)
			_results.append(result)
			if not result.get("success", false):
				_fail(str(result.get("failure", "Unknown threaded-load failure.")))
				_finish()
				return

	_finish()


func _select_asset_paths(manifest: TerrainChunkManifest) -> Array[String]:
	var entries: Array[TerrainChunkManifestEntry] = []
	for entry in manifest.entries:
		if entry != null and entry.lod_level == 0 and not entry.asset_path.is_empty():
			entries.append(entry)
	entries.sort_custom(func(a: TerrainChunkManifestEntry, b: TerrainChunkManifestEntry) -> bool:
		if a.chunk_coordinate.x != b.chunk_coordinate.x:
			return a.chunk_coordinate.x < b.chunk_coordinate.x
		if a.chunk_coordinate.y != b.chunk_coordinate.y:
			return a.chunk_coordinate.y < b.chunk_coordinate.y
		return a.chunk_coordinate.z < b.chunk_coordinate.z
	)
	var paths: Array[String] = []
	var count := mini(SAMPLE_COUNT, entries.size())
	for index in count:
		paths.append(entries[index].asset_path)
	return paths


func _run_threaded_batch(paths: Array[String], concurrency: int, repetition: int) -> Dictionary:
	var started_usec := Time.get_ticks_usec()
	var next_index := 0
	var active: Dictionary = {}
	var observations: Array[Dictionary] = []
	var peak_active := 0

	while next_index < paths.size() or not active.is_empty():
		while next_index < paths.size() and active.size() < concurrency:
			var path := paths[next_index]
			var request_error := ResourceLoader.load_threaded_request(path)
			if request_error != OK:
				return _failed_batch(concurrency, repetition, started_usec, "load_threaded_request failed for %s: %s" % [path, error_string(request_error)])
			active[path] = Time.get_ticks_usec()
			next_index += 1
			peak_active = maxi(peak_active, active.size())

		var completed_paths: Array[String] = []
		for path: String in active.keys():
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var resource := ResourceLoader.load_threaded_get(path)
				if resource == null:
					return _failed_batch(concurrency, repetition, started_usec, "load_threaded_get returned null for %s." % path)
				observations.append({
					"path": path,
					"latency_msec": float(Time.get_ticks_usec() - int(active[path])) / 1000.0,
				})
				completed_paths.append(path)
			elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				return _failed_batch(concurrency, repetition, started_usec, "Threaded load failed for %s with status %d." % [path, status])
			elif Time.get_ticks_usec() - int(active[path]) > LOAD_TIMEOUT_MSEC * 1000:
				return _failed_batch(concurrency, repetition, started_usec, "Timed out loading %s." % path)

		for path in completed_paths:
			active.erase(path)
		await get_tree().process_frame

	var duration_msec := float(Time.get_ticks_usec() - started_usec) / 1000.0
	var total_latency := 0.0
	var max_latency := 0.0
	for observation in observations:
		var latency := float(observation["latency_msec"])
		total_latency += latency
		max_latency = maxf(max_latency, latency)

	return {
		"strategy": "resource_loader_threaded",
		"concurrency": concurrency,
		"repetition": repetition,
		"asset_count": paths.size(),
		"duration_msec": duration_msec,
		"throughput_assets_per_second": float(paths.size()) * 1000.0 / maxf(duration_msec, 0.001),
		"average_latency_msec": total_latency / maxf(float(observations.size()), 1.0),
		"maximum_latency_msec": max_latency,
		"peak_active": peak_active,
		"observations": observations,
		"success": true,
		"failure": "",
	}


func _failed_batch(concurrency: int, repetition: int, started_usec: int, message: String) -> Dictionary:
	return {
		"strategy": "resource_loader_threaded",
		"concurrency": concurrency,
		"repetition": repetition,
		"duration_msec": float(Time.get_ticks_usec() - started_usec) / 1000.0,
		"success": false,
		"failure": message,
	}


func _finish() -> void:
	var payload := {
		"schema_version": 1,
		"experiment": "web-resource-loader-microbenchmark",
		"configuration": {
			"manifest_path": MANIFEST_PATH,
			"sample_count": SAMPLE_COUNT,
			"repetitions": REPETITIONS,
			"concurrency_values": CONCURRENCY_VALUES,
			"cache_provenance": "single browser process; browser and Web virtual-filesystem cache state uncontrolled",
		},
		"environment": {
			"godot_version": str(Engine.get_version_info().get("string", "unknown")),
			"os_name": OS.get_name(),
			"display_server": DisplayServer.get_name(),
			"thread_smoke": _thread_smoke(),
		},
		"measured": {
			"total_duration_msec": float(Time.get_ticks_usec() - _started_usec) / 1000.0,
			"runs": _results,
		},
		"limitations": [
			"The experiment runs inside a real threaded Web export but bypasses ChunkStreamer residency and MeshInstance3D creation.",
			"Browser, service-worker, operating-system, and Web virtual-filesystem cache state are not reset between repetitions.",
			"Headless browser execution does not represent GPU rendering cost and is not a rendered frame-time benchmark.",
			"ResourceLoader completion is observed once per Godot process frame.",
		],
		"success": not _failed,
		"failure": _failure_message,
	}
	var json := JSON.stringify(payload)
	print("WEB_RESOURCE_LOADING_EXPERIMENT_JSON=" + json)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__voxelResourceLoadingExperiment = %s;" % json)
	get_tree().quit(1 if _failed else 0)


func _thread_smoke() -> Dictionary:
	return {
		"web_feature": OS.has_feature("web"),
		"processor_count": OS.get_processor_count(),
	}


func _fail(message: String) -> void:
	_failed = true
	_failure_message = message
	push_error(message)
