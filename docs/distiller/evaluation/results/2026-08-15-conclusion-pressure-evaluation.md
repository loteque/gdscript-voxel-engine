# Conclusion-Pressure Distiller Evaluation

Date: 2026-08-15

## Purpose

The initial repeated evaluation found that `resource-loading-investigation` was the only case to miss the acceptance threshold and suggested that the initial vocabulary may lack a clean representation for derived engineering conclusions.

This experiment tests that hypothesis before changing the ontology.

## Added Evaluation Shape

A synthetic-but-project-grounded case was evaluated using the current `DIRECTIVE.md` vocabulary only.

### Case: validation-evidence-conclusion

Evidence supplied to the distiller:

- A substantial runtime feature has a dedicated validation scene.
- The validation scene exercises the feature through its public API and normal runtime path.
- The relevant headless validation passes.
- The exported Integration Preview runs successfully through the published web build.
- These observations establish that the required validation surfaces exercised successfully for the tested revision.
- They do not establish that the feature is correct for every input, platform, future revision, or untested runtime condition.

Expected durable content:

1. observations for the successful validation surfaces;
2. a derived, scoped proposition that the tested revision satisfied the required validation surfaces;
3. uncertainty or explicit scope preventing universal correctness claims.

The important question is whether item 2 can be represented naturally with only `observation`, `decision`, `assumption`, and `uncertainty`.

## Repeated Pass Results

Five separated passes were evaluated using the same precision-heavy criteria as the initial experiment.

| Pass | Treatment of derived proposition | Result |
| --- | --- | --- |
| 1 | encoded as `observation` with `derived` authority | semantically awkward but safe |
| 2 | omitted derived proposition; retained component observations | safe, but loses argument compression |
| 3 | encoded as `observation` with `derived` authority | semantically awkward but safe |
| 4 | split into observations and an uncertainty boundary; omitted synthesis | safe, but rationale incomplete |
| 5 | encoded as `observation` with `derived` authority | semantically awkward but safe |

No pass invented universal correctness, fabricated provenance, or promoted the result into an owner/governed decision.

## Finding

The same semantic pressure observed in `resource-loading-investigation` reproduced in a second, materially different case.

The current record type and authority dimensions are being forced to compensate for one another:

```text
kind: observation
authority: derived
```

This is understandable to a human, but it weakens the ontology. An observation should represent something established directly by evidence. A conclusion represents a proposition derived from one or more observations while remaining scoped to those observations.

The alternative, omitting the synthesis, preserves precision but loses the symbolic argument that the distiller exists to retain.

## Recommendation

Add `conclusion` as an experimental record type in vocabulary v2.

Proposed semantics:

> `conclusion`: a durable proposition derived from supplied observations, validation, or other evidence, where the derivation is explicit enough to preserve but the proposition is not itself a direct observation or governed decision.

Rules:

- authority should normally be `derived`;
- a conclusion must have supporting provenance and/or `supports` / `validated_by` relationships;
- its scope must not exceed its evidence;
- it must not be used as a synonym for opinion, recommendation, assumption, or decision;
- conclusions must remain supersedable when later evidence contradicts them.

## Relation Implication

Adding `conclusion` also resolves part of the relation ambiguity from the initial evaluation.

For example:

```text
observation: headless validation passed
observation: published Integration Preview ran successfully
        │
        └── supports ──►
                         conclusion: required validation surfaces exercised successfully for tested revision
```

Likewise, the deployed-UI case can represent the inference boundary without claiming that green deployment contradicts missing UI directly:

```text
observation: deployment was green
observation: runtime UI was missing

conclusion: green deployment does not establish runtime UI startup correctness
```

The observations coexist. The conclusion captures what can safely be inferred from them.

## Decision

The evidence now supports expanding the experimental vocabulary from four to five record types:

- observation
- decision
- assumption
- uncertainty
- conclusion

This remains an experimental vocabulary change, not a frozen PEMS schema decision.

## Next Evaluation

The next evaluation should target provenance quality rather than ontology expansion:

- provide multiple valid source references of different strength;
- require the distiller to select the strongest direct provenance;
- test whether derived conclusions preserve both their immediate evidence and upstream source provenance;
- penalize use of broad chat-level provenance when a specific immutable commit, test run, or governed record is available.
