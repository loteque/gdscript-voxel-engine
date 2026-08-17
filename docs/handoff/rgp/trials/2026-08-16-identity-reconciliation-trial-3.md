# RGP Distillation Trial 3 — Identity Reconciliation

## Goal

Stress semantic identity reconciliation against the admitted Trial-2 canonical baseline without changing RGP ontology.

Trial 3 asks the Steward to distinguish:

- exact canonical reuse;
- semantic paraphrase reuse;
- similar-but-distinct propositions;
- two differently worded records that should converge on one new semantic identity while preserving both provenance chains;
- resolution of an admitted uncertainty through later contradictory and superseding evidence.

Candidate submission:

`docs/handoff/rgp/submissions/RGP-20260816T215500-0700-003.json`

## Canonical baseline

The trial is designed against the authoritative Trial-2 admitted state recorded by:

`docs/handoff/rgp/dispositions/RGPD-20260816T214100-0700-007.json`

Trial 2 admitted the standing-workflow observation as:

`pems:proposition:8b9f0d3af665298b7959`

and the former non-no-op uncertainty as:

`pems:unresolved_item:f9b6d2ffa30628f5c387`

These identities are producer expectations only for reconciliation pressure. The RGP producer does not assign canonical identity.

## Immutable source slice

1. `docs/handoff/rgp/tooling/ADMISSION_TOOLING_STATUS_2026-08-16.md`
   - blob `d53b49792a645d5775a15fea980b671d74b922f3`
   - grounds the standing workflow proposition and the former uncertainty context.

2. `docs/handoff/rgp/evidence/RGP-20260816T190100-0700-002.admission-006.runner-artifact/admission-proof.json`
   - blob `e4b0fbf4f7e031614b0177e9ffedfde4cd06a83f`
   - grounds the actual successful Trial-2 non-no-op proof.

3. `docs/handoff/rgp/dispositions/RGPD-20260816T214100-0700-007.json`
   - blob `6e5056966ee69ee0ac48394e2e74240e3670c17b`
   - grounds the authoritative closeout, exact-byte installation, and branch-local execution history.

## Candidate pressure cases

### r1 — exact reuse

Exact restatement of the previously admitted standing-workflow observation.

Expected pressure outcome: reuse the existing canonical proposition rather than allocate a duplicate.

### r2 — paraphrase reuse

Semantically equivalent wording of r1 with the same scope and truth conditions.

Expected pressure outcome: reconcile to the same canonical semantic identity as r1 despite lexical differences.

### r3 — similar but distinct

Observation about the branch-local immutable proof-request workflow that actually executed Trial 2's non-no-op proof.

It is related to the standing proof workflow but is not the same proposition or the same execution mechanism.

Expected pressure outcome: keep distinct from r1/r2.

### r4 — existing uncertainty reuse

Exact Trial-2 uncertainty that a novel non-no-op transaction remained unverified.

Expected pressure outcome: reuse the existing unresolved-item identity and preserve it historically rather than silently deleting or rewriting it.

### r5 and r6 — multi-source semantic convergence

Both assert that Trial 2's real non-no-op transaction passed deterministic admission proof, but use materially different wording and different immutable primary sources.

Expected pressure outcome: if the Steward determines the truth conditions are the same, map both candidate records to one canonical semantic identity while preserving both provenance chains. If the Steward finds a meaningful scope difference, keep them distinct and explain it. The test is semantic, not string-based.

### r7 — similar but distinct auditability fact

Observation that exact candidate bytes were persisted as immutable RGP evidence before canonical installation.

This is closely related to the successful proof but asserts a different event and must not collapse into r5/r6.

## Relations

- `r5 contradicts r4`
- `r5 supersedes r4`
- `r3 supports r5`

The first two must remain distinct. A successful non-no-op proof is incompatible with the old proposition that such behavior remains unverified, and it also replaces that uncertainty as the current project state while preserving the historical uncertainty.

The support edge does not make r3 a constitutive premise of r5.

## Producer validation

The complete submission envelope was replayed against the current `rgp-validator/1` structural invariants before commit.

Result: **PASS**.

The validator checks structure only. It does not decide any of the identity expectations above.

## Success criteria

Trial 3 succeeds if Steward reconciliation demonstrates all of the following without producer/tool identity decisions:

1. exact duplicate candidate content reuses canonical identity;
2. semantic paraphrase can reuse identity without requiring byte/string equality;
3. related workflow propositions are not collapsed merely because their wording and domain overlap;
4. independent provenance can converge on one semantic proposition without discarding either provenance chain;
5. the admitted uncertainty can be preserved historically while contradictory/superseding resolved evidence becomes current;
6. `contradicts` remains distinct from `supersedes`;
7. no validator or deterministic admission tool makes semantic identity decisions.

## Producer result

**Identity-reconciliation candidate: READY FOR STEWARD.**

No canonical PEMS/COVE mutation is performed by this trial. Canonical identity reuse or allocation remains exclusively a Steward decision.
