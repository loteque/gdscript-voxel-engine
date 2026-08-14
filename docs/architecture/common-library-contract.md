# Common Library Contract

## Purpose

The common library collects Godot components whose ownership and usefulness extend beyond the voxel terrain engine and this repository's demos.

Extraction into the common library is an architectural decision, not a folder-cleanup exercise. A component should be promoted only when its existing responsibilities form a coherent cross-project capability.

The library exists to capture proven reusable elements as they emerge from project work without forcing terrain-specific systems into generic abstractions prematurely.

## Dependency Layers

The intended dependency direction is:

```text
project / demos
        ↓
voxel terrain engine
        ↓
common library
```

Dependencies must not point upward through these layers.

Common-library code must not depend on voxel-terrain engine types, terrain demos, project-specific fixtures, or project-specific workflow assumptions.

Voxel-engine systems may consume common-library components while retaining their own domain-specific contracts.

## Library Promotion Criteria

A component is a strong candidate for the common library when:

- its responsibility is meaningful outside voxel terrain;
- another Godot project could reasonably consume it without changing its core behavior;
- its public API can be understood without knowledge of this project's terrain architecture;
- it does not depend on voxel-specific types, data, terminology, or runtime assumptions;
- its validation can be expressed independently of terrain behavior; and
- extraction produces clearer ownership or reuse rather than merely relocating files.

Not every criterion must be mechanically satisfied. Promotion is a design judgment based on whether the component has demonstrated a genuinely project-independent contract.

## What Does Not Belong in the Common Library

Do not promote a component merely because it is reusable within this repository.

Terrain-domain systems such as scalar-field representation, terrain meshing, chunk assets, terrain manifests, and terrain streaming belong to the voxel engine even when they are reusable across multiple voxel projects.

Demo scenes, validation fixtures, project presentation, and repository-specific integration behavior remain project-level concerns unless a genuinely independent capability emerges from them.

Avoid using the common library as a general `misc`, `shared`, or `utils` directory. Files without clear ownership should have their ownership clarified rather than hidden behind a generic folder.

## Promotion Process

When considering a component for promotion:

1. identify its existing responsibility and consumers;
2. determine whether that responsibility is genuinely project-independent;
3. identify dependencies that would cross the library boundary;
4. preserve or clarify its public contract during extraction;
5. retain appropriate validation for the extracted behavior; and
6. update consumers to depend on the library component rather than maintaining parallel copies.

Promotion should not broaden a component's responsibilities simply to make it appear more generic.

If substantial redesign is required before a component can become independent, treat that redesign as separate architectural work rather than disguising it as a file move.

## Ownership After Promotion

Once promoted, the common-library version is authoritative for that capability.

Project and engine code should consume it through its public API rather than duplicating or specializing its internal behavior locally. Domain-specific behavior should remain in the consuming layer and compose with the library component where practical.

A common-library component may evolve as new projects expose legitimate requirements, but terrain-specific requirements alone should not distort a general contract.

## Extraction Is Reversible

Promotion is not a declaration that an abstraction is permanently correct.

If later evidence shows that a component's supposedly general contract is actually dominated by one domain, its ownership should be reconsidered. Prefer accurate ownership over preserving a library abstraction for historical reasons.

## Planning Guidance

This contract is intended for both human engineers and development agents.

It defines architectural boundaries, promotion criteria, and expected outcomes. It does not prescribe implementation details for individual extractions.

Engineers should inspect the current repository, evaluate dependencies and validation requirements, and develop an implementation plan appropriate to the component being considered.
