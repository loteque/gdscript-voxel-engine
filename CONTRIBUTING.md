# Contributing to GDScript Voxel Terrain

Thank you for contributing to GDScript Voxel Terrain. This project favors incremental development, explicit ownership, deterministic validation, and complete delivery over isolated implementation speed.

A substantial engine feature is not complete when its production code compiles. It is complete when its architecture, implementation, automated validation, human-visible validation, browser integration where applicable, and pull request evidence form one coherent package.

## Engineering Principles

### Preserve subsystem ownership

Keep responsibilities at their established boundaries:

- `PointFieldResource` owns scalar-field representation, sample geometry, densities, indexing, sampling, validation, serialization, and generation-time field logic.
- `SurfaceNetsMesher` consumes point fields and produces meshes.
- `ChunkAssetBaker` owns offline chunk asset creation and persistence.
- `TerrainChunkAsset` represents a precomputed chunk asset.
- `TerrainChunkManifest` catalogs precomputed chunk assets and their spatial metadata.
- `ChunkStreamer` owns runtime residency, loading execution, scheduling, and resident scene instances.
- Runtime streaming must not invoke point-field generation, Surface Nets, or another procedural mesh-generation fallback.

Do not move responsibilities across these boundaries merely to make an optimization or demo easier.

### Protect contracts before optimizing

Do not sacrifice established public contracts for performance. Prefer optimizations behind stable interfaces. If an optimization genuinely requires a contract change, make that change explicit and justify it separately.

Reuse authoritative configuration rather than copying it into consumers. Avoid duplicated topology, coordinate-conversion, field, or chunk-layout state.

### Design for likely extensions without speculative architecture

The engine is expected to grow toward larger streamed terrain, LOD, and potentially other meshers such as Dual Contouring. Keep those directions possible, but do not introduce abstractions solely for hypothetical future requirements.

Extract a new subsystem or abstraction only when it materially improves correctness, ownership, maintainability, performance, or extensibility.

## Common Library Promotion

The repository maintains a distinction between project-level code, reusable voxel-engine systems, and genuinely cross-project Godot components.

The intended dependency direction is:

```text
project / demos
        ↓
voxel terrain engine
        ↓
common library
```

Dependencies must not point upward through these layers.

Promote a component into the common library only when its demonstrated responsibility is genuinely project-independent. A strong candidate should be understandable and useful outside voxel terrain, avoid dependencies on terrain-specific types or assumptions, and retain validation that can be expressed independently of terrain behavior.

Do not promote code merely because it is reused within this repository. Scalar-field representation, terrain meshers, chunk assets, terrain manifests, and terrain streaming remain voxel-engine concerns even when they are reusable across voxel projects.

Do not use the common library as a generic `misc`, `shared`, or `utils` folder. Extraction should clarify ownership and establish one authoritative reusable capability rather than create parallel copies or broaden responsibilities to make a component appear generic.

Before extracting a component, inspect its current consumers and dependencies, confirm the cross-project contract, preserve appropriate validation, and update consumers to use the promoted component through its public API.

The durable architectural contract and promotion criteria are documented in `docs/architecture/common-library-contract.md`.

## GDScript Conventions

Follow the official Godot GDScript style guide.

Use `##` documentation comments for public APIs.

Use section headers in this form:

```gdscript
# [b]Section Name[/b]
# Short description of why the section exists.
```

Prefer explicit, coherent public APIs over validation or consumer code reaching into private implementation state.

## Branches and Pull Requests

Never develop a feature directly on `main`.

Create or use a branch named after the feature being developed, for example:

- `surface-nets-mesher`
- `point-field-api`
- `chunked-terrain`
- `async-chunk-loading`
- `chunk-load-priority`
- `chunk-residency-hysteresis`

Avoid generic names such as `changes`, `update`, or `fix` when a meaningful feature name exists.

Branch new milestones from the latest appropriate `main` unless the work explicitly depends on an unmerged branch.

Do not merge a pull request unless explicitly authorized. Keep substantial feature PRs in draft while required validation is incomplete. Mark them ready for review only after the applicable completion gates below have been satisfied.

## Feature Planning

Before changing production code for a substantial feature, establish a private completion checklist from the repository's current conventions.

Answer these questions up front:

1. What existing contract does this feature extend or change?
2. Which subsystem owns the new behavior?
3. What edge cases define correctness?
4. What failure and cancellation behavior is required?
5. How will the behavior be proven deterministically in headless tests?
6. How will a human observe the behavior in a validation scene?
7. Which existing Integration Preview should demonstrate it?
8. What version, changelog, CI, and publication requirements apply?
9. What evidence must exist before the PR is merge-ready?

Design validation at the same time as the production behavior rather than adding it after implementation.

A useful delivery model is:

```text
Production behavior
        ↓
Automated proof
        ↓
Human-visible proof
        ↓
Published browser proof
```

## Feature Completion Checklist

### Architecture

Before considering implementation complete, verify that:

- the correct subsystem owns the behavior;
- existing public APIs are reused where appropriate;
- authoritative configuration is not duplicated across systems;
- established contracts have not been weakened for optimization;
- runtime systems have not absorbed generation-time responsibilities;
- new abstractions exist only where they materially improve the design; and
- likely future extensions remain possible without prematurely implementing them.

### Implementation

Verify that:

- the public API is coherent and documented;
- important edge cases have been identified and handled;
- behavior is deterministic where practical;
- failure paths are explicit;
- cancellation paths are explicit where applicable;
- duplicate/idempotent operations behave coherently where applicable; and
- existing behavior remains compatible unless the feature deliberately changes a contract.

### Automated validation

Substantial features should include deterministic tests of observable contracts rather than tests coupled unnecessarily to private implementation details.

Add, as applicable:

- contract tests for the new behavior;
- regression tests for important edge cases;
- failure and cancellation tests;
- deterministic ordering or boundary tests;
- headless validation-scene coverage; and
- architecture guards that prevent prohibited runtime dependencies.

Tests and demos must exercise the real production code path. Do not create alternate implementations solely to make validation easier.

Run the relevant headless suite before declaring the feature complete. Inspect failures and correct the smallest underlying implementation, test, or infrastructure problem rather than weakening valid contracts to make CI pass.

## Validation Scenes

Every substantial engine feature must have a dedicated validation scene or update the existing validation scene for its subsystem before its PR is ready to merge.

A validation scene must:

- exercise the production public API and real runtime path;
- remain separate from the implementation it validates;
- make important state and behavior visible for manual QA;
- fail clearly when required configuration, data, or assets are missing;
- avoid duplicating production logic or creating demo-only engine paths; and
- include deterministic headless validation where practical.

Follow the established patterns used by `ChunkValidationDemo` and `ChunkStreamingValidationDemo`.

Validation UI may expose diagnostic state, but production systems should provide coherent read-only APIs for that state rather than allowing demo code to inspect private storage.

## GitHub Pages and Integration Preview

When a feature is suitable for browser validation, the GitHub Pages Integration Preview must expose the current behavior before the PR is considered complete.

Feature identity and validation-surface identity are different concepts:

```text
feature branch / PR identity
        ≠
validation subsystem identity
```

For example, `chunk-residency`, `async-chunk-loading`, `chunk-load-priority`, and later streaming milestones should normally evolve the same long-lived **Runtime Streaming Validation Demo**.

For runtime streaming work, update the existing Integration Preview at:

```text
preview/integration/streaming/
```

Do not create a feature-specific Pages category such as `/priority/` merely because a new feature has its own branch or validation work.

Add a new Pages demo category only when the feature introduces a genuinely distinct validation surface.

### Preserve deployment contracts

When updating Pages:

1. Export the applicable validation scene using the established Web export workflow.
2. Preserve the stable demo key and URL whenever practical.
3. Preserve all existing immutable release URLs.
4. Publish development behavior only to the mutable Integration Preview.
5. Keep the shared grouped demo selector and manifest integration intact.
6. Update `.github/scripts/build_demo_manifest.py` only when the demo catalog genuinely needs to change.
7. Add or update deployment regression tests when workflow routing changes.
8. Verify the actual published build rather than inferring publication from a successful source commit.

For threaded Web features, validate the browser runtime rather than merely checking that headless execution works. The streaming validation surface should retain useful runtime diagnostics such as Web thread prerequisites and worker-thread smoke validation when those remain relevant to the subsystem.

Be aware that service-worker caching can make an older Integration Preview appear current. When deployment evidence and visible browser behavior disagree, verify the deployed package and clear site/service-worker data before diagnosing the production engine path.

## Manual Browser QA

A successful Pages deployment is not equivalent to successful runtime validation.

Before calling a browser-demonstrable feature merge-ready:

- open the published Integration Preview;
- verify the expected validation UI is the current build;
- exercise the important behavior through the production API/runtime path;
- confirm required geometry or other visible output actually appears;
- confirm diagnostic state agrees with the visible behavior; and
- record or report the manual verification result.

If the published build has not been manually exercised, describe publication as complete but browser validation as outstanding.

## Performance and Scaling Evidence

Performance and scalability milestones must leave a durable evidence record under `docs/performance/` when their measurements materially inform later architecture or optimization work.

Use the conventions in `docs/performance/README.md`.

A performance report should record enough build, dataset, configuration, platform, and runtime context to make later comparisons meaningful. If a detail such as exact hardware was not recorded, say so rather than reconstructing it from memory.

Keep these categories explicit and separate:

```text
measured evidence
        ↓
engineering inference
        ↓
decisions
        ↓
open questions / next experiments
```

Do not present an estimate or hypothesis as a measurement. Preserve qualifiers such as `approximate`, and do not treat validation-oriented frame-time observations as laboratory-grade benchmarks.

When an earlier validation run is later found to contain a test or demo artifact, preserve the observation when it remains useful, explain the artifact, and identify the corrected run that should serve as the baseline.

For a substantial performance/scaling PR, merge readiness additionally requires that applicable measured findings and their architectural implications are recorded in `docs/performance/` before the milestone is considered complete.

## Versioning and Changelog

Substantial features may require a version change under the repository's established release policy. Keep version metadata synchronized wherever the project currently records it, including files such as `VERSION`, `project.godot`, splash/version metadata, and `CHANGELOG.md` when applicable.

Do not wait for release-validation CI to discover an obvious versioning requirement. Include version and changelog work in the feature's completion checklist from the beginning.

Preserve immutable published releases. Integration Preview builds are mutable; versioned release builds are not.

## Pull Request Completion

Before describing a substantial feature PR as **ready to merge**, verify all applicable gates:

- production implementation is complete;
- architectural boundaries remain intact;
- public APIs are documented and coherent;
- deterministic contract and regression tests pass;
- validation-scene coverage passes;
- the actual validation scene is exercised in CI where practical;
- required version and changelog changes are complete;
- applicable performance/scaling evidence is recorded under `docs/performance/`;
- the relevant Integration Preview contains the current feature behavior;
- the published browser build has been manually verified;
- all required CI checks are green; and
- the PR description explains both the architecture and the validation performed.

If only production implementation is complete, say so explicitly. For example:

> The production implementation is complete. Validation and Pages publication are still outstanding.

Do not describe a feature as complete merely because its code has been written.

## Pull Request Description

A substantial feature PR should explain:

- what changed;
- why the change belongs in the chosen subsystem;
- important design decisions and tradeoffs;
- contracts intentionally preserved or changed;
- edge cases addressed;
- automated tests added or updated;
- validation-scene behavior;
- performance/scaling evidence where applicable;
- GitHub Pages/Integration Preview status where applicable;
- manual browser QA status;
- version/changelog changes; and
- any known remaining work that is explicitly outside the PR's scope.

Keep future roadmap items separate from the current milestone. Do not expand a PR simply because adjacent work is obvious.

## Focused Milestones

Complete the requested milestone first. Point out architectural problems when they materially affect correctness, maintainability, performance, or extensibility, but avoid turning focused work into speculative redesign.

Typical streaming milestones should remain independently reviewable. For example:

```text
chunk residency
        ↓
asynchronous chunk loading
        ↓
priority / loading budgets
        ↓
residency hysteresis
        ↓
large single-LOD validation
        ↓
performance analysis
        ↓
LOD architecture
```

Do not pull later roadmap items such as hysteresis, LOD, predictive loading, or runtime procedural fallback into an earlier milestone unless they are required for correctness.

## Definition of Done

A successful substantial engine milestone arrives as one coherent package:

```text
architecture
    + implementation
    + tests
    + validation scene
    + performance evidence, when applicable
    + published browser QA, when applicable
    + green PR
```

End-to-end delivery is part of engineering correctness. Do not wait for the project owner to request the validation, publication, evidence recording, or CI work that is already implied by the feature.