# Distiller Phase 5 — Guarded Admission Automation

Date: 2026-08-17
Contract: `rgp/1`

## Purpose

Phase 5 automates only the mechanical portions of the proven Phase-4 admission path while preserving human/Steward semantic authority.

The Distiller still cannot admit its own output or write canonical PEMS/COVE directly.

## Authority boundary

A Phase-5 automation run requires an immutable Steward approval request committed separately from the RGP submission and reconciliation plan.

The approval request must:

- identify an already-committed immutable RGP submission;
- identify an already-committed Steward reconciliation transaction;
- identify the canonical PEMS/2 base path;
- declare whether canonical installation is authorized;
- identify the approving GitHub actor;
- declare `project-engineering-steward` as the semantic authority.

The workflow rejects approval commits that contain any change besides one newly-added automation request JSON. This prevents a producer or workflow from altering the submission, plan, or canonical memory in the same commit that grants approval.

## Automated stages

After Steward approval, the workflow may automate:

1. authoritative RGP validation;
2. guarded admission-transaction pressure tests;
3. deterministic PEMS/2 reconciliation proof against the exact base;
4. PEMS/2 contract validation and graph-integrity proof;
5. deterministic PEMS/COVE generation;
6. immutable proof-evidence persistence in a separate commit;
7. optimistic-concurrency verification that the branch has not moved;
8. exact-byte canonical installation in a second, separate commit when `install` is explicitly true.

The generated proof candidate is copied to canonical paths byte-for-byte. It is never regenerated during installation.

## Non-automated stages

Automation does not decide:

- whether a proposition is worth admitting;
- whether candidate meaning is semantically identical to an existing canonical record;
- whether an uncertainty may be resolved;
- whether an observation may become a claim;
- whether source authority is sufficient;
- which canonical identities should be reused;
- whether a reused record should be updated;
- whether canonical installation is authorized.

Those remain Steward responsibilities encoded in the reconciliation transaction and approval request.

## Concurrency and mutation safety

The automation request commit is treated as the optimistic-concurrency anchor.

Before persisting proof evidence, the workflow verifies that the remote `project-chat-handoff` head still equals the approval-request commit. Before installation, it verifies that the remote head still equals the evidence-persistence commit. Any intervening write fails the run rather than rebasing or silently recomputing.

The deterministic admission transaction also requires an exact normalized PEMS base hash, and v2 reused-record updates require exact before-state hashes while preserving record identity and kind.

## Modes

`install: false` performs proof plus immutable evidence persistence only. It is the safe mode for automation regression testing.

`install: true` additionally performs exact-byte canonical installation after proof evidence has been persisted successfully and the branch concurrency guard still holds.

## Phase-5 exit gate

Phase 5 passes when:

- the new automation workflow passes a proof-only dry run against current canonical state;
- at least one novel Steward-reconciled Distiller candidate is admitted using the automated proof/persist/install path;
- the candidate submission and Steward reconciliation remain immutable;
- semantic identity decisions are supplied by the Steward, not inferred by the workflow;
- proof evidence is committed before canonical installation;
- canonical installation uses the exact persisted candidate bytes;
- stale-base or branch-movement conditions fail closed;
- no automatic Distiller self-admission path exists.

A Phase-5 pass authorizes routine use of this Steward-triggered automation, not autonomous semantic admission.
