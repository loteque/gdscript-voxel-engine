# Steward Review — Standalone Reasoning Distiller Repository

Date: 2026-08-17
Role: Project Engineering Steward
Proposal: `docs/distiller/PROPOSAL_STANDALONE_REPOSITORY.md`
Recommendation: **APPROVE WITH CHANGES**

## Review basis

The proposal is consistent with the established authority invariant: the Distiller is a candidate producer only; the Project Engineering Steward owns semantic reconciliation and admission authority; deterministic tooling may validate/prove/execute an authorized transaction but does not acquire semantic authority.

## Findings

### S1 — Authority boundary is preserved

**Finding:** Accept.

The proposal correctly preserves Steward authority and explicitly denies the Distiller semantic-identity, reconciliation, admission, and canonical-write authority. The standalone repository may define the abstract Steward role and transaction contracts, but a consuming project must define the actual authority assignment and policy under which its Steward acts.

### S2 — Canonical project memory must remain project-owned

**Finding:** Accept with clarification.

Voxel-engine canonical PEMS/COVE, project-specific Steward dispositions, authority assignments, and historical canonical transactions remain owned by the voxel-engine project. They may be referenced by the standalone evaluation corpus, but copying them for regression evidence must not make the standalone repository authoritative for voxel-engine canonical state.

**Required amendment:** the extraction manifest must distinguish `reference-copy` from `ownership-transfer`. Any copied project-owned artifact is explicitly non-authoritative outside its source project.

### S3 — Evaluation evidence must retain source identity

**Finding:** Accept with requirement.

The voxel-engine corpus is valuable precisely because it is fixed evidence from completed proving work. Raw candidates and supplied evidence must remain immutable. Expected/scoring material may be versioned, but historical evaluation results must not be rewritten to fit later behavior.

**Required amendment:** every copied reference artifact must retain source repository, source ref/commit, source path, and source blob hash. Where an evidence registry points to project-local source IDs, the standalone corpus must carry enough resolver metadata to reproduce the original interpretation without inferring semantics from identifier spelling.

### S4 — Extraction parity must include authority-negative tests

**Finding:** Proposal is directionally correct but parity is underspecified.

Structural validator parity alone is insufficient. The extraction gate must demonstrate that the standalone system still rejects or prevents Distiller self-admission, executor semantic reconciliation, authority inference from source naming, uncertainty promotion, and unguarded canonical mutation.

**Required amendment:** Phase 6.0 parity explicitly includes the existing authority-boundary and failure-path tests, not merely successful corpus reproduction.

### S5 — Generic reconciliation contracts must not imply generic reconciliation authority

**Finding:** Accept with wording constraint.

It is appropriate for the standalone repository to own schemas/tools for expressing a Steward reconciliation plan. It is not appropriate for the standalone repository to become the source of authority for a consuming project's semantic decisions.

**Required amendment:** generic reconciliation artifacts are described as mechanisms/contracts. Authority is always supplied by the consuming project's governance configuration or authorized Steward context.

### S6 — PEMS/COVE admission machinery requires a boundary decision

**Finding:** Requires Architect attention.

The proposal lists generic proof/executor mechanisms while the demonstrated implementation is PEMS/2 and COVE-specific. The standalone system may ship those as a reference memory backend, but it should not equate the Distiller core with PEMS/COVE persistence unless that coupling is an explicit architectural decision.

The Architect should determine whether PEMS/COVE becomes a first-party backend package/adapter or remains in voxel-engine until a generic canonical-memory interface is justified.

### S7 — Extraction source must be frozen after review disposition

**Finding:** Required sequencing clarification.

The extraction manifest cannot safely use an arbitrary moving branch tip. The final review/disposition should be committed first; then one exact source commit should be declared as the extraction baseline. No extraction implementation should precede that freeze.

## Risks

- Project-owned historical records could be mistaken for standalone canonical truth if copied without ownership metadata.
- A generic `reconciliation/` package could accidentally blur mechanism with Steward authority.
- PEMS/COVE-specific mechanics could be mislabeled as generic Distiller semantics.
- Corpus transformation during migration could invalidate the value of prior evaluation evidence.
- Maintaining generic implementation in both repositories after parity would create split-brain behavior.

## Steward recommendation

**APPROVE WITH CHANGES.**

Repository extraction is appropriate before Phase-6 production interfaces are frozen, provided the final disposition incorporates S2–S7. No extraction should begin until the Architect review is complete and a final disposition freezes the approved invariants and next step.

## Submission to Architect

The Architect is requested to review the original proposal together with this complete Steward review. In particular, address S6 explicitly and evaluate whether the proposed package layout cleanly separates the semantic producer/protocol from project-specific evidence adapters and canonical-memory backends.
