# Changelog

All notable changes to this project are recorded here by project version.

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
