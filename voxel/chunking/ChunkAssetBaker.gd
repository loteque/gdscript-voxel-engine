class_name ChunkAssetBaker
extends RefCounted

## Packages generated point fields into streamable terrain chunk assets.
##
## Generation, meshing, serialization, and runtime streaming remain separate:
## callers provide a current field and deterministic chunk placement, this baker
## invokes the mesher and writes the resulting asset/manifest records.


# [b]Asset Construction[/b]
# Converts current field data into a render-ready serialized chunk resource.

## Builds a chunk asset from a current field and its terrain-local origin.
func build_asset(
	field: PointFieldResource,
	chunk_coordinate: Vector3i,
	local_origin: Vector3,
	lod_level: int = 0,
	iso_level: float = 0.0
) -> TerrainChunkAsset:
	if field == null or not field.is_data_current():
		push_error("ChunkAssetBaker requires current point-field data.")
		return null

	var mesh := SurfaceNetsMesher.new().generate_mesh(field, iso_level)
	var asset := TerrainChunkAsset.new()
	asset.chunk_coordinate = chunk_coordinate
	asset.lod_level = lod_level
	asset.local_origin = local_origin
	asset.cell_dimensions = field.cell_dimensions
	asset.sample_spacing = field.sample_spacing
	asset.mesh = mesh
	asset.bounds = AABB(local_origin, field.size)
	return asset


# [b]Serialization[/b]
# Saves chunk assets and updates lightweight manifests explicitly.

## Saves [param asset] and records its path in [param manifest].
func save_asset(
	asset: TerrainChunkAsset,
	asset_path: String,
	manifest: TerrainChunkManifest = null
) -> Error:
	if asset == null or not asset.is_valid():
		push_error("ChunkAssetBaker requires a valid TerrainChunkAsset.")
		return ERR_INVALID_DATA
	if asset_path.is_empty():
		return ERR_INVALID_PARAMETER

	var error := ResourceSaver.save(asset, asset_path)
	if error != OK:
		return error

	if manifest != null:
		var entry := TerrainChunkManifestEntry.new()
		entry.chunk_coordinate = asset.chunk_coordinate
		entry.lod_level = asset.lod_level
		entry.asset_path = asset_path
		entry.bounds = asset.bounds
		entry.serialized_size_bytes = _get_serialized_size_bytes(asset_path)
		entry.mesh_vertex_count = _get_mesh_vertex_count(asset.mesh)
		entry.mesh_index_count = _get_mesh_index_count(asset.mesh)
		manifest.set_entry(entry)
	return OK


## Saves a completed manifest resource.
func save_manifest(manifest: TerrainChunkManifest, manifest_path: String) -> Error:
	if manifest == null or not manifest.is_valid():
		push_error("ChunkAssetBaker requires a valid TerrainChunkManifest.")
		return ERR_INVALID_DATA
	if manifest_path.is_empty():
		return ERR_INVALID_PARAMETER
	return ResourceSaver.save(manifest, manifest_path)


# [b]Baked Characteristics[/b]
# Captures immutable asset measurements while the offline baker already owns the data.

func _get_serialized_size_bytes(asset_path: String) -> int:
	var file := FileAccess.open(asset_path, FileAccess.READ)
	if file == null:
		return 0
	return file.get_length()


func _get_mesh_vertex_count(mesh: ArrayMesh) -> int:
	if mesh == null:
		return 0
	var count := 0
	for surface_index in mesh.get_surface_count():
		count += mesh.surface_get_array_len(surface_index)
	return count


func _get_mesh_index_count(mesh: ArrayMesh) -> int:
	if mesh == null:
		return 0
	var count := 0
	for surface_index in mesh.get_surface_count():
		count += mesh.surface_get_array_index_len(surface_index)
	return count
