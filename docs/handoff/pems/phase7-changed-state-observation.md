# Phase 7 Changed-State Steward Observation

Status: Phase 7 evidence, noncanonical

## Reconciliation input

The Project Engineering Steward supplied a genuine changed-state reconciliation of the canonical `docs/project-chat-handoff.json` without changing production `main`.

- previous handoff source commit: `18ece6c5791da00ff5c14eb79172cf6d7fea5860`
- previous handoff blob: `7f848c9259c63d8095a4b310bcfe6fab11495a88`
- changed handoff source commit: `ff2718a00b3a267407beb446607ea6eeb664e66e`
- changed handoff blob: `e54e268cdd4fc4dad9a340c5a19958b734a74186`
- production `main` in both observations: `1f72f8d61e0799cf94a5dedb3953d533068bf502`
- previous `generated_at`: `2026-08-13T13:08:00-07:00`
- changed `generated_at`: `2026-08-13T21:09:00-07:00`

The semantic change is engineering-memory continuity, not terrain-engine behavior. The changed handoff records the accepted PEMS/COVE v1 and `jcs/1` contracts through Phase 6, the provisional Phase 6 importer boundary, Phase 7 shadow status, the still-gated Phase 8 adoption decision, canonical-authority status, and repository-write safety. The Project Engineering Steward chat summary and decision list were also reconciled accordingly.

`docs/project-chat-handoff.json` remains authoritative. All PEMS/COVE/JCS results in this document are shadow evidence only.

## Validation evidence

GitHub Actions run `31772003438` (`PEMS Phase 7 Shadow Validation`) completed successfully against implementation commit `c449d3a47616ed7120729f05b25957e3239d280b`.

The focused/regression selection completed with 23 passing tests. The workflow verified the exact before/after handoff blobs against Git history before generating the shadow comparison.

### Previous observation

- normalized PEMS records: 138
- expanded normalized bytes: 55,545
- COVE + `jcs/1` bytes: 31,159
- normalized PEMS SHA-256: `21dd50f50c64bb0232304f56674e7683a945e26aab785165e629fa73a589599e`
- COVE + `jcs/1` SHA-256: `136ba1638efa87de291cd742d78919bfcfc36229c6147e937ffc708ac4fffdb8`
- deterministic human reconstruction SHA-256: `1ecd85f1808f588cbbb86bd5d4433a33ad42458596c0ec08b3c2e0431661b4d1`
- source-observation provisional ID: `import:source_observation:5b206d4358781f93074b`
- compact reduction versus expanded: approximately 43.9%

### Changed observation

- normalized PEMS records: 142
- expanded normalized bytes: 57,728
- COVE + `jcs/1` bytes: 32,549
- normalized PEMS SHA-256: `295695b55566fe51a0dcfb19f2c1f167e37142e9478d0e2b96d9017e8ca8b0e4`
- COVE + `jcs/1` SHA-256: `bb56776c789a0e7fa406036b4b77b625d48edc8b94dfca85394d71cb57615313`
- deterministic human reconstruction SHA-256: `f58a886227cf4e1ff7539559eb0083cae7705a80b2e74e17e6d644c3c7b9431b`
- source-observation provisional ID: `import:source_observation:8c186a6ca2398e0cfe5e`
- compact reduction versus expanded: approximately 43.6%

### Transition

- stable candidate IDs: 136
- added candidate IDs: 6
- removed candidate IDs: 2
- expanded byte delta: +2,183 bytes (+3.93%)
- compact byte delta: +1,390 bytes (+4.46%)
- source changed: true
- source-observation changed: true
- canonical-byte stability when source unchanged: not applicable to this changed-source transition
- human-export stability when source unchanged: not applicable to this changed-source transition

The six added candidates are five `decision` candidates plus the new `source_observation`. The two removed candidates are one prior decision wording plus the previous `source_observation`. The decision replacement corresponds to the Steward reconciliation changing the scope statement from modifying only the handoff JSON to modifying Steward-owned continuity artifacts. Stable project, branch, module, chat, role, expectation, external-file, continuation, and unaffected decision identities remain stable where their identity-bearing source fields did not change.

Every generated record remains provisional at the existing Steward admission boundary. No candidate becomes canonical merely because it appears in the shadow.

The uploaded evidence artifact is `phase7-shadow-changed-state-evidence`, artifact ID `9208461432`, with ZIP digest `sha256:df33a4fb5ceff79c728233ca0914eae78254653e85d6508f4fd2ca1736f2f2a5`.

## Semantic preservation assessment

The changed Steward chat retains its stable chat identity while its summary changes, proving content-bearing reconciliation does not require identity rebinding. The newly reconciled PEMS/COVE/JCS, Phase 6 importer, Phase 7/Phase 8 authority, and repository-write-safety outcomes appear as new imported decision candidates and survive PEMS normalization, COVE encoding, `jcs/1` serialization, decode, and deterministic human reconstruction.

Production architecture remains intentionally unchanged because the canonical repository snapshot still points at the same `main` commit. The shadow therefore distinguishes engineering-memory evolution from production-engine evolution rather than inventing a terrain change.

## Provenance and historical-retention assessment

The stable canonical-handoff `source` identity remains unchanged across observations. A new immutable `source_observation` is minted for the changed handoff revision, while the prior observation remains distinguishable in the longitudinal Phase 7 evidence. This is correct provenance evolution for snapshot comparison.

The per-snapshot Phase 6 importer does not accumulate the prior source-observation into the newest generated PEMS document. Phase 7 therefore preserves longitudinal history in its evidence series rather than silently claiming that one imported current snapshot is already a complete historical canonical corpus. Before Phase 8 adoption, the owner/Steward should explicitly decide how validated shadow-era observations and admitted identities seed the first canonical PEMS/COVE document so the frozen historical-retention contract is not weakened during migration.

## Discrepancy: structured engineering-memory direct mapping

The changed canonical handoff now contains structured `project_level.engineering_memory.representation_workstream` and `repository_write_safety` data. The Phase 6 importer does not directly map those nested structures into dedicated PEMS records. Their essential current meaning is preserved in this reconciliation because the Steward also recorded the same outcomes in the imported Project Engineering Steward chat summary and decisions.

The changed-state workflow deliberately asserts `PHASE7_STRUCTURED_ENGINEERING_MEMORY_DIRECT_MAPPING=false` so this limitation cannot be hidden by a successful byte round trip.

This is an adoption-relevant migration-shape discrepancy, not evidence of nondeterminism or data corruption inside the fields the importer does map. Phase 8 should not assume that every legacy nested field has a one-to-one PEMS record merely because the shadow is valid. The adoption decision should either accept the semantic projection strategy explicitly or require additional migration mapping before canonical cutover.

## Phase 7 completion assessment

Together with the earlier real no-change Steward reconciliation, this changed-state observation satisfies the Phase 7 evidence stop condition:

- repeated unchanged canonical state produced identical PEMS, COVE/JCS, and human hashes;
- a genuine changed canonical state produced deterministic changed hashes and reproducible byte deltas;
- stable semantic identities remained stable while changed/new identity-bearing facts produced explicit candidate deltas;
- every candidate remained provisional pending Steward admission;
- source identity remained stable while immutable source-observation identity evolved with source revision;
- changed chat/decision semantics survived the full shadow round trip and deterministic human reconstruction;
- production `main` remained unchanged and was not falsely represented as an engine change;
- longitudinal evidence retains both source observations while exposing that one current-snapshot import alone is not a cumulative historical corpus;
- structured engineering-memory direct mapping is explicitly surfaced as an adoption-relevant discrepancy rather than normalized away;
- actual expanded and compact byte behavior is reproducible and remains favorable without becoming a normative threshold.

Phase 7 can therefore close as an evidence-gathering tranche. This completion does **not** authorize Phase 8 adoption. The next gate is a separate owner/Steward review of the complete Phase 7 evidence, including the historical-seeding and structured-mapping discrepancies, followed by an explicit canonical-adoption decision or remediation request.
