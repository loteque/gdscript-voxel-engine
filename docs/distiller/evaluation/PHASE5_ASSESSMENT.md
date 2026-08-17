# Distiller Phase 5 Assessment

Date: 2026-08-17
Contract: `rgp/1`
Status: **PASS — mechanical admission executor established; reconciliation authorization is external**

## Entry condition

Phase 4 passed after three routine guarded admissions covering mixed semantic reuse/new meaning, unresolved investigation evidence, and quantitative performance evidence. In every Phase-4 trial the Distiller remained a non-authoritative producer and proof/install remained deterministic, exact-base, and auditable.

## Mechanical automation demonstrated

Phase 5 added `.github/workflows/rgp-steward-admission-automation.yml` and the governance contract in `docs/distiller/PHASE5_AUTOMATION.md`.

The original Phase-5 trials demonstrated that the repository can automate the mechanical path after a reconciliation plan exists:

- RGP validation;
- guarded-update pressure tests;
- deterministic PEMS/2 reconciliation proof;
- candidate contract and graph validation;
- deterministic PEMS/COVE generation;
- proof-evidence persistence before installation;
- optimistic branch-head checks;
- exact-byte installation.

The proof-only dry run and live documentation-release-policy trial remain valid evidence for those mechanical properties.

## Authority-model correction

The original Phase-5 request contract represented semantic authority as repository-local `project-engineering-steward` approval bound to GitHub actor `loteque`.

That representation conflated two different concerns and is now superseded for new runs.

**Intended governance:** reconciliation authorization belongs to an external authority. The repository workflow is an executor, not a reconciliation authority.

The corrected request contract is `rgp-admission-execution-request/2`.

A new execution request must provide an `external_reconciliation_authorization` object containing:

- `authority_class: "external"`;
- an opaque external authorization reference;
- a `sha256:<digest>` binding that authorization to the exact committed reconciliation plan.

The workflow verifies the exact plan digest and then performs deterministic execution. It does not decide whether the external authority was semantically correct, who should hold that authority, or whether reconciliation should have been authorized.

The GitHub actor check now protects only the repository execution/write surface. It is explicitly **not** reconciliation authorization.

## Historical proof-only pressure run

The first dry-run request, `PHASE5-DRYRUN-001`, failed closed before validation because the initial workflow incorrectly treated `evidence_key` as a repository file path. The failed immutable request was preserved unchanged.

The workflow was corrected without modifying that failed request. A new immutable request, `PHASE5-DRYRUN-002`, then ran as workflow run `32044664554` with installation disabled.

**PASS.** The corrected dry run successfully completed validation, pressure tests, exact-base deterministic proof, candidate validation, deterministic evidence generation, and separate proof-evidence persistence while canonical installation remained skipped.

## Historical live automation trial — documentation release policy

Submission: `RGP-20260817T091500-0700-008`.

The submitted candidate graph was unchanged from the Phase-3 `docs-release-policy` shadow candidate. The reconciliation plan admitted the four policy/validation meanings plus typed PR #51 source records against a 218-record / 14-relation base.

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

Those historical artifacts are retained unchanged. They prove the mechanical pipeline, not the corrected external-authorization interface.

## Current Phase-5 boundary

**PASS for mechanical execution.**

The repository now enforces the intended separation for new requests:

- Distiller: produces candidate RGP only;
- external authority: authorizes semantic reconciliation;
- committed reconciliation plan: carries the exact semantic choices;
- repository executor: validates plan binding and performs deterministic proof/persist/install mechanics;
- canonical installation: exact-base, evidence-before-install, byte-for-byte.

The repository does not self-authorize reconciliation and does not grant the Distiller reconciliation authority.

## Disposition

Phase 5 remains complete as a mechanical automation milestone, with the authority model corrected so reconciliation authorization is explicitly external.

Any future integration with a concrete external authority may strengthen authentication of the external authorization reference (for example by signed attestation or a dedicated external service), but that integration must not move semantic reconciliation authority into the repository executor.
