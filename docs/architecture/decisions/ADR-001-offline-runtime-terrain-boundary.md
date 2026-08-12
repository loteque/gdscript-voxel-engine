# ADR-001: Keep Procedural Terrain Generation Offline

**Status:** Accepted

## Context

The project separates scalar-field generation and meshing from runtime chunk residency. `PointFieldResource`, `SurfaceNetsMesher`, and `ChunkAssetBaker` form the generation path, while runtime streaming consumes assets cataloged by `TerrainChunkManifest`.

The several-kilometer asteroid goal requires runtime behavior to scale independently from the cost and complexity of procedural field generation and meshing.

## Evidence and constraints

The current streaming milestones have established that precomputed chunks can be loaded, scheduled, retained, and unloaded without invoking the generation pipeline at runtime.

The 0.13.0 large single-LOD validation further established a working 169-chunk precomputed streaming fixture and identified resource-loading throughput as the first material scaling pressure observed by the available instrumentation. See `docs/performance/0.13.0-large-single-lod-validation.md`.

That evidence does not establish a need to move procedural generation into runtime.

## Decision

Procedural scalar-field generation and terrain meshing remain offline responsibilities.

Runtime terrain streaming consumes precomputed terrain assets through the manifest and streamer architecture. Runtime procedural generation or meshing is not a fallback for solving streaming-performance problems unless a future architectural decision explicitly supersedes this record.

## Consequences

- Generation and runtime performance can be reasoned about independently.
- `PointFieldResource` and mesher contracts remain free of runtime residency concerns.
- Runtime optimization should first address measured runtime constraints behind existing contracts.
- Offline storage and asset-production costs remain relevant tradeoffs as terrain scale and LOD grow.
- A future change to runtime procedural generation would be an architectural change, not an incidental optimization.

## Alternatives considered

### Runtime field generation and meshing

This could reduce reliance on precomputed assets in some future designs, but it would introduce generation cost and additional ownership into the runtime path. Current evidence does not justify that tradeoff.

### Hybrid procedural fallback

A fallback could hide missing or slow assets, but it would create a second terrain-production path with different performance and correctness characteristics. Current project goals favor validating and improving the precomputed streaming architecture first.

## Related records

- `ROADMAP.md`
- `docs/performance/0.13.0-large-single-lod-validation.md`
- `docs/roadmap/history/2026-08-11-resource-loading-before-lod.md`