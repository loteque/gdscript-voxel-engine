# Authority from Provenance Evaluation

Date: 2026-08-15

## Question

Can proposition-level `authority` be removed and recovered from the provenance chain instead?

## Candidate Model

A proposition stores no authority field. Normative standing is inferred by tracing its provenance to typed sources.

Example candidate record:

```json
{
  "temp_id": "r1",
  "kind": "decision",
  "statement": "Substantial engine features require dedicated validation scenes.",
  "provenance": {
    "primary": ["source:owner:validation-requirement"]
  }
}
```

The proposition does not repeat `authority: owner`. The referenced source is responsible for carrying that fact.

## Cases Tested

The existing provenance and adversarial cases were re-evaluated under two conditions:

1. source references have authoritative typed metadata available outside the proposition;
2. source references are opaque identifiers with no separately available metadata.

The tested normative cases included:

- explicit owner validation requirement;
- agent summary repeating an owner rule;
- existing implementation patterns that must not become governance;
- governed runtime contract evidence;
- derived propositions whose premises eventually trace to authoritative sources.

## Results

### Typed source metadata available

All tested authority distinctions were recoverable without a proposition-level `authority` field.

The model correctly distinguishes:

- an owner instruction from an agent summary repeating it;
- a governed contract from implementation merely conforming to it;
- empirical evidence from normative evidence;
- derived propositions from their authoritative upstream premises.

No proposition-level authority field was necessary for these cases.

### Opaque source identifiers only

Authority was not reliably recoverable.

A reference such as:

```text
source-17
```

contains no semantic information by itself. Authority cannot safely be inferred from naming convention, prose in the proposition, or the fact that the proposition is a decision.

The existing examples often use descriptive identifiers such as `source:owner:*`, but those prefixes must not become an implicit authority protocol. Identifiers should remain identifiers.

## Finding

The candidate factoring is sound **provided that provenance sources are first-class typed entities or otherwise resolve to typed source metadata**.

The dependency is:

```text
proposition
  -> provenance reference
  -> source entity
  -> source type / authority characteristics
```

Under that model, proposition authority is derived data and should not be duplicated.

Without typed source metadata, removing `authority` would lose information.

## Provenance Role Implication

This test does not yet justify removing `provenance.authority` independently.

If provenance roles continue to distinguish why a source is attached, `authority` may still have meaning as an edge/source-role classification even after proposition-level authority is removed. A separate test should determine whether that role can also collapse into `primary` once source metadata is formalized.

## Recommendation

Do not change the proposition schema yet.

First define the minimum source entity/resolution contract needed to make authority derivable. Then repeat the test with opaque source IDs and explicit source metadata. If authority remains recoverable, remove proposition-level `authority`.

This preserves the factoring principle: do not remove stored data until the replacement derivation path is explicit and deterministic.
