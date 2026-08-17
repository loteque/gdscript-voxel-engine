# Distiller Phase 5 — Guarded Admission Automation

Date: 2026-08-17
Contract: `rgp/1`

## Purpose

Phase 5 automates only the mechanical portions of the proven admission path while preserving the Project Engineering Steward as the semantic reconciliation authority.

The Distiller cannot admit its own output, reconcile candidate meaning into canonical identities, or write canonical PEMS/COVE directly.

## Authority boundary

**The Project Engineering Steward owns reconciliation authority. The Distiller does not.**

The Steward decides:

- whether candidate meaning is worth admitting;
- semantic identity and reuse versus new-record creation;
- lifecycle changes;
- provenance sufficiency and authority;
- uncertainty preservation or resolution;
- whether a reused canonical record should be updated;
- whether canonical installation is authorized.

The repository workflow is a deterministic executor of an already-produced Steward reconciliation plan. It does not perform semantic reconciliation and it does not elevate Distiller output into canonical truth on its own.

The GitHub execution actor check protects the repository write surface. It is not a substitute for the Steward's semantic reconciliation decision.

## Execution request

A Phase-5 run requires an immutable execution request committed separately from the RGP submission and Steward reconciliation plan.

The current request contract is `rgp-steward-admission-execution-request/3` and must:

- identify an already-committed immutable RGP submission;
- identify an already-committed Steward reconciliation transaction;
- identify the canonical PEMS/2 base path;
- declare `reconciliation_authority = "project-engineering-steward"`;
- bind the request to the exact reconciliation plan with `sha256:<digest>`;
- declare whether canonical installation is requested;
- explicitly request execution.

The workflow rejects request commits that contain any change besides one newly-added execution-request JSON. This prevents the Distiller or executor from changing the submission, reconciliation plan, or canonical memory in the same commit that requests execution.

## Automated stages

After the Steward has supplied the reconciliation plan, the workflow may automate:

1. authoritative RGP validation;
2. guarded admission-transaction pressure tests;
3. verification that the request digest matches the exact committed Steward reconciliation plan;
4. deterministic PEMS/2 reconciliation proof against the exact base;
5. PEMS/2 contract validation and graph-integrity proof;
6. deterministic PEMS/COVE generation;
7. immutable proof-evidence persistence in a separate commit;
8. optimistic-concurrency verification that the branch has not moved;
9. exact-byte canonical installation in a second, separate commit when installation is requested by the Steward-governed path.

The generated proof candidate is copied to canonical paths byte-for-byte. It is never regenerated during installation.

## Non-automated stages

The Distiller and repository automation do not decide:

- whether a proposition is worth admitting;
- whether candidate meaning is semantically identical to an existing canonical record;
- whether an uncertainty may be resolved;
- whether an observation may become a claim;
- whether source authority is sufficient;
- which canonical identities should be reused;
- whether a reused record should be updated;
- whether the reconciliation plan is semantically correct or authorized.

Those are Steward responsibilities encoded in the Steward reconciliation transaction and disposition.

## Concurrency and mutation safety

The execution-request commit is treated as the optimistic-concurrency anchor.

Before persisting proof evidence, the workflow verifies that the remote `project-chat-handoff` head still equals the execution-request commit. Before installation, it verifies that the remote head still equals the evidence-persistence commit. Any intervening write fails the run rather than rebasing or silently recomputing.

The deterministic admission transaction also requires an exact normalized PEMS base hash, and v2 reused-record updates require exact before-state hashes while preserving record identity and kind.

## Modes

`install: false` performs proof plus immutable evidence persistence only.

`install: true` additionally performs exact-byte canonical installation after proof evidence has been persisted successfully and the branch concurrency guard still holds.

Neither mode gives reconciliation authority to the Distiller or workflow.

## Historical Phase-5 evidence

The Phase-5 dry run and documentation-release-policy trial remain valid evidence that the mechanical automation path works. Their semantic reconciliation decisions were Steward decisions; the Distiller remained only the candidate producer.

An intermediate documentation revision incorrectly described reconciliation authority as external to the Steward. That interpretation is superseded by this document and was never intended to grant the Distiller authority.

## Phase-5 disposition

The mechanical automation demonstrated by Phase 5 remains valid with the intended governance boundary:

- Distiller output remains non-authoritative;
- the Project Engineering Steward owns reconciliation authority;
- repository automation verifies exact artifact binding and deterministic mechanics only;
- canonical mutation remains exact-base, evidence-before-install, and byte-for-byte;
- no automatic Distiller self-admission path exists.
