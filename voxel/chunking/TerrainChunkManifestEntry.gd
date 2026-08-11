class_name TerrainChunkManifestEntry
extends Resource

## Lightweight lookup record for one serialized terrain chunk asset.


# [b]Lookup[/b]
# Identifies an asset without loading its render mesh eagerly.

@export var chunk_coordinate: Vector3i = Vector3i.ZERO
@export var lod_level: int = 0
@export_file("*.tres", "*.res") var asset_path: String = ""
@export var bounds: AABB


# [b]Validation[/b]
# Checks manifest-record invariants only.

## Returns whether this entry can identify a loadable chunk asset.
func is_valid() -> bool:
	return not asset_path.is_empty() and bounds.size != Vector3.ZERO
