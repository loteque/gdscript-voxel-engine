# Distiller Phase 2 — Producer/Validator Integration

Date: 2026-08-17
Contract: `rgp/1`

## Purpose

Phase 2 proves that Distiller candidates can enter the authoritative deterministic RGP validator without producer-specific repair or exceptions.

This phase does **not** authorize canonical PEMS/COVE mutation, semantic admission, provenance resolution, identity reconciliation, or authority promotion.

## Pipeline under test

```text
observable supplied evidence
    -> Distiller
    -> immutable raw rgp/1 candidate
    -> authoritative deterministic validator
    -> validation result
    -> evaluation/review only
```

The raw candidate is frozen before validation. Validator failure must never trigger post-hoc candidate editing inside the same run.

## Authoritative validator

Phase 2 uses:

- `docs/distiller/validation/schema.json`
- `docs/distiller/validation/validate_distillation.py`
- `docs/distiller/validation/run_fixture_tests.py`
- existing fixtures under `docs/distiller/validation/fixtures/`

The producer must conform to the validator. The validator must not gain Distiller-specific exceptions merely to make producer output pass.

## Required integration checks

Every candidate is checked mechanically for:

1. schema and top-level shape;
2. permitted record kinds;
3. permitted relation vocabulary;
4. reference integrity;
5. non-empty and acyclic `premise` structure;
6. primary grounding for non-derived observations;
7. malformed/self-referential graph structure;
8. forbidden nulls, empty objects, and empty optional collections;
9. forbidden embedded authority or non-RGP validation relations.

Mechanical success means only that the graph is protocol-valid. It does not prove truth, semantic identity, normative authority, provenance resolution, or admissibility.

## Phase-2 evaluation batch

Use the successful Phase-1 independent batch as producer artifacts:

- `docs/distiller/evaluation/phase1/independent/invocation-1/`
- `docs/distiller/evaluation/phase1/independent/invocation-20260817-b/`
- `docs/distiller/evaluation/phase1/independent/invocation-20260817-c/`

There are 15 candidate graphs across five cases and three fresh invocations.

For each candidate, preserve:

- candidate path and blob SHA;
- validator version/blob SHA;
- schema blob SHA;
- pass/fail result;
- exact diagnostics on failure.

Do not treat the Phase-1 human score as a substitute for validator execution.

## Negative-path requirement

Phase 2 must also demonstrate that malformed candidates fail mechanically. Existing validator fixtures remain the primary regression corpus. At minimum the integration evidence must cover failures for malformed shape/reference/premise/grounding/empty-field behavior represented by the fixture suite.

A producer-specific wrapper may orchestrate validation, but it may not weaken or reinterpret validator results.

## Exit criterion

Phase 2 passes only when:

- all 15 successful Phase-1 raw candidates pass the authoritative validator unchanged;
- the existing validator fixture suite passes, including expected rejection fixtures;
- no producer-specific validator exception is introduced;
- validation results are preserved as auditable evidence;
- canonical PEMS/COVE and admission artifacts remain untouched.

If any raw candidate fails, preserve the failure and return to producer correction plus fresh evaluation rather than repairing that candidate.

## After Phase 2

A Phase-2 pass permits progression to **Phase 3 — Shadow Operation** on real project tasks. Shadow operation still prohibits automatic canonical mutation and adds human comparison, review-burden, omission/invention, provenance, authority, and stability measurements.
