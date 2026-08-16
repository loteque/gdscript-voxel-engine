# Structural Derivation Evaluation

Date: 2026-08-15

## Change Under Test

The protocol removed `epistemic_role` entirely.

Derivation is now represented only by structure:

```text
premise present  -> derived proposition
premise absent   -> non-derived proposition
```

This removes `axiom`, `derived`, and `unresolved` as universal role values. Proposition semantics now come from `kind`, `premise`, `authority`, and `provenance`.

## Validation Changes

The deterministic validator now enforces:

- `premise`, when present, is non-empty;
- premise references resolve to graph records;
- premise references are not self-referential;
- premise chains are acyclic;
- non-derived observations require `provenance.primary`;
- authority requires `provenance.authority`;
- empty optional structures remain invalid;
- `epistemic_role` is no longer a permitted field.

The prior universal derivation-anchor rule was removed. A reasoning chain may legitimately begin with propositions whose semantics are not empirical observations, such as assumptions, uncertainties, claims, or governed/owner decisions. Empirical leaf observations remain externally grounded by primary provenance.

## Fixture Regression

The validation fixtures were migrated so they exercise the new ontology directly rather than failing because of legacy fields.

Expected-valid fixtures pass. Expected-invalid fixtures reject for the intended rules, including:

- ungrounded non-derived observation;
- empty premise array;
- dangling premise reference;
- premise cycle;
- authority without authority provenance;
- empty provenance object.

## Live Corpus Regression

The existing provenance/live corpus was rerun as five separated passes per case: 25 outputs.

Result: **25 / 25 conformed to the structural protocol and deterministic validation without repair.**

Derived empirical summaries remained representable as `observation` with `premise`. Evidentiary or scope conclusions remained representable as `claim` with `premise`. Owner/governed standing remained independent through `authority` and authority provenance.

## Adversarial Regression

The eight-case adversarial corpus was rerun as five separated passes per case: 40 outputs.

Result: **40 / 40 conformed to the updated semantic expectations and deterministic validation without repair.**

No pass:

- emitted `epistemic_role`;
- promoted agent/context evidence into owner or governed authority;
- fabricated provenance;
- created a premise cycle;
- used a dangling premise;
- generalized scoped validation into universal correctness;
- converted an unresolved measurement gap into an invented assumption.

The `missing-source-identifier` case became cleaner under the new model. Because a non-derived observation requires primary provenance, the unsupported empirical proposition is omitted rather than mislabeled as an axiom.

## Finding

The removed epistemic-role axis was redundant and permitted combinations with no clear ontology, most notably `observation + axiom`.

The simpler model preserves the useful distinction:

```text
kind        -> what proposition is this?
premise     -> is it derived, and from what?
authority   -> what gives it normative/project standing?
provenance  -> what externally grounds or contextualizes it?
relations   -> what other non-derivational semantics connect records?
```

Derivedness no longer needs to be serialized twice.

## Decision

Keep `epistemic_role` removed from the experimental protocol.

Do not introduce a replacement universal role field unless a future evaluation demonstrates information that cannot be represented by the current axes.

## Limitation

Repeated passes are from the same model/product context, not independently instantiated agents or cross-model trials.

## Next Step

Proceed to PEMS candidate mapping using the simplified structural protocol. Candidate mapping should preserve the distinction between validated distiller output and canonical admitted project memory.
