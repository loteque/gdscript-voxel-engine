# Distiller Phase 1 Assessment

Date: 2026-08-16
Role: Reasoning Graph Protocol Engineer
Contract: `rgp/1`
Baseline commit: `0f196fb096a1830b184710d175f9e6b03f0a5112`

## Result

**Prototype implementation: complete.**

**Initial evaluation batch: pass.**

**Prototype stability: not yet established.**

The Phase-1 producer contract is explicit in `docs/distiller/PHASE1_PROTOTYPE.md`, with a fixed supplied-source registry in `docs/distiller/evaluation/phase1-inputs.json`.

The initial batch preserves 15 raw candidate graphs: three semantic passes over each of the five Phase-0 core cases.

## Structural validation

All 15 candidate graphs satisfy the current deterministic validator contract in `docs/distiller/validation/validate_distillation.py`:

- only current `rgp/1` record kinds are used;
- only current provenance roles are used;
- non-derived observations carry `provenance.primary`;
- no unsupported or empty optional structures are emitted;
- no dangling, self-referential, or cyclic premise references exist;
- no invalid relation vocabulary is emitted.

No candidate uses `validated_by`, embedded `authority`, hidden-chain-of-thought material, fabricated source IDs, or PEMS/COVE mutation instructions.

## Human-review scoring

All 15 batch candidates score 18/18 against the Phase-0 scoring dimensions:

- Durable Recall: 3
- Precision: 3
- Relation Integrity: 3
- Provenance: 3
- Authority / Epistemic Safety: 3
- Compression: 3

No hard failures were recorded.

The batch preserves the expected semantic boundaries:

- PointFieldResource ownership remains a decision rather than an inferred performance claim.
- Offline generation and runtime residency remain separate scoped decisions.
- The validation-demo requirement is sourced separately from the implementation gap.
- Resource-loading conclusions remain measurement-scoped and unmeasured platforms/builds remain uncertainty.
- Green CI/deployment does not erase the observed missing runtime UI, and the cause remains unresolved.

## Important limitation

The three passes per case were produced during one RGP Engineer execution context. They are not genuinely independent fresh model invocations.

Therefore the strict Phase-0 stability criterion is **not yet satisfied**, even though the batch itself is semantically and structurally clean.

This is not an RGP semantic defect. It is an evaluation-evidence limitation.

## Phase-1 disposition

- Producer contract: **ready**
- Current `rgp/1` vocabulary fit: **ready**
- Deterministic structural validation compatibility: **ready**
- Initial precision/authority/provenance behavior: **promising**
- Independent repeated-run stability evidence: **pending**
- Automatic canonical admission: **not authorized**

## Next gate

Run the same five core cases through at least three genuinely fresh Distiller invocations and preserve the raw outputs. If every independent run meets the Phase-0 threshold and no kind/relation disagreement requires review, Phase 1 may be declared stable and the project can proceed to Phase 2 producer/validator integration and then shadow operation.

Do not modify canonical PEMS/COVE as part of this evaluation.
