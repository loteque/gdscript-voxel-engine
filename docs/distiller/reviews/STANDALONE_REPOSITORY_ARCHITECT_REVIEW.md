# Architect Review — Standalone Reasoning Distiller Repository

Date: 2026-08-17
Role: Project Architect
Proposal: `docs/distiller/PROPOSAL_STANDALONE_REPOSITORY.md`
Attached Steward review: `docs/distiller/reviews/STANDALONE_REPOSITORY_STEWARD_REVIEW.md`
Recommendation: **APPROVE WITH CHANGES**

## Inputs reviewed

This review considers both the original standalone-repository proposal and the complete Steward review. The Steward findings S1–S7 are treated as constraints/input rather than being reviewed in isolation.

## Architectural findings

### A1 — Repository extraction is correctly timed

Agree with the proposal and Steward. Phase 6 is where stable external interfaces begin to harden. Extracting before those contracts are frozen reduces the risk that voxel-engine directory layout, GitHub workflow names, canonical file paths, or domain concepts become accidental generic API.

### A2 — Use a layered repository, not a monolithic generic package

The proposed layout should be amended to make dependency direction explicit:

```text
protocol/rgp            # semantic interchange contract
producer/               # Distiller invocation and evidence consumption
validation/             # deterministic RGP validation
reconciliation/         # Steward plan schemas/mechanical validation only
backends/
    pems2/               # first-party reference canonical-memory backend
orchestration/          # lifecycle and execution coordination
corpus/voxel-engine/    # immutable reference corpus
```

Dependency direction should flow from orchestration/backends toward protocol contracts, never from protocol/producer toward voxel-engine or a specific canonical backend.

### A3 — Response to Steward S6: PEMS/COVE should be a first-party reference backend, not the Distiller core

The demonstrated PEMS/2 proof and COVE exact-byte installation are valuable and should move with the standalone system because they prove the admission architecture. However, they are persistence/backend concerns rather than `rgp/1` semantics.

**Required architectural change:** place PEMS/2/COVE schemas, proof, transaction application, and exact-install logic behind a clearly named first-party backend boundary such as `backends/pems2/`. Do not invent a broad backend plugin API during extraction. The initial orchestration may explicitly support the PEMS/2 backend while preserving package/dependency separation.

This satisfies Steward S6 without prematurely designing an abstraction unsupported by a second backend.

### A4 — Generic Steward mechanisms must be authority-neutral

Agree with Steward S1/S5. `reconciliation/` may define transaction representation, hashing/binding, deterministic structural checks, and lifecycle artifacts. It must not contain policy that decides semantic identity or whether a candidate deserves admission. The consuming project supplies the authorized Steward decision.

### A5 — Project adapter should be narrow

The voxel-engine adapter should convert project-observable material into the generic evidence-envelope contract and resolve project-local source metadata. It should not transform RGP semantics, reinterpret record kinds, or perform reconciliation.

Avoid a general plugin framework in 6.0. A documented adapter interface plus the voxel-engine implementation is enough until a second consumer establishes common requirements.

### A6 — Migration sequencing should add a dual-run interval

The proposal correctly separates extraction from integration redesign, but a short dual-run parity interval is warranted before deleting the embedded generic implementation.

Recommended sequence:

1. freeze exact voxel-engine extraction baseline after final disposition;
2. copy/classify artifacts with manifest and provenance;
3. make standalone tests pass without semantic changes;
4. tag an extraction-parity baseline in the standalone repository;
5. have voxel-engine invoke both embedded and standalone implementations on a fixed non-canonical test batch and compare outputs/mechanical results;
6. switch voxel-engine integration to the standalone version;
7. only then remove duplicated generic implementation from voxel-engine.

Dual-run must not produce duplicate canonical admissions.

### A7 — Version topology

Version the standalone system independently from the voxel engine. Keep protocol versions (`rgp/1`, evidence-envelope version, transaction contracts) distinct from repository/package release versions. A standalone release declares the protocol versions it supports.

The voxel-engine integration should pin an immutable release/tag/commit rather than track the standalone default branch.

### A8 — Reference corpus ownership and provenance

Agree with Steward S2/S3. `corpus/voxel-engine/` is evidence, not canonical ownership. Its manifest must identify copied project-owned artifacts as reference copies and preserve original repository/ref/path/blob identities. Source-resolution fixtures should be sufficient to replay evaluation without relying on live mutable branch state where practical.

### A9 — Extraction parity must be byte/behavior aware

Agree with Steward S4. For deterministic components, parity should compare exact expected bytes/hashes where the existing contract promises determinism. For model-produced Distiller output, parity should use the established scoring/stability methodology rather than requiring impossible byte identity across fresh semantic invocations. Authority-negative and malformed-input cases are mandatory.

### A10 — Split-brain prevention needs an explicit sunset gate

The proposal says duplicated generic implementation should eventually be removed; make this a blocking migration milestone. After voxel-engine switches to a pinned standalone release and parity passes, the embedded generic implementation becomes read-only historical evidence or is removed. No feature development should continue in both copies.

## Response to Steward findings

- **S1 Authority boundary:** agree without modification.
- **S2 Project ownership:** agree; require `reference-copy` classification.
- **S3 Provenance:** agree; preserve source repo/ref/path/blob and resolver metadata.
- **S4 Authority-negative parity:** agree; make blocking Phase-6.0 tests.
- **S5 Mechanism versus authority:** agree; reconciliation package is authority-neutral machinery.
- **S6 PEMS/COVE boundary:** resolve by making PEMS/2+COVE a first-party reference backend package, without inventing a generalized plugin framework yet.
- **S7 Baseline freeze:** agree; freeze after final disposition and before extraction writes.

## Risks

- Over-generalizing a backend interface before a second backend exists.
- Allowing orchestration code to depend on voxel-engine paths or GitHub-specific assumptions that should belong to adapters/deployment configuration.
- Treating model output parity as byte identity rather than semantic/evaluation parity.
- Running embedded and standalone paths against canonical state simultaneously during migration.
- Failing to sunset the embedded implementation after successful cutover.

## Architect recommendation

**APPROVE WITH CHANGES.**

Proceed with extraction before Phase 6.1, subject to the amendments above. Phase 6 should continue in the standalone repository after the Phase-6.0 extraction-parity gate passes. The voxel engine should remain the first reference corpus and consumer, with a pinned standalone release after cutover.
