# Changelog

All notable changes to this project are recorded here by project version.

## 0.10.0

### Added
- Added asynchronous precomputed chunk loading to `ChunkStreamer` using Godot's threaded `ResourceLoader` APIs.
- Added an explicit `UNLOADED` → `QUEUED` → `LOADING` → `RESIDENT` lifecycle with pending-state queries and loading lifecycle signals.
- Added deterministic headless coverage for request lifecycle, successful completion, duplicate requests, pending cancellation, failed loads, residency changes while loads are pending, and runtime generation-layer separation.
- Expanded the existing Chunk Streaming Validation Demo to display queued/loading work separately from resident chunks.

### Changed
- `update_residency()` now remains a residency-policy operation while loading execution advances pending requests independently each frame.
- `load_chunk()` now accepts an asynchronous load request instead of blocking on resource I/O; `is_chunk_loaded()` continues to mean that a normal resident `MeshInstance3D` exists.
- Pending chunks that stop being desired are logically cancelled without creating runtime instances when their threaded resource request eventually completes.
- The GitHub Pages `streaming` Integration Preview continues to use the existing stable validation slot while exposing the latest asynchronous streaming behavior.

## 0.9.0

### Added
- Added deterministic target-relative chunk residency to `ChunkStreamer`, including a configurable chunk-coordinate radius and an optional `Node3D` target.
- Added manifest-derived chunk coordinate conversion with floor semantics for negative coordinates, exact boundaries, non-unit sample spacing, and non-cubic chunk dimensions.
- Expanded the Chunk Streaming Validation Demo into a moving-target residency proof backed by a deterministic `5 x 1 x 5` region of precomputed noise-generated terrain chunks.
- Added headless coverage for residency radius zero and one, target transitions, unload behavior, duplicate updates, sparse manifests, coordinate conversion, runtime generation-layer separation, and the residency validation scene itself.

### Changed
- Runtime residency policy now composes the existing explicit `load_chunk()`, `unload_chunk()`, and `is_chunk_loaded()` APIs rather than duplicating chunk-loading behavior.
- The GitHub Pages `streaming` validation slot now evolves in place with the latest runtime streaming milestone. The Integration Preview uses the residency-enabled interactive demo at the existing `/streaming/` URL rather than adding a separate feature-specific demo entry.

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
- Added a reusable mobile touch-control overlay for browser demos, including directional movement, vertical movement, fast movement, and touch-look input.
- Added mobile controls to the Terrain / Surface Nets and Chunk Validation demos through a shared production input path.
- Added a mutable GitHub Pages Integration Preview alongside immutable release demos.

## 0.6.0

### Added
- Added the first offline terrain chunk asset pipeline with `TerrainChunkAsset`, `TerrainChunkManifestEntry`, `TerrainChunkManifest`, and `ChunkAssetBaker`.
- Added deterministic chunk validation fixtures and tests for chunk metadata, manifest lookup, save/load behavior, and shared Surface Nets boundaries.

## 0.5.0

### Added
- Added automated asteroid-generation contract coverage for deterministic shared sampling across neighboring generated fields.

## 0.4.0

### Added
- Added browser deployment and selectable GitHub Pages demos for terrain and chunk validation.

## 0.3.0

### Added
- Added the first chunk validation scene and chunk Surface Nets continuity tests.

## 0.2.0

### Added
- Added `SurfaceNetsMesher` as a stateless consumer of `PointFieldResource`.
- Added deterministic mesher tests and renderable `ArrayMesh` output.

## 0.1.0

### Added
- Established `PointFieldResource` as the authoritative sampled scalar field.
- Added generation, indexing, sampling, validation, serialization, and visualization foundations.
