extends SceneTree

const VALIDATION_SCENE := preload("res://demo/ChunkValidationDemo.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := VALIDATION_SCENE.instantiate() as ChunkValidationDemo
	root.add_child(scene)

	var manager := scene.get_node("ChunkManager") as ChunkManager
	var surface_display := scene.get_node("ChunkSurfaceNetsDisplay") as ChunkSurfaceNetsDisplay
	var visualizer := scene.get_node("ChunkVisualizer") as ChunkVisualizer
	var camera := scene.get_node("Camera") as Camera3D

	# _ready() reaches the first process-frame await before add_child() returns.
	# At that boundary the lightweight startup presentation must already exist,
	# while expensive chunk creation/generation has not begun.
	_assert_true(scene.startup_preview_presented, "Validation scene must present its startup preview before generation.")
	_assert_true(manager != null, "Validation scene must contain its ChunkManager.")
	_assert_true(surface_display != null, "Validation scene must contain its chunk Surface Nets display.")
	_assert_true(visualizer != null, "Validation scene must contain its ChunkVisualizer.")
	_assert_true(camera != null and camera.current, "Validation scene must contain an active camera.")

	if manager != null:
		_assert_equal(manager.get_chunk_count(), 0, "Startup preview must not allocate chunks before the first presented frame.")

	if visualizer != null:
		_assert_equal(
			visualizer.get_visualized_preview_cell_count(),
			9,
			"Startup preview must show the planned 3x1x3 chunk grid before terrain generation."
		)
		_assert_equal(
			visualizer.get_visualized_loaded_chunk_count(),
			0,
			"Startup preview must not show loaded chunks before generation begins."
		)

	if not scene.generation_complete:
		await scene.generation_completed

	_assert_true(scene.generation_complete, "Validation scene must complete staged generation.")

	if manager != null:
		_assert_equal(manager.get_chunk_count(), 9, "Validation scene must create a 3x1x3 chunk grid.")
		for coordinate in manager.get_chunk_coordinates():
			var chunk := manager.get_chunk(coordinate)
			_assert_true(
				chunk != null and chunk.point_field != null and chunk.point_field.is_data_current(),
				"Every validation chunk must have a current generated point field."
			)

	if surface_display != null:
		_assert_equal(
			surface_display.get_display_count(),
			9,
			"Validation scene must create one Surface Nets display per chunk."
		)
		var nonempty_mesh_count := 0
		for coordinate in manager.get_chunk_coordinates():
			var display := surface_display.get_display(coordinate)
			if display != null and display.mesh != null and display.mesh.get_surface_count() > 0:
				nonempty_mesh_count += 1
		_assert_true(
			nonempty_mesh_count > 0,
			"Validation scene must generate visible Surface Nets geometry."
		)

	if visualizer != null:
		visualizer.rebuild()
		_assert_equal(
			visualizer.get_visualized_loaded_chunk_count(),
			9,
			"Validation scene must visualize all loaded chunks after generation."
		)
		_assert_equal(
			visualizer.get_visualized_preview_cell_count(),
			9,
			"Validation scene must retain the planned 3x1x3 grid after generation."
		)

	if camera != null:
		var target: Vector3 = scene.get_grid_center()
		var direction_to_target: Vector3 = camera.global_position.direction_to(target)
		var camera_forward: Vector3 = -camera.global_basis.z.normalized()
		_assert_true(
			camera_forward.dot(direction_to_target) > 0.99,
			"Validation camera must face the generated chunk grid."
		)

	scene.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s Expected %s, got %s." % [message, expected, actual])
