# GDScript Voxel Terrain Roadmap

This document records the current development direction of GDScript Voxel Terrain. It is intentionally mutable.

It is written for both human engineers and autonomous development agents. It provides enough context to develop an implementation plan, but does not prescribe implementation. Assume the reader is a competent professional who will inspect the current repository, evaluate alternatives, and choose an appropriate implementation.

Historical reasoning belongs in `docs/roadmap/history/`, durable architectural decisions belong in `docs/architecture/decisions/`, and measured scaling evidence belongs in `docs/performance/`.

## Project Goal

Build a robust procedural voxel terrain engine capable of representing and streaming a several-kilometer asteroid while preserving clean boundaries between scalar-field generation, meshing, offline asset production, and runtime streaming.

The current production architecture is:

```text
OFFLINE

PointFieldResource
    ↓
SurfaceNetsMesher
    ↓
ArrayMesh
    ↓
ChunkAssetBaker
    ↓
TerrainChunkAsset
    ↓
TerrainChunkManifest

RUNTIME

TerrainChunkManifest
    ↓
ChunkStreamer
    ├── residency policy
    ├── nearest-first scheduling
    ├── loading budgets
    ├── asynchronous loading
    ├── residency hysteresis
    └── resident MeshInstance3D instances
```

The offline/runtime boundary is intentional. Runtime streaming consumes precomputed terrain assets rather than invoking scalar-field generation or meshing.

## Completed Foundations

- [x] `PointFieldResource`
- [x] Surface Nets meshing
- [x] `ArrayMesh` generation
- [x] offline chunk baking
- [x] `TerrainChunkAsset`
- [x] `TerrainChunkManifest`
- [x] basic runtime chunk loading
- [x] target-relative chunk residency
- [x] asynchronous resource loading
- [x] nearest-first load prioritization
- [x] per-frame and concurrent loading budgets
- [x] spatial residency hysteresis
- [x] large single-LOD streaming validation
- [x] runtime streaming metrics
- [x] initial performance baseline

## Current Milestone: Resource-Loading Analysis

The large single-LOD validation identified precomputed resource-loading throughput as the first material scaling pressure observed by the current instrumentation.

Determine which parts of the runtime asset-loading path account for the observed latency and produce sufficient evidence to decide whether loading architecture, asset representation, platform behavior, or another factor should be addressed before LOD work begins.

Relevant evidence should be compared across representative runtime environments where practical, and should distinguish latency, throughput, frame-time effects, failures, cancellations, and scheduler behavior sufficiently to support an architectural decision.

The purpose of this milestone is diagnosis, not premature optimization.

### Desired outcome

Establish an evidence-backed understanding of the dominant runtime loading constraint and record the resulting architectural and roadmap implications.

### Questions to resolve

- Where is material latency introduced along the runtime asset-loading path?
- How much of the observed behavior is platform-specific?
- How does loading concurrency affect throughput and responsiveness?
- Does the evidence justify changing loading architecture or asset representation before LOD?
- Which uncertainties remain material to the next milestone?

## Next: Loading Architecture Decision

Use the resource-loading analysis to decide whether any change to loading architecture, asset representation, scheduling policy, or platform strategy is justified.

Preserve the offline/runtime contract unless measured evidence demonstrates that a deliberate contract change is necessary and worth its consequences.

The desired outcome is a documented decision, including a decision to make no architectural change if the evidence supports the current design.

## Next: LOD Architecture

Design LOD from measured runtime and asset constraints rather than assuming which problem LOD must solve.

The design must preserve the algorithm-independent scalar-field foundation, offline asset pipeline, manifest-driven runtime model, and bounded streaming behavior unless a separately recorded architectural decision changes those contracts.

Questions include chunk identity across LOD levels, residency and scheduling semantics, memory constraints, transition behavior, neighboring-LOD seams, and offline asset production.

The roadmap does not prescribe the implementation. The engineer responsible for the milestone should inspect the current system and produce an implementation plan from the accepted constraints and evidence.

## Next: Larger Volumetric Asteroid Validation

Validate the resulting architecture against a genuinely volumetric terrain dataset with materially larger world extent and viewing-distance variation.

The validation should answer whether sustained traversal, residency, asset loading, memory use, scheduling, and any LOD behavior remain controlled at the next scale.

Continue evolving the existing Runtime Streaming Validation surface where it remains the appropriate human-QA surface.

## Target: Several-Kilometer Asteroid

The major demonstration target is a complete streamed asteroid at several-kilometer scale.

Success means more than rendering the dataset once. The engine should support sustained traversal while runtime resource use, loading behavior, visual continuity, and validation remain controlled and observable.

## Future Meshing Work

Dual Contouring remains a planned future meshing option but is not currently on the critical path toward proving asteroid-scale streaming.

The scalar-field architecture should remain algorithm-independent so future meshers can consume `PointFieldResource` without redesigning the field representation.

## Roadmap Discipline

After a milestone produces meaningful architectural or performance evidence:

1. analyze the updated `main`;
2. record measured evidence without presenting inference as measurement;
3. add or supersede an ADR when a durable architectural decision changes;
4. add a roadmap history record when development priorities materially change; and
5. update this file to represent the resulting current plan.

These records answer different questions:

```text
ROADMAP.md
→ What are we doing now and next?

docs/roadmap/history/
→ Why did the roadmap change?

docs/architecture/decisions/
→ Why is the engine designed this way?

docs/performance/
→ What measurements informed those decisions?
```

Roadmap entries should describe the problem or opportunity, context and evidence, constraints, desired outcome, and unresolved questions. They should generally not prescribe files to modify, methods to add, classes to create, or algorithms to implement.

## Current Development Order

```text
Resource-loading analysis              ← CURRENT
        ↓
Loading architecture decision
        ↓
LOD architecture
        ↓
Larger volumetric asteroid validation
        ↓
Several-kilometer asteroid
        ↓
Further meshing / Dual Contouring
```

This ordering is expected to change when evidence justifies changing it.