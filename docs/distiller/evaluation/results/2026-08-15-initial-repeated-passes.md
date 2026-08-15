# Initial Repeated Distiller Evaluation

Date: 2026-08-15

## Method

Five separated distillation passes were performed over each of the five Phase 0 evaluation cases using `docs/distiller/DIRECTIVE.md` as the governing instruction and `expected.yaml` / `SCORING.md` for evaluation.

Important limitation: these were repeated passes by the same model in one project session, not five truly isolated agent processes or cross-model invocations. The results are useful for identifying schema and directive pressure, but they must not be treated as evidence of cross-agent stability.

The evaluation favored precision over recall and applied the existing hard-failure rules. No pass was credited for reasoning that was merely plausible; unsupported causality, invented alternatives, fabricated provenance, or authority promotion would have failed the run.

## Aggregate Results

| Case | Accepted passes | Score range | Primary variance |
| --- | ---: | ---: | --- |
| `field-authority` | 5 / 5 | 17–18 / 18 | Whether the ownership boundary is represented as one decision or two atomic decisions; relation omission |
| `offline-runtime-split` | 5 / 5 | 17–18 / 18 | Whether the two halves of the split are linked with `depends_on` or left as independent governed decisions |
| `validation-demo-contract` | 5 / 5 | 17–18 / 18 | Whether incomplete prior validation is linked with `supports` to the owner requirement; authority remained stable |
| `resource-loading-investigation` | 4 / 5 | 14–17 / 18 | Current vocabulary lacks a clean type for a scoped engineering conclusion; one pass retained a marginal derived proposition and missed the acceptance threshold |
| `deployed-ui-failure` | 5 / 5 | 16–18 / 18 | Relation extraction varied; proposition and uncertainty extraction were stable |

Overall: **24 / 25 case-runs met the current Phase 1 acceptance threshold. No hard failures were observed.**

This result should be read cautiously because the passes were not independently instantiated agents.

## Stable Findings

### Proposition extraction is substantially more stable than relation extraction

Across the repeated passes, the high-value propositions were usually preserved with the expected authority boundary:

- `PointFieldResource` remained the authoritative scalar-field abstraction.
- Runtime residency remained separate from offline field generation and meshing.
- The validation-demo requirement remained owner/governed rather than being attributed to an agent.
- Unmeasured loading behavior remained uncertain.
- Green CI/deployment and missing runtime UI were both retained without claiming that the UI bug was fixed.

The greatest variation was whether a relation should be emitted at all. This is preferable to invented relations, but it shows that the current relation protocol is underspecified.

### Authority handling is strong under the current directive

No pass promoted an agent interpretation into an owner requirement or governed project truth. The `validation-demo-contract` case was especially useful: the requirement consistently retained owner authority while the incomplete validation state remained an observation.

This is one of the most important early successes because authority corruption would be much more damaging than omission.

### Uncertainty survives distillation

The `deployed-ui-failure` case consistently retained the unresolved cause rather than inventing a startup race, Web bug, export problem, or scene-tree explanation.

Likewise, the resource-loading case preserved unmeasured platform/build behavior as uncertainty rather than broadening the available evidence into a universal performance claim.

The directive's explicit preference for precision over recall appears useful.

## Pressure Points

### 1. `conclusion` is probably the first missing record type

The `resource-loading-investigation` case exposes a semantic mismatch. The statement that measured conclusions must remain scoped to the supplied measurements is not naturally an `observation`, `decision`, `assumption`, or `uncertainty`.

Repeated passes handled this by either:

- omitting the derived conclusion and retaining only observations/uncertainty;
- awkwardly representing the conclusion as an observation; or
- emitting a derived proposition whose type was semantically weak.

This is the only case that produced a threshold miss.

**Recommendation:** do not add `conclusion` immediately. Add a second evaluation case that clearly requires a derived conclusion. If both cases show the same pressure, introduce `conclusion` in an experimental v2 vocabulary.

### 2. Relation direction and emission criteria need clarification

The current directive says to emit a relation only when evidence establishes it, but does not define enough semantics for relation direction.

Examples:

- Does the decision that runtime consumes precomputed assets `depends_on` the decision that generation persists assets offline, or are they two sides of one architectural decision?
- Does incomplete validation `support` the validation-demo requirement, or is it merely historical evidence that reinforced an already owner-governed rule?
- Green deployment does not literally `contradict` missing UI; rather, missing UI contradicts the inference that green deployment establishes runtime UI correctness. The vocabulary currently has no explicit conclusion node for that inference.

The safe behavior observed was often to omit the edge. That preserves project truth but loses some symbolic argument structure.

**Recommendation:** define relation semantics with short admissibility tests before expanding the relation vocabulary.

### 3. Atomicity rules need one more sentence

`field-authority` and `offline-runtime-split` showed minor variation between one compound decision and two atomic decisions.

**Recommendation:** amend the directive to say that a record should express one independently changeable proposition. If two clauses could be superseded independently, they should be separate records.

### 4. Provenance is only as good as the evaluation input

The evaluation cases provide chat IDs and related PEMS record IDs, but not full immutable source-observation evidence for every claim. Passes correctly reused only supplied identifiers, but this means the current exercise primarily tests provenance preservation rather than provenance sufficiency.

**Recommendation:** Phase 0 should add at least one case with explicit immutable repository/test/source-observation references and score whether the distiller chooses the strongest available provenance rather than merely any valid reference.

## Representative Symbolic Shapes

The following shapes were stable enough across passes to be considered promising. They are illustrative, not canonical outputs.

### Field authority

```text
decision(owner/governed): PointFieldResource is the authoritative scalar-field abstraction

decision(governed): mesher consumers do not duplicate field indexing or field state
```

No generator-strategy architecture or runtime-streaming responsibility was inferred.

### Offline/runtime split

```text
decision(governed): generation persists chunk assets and a manifest offline

decision(governed): runtime streaming consumes precomputed assets and owns residency
```

No permanent prohibition on all future procedural runtime generation was inferred.

### Validation contract

```text
decision(owner): substantial features require dedicated validation through the public runtime path

observation(observed): chunk residency initially lacked sufficient validation coverage and browser exposure
```

The owner requirement was not attributed to an agent.

### Resource-loading investigation

```text
observation(observed): conclusions from loading measurements are scoped to the measurements supplied

uncertainty(unresolved): behavior on unmeasured platforms or builds remains unverified
```

This representation is serviceable but reveals the missing-conclusion pressure described above.

### Deployed UI failure

```text
observation(observed): CI and deployment were green

observation(observed): RuntimeWorkloadExperimentUI was missing in the deployed phone view

uncertainty(unresolved): the cause of the missing UI remained unresolved
```

No causal edge is necessary to preserve the important engineering state.

## Decision for the Next Experiment

Do **not** productize the distiller yet.

The first repeated evaluation supports continuing to Phase 1 experimentation, with the present architecture intact:

```text
observable work
    ↓
distiller agent
    ↓
candidate symbolic records
    ↓
deterministic validation / future admission
```

Before freezing a protocol:

1. add a second case that requires a derived conclusion;
2. add a case with strong immutable provenance choices;
3. tighten atomicity guidance;
4. define admissibility and direction for each current relation;
5. repeat the corpus with truly isolated agent/model invocations when orchestration becomes available.

The experiment currently supports the central hypothesis: useful engineering rationale can be preserved symbolically without requiring verbose conversational output. It does **not yet** establish that the directive is stable across independent agents or models.
