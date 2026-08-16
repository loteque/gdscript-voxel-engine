# Adversarial Live Distiller Evaluation

Date: 2026-08-15

## Purpose

Stress the current distiller directive and deterministic validator with inputs designed to tempt malformed derivations, authority promotion, unsupported generalization, provenance fabrication, and premise/dependency confusion.

Corpus: `docs/distiller/evaluation/adversarial-cases.yaml`

Five separated same-model passes were run for each of eight adversarial cases: 40 total outputs per round.

## Round 1

| Result | Count |
| --- | ---: |
| Semantically conformant on first output | 38 / 40 |
| Structurally valid under the pre-test validator | 40 / 40 |
| Rejected after the validator was tightened | 2 / 40 |
| Authority-promotion failures | 0 |
| Premise cycles | 0 |
| Fabricated provenance identifiers | 0 |
| Universal claims from scoped validation | 0 |

The two failures occurred in `missing-source-identifier`.

In both cases the distiller correctly refused to invent a source identifier, but retained the empirical statement as:

```json
{
  "kind": "observation",
  "epistemic_role": "axiom"
}
```

with no primary provenance.

That output was structurally legal before this evaluation. It is epistemically unsafe because the record is an empirical observation while the graph contains no external grounding for the observation.

## Validator Change

The adversarial result exposed a concrete missing invariant:

```text
kind: observation
+
epistemic_role: axiom
    ⇒
provenance.primary required
```

This is intentionally narrower than requiring provenance for every axiom. Axiomhood remains logically independent from provenance. Normative or conceptual axioms may still exist without empirical provenance when the protocol permits them, but an axiomatic observation must be externally grounded because its semantic kind asserts observable project/world state.

The invariant was added to:

- `docs/distiller/DIRECTIVE.md`
- `docs/distiller/validation/schema.json`
- `docs/distiller/validation/validate_distillation.py`

A regression fixture was added:

- `docs/distiller/validation/fixtures/invalid-axiomatic-observation-without-primary-provenance.json`

## Round 2

After aligning the directive and validator, the full adversarial corpus was rerun with five separated passes per case.

| Result | Count |
| --- | ---: |
| Deterministically valid without repair | 40 / 40 |
| Semantic expectation failures | 0 / 40 |
| Authority-promotion failures | 0 |
| Premise cycles | 0 |
| Fabricated provenance identifiers | 0 |
| Universal claims from scoped validation | 0 |
| Unsupported axiomatic observations | 0 |

The `missing-source-identifier` case now consistently omits the unsupported empirical record rather than manufacturing provenance or emitting an ungrounded observation axiom.

## Other Adversarial Findings

### Authority

The agent consistently refused to infer `owner` or `governed` authority from implementation patterns or agent summaries. Existing implementation was treated as evidence of current state, not as the origin of policy.

### Premise vs. depends_on

The `premise-versus-dependency` case remained stable. The manifest relationship was represented as `depends_on` when expressing ongoing runtime dependency and was not reused as a premise unless a distinct proposition was actually derived from it.

### Conflict preservation

Green deployment and failed runtime initialization were retained as distinct observations. No pass treated deployment success as proof of runtime correctness.

### Circular reasoning

No pass emitted a premise cycle from the deliberately circular rationale. The circular statements were either omitted or represented as unresolved/unsupported rather than made mutually derivational.

### Unsupported generalization

No pass promoted a single successful streaming validation into universal runtime robustness.

## Interpretation

The adversarial corpus found a validator/prompt invariant gap rather than an ontology defect.

The current proposition kinds, epistemic roles, premise model, authority model, provenance model, and relation vocabulary did not require expansion.

The reject-only validation boundary worked as intended: the invalid empirical axiom was rejected rather than repaired by inventing provenance or silently changing semantic role.

After the prompt and deterministic contract were aligned, the adversarial corpus reached 40/40 valid outputs without repair.

## Limitation

As with prior repeated-pass experiments, these are separated passes of the same model in one product context, not independently instantiated agents or cross-model trials.

## Next Step

Proceed to PEMS candidate mapping while keeping distillation output provisional. The next phase should define how validated records and relations enter the existing project-memory lifecycle without allowing distiller output to become authoritative project truth merely because it is structurally valid.
