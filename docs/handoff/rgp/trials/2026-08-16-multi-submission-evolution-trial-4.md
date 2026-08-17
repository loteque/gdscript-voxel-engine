# RGP Trial 4 — Multi-Submission Evolution

## Status

Candidate-producing RGP Engineer trial. This document is not a Steward disposition and does not authorize canonical PEMS/COVE mutation.

## Purpose

Trial 4 tests whether independent RGP submissions can evolve an already-admitted canonical reasoning graph without losing semantic identity, provenance, historical lifecycle, or epistemic distinctions.

The admitted Trial-3 state is the baseline. The trial deliberately combines replayed prior knowledge, new evidence, a stale historical uncertainty, a new unresolved uncertainty, cross-generation derivation, and an unsupported universal generalization.

## Baseline

At trial design time, `project-chat-handoff` head is `8b493fe186be82d0e3cfddb8853106dd7e95754e` and Trial 3 is admitted by `RGPD-20260816T221030-0700-009`.

The RGP producer treats these as context and evidence only. Canonical identity/lifecycle decisions remain Steward-owned.

## Pressure cases

### r1 — replayed admitted observation

Observation: the Trial-2 non-no-op transaction passed its deterministic admission proof.

Expected pressure: semantic/idempotent reuse of the canonical Trial-3 proof-success proposition rather than allocation of a duplicate proposition.

### r2 — new later-generation observation

Observation: Trial 3's guarded transaction v2 passed with an exact before-state lifecycle update to a reused unresolved-item record while preserving identity and kind.

Expected pressure: new semantic identity grounded in the immutable Trial-3 v2 proof artifact.

### r3 — new canonical-install observation

Observation: Trial 3 installed the exact persisted proof candidate as canonical PEMS/2/COVE state and preserved unrelated tree content.

Expected pressure: remain distinct from proof success. Passing a proof and installing its exact candidate bytes are different events.

### r4 — stale historical uncertainty replay

Uncertainty: whether the standing Admission Proof workflow preserves its guarantees for a novel non-no-op transaction remains unverified.

This deliberately restates the Trial-2 uncertainty after Trial 3 has already preserved that uncertainty historically and superseded its current/open state.

Expected pressure: do not reactivate a resolved historical unresolved-item merely because a later candidate again presents the same uncertainty text. The Steward must reconcile truth/lifecycle against current canonical state.

### r5 — genuinely new uncertainty

Uncertainty: whether transaction v2 preserves its guarantees when one connected admission updates multiple reused canonical records remains unverified.

Expected pressure: create/reconcile a new current uncertainty if repository evidence does not already answer it. This is materially narrower and later than r4.

### r6 — cross-generation derived claim

Claim: RGP admission has demonstrated multi-generation canonical evolution across additive non-no-op admission and a guarded reused-record lifecycle transition.

Premises: r1, r2, r3.

Expected pressure: preserve a derivation whose constitutive evidence spans multiple admitted generations and distinguishes proof success from canonical installation.

### r7 — unsupported universal generalization

Claim: the successful Trial-3 v2 proof establishes guarded updates are correct for any number of reused-record updates in every future admission transaction.

Expected pressure: structurally valid but epistemically unsupported. One successful single-record guarded update does not prove arbitrary future batch behavior.

## Relations

- r1 contradicts r4
- r1 supersedes r4
- r7 contradicts r5

The r1→r4 pair intentionally replays semantics already represented canonically. This tests relation idempotency and historical-state preservation rather than requesting a second canonical effect.

The r7→r5 contradiction should not force admission of r7; structural connectivity is not truth authority.

## Success criteria

Trial 4 succeeds as an RGP production trial if:

1. the immutable candidate passes `rgp-validator/1`;
2. prior canonical knowledge can be replayed without duplicate semantic effects;
3. historical r4 cannot be silently reactivated as current uncertainty;
4. new r5 remains distinct from r4;
5. r2 and r3 remain distinct proof-versus-install events;
6. r6 retains all three constitutive premises;
7. r7 can be rejected epistemically without weakening structural rules;
8. producer tooling makes no canonical identity, provenance-resolution, lifecycle, admission, or truth decisions.

## Candidate submission

`docs/handoff/rgp/submissions/RGP-20260816T222500-0700-004.json`

## Authority boundary

Expected outcomes in this trial document are pressure-test hypotheses only. The Project Engineering Steward independently reconciles semantic identity, provenance, lifecycle, truth, graph disposition, and any canonical PEMS/2/COVE mutation.
