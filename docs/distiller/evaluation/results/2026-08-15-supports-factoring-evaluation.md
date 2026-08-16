# Supports Factoring Evaluation

Date: 2026-08-15

## Question

Can the general `supports` relation be removed and its meaning represented entirely by `premise` and `provenance.corroborating`?

## Result

No. `supports` carries a distinct proposition-to-proposition relationship that is neither formal derivation nor external-source corroboration.

## Factoring outcomes

Six pressure cases were evaluated against three candidate encodings: `premise`, `provenance.corroborating`, and no explicit relationship.

### Cases that factor cleanly

- When propositions are constitutive of a derived proposition, use `premise`; adding `supports` would duplicate derivation.
- When reinforcing evidence exists only as an external source, use `provenance.corroborating`; a graph relation is unnecessary.
- When multiple observations are retained specifically to derive a synthesis proposition, those observations belong in that proposition's `premise` field.

### Cases that do not factor cleanly

#### Evidence favoring a decision

An observation can materially support a decision without logically deriving it. Decisions may also depend on priorities, tradeoffs, owner intent, or alternatives not represented as premises. Encoding the observation as a premise would overstate the logical relationship. Omitting the relationship would lose durable rationale.

#### Evidence increasing plausibility of an uncertainty

An observation can strengthen an unresolved hypothesis without establishing it. Making the observation a premise risks implying that the uncertainty is a derived conclusion rather than an unresolved proposition whose plausibility has increased. `provenance.corroborating` is unavailable when both endpoints are propositions in the graph rather than an external source and a proposition.

#### Independent proposition-level corroboration

Two independently meaningful propositions can reinforce one another while remaining separately sourced records. If both records are retained for their own durable value, collapsing one into the other's provenance would erase proposition identity and graph structure.

## Semantic boundary

The resulting distinction is:

```text
premise
    Proposition A participates constitutively in deriving proposition B.

supports
    Proposition A increases the warrant, rationale, confidence, or plausibility of proposition B without being constitutive of B's derivation.

provenance.corroborating
    An external source independently strengthens the proposition but is not itself a proposition node in the reasoning graph.
```

The relations are therefore not interchangeable.

## Recommendation

Keep `supports` in production.

Tighten its directive definition so agents do not use it as a weaker synonym for `premise`. A useful admissibility test is:

> If removing A from B's derivation would prevent B from being inferred, A is a premise. If B can still stand but A materially strengthens its warrant, A may support B.

No production schema change is recommended from this evaluation.
