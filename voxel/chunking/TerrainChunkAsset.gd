class_name TerrainChunkAsset
extends Resource

## Serializable output of the offline terrain-generation pipeline.
##
## The asset contains render-ready mesh data plus enough spatial metadata for a
## runtime streamer to place it without reconstructing scalar-field state.


# [b]Identity[/b]
# Locates this asset in the deterministic chunk lattice.

## Integer coordinate of this chunk in terrain chunk space.
@export var chunk_coordinate: Vector3i = Vector3i.ZERO

## LOD level represented by this asset. Level zero is full resolution.
@export var lod_level: int = 0


# [b]Geometry[/b]
# Describes placement and source sampling geometry.

## Terrain-local minimum corner of the chunk.
@export var local_origin: Vector3 = Vector3.ZERO

## Number of logical cells represented by the source field.
@export var cell_dimensions: Vector3i = Vector3i.ZERO

## Distance between adjacent source-field samples.
@export var sample_spacing: float = 1.0

## Render-ready mesh generated from the chunk-local scalar field.
@export var mesh: ArrayMesh

## Terrain-local bounds used for coarse visibility and streaming decisions.
@export var bounds: AABB


# [b]Validation[/b]
# Checks only serialized asset invariants, not runtime streaming policy.

## Returns whether this asset contains enough information to be streamed.
func is_valid() -> bool:
	return (
		mesh != null
		and cell_dimensions.x > 0
		and cell_dimensions.y > 0
		and cell_dimensions.z > 0
		and sample_spacing > 0.0
		and bounds.size.x > 0.0
		and bounds.size.y > 0.0
		and bounds.size.z > 0.0
	)
