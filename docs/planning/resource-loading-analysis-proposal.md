# Proposal: Resource-Loading Analysis

**Status:** Proposed for architectural review

## Purpose

The current roadmap identifies precomputed resource-loading throughput as the first material scaling pressure observed by the large single-LOD validation. This proposal defines an investigation intended to determine where material latency is introduced in the runtime asset-loading path and to produce evidence for the subsequent loading-architecture decision.

This milestone is diagnostic. It should not begin from the assumption that `ChunkStreamer`, `ResourceLoader`, the serialized asset representation, Web deployment, scheduler configuration, or LOD is the cause or solution.

## Architectural constraints

The investigation preserves the accepted offline/runtime boundary in ADR-001:

```text
OFFLINE
PointFieldResource -> SurfaceNetsMesher -> ChunkAssetBaker -> TerrainChunkAsset -> TerrainChunkManifest

RUNTIME
TerrainChunkManifest -> ChunkStreamer -> resident MeshInstance3D
```

In particular:

- runtime procedural scalar-field generation remains out of scope;
- runtime Surface Nets or other runtime meshing remains out of scope;
- the manifest remains the catalog for precomputed chunk assets;
- residency, hysteresis, nearest-first scheduling, and loading budgets retain their current semantics unless evidence demonstrates a correctness problem;
- instrumentation must not create an alternate loading path;
- LOD design remains deferred until the loading analysis and resulting architectural decision are complete.

## Current evidence

The accepted 0.13.0 mobile-Web observation records approximately 2.22 seconds average load latency and 5.43 seconds maximum observed latency while corrected backpressured traversal produced zero failed loads and zero cancelled pending loads. Resident mesh memory did not emerge as the dominant observed constraint, and residency/scheduling behavior remained functionally coherent.

The current `ChunkStreamer` measures load latency from the successful start of `ResourceLoader.load_threaded_request()` until the loaded `TerrainChunkAsset` has been validated and accepted as a resident `MeshInstance3D`. That aggregate measurement is useful as a baseline but does not isolate which portion of the loading path dominates.

## Questions this work should answer

1. Where is material latency introduced between starting a threaded resource request and establishing normal resident chunk state?
2. How much of the observed latency and throughput is specific to Web, mobile Web, or a particular browser/device rather than the general runtime architecture?
3. How does configured loading concurrency affect completion throughput, latency, frame-time behavior, and scheduler utilization?
4. Is post-load resource validation and resident-instance creation material compared with waiting for the threaded resource load?
5. Does the evidence justify changing loading architecture, asset representation, scheduler policy, or platform strategy before LOD?
6. Which remaining uncertainties would materially affect the subsequent loading-architecture decision?

## Proposed investigation

### 1. Establish lifecycle measurement boundaries

Extend runtime observability only enough to separate meaningful phases already present in the production loading lifecycle. Candidate observations are:

```text
queued
  -> threaded request accepted
  -> ResourceLoader reports loaded/failed
  -> loaded resource retrieved and validated
  -> MeshInstance3D established as resident
```

The exact representation should be chosen after implementation review. Prefer a small extension of the existing read-only metrics/snapshot surface over a telemetry framework or mutable diagnostic state exposed to validation code.

The measurements should preserve the current public residency contract. Instrumentation should observe loading execution rather than become responsible for scheduling it.

### 2. Separate waiting time from completion work

The current aggregate load-latency metric spans both background resource loading and the synchronous completion path. Add enough observation to determine whether significant time is spent:

- waiting for `ResourceLoader.load_threaded_get_status()` to report completion;
- retrieving/validating the resulting `TerrainChunkAsset`;
- creating and attaching the resident `MeshInstance3D` and assigning its mesh.

Where a phase is too small or platform APIs do not permit meaningful isolation, record that limitation rather than manufacturing precision.

### 3. Run controlled concurrency experiments

Use the existing deterministic large single-LOD fixture and production streamer. Compare a small set of concurrency configurations while holding dataset, residency policy, traversal behavior, and per-frame start policy controlled where practical.

The experiment should observe at least:

- completed loads over an observation interval or equivalent throughput evidence;
- average and maximum aggregate load latency;
- separated lifecycle timing introduced by this milestone;
- queued/loading/resident counts;
- loading-capacity utilization;
- failures and logical cancellations;
- frame-time behavior;
- residency churn.

The purpose is to identify trends and saturation behavior, not to choose the largest concurrency value that produces the best isolated number.

### 4. Compare representative runtime environments

Where practical, repeat equivalent observations across:

- native desktop;
- desktop Web;
- mobile Web.

Record browser, device/platform, build/version, fixture configuration, residency radii, scheduler budgets, and relevant runtime conditions with each accepted observation.

Environment-specific measurements must remain labeled as such. If an environment cannot be measured comparably, preserve that limitation in the report.

### 5. Preserve the existing human-validation surface

Evolve `ChunkStreamingValidationDemo` and the stable `/streaming/` Integration Preview rather than creating a feature-specific Pages category.

The validation UI should expose only diagnostics needed to understand the investigation, such as current scheduler configuration, queue/loading/resident state, aggregate latency, newly separated loading-phase observations, and frame-time observations.

The existing Web thread/runtime smoke diagnostics and backpressured traversal behavior should remain intact unless the investigation establishes a reason to change them.

## Automated validation strategy

Tests should prove instrumentation and lifecycle accounting, not performance thresholds.

Expected contract coverage includes:

- new metrics begin in a coherent initial state;
- successful loads update the appropriate lifecycle observations exactly once;
- failures do not count as successful completions and free scheduler capacity as before;
- logical cancellation does not later produce resident state;
- metric snapshots do not mutate runtime state;
- reset behavior is coherent for any new cumulative metrics;
- existing nearest-first scheduling, load-start budgets, concurrency limits, hysteresis, and idempotency remain unchanged;
- the validation scene exposes the expected diagnostic state through production APIs;
- runtime continues to have no dependency on point-field generation, Surface Nets, or procedural runtime mesh generation.

Avoid brittle wall-clock performance assertions in CI. Timing tests should validate accounting relationships and non-negative/ordered observations where deterministic, not demand machine-specific latency ceilings.

## Experiment discipline

For every accepted measurement, distinguish:

```text
measured evidence
        ↓
engineering inference
        ↓
architectural implication
```

Do not infer a bottleneck merely because one aggregate metric is large. Do not compare measurements collected under materially different configurations without recording the difference.

The existing 0.13.0 report remains the baseline rather than being rewritten after new measurements are available.

## Deliverables

If this proposal is accepted, the implementation milestone should deliver:

1. narrowly scoped production-path instrumentation sufficient to decompose the current loading observation;
2. deterministic headless contract coverage for that instrumentation and unchanged streaming behavior;
3. an updated `ChunkStreamingValidationDemo` using the production metrics surface;
4. the updated stable `/streaming/` Integration Preview;
5. manually verified observations from representative environments where practical;
6. a new report under `docs/performance/` recording configuration, provenance, measurements, limitations, inference, and open questions;
7. a loading-architecture recommendation based on the evidence.

If that recommendation establishes or changes a durable engine contract, it should be recorded as an ADR. If the evidence materially changes development order, `ROADMAP.md` and roadmap history should be updated according to the repository planning discipline.

## Explicit non-goals

This proposal does not authorize:

- LOD architecture or implementation;
- runtime procedural generation or meshing;
- speculative replacement of Godot's resource loader;
- custom worker-thread infrastructure without evidence that the supported loading path is inadequate;
- asset-format redesign before measurements justify it;
- predictive, velocity, or frustum-weighted scheduling;
- broad extraction of `ChunkStreamer` responsibilities solely for aesthetic reasons;
- performance claims based on CI wall-clock timing.

## Decision requested from architecture review

Please review whether this investigation provides enough discrimination to support the roadmap's subsequent **Loading Architecture Decision** without prematurely prescribing a solution.

In particular, feedback is requested on:

- whether the proposed lifecycle boundaries are sufficient or too implementation-specific;
- whether the environment/concurrency matrix is adequate to distinguish platform behavior from architecture behavior;
- whether any measurement would materially improve the later LOD decision and is missing here;
- whether any proposed instrumentation risks weakening subsystem ownership or the accepted offline/runtime boundary.

No production implementation should begin from this proposal until the investigation scope is accepted or revised through review.