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
