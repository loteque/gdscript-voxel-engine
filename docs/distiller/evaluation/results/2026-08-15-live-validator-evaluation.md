# Live Distiller Validator Evaluation

Date: 2026-08-15

## Purpose

Test whether fresh distiller outputs produced under the current `DIRECTIVE.md` satisfy the deterministic validation boundary without manual repair.

This evaluation follows the addition of:

- `docs/distiller/validation/schema.json`
- `docs/distiller/validation/validate_distillation.py`
- deterministic validation fixtures

## Corpus

The five provenance cases were used because they exercise both simple grounded propositions and multi-node derivations:

1. `direct-test-over-chat`
2. `owner-rule-over-agent-summary`
3. `conclusion-upstream-provenance`
4. `conflicting-specific-sources`
5. `specific-file-over-repository-summary`

Five fresh passes were produced for each case, for 25 total outputs.

No output was manually repaired before validation.

## Result

| Metric | Result |
| --- | ---: |
| Total fresh outputs | 25 |
| Structurally valid | 25 |
| Invalid | 0 |
| Manual repairs | 0 |
| Validator false positives observed | 0 |

**Pass rate: 25 / 25 (100%).**

## Behaviors Exercised

The successful outputs exercised:

- axiom records with direct immutable provenance;
- owner authority with `provenance.authority`;
- derived observations with multiple local `premise` references;
- derived claims expressing evidentiary boundaries;
- unresolved uncertainty records;
- omission of unused optional fields and empty structures;
- minimal provenance selection;
- optional corroborating and contextual provenance.

The multi-node validation case used three grounded observations as premises for a derived observation. The conflicting-source case used two grounded observations as premises for a derived claim while preserving a separate unresolved proposition.

## Finding

The current agent directive and deterministic validator are aligned well enough that valid output does not require a normalization/repair pass for the tested cases.

This is important because a repair stage would risk becoming an undeclared second semantic agent. At this stage, validation can remain a rejecting boundary rather than a rewriting boundary.

## Limitation

These are repeated passes produced by the same model context, not truly isolated agents or multiple models. The result establishes prompt-to-validator compatibility, not cross-agent stability.

The evaluation also tests structural validity, not whether every semantically valid output is the best possible distillation. Semantic quality remains covered by the existing corpus expectations and scoring exercises.

## Recommendation

Keep the validator reject-only. Do not introduce automatic repair.

The next useful validation step is adversarial live output testing: deliberately present cases where a distiller is tempted to produce malformed derivation structure, including:

- a derived proposition whose premise is only implicit in prose;
- a derived proposition referencing an unresolved proposition;
- a multi-level derivation with one unsupported branch;
- a proposition with legitimate external provenance but an incorrect epistemic role;
- a normative proposition whose authority and provenance disagree.

This should test whether the validator catches realistic agent mistakes rather than only hand-authored malformed fixtures.
