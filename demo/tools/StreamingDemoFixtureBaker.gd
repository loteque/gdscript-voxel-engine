class_name StreamingDemoFixtureBaker
extends RefCounted

## Builds the deterministic, precomputed terrain fixture used by the streaming demo.
##
## This utility belongs to the offline validation/build path. The published demo
## consumes only the serialized manifest and chunk assets produced here.

const OUTPUT_DIRECTORY := "res://demo/generated"
const MANIFEST_PATH := OUTPUT_DIRECTORY + "/StreamingDemoManifest.tres"
const SURFACE_MATERIAL_PATH := "res://voxel/meshing/DemoTerrainSurface.tres"

const CELL_DIMENSIONS := Vector3i(12, 12, 12)
const SAMPLE_SPACING := 1.0
const REGION_MIN := Vector3i(-6, 0, -6)
const REGION_MAX := Vector3i(6, 0, 6)
const NOISE_SEED := 8675309
const NOISE_FREQUENCY := 0.065
const TERRAIN_BASE_HEIGHT := 4.0
const TERRAIN_HEIGHT_SCALE := 5.5
const ISO_LEVEL := 0.0


## Generates a deterministic 13 x 1 x 13 asteroid-surface region and serializes its manifest.
##
## The 169-chunk scale is large enough to exercise sustained queueing, bounded
## threaded loading, hysteresis, and repeated eviction while remaining practical
## for CI and the threaded GitHub Pages Web export.
func bake() -> Error:
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return directory_error

	_cleanup_previous_chunks()

	var baker := ChunkAssetBaker.new()
	var manifest := TerrainChunkManifest.new()
	manifest.chunk_cell_dimensions = CELL_DIMENSIONS
	manifest.sample_spacing = SAMPLE_SPACING
	var material := load(SURFACE_MATERIAL_PATH) as Material
	var noise := _create_noise()
	var chunk_extent := Vector3(CELL_DIMENSIONS) * SAMPLE_SPACING

	for z in range(REGION_MIN.z, REGION_MAX.z + 1):
		for y in range(REGION_MIN.y, REGION_MAX.y + 1):
			for x in range(REGION_MIN.x, REGION_MAX.x + 1):
				var coordinate := Vector3i(x, y, z)
				var local_origin := Vector3(coordinate) * chunk_extent
				var local_center := local_origin + chunk_extent * 0.5
				var field := _create_field(local_center, noise)
				if not field.is_data_current():
					push_error("Streaming demo fixture failed to generate field %s." % coordinate)
					return ERR_INVALID_DATA

				var asset := baker.build_asset(field, coordinate, local_center, 0, ISO_LEVEL)
				if asset == null or not asset.is_valid():
					push_error("Streaming demo fixture failed to build chunk %s." % coordinate)
					return ERR_INVALID_DATA
				asset.bounds = AABB(local_origin, chunk_extent)
				if material != null:
					for surface_index in asset.mesh.get_surface_count():
						asset.mesh.surface_set_material(surface_index, material)

				var save_error := baker.save_asset(asset, _asset_path(coordinate), manifest)
				if save_error != OK:
					return save_error

	return baker.save_manifest(manifest, MANIFEST_PATH)


func _create_field(sampling_center: Vector3, noise: FastNoiseLite) -> PointFieldResource:
	var field := PointFieldResource.new()
	field.cell_dimensions = CELL_DIMENSIONS
	field.sample_spacing = SAMPLE_SPACING
	field.sampling_origin = sampling_center
	field.noise = noise
	field.density_scale = 1.0
	field.terrain_base_height = TERRAIN_BASE_HEIGHT
	field.terrain_height_scale = TERRAIN_HEIGHT_SCALE
	field.regenerate()
	return field


func _cleanup_previous_chunks() -> void:
	var directory := DirAccess.open(OUTPUT_DIRECTORY)
	if directory == null:
		return
	for filename in directory.get_files():
		if filename.begins_with("StreamingDemoChunk_") and filename.ends_with(".tres"):
			directory.remove(filename)


func _asset_path(coordinate: Vector3i) -> String:
	return OUTPUT_DIRECTORY + "/StreamingDemoChunk_%d_%d_%d.tres" % [
		coordinate.x, coordinate.y, coordinate.z
	]


func _create_noise() -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = NOISE_SEED
	noise.frequency = NOISE_FREQUENCY
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	return noise
