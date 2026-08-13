# Mobile Web Resource-Loading Experiment

## Decision being tested

The native-headless and browser-headless experiments show that threaded `ResourceLoader` can scale with concurrency. The rendered Android/Firefox streaming matrix does not: traversal duration remains roughly flat while observed request latency grows with concurrency.

The next diagnostic question is therefore:

> Does direct threaded `ResourceLoader` still scale on the actual mobile browser/device when `ChunkStreamer`, residency policy, terrain traversal, and resident mesh creation are absent?

This experiment is designed to answer that single question before any production loading architecture is changed.

## Why this technique

The experiment reuses the same direct-loader implementation used by the automated browser-headless benchmark. That keeps the measured code path stable while changing the environment from desktop CI Chromium to the actual rendered mobile browser/device.

The diagnostic boundary is:

```text
actual mobile browser/device
        ↓
Godot threaded Web export
        ↓
Web virtual filesystem / pack access
        ↓
ResourceLoader threaded request + polling
        ↓
TerrainChunkAsset deserialization
```

It intentionally excludes:

```text
ChunkStreamer
residency policy
nearest-first scheduling
hysteresis
terrain target traversal
MeshInstance3D residency
representative terrain rendering load
```

This creates a high-information comparison with only one large class of variables changed: browser/device environment.

## Publication surface

The experiment is exposed beneath the existing Runtime Streaming Integration Preview rather than as a new demo category:

```text
preview/integration/streaming/resource-loader/
```

This is a diagnostic route, not a new long-lived validation identity. The stable `streaming` demo key and `preview/integration/streaming/` URL remain the subsystem's primary validation surface.

## Matrix

The page automatically runs the same controlled direct-loader matrix as CI:

- 24 deterministic LOD-0 `TerrainChunkAsset` resources from the production streaming fixture;
- concurrency values `1`, `2`, `4`, `8`;
- three repetitions per concurrency value;
- 12 total runs;
- real threaded `ResourceLoader.load_threaded_request()` / polling / `load_threaded_get()` behavior.

No performance thresholds are applied. A run is invalid only when experiment execution or resource loading fails.

## Operator workflow

1. Open the diagnostic route on the target mobile browser/device.
2. Leave the page active until the status reports completion.
3. Press **Export JSON**.
4. Send the exported JSON for analysis.
5. Use **Run Again** only when an additional repetition of the full matrix is intentionally desired.

The overlay uses large text and controls and is collapsible so the experiment remains accessible without permanently covering the Web surface.

## Cache provenance

The page does not claim to establish a laboratory-cold cache. Browser, service-worker, operating-system, Godot, and Web virtual-filesystem cache behavior may survive or vary between runs.

The exported payload retains the benchmark's cache limitation. When stricter cache comparison is required, the operator must clear site/browser storage before loading the page and record that procedure separately.

## Interpretation

Compare mobile direct-loader throughput and latency scaling with:

1. native headless direct/resource-loading evidence;
2. CI browser-headless direct-loader evidence;
3. rendered mobile `ChunkStreamer` matrix evidence.

Two outcomes matter most.

### Direct mobile loading scales

If batch throughput improves materially from concurrency `1 → 2 → 4 → 8`, then the mobile browser/device can execute the direct loading path concurrently. The seconds-long rendered streaming behavior must depend on interactions introduced by the production streaming/runtime environment, and the next experiment should isolate those interactions.

### Direct mobile loading does not scale

If throughput stays flat while request latency rises with concurrency, then the browser/device environment itself is the dominant differentiator from desktop headless Chromium. The next investigation should focus on mobile browser/platform behavior before changing `ChunkStreamer`.

## Architectural constraint

This experiment is validation infrastructure only. It does not alter `ChunkStreamer`, chunk assets, residency policy, scheduler semantics, or runtime generation boundaries. No production optimization should be made until this result is compared with the existing evidence set.
