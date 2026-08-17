# Distiller Phase 1 Assessment

Date: 2026-08-17
Role: Reasoning Graph Protocol Engineer
Contract: `rgp/1`
Baseline commit: `0f196fb096a1830b184710d175f9e6b03f0a5112`

## Result

**Prototype implementation: complete.**

**Initial evaluation batch: pass.**

**Independent repeated-run stability gate: fail.**

**Prototype stability: not established.**

The Phase-1 producer contract remains explicit in `docs/distiller/PHASE1_PROTOTYPE.md`, with a fixed supplied-source registry in `docs/distiller/evaluation/phase1-inputs.json`.

Three genuinely fresh Distiller invocations have now been preserved under `docs/distiller/evaluation/phase1/independent/`, covering the same five Phase-0 core cases for 15 independent candidate graphs total. Raw candidates were not edited during closeout. Detailed per-run diagnostics and scores are recorded separately in `docs/distiller/evaluation/phase1/independent/closeout.json`.

## Deterministic structural validation

Invocation 1 passes the current deterministic validator for all five cases.

Invocations 2 and 3 fail deterministic validation for all five cases because each candidate emits:

```json
"relations": []
```

The `rgp/1` output contract requires optional empty collections to be omitted, and `validate_distillation.py` rejects `relations` when it is present but empty. This yields 10 validator failures across the 15 independent candidates.

The raw candidates remain preserved as produced. They were not repaired after validation because the Phase-1 invocation contract requires unedited candidate evidence.

No candidate fabricated provenance, emitted an unsupported relation type, reconstructed hidden chain-of-thought, embedded authority, or instructed mutation of canonical PEMS/COVE.

## Human-review scoring

Thirteen of the 15 independent candidates score 18/18 against the Phase-0 dimensions on semantic content.

The two `resource-loading-investigation` candidates from invocations 2 and 3 each score 16/18:

- Durable Recall: 2
- Precision: 3
- Relation Integrity: 3
- Provenance: 3
- Authority / Epistemic Safety: 2
- Compression: 3

They do not satisfy the Phase-1 acceptance threshold because Authority / Epistemic Safety must equal 3.

Neither case has a hard failure. The issue is narrower: both runs preserve that no measurements were supplied for other platforms or builds as an `observation`, then derive a `claim` that the evidence does not establish universal causality. They omit the oracle-required durable proposition that unmeasured platforms or builds **remain an explicit uncertainty**.

## Cross-invocation stability

### `field-authority`

Stable at the required semantic level. All three invocations preserve PointFieldResource authority and the prohibition on consumers duplicating field indexing/state. Invocations 2 and 3 additionally retain the explicit scope limit that runtime streaming is not assigned to PointFieldResource.

### `offline-runtime-split`

Stable at the required semantic level. All three invocations preserve offline production of persisted assets and runtime ownership of residency. Invocations 2 and 3 additionally preserve PointFieldResource and SurfaceNetsMesher as generation-side concerns.

### `validation-demo-contract`

Stable in meaning, with factoring variation. Invocation 1 bundles the three owner requirements into one decision; invocations 2 and 3 factor public-runtime validation, headless validation where practical, and Integration Preview exposure into separate atomic decisions. The implementation-gap observation is preserved in all three runs.

### `resource-loading-investigation`

Not stable. The required measurement-scope proposition is preserved in all three invocations, but the required uncertainty appears in only 1 of 3 runs. Invocations 2 and 3 instead use an observation about absent measurements plus a derived claim. This is a repeated proposition-kind disagreement and therefore requires review before progression under the Phase-0 stability policy.

### `deployed-ui-failure`

Stable at the required semantic level. All three invocations preserve successful CI/deployment, the missing RuntimeWorkloadExperimentUI in the deployed phone view, and the unresolved cause. Later runs preserve additional supplied observations without resolving the cause.

## Stability disposition

The independent-run requirement has now been executed, but its exit criteria are not met.

Blocking evidence:

1. 10 of 15 independent candidates fail deterministic structural validation because optional empty `relations` collections were emitted.
2. The required resource-loading uncertainty is preserved in only 1 of 3 independent runs.
3. The repeated resource-loading kind disagreement requires review.
4. The resource-loading cases in invocations 2 and 3 score Authority / Epistemic Safety = 2, below the mandatory threshold of 3.

Therefore Phase 1 must **not** be declared stable and the project should **not** progress to Phase 2 producer/validator integration or shadow operation on the strength of this batch.

Automatic canonical admission remains unauthorized. Canonical PEMS/COVE and admission artifacts were not modified by this evaluation.

## Next gate

Make a producer-level correction rather than editing the preserved raw candidates:

- reinforce that optional empty collections, especially `relations`, must be omitted;
- reinforce that absence of measurements for other platforms/builds leaves their behavior as an explicit `uncertainty`, rather than replacing that uncertainty with only an observation about missing measurements;
- execute at least three new genuinely fresh Distiller invocations over the same five core cases;
- preserve those outputs raw and repeat deterministic validation, oracle scoring, and cross-run comparison.

Only after every fresh run satisfies the acceptance threshold and no kind/relation disagreement remains unresolved should Phase 1 be declared stable.
