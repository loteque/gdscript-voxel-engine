extends SceneTree

const OUTPUT_DIR := "res://demo/generated/resource_loader_controls"
const COUNT := 24


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for index in COUNT:
		var resource := Resource.new()
		resource.set_meta("control_index", index)
		var path := "%s/control_%02d.tres" % [OUTPUT_DIR, index]
		var error := ResourceSaver.save(resource, path)
		if error != OK:
			push_error("Failed to save %s: %s" % [path, error_string(error)])
			quit(1)
			return
	print("Baked %d trivial ResourceLoader controls." % COUNT)
	quit(0)
