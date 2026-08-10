extends Node3D

## Minimal runtime proof for loading a baked chunk through TerrainChunkManifest.


# [b]Configuration[/b]
# Supplies the baked catalog and coordinate under validation.

@export var manifest: TerrainChunkManifest
@export var chunk_coordinate: Vector3i = Vector3i.ZERO
@export var lod_level: int = 0


# [b]Scene References[/b]
# Keeps validation UI separate from the streaming implementation.

@onready var _streamer: ChunkStreamer = $ChunkStreamer
@onready var _status_label: Label = $UI/Panel/Margin/Content/Status
@onready var _load_button: Button = $UI/Panel/Margin/Content/Buttons/Load
@onready var _unload_button: Button = $UI/Panel/Margin/Content/Buttons/Unload


func _ready() -> void:
	_streamer.manifest = manifest
	_streamer.lod_level = lod_level
	_streamer.chunk_loaded.connect(_on_chunk_loaded)
	_streamer.chunk_unloaded.connect(_on_chunk_unloaded)
	_streamer.chunk_load_failed.connect(_on_chunk_load_failed)
	_load_button.pressed.connect(_load_chunk)
	_unload_button.pressed.connect(_unload_chunk)
	_load_chunk()


# [b]Validation Actions[/b]
# Exercises only the baked-asset runtime path.

func _load_chunk() -> void:
	var error := _streamer.load_chunk(chunk_coordinate)
	if error == OK:
		_update_status("loaded")
	else:
		_update_status("load failed: %s" % error_string(error))


func _unload_chunk() -> void:
	if _streamer.unload_chunk(chunk_coordinate):
		_update_status("unloaded")
	else:
		_update_status("already unloaded")


# [b]Status[/b]
# Makes manifest lookup and residency state visible during manual QA.

func _update_status(state: String) -> void:
	var asset_path := "<missing manifest entry>"
	if manifest != null:
		var entry := manifest.find_entry(chunk_coordinate, lod_level)
		if entry != null:
			asset_path = entry.asset_path

	_status_label.text = (
		"Coordinate: %s\nLOD: %d\nAsset: %s\nState: %s"
		% [chunk_coordinate, lod_level, asset_path, state]
	)


func _on_chunk_loaded(_coordinate: Vector3i, _instance: MeshInstance3D) -> void:
	_update_status("loaded")


func _on_chunk_unloaded(_coordinate: Vector3i) -> void:
	_update_status("unloaded")


func _on_chunk_load_failed(_coordinate: Vector3i, error: Error) -> void:
	_update_status("load failed: %s" % error_string(error))
