# Distiller Deterministic Validation

This directory contains the first deterministic validation layer for the reasoning-distiller protocol.

## Files

- `schema.json` documents the structural JSON contract.
- `validate_distillation.py` validates both structure and cross-record semantic invariants using only the Python standard library.
- `run_fixture_tests.py` verifies the validator against known-valid and known-invalid fixtures.
- `fixtures/` contains those fixed validation examples.

## Validation Boundary

JSON Schema handles local shape constraints such as allowed values, required fields, non-empty arrays, and omission of empty optional structures.

The Python validator additionally checks graph-wide rules:

- record IDs are unique;
- every premise resolves to a record;
- `derived` and non-empty `premise` are biconditional;
- premise references cannot self-reference;
- premise graphs are acyclic;
- derived chains terminate in axioms or externally grounded propositions;
- owner/governed authority has authority provenance;
- general relation endpoints resolve;
- general relations cannot self-reference;
- optional arrays and objects are non-empty when present.

This validator intentionally does not decide whether a proposition was classified semantically correctly. That remains evaluation territory for the distiller agent.

## Usage

```bash
python docs/distiller/validation/validate_distillation.py output.json
python docs/distiller/validation/run_fixture_tests.py
```

The validator exits non-zero when any supplied document is invalid.

## Design Rule

Validation must reject malformed symbolic reasoning without inventing, repairing, or reinterpreting it.
