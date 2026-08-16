# `validated_by` Factoring Evaluation

Date: 2026-08-15

## Purpose

Test whether the general relation `validated_by` carries semantics that cannot already be represented by `premise`, `supports`, or provenance.

Corpus: `docs/distiller/evaluation/validated-by-factoring-cases.yaml`

Six pressure cases were evaluated across five separated passes each: 30 total classifications.

## Result

All 30 classifications preserved the intended meaning without `validated_by`.

No case required a distinct validation relation.

The cases consistently factored into three existing mechanisms:

1. `premise` when a validation-result proposition participates directly in deriving the target proposition;
2. `supports` when validation evidence strengthens a target without constituting its derivation;
3. provenance when the validating entity is an external test, validator, workflow result, manual QA result, or other source rather than a proposition in the reasoning graph.

## Semantic Boundary

The proposed factoring is:

```text
premise
    constitutive inferential support

supports
    non-constitutive evidentiary support

provenance
    external grounding, including validation artifacts/results that are not graph propositions
```

Under this model, `validated_by` does not identify a fourth semantic category. It is a domain-flavored spelling of one of the three mechanisms above.

## Pressure Cases

### Direct test establishes an observation

A passing test can either be direct primary provenance for an observation or a premise proposition for a broader derived observation. `validated_by` adds no information.

### Manual QA establishes runtime behavior

Manual validation behaves the same way: direct provenance when it directly establishes the target, or premise when a durable QA proposition is retained and used in a derivation.

### Green workflow does not establish runtime correctness

Removing `validated_by` does not encourage overclaiming. A deployment-success proposition is not a premise of runtime correctness merely because it is a successful validation-adjacent event. It may be `supports` only when it genuinely strengthens the target; otherwise the unresolved state remains.

### Contract check establishes compliance

A machine-readable contract-check result is naturally a premise of a derived compliance claim. A separate `validated_by` edge duplicates that relationship.

### Multiple validation surfaces

Headless and manual validation results can be premises of a scoped completion claim. A deployment result may be supporting/contextual evidence but does not become a premise automatically.

### Validator executable is not a proposition

When the validating entity is a tool or external result rather than a proposition, provenance is the correct representation. Creating a graph relation solely to say which tool validated something would blur proposition graph structure with source metadata.

## Conclusion

`validated_by` is redundant in the current protocol.

Recommended production change:

```diff
 relations:
   supports
   contradicts
   depends_on
   supersedes
-  validated_by
```

No other schema change is required.

## Limitation

The repository currently contains no indexed durable graph examples that rely on `validated_by`; this evaluation therefore uses targeted semantic pressure cases rather than migration of historical production records.
