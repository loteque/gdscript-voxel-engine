@tool
class_name SurfaceNetsMeshDisplay
extends MeshInstance3D

## Displays a Surface Nets mesh generated from a [PointFieldResource].
##
## This node owns transient mesh presentation only. The point field remains the
## authoritative source of scalar data, while [SurfaceNetsMesher] owns the
## extraction algorithm. Mesh generation is deferred while the display is
## hidden so field edits do not spend time rebuilding invisible geometry.

signal loading_state_changed(is_loading: bool)


# [b]Display Configuration[/b] Controls the field and iso-surface shown by this node.

## The authoritative scalar field consumed by the Surface Nets mesher.
@export var field: PointFieldResource:
	set(value):
		if field == value:
			return
		_disconnect_field()
		field = value
		_connect_field()
		_mark_mesh_dirty()

## Whether the generated Surface Nets mesh is visible.
@export var display_surface_nets_mesh: bool = false:
	set(value):
		if display_surface_nets_mesh == value:
			return
		display_surface_nets_mesh = value
		visible = value
		if value:
			_queue_mesh_rebuild()
		else:
			_set_loading(false)

## Density value extracted as the Surface Nets iso-surface.
@export_range(-2.0, 2.0, 0.01, "or_greater", "or_less")
var iso_level: float = 0.0:
	set(value):
		if is_equal_approx(iso_level, value):
			return
		iso_level = value
		_mark_mesh_dirty()


# [b]Meshing State[/b] Keeps algorithm state transient and avoids duplicate rebuild requests.

var is_loading: bool = false
var _mesher := SurfaceNetsMesher.new()
var _mesh_dirty: bool = true
var _mesh_rebuild_queued: bool = false


# [b]Lifecycle[/b] Connects field changes and synchronizes initial visibility.

func _enter_tree() -> void:
	visible = display_surface_nets_mesh
	_connect_field()
	_mark_mesh_dirty()


func _exit_tree() -> void:
	_disconnect_field()
	_set_loading(false)


# [b]Public API[/b] Rebuilds or invalidates the transient ArrayMesh.

## Immediately regenerates the displayed mesh when the display is enabled.
func rebuild_mesh() -> void:
	_mesh_rebuild_queued = false

	if not display_surface_nets_mesh:
		_set_loading(false)
		return

	_mesh_dirty = false
	if field == null or not field.validate_data():
		mesh = null
		_set_loading(false)
		return

	mesh = _mesher.generate_mesh(field, iso_level)
	_set_loading(false)


## Marks the generated mesh stale and schedules a rebuild when visible.
func invalidate_mesh() -> void:
	_mark_mesh_dirty()


# [b]Field Synchronization[/b] Observes only changes that can affect extracted topology.

func _connect_field() -> void:
	if field == null:
		return

	if not field.geometry_configuration_changed.is_connected(_on_field_changed):
		field.geometry_configuration_changed.connect(_on_field_changed)

	if not field.positions_changed.is_connected(_on_field_changed):
		field.positions_changed.connect(_on_field_changed)

	if not field.densities_changed.is_connected(_on_field_changed):
		field.densities_changed.connect(_on_field_changed)


func _disconnect_field() -> void:
	if field == null:
		return

	if field.geometry_configuration_changed.is_connected(_on_field_changed):
		field.geometry_configuration_changed.disconnect(_on_field_changed)

	if field.positions_changed.is_connected(_on_field_changed):
		field.positions_changed.disconnect(_on_field_changed)

	if field.densities_changed.is_connected(_on_field_changed):
		field.densities_changed.disconnect(_on_field_changed)


func _on_field_changed() -> void:
	_mark_mesh_dirty()


# [b]Deferred Rebuilds[/b] Coalesces bursts of field signals into one mesh generation pass.

func _mark_mesh_dirty() -> void:
	_mesh_dirty = true
	if display_surface_nets_mesh:
		_queue_mesh_rebuild()


func _queue_mesh_rebuild() -> void:
	if not is_inside_tree() or _mesh_rebuild_queued or not _mesh_dirty:
		return

	_mesh_rebuild_queued = true
	_set_loading(true)
	call_deferred("rebuild_mesh")


func _set_loading(value: bool) -> void:
	if is_loading == value:
		return

	is_loading = value
	loading_state_changed.emit(is_loading)
