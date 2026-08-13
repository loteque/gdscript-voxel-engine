class_name StreamingExperimentMatrix
extends Resource

## Describes a repeatable validation experiment without owning streaming behavior.
##
## The matrix is consumed by validation/demo runners. It deliberately contains only
## experiment configuration and provenance; ChunkStreamer remains unaware of benchmark
## orchestration and continues to own the production loading/residency path.


# [b]Identity[/b]
# Records stable human-readable provenance for exported experiment results.

## Stable name written into exported experiment evidence.
@export var matrix_name: String = "streaming experiment"

## Human-readable purpose and operating notes for the experiment.
@export_multiline var description: String = ""

## Cache-state provenance supplied by the operator.
## This is a label only; loading a matrix never clears browser or ResourceLoader caches.
@export_enum("unknown", "first-load / cold-ish", "repeated / warm") var cache_provenance: String = "unknown"


# [b]Streaming Configuration[/b]
# Defines the controlled variables applied through normal ChunkStreamer APIs.

## Concurrency values executed in order.
@export var concurrency_values: PackedInt32Array = PackedInt32Array([1, 2, 4, 8])

## Number of repetitions performed for each concurrency value.
@export_range(1, 32, 1) var repetitions_per_concurrency: int = 3

## Admission radius used for every run in the matrix.
@export_range(0, 16, 1) var load_radius: int = 2

## Retention radius used for every run in the matrix.
@export_range(0, 16, 1) var unload_radius: int = 3

## Maximum queued loads started by ChunkStreamer per process update.
@export_range(1, 64, 1) var max_load_starts_per_frame: int = 2


# [b]Traversal[/b]
# Defines deterministic target coordinates and settling behavior for each run.

## Chunk coordinates visited in order during every repetition.
@export var waypoint_coordinates: Array[Vector3i] = []

## Number of pending-free process frames required before advancing to the next waypoint.
@export_range(1, 30, 1) var settle_frames: int = 2


# [b]Queries[/b]
# Provides validation-friendly derived values without exposing mutable runner state.

## Returns the total number of runs represented by this matrix.
func get_run_count() -> int:
	return concurrency_values.size() * repetitions_per_concurrency


## Returns an empty string when the matrix is runnable, otherwise a concise error.
func get_validation_error() -> String:
	if matrix_name.strip_edges().is_empty():
		return "matrix_name must not be empty"
	if concurrency_values.is_empty():
		return "concurrency_values must not be empty"
	for concurrency in concurrency_values:
		if concurrency <= 0:
			return "concurrency values must be greater than zero"
	if repetitions_per_concurrency <= 0:
		return "repetitions_per_concurrency must be greater than zero"
	if unload_radius < load_radius:
		return "unload_radius must be greater than or equal to load_radius"
	if max_load_starts_per_frame <= 0:
		return "max_load_starts_per_frame must be greater than zero"
	if waypoint_coordinates.is_empty():
		return "waypoint_coordinates must not be empty"
	if settle_frames <= 0:
		return "settle_frames must be greater than zero"
	return ""
