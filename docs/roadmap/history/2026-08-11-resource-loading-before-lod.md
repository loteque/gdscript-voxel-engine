# Resource-Loading Analysis Before LOD

**Date:** 2026-08-11

## Prior roadmap direction

After residency, asynchronous loading, bounded scheduling, hysteresis, and a large single-LOD validation were complete, the project expected to move from performance analysis into LOD architecture.

## Evidence prompting reassessment

The 0.13.0 large single-LOD validation exercised a deterministic 169-chunk precomputed streaming fixture through the production runtime path.

The accepted mobile-Web observation recorded approximately:

- 32 resident chunks;
- 36 peak resident chunks;
- 86 completed loads;
- 0 failed loads;
- 0 cancelled pending loads;
- 2.22 seconds average load latency;
- 5.43 seconds maximum observed load latency;
- 0.39 MiB approximate resident mesh memory;
- 31.67 ms observed frame time; and
- 34.72 ms recent maximum observed frame time.

These values are environment-specific validation observations, not universal engine benchmarks. Full provenance and qualifications are recorded in `docs/performance/0.13.0-large-single-lod-validation.md`.

## Engineering inference

The measurements suggest that precomputed resource-loading throughput is the first material scaling pressure exposed by the current validation fixture.

The evidence does not yet isolate which part of the runtime asset-loading path accounts for the observed latency. It also does not demonstrate that LOD is the appropriate solution to that latency.

Resident mesh memory did not emerge as the dominant constraint in the available estimate, and the established residency, scheduling, and hysteresis behavior remained functionally sound under the corrected validation route.

## Roadmap adjustment

Defer LOD architecture until the project has better evidence about the runtime asset-loading constraint.

The next milestone is resource-loading analysis: determine where material loading latency is introduced, how platform-dependent the behavior is, and how loading concurrency affects throughput and responsiveness sufficiently to support an architectural decision.

After that analysis, record the resulting loading-architecture decision before proceeding to LOD architecture.

## Work deliberately deferred

- LOD architecture and implementation
- changes to terrain representation intended only to reduce the observed loading latency
- runtime procedural generation or meshing fallback
- speculative extraction or redesign of streaming subsystems without evidence that ownership or performance requires it

## Desired outcome of the next milestone

Produce enough evidence to decide whether the current loading architecture or asset representation should change before LOD work begins, while preserving uncertainty where the measurements do not isolate a cause.

The milestone should inform an implementation plan; this record intentionally does not prescribe that implementation.

## Related records

- `ROADMAP.md`
- `docs/performance/0.13.0-large-single-lod-validation.md`
- `docs/architecture/decisions/ADR-001-offline-runtime-terrain-boundary.md`