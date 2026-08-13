# ChunkStreamer Request Lifecycle Trace

## Purpose

The direct mobile loading strategy comparison showed that real `TerrainChunkAsset` resources load synchronously in a few milliseconds and that threaded loading closely tracks trivial control resources when isolated. The rendered streaming matrix still reports hundreds or thousands of milliseconds between `load_threaded_request()` and `THREAD_LOAD_LOADED` observation.

This trace narrows that contradiction inside the real production streaming path. It does not introduce a second loader, change residency policy, or alter chunk ownership.

## Trace boundary

For every completed chunk request, `ChunkStreamer` records these production transitions:

```text
residency desires chunk
        ↓
request queued
        ↓
load_threaded_request() issued
        ↓
first status poll
        ↓
THREAD_LOAD_LOADED first observed
        ↓
load_threaded_get()
        ↓
asset validation
        ↓
MeshInstance3D setup
        ↓
scene attachment
        ↓
resident state commit
```

The trace exports monotonic microsecond timestamps, process-frame indices, phase durations, and queue/loading/resident counts captured at queue admission, request start, loader-completion observation, and resident commit.

The existing streaming matrix already exports `ChunkStreamer.get_completed_load_observations()`, so no alternate validation path is required. The same `1 / 2 / 4 / 8 × 3` mobile matrix remains the experiment runner.

## Fields added to each completed observation

Timing fields:

- `desired_usec` and `desired_frame`
- `queued_usec` and `queued_frame`
- `started_usec` and `started_frame`
- `first_status_poll_usec` and `first_status_poll_frame`
- `completion_observed_usec` and `completion_observed_frame`
- `resource_get_started_usec`
- `resident_commit_usec` and `resident_frame`
- `desired_to_queued_msec`
- `queue_wait_msec`
- `request_to_first_poll_msec`
- `first_poll_to_completion_msec`
- `loader_wait_msec`
- `resource_get_msec`
- `asset_validation_msec`
- `instance_setup_msec`
- `scene_attach_msec`
- `resident_commit_msec`
- `total_desired_to_resident_msec`

State snapshots:

- `queued_state`
- `started_state`
- `completion_observed_state`
- `resident_state`

Each state snapshot contains the queued, loading, and resident counts at that transition.

## Interpretation

If `desired_to_queued_msec` or `queue_wait_msec` dominates, the pressure is in admission or scheduling before the threaded request starts.

If `loader_wait_msec` dominates but the direct mobile strategy comparison remains fast, compare `request_to_first_poll_msec`, `first_poll_to_completion_msec`, frame indices, and poll counts. A large request-to-first-poll interval points to main-thread scheduling starvation before the streamer can observe the request. A large first-poll-to-completion interval means the request repeatedly reports `THREAD_LOAD_IN_PROGRESS` in the rendered runtime.

If loader timing remains small but post-completion phases grow, the synchronous residency path is implicated.

## Measurement limits

Godot does not expose the exact instant background resource work finishes. `completion_observed_usec` is therefore the first time the production streamer observes `THREAD_LOAD_LOADED`, not an internal loader-completion timestamp.

The state snapshots are observational and intentionally lightweight. They do not introduce a completed-resource holding queue, because doing so would alter the production behavior under investigation.

The trace should be interpreted together with the direct mobile strategy comparison and the existing rendered streaming matrix. No loading-architecture change should be made from an isolated trace.