# Changelog

All notable changes to this project are recorded here by project version.

## 0.9.0

### Added
- Added deterministic target-relative chunk residency to `ChunkStreamer`, including a configurable chunk-coordinate radius and an optional `Node3D` target.
- Added manifest-derived chunk coordinate conversion with floor semantics for negative coordinates, exact boundaries, non-unit sample spacing, and non-cubic chunk dimensions.
- Expanded the Chunk Streaming Validation Demo into a moving-target residency proof backed by a deterministic `5 x 1 x 5` region of precomputed noise-generated terrain chunks.
- Added headless coverage for residency radius zero and one, target transitions, unload behavior, duplicate updates, sparse manifests, coordinate conversion, and runtime generation-layer separation.

### Changed
- Runtime residency policy now composes the existing explicit `load_chunk()`, `unload_chunk()`, and `is_chunk_loaded()` APIs rather than duplicating chunk-loading behavior.
- The existing GitHub Pages Chunk Streaming demo keeps its stable selector key and URL while demonstrating camera-relative residency instead of only single-chunk load/unload.

## 0.8.0

### Added
- Added serialized terrain chunk assets and manifests for precomputed runtime terrain data.
- Added `ChunkStreamer` as the runtime owner for loading, unloading, and tracking baked chunk residency without invoking terrain generation or meshing.
- Added the Chunk Streaming Validation Demo and exposed it as a third selectable GitHub Pages demo for immutable releases and the mutable Integration Preview.
- Added a deterministic noise-backed streaming demo bake that runs through the real `PointFieldResource` → Surface Nets → chunk asset pipeline before validation and Web export.
- Added automated coverage for manifest lookup, serialized chunk loading, duplicate residency protection, unload/reload behavior, streaming architecture boundaries, and the web-demo manifest/deployment wiring.

### Changed
- The GitHub Pages demo catalog now includes Terrain / Surface Nets, Chunk Validation, and Chunk Streaming demos while preserving existing versioned URLs.
- Integration and release validation now exercise the baked chunk streaming path using reproducible procedural terrain data.

## 0.7.0

### Added
- Added touchscreen runtime controls for free-fly camera movement, sprinting, vertical movement, and drag-to-look input.
- Added automatic touch-device visibility and headless regression coverage for shared movement actions, touch look, and touchscreen detection.

### Changed
- `NoClipCameraController` now exposes a small reusable look-delta API so non-mouse input can share the existing sensitivity and pitch constraints.

## 0.6.1

### Added
- Added authoritative x-fastest cell indexing helpers to `PointFieldResource`, including inverse cell-coordinate lookup.

### Changed
- `SurfaceNetsMesher` now consumes the resource-owned cell indexing contract instead of maintaining a duplicate private mapping.

## 0.6.0

### Added
- Added editor/runtime chunk visualization for planned chunk bounds, loaded chunk bounds, chunk centers, and full-resolution editor wireframe terrain previews.
- Added `ChunkValidationDemo` as a discoverable validation harness with top-level terrain controls, an explicit Regenerate Terrain action, immediate startup preview, and budgeted runtime chunk generation.
- Added headless validation for chunk visualization and the complete chunk validation scene startup/generation path.
- Added a second versioned web demo for `ChunkValidationDemo` at `/<version>/chunks/`.
- Added a grouped demo/version catalog generated from the immutable GitHub Pages archive.

### Changed
- Runtime validation generation now uses a configurable per-frame time budget instead of yielding after every chunk.
- Explicit chunk regeneration suppresses duplicate automatic mesh rebuild scheduling so each generation pass builds each mesh once.
- The deployed web selector is now a wider grouped demo/version dropdown while preserving existing version-root terrain demo URLs.

## 0.5.0

### Added
- Added `TerrainChunk` as the runtime owner for one integer chunk coordinate and its independent `PointFieldResource` sample storage.
- Added `ChunkManager` for deterministic chunk lifecycle, chunk-coordinate mapping, negative-coordinate handling, terrain-local placement, centered fixed-grid creation, and explicit batch regeneration.
- Added `PointFieldResource.sampling_origin` so chunk-local sample geometry can evaluate one continuous terrain density space.
- Added `ChunkSurfaceNetsDisplay` as a chunk-aware presentation consumer that creates one ordinary `SurfaceNetsMeshDisplay` per managed chunk without making `SurfaceNetsMesher` chunk-aware.
- Added headless chunk-foundation tests covering coordinate mapping, cells-versus-samples dimensions, field ownership, shared generation configuration, and adjacent-boundary continuity.
- Added a headless `3x1x3` Surface Nets chunk-grid integration test covering chunk creation, per-chunk mesh generation, display ownership, and X/Z shared-density continuity.

### Changed
- Chunk fields now copy terrain-generation settings explicitly instead of duplicating an entire `PointFieldResource`, keeping generated sample storage independent while intentionally sharing generator resources such as `FastNoiseLite`.
- Density generation now evaluates local sample positions through `sampling_origin`, allowing adjacent chunks to produce identical density values at shared sample coordinates.

## 0.4.2

### Added
- Added a reusable lit demo terrain material for Surface Nets presentation.
- Added directional lighting to the demo scene so generated terrain responds visibly to surface normals and scene illumination.

### Changed
- `SurfaceNetsMeshDisplay` now owns an overridable presentation material while `SurfaceNetsMesher` remains geometry-only.
- Demo lighting remains owned by `VoxelTerrainDemo.tscn` rather than the reusable terrain components.

## 0.4.1

### Added
- Added a bottom-center animated loading indicator for point-field regeneration and Surface Nets mesh rebuilding.
- Added headless UI smoke coverage for loading-state behavior, automatic terrain edits, Surface Nets enablement, and committed numeric editing.

### Changed
- Runtime generation controls now enter the same observable regeneration path as explicit generation actions so loading state is reported consistently.
- Surface Nets mesh rebuilding yields a rendered frame after entering loading state so the indicator is visible before synchronous meshing begins.
- Numeric text edits now commit on Enter or focus loss instead of regenerating terrain for every typed character; spinner adjustments remain immediate.

## 0.4.0

### Added
- Added explicit `positions_dirty` and `densities_dirty` state tracking to `PointFieldResource` so generated channel freshness is no longer inferred from array sizes.
- Added `data_state_changed` and `is_data_current()` for consumers to observe field freshness directly.
- Added headless state-transition and integration regression tests for point-field regeneration and Surface Nets synchronization.

### Changed
- Point-field configuration changes now preserve stale generated arrays while marking the affected channels dirty.
- Position regeneration explicitly marks dependent density data dirty until densities are regenerated.
- Re-enabling automatic regeneration now synchronizes already-dirty field state.
- `SurfaceNetsMeshDisplay` preserves its current mesh while source field data is dirty and rebuilds only when the field becomes current.

## 0.3.0

### Added
- Added explicit terrain density semantics: density above the iso-level is solid, density below it is empty, and the iso-level itself is the surface.
- Added `terrain_base_height` and `terrain_height_scale` controls to `PointFieldResource` and the runtime point-field panel.
- Added deterministic headless tests for flat-ground orientation and outward-facing closed-volume normals.

### Changed
- Default density generation now produces height-field terrain from X/Z noise with +Y as world up instead of sampling unconstrained 3D noise volumes.
- `SurfaceNetsMesher` winding and generated normals now point from solid material toward empty space.
- Headless validation now runs surface-orientation regression tests before starting the demo scene.

## 0.2.0

### Added
- Added `SurfaceNetsMesher` as a stateless consumer of `PointFieldResource` for generating terrain `ArrayMesh` geometry.
- Generates one averaged iso-surface intersection vertex per active field cell and stitches neighboring cells into indexed surface topology.
- Generates smooth area-weighted vertex normals for Surface Nets meshes.
- Added `SurfaceNetsMeshDisplay` as an independent mesh consumer that rebuilds from point-field changes only while visible.
- Added a `Surface Nets Mesh` checkbox to the existing runtime visualization controls and synchronized its iso level with the point-field density viewer.

## 0.1.3

### Fixed
- Isolated `gh-pages` archive assembly in a separate Git worktree so generated `build/web` files cannot block switching to the archive branch.
- Removed legacy root-level `build/` output from the Pages archive during publishing.
- Pull request web validation now exercises the archive worktree assembly path and verifies root build output is not present.

## 0.1.2

### Changed
- Upgraded GitHub Pages actions to Node.js 24-compatible major versions: `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, and `actions/deploy-pages@v5`.
- Pull request web deployment validation now uses the same current Pages action majors as production deployment.

## 0.1.1

### Fixed
- GitHub Actions workflow parsing for JavaScript inside the version selector injection.
- Versioned web deployment validation now avoids `${...}` JavaScript template expressions that GitHub Actions can misinterpret as workflow expressions.

## 0.1.0

### Added
- Project-wide semantic version source in `VERSION`.
- Pull request validation for version, changelog, project metadata, and splash-screen consistency.
- Versioned GitHub Pages web builds with immutable release directories.
- Project version displayed at the bottom center of the boot splash screen.
- Top-right version selector on deployed web builds for switching between published versions.
- Pull request validation that exports the versioned Web build, assembles the Pages payload, smoke-tests it over HTTP, and uploads the validated deployment artifact.
