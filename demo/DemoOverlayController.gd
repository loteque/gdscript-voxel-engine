extends Node

## Provides a persistent collapse/restore control for every scene under res://demo/.
##
## The controller hides whole CanvasLayer overlays so each overlay preserves its
## own internal visibility state. On Web builds it also hides the injected
## GitHub Pages demo selector, leaving only the persistent restore control.

const DEMO_SCENE_PREFIX := "res://demo/"
const PAGES_SELECTOR_ID := "voxel-demo-selector"
const TOGGLE_SIZE := Vector2(220.0, 72.0)
const TOGGLE_BOTTOM_MARGIN := 24.0

var _active_scene: Node
var _overlay_visibility: Dictionary = {}
var _overlays_visible: bool = true
var _toggle_layer: CanvasLayer
var _toggle_button: Button


func _ready() -> void:
	_create_toggle_ui()
	set_process(true)


func _process(_delta: float) -> void:
	var current_scene := get_tree().current_scene
	if current_scene == _active_scene:
		return

	_restore_previous_scene_overlays()
	_active_scene = current_scene
	_overlays_visible = true
	_overlay_visibility.clear()
	_refresh_activation()


## Returns whether a scene path participates in the demo overlay convention.
func is_demo_scene_path(scene_path: String) -> bool:
	return scene_path.begins_with(DEMO_SCENE_PREFIX)


## Returns whether the active demo overlays are currently visible.
func are_overlays_visible() -> bool:
	return _overlays_visible


## Shows or hides every CanvasLayer overlay owned by the active demo scene.
##
## Existing per-layer visibility is remembered while collapsed and restored
## exactly when the UI is shown again.
func set_overlays_visible(visible: bool) -> void:
	if _active_scene == null or not is_demo_scene_path(_active_scene.scene_file_path):
		return
	if visible == _overlays_visible:
		return

	if visible:
		_restore_saved_overlay_visibility()
	else:
		_capture_and_hide_overlays(_active_scene)

	_overlays_visible = visible
	_update_toggle_button()
	_set_pages_selector_visible(visible)


## Toggles all demo UI overlays while keeping the restore control available.
func toggle_overlays() -> void:
	set_overlays_visible(not _overlays_visible)


func _create_toggle_ui() -> void:
	_toggle_layer = CanvasLayer.new()
	_toggle_layer.name = "DemoOverlayToggleLayer"
	_toggle_layer.layer = 1000
	add_child(_toggle_layer)

	_toggle_button = Button.new()
	_toggle_button.name = "DemoOverlayToggleButton"
	_toggle_button.custom_minimum_size = TOGGLE_SIZE
	_toggle_button.anchor_left = 0.5
	_toggle_button.anchor_top = 1.0
	_toggle_button.anchor_right = 0.5
	_toggle_button.anchor_bottom = 1.0
	_toggle_button.offset_left = -TOGGLE_SIZE.x * 0.5
	_toggle_button.offset_top = -TOGGLE_SIZE.y - TOGGLE_BOTTOM_MARGIN
	_toggle_button.offset_right = TOGGLE_SIZE.x * 0.5
	_toggle_button.offset_bottom = -TOGGLE_BOTTOM_MARGIN
	_toggle_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toggle_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toggle_button.add_theme_font_size_override("font_size", 28)
	_toggle_button.focus_mode = Control.FOCUS_ALL
	_toggle_button.pressed.connect(toggle_overlays)
	_toggle_layer.add_child(_toggle_button)
	_update_toggle_button()
	_toggle_layer.visible = false


func _refresh_activation() -> void:
	var active := _active_scene != null and is_demo_scene_path(_active_scene.scene_file_path)
	_toggle_layer.visible = active
	_update_toggle_button()
	if active:
		_set_pages_selector_visible(true)


func _update_toggle_button() -> void:
	if _toggle_button == null:
		return
	_toggle_button.text = "Hide UI" if _overlays_visible else "Show UI"
	_toggle_button.tooltip_text = (
		"Hide demo overlays to watch the scene unobstructed."
		if _overlays_visible
		else "Restore demo overlays."
	)


func _capture_and_hide_overlays(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			var layer := child as CanvasLayer
			_overlay_visibility[layer.get_instance_id()] = {
				"node": layer,
				"visible": layer.visible,
			}
			layer.visible = false
		_capture_and_hide_overlays(child)


func _restore_saved_overlay_visibility() -> void:
	for state: Dictionary in _overlay_visibility.values():
		var layer: CanvasLayer = state["node"]
		if is_instance_valid(layer):
			layer.visible = bool(state["visible"])
	_overlay_visibility.clear()


func _restore_previous_scene_overlays() -> void:
	if not _overlays_visible:
		_restore_saved_overlay_visibility()
		_set_pages_selector_visible(true)


func _set_pages_selector_visible(visible: bool) -> void:
	if not OS.has_feature("web"):
		return
	var display_value := "" if visible else "none"
	JavaScriptBridge.eval(
		"(() => { const element = document.getElementById('%s'); if (element) element.style.display = '%s'; return true; })()"
		% [PAGES_SELECTOR_ID, display_value],
		true
	)
