class_name TerrainChunkManifest
extends Resource

## Lightweight catalog of serialized terrain chunk assets.
##
## The manifest intentionally stores asset paths rather than chunk meshes so a
## runtime streamer can make load decisions before touching heavyweight data.


# [b]Layout[/b]
# Records the deterministic chunk geometry shared by all entries.

@export var chunk_cell_dimensions: Vector3i = Vector3i.ZERO
@export var sample_spacing: float = 1.0
@export var entries: Array[TerrainChunkManifestEntry] = []


# [b]Queries[/b]
# Provides deterministic coordinate/LOD lookup without streaming policy.

## Returns the manifest entry for [param coordinate] and [param lod_level].
func find_entry(
	coordinate: Vector3i,
	lod_level: int = 0
) -> TerrainChunkManifestEntry:
	for entry in entries:
		if entry == null:
			continue
		if entry.chunk_coordinate == coordinate and entry.lod_level == lod_level:
			return entry
	return null


## Returns whether this manifest contains a coordinate/LOD pair.
func has_entry(coordinate: Vector3i, lod_level: int = 0) -> bool:
	return find_entry(coordinate, lod_level) != null


# [b]Mutation[/b]
# Supports offline manifest assembly while preventing duplicate lookup keys.

## Adds or replaces one coordinate/LOD entry.
func set_entry(entry: TerrainChunkManifestEntry) -> void:
	if entry == null:
		return
	for index in entries.size():
		var existing := entries[index]
		if existing == null:
			continue
		if (
			existing.chunk_coordinate == entry.chunk_coordinate
			and existing.lod_level == entry.lod_level
		):
			entries[index] = entry
			emit_changed()
			return
	entries.append(entry)
	emit_changed()


# [b]Validation[/b]
# Checks manifest structure, not file-system availability.

## Returns whether layout metadata and all entries are structurally valid.
func is_valid() -> bool:
	if chunk_cell_dimensions.x <= 0 or chunk_cell_dimensions.y <= 0 or chunk_cell_dimensions.z <= 0:
		return false
	if sample_spacing <= 0.0:
		return false
	for entry in entries:
		if entry == null or not entry.is_valid():
			return false
	return true
