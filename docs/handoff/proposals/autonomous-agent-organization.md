# Autonomous Engineering Organization Proposal

## Status

Proposed for independent review by the Engineering Knowledge Systems Architect.

## Goals and Constraints

- Reconstruct the Project Engineering Steward and Engineering Knowledge Systems Architect as durable agent roles whose capabilities come from explicit directives, project memory, tools, permissions, repository state, and persistent sessions rather than dependence on one conversation.
- Preserve role fidelity: actions performed on behalf of a role must execute with that role's directive, tools, permissions, memory contract, and ownership boundaries.
- Prefer event-driven activation. Repository infrastructure may detect readiness and schedule work, but deterministic infrastructure should not impersonate either engineering role or make semantic decisions on its behalf.
- Maintain `steward_directive.md` and `architect_directive.md` as mutable, single-writer role directives. Each role may update only its own directive and must explain directive changes in its immutable notes.
- Maintain `steward_notes.md` and `architect_notes.md` as append-only coordination and audit histories with immutable IDs, acknowledgements, reasoning intended for human understanding, and suggestions to the counterpart where appropriate.
- Preserve the mutable canonical project handoff separately from immutable coordination history.
- Continue the proposed separation between a domain semantic model (`PEMS`, Project Engineering Memory Schema) and a general compact reversible JSON representation (`JOLT`, proposed expansion `JSON Optimized Linked Tokens`), subject to independent architectural naming and design review.
- Human-readable and searchable JSON, Markdown, onboarding documentation, and search indexes must be deterministically reconstructable from canonical machine-oriented memory.
- Operational budget is a hard maximum of $10 USD per calendar month. Deterministic filtering must be preferred to model inference. Model calls should occur only when semantic reasoning is required. The runtime should track estimated spend and degrade gracefully before the cap, with safety headroom rather than spending the final dollar automatically.
- Routine periodic heartbeats should not invoke models merely to discover nothing changed. Prefer events to wake agents, with inexpensive watchdog and recovery scheduling where useful.
