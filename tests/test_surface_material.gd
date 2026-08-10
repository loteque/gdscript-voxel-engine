extends SceneTree

const SURFACE_NETS_DISPLAY := preload("res://voxel/meshing/SurfaceNetsMeshDisplay.gd")

var _failed: bool = false


func _initialize() -> void:
	_run_test.call_deferred()


func _run_test() -> void:
	var display := SURFACE_NETS_DISPLAY.new()
	root.add_child(display)
	await process_frame

	_assert_true(display.surface_material != null, "Surface Nets display must provide a default demo surface material.")
	_assert_true(display.material_override == display.surface_material, "Surface Nets display must apply its surface material as the mesh material override.")
	_assert_true(display.surface_material is StandardMaterial3D, "Default demo surface must use StandardMaterial3D so it participates in scene lighting.")

	if display.surface_material is StandardMaterial3D:
		var material := display.surface_material as StandardMaterial3D
		_assert_true(material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED, "Demo terrain surface must remain lit rather than unshaded.")

	display.queue_free()
	await process_frame

	if _failed:
		quit(1)
	else:
		print("Surface material tests passed.")
		quit(0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
