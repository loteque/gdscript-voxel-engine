# Autonomous Engineering Organization Proposal - Safety Test

## Goals and Constraints

- Reconstruct the Project Engineering Steward and Engineering Knowledge Systems Architect as durable OpenAI-agent roles whose capabilities come from explicit directives, project memory, tools, permissions, repository state, and persistent sessions rather than dependence on one ChatGPT conversation.
- Preserve role fidelity: actions performed on behalf of a role must execute with that role's directive, tools, permissions, memory contract, and ownership boundaries.
- Prefer event-driven activation. GitHub/repository infrastructure may detect readiness and schedule work, but deterministic infrastructure should not impersonate either engineering role or make semantic decisions on its behalf.
- Maintain steward_directive.md and architect_directive.md as mutable, single-writer role directives. Each role may update only its own directive and must explain directive changes in immutable notes.
- Maintain steward_notes.md and architect_notes.md as append-only coordination and audit histories with immutable IDs, acknowledgements, reasoning intended for human understanding, and suggestions to the counterpart where appropriate.
- Preserve the mutable canonical project handoff separately from immutable coordination history.
- Continue the proposed separation between PEMS, Project Engineering Memory Schema, and JOLT, JSON Optimized Linked Tokens, as a general compact reversible JSON representation, subject to independent architectural naming and design review.
- Human-readable and searchable JSON, Markdown, onboarding documentation, and search indexes must be deterministically reconstructable from canonical machine-oriented memory.
- Operational budget is a hard maximum of $10 USD per calendar month. Deterministic filtering must be preferred to model inference. Model calls should occur only when semantic reasoning is required. The runtime should track estimated spend and degrade gracefully before the cap.
- Routine periodic heartbeats should not invoke models merely to discover nothing changed. Prefer events to wake agents, with inexpensive watchdog and recovery scheduling where useful.

## Proposed Runtime Layering

project owner / human interface
  -> agent runtime and event router
    -> Steward agent and Architect agent
      -> GitHub + role-owned files + PEMS/JOLT memory

GitHub events and actions validate and signal durable state. Agent roles perform semantic reasoning and role-owned mutations.

## Proposed Human Interface

- One project console rather than separate infrastructure consoles.
- Ability to address Steward or Architect explicitly, or route natural-language requests.
- Current role status: idle, working, blocked, or awaiting owner.
- Recent changes, pending owner decisions, GitHub links and line ranges, and monthly budget usage.
- Run now for urgent work versus queued or non-urgent work where that helps budget control.
- Activity and timeline view generated from immutable notes and repository events.
- Knowledge and onboarding view generated from PEMS into human-readable and searchable documentation.
- The human should not need to manually edit coordination Markdown or manually trigger workflows for normal operation.

## Questions for Architectural Review

1. Is the separation between scheduler and event infrastructure and semantic agent roles architecturally sound?
2. What minimum capabilities and state must be reconstructed for an external Steward or Architect agent to be considered role-faithful?
3. Which state belongs in PEMS/JOLT, persistent agent sessions, GitHub, directives, and immutable notes respectively?
4. How should exactly-once or idempotent consumption of counterpart work be represented?
5. How should event-driven activation, watchdog recovery, retries, and failure states interact without duplicate semantic work?
6. How should the $10/month hard budget be enforced architecturally, including model routing and graceful degradation?
7. Is the proposed single human console appropriate, and what is the minimum viable human interface?
8. Should an Agent Systems Engineer be introduced as a separate implementation role? If yes, define its ownership boundary relative to Architect and Steward.
9. What security, provenance, concurrency, schema-governance, or operational risks have been overlooked?
10. What incremental implementation sequence best proves role fidelity and cost control before building a larger UI?

The Architect should evaluate this proposal independently rather than accepting it because the Steward or project owner currently favors parts of it. This proposal is architectural and does not authorize implementation of the autonomous runtime.