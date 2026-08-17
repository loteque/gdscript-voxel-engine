# Distiller Phase 5 Assessment

Date: 2026-08-17
Contract: `rgp/1`
Status: **PASS — Steward-triggered guarded admission automation established**

## Entry condition

Phase 4 passed after three routine Steward-governed admissions covering mixed semantic reuse/new meaning, unresolved investigation evidence, and quantitative performance evidence. In every Phase-4 trial the Distiller remained a non-authoritative producer and proof/install remained deterministic, exact-base, and auditable.

## Automation boundary introduced

Phase 5 adds `.github/workflows/rgp-steward-admission-automation.yml` and the governance contract in `docs/distiller/PHASE5_AUTOMATION.md`.

The workflow automates only mechanical stages after semantic reconciliation has already been supplied by the Project Engineering Steward. It requires a separately committed immutable approval request whose commit contains exactly one newly-added automation-request JSON. The request binds approval to GitHub actor `loteque`, requires `project-engineering-steward` authority, identifies already-committed submission/plan/base paths, and explicitly chooses proof-only versus installation mode.

The workflow performs RGP validation, guarded-update pressure tests, deterministic PEMS/2 reconciliation proof, candidate contract validation, deterministic PEMS/COVE generation, proof-evidence persistence in a separate commit, optimistic branch-head checks, and—only when authorized—exact-byte installation in a second commit.

It does not choose canonical semantic identity, decide whether uncertainty is resolved, promote authority, choose reuse/update targets, or authorize installation.

## Proof-only pressure run

The first dry-run request, `PHASE5-DRYRUN-001`, failed closed before validation because the initial workflow incorrectly treated `evidence_key` as a repository file path. The failed immutable request was preserved unchanged.

The workflow was corrected without modifying that failed request. A new immutable approval request, `PHASE5-DRYRUN-002`, then ran as workflow run `32044664554` with `install: false`.

**PASS.** The corrected dry run successfully completed:

- isolated Steward approval validation;
- authoritative RGP validation;
- guarded admission-transaction pressure tests;
- exact-base deterministic PEMS/2 proof;
- candidate contract and graph validation;
- deterministic evidence generation;
- proof evidence persistence in a separate commit.

Canonical installation was correctly skipped. This demonstrates that proof-only automation can run without granting the automation path canonical mutation authority.

## Live automated admission trial — documentation release policy

Submission: `RGP-20260817T091500-0700-008`.

The submitted candidate graph is unchanged from the Phase-3 `docs-release-policy` shadow candidate. It contains three repository-policy decisions from merged PR #51 and one regression-coverage observation.

### Steward semantic reconciliation

Before automation approval, the Steward reconciled the candidate against the then-current 218-record / 14-relation canonical PEMS/2 state.

No equivalent docs-only release-policy meanings existed in canonical memory, so the Steward admitted all four candidate meanings as new durable records and resolved PR #51 to a typed repository source plus immutable source observation. No unrelated existing identity was reused merely to avoid creating a record.

The reconciliation plan remained separately committed and immutable. The workflow did not infer or alter these semantic choices.

### Isolated approval and automated proof

The live approval request was committed alone at `72347aa1286e7061f0e149aabf5f1b0225d89023` with `install: true`.

Workflow run `32044753159` passed all stages. The deterministic proof established:

- exact normalized base SHA-256 `07818a18e982bd0dd58d0273dfac4715212ffbfcd8c5ce89cad129ebf195c7a2`;
- base 218 records / 14 relations;
- candidate 224 records / 14 relations;
- 6 new records / 0 new relations;
- PEMS/2 schema validity and graph integrity;
- deterministic PEMS JCS SHA-256 `e32dae550132582e2f1a9689b04b181989ccb97e978acdb7a47996d8ed347b79`;
- deterministic COVE JCS SHA-256 `1dbf7ee6261863dd92c10d1d51994d7f89fc71f1b6ecb7da7bec67a3f14bd9f1`;
- no canonical mutation during proof.

### Evidence-before-install and exact installation

The workflow persisted the complete proof bundle first, in separate commit `f512792f5e39f78fe437f6373ec93c3932f64a9d`, under:

`docs/handoff/rgp/evidence/RGP-20260817T091500-0700-008.admission-018-v2.runner-automation/`

Before persistence, the workflow verified that the remote branch still pointed to the exact approval commit. Before installation, it verified that the remote branch still pointed to the evidence-persistence commit. Either branch movement would have failed closed.

The exact persisted candidate blobs were then installed in a second commit:

`6e908a125582f49a20def9dbc656b104d9651b06`

Installed canonical blob identities:

- PEMS/2: `ae436b9da10ec01e7eb96f80f0b8ef502827eaea`
- COVE: `fe895cbc47abb316079531407dd103c23fd100c3`

The final immutable Steward disposition is `docs/handoff/rgp/dispositions/RGPD-20260817T092000-0700-013.json`.

## Phase-5 exit gate

**PASS.**

Phase 5 has demonstrated both required operating modes:

1. proof-only Steward-triggered automation with canonical installation disabled;
2. a novel Steward-reconciled Distiller candidate progressing through automated validation, deterministic proof, separate proof-evidence persistence, optimistic concurrency checks, and exact-byte canonical installation.

The safety separation remains intact:

- the Distiller produces immutable RGP candidates but does not admit them;
- the deterministic validator remains a hard protocol boundary;
- the Steward still owns semantic reconciliation and admission authority;
- approval is explicit, actor-bound, isolated from submission/plan mutation, and separately committed;
- proof does not write canonical memory;
- evidence is persisted before installation;
- installation consumes exact persisted candidate bytes rather than regenerating them;
- stale-base and branch-movement conditions fail closed;
- no Distiller self-admission path exists.

## Disposition

Phase 5 is complete. The Steward-triggered guarded automation may now be used as the routine mechanical execution path for reconciled RGP admissions on `project-chat-handoff`.

This does **not** authorize autonomous semantic reconciliation, automatic approval, or Distiller self-admission. Any proposal to automate those authority-bearing decisions requires a separately defined and explicitly authorized evaluation gate.
