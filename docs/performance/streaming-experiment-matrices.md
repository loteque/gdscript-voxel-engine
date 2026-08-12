# Streaming Experiment Matrices

## Purpose

Streaming experiment matrices provide a repeatable way to run controlled browser and native validation experiments without asking a human operator to manually reset, reconfigure, record, and transcribe every run.

The system exists to answer performance questions with reproducible evidence while preserving the production streaming architecture.

The ownership boundary is:

```text
StreamingExperimentMatrix
    ↓
ChunkStreamingValidationDemo
    ↓
ChunkStreamer public configuration and runtime path
    ↓
TerrainChunkManifest / ResourceLoader / MeshInstance3D
```

`StreamingExperimentMatrix` describes what to run. The validation demo owns experiment orchestration and evidence capture. `ChunkStreamer` remains unaware of experiment matrices and continues to own only production residency, scheduling, asynchronous loading, and resident scene instances.

## Why we chose a resource-driven matrix

The first resource-loading measurements were collected manually from the Web validation demo. That was sufficient to establish that mobile-Web resource loading differed dramatically from native headless loading, but it made controlled repetitions tedious and introduced avoidable operator error.

We considered an accumulating `Add Run` button, but chose a resource-driven automated matrix instead because it gives stronger provenance and repeatability:

- every controlled variable is serialized with the experiment definition;
- run order cannot accidentally drift halfway through a measurement series;
- repetitions and concurrency sweeps are automatic;
- the same deterministic target waypoints can be shared conceptually with headless experiments;
- exported evidence contains both the matrix definition and measured results;
- validation orchestration remains outside production runtime classes;
- new experiment matrices can be added without changing `ChunkStreamer`.

This is intentionally a small validation facility, not a general benchmark framework. We should only add matrix fields when a real experiment requires them.

## Matrix resource

The resource type is:

```text
res://demo/experiments/StreamingExperimentMatrix.gd
```

A matrix records:

- stable experiment name and description;
- operator-supplied cache provenance;
- concurrency values;
- repetitions per concurrency value;
- load radius;
- unload radius;
- per-frame load-start budget;
- deterministic chunk-coordinate waypoints;
- the number of pending-free frames required before a waypoint is considered settled.

The checked-in Web baseline is:

```text
res://demo/experiments/mobile_web_warm_matrix.tres
```

It runs:

```text
1 concurrent × 3 repetitions
2 concurrent × 3 repetitions
4 concurrent × 3 repetitions
8 concurrent × 3 repetitions
```

using the same eleven chunk-coordinate waypoints as the automated native-headless resource-loading experiment.

## Cache provenance

Cache provenance is a label, not a cache-control mechanism.

The matrix runner must not claim to clear browser, service-worker, operating-system, or `ResourceLoader` caches. In particular, a twelve-run matrix cannot make every repetition a genuinely first-load run inside one browser process.

For the checked-in automated matrix, use:

```text
repeated / warm
```

A cold-ish observation still requires an operator-controlled browser reset/reload procedure and should be recorded separately with that limitation stated explicitly.

## Browser workflow

1. Open the Runtime Streaming Integration Preview.
2. Confirm the thread smoke check passes.
3. Allow any initial streaming work to settle.
4. Press **Run Experiment Matrix**.
5. Do not change cache provenance, concurrency, residency settings, or target motion while the matrix is running. Those controls are locked by the runner.
6. The runner automatically executes each concurrency/repetition pair and visits every configured waypoint.
7. When the status reports the matrix complete, press **Export Experiment**.
8. Send or archive the downloaded JSON file as the raw experiment evidence.

The operator may collapse the demo UI while the matrix runs. Collapsing validation overlays does not alter experiment state.

## Run lifecycle

Each run follows this validation-only sequence:

```text
apply matrix configuration
    ↓
clear resident/pending chunks through ChunkStreamer APIs
    ↓
reset streaming metrics
    ↓
move target to first matrix waypoint
    ↓
wait for pending work to settle
    ↓
record waypoint observation
    ↓
advance through remaining waypoints
    ↓
record run result
    ↓
advance repetition / concurrency
```

The runner uses the normal `ChunkStreamer` target, residency, asynchronous loading, and metrics APIs. It does not generate point fields, invoke Surface Nets, create alternate resource-loading paths, or bypass scheduler budgets.

## Exported evidence

The JSON export contains:

- schema version;
- experiment identity;
- complete matrix definition;
- Godot/runtime/browser environment information where available;
- expected and completed run counts;
- whether the full matrix completed;
- one record for every completed run;
- cumulative streamer metrics for each run;
- per-load observations;
- per-waypoint settle observations;
- peak queued/loading counts;
- observed peak frame time;
- explicit measurement limitations.

The export is raw evidence. Durable engineering conclusions should still be summarized in `docs/performance/` with measured evidence kept separate from engineering inference.

## Rendering and timing limits

The Web matrix runs in the real rendered browser demo, so it captures the browser/runtime conditions that native headless execution cannot reproduce. Its frame-time values are useful comparative diagnostics, but they are not a substitute for a GPU profiler or laboratory benchmark.

`ChunkStreamer` resource-completion timing remains polling-cadence observed. The exported report therefore records these values as comparative observations rather than profiler-precise timing boundaries.

## Tests

`tests/test_streaming_experiment_matrix.gd` verifies both the serialized baseline matrix and the runner contract.

The test checks that:

- the baseline matrix contains the intended `1 / 2 / 4 / 8 × 3` sweep;
- the established residency and scheduler configuration is preserved;
- the Web matrix uses the same eleven waypoints as the headless experiment;
- a minimal matrix can run through the real `ChunkStreamer` production path;
- completed results are accumulated;
- exported payloads include matrix provenance and completion state.

Performance values are deliberately not asserted as CI thresholds. Correctness is deterministic; timing on shared CI runners is not.

## Extension rule

Prefer adding a new `.tres` matrix when a future controlled experiment needs a different set of parameters. Do not add experiment concepts to `ChunkStreamer` merely because validation needs another matrix dimension.

If the matrix system grows enough that orchestration itself becomes difficult to maintain or test, evaluate extracting a dedicated validation runner. Do not introduce that abstraction preemptively.
