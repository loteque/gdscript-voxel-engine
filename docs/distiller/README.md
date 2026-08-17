# Reasoning Distiller

## Motivation

Engineering agents can perform substantial analysis while producing concise responses. The project should preserve the durable structure of important reasoning without requiring verbose chat transcripts to serve as the historical record.

The Distiller preserves useful symbolic structure between raw reasoning narratives and final decisions.

## Intent

The Distiller converts observable engineering work into candidate semantic records and relationships suitable for project memory. It does not record, reconstruct, or claim access to hidden chain-of-thought.

```text
engineering work
      ↓
observable evidence and outcomes
      ↓
Distiller
      ↓
candidate RGP
      ↓
validator
      ↓
immutable submission
      ↓
Project Engineering Steward reconciliation
      ↓
deterministic proof / exact installation
      ↓
canonical PEMS/COVE
```

The Distiller is a candidate producer only. It has no reconciliation or admission authority and cannot write canonical project memory directly.

## Important Terms

**Distiller** — Semantic producer that converts observable evidence into an immutable candidate reasoning graph.

**Observable evidence** — Externally available task material such as instructions, repository state, tool output, tests, artifacts, explicit decisions, and unresolved questions.

**RGP (`rgp/1`)** — Reasoning Graph Protocol used for Distiller candidate records, provenance, premises, and relations.

**Candidate** — Proposed semantic graph with no canonical authority merely because the Distiller produced it.

**Record** — Atomic semantic proposition classified as an observation, decision, assumption, uncertainty, or claim.

**Observation** — Proposition reporting supplied or measured evidence.

**Decision** — Normative choice or requirement supported by an appropriate authority source.

**Assumption** — Proposition provisionally treated as true without sufficient evidence to classify it as an observation.

**Uncertainty** — Explicit unresolved question, unknown, or insufficiently established proposition.

**Claim** — Derived or interpretive proposition supported by premises or evidence.

**Premise** — Record reference that is constitutive of a derived claim.

**Relation** — Non-derivational semantic link: `supports`, `contradicts`, `depends_on`, or `supersedes`.

**Provenance** — References identifying the evidence supporting a record.

**Validator** — Deterministic checker for RGP structure and protocol invariants; it does not determine semantic truth or admission.

**Submission** — Immutable validated candidate packaged for Steward review.

**Project Engineering Steward** — Authority responsible for semantic reconciliation and canonical admission decisions.

**Semantic reconciliation** — Steward-authorized mapping of candidate meaning onto canonical knowledge by resolving identity, reuse versus creation, provenance, authority, uncertainty, conflict, and disposition.

**Canonical reuse** — Mapping candidate meaning to an existing canonical record rather than creating a duplicate.

**Admission** — Authorized decision to incorporate reconciled meaning into canonical project memory.

**Disposition** — Immutable record of the Steward's admitted, rejected, or provisional outcome.

**PEMS/2** — Canonical semantic project-memory representation.

**COVE** — Deterministic companion encoding/index representation generated from canonical memory.

**Admission transaction** — Steward-authored exact reconciliation plan describing canonical creations, reuse, updates, and relations.

**Proof** — Deterministic, read-only application of an admission transaction against an exact canonical base.

**Exact-base concurrency** — Requirement that admission applies only to the canonical state against which it was proved.

**Exact-byte installation** — Canonical write that installs the exact PEMS/COVE artifacts produced and validated by the proof stage.

**Executor** — Mechanical workflow that validates, proves, persists evidence, and installs a Steward-authorized transaction without performing semantic reconciliation.

**Authority boundary** — Distiller proposes; Steward reconciles and authorizes; executor applies deterministically.

## RGP/1 Semantic Vocabulary

Record kinds:

- `observation`
- `decision`
- `assumption`
- `uncertainty`
- `claim`

Relations:

- `supports`
- `contradicts`
- `depends_on`
- `supersedes`

Provenance roles:

- `primary`
- `corroborating`
- `context`

Validation evidence belongs in provenance when it is evidence. `validated_by` is not an RGP/1 relation. RGP does not contain an authority field.

## Design Principles

1. Preserve the argument, not the monologue.
2. Use only observable evidence and explicit outcomes.
3. Prefer atomic semantic records over prose blobs.
4. Preserve uncertainty rather than inventing resolution.
5. Preserve minimal sufficient provenance.
6. Distillation proposes memory; it does not grant authority.
7. Keep semantic interpretation separate from deterministic validation and persistence.
8. Discard low-value activity.
9. Keep the vocabulary small and change-controlled.
10. Keep the Distiller independent of a particular chat role, engineering domain, or storage implementation.

## Relationship to PEMS and COVE

The Distiller is upstream of project-memory admission. PEMS remains canonical semantic memory. COVE remains a deterministic companion representation. Neither representation is a store for hidden agent cognition.

Raw Distiller candidates remain immutable. Steward reconciliation produces a separate authorized transaction describing how candidate meaning maps to canonical memory.

## Success Criterion

A fresh agent should be able to reconstruct durable engineering decisions, evidence, interpretation, and unresolved uncertainty from project memory without requiring the original chat transcript, while ordinary project conversations remain concise.
