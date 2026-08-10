@tool
class_name ChunkSurfaceNetsDisplay
extends Node3D

## Presents one Surface Nets mesh display for every chunk in a [ChunkManager].
##
## This node is a consumer only. ChunkManager owns chunk lifecycle,
## TerrainChunk owns point-field storage, and SurfaceNetsMeshDisplay owns
## transient mesh presentation. The Surface Nets mesher remains completely
## unaware that chunks exist.


# [b]Display Configuration[/b]

@export var chunk_manager: ChunkManager:
	set(value):
		if chunk_manager == value:
			return
		_disconnect_manager()
		chunk_manager = value
		_connect_manager()
		_rebuild_displays()

@export var display_meshes: bool = true:
	set(value):
		if display_meshes == value:
			return
		display_meshes = value
		_update_display_visibility()

@export_range(-2.0, 2.0, 0.01, "or_greater", "or_less")
var iso_level: float = 0.0:
	set(value):
		if is_equal_approx(iso_level, value):
			return
		iso_level = value
		_update_iso_level()

@export var surface_material: Material = SurfaceNetsMeshDisplay.DEFAULT_DEMO_SURFACE:
	set(value):
		surface_material = value
		_update_surface_material()


# [b]Editor Preview[/b]

## Uses the real generated Surface Nets mesh with a cheap wireframe shader in
## the editor. Runtime continues to use [member surface_material].
@export var editor_wireframe_preview: bool = true:
	set(value):
		if editor_wireframe_preview == value:
			return
		editor_wireframe_preview = value
		_editor_wireframe_material = null
		_update_surface_material()

@export var editor_wireframe_color: Color = Color(0.3, 0.9, 1.0, 1.0):
	set(value):
		editor_wireframe_color = value
		_editor_wireframe_material = null
		_update_surface_material()


# [b]Display Storage[/b]

var _displays: Dictionary[Vector3i, SurfaceNetsMeshDisplay] = {}
var _editor_wireframe_material: ShaderMaterial


# [b]Lifecycle[/b]

func _enter_tree() -> void:
	_connect_manager()
	_rebuild_displays()


func _exit_tree() -> void:
	_disconnect_manager()


# [b]Public API[/b]

func get_display(coordinate: Vector3i) -> SurfaceNetsMeshDisplay:
	return _displays.get(coordinate) as SurfaceNetsMeshDisplay


func get_display_count() -> int:
	return _displays.size()


func rebuild_all_meshes() -> void:
	for coordinate in _displays:
		var display := _displays[coordinate]
		if display != null:
			display.rebuild_mesh()


# [b]Manager Synchronization[/b]

func _connect_manager() -> void:
	if chunk_manager == null:
		return
	if not chunk_manager.chunk_added.is_connected(_on_chunk_added):
		chunk_manager.chunk_added.connect(_on_chunk_added)
	if not chunk_manager.chunk_removed.is_connected(_on_chunk_removed):
		chunk_manager.chunk_removed.connect(_on_chunk_removed)


func _disconnect_manager() -> void:
	if chunk_manager == null:
		return
	if chunk_manager.chunk_added.is_connected(_on_chunk_added):
		chunk_manager.chunk_added.disconnect(_on_chunk_added)
	if chunk_manager.chunk_removed.is_connected(_on_chunk_removed):
		chunk_manager.chunk_removed.disconnect(_on_chunk_removed)


func _on_chunk_added(chunk: TerrainChunk) -> void:
	_create_display_for_chunk(chunk)


func _on_chunk_removed(coordinate: Vector3i) -> void:
	_displays.erase(coordinate)


# [b]Display Construction[/b]

func _rebuild_displays() -> void:
	_clear_displays()
	if chunk_manager == null:
		return

	for coordinate in chunk_manager.get_chunk_coordinates():
		_create_display_for_chunk(chunk_manager.get_chunk(coordinate))


func _create_display_for_chunk(chunk: TerrainChunk) -> SurfaceNetsMeshDisplay:
	if chunk == null:
		return null

	var existing := get_display(chunk.chunk_coordinate)
	if existing != null:
		return existing

	var display := SurfaceNetsMeshDisplay.new()
	display.name = "SurfaceNetsMesh"
	display.field = chunk.point_field
	display.iso_level = iso_level
	display.surface_material = _get_active_surface_material()
	display.display_surface_nets_mesh = display_meshes
	chunk.add_child(display)
	_displays[chunk.chunk_coordinate] = display
	return display


func _clear_displays() -> void:
	for coordinate in _displays:
		var display := _displays[coordinate]
		if is_instance_valid(display):
			display.queue_free()
	_displays.clear()


# [b]Display Updates[/b]

func _update_display_visibility() -> void:
	for coordinate in _displays:
		var display := _displays[coordinate]
		if display != null:
			display.display_surface_nets_mesh = display_meshes


func _update_iso_level() -> void:
	for coordinate in _displays:
		var display := _displays[coordinate]
		if display != null:
			display.iso_level = iso_level


func _update_surface_material() -> void:
	var active_material := _get_active_surface_material()
	for coordinate in _displays:
		var display := _displays[coordinate]
		if display != null:
			display.surface_material = active_material


func _get_active_surface_material() -> Material:
	if not Engine.is_editor_hint() or not editor_wireframe_preview:
		return surface_material

	if _editor_wireframe_material == null:
		# Wireframe is a spatial shader render mode rather than a
		# StandardMaterial3D polygon property in Godot 4.7.
		RenderingServer.set_debug_generate_wireframes(true)
		var shader := Shader.new()
		shader.code = """
shader_type spatial;
render_mode unshaded, wireframe, cull_disabled;
uniform vec4 wire_color : source_color = vec4(0.3, 0.9, 1.0, 1.0);
void fragment() {
	ALBEDO = wire_color.rgb;
	ALPHA = wire_color.a;
}
"""
		_editor_wireframe_material = ShaderMaterial.new()
		_editor_wireframe_material.shader = shader
		_editor_wireframe_material.set_shader_parameter("wire_color", editor_wireframe_color)

	return _editor_wireframe_material
