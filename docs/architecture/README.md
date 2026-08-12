# Architecture Decision Records

This directory preserves durable architectural decisions for GDScript Voxel Terrain.

The records are intended for both human engineers and autonomous development agents. They provide context and constraints from which a qualified engineer can develop an implementation plan. They should explain why a durable decision exists without prescribing incidental implementation details.

## When to add an ADR

Add an ADR when a decision establishes, changes, or supersedes a durable engine contract, subsystem boundary, ownership rule, or architectural constraint that future work will depend on.

Do not create an ADR for ordinary implementation choices that can change without affecting the engine's architectural direction.

## Suggested structure

Each ADR should include:

- **Status**: Proposed, Accepted, Superseded, or Deprecated.
- **Context**: the problem, constraints, and relevant project state.
- **Evidence**: measurements, prior decisions, or observed behavior that materially informed the decision.
- **Decision**: the durable architectural choice.
- **Consequences**: important benefits, costs, constraints, and future implications.
- **Alternatives considered**: meaningful alternatives and why they were not selected.
- **Related records**: relevant performance reports, roadmap history, PRs, or superseding ADRs.

## Record discipline

Do not rewrite accepted ADRs to make history look cleaner after the architecture changes. Mark an old ADR as superseded and link to the newer record.

Distinguish measured evidence from engineering inference. If evidence does not isolate a cause, preserve that uncertainty.

ADRs may describe implementation consequences when those consequences are part of the architectural decision, but should generally avoid prescribing files, methods, classes, or algorithms. Implementation planning belongs to the engineer or agent performing the milestone after inspecting the current repository.