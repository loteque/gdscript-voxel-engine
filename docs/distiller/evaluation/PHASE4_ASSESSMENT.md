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

## Routine trial 2 — resource-loading roadmap uncertainty

Submission: `RGP-20260817T054500-0700-006`.

The submitted `candidate_graph` is unchanged from the Phase-3 `resource-loading-roadmap` shadow candidate. It contains one measured observation, one explicit uncertainty, and two project/planning decisions.

### Semantic reconciliation

The Steward preserved the baseline's causal uncertainty rather than promoting it to a fact. Two candidate meanings were already canonical and were reused:

- `r3` maps to `pems:decision:e7b384909352ef0ee65c` (`Resource loading was elevated ahead of LOD.`);
- `r4` maps to `pems:decision:ca231dae6fce15247762` (outcome-oriented, nonprescriptive planning guidance).

The measured scaling-pressure observation and unresolved loading-latency cause were admitted as genuinely new durable meaning. Baseline and PR #52 source identifiers were resolved into typed immutable source observations.

Because PR #52 supplied stronger provenance for both reused decisions, the Steward used guarded admission transaction v2 to enrich both existing records while preserving identity and kind. This intentionally exercised a connected admission containing two exact-before-state updates to reused canonical records.

### Deterministic proof

Proof request run `32031251395` passed:

- authoritative RGP validation passed;
- guarded-update v2 pressure tests passed;
- exact canonical base matched;
- both reused-record before states matched exactly;
- both reused record identities and kinds were preserved;
- candidate PEMS/2 validation and graph integrity passed;
- repeated PEMS and COVE bytes were deterministic;
- the proof runner wrote no canonical state.

The accepted proof candidate has:

- base: 208 records / 14 relations;
- candidate: 214 records / 14 relations;
- 2 reused canonical records;
- 2 guarded reused-record provenance updates;
- 6 new records;
- 0 new relations;
- candidate PEMS JCS SHA-256 `86288d731731c2cb0e01e1f17fd59b6506b9e79a6078921e3da630a50fea09cd`;
- candidate COVE SHA-256 `f2db2f559a9f9baf72aa58e2b3cf5e2823c3d50258dbd4ca60d5eea617d89793`.

The exact proof artifact bytes were persisted under `docs/handoff/rgp/evidence/RGP-20260817T054500-0700-006.admission-015-v2.runner-artifact/` in commit `5b3e3e9a7ecccc323ae3f2d97a59187635588ec7` before installation.

### Canonical installation

The guarded install request verified the unchanged canonical base and exact persisted candidate blobs and installed the exact candidate bytes atomically.

Installation commit: `40535385b0e9905edba2858492f880c3d4406ac7`.

Installed canonical blob identities:

- PEMS/2: `807ccc0fa708966ee300053738f16fc086994094`
- COVE: `085d7b211529e4d313ebb10f60f6592ef0646c9c`

The final immutable Steward disposition is `docs/handoff/rgp/dispositions/RGPD-20260817T054600-0700-011.json`.

## Trial-2 result

**PASS.**

This trial demonstrates:

- uncertainty remains uncertainty through Distiller submission and canonical admission;
- measured evidence is not promoted into an unsupported causal explanation;
- semantic reuse works for existing roadmap and planning decisions;
- reused records can gain new typed primary provenance without identity churn;
- one connected v2 transaction can safely update multiple reused canonical records under exact before-state guards;
- new observations and unresolved questions can be admitted alongside reused meaning;
- proof, persistence, and canonical installation remain separate auditable stages.

## Current Phase-4 disposition

**Phase 4 remains active, not complete.**

Two routine submissions have now passed: one mixed reuse/new-meaning implementation candidate and one investigation/uncertainty-heavy candidate with guarded multi-record provenance updates. The remaining high-value pressure shape before closing the Phase-4 gate is a measured-performance or policy candidate, preferably one that tests whether quantitative evidence or policy semantics can be reconciled without duplicate canonical churn or authority promotion.
