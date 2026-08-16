# Adversarial Live Distiller Evaluation

Date: 2026-08-15

## Purpose

Stress the current distiller directive and deterministic validator with inputs designed to tempt malformed derivations, authority promotion, unsupported generalization, provenance fabrication, and premise/dependency confusion.

Corpus: `docs/distiller/evaluation/adversarial-cases.yaml`

Five separated same-model passes were run for each of eight adversarial cases: 40 total outputs.

## Results

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

The invariant was added to both:

- `docs/distiller/validation/schema.json`
- `docs/distiller/validation/validate_distillation.py`

A regression fixture was added:

- `docs/distiller/validation/fixtures/invalid-axiomatic-observation-without-primary-provenance.json`

Under the tightened validator, the two adversarial outputs are rejected rather than silently admitted.

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

The adversarial corpus found a validator defect rather than an ontology defect.

This is a favorable result: the current proposition kinds, epistemic roles, premise model, authority model, and relation vocabulary did not require expansion.

It also demonstrates why deterministic validation should remain reject-only. The invalid empirical axiom was not something a validator should repair by inventing provenance or changing epistemic role. Rejection correctly returns the semantic problem to the distillation stage.

## Remaining Gap

The directive currently says provenance may be absent from axioms in general. It should be tightened to state the new narrower rule explicitly:

> An `observation` with `epistemic_role: axiom` requires `provenance.primary`.

The deterministic contract already enforces this rule. The prompt should be brought into exact alignment before the next live evaluation.

## Limitation

As with prior repeated-pass experiments, these are separated passes of the same model in one product context, not independently instantiated agents or cross-model trials.

## Next Step

Align `DIRECTIVE.md` with the new empirical-grounding invariant, rerun the adversarial corpus, and require 40/40 outputs to pass deterministic validation without repair before moving to PEMS candidate mapping.
