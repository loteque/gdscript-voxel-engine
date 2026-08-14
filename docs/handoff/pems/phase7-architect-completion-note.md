
## ARCH-20260813T220800-0700-014

- timestamp: `2026-08-13T22:08:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-012`, `STEWARD-20260813-013`
- subject: PEMS/COVE Phase 7 longitudinal shadow validation complete

### Assessment

Phase 7 is complete as the evidence-gathering tranche authorized by `STEWARD-20260813-012`. The project now has multiple real Steward reconciliation observations covering both unchanged canonical state and a genuine changed canonical state while `docs/project-chat-handoff.json` remained authoritative throughout.

The no-change observation proved byte-stable regeneration when canonical semantics do not change. The changed-state observation compared handoff source commit `18ece6c5791da00ff5c14eb79172cf6d7fea5860` / blob `7f848c9259c63d8095a4b310bcfe6fab11495a88` with Steward reconciliation commit `ff2718a00b3a267407beb446607ea6eeb664e66e` / blob `e54e268cdd4fc4dad9a340c5a19958b734a74186`. Production `main` remained `1f72f8d61e0799cf94a5dedb3953d533068bf502`, so the observed transition is correctly attributed to engineering-memory continuity rather than terrain-engine behavior.

### Longitudinal evidence

The accepted no-change evidence is recorded in `docs/handoff/pems/phase7-no-change-observation.md`. It produced 138 records, 55,545 expanded bytes, 31,159 COVE + `jcs/1` bytes, PEMS SHA-256 `21dd50f50c64bb0232304f56674e7683a945e26aab785165e629fa73a589599e`, compact SHA-256 `136ba1638efa87de291cd742d78919bfcfc36229c6147e937ffc708ac4fffdb8`, and human-export SHA-256 `1ecd85f1808f588cbbb86bd5d4433a33ad42458596c0ec08b3c2e0431661b4d1`. Repeating the unchanged source produced identical hashes and zero identity/size deltas.

The real changed-state validation ran in GitHub Actions run `31772003438` against Phase 7 implementation commit `c449d3a47616ed7120729f05b25957e3239d280b`, with 23 focused/regression tests passing. The changed observation produced 142 records, 57,728 expanded bytes, and 32,549 compact bytes. Its PEMS SHA-256 is `295695b55566fe51a0dcfb19f2c1f167e37142e9478d0e2b96d9017e8ca8b0e4`; COVE + `jcs/1` SHA-256 is `bb56776c789a0e7fa406036b4b77b625d48edc8b94dfca85394d71cb57615313`; deterministic human-export SHA-256 is `f58a886227cf4e1ff7539559eb0083cae7705a80b2e74e17e6d644c3c7b9431b`.

Across the changed transition, 136 provisional candidate identities remained stable, six candidates were added, and two were removed. The added set contains five decision candidates plus the new immutable source observation. The removed set contains one superseded decision wording plus the previous source observation. Expanded size increased by 2,183 bytes and compact size by 1,390 bytes. Compact representation remained approximately 43.6% smaller than expanded PEMS for the changed observation; this remains observational evidence rather than a normative compression threshold.

The stable canonical-handoff `source` identity persisted while the source-observation candidate changed from `import:source_observation:5b206d4358781f93074b` to `import:source_observation:8c186a6ca2398e0cfe5e`, matching the frozen provenance model. Every generated record remains provisional at the Steward admission boundary.

### Semantic preservation and reconstruction

The Project Engineering Steward chat retained its stable chat identity while its summary changed, demonstrating stable identity across content-bearing reconciliation. Newly reconciled PEMS/COVE/JCS, Phase 6 importer, Phase 7/Phase 8 authority, and repository-write-safety outcomes became explicit provisional decision records and survived PEMS normalization, COVE encoding, `jcs/1` canonical serialization, decode, and deterministic human reconstruction.

The changed-state evidence is documented in `docs/handoff/pems/phase7-changed-state-observation.md`. The uploaded evidence artifact from run `31772003438` is `phase7-shadow-changed-state-evidence`, artifact ID `9208461432`, ZIP digest `sha256:df33a4fb5ceff79c728233ca0914eae78254653e85d6508f4fd2ca1736f2f2a5`.

### Discrepancies surfaced for Phase 8 review

Two adoption-relevant discrepancies remain visible rather than being normalized away.

First, the per-snapshot Phase 6 importer does not accumulate the previous source-observation into the newest generated PEMS snapshot. Longitudinal Phase 7 evidence retains both observations, but a future canonical cutover must explicitly decide how validated shadow-era observations and admitted identities seed the first canonical PEMS/COVE corpus so the frozen historical-retention contract is not weakened.

Second, newly structured `project_level.engineering_memory.representation_workstream` and `repository_write_safety` values are not directly mapped to dedicated PEMS records by the Phase 6 importer. Their essential current meaning survives this reconciliation because the Steward also records it in imported chat summaries and decision outcomes. The validation workflow explicitly asserts `PHASE7_STRUCTURED_ENGINEERING_MEMORY_DIRECT_MAPPING=false` so this projection limitation cannot be hidden by a valid round trip.

These findings do not invalidate Phase 7. Phase 7's purpose is to gather longitudinal migration evidence and surface discrepancies before adoption. They do mean Phase 8 must treat migration seeding/history and structured legacy-field projection as explicit adoption questions rather than assuming the shadow representation is already a drop-in canonical replacement.

### Authority and stop condition

`docs/project-chat-handoff.json` remains canonical. No `docs/project-chat-handoff.cove.json` authority artifact was adopted, no autonomous-agent runtime work or production voxel-engine behavior changed, and no pull request or merge was created.

The Phase 7 stop condition is satisfied: multiple real Steward reconciliations have been observed; deterministic unchanged-state regeneration, changed-state identity/admission behavior, provenance evolution, semantic preservation, human reconstruction, discrepancies, historical-retention implications, compatibility/regression behavior, and reproducible size evidence are documented.

Phase 8 canonical adoption remains unauthorized. The next gate is owner/Steward review of this Phase 7 evidence and an explicit adoption, remediation, or defer decision.

### Human reasoning

Phase 7 needed to prove more than that one importer invocation works. The unchanged observation demonstrates that a no-op Steward reconciliation does not create phantom semantic or byte drift. The changed observation then demonstrates that a legitimate continuity update produces bounded, explainable identity and byte changes while stable semantic identities remain stable.

The most useful result is that the shadow exposed migration-shape questions before canonical authority moved. A green serializer round trip cannot tell us whether every legacy nested field deserves a direct PEMS record or how pre-adoption observations should seed canonical history. Keeping those questions visible is exactly why shadow validation precedes the Phase 8 owner/Steward adoption decision.
