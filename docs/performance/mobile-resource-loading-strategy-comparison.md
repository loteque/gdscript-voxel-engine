# Mobile Resource-Loading Strategy Comparison

## Question

The rendered streaming trace showed long `THREAD_LOAD_IN_PROGRESS` intervals while post-load residency work stayed sub-millisecond. Direct mobile loading, however, previously scaled well. This comparison determines whether the slow interval is specific to threaded terrain loading, generic threaded loading, or terrain resource deserialization/dependencies.

## Controlled comparison

The experiment runs in one mobile Web session and compares four paths over 24 resources, three repetitions each:

1. `terrain_sync`: real `TerrainChunkAsset` files through `ResourceLoader.load()`;
2. `terrain_threaded`: the same terrain files through threaded loading at concurrency 1 and 4;
3. `control_sync`: trivial `Resource` files with no mesh dependency through synchronous loading;
4. `control_threaded`: the same trivial controls through threaded loading at concurrency 1 and 4.

All loads use `CACHE_MODE_IGNORE` for the resource under test. External dependencies may still reuse Godot cache state, which is recorded as a limitation. Synchronous loads yield one process frame between assets so the browser remains interactive; the timed call itself remains synchronous.

## Interpretation

- Terrain threaded slow, terrain synchronous fast, controls fast: threaded scheduling/interaction is implicated.
- Terrain threaded and control threaded slow, synchronous paths fast: generic threaded Web scheduling is implicated.
- Terrain slow in both sync and threaded, controls fast: terrain serialization or external mesh dependency loading is implicated.
- All four paths fast: the slow behavior requires the surrounding rendered streaming lifecycle and must be isolated there.
- All four paths slow: investigate broader Web runtime/device contention before changing terrain architecture.

Do not change production loading architecture from a single comparison. Combine this evidence with the direct-loader and production-streamer traces.

## Human run

The published diagnostic lives beneath the existing streaming Integration Preview at `preview/integration/streaming/resource-loader/strategy-comparison/`. Let the automated run complete in the foreground, export the JSON, and preserve that file as the experiment record.
