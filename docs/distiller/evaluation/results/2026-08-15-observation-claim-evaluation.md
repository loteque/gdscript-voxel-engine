# Observation vs. Claim Evaluation

Date: 2026-08-15

## Purpose

Test whether the tightened semantic distinction between `observation` and `claim` remains stable when both propositions are `epistemic_role: derived` and use first-class `premise` references.

This evaluation uses `observation-claim-cases.yaml` and the current `DIRECTIVE.md`.

## Method

Eight borderline propositions were evaluated across five separated passes in the same model/session, for 40 classification decisions total. This is a variance probe, not evidence of cross-model or isolated-agent consistency.

The target distinction was:

- `observation`: empirically established/testable state or behavior, including empirical syntheses;
- `claim`: evidentiary, interpretive, scope, logical-boundary, or compliance propositions.

All derived outputs were additionally checked for non-empty `premise` references.

## Results

| Case | Expected | Stable classifications | Notes |
| --- | --- | ---: | --- |
| measured-dominance | observation | 5/5 | stable empirical synthesis |
| validation-summary | observation | 5/5 | stable when scoped to tested revision |
| deployment-evidence-boundary | claim | 5/5 | clear evidentiary-boundary statement |
| contract-compliance | claim | 5/5 | clear normative/compliance judgment |
| cpu-bound-workload | observation | 5/5 | stable empirical proposition |
| platform-scope-boundary | claim | 5/5 | clear scope/evidentiary boundary |
| architecture-independence | observation | 4/5 | one pass chose claim because the wording sounded architectural/interpretive rather than explicitly inspectable |
| evidence-supports-bottleneck | claim | 5/5 | clear statement about evidentiary support |

Overall expected-kind agreement: **39 / 40 (97.5%)**.

No pass used `claim` merely because a proposition was derived. No pass emitted `conclusion`. No derived proposition lacked `premise`.

## Finding

The distinction is useful and mostly stable.

The strongest discriminator is not whether the proposition was synthesized. It is what the proposition is *about*:

```text
project/world state or behavior
    -> observation

evidence, interpretation, scope, logic, or compliance
    -> claim
```

The previous ambiguity around empirical synthesis is substantially resolved. For example, `Deserialization dominates the measured chunk-loading stages` remains an `observation` even though it is derived from multiple measurement premises.

Likewise, `The supplied measurements support deserialization as the dominant measured stage` is a `claim` because its subject is the evidentiary relationship itself.

## Architectural-State Pressure

`The current architecture keeps runtime residency independent of meshing` exposed the only material instability.

The proposition can mean either:

1. an inspectable statement about current dependency structure, which is an `observation`; or
2. an architectural interpretation or guarantee, which is a `claim`.

This is primarily an atomic wording/scope problem rather than evidence that the two kinds overlap fundamentally.

Prefer concrete observable wording when the intended record is empirical, for example:

> Runtime residency has no dependency on a mesher in the inspected implementation.

Reserve broader architectural or contractual interpretations for `claim`.

## Decision

Keep both `observation` and `claim`.

Do not add another proposition kind.

Retain the current directive rule:

- use `observation` for empirically falsifiable state/behavior;
- use `claim` for propositions whose truth primarily depends on reasoning about evidence, interpretation, scope, logic, or compliance.

## Next Protocol Pressure

The current schema is now sufficiently expressive that the next useful work should shift from ontology changes toward deterministic validation.

Highest-value validators:

1. `derived` iff `premise` exists and is non-empty;
2. premise references resolve;
3. `axiom` and `unresolved` forbid `premise`;
4. no `null`, empty arrays, or empty objects;
5. authority is limited to `owner | governed` and requires authority provenance;
6. provenance references are external sources, never graph record IDs;
7. derivation chains terminate in axioms and/or externally grounded propositions.
