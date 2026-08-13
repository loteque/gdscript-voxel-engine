class_name TerrainChunkManifestEntry
extends Resource

## Lightweight lookup record for one serialized terrain chunk asset.


# [b]Lookup[/b]
# Identifies an asset without loading its render mesh eagerly.

@export var chunk_coordinate: Vector3i = Vector3i.ZERO
@export var lod_level: int = 0
@export_file("*.tres", "*.res") var asset_path: String = ""
@export var bounds: AABB


# [b]Baked Characteristics[/b]
# Preserves immutable offline measurements for runtime analysis without loading assets.

## Serialized size of the baked chunk resource in bytes, when known.
@export var serialized_size_bytes: int = 0

## Total vertex count across all mesh surfaces, measured during baking.
@export var mesh_vertex_count: int = 0

## Total index count across all mesh surfaces, measured during baking.
@export var mesh_index_count: int = 0


# [b]Validation[/b]
# Checks manifest-record invariants only.

## Returns whether this entry can identify a loadable chunk asset.
func is_valid() -> bool:
	return not asset_path.is_empty() and bounds.size != Vector3.ZERO
