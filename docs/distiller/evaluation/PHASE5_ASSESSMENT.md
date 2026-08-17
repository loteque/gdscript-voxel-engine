# Distiller Phase 5 Assessment

Date: 2026-08-17
Contract: `rgp/1`
Status: **PASS — Steward-governed mechanical admission automation established**

## Entry condition

Phase 4 passed after three routine Steward-governed admissions covering mixed semantic reuse/new meaning, unresolved investigation evidence, and quantitative performance evidence. In every Phase-4 trial the Distiller remained a non-authoritative producer and proof/install remained deterministic, exact-base, and auditable.

## Mechanical automation demonstrated

Phase 5 added `.github/workflows/rgp-steward-admission-automation.yml` and the governance contract in `docs/distiller/PHASE5_AUTOMATION.md`.

The Phase-5 trials demonstrated that the repository can automate the mechanical path after a Steward reconciliation plan exists:

- RGP validation;
- guarded-update pressure tests;
- deterministic PEMS/2 reconciliation proof;
- candidate contract and graph validation;
- deterministic PEMS/COVE generation;
- proof-evidence persistence before installation;
- optimistic branch-head checks;
- exact-byte installation.

The proof-only dry run and live documentation-release-policy trial remain valid evidence for those mechanical properties.

## Correct authority model

**The Project Engineering Steward owns semantic reconciliation authority. The Distiller does not.**

The Distiller produces immutable candidate RGP only. It does not decide semantic identity, canonical reuse, lifecycle, provenance sufficiency, uncertainty resolution, record updates, or admission.

The Steward performs those authority-bearing decisions and encodes them in the reconciliation transaction and disposition. The repository workflow executes the resulting plan deterministically and fails closed on invalid, stale, or concurrently displaced state.

The GitHub execution actor protects the repository execution/write surface; it does not transfer reconciliation authority to the Distiller or workflow.

The current execution-request contract is `rgp-steward-admission-execution-request/3`, which declares `reconciliation_authority = "project-engineering-steward"` and binds execution to the exact committed Steward plan digest.

## Historical proof-only pressure run

The first dry-run request, `PHASE5-DRYRUN-001`, failed closed before validation because the initial workflow incorrectly treated `evidence_key` as a repository file path. The failed immutable request was preserved unchanged.

The workflow was corrected without modifying that failed request. A new immutable request, `PHASE5-DRYRUN-002`, then ran as workflow run `32044664554` with installation disabled.

**PASS.** The corrected dry run successfully completed validation, pressure tests, exact-base deterministic proof, candidate validation, deterministic evidence generation, and separate proof-evidence persistence while canonical installation remained skipped.

## Live automation trial — documentation release policy

Submission: `RGP-20260817T091500-0700-008`.

The submitted candidate graph was unchanged from the Phase-3 `docs-release-policy` shadow candidate. The Steward reconciliation plan admitted the four policy/validation meanings plus typed PR #51 source records against a 218-record / 14-relation base.

Workflow run `32044753159` passed all mechanical stages. The deterministic proof established:

- exact normalized base SHA-256 `07818a18e982bd0dd58d0273dfac4715212ffbfcd8c5ce89cad129ebf195c7a2`;
- base 218 records / 14 relations;
- candidate 224 records / 14 relations;
- 6 new records / 0 new relations;
- PEMS/2 schema validity and graph integrity;
- deterministic PEMS JCS SHA-256 `e32dae550132582e2f1a9689b04b181989ccb97e978acdb7a47996d8ed347b79`;
- deterministic COVE JCS SHA-256 `1dbf7ee6261863dd92c10d1d51994d7f89fc71f1b6ecb7da7bec67a3f14bd9f1`;
- no canonical mutation during proof.

The proof bundle was persisted first in commit `f512792f5e39f78fe437f6373ec93c3932f64a9d`, and the exact persisted candidate bytes were then installed in commit `6e908a125582f49a20def9dbc656b104d9651b06`.

## Current Phase-5 boundary

**PASS.**

The intended separation is:

- Distiller: non-authoritative candidate producer;
- Project Engineering Steward: semantic reconciliation and admission authority;
- committed Steward transaction: exact semantic choices;
- repository executor: deterministic validation/proof/persist/install mechanics;
- canonical installation: exact-base, evidence-before-install, byte-for-byte.

An intermediate documentation revision incorrectly described reconciliation authority as external to the Steward. That interpretation is superseded and is not part of the intended design.

## Disposition

Phase 5 remains complete. Routine admissions may use the automated mechanical execution path after Steward reconciliation. No Distiller self-admission or Distiller reconciliation authority is authorized.
