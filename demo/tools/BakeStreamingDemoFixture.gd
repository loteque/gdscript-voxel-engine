extends SceneTree

## Headless entrypoint for regenerating the streaming validation terrain fixture.


func _initialize() -> void:
	var baker := StreamingDemoFixtureBaker.new()
	var error := baker.bake()
	if error != OK:
		push_error("Streaming demo fixture bake failed: %s" % error_string(error))
		quit(1)
		return

	print("Streaming demo terrain fixture baked successfully.")
	quit(0)
