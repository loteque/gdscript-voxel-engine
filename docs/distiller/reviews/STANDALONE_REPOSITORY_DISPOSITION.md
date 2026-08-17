# Steward Disposition — Standalone Reasoning Distiller Repository

Date: 2026-08-17
Proposal: `docs/distiller/PROPOSAL_STANDALONE_REPOSITORY.md`
Steward review: `docs/distiller/reviews/STANDALONE_REPOSITORY_STEWARD_REVIEW.md`
Architect review: `docs/distiller/reviews/STANDALONE_REPOSITORY_ARCHITECT_REVIEW.md`
Final decision: **APPROVED WITH REQUIRED AMENDMENTS**

## Steward recommendation

**Approve with changes.** The extraction preserves the established governance model if project-owned canonical state remains project-owned, reference evidence retains source identity, parity includes authority-negative tests, and generic reconciliation mechanisms do not claim reconciliation authority.

## Architect recommendation

**Approve with changes.** Extract before Phase 6.1, make dependency direction explicit, treat PEMS/2+COVE as a first-party reference backend rather than Distiller-core semantics, use a narrow voxel-engine adapter, independently version the standalone system, and require a controlled cutover/sunset of the embedded implementation.

## Required amendments

The approved extraction plan incorporates the following amendments:

1. **Reference ownership metadata.** The extraction manifest distinguishes `generic`, `reference-copy`, and `project-owned/not-moved`. Copying a voxel-engine artifact does not transfer canonical ownership.
2. **Source identity preservation.** Reference-corpus entries preserve source repository, frozen source commit/ref, source path, blob hash, and sufficient source-registry/resolver metadata for their original evidentiary interpretation.
3. **Authority-negative parity.** Phase 6.0 includes tests preventing Distiller self-admission, executor semantic reconciliation, source-name authority inference, uncertainty promotion, and unguarded canonical mutation, in addition to positive validator/evaluation/proof parity.
4. **Authority-neutral reconciliation machinery.** The standalone repository may define Steward-plan schemas and deterministic mechanics, but consuming-project governance supplies the actual Steward authority and semantic decisions.
5. **PEMS/2+COVE backend boundary.** PEMS/2 transaction/proof/COVE/install machinery moves, if moved, as a clearly named first-party reference backend. It is not part of `rgp/1` semantics. No speculative general backend plugin framework is authorized during extraction.
6. **Frozen extraction baseline.** After this disposition, declare one exact voxel-engine commit as the extraction source baseline before extraction writes begin. The manifest binds to that commit.
7. **Parity semantics.** Deterministic components use exact bytes/hashes where promised; fresh model-produced Distiller runs use the established semantic scoring/stability criteria rather than byte equality.
8. **Controlled cutover.** After standalone parity, perform a non-canonical dual-run comparison, pin voxel-engine to an immutable standalone release/tag/commit, then sunset the embedded generic implementation. Dual-run must never create duplicate canonical admissions.
9. **Independent version topology.** Standalone release versions are distinct from protocol/contract versions; consuming projects pin immutable standalone releases.
10. **Second-project pressure before broader abstraction.** A second independent project corpus is required before treating untested cross-project assumptions as generic requirements or expanding backend/plugin abstractions without demonstrated need.

## Disagreements and resolution

There is no substantive Steward/Architect disagreement.

The only issue requiring architectural resolution was Steward finding S6: whether demonstrated PEMS/2+COVE admission machinery belongs in the generic extraction. The Architect resolves this by retaining it as a **first-party reference backend**, separate from the Distiller/RGP semantic core and without prematurely introducing a generalized backend plugin architecture. The Steward accepts this resolution because it preserves project authority boundaries and prevents persistence mechanics from becoming semantic authority.

## Final extraction decision

**APPROVED WITH REQUIRED AMENDMENTS.**

The Reasoning Distiller should be extracted into a standalone repository before Phase 6.1 production-interface work continues.

This approval does not authorize semantic redesign during extraction and does not transfer voxel-engine canonical-memory ownership to the standalone repository.

## Approved extraction invariants

1. Distiller produces candidate RGP only.
2. Distiller has no semantic-reconciliation, admission, or canonical-write authority.
3. Steward owns semantic reconciliation and admission authority for the consuming project.
4. Deterministic validation/proof/execution does not confer semantic authority.
5. Voxel-engine canonical PEMS/COVE remains voxel-engine-owned.
6. Reference copies are non-authoritative and provenance-bound to their frozen source identities.
7. `rgp/1` semantics remain unchanged during extraction.
8. Raw historical evaluation candidates/evidence are not post-hoc edited.
9. Extraction parity is blocking before Phase 6.1.
10. PEMS/2+COVE is a backend concern, not RGP semantic core.
11. No speculative plugin/ontology expansion is authorized by extraction alone.
12. No canonical dual-write occurs during migration.
13. The embedded generic implementation is sunset after successful pinned standalone cutover.

## Approved next implementation step

Begin **Phase 6.0 — Repository Extraction and Behavioral Parity** only.

The first implementation action is to freeze and record the exact `gdscript-voxel-engine/project-chat-handoff` source commit that includes this disposition, then create the standalone repository skeleton and extraction manifest from that immutable baseline.

Do not begin Phase 6.1 interface redesign until the standalone extraction-parity gate passes.
