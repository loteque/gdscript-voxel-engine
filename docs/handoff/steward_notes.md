# Project Engineering Steward Notes

Append-only coordination and audit history for the Project Engineering Steward.

Prior entries are immutable. New entries must be appended and must not rewrite, reorder, or delete earlier entries.

---

## STEWARD-20260813-001

**Timestamp:** 2026-08-13
**Type:** governance-correction
**Status:** active

### Summary

Initialized the Steward-owned immutable notes file after the project owner identified that the required `docs/handoff/steward_notes.md` artifact had not been created.

### Correction

The Steward had established a coordination design in which both the Engineering Knowledge Systems Architect and Project Engineering Steward maintain append-only notes, but only the Architect notes artifact had actually been created. This was an execution/governance gap. The absence of the Steward notes file also prevented the Architect from acknowledging Steward entries during startup, which explains repeated Architect reports that there were no Steward notes to acknowledge.

### Current Steward context to preserve

- The Steward owns trustworthy engineering continuity and canonical project-memory contents; the Architect owns the PEMS/COVE representation contract.
- `docs/project-chat-handoff.json` remains the mutable canonical handoff until an explicitly approved PEMS/COVE migration changes that authority.
- PEMS/COVE design work must preserve receiving-chat continuation, provenance, current-versus-historical state, role/workstream context, project-level context, files/modules/configuration/schema facts, decisions, unresolved items, validation responsibilities, and repository/ADR/roadmap authority boundaries.
- The Steward recommended that operational runtime state such as activation leases, retry counters, transient queues, budget meters, and execution receipts remain outside PEMS unless stable outcomes need archival projection.
- The autonomous engineering organization has a hard operating budget target of $10 USD per calendar month; deterministic filtering should precede semantic model invocation.
- Repository write failures must be reported to the project owner. The Steward must not silently alter retry strategy, wording, payload, or execution path after a failure; the owner and Steward determine the next course of action together.
- Substantial architectural proposals should be durable repository artifacts rather than existing only inside scheduled-task prompts.

### PEMS/COVE design recommendations already supplied to Architect

The Steward requested stable semantic identities, first-class provenance/state, explicit null/absent/empty semantics, secret-safe environment-variable representation, domain independence for COVE, deterministic dictionary/layout/reference construction, independent PEMS/COVE/serializer versioning, RFC 8785 JCS evaluation, reproducible size regression, malformed-input fixtures, selective-decoding analysis, artifact-boundary analysis, human-readable reconstruction, staged shadow migration, and retention of the current human-readable handoff during migration until canonical adoption is explicitly approved.

### Human reasoning

The two-role governance model only works if both sides have durable, independently owned coordination history. A missing Steward notes file makes communication asymmetric: the Steward can read Architect decisions, while the Architect has no durable Steward channel to read or acknowledge. Creating this file restores the intended single-writer, append-only coordination boundary and makes future startup checks meaningful.

### Owner feedback incorporated

The project owner explicitly identified the missing Steward notes artifact. This entry records the correction rather than pretending the file had existed previously.

---

## STEWARD-20260813-002

**Timestamp:** 2026-08-13
**Type:** owner-decision
**Status:** accepted

### Summary

The project owner approved two Steward amendments to the current PEMS v1 proposal: canonical semantic ID allocation ownership and separation of stable source identity from immutable source observations.

### Decision 1: canonical semantic ID allocation

Canonical PEMS semantic IDs are allocated or confirmed by the Project Engineering Steward during reconciliation. Other roles and tools may propose candidate IDs or semantic objects, but a proposed ID is not authoritative until incorporated into canonical PEMS by the Steward.

Existing semantic IDs must never be silently reassigned to different meanings. Display-name changes do not change identity. Where external systems provide intrinsically stable identity, such as repository-qualified pull-request numbers, commit SHAs, or other immutable external identifiers, PEMS may derive or incorporate those identifiers according to the schema, but canonical admission and collision handling remain Steward responsibilities.

The PEMS normalizer must reject collisions and duplicate canonical IDs.

### Decision 2: source identity and source observation are distinct semantics

PEMS should distinguish the stable identity of an evidence source from a concrete observation of that source.

Conceptually:

```text
source
  stable identity of the thing being observed
  e.g. docs/ROADMAP.md

source observation
  immutable evidence snapshot of that source
  e.g. docs/ROADMAP.md at commit abc123, observed at a recorded time

semantic record / claim
  provenance reference to the applicable source observation
```

This prevents a mutable `source` record from either erasing historical evidence when a source changes or forcing identity and observation semantics into one overloaded object.

The Architect should determine the precise v1 schema representation, naming, relation structure, and whether limited direct source references remain valid when an immutable observation cannot be captured. Current repository, architecture, roadmap, validation, and other time-sensitive truth should prefer immutable observation provenance when practical.

### Human reasoning

Stable identity is a governance concern, not merely a string-format concern. Because the Steward is the single writer and reconciler of canonical project knowledge, final semantic ID allocation belongs at that boundary. This prevents independently acting roles from accidentally giving one ID to two meanings or minting parallel identities for one semantic object.

Source identity and evidence observation answer different questions. `docs/ROADMAP.md` answers “what source is this?” while `docs/ROADMAP.md` at a specific commit answers “what exactly did we observe when this claim was recorded?” Keeping both concepts explicit preserves auditability without making current source identity itself immutable.

### Architect action requested

Amend the PEMS v1 design before implementation to incorporate both owner-approved decisions. The Architect retains ownership of the exact representation contract and may refine the shape so long as these semantic requirements are preserved.

---

## STEWARD-20260813-003

**Timestamp:** 2026-08-13
**Type:** design-freeze
**Status:** accepted

### Summary

The project owner approved the amended PEMS v1 / COVE v1 design package after final Steward review. The design is frozen as the implementation contract for v1, subject only to evidence-gated choices explicitly left open by the proposal. This approval authorizes implementation work in the proposal's staged sequence but does not authorize canonical migration away from `docs/project-chat-handoff.json`.

### Frozen v1 decisions

- PEMS uses normalized typed records, explicit relations, stable Steward-admitted semantic IDs, type-specific states, and record-level provenance.
- Canonical semantic IDs are allocated or confirmed by the Project Engineering Steward during reconciliation. Candidate IDs from roles, tools, importers, or agents are provisional until admitted.
- Stable `source` identity and immutable `source_observation` evidence are separate record kinds. Semantic provenance references observations rather than mutable sources; when immutable evidence is unavailable, pems/1 uses an explicit immutable `unversioned_observation` record.
- Historical, superseded, tombstoned, and observation records are preserved by ordinary normalization. Destructive compaction requires a separately approved Steward retention policy and fixtures.
- The current nested human handoff is requirements input rather than the future semantic shape.
- COVE v1 is domain-agnostic and uses global string interning plus deterministic object-shape factoring as its deliberately small structural core.
- PEMS, COVE, and deterministic byte serialization are independently versioned contracts.
- RFC 8785 JCS remains the preferred serializer and may become normative after conformance evidence. The project is willing in principle to adopt an RFC 8785 implementation/tooling dependency if exact JCS serialization is not natively available, but dependency selection is an implementation decision supported by evidence.
- One canonical compact project-memory document is the v1 target rather than canonical sharding.
- Human-readable/searchable artifacts are deterministic derivatives that preserve semantic IDs and provenance paths.
- Runtime leases, queues, retries, receipts, budget meters, and similar execution mechanics remain outside PEMS.
- No fixed 20% compression threshold is normative before representative measurements exist.
- The v1 record-kind vocabulary remains closed for implementation; extension policy is deferred until evidence shows a need. Every record kind actually admitted into pems/1 must have a normative schema by completion of Phase 1; arbitrary `data` objects must not become an escape hatch.

### Post-migration canonical path decision

The project owner approved `docs/project-chat-handoff.cove.json` as the intended canonical compact-memory path after a future explicit migration decision. `docs/project-chat-handoff.json` is intended to remain as a generated compatibility/human-readable derivative after that migration.

This path decision does **not** authorize migration now. Until shadow validation is complete and the owner/Steward explicitly approve canonical adoption, `docs/project-chat-handoff.json` remains the authoritative continuity artifact.

### Evidence-gated and deferred items

- Exact JCS library/tool dependency remains an implementation choice gated by conformance evidence.
- Project-local extension kinds are deferred; use the closed pems/1 vocabulary unless a later schema decision changes it.
- A numeric COVE compression threshold will be selected or explicitly waived only after representative fixture measurements exist.
- Any destructive historical-retention/compaction policy is future Steward policy work and is not part of ordinary pems/1 normalization.

### Implementation authorization and sequence

The design freeze authorizes implementation according to the approved sequence:

1. freeze normative expanded PEMS semantic schemas and fixtures;
2. implement deterministic PEMS validation/normalization and Steward ID-admission contracts;
3. implement generic COVE v1 encoder/decoder against generic fixtures first and PEMS fixtures second;
4. implement and validate deterministic serialization, preferring JCS if conformance evidence succeeds;
5. build the full conformance suite including semantic/byte round trips, malformed input, provenance, identity, historical retention, secret handling, migration, human reconstruction, and reproducible size measurements;
6. build one-way current-handoff import/conversion tooling with provisional IDs and source/observation splitting;
7. run shadow generation over multiple Steward reconciliations while the existing human handoff remains canonical;
8. make a separate owner/Steward canonical-adoption decision only after evidence is satisfactory.

The immediate next implementation milestone is **Phase 1 only: normative semantic schemas and fixtures**. Phase 1 must make every pems/1 record kind used by the fixtures structurally normative and must include the required success and failure cases from the frozen design.

### Human reasoning

Freezing the contract before implementation prevents implementation convenience from silently redefining project-memory semantics. The staged path deliberately establishes semantic fixtures before codec work so PEMS meaning can be validated independently of compression. COVE remains a representation mechanism rather than a second semantic system, and the existing handoff remains a safe rollback/reference artifact throughout shadow migration.
