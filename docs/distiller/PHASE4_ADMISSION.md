# Distiller Phase 4 — Routine Steward-Governed Admission

Date: 2026-08-17
Contract: `rgp/1`

## Purpose

Phase 4 evaluates routine use of the existing RGP producer-to-Steward admission path with Distiller-produced candidates that have already passed deterministic validation and shadow review.

Phase 4 does not transfer canonical-memory authority to the Distiller. The Distiller remains an RGP producer. The Project Engineering Steward remains responsible for provenance resolution, semantic identity reconciliation, admission policy, canonical PEMS/2 persistence, and disposition.

## Existing guarded pipeline

```text
validated Distiller candidate
    -> immutable RGP submission
    -> Project Engineering Steward reconciliation
    -> immutable Steward disposition
    -> Steward-authored admission transaction plan when mutation is required
    -> read-only RGP Admission Proof
    -> exact persisted PEMS/2 + COVE candidate evidence
    -> explicit guarded canonical install request when admitted
    -> exact-base / exact-byte installation
```

The authoritative coordination contracts remain:

- `docs/handoff/rgp/SUBMISSION_PROTOCOL.md`
- `docs/handoff/rgp/steward_distiller_admission_directive.md`
- `docs/handoff/rgp/RECONCILIATION_EVIDENCE_PROTOCOL.md`

The existing proof and install workflows remain the execution substrate. Phase 4 must not introduce a parallel admission system or Distiller-specific bypass.

## Safety boundaries

1. A Distiller submission is a proposal, never canonical state.
2. Raw candidate semantics are immutable after submission.
3. Deterministic validation does not imply admission or truth.
4. The Steward may reuse canonical identities, admit new identities, retain candidates provisionally, or reject them according to accepted policy.
5. Provenance identifiers are resolved by the Steward; source spelling never creates normative authority.
6. Canonical mutation is allowed only after a successful exact-base deterministic proof and an explicit guarded install request.
7. A no-op or duplicate reconciliation must not manufacture a canonical write merely to demonstrate installation.
8. Canonical PEMS/2 and COVE must remain unchanged when reconciliation concludes that the candidate is already represented or is not admitted.

## Initial routine trial

The first Phase-4 trial uses the Phase-3 `common-no-clip-camera` shadow candidate unchanged.

This sample is intentionally useful for routine reconciliation because the underlying work predates Phase 4 and portions of its meaning are already represented in canonical project memory. The Steward must therefore distinguish semantic reuse/coverage from genuinely new durable meaning rather than blindly appending the candidate.

The producer step creates exactly one immutable submission under `docs/handoff/rgp/submissions/`. The producer does not author the Steward disposition or canonical transaction as part of that same operation.

## Trial evidence

Phase-4 trial evidence lives under:

`docs/distiller/evaluation/phase4/`

It records submission identity, immutable source candidate identity, Steward disposition/proof/install references, canonical before/after blob identities, and whether any write was actually required.

## Exit criterion

Phase 4 is ready to progress only after multiple routine Distiller submissions demonstrate that:

- immutable submissions are accepted by the existing handoff contract;
- Steward reconciliation correctly handles both semantic reuse and genuinely new meaning;
- provenance is resolved without authority promotion;
- graph integrity and proposition kinds survive reconciliation;
- required PEMS/2 mutation proofs pass against exact canonical bases;
- any installation uses exact persisted proof candidates and guarded exact-base requests;
- duplicate/no-op outcomes do not cause artificial canonical churn;
- immutable dispositions make admission outcomes auditable;
- no Distiller-controlled path can directly mutate canonical PEMS/COVE.

Passing Phase 4 may justify considering higher-throughput orchestration of the same guarded pipeline. It does not authorize autonomous canonical truth or removal of Steward governance.
