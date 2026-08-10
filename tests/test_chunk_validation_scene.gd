extends SceneTree

const VALIDATION_SCENE := preload("res://demo/ChunkValidationDemo.tscn")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := VALIDATION_SCENE.instantiate()
	root.add_child(scene)

	await process_frame
	await process_frame

	var manager := scene.get_node("ChunkManager") as ChunkManager
	var surface_display := scene.get_node("ChunkSurfaceNetsDisplay") as ChunkSurfaceNetsDisplay
	var visualizer := scene.get_node("ChunkVisualizer") as ChunkVisualizer

	_assert_true(manager != null, "Validation scene must contain its ChunkManager.")
	_assert_true(surface_display != null, "Validation scene must contain its chunk Surface Nets display.")
	_assert_true(visualizer != null, "Validation scene must contain its ChunkVisualizer.")

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

	if visualizer != null:
		visualizer.rebuild()
		_assert_equal(
			visualizer.get_visualized_loaded_chunk_count(),
			9,
			"Validation scene must visualize all loaded chunks."
		)
		_assert_equal(
			visualizer.get_visualized_preview_cell_count(),
			9,
			"Validation scene must visualize the planned 3x1x3 grid."
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
