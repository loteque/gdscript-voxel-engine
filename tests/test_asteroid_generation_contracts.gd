extends SceneTree

const POINT_FIELD_RESOURCE := preload("res://voxel/field/PointFieldResource.gd")
const SURFACE_NETS_MESHER := preload("res://voxel/meshing/SurfaceNetsMesher.gd")
const TERRAIN_CHUNK_ASSET := preload("res://voxel/chunking/TerrainChunkAsset.gd")
const TERRAIN_CHUNK_MANIFEST := preload("res://voxel/chunking/TerrainChunkManifest.gd")
const TERRAIN_CHUNK_MANIFEST_ENTRY := preload("res://voxel/chunking/TerrainChunkManifestEntry.gd")
const CHUNK_ASSET_BAKER := preload("res://voxel/chunking/ChunkAssetBaker.gd")

var _failed: bool = false


func _initialize() -> void:
	_test_complete_density_installation()
	_test_surface_nets_rejects_stale_field_data()
	_test_manifest_coordinate_lookup_and_replacement()
	_test_chunk_asset_baking_and_serialization()

	if _failed:
		quit(1)
	else:
		print("Asteroid generation contract tests passed.")
		quit(0)


func _test_complete_density_installation() -> void:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(2, 2, 2)
	field.generate_positions()

	var values := PackedFloat32Array()
	values.resize(field.sample_count)
	for index in field.sample_count:
		values[index] = float(index)

	_assert_true(field.set_density_data(values), "Complete density data must be accepted.")
	_assert_true(field.is_data_current(), "Bulk density installation must make the field current.")
	values[0] = 999.0
	_assert_true(
		not is_equal_approx(field.densities[0], values[0]),
		"PointFieldResource must duplicate caller-owned density arrays."
	)

	var wrong_size := PackedFloat32Array([1.0, 2.0])
	_assert_true(
		not field.set_density_data(wrong_size),
		"Bulk density installation must reject incomplete channels."
	)


func _test_surface_nets_rejects_stale_field_data() -> void:
	var field := _make_plane_field()
	var mesher := SURFACE_NETS_MESHER.new()
	var current_mesh := mesher.generate_mesh(field)
	_assert_true(current_mesh.get_surface_count() == 1, "Current plane field must generate a mesh.")

	field.terrain_height_scale += 1.0
	_assert_true(field.densities_dirty, "Density configuration must mark the field stale.")
	var stale_mesh := mesher.generate_mesh(field)
	_assert_true(
		stale_mesh.get_surface_count() == 0,
		"Surface Nets must not consume structurally valid but stale field data."
	)


func _test_manifest_coordinate_lookup_and_replacement() -> void:
	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = Vector3i(16, 16, 16)
	manifest.sample_spacing = 2.0

	var first := TERRAIN_CHUNK_MANIFEST_ENTRY.new()
	first.chunk_coordinate = Vector3i(-2, 0, 3)
	first.asset_path = "res://generated/chunk_a.tres"
	first.bounds = AABB(Vector3(-64.0, 0.0, 96.0), Vector3(32.0, 32.0, 32.0))
	manifest.set_entry(first)

	_assert_true(manifest.has_entry(Vector3i(-2, 0, 3)), "Manifest must find negative coordinates.")
	_assert_true(manifest.find_entry(Vector3i(-2, 0, 3)) == first, "Manifest lookup must return the stored entry.")

	var replacement := TERRAIN_CHUNK_MANIFEST_ENTRY.new()
	replacement.chunk_coordinate = first.chunk_coordinate
	replacement.asset_path = "res://generated/chunk_b.tres"
	replacement.bounds = first.bounds
	manifest.set_entry(replacement)
	_assert_true(manifest.entries.size() == 1, "Coordinate/LOD replacement must not duplicate entries.")
	_assert_true(manifest.find_entry(first.chunk_coordinate) == replacement, "Replacement entry must win lookup.")
	_assert_true(manifest.is_valid(), "A structurally complete manifest must validate.")


func _test_chunk_asset_baking_and_serialization() -> void:
	var field := _make_plane_field()
	var baker := CHUNK_ASSET_BAKER.new()
	var coordinate := Vector3i(1, -1, 2)
	var origin := Vector3(8.0, -8.0, 16.0)
	var asset: TerrainChunkAsset = baker.build_asset(field, coordinate, origin)

	_assert_true(asset != null, "Current field data must produce a chunk asset.")
	if asset == null:
		return
	_assert_true(asset.chunk_coordinate == coordinate, "Chunk asset must preserve its lattice coordinate.")
	_assert_true(asset.local_origin.is_equal_approx(origin), "Chunk asset must preserve deterministic placement.")
	_assert_true(asset.mesh != null and asset.mesh.get_surface_count() == 1, "Chunk asset must contain render-ready mesh data.")
	_assert_true(asset.is_valid(), "Baked chunk asset must validate.")

	var manifest := TERRAIN_CHUNK_MANIFEST.new()
	manifest.chunk_cell_dimensions = field.cell_dimensions
	manifest.sample_spacing = field.sample_spacing
	var asset_path := "user://asteroid_generation_contract_chunk.tres"
	var manifest_path := "user://asteroid_generation_contract_manifest.tres"
	_assert_true(baker.save_asset(asset, asset_path, manifest) == OK, "Chunk asset serialization must succeed.")
	_assert_true(manifest.has_entry(coordinate), "Saving an asset must update the supplied manifest.")
	_assert_true(baker.save_manifest(manifest, manifest_path) == OK, "Manifest serialization must succeed.")

	var loaded_asset := ResourceLoader.load(asset_path) as TerrainChunkAsset
	var loaded_manifest := ResourceLoader.load(manifest_path) as TerrainChunkManifest
	_assert_true(loaded_asset != null and loaded_asset.chunk_coordinate == coordinate, "Serialized chunk assets must round-trip.")
	_assert_true(loaded_manifest != null and loaded_manifest.has_entry(coordinate), "Serialized manifests must round-trip.")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(asset_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(manifest_path))


func _make_plane_field() -> PointFieldResource:
	var field := POINT_FIELD_RESOURCE.new()
	field.cell_dimensions = Vector3i(4, 4, 4)
	field.sample_spacing = 1.0
	field.generate_positions()
	var values := PackedFloat32Array()
	values.resize(field.sample_count)
	for index in field.sample_count:
		values[index] = -field.positions[index].y + 0.25
	field.set_density_data(values)
	return field


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
