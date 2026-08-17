# Distiller Phase 4 Assessment

Date: 2026-08-17
Contract: `rgp/1`
Status: **PASS — routine Steward-governed admission established**

## Entry condition

Phase 3 passed on a five-shape real-work shadow set with protocol-valid candidates, zero recorded inventions/material omissions/provenance or authority promotions, and low human review burden.

## Guarded admission substrate

Phase 4 used the repository's existing immutable RGP submission, Steward reconciliation, deterministic admission proof, proof-artifact persistence, and exact-base canonical installation machinery. The Distiller never received a direct PEMS/COVE mutation path.

## Routine trial 1 — common no-clip camera

Submission: `RGP-20260817T013000-0700-005`.

**PASS.** The unchanged Distiller candidate entered the immutable submission contract. An invalid Steward representation was rejected mechanically and preserved. A later mechanically valid but duplicate-heavy plan was withheld. The final reconciliation reused existing common-camera identities and admitted only genuinely missing durable meaning. Exact proof artifacts were persisted before guarded installation.

Installation commit: `0f1be824f32f95b8e0e9814168d4c9a4bbf9677d`.

Final disposition: `docs/handoff/rgp/dispositions/RGPD-20260817T014700-0700-010.json`.

This trial established mixed semantic reuse plus genuinely new implementation meaning without producer mutation or duplicate canonical churn.

## Routine trial 2 — resource-loading roadmap uncertainty

Submission: `RGP-20260817T054500-0700-006`.

**PASS.** The unchanged candidate preserved one measured observation, one explicit causal uncertainty, and two planning decisions. The measured scaling-pressure observation and unresolved loading-latency cause were admitted as new durable meaning; two existing planning decisions were reused. Guarded transaction v2 enriched two reused records with stronger typed provenance under exact before-state guards while preserving identity and kind.

Proof candidate: 214 records / 14 relations from a 208-record / 14-relation base.

Installation commit: `40535385b0e9905edba2858492f880c3d4406ac7`.

Final disposition: `docs/handoff/rgp/dispositions/RGPD-20260817T054600-0700-011.json`.

This trial established uncertainty preservation, non-causal promotion of measured evidence, multi-record guarded updates, and mixed reuse/new-meaning admission.

## Routine trial 3 — streaming performance baseline

Submission: `RGP-20260817T073100-0700-007`.

The submitted graph was unchanged from the Phase-3 `streaming-performance-baseline` candidate and contained two quantitative observations, one derived scaling-pressure claim, one project decision, and one unresolved uncertainty.

### Semantic reconciliation

The Steward reconciled the candidate against the exact Trial-2 canonical state:

- `r1` became a new scoped quantitative latency observation;
- `r2` became a new accepted-run metrics observation;
- `r3` reused `pems:proposition:2f835b519a295141a201` rather than duplicating the already-canonical scaling-pressure meaning;
- `r4` reused `pems:decision:e7b384909352ef0ee65c` and enriched its provenance under an exact before-state guard;
- `r5` reused `pems:unresolved_item:fe7a5220140a5fd6527c` rather than creating a second uncertainty record.

PR #49 was resolved to a typed repository source plus immutable source observation. The existing performance report source/observation from Trial 2 was reused.

### Deterministic proof

Proof request run `32040766845` passed:

- authoritative RGP validation passed;
- guarded-update v2 pressure tests passed;
- exact canonical base matched;
- reused-record before state matched exactly;
- reused record identity and kind were preserved;
- candidate PEMS/2 validation and graph integrity passed;
- repeated PEMS and COVE bytes were deterministic;
- the proof runner wrote no canonical state.

The proof candidate has:

- base: 214 records / 14 relations;
- candidate: 218 records / 14 relations;
- 5 reused canonical records;
- 1 guarded reused-record provenance update;
- 4 new records;
- 0 new relations;
- candidate PEMS JCS SHA-256 `07818a18e982bd0dd58d0273dfac4715212ffbfcd8c5ce89cad129ebf195c7a2`;
- candidate COVE SHA-256 `7e9e1c77222df7e5ccbf7b508b0af574c79773b74c8ea1066c156afa4e0458a6`.

The exact proof bundle was persisted under `docs/handoff/rgp/evidence/RGP-20260817T073100-0700-007.admission-016-v2.runner-artifact/` before installation.

### Canonical installation

Guarded install workflow run `32041067475` verified the unchanged Trial-2 base, exact persisted candidate blobs, and candidate validity, then installed the exact candidate bytes atomically.

Installation commit: `a841f0971111893556cea9f5ee4ba490a71eff39`.

Installed canonical blob identities:

- PEMS/2: `b5a3490b0e1e9dafab1c4b8dbdd6fcabd0dca7c0`
- COVE: `25f13eecef75385f938d84e3e3620503df9796c8`

Final disposition: `docs/handoff/rgp/dispositions/RGPD-20260817T080300-0700-012.json`.

### Trial-3 result

**PASS.**

This trial establishes that quantitative evidence can be admitted without converting fixture-specific measurements into universal claims, while semantic reuse prevents duplicate inference/uncertainty records and guarded provenance enrichment preserves canonical identity.

## Phase-4 exit gate

**PASS.**

Three routine Steward-governed Distiller submissions have now exercised the required pressure shapes:

1. mixed semantic reuse plus genuinely new implementation meaning;
2. investigation/uncertainty-heavy evidence with multiple guarded reused-record provenance updates;
3. measured quantitative performance evidence with scoped observations, reused inference/uncertainty meaning, and a guarded provenance update.

Across all three trials:

- Distiller submissions remained immutable;
- deterministic RGP validation remained a hard boundary;
- Steward, not the Distiller, owned semantic identity reconciliation and admission authority;
- duplicate canonical meaning was reused rather than re-added;
- uncertainties remained uncertainties;
- observations remained scoped to their evidence;
- reused-record updates were exact-before-state guarded and identity/kind preserving;
- proof runners did not mutate canonical state;
- proof artifacts were persisted before installation;
- canonical installers required exact base and exact candidate blobs;
- canonical PEMS/COVE mutation occurred only through the guarded installer;
- production `main` was not changed by these admission trials.

## Disposition

Phase 4 is complete. Routine Steward-governed admission is established for the evaluated Distiller workflow.

This does **not** grant the Distiller authority to admit its own output or to write canonical PEMS/COVE directly. Human/Steward semantic reconciliation and the deterministic proof/install boundary remain mandatory.

## Next gate

Proceed to Phase 5 only as a separately defined governance step. The next question is not whether the Distiller can produce or route candidates safely; it is whether any portion of routine reconciliation/admission can be automated further without collapsing the separation among producer, validator, Steward authority, proof, and exact-byte installation.
