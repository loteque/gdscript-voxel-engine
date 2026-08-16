# First RGP → Steward → PEMS/2 Admission Trial

## Scope

This is the first bounded integration trial of the RGP submission/admission boundary against the canonical PEMS/2 handoff on `project-chat-handoff`.

The trial intentionally separates producer-owned execution from Steward-owned authority. The RGP Engineer may create and validate the candidate submission and may perform a non-authoritative reconciliation dry run against an exact canonical snapshot. It must not fabricate a Steward disposition or mutate canonical PEMS/COVE on the Steward's behalf.

## Trial submission

Submission:

`docs/handoff/rgp/submissions/RGP-20260816T152100-0700-001.json`

The graph contains four records:

1. `r1` — observation: committed RGP submissions are immutable.
2. `r2` — observation: RGP producers must not write directly to canonical PEMS/COVE.
3. `r3` — derived claim: candidate RGP production and canonical PEMS persistence are separate operations.
4. `r4` — decision: the Project Engineering Steward owns canonical PEMS reconciliation and regeneration of canonical/derivative handoff artifacts.

It also contains two `supports` relations into `r3`.

This shape deliberately exercises:

- new generic `observation` propositions;
- new generic `claim` propositions;
- RGP `premise` → PEMS/2 `derived_from`;
- proposition-level `supports`;
- immutable external GitHub provenance resolution;
- reuse of an existing canonical PEMS decision identity.

## Source basis

`r1` and `r2` use the immutable repository source reference:

`github:commit:da59ddaa352f09d6e64908c458d7e61e1fae61fd:docs/handoff/rgp/SUBMISSION_PROTOCOL.md`

`r4` uses existing canonical PEMS source observation:

`pems:source_observation:be6819991bf46e7cc226`

The canonical PEMS/2 snapshot inspected for reconciliation is `docs/project-chat-handoff.json` on `project-chat-handoff` at blob `876b24888dbf9c8f66126be8eacf2cd299a41cd9`.

## Executed checks

### 1. RGP structural validation

The candidate graph was executed against the current deterministic rules implemented by `docs/distiller/validation/validate_distillation.py` (`rgp-validator/1`).

Result: **PASS**.

Observed validator errors: none.

The graph has unique candidate IDs, valid kinds, valid provenance roles, required primary provenance for non-derived observations, an acyclic premise graph, valid relation endpoints, and only current RGP relation kinds.

### 2. Submission-envelope conformance

The committed envelope was checked against `docs/handoff/rgp/SUBMISSION_PROTOCOL.md`.

Result: **PASS**.

It has a unique submission ID, explicit `rgp/1`, `candidate` status, producer identity, immutable candidate graph, passed validator declaration, and source context that is separate from proposition provenance.

The current submission protocol is prose-normative; there is not yet a machine-readable submission-envelope schema/validator. This is a tooling gap exposed by the trial, not a semantic failure.

### 3. PEMS/2 compatibility dry run

The canonical PEMS/2 snapshot currently contains no `proposition` records, so `r1`, `r2`, and `r3` do not collide with existing generic proposition identities by existing-ID inspection.

Expected semantic projection:

| RGP candidate | PEMS/2 projection | Reconciliation result |
| --- | --- | --- |
| `r1` | `proposition(observation, asserted)` | new canonical identity required |
| `r2` | `proposition(observation, asserted)` | new canonical identity required |
| `r3` | `proposition(claim, derived)` | new canonical identity required; `derived_from` `r2` required |
| `r4` | existing `decision` | exact semantic identity already exists as `pems:decision:2197184a0ef4b2a120e4` |

Expected relation projection:

- RGP `r3.premise = [r2]` → PEMS/2 `derived_from` from the canonical identity for `r3` to the canonical identity for `r2`.
- RGP `supports(r1, r3)` → PEMS/2 `supports`.
- RGP `supports(r4, r3)` → PEMS/2 `supports`.

Result: **SEMANTICALLY REPRESENTABLE** under the current `pems/2-rgp/1` profile.

### 4. Provenance reconciliation dry run

`r4` already terminates at an existing PEMS source observation and is immediately resolvable.

The immutable GitHub source reference used by `r1` and `r2` is not currently represented by an existing canonical PEMS source/source-observation identity. PEMS/2 admission therefore requires the Steward to reconcile or create the stable source identity and immutable source observation for that exact commit/path before admission.

Result: **RESOLVABLE BUT NOT YET RECONCILED**.

This is the expected boundary: the producer supplies an opaque immutable source reference; the Steward owns canonical source identity reconciliation.

### 5. Canonical identity reconciliation dry run

The exact `r4` decision statement already exists in canonical PEMS as:

`pems:decision:2197184a0ef4b2a120e4`

The dry run therefore predicts identity reuse rather than a duplicate decision.

No generic PEMS/2 propositions currently exist in the canonical snapshot, so the remaining three records require new Steward-admitted identities.

Result: **PASS for duplicate detection / identity reuse boundary**.

## Failure pressure cases

The trial also checked the following boundary behaviors against the current RGP, submission, and PEMS/2 contracts:

| Case | Expected behavior | Result |
| --- | --- | --- |
| dangling/missing premise | RGP validator rejects before submission | PASS |
| unsupported `rgp/2` | PEMS/2 compatibility fails closed | PASS |
| same submission ID with changed candidate semantics | hard submission identity collision | PASS |
| identical submission retry | idempotent; no duplicate canonical effect | PASS |
| provenance reference that cannot be resolved | remain provisional/reject per Steward policy; never guess | PASS |
| duplicate decision candidate | reuse existing canonical identity | PASS |
| candidate supersession without accepted authority | no canonical lifecycle mutation | PASS |

These are contract pressure checks. They do not claim a Steward admission occurred.

## Dry-run disposition

The RGP Engineer's non-authoritative predicted disposition is:

```text
provisional
```

Reason:

- RGP structure is valid.
- PEMS/2 can represent the complete graph without semantic loss.
- one candidate reuses an established canonical decision identity.
- three proposition identities require Steward allocation/reconciliation.
- two records require canonical source/source-observation reconciliation for their immutable GitHub provenance.
- only the Steward may perform those operations and write the authoritative disposition/canonical memory mutation.

This is not a Steward disposition and must not be stored under `docs/handoff/rgp/dispositions/`.

## Round-trip expectation

If the Steward admits the connected graph transactionally, a PEMS/2 → RGP/1 export at that admitted snapshot should reconstruct:

- `r1` semantics as RGP `observation`;
- `r2` semantics as RGP `observation`;
- `r3` semantics as RGP `claim` with `r2` as premise;
- `r4` semantics as RGP `decision` while it remains current/accepted;
- both `supports` relationships;
- typed provenance for the admitted source observations.

Exact candidate `temp_id` values are not expected to survive canonicalization. Semantic identity is carried by the Steward-provided candidate-to-canonical mapping.

## Trial result

**Producer-to-admission-boundary trial: PASS.**

**Authoritative end-to-end admission: PENDING STEWARD.**

The architecture composed correctly through candidate generation, validation, immutable submission, PEMS/2 semantic projection, duplicate detection, and source-resolution planning. The trial correctly stopped at the Steward authority boundary instead of fabricating admission.

## Findings

1. The RGP/PEMS2 semantic boundary is viable for the exercised graph.
2. Existing domain decision identity can coexist with new generic proposition nodes without duplication.
3. External opaque provenance resolution is the first real Steward-side integration operation needed by the trial.
4. The RGP Submission Protocol should gain a deterministic JSON Schema/envelope validator so submission conformance is executable rather than prose-only.
5. The next authoritative action is for the Project Engineering Steward to process `RGP-20260816T152100-0700-001`, emit an immutable disposition, and, if admitted, regenerate canonical PEMS/2/COVE and the compatibility derivative.
