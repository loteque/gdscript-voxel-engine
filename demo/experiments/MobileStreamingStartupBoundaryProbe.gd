extends Node

## Temporary Web-only diagnostic for the mobile streaming startup investigation.
##
## This probe deliberately observes the existing Integration Preview from outside the
## ChunkStreamer/runtime implementation. It reports the first post-resource-loading
## startup boundary that has not completed, without changing streaming behavior.

const STREAMING_SCENE_PATH := "res://demo/ChunkStreamingValidationDemo.tscn"
const OVERLAY_ID := "voxel-mobile-startup-boundary"

var _last_message: String = ""


func _ready() -> void:
	if OS.has_feature("web"):
		_publish("PROBE ACTIVE", "Waiting for the streaming Integration Preview scene.")


func _process(_delta: float) -> void:
	if not OS.has_feature("web"):
		return

	var scene := get_tree().current_scene
	if scene == null:
		_publish("SCENE", "Main scene has not been installed yet.")
		return
	if scene.scene_file_path != STREAMING_SCENE_PATH:
		return

	var manifest = scene.get("manifest")
	var matrix = scene.get("experiment_matrix")
	if manifest == null or matrix == null:
		_publish(
			"RESOURCE ASSIGNMENT",
			"Scene exists, but manifest/matrix assignment is incomplete: manifest=%s matrix=%s"
			% [manifest != null, matrix != null]
		)
		return

	var streamer := scene.get_node_or_null("ChunkStreamer")
	var target := scene.get_node_or_null("ResidencyTarget")
	if streamer == null or target == null:
		_publish("SCENE WIRING", "Required ChunkStreamer or ResidencyTarget node is missing.")
		return

	if streamer.get("manifest") != manifest:
		_publish("STREAMER CONFIG", "Resources loaded, but _streamer.manifest assignment has not completed.")
		return
	if streamer.get("target") != target:
		_publish("STREAMER CONFIG", "Manifest assigned, but _streamer.target assignment has not completed.")
		return

	var streaming_signals_ready := (
		_has_connection(streamer, &"chunk_load_queued", Callable(scene, "_on_chunk_load_queued"))
		and _has_connection(streamer, &"chunk_load_started", Callable(scene, "_on_chunk_load_started"))
		and _has_connection(streamer, &"chunk_loaded", Callable(scene, "_on_residency_changed"))
		and _has_connection(streamer, &"chunk_unloaded", Callable(scene, "_on_chunk_unloaded"))
		and _has_connection(streamer, &"chunk_load_failed", Callable(scene, "_on_chunk_load_failed"))
	)
	if not streaming_signals_ready:
		_publish("SIGNAL WIRING", "Streamer configuration completed, but streaming signal wiring is incomplete.")
		return

	var matrix_panel = scene.get("_matrix_panel")
	var matrix_status_label = scene.get("_matrix_status_label")
	if matrix_panel == null or matrix_status_label == null:
		_publish("UI INITIALIZATION", "Streaming signals are wired, but experiment controls are not fully initialized.")
		return

	var streaming_state := str(scene.get("_streaming_state"))
	if streaming_state == "not configured":
		_publish("READY-STATE", "Controls are initialized, but final ready-state initialization has not completed.")
		return

	var pending_count := 0
	if streamer.has_method("get_pending_coordinates"):
		var pending = streamer.call("get_pending_coordinates")
		if pending is Array:
			pending_count = pending.size()
	_publish(
		"READY COMPLETE",
		"Post-load startup completed. streaming_state=%s; pending=%d" % [streaming_state, pending_count]
	)


func _has_connection(node: Node, signal_name: StringName, callable: Callable) -> bool:
	for connection in node.get_signal_connection_list(signal_name):
		if connection.get("callable") == callable:
			return true
	return false


func _publish(stage: String, detail: String) -> void:
	var message := "%s\n%s" % [stage, detail]
	if message == _last_message:
		return
	_last_message = message
	print("MOBILE STARTUP BOUNDARY | %s | %s" % [stage, detail])

	var payload := JSON.stringify({"stage": stage, "detail": detail})
	var script := """
(() => {
  const payload = %s;
  window.__voxelMobileStartupBoundary = payload;
  let root = document.getElementById('%s');
  if (!root) {
    root = document.createElement('div');
    root.id = '%s';
    root.setAttribute('role', 'status');
    root.style.cssText = [
      'position:fixed', 'z-index:2147483645', 'left:16px', 'right:16px', 'top:136px',
      'max-width:760px', 'margin:auto', 'padding:14px 16px', 'box-sizing:border-box',
      'border:3px solid #f5b642', 'border-radius:14px', 'background:rgba(25,17,2,.96)',
      'color:#fff8e8', 'font:700 19px/1.35 system-ui,sans-serif', 'white-space:pre-wrap',
      'pointer-events:none'
    ].join(';');
    document.body.appendChild(root);
  }
  root.textContent = `Startup boundary: ${payload.stage}\n${payload.detail}`;
})();
""" % [payload, OVERLAY_ID, OVERLAY_ID]
	JavaScriptBridge.eval(script, true)
