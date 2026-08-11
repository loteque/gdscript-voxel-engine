class_name StreamingDemoFixtureBaker
extends RefCounted

## Builds the deterministic, precomputed terrain fixture used by the streaming demo.
##
## This utility belongs to the offline validation/build path. The published demo
## consumes only the serialized manifest and chunk asset produced here.

const OUTPUT_DIRECTORY := "res://demo/generated"
const ASSET_PATH := OUTPUT_DIRECTORY + "/StreamingDemoChunk.tres"
const MANIFEST_PATH := OUTPUT_DIRECTORY + "/StreamingDemoManifest.tres"
const SURFACE_MATERIAL_PATH := "res://voxel/meshing/DemoTerrainSurface.tres"

const CHUNK_COORDINATE := Vector3i.ZERO
const CELL_DIMENSIONS := Vector3i(16, 16, 16)
const SAMPLE_SPACING := 1.0
const NOISE_SEED := 8675309
const NOISE_FREQUENCY := 0.065
const TERRAIN_HEIGHT_SCALE := 5.5
const ISO_LEVEL := 0.0


## Generates one noise-driven Surface Nets chunk and serializes its manifest.
func bake() -> Error:
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return directory_error

	var field := PointFieldResource.new()
	field.cell_dimensions = CELL_DIMENSIONS
	field.sample_spacing = SAMPLE_SPACING
	field.sampling_origin = Vector3.ZERO
	field.noise = _create_noise()
	field.density_scale = 1.0
	field.terrain_base_height = 0.0
	field.terrain_height_scale = TERRAIN_HEIGHT_SCALE
	field.regenerate()
	if not field.is_data_current():
		push_error("Streaming demo fixture failed to generate current point-field data.")
		return ERR_INVALID_DATA

	var baker := ChunkAssetBaker.new()
	var asset := baker.build_asset(field, CHUNK_COORDINATE, Vector3.ZERO, 0, ISO_LEVEL)
	if asset == null or not asset.is_valid() or asset.mesh.get_surface_count() == 0:
		push_error("Streaming demo fixture failed to generate renderable terrain.")
		return ERR_INVALID_DATA

	var material := load(SURFACE_MATERIAL_PATH) as Material
	if material != null:
		for surface_index in asset.mesh.get_surface_count():
			asset.mesh.surface_set_material(surface_index, material)

	var manifest := TerrainChunkManifest.new()
	manifest.chunk_cell_dimensions = CELL_DIMENSIONS
	manifest.sample_spacing = SAMPLE_SPACING

	var save_error := baker.save_asset(asset, ASSET_PATH, manifest)
	if save_error != OK:
		return save_error
	return baker.save_manifest(manifest, MANIFEST_PATH)


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
