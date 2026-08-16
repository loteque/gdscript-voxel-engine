# Uncertainty Kind Factoring Evaluation

Date: 2026-08-15

## Candidate Change

Remove `uncertainty` from the record-kind vocabulary and represent unresolved material using only `observation` or `claim` wording.

Corpus: `docs/distiller/evaluation/uncertainty-factoring-cases.yaml`

Eight pressure cases were evaluated across five separated same-model passes: 40 classifications.

## Result

All 40 cases could be expressed syntactically without the `uncertainty` kind:

- inspectable absence or missing-state propositions could be represented as `observation`;
- epistemic-status, scope, and open-question propositions could be represented as `claim`.

However, the candidate change is **not semantics-preserving**.

Removing `uncertainty` eliminates the graph's explicit machine-readable distinction between an unresolved proposition and an ordinary claim or observation. Consumers would need to infer unresolved status from natural-language wording such as `unknown`, `not established`, `unresolved`, or `has not been decided`.

That conflicts with the protocol's goal of preserving durable symbolic reasoning rather than requiring later language interpretation.

## Key Cases

`Browser runtime behavior has not been measured.` can be represented as an `observation`, but the observation kind alone does not indicate whether the missing measurement is an unresolved item requiring future work or merely historical state.

`The cause of the missing runtime UI is unknown.` can be represented as a `claim`, but `claim` does not distinguish this unresolved proposition from a settled derived claim.

`It is unresolved whether chunk residency should remain coupled to manifest lifetime.` becomes especially lossy as a generic claim because the unresolved status is the primary semantic content of the record.

## Interpretation

`uncertainty` is partially redundant at the natural-language level but not at the symbolic graph level.

It functions as an explicit query/indexing category for unresolved propositions and avoids brittle text interpretation by downstream consumers.

This differs from `validated_by`, whose semantics were fully recoverable from `premise`, `supports`, and provenance.

## Recommendation

Retain `uncertainty` as a first-class record kind for now.

Do not modify the production schema based on this factoring candidate.

A future redesign could reconsider whether unresolved status belongs on a separate orthogonal field, but reintroducing such a field would increase schema complexity and risks recreating the recently removed universal epistemic-role axis.

## Limitation

These are separated same-model evaluations, not independent cross-model trials.
