# Claim + Premise Model Evaluation

Date: 2026-08-15

## Purpose

This evaluation tests the revised distiller model after:

- removing `conclusion` as a proposition kind;
- adding `claim` as the generic proposition kind;
- making `premise` a first-class relational definition on derived propositions;
- narrowing authority to optional `owner | governed`;
- separating graph derivation from external provenance;
- retaining general relations only for non-derivational semantics.

The central hypothesis is:

```text
derived proposition
    = semantic kind
    + epistemic_role: derived
    + non-empty premise
```

rather than requiring a distinct `conclusion` kind or duplicated provenance on every downstream proposition.

## Method

Five separated passes were performed over each of the five provenance cases, plus five passes over each of the two previously identified conclusion-pressure shapes:

1. scoped resource-loading synthesis;
2. validation-surface synthesis.

Total: 35 case-runs.

As with earlier evaluations, these are separated passes by the same model in one project session, not independently instantiated agents or cross-model runs. The results test schema pressure and directive behavior, not cross-model stability.

The revised hard failures included:

- derived proposition without a non-empty premise;
- external source identifier used as a premise;
- premise relationship duplicated in general relations;
- `conclusion` emitted as a kind;
- owner/governed authority without authority provenance;
- unresolved evidence silently promoted to settled truth.

## Aggregate Result

**34 / 35 runs conformed to the revised model without hard failure.**

The single failure represented a derived validation synthesis as a `claim` with direct provenance but omitted `premise`. This is useful because the new invariant caught a structure that the older schema would have accepted.

No run:

- emitted `conclusion` as a kind;
- used external source IDs inside `premise`;
- duplicated premise relationships as generic relations;
- treated broad chat context as stronger than direct evidence;
- promoted agent synthesis into owner/governed authority;
- inferred axiomhood from missing provenance.

## Stable Findings

### 1. `claim + derived + premise` resolves the former conclusion-kind pressure

The two cases that originally motivated `conclusion` now have a natural representation.

Example:

```json
{
  "temp_id": "r3",
  "kind": "claim",
  "statement": "Successful deployment does not establish runtime UI startup correctness.",
  "epistemic_role": "derived",
  "premise": ["r1", "r2"]
}
```

This is semantically cleaner than treating the proposition as an observation or inventing a conclusion kind.

### 2. Premise removes provenance duplication

The revised model cleanly separates:

```text
external evidence → provenance → grounded proposition
                                   ↓
                                premise
                                   ↓
                            derived proposition
```

Derived propositions no longer need to repeat upstream external provenance merely to remain traceable, provided the premise chain resolves to grounded propositions or axioms.

This reduced source noise in all five provenance passes involving derived synthesis.

### 3. Premise is usefully constitutive

The strongest benefit of the field is mechanical validation:

```text
epistemic_role: derived
    ⇔
premise exists and is non-empty
```

The one failed run demonstrates the value of this rule. A proposition cannot merely label itself derived; it must expose its basis structurally.

### 4. Authority is cleaner after removing `observed` and `agent`

Empirical propositions were adequately represented through provenance and epistemic role. Agent synthesis was adequately represented through derivation.

No evaluated case required `observed` or `agent` as normative authority values.

The remaining authority values behaved consistently:

- `owner`
- `governed`

### 5. `depends_on` remained distinguishable from premise

No accepted pass used `depends_on` as a substitute for derivation.

The working distinction held:

- `premise`: participates in deriving the proposition;
- `depends_on`: changing the related proposition may invalidate, alter, or constrain the proposition, but it is not part of the derivation itself.

This distinction should remain explicit in the protocol.

## Remaining Pressure

### Observation vs claim for empirical synthesis

A scoped synthesis such as:

> Deserialization dominates the supplied chunk-loading measurements.

was represented in two defensible ways across passes:

```text
kind: observation
role: derived
```

or:

```text
kind: claim
role: derived
```

Neither representation loses the reasoning structure because `premise` carries the derivation.

The distinction now concerns semantic taxonomy rather than epistemic correctness.

**Recommendation:** do not add another kind. Add an admissibility rule:

- use `observation` when the proposition reports an empirical state or measured pattern;
- use `claim` when the proposition is primarily logical, interpretive, comparative, or meta-evidentiary and does not fit another specific kind.

Then test this rule against a wider corpus.

## Representative Shape

```json
{
  "records": [
    {
      "temp_id": "r1",
      "kind": "observation",
      "statement": "Deployment completed successfully.",
      "epistemic_role": "axiom",
      "provenance": {
        "primary": ["source:workflow:deploy-green"]
      }
    },
    {
      "temp_id": "r2",
      "kind": "observation",
      "statement": "RuntimeWorkloadExperimentUI was missing on the tested phone build.",
      "epistemic_role": "axiom",
      "provenance": {
        "primary": ["source:manual:phone-ui-missing"]
      }
    },
    {
      "temp_id": "r3",
      "kind": "claim",
      "statement": "Successful deployment does not establish runtime UI startup correctness.",
      "epistemic_role": "derived",
      "premise": ["r1", "r2"]
    },
    {
      "temp_id": "r4",
      "kind": "uncertainty",
      "statement": "The cause of the missing runtime UI remains unresolved.",
      "epistemic_role": "unresolved",
      "provenance": {
        "context": ["source:manual:phone-ui-missing"]
      }
    }
  ]
}
```

No general relation is needed to reproduce the derivation represented by `premise`.

## Decision

The experiment supports retaining:

- `claim` as a generic semantic kind;
- `premise` as a first-class field on derived propositions;
- the biconditional between derived role and non-empty premise;
- optional authority limited to `owner | governed`;
- typed external provenance;
- non-derivational general relations.

It does **not** support reintroducing `conclusion`.

## Next Test

The next useful evaluation should focus on semantic-kind selection rather than adding structure:

- empirical derived observation vs generic derived claim;
- assumption vs unresolved claim;
- uncertainty vs claim about uncertainty;
- decision derived from premises vs governed axiom decision.

The goal should be to tighten admissibility tests for the existing kinds before expanding the ontology.
