# Distiller Phase 1 Assessment

Date: 2026-08-17
Role: Reasoning Graph Protocol Engineer
Contract: `rgp/1`
Baseline commit: `0f196fb096a1830b184710d175f9e6b03f0a5112`

## Result

**Prototype implementation: complete.**

**Initial evaluation batch: pass.**

**Independent repeated-run stability gate: pass.**

**Prototype stability: established for Phase-2 consideration.**

The successful independent batch consists of `invocation-1`, `invocation-20260817-b`, and `invocation-20260817-c`, covering the same five Phase-0 core cases for 15 fresh candidate graphs total. Their manifests record the same fixed directive, baseline, input, oracle, and scoring blobs and explicitly state that prior Phase-1 outputs were excluded during production. Raw candidates were preserved without post-hoc editing.

Detailed diagnostics are recorded in `docs/distiller/evaluation/phase1/independent/closeout.json`.

## Deterministic structural validation

All 15 candidates in the successful batch satisfy the current `rgp/1` structural requirements on inspection:

- optional absent collections are omitted rather than emitted empty;
- all record kinds are permitted;
- every non-derived observation has supplied primary provenance;
- the one derived claim uses a non-empty, resolving, acyclic `premise` array;
- no unsupported general relation is emitted;
- no `validated_by`, embedded authority, null value, empty object, or empty array is emitted.

No candidate fabricated provenance, reconstructed hidden chain-of-thought, invented an unresolved bug cause, or instructed mutation of canonical PEMS/COVE.

## Human-review scoring

All 15 candidates score 18/18 against the Phase-0 dimensions:

- Durable Recall: 3
- Precision: 3
- Relation Integrity: 3
- Provenance: 3
- Authority / Epistemic Safety: 3
- Compression: 3

There are no hard failures.

Every run therefore satisfies the Phase-1 acceptance threshold: Precision = 3, Provenance = 3, Authority / Epistemic Safety = 3, total >= 15/18, and no hard failure.

## Cross-invocation stability

### `field-authority`

Stable. All three runs preserve PointFieldResource as the authoritative scalar-field abstraction and preserve the prohibition on consumers duplicating field indexing/state. The explicit runtime-streaming scope limit is additionally retained in two runs; its omission in one does not remove either required high-value proposition.

### `offline-runtime-split`

Stable. All three runs preserve offline production of persisted chunk assets and runtime streaming ownership of residency. The generation-side placement of PointFieldResource and SurfaceNetsMesher is additionally retained in two runs.

### `validation-demo-contract`

Stable in required meaning. Two runs atomize the owner requirements into three decisions; one run bundles them into a single decision. All three preserve the required public-runtime validation direction and the implementation-gap observation with correct authority/provenance boundaries. This is factoring variation, not a kind or relation disagreement.

### `resource-loading-investigation`

Stable. All three runs preserve the supplied measurement scope as an observation and explicitly retain unmeasured platforms/builds as an `uncertainty`. One run additionally derives the supported claim that the supplied evidence does not establish universal causality. The earlier certainty-boundary failure is absent from this batch.

### `deployed-ui-failure`

Stable. All three runs preserve green CI/deployment, the missing RuntimeWorkloadExperimentUI in the deployed phone view, and the unresolved cause as an uncertainty. Successful deployment is never promoted into proof of runtime correctness and no cause is invented.

## Stability disposition

The successful batch satisfies the Phase-0 repeated-run policy:

1. all three runs for every case satisfy the acceptance threshold;
2. no run invents a proposition, relation, provenance identifier, or authority transition;
3. every required high-value proposition appears in all three runs;
4. cosmetic wording and factoring variation do not change semantic identity;
5. there is no unresolved proposition-kind or relation-type disagreement.

Therefore Phase 1 is **stable enough for Phase-2 producer/validator integration or shadow-operation consideration**.

This result does not authorize automatic canonical admission. Canonical PEMS/COVE and admission artifacts remain unchanged, and existing human review/admission controls remain required.

## Next gate

Proceed to Phase 2 under the existing safety boundary: integrate or shadow the Distiller with deterministic validation and human-reviewed admission, while keeping automatic canonical PEMS/COVE mutation disabled until separately authorized and evaluated.
