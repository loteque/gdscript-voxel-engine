# Distiller Phase 5 — Guarded Admission Automation

Date: 2026-08-17
Contract: `rgp/1`

## Purpose

Phase 5 automates only the mechanical portions of the proven admission path.

The Distiller still cannot admit its own output or write canonical PEMS/COVE directly.

## Correct authority boundary

**Reconciliation authorization is external to this repository automation.**

The repository does not decide who is authorized to reconcile candidate meaning, and the GitHub Actions workflow is not a semantic authority. An external authority decides whether a reconciliation plan is authorized and supplies an authorization reference bound to the exact reconciliation-plan digest.

The repository consumes that already-authorized plan and performs deterministic execution only.

Two authority scopes are therefore intentionally separate:

1. **External reconciliation authority** — decides semantic identity, reuse, lifecycle, provenance sufficiency, uncertainty handling, and whether the reconciliation plan is authorized.
2. **Repository execution authority** — decides only whether the already externally-authorized plan should be executed in proof-only or proof-plus-install mode against the current exact canonical state.

The external authorization reference is audit metadata from the external authority. The workflow verifies that its declared SHA-256 digest matches the exact committed reconciliation plan; it does not manufacture or reinterpret the external authority decision.

## Execution request

A Phase-5 execution run requires an immutable execution request committed separately from the RGP submission and reconciliation plan.

The current request contract is `rgp-admission-execution-request/2` and must:

- identify an already-committed immutable RGP submission;
- identify an already-committed reconciliation transaction;
- identify the canonical PEMS/2 base path;
- provide `external_reconciliation_authorization.authority_class = "external"`;
- provide an opaque external authorization reference;
- bind that external authorization to the exact reconciliation plan with `sha256:<digest>`;
- declare whether canonical installation is requested;
- explicitly request execution.

The workflow rejects request commits that contain any change besides one newly-added execution-request JSON. This prevents a producer or executor from changing the submission, reconciliation plan, or canonical memory in the same commit that requests execution.

The repository execution actor check is not reconciliation authorization. It only protects the repository write/execution surface.

## Automated stages

After an externally-authorized reconciliation plan has been supplied, the workflow may automate:

1. authoritative RGP validation;
2. guarded admission-transaction pressure tests;
3. verification that the external authorization digest matches the exact committed reconciliation plan;
4. deterministic PEMS/2 reconciliation proof against the exact base;
5. PEMS/2 contract validation and graph-integrity proof;
6. deterministic PEMS/COVE generation;
7. immutable proof-evidence persistence in a separate commit;
8. optimistic-concurrency verification that the branch has not moved;
9. exact-byte canonical installation in a second, separate commit when installation is requested.

The generated proof candidate is copied to canonical paths byte-for-byte. It is never regenerated during installation.

## Non-automated stages

Repository automation does not decide:

- who has reconciliation authority;
- whether a proposition is worth admitting;
- whether candidate meaning is semantically identical to an existing canonical record;
- whether an uncertainty may be resolved;
- whether an observation may become a claim;
- whether source authority is sufficient;
- which canonical identities should be reused;
- whether a reused record should be updated;
- whether a reconciliation plan is semantically authorized.

Those decisions belong to the external reconciliation authority and are encoded in the externally-authorized reconciliation artifact supplied to the repository.

## Concurrency and mutation safety

The execution-request commit is treated as the optimistic-concurrency anchor.

Before persisting proof evidence, the workflow verifies that the remote `project-chat-handoff` head still equals the execution-request commit. Before installation, it verifies that the remote head still equals the evidence-persistence commit. Any intervening write fails the run rather than rebasing or silently recomputing.

The deterministic admission transaction also requires an exact normalized PEMS base hash, and v2 reused-record updates require exact before-state hashes while preserving record identity and kind.

## Modes

`install: false` performs proof plus immutable evidence persistence only.

`install: true` additionally performs exact-byte canonical installation after proof evidence has been persisted successfully and the branch concurrency guard still holds.

Neither mode grants reconciliation authority to the repository.

## Historical Phase-5 evidence

The original Phase-5 trials used a repository-local `project-engineering-steward` approval field bound to a GitHub actor. Those artifacts are preserved unchanged as historical evidence of the mechanical automation trials.

That representation is now superseded for new runs by `rgp-admission-execution-request/2`, which explicitly leaves reconciliation authorization external and treats the repository workflow as an executor only.

## Phase-5 disposition

The mechanical automation demonstrated by the original Phase-5 trials remains valid. The governance boundary is corrected as follows:

- Distiller output remains non-authoritative;
- reconciliation authorization remains external;
- repository automation verifies exact artifact binding and deterministic mechanics only;
- canonical mutation remains exact-base, evidence-before-install, and byte-for-byte;
- no automatic Distiller self-admission or repository self-authorization path exists.
