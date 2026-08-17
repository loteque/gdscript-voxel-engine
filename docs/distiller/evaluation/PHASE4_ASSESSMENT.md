# Distiller Phase 4 Assessment

Date: 2026-08-17
Contract: `rgp/1`
Status: **routine Steward-governed admission in progress**

## Entry condition

Phase 3 passed on a five-shape real-work shadow set with protocol-valid candidates, zero recorded inventions/material omissions/provenance or authority promotions, and low human review burden.

## Guarded admission substrate

Phase 4 uses the repository's existing immutable RGP submission, Steward reconciliation, deterministic admission proof, proof-artifact persistence, and exact-base canonical installation machinery. The Distiller has no direct PEMS/COVE mutation path.

## Routine trial 1 — common no-clip camera

Submission: `RGP-20260817T013000-0700-005`.

The submitted `candidate_graph` is unchanged from the Phase-3 `common-no-clip-camera` shadow candidate.

### Reconciliation pressure encountered

The first Steward plan (`steward-012`) was rejected by the deterministic PEMS/2 transaction runner even though the immutable RGP submission passed validation. The rejected plan incorrectly represented RGP `decision` records as PEMS proposition records and used unsupported source-locator fields. The failure was preserved; neither the submission nor the failed plan was edited in place.

The corrected `steward-013` plan passed deterministic proof, but Steward semantic review withheld it from installation because it would have added duplicate canonical records for common-camera ownership and the historical demo compatibility adapter.

The narrowed `steward-014` plan reused the existing canonical identities for those already-represented meanings and admitted only four new records: the resolved PR source, its immutable source observation, the explicit MobileTouchControls non-goal decision, and the headless-validation wiring observation.

### Deterministic proof

Proof request run `32011861367` passed:

- authoritative RGP validation passed;
- deterministic PEMS/2 transaction passed;
- candidate PEMS/2 schema/semantic validation passed;
- graph integrity passed;
- exact-base check passed;
- repeated PEMS and COVE bytes were deterministic;
- the proof runner wrote no canonical state.

The accepted proof candidate has:

- base: 204 records / 14 relations;
- candidate: 208 records / 14 relations;
- 4 reused canonical records;
- 4 new records;
- 0 new relations;
- candidate PEMS JCS SHA-256 `8f6e0c2141b83f1f50fad7b6e7eda44176ce7b4a59f5a07940a0a64c2bac7edf`;
- candidate COVE SHA-256 `d9b6590580a83f7120684f17a2b793bdbce15d73902516dd5b028ba35a6165a1`.

The exact proof artifact bytes were persisted under `docs/handoff/rgp/evidence/RGP-20260817T013000-0700-005.admission-014.runner-artifact/` before installation.

### Canonical installation

The explicit guarded install request verified the unchanged canonical base and exact persisted candidate blobs, validated the candidate, and installed the exact candidate bytes in one commit.

Installation commit: `0f1be824f32f95b8e0e9814168d4c9a4bbf9677d`.

Installed canonical blob identities:

- PEMS/2: `3060c588368e58bf11967775527ae2283b125f2e`
- COVE: `042b0b2f7d8a855fd45faf22a8db8feb28ac0028`

The final immutable Steward disposition is `docs/handoff/rgp/dispositions/RGPD-20260817T014700-0700-010.json`.

## Trial-1 result

**PASS.**

This trial demonstrates all of the following simultaneously:

- a Distiller candidate can enter the existing immutable submission contract unchanged;
- a bad Steward representation is rejected mechanically without corrupting or rewriting the producer submission;
- a mechanically valid but semantically duplicate-heavy plan can be withheld before installation;
- canonical identity reuse can eliminate duplicate churn;
- new durable meaning can be admitted alongside reused canonical meaning;
- raw source identifiers can be resolved into canonical typed provenance without authority promotion;
- proof and installation remain separate, exact-base, auditable stages;
- the Distiller never directly writes canonical PEMS/COVE.

## Current Phase-4 disposition

**Phase 4 remains active, not complete.**

The exit criterion calls for multiple routine submissions, including both semantic-reuse and genuinely new-meaning pressure. Trial 1 exercised a mixed reuse/new-meaning admission successfully. Additional routine Distiller submissions should now test at least an investigation/uncertainty-heavy candidate and a measured-performance or policy candidate before the Phase-4 gate is closed.
