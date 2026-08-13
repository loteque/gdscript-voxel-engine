# Proposal: Resource-Loading Analysis

**Status:** Proposed for architectural review

## Purpose

The current roadmap identifies precomputed resource-loading throughput as the first material scaling pressure observed by the large single-LOD validation. This proposal defines an investigation intended to determine where material latency is introduced in the runtime asset-loading path and to produce evidence for the subsequent loading-architecture decision.

This milestone is diagnostic. It should not begin from the assumption that `ChunkStreamer`, Godot's supported resource-loading facilities, the serialized asset representation, Web deployment, scheduler configuration, or LOD is the cause or solution.

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

The current aggregate load-latency observation spans the period from active loading beginning until the precomputed chunk has been accepted into normal resident state. That baseline is useful but does not isolate whether the dominant cost is background resource loading, later completion work, asset-dependent work, platform overhead, or another factor.

## Questions this work should answer

1. Where is material observable time introduced between beginning an active precomputed chunk load and establishing normal resident chunk state?
2. How much of the observed latency and throughput is specific to Web, mobile Web, or a particular browser/device rather than the general runtime architecture?
3. How does configured loading concurrency affect completion throughput, latency, frame-time behavior, and scheduler utilization?
4. Is work after the background load becomes observable as complete material compared with the preceding loading wait?
5. Does load latency correlate materially with serialized chunk-asset size and/or mesh complexity?
6. For Web observations, how materially do first-load, repeated-load, or unknown cache conditions affect the measurements?
7. Does the evidence justify changing loading architecture, asset representation, scheduler policy, platform strategy, or the timing of LOD work?
8. Which remaining uncertainties would materially affect the subsequent loading-architecture decision?

## Proposed investigation

### 1. Establish discriminating observable boundaries

Collect only enough additional evidence to distinguish meaningful phases already present in the production loading lifecycle.

The investigation should be able to distinguish, where the runtime permits meaningful observation:

```text
request waiting to start
        ↓
active background loading
        ↓
background completion becomes observable to the streamer
        ↓
normal resident state established
```

These are evidence requirements, not a prescribed instrumentation design. The implementing engineer should inspect the current code and platform constraints and choose the smallest reliable measurement mechanism that preserves production ownership and does not create an alternate loading path.

If a boundary cannot be observed independently with useful precision, record that limitation rather than introducing artificial structure solely to make the measurement possible.

### 2. Determine whether completion work is material

Establish whether a material portion of aggregate latency occurs after background loading has become observably complete but before the chunk reaches normal resident state.

The investigation should answer whether that interval is negligible, material, or not meaningfully isolatable with the available runtime interfaces. It should not assume which completion sub-step is responsible unless the evidence actually discriminates between them.

### 3. Correlate latency with serialized asset size and mesh complexity

Treat asset-dependent cost as required evidence rather than assuming every chunk load has equivalent work.

For observed chunk loads, record enough immutable asset characteristics to evaluate whether latency or throughput correlates materially with factors such as:

- serialized chunk-asset size;
- mesh vertex count;
- mesh index/triangle count;
- another existing mesh-complexity measure if it better represents the current serialized assets.

The purpose is correlation, not asset-format optimization during this milestone.

This evidence is important to the later LOD decision. If materially smaller or simpler baked assets consistently load faster, LOD may influence streaming throughput as well as rendering cost. If latency is dominated by largely fixed or platform-specific overhead, that would point toward a different architectural response.

Do not infer causation from correlation alone.

### 4. Run controlled concurrency experiments

Use the existing deterministic large single-LOD fixture and production streamer. Compare a small set of concurrency configurations while holding dataset, residency policy, traversal behavior, and other relevant scheduling conditions controlled where practical.

The experiment should observe at least:

- completion throughput or equivalent completed-load evidence over a defined observation;
- average and maximum aggregate load latency;
- any discriminating lifecycle observations supported by the selected instrumentation;
- queued/loading/resident counts;
- loading-capacity utilization;
- failures and logical cancellations;
- frame-time behavior;
- residency churn;
- asset-size and mesh-complexity correlation.

The purpose is to identify trends and saturation behavior, not to select the largest concurrency value that produces the best isolated number.

### 5. Compare representative runtime environments

Where practical, repeat equivalent observations across:

- native desktop;
- desktop Web;
- mobile Web.

Record browser, device/platform, build/version, fixture configuration, residency radii, scheduler budgets, and other runtime conditions needed to interpret the observation.

For Web observations, also record cache provenance as one of:

- first-load / cold-ish condition;
- repeated / warm condition;
- unknown cache condition.

The investigation does not prescribe cache-clearing mechanics. The requirement is to preserve the condition so measurements collected under materially different cache states are not treated as directly equivalent.

Environment-specific measurements must remain labeled as such. If an environment cannot be measured comparably, preserve that limitation in the report.

The initial environment/concurrency matrix should remain intentionally small. Do not broaden it unless the observations reveal a question that materially requires another axis.

### 6. Preserve timing-resolution limitations

Any timing boundary inferred from periodic observation of asynchronous loading is measured at the observer's cadence, not necessarily at the exact instant background work completed.

Accepted measurements and the final report must state the effective timing-resolution limitation of the chosen observation method. Do not imply finer precision than the runtime exposes.

At the current multi-second mobile-Web baseline this may be a minor source of error, but it becomes more important if later observations become substantially shorter.

### 7. Preserve the existing human-validation surface

Evolve `ChunkStreamingValidationDemo` and the stable `/streaming/` Integration Preview rather than creating a feature-specific Pages category.

The validation UI should expose only enough diagnostic state for a human to understand the experiment and distinguish the important observations. The exact presentation and metrics surface should be selected during implementation after the instrumentation design is chosen.

The existing Web thread/runtime smoke diagnostics and backpressured traversal behavior should remain intact unless the investigation establishes a reason to change them.

## Automated validation strategy

Tests should prove instrumentation/accounting correctness and unchanged streaming contracts, not performance thresholds.

Expected contract coverage includes:

- new observations begin in a coherent initial state;
- successful loads update each relevant accounting value exactly once;
- failures do not count as successful completions and continue freeing scheduler capacity correctly;
- logical cancellation does not later produce resident state;
- read-only observations do not mutate runtime state;
- reset behavior is coherent for any new cumulative observations;
- asset characteristics used for correlation are reported consistently without changing runtime asset ownership;
- existing nearest-first scheduling, load-start budgets, concurrency limits, hysteresis, and idempotency remain unchanged;
- the validation scene exposes the intended diagnostic state through production APIs;
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

Do not infer a bottleneck merely because one aggregate metric is large. Do not compare measurements collected under materially different configurations or cache states without recording the difference.

Record relevant asset size/complexity alongside latency observations so later analysis can test whether the relationship is meaningful rather than relying on intuition.

Preserve the timing precision actually supported by the measurement method. If a boundary is polling-cadence limited, state that explicitly.

The existing 0.13.0 report remains the baseline rather than being rewritten after new measurements are available.

## Deliverables

If this proposal is accepted, the implementation milestone should deliver:

1. narrowly scoped production-path observability sufficient to discriminate the material loading intervals that the runtime can reliably expose;
2. evidence relating load behavior to serialized asset size and mesh complexity;
3. deterministic headless contract coverage for the observations and unchanged streaming behavior;
4. an updated `ChunkStreamingValidationDemo` using production observability;
5. the updated stable `/streaming/` Integration Preview;
6. manually verified observations from representative environments where practical, including Web cache-state provenance;
7. a new report under `docs/performance/` recording configuration, provenance, measurements, timing limitations, inference, and open questions;
8. a loading-architecture recommendation based on the evidence.

If that recommendation establishes or changes a durable engine contract, it should be recorded as an ADR. If the evidence materially changes development order, `ROADMAP.md` and roadmap history should be updated according to the repository planning discipline.

## Explicit non-goals

This proposal does not authorize:

- LOD architecture or implementation;
- runtime procedural generation or meshing;
- speculative replacement of Godot's supported resource-loading path;
- custom worker-thread infrastructure without evidence that the supported loading path is inadequate;
- asset-format redesign before measurements justify it;
- predictive, velocity, or frustum-weighted scheduling;
- broad extraction of `ChunkStreamer` responsibilities solely for aesthetic reasons;
- performance claims based on CI wall-clock timing;
- implementation structures introduced only to manufacture measurement boundaries.

## Decision requested from architecture review

Please review whether this revised investigation provides enough discrimination to support the roadmap's subsequent **Loading Architecture Decision** without prematurely prescribing a solution.

In particular, feedback is requested on:

- whether the required observable boundaries are sufficiently discriminating without prescribing instrumentation design;
- whether serialized asset size / mesh-complexity correlation is framed at the right level for the later LOD decision;
- whether the environment/concurrency matrix and Web cache provenance are adequate;
- whether the timing-resolution limitations are stated strongly enough;
- whether any remaining requirement risks weakening subsystem ownership or the accepted offline/runtime boundary.

No production implementation should begin from this proposal until the investigation scope is accepted or revised through review.