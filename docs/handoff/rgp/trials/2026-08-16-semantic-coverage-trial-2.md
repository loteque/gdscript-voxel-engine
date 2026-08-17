# RGP Distillation Trial 2 — Semantic Coverage

## Goal

Exercise RGP semantics that the first admission trial did not materially cover, while keeping the source slice small and real.

This trial uses the project transition from a trial-scoped RGP admission runner to the standing `RGP Admission Proof` workflow.

The candidate submission is:

`docs/handoff/rgp/submissions/RGP-20260816T190100-0700-002.json`

## Immutable source slice

The graph is grounded in two durable project artifacts:

1. `docs/handoff/rgp/dispositions/RGPD-20260816T183100-0700-003.json`
   - blob `24dec513a43fc95c8fbda186260f61f27c3cfad2`
   - records the then-current non-blocking defect `NO_GENERIC_REPOSITORY_NATIVE_RGP_ADMISSION_RUNNER`.

2. `docs/handoff/rgp/tooling/ADMISSION_TOOLING_STATUS_2026-08-16.md`
   - blob `d53b49792a645d5775a15fea980b671d74b922f3`
   - records the later standing workflow, its successful no-op self-test, and the proof-only/Steward-authority boundary.

## Coverage graph

The candidate intentionally exercises:

- `observation`
- `assumption`
- `uncertainty`
- derived `claim`
- `premise`
- `contradicts`
- `supersedes`
- `depends_on`

### Records

- `r1` observation: no generic repository-native RGP admission runner exists.
- `r2` observation: a standing proof workflow now exists and does not install canonical state.
- `r3` assumption: the standing workflow is representative enough of the proven trial-specific execution path to use for subsequent admissions.
- `r4` uncertainty: behavior on a novel non-no-op transaction remains unverified.
- `r5` derived claim: the standing workflow remains suitable for Steward-governed admission proofs; premises are `r2` and `r3`.
- `r6` observation: the standing workflow is read-only and leaves canonical installation to the Steward.
- `r7` adversarial claim: a successful no-op self-test proves correctness for every future non-no-op transaction.

`r7` is intentionally included as a structurally valid but semantically unsupported pressure candidate. It must not be treated as a production-quality distillation proposition. The trial expects the Steward to reject it rather than allowing structural validity to masquerade as epistemic validity.

### Relations

- `r2 contradicts r1`: the bare current-state propositions are materially incompatible.
- `r2 supersedes r1`: the later workflow state replaces the earlier current-state tooling condition while preserving historical evidence.
- `r5 depends_on r6`: continued applicability of the suitability claim is conditional on the workflow preserving the proof-only authority boundary.
- `r5.premise = [r2, r3]`: existence of the workflow plus the explicit operational assumption participate in deriving the suitability claim.

This deliberately distinguishes derivation from conditional validity.

## Producer validation

The graph was checked against the current `rgp-validator/1` structural rules before submission.

Result: **PASS**.

Structural checks include:

- unique candidate IDs;
- accepted RGP kinds;
- required primary provenance for non-derived observations;
- valid provenance roles;
- acyclic and resolving premise references;
- valid relation endpoints;
- accepted relation vocabulary;
- no self-relations.

The validator is intentionally insufficient to reject `r7`: `r7` is structurally well-formed. Its defect is semantic overgeneralization and belongs at Distiller evaluation / Steward admission rather than structural graph validation.

## Expected PEMS/2 projections

The currently explicit `pems/2-rgp/1` profile supports:

- RGP `observation` -> generic PEMS/2 proposition;
- RGP `assumption` -> generic PEMS/2 proposition;
- RGP `claim` -> generic PEMS/2 proposition;
- RGP `premise` -> PEMS/2 `derived_from`;
- RGP `depends_on` -> PEMS/2 `depends_on` with `dependency_kind=conditional_validity`;
- RGP `contradicts` -> PEMS/2 canonical symmetric contradiction relation;
- RGP supersession through PEMS lifecycle/supersession machinery.

## Newly exposed compatibility question

The current PEMS/2 compatibility fixtures explicitly define:

`PEMS unresolved_item -> RGP uncertainty`

for current open/blocked/deferred unresolved items.

They do **not** currently define the reverse import:

`RGP uncertainty -> PEMS/2 ?`

This trial therefore must not invent a representation for `r4`.

The Steward should either:

1. reconcile `r4` to an existing/new `unresolved_item` under an already accepted normative rule, if such a rule exists outside the current fixture surface; or
2. keep `r4` provisional and submit the missing import rule to the PEMS/COVE Architect.

This is a real semantic integration finding, not a validator failure.

## Expected Steward pressure outcomes

These are producer expectations, not authoritative dispositions:

| Candidate | Expected pressure outcome |
| --- | --- |
| `r1` | preserve only with historical/superseded semantics if admitted; do not reassert as current |
| `r2` | admit/reconcile as grounded observation if canonical value is durable |
| `r3` | admit as assumption only if the project is materially relying on it; otherwise provisional/omit |
| `r4` | provisional unless the normative RGP-uncertainty import mapping is already established |
| `r5` | admit only if premises are admitted/reconciled and `depends_on` integrity is preserved |
| `r6` | admit/reconcile as grounded observation if not already represented |
| `r7` | reject as unsupported universal generalization |

The key non-admission pressure case is `r7`. The key representation-pressure case is `r4`.

## Distiller evaluation

The production-quality semantic subset is `r1-r6`. `r7` is excluded from ordinary precision scoring because it is deliberately adversarial.

Pre-Steward assessment of `r1-r6` against `docs/distiller/evaluation/SCORING.md`:

- Durable Recall: 3/3
- Precision: 3/3
- Relation Integrity: 3/3
- Provenance: 3/3
- Authority / Epistemic Safety: 3/3
- Compression: 3/3

Total: **18/18**, pending independent Steward challenge.

The full seven-record evaluation package is intentionally not a production-quality distillation because `r7` violates the precision objective. Its presence tests whether the admission boundary catches semantically unsafe but structurally legal content.

## Trial success criteria

Trial 2 succeeds if the Steward independently demonstrates all of the following:

1. `assumption` remains an assumption and is not promoted to established fact.
2. `uncertainty` remains unresolved and is not silently coerced into generic claim semantics.
3. `contradicts` and `supersedes` remain distinct and can coexist when logical incompatibility and historical replacement are both present.
4. `depends_on` is imported as conditional validity rather than derivation.
5. `premise` is imported as `derived_from` and not duplicated as `depends_on`.
6. the unsupported `r7` claim is rejected or otherwise prevented from becoming canonical project truth.
7. no canonical mutation occurs if the uncertainty import contract is insufficient to preserve the submitted graph transactionally.

## Producer result

**Semantic coverage candidate: READY FOR STEWARD.**

The graph is structurally valid and exercises the intended RGP vocabulary. It also surfaced a concrete PEMS/2 compatibility question before canonical admission: reverse import semantics for RGP `uncertainty` are not explicit in the current compatibility fixtures.

The next authoritative step is Steward reconciliation and disposition of `RGP-20260816T190100-0700-002`.
