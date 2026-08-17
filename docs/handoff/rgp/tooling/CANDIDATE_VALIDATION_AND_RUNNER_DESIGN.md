# Candidate Validation and Standing Admission Runner Design

## Purpose

Close the two non-blocking tooling defects recorded by `RGPD-20260816T183100-0700-003` without changing RGP, PEMS/2, COVE, JCS, or Steward authority semantics.

## Decisions

1. `validate_pems2_contract.py` gains an optional `--candidate` argument. Existing no-argument contract/fixture behavior remains unchanged.
2. Candidate validation is generic PEMS/2 validation: normative JSON Schema validation plus cross-record graph/reference integrity checks. It does not perform RGP semantic admission.
3. A standing GitHub Actions runner accepts a Steward-prepared immutable submission path and admission transaction plan path.
4. The runner replays `rgp-validator/1`, executes `rgp-pems2-admission-transaction/1`, runs candidate-aware PEMS/2 validation, records hashes/proofs, and uploads the complete evidence bundle.
5. The standing runner never modifies `docs/project-chat-handoff.json` or `docs/project-chat-handoff.cove.json` and never chooses canonical identities.
6. Canonical installation remains a separate Steward-authorized operation after proof inspection.

## Authority Boundary

```text
Steward reconciliation
    ↓
Steward-authored transaction plan
    ↓
standing admission proof runner
    ↓
validated candidate + proof bundle
    ↓
Steward inspection / disposition
    ↓
explicit canonical installation, when authorized
```

CI proves deterministic transformation. It does not admit project knowledge.