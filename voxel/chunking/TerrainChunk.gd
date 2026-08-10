@tool
class_name TerrainChunk
extends Node3D

## Runtime container for one chunk of terrain field data.
##
## A chunk owns its [PointFieldResource] instance and its location in the chunk
## lattice. It does not own density-generation policy, meshing algorithms,
## streaming decisions, or neighbor lifecycle. Those responsibilities remain in
## the field resource, mesher, and chunk manager respectively.


# [b]Chunk State[/b]

## Integer coordinate identifying this chunk within its manager's chunk lattice.
var chunk_coordinate: Vector3i = Vector3i.ZERO

## Scalar field sampled for this chunk. Meshers consume this resource directly.
var point_field: PointFieldResource


# [b]Configuration[/b]

## Configures this chunk around [param sampling_center] in terrain sampling space.
##
## The node is placed at the same center in its parent's local space, so field
## positions remain chunk-local while density generation samples a continuous
## coordinate system through [member PointFieldResource.sampling_origin].
func configure(
	coordinate: Vector3i,
	field: PointFieldResource,
	sampling_center: Vector3
) -> void:
	chunk_coordinate = coordinate
	point_field = field
	position = sampling_center

	if point_field != null:
		point_field.sampling_origin = sampling_center


# [b]Generation[/b]

## Regenerates this chunk's scalar field without taking ownership of meshing.
func regenerate_field() -> void:
	if point_field == null:
		push_error("TerrainChunk requires a PointFieldResource before regeneration.")
		return
	point_field.regenerate()
