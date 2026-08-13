# ChunkStreamer Lifecycle Timing Experiment

## Purpose

The resource-loading investigation now has two controls that materially narrow the bottleneck:

- direct threaded `ResourceLoader` scales in browser-headless Chromium;
- direct threaded `ResourceLoader` also scales on the affected Android/Firefox device.

The remaining unexplained behavior appears only in the rendered production streaming path. This experiment therefore instruments that path rather than introducing another loader implementation.

The goal is to locate where elapsed time enters this lifecycle:

```text
residency admission
    ↓
queued request
    ↓
threaded request start
    ↓
ResourceLoader completion first observed
    ↓
load_threaded_get
    ↓
asset validation
    ↓
MeshInstance3D construction and configuration
    ↓
scene-tree attachment
    ↓
resident state commit
```

## Measurement design

`ChunkStreamer` remains the owner of the production lifecycle. It records bounded, read-only observations because only the streamer can observe these boundaries without validation code reaching into private dictionaries.

Each completed observation records:

- queue wait: accepted request to threaded request start;
- loader wait: threaded request start to `THREAD_LOAD_LOADED` first observed;
- `load_threaded_get()` duration;
- asset validation duration;
- `MeshInstance3D` construction/configuration duration;
- `add_child()` duration;
- resident-state commit duration;
- synchronous completion duration;
- total request duration from queue admission to resident commit;
- number of polling observations while `THREAD_LOAD_IN_PROGRESS`;
- process-frame indices for request start, completion observation, and resident commit;
- baked asset size and mesh counts.

Microsecond monotonic timestamps are used for the synchronous phases so sub-millisecond work does not collapse to zero. The timestamps remain validation observations, not profiler-grade instrumentation.

The existing aggregate metrics are preserved for compatibility. Their historical `background_wait` field remains equivalent to request-start through first-observed loader completion. The new lifecycle fields make that boundary explicit.

## Experiment execution

The existing `ChunkStreamingValidationDemo` matrix remains the experiment runner. It continues to execute the deterministic waypoint path for concurrency values `1 / 2 / 4 / 8`, three repetitions each, through the real `ChunkStreamer` and real resident meshes.

No alternate streaming path is introduced.

The matrix JSON export now includes the richer per-load lifecycle observations automatically. The existing stable streaming Integration Preview remains the human validation surface.

## Interpretation

The important comparison is between the direct mobile loader experiment and this rendered production-streamer trace.

If `loader_wait_msec` remains tens of milliseconds while `queue_wait_msec` grows into seconds, scheduling/admission is the dominant delay.

If `loader_wait_msec` grows into hundreds or thousands of milliseconds only in the rendered streamer, the same loader is being slowed or starved by the surrounding runtime workload.

If `load_threaded_get_msec`, instance construction, scene attachment, or resident commit becomes large, synchronous main-thread integration is implicated.

If all individual phases remain small but total waypoint settlement remains large, investigate request turnover, frame cadence, and scheduler throughput rather than individual chunk integration.

## Measurement limits

`ResourceLoader` does not expose the exact instant background work finishes. `loader_wait_msec` therefore ends when `ChunkStreamer` first observes `THREAD_LOAD_LOADED`, and can include up to the polling cadence plus any period in which the main thread did not poll.

That ambiguity is intentional and recorded. The direct mobile loader experiment provides the independent baseline needed to interpret it.

Do not optimize production behavior from one trace. Compare repetitions and concurrency levels, distinguish measured evidence from inference, and use the combined evidence to make the loading-architecture decision.
