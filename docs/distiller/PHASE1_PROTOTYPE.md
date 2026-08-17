# Reasoning Distiller Phase 1 Prototype

Date: 2026-08-16
Role: Reasoning Graph Protocol Engineer
Contract: `rgp/1`
Baseline: `docs/distiller/evaluation/PHASE0_BASELINE.md`

## Prototype definition

The Phase-1 prototype is the specialized semantic producer defined by `docs/distiller/DIRECTIVE.md` plus the fixed evaluation harness in `docs/distiller/evaluation/phase1-inputs.json`.

The producer receives only the supplied evidence registry and case material. It emits candidate RGP only. It does not:
- reconstruct hidden chain-of-thought;
- resolve canonical semantic identity;
- determine project truth or normative standing;
- mutate PEMS/COVE;
- repair unsupported output by inventing provenance.

Candidate output is evaluated against `docs/distiller/evaluation/expected.yaml` and mechanically checked by `docs/distiller/validation/validate_distillation.py`.

## Invocation contract

For each evaluation pass:

1. Load `docs/distiller/DIRECTIVE.md`.
2. Select one case from `phase1-inputs.json`.
3. Treat source IDs in that case as the complete supplied external source registry for the pass.
4. Produce structured RGP only.
5. Preserve the candidate output without editing.
6. Run the deterministic validator.
7. Score separately using `SCORING.md`.
8. Never treat the candidate or diagnostics as canonical project memory.

## Phase-1 batch

The initial batch contains three semantic passes for each of the five Phase-0 core cases, 15 candidate graphs total.

These passes are useful for:
- checking protocol-shape conformance;
- detecting vocabulary drift;
- checking whether the prompt tends toward invention or over-retention;
- comparing semantic stability under wording variation.

They are **not** counted as independent fresh model invocations because they were produced inside one RGP Engineer execution context. Therefore this batch cannot, by itself, satisfy the Phase-0 independence requirement for a stability claim.

## Exit policy

Prototype implementation is complete when:
- the producer contract is executable from supplied evidence;
- outputs are preserved raw;
- outputs pass the deterministic RGP validator;
- human scoring can be recorded without altering candidate output.

Prototype stability is a separate gate and requires at least three genuinely fresh Distiller invocations per core case, as defined by `PHASE0_BASELINE.md`.
