# RGP Admission Tooling Status — 2026-08-16

## Result

The two non-blocking tooling defects recorded by `RGPD-20260816T183100-0700-003` are resolved.

### PEMS2_CONTRACT_VALIDATOR_NOT_CANDIDATE_PARAMETERIZED

Resolved by extending:

`docs/handoff/pems/v2/validate_pems2_contract.py`

The validator retains its existing no-argument PEMS/2 contract/fixture suite and now accepts:

```text
--candidate <complete-pems2-document>
```

Candidate mode validates the normative PEMS/2 JSON Schema plus generic cross-record integrity: unique record/relation IDs, project reference validity, source/source-observation linkage, provenance resolution, relation endpoints, derived proposition premises, and canonical contradiction ordering.

Candidate mode does not perform RGP admission or semantic identity decisions.

### NO_GENERIC_REPOSITORY_NATIVE_RGP_ADMISSION_RUNNER

Resolved by adding:

`.github/workflows/rgp-admission-proof.yml`

The standing `RGP Admission Proof` workflow supports reusable/manual proof execution with explicit submission, Steward-authored transaction plan, base PEMS/2 document, and evidence key inputs.

It:

1. replays `rgp-validator/1`;
2. executes `rgp-pems2-admission-transaction/1`;
3. runs candidate-aware PEMS/2 contract validation;
4. records complete output hashes and proof metadata;
5. uploads the complete proof bundle as a workflow artifact.

The workflow has read-only repository permissions and never installs canonical PEMS/COVE state. Steward semantic reconciliation and canonical installation remain separate authority operations.

## Self-test

Publishing the standing workflow to `project-chat-handoff` triggered its built-in self-test against canonical PEMS/2.

Workflow run:

`https://github.com/loteque/gdscript-voxel-engine/actions/runs/31986174387`

Result: `success`

The self-test replayed the RGP validator, validated current canonical PEMS/2 through the new candidate mode, generated a deterministic no-op admission plan against the exact current canonical hash, executed the admission transaction tooling, revalidated the generated candidate, and proved that the no-op candidate normalized to the exact base state.

## Architecture Boundary

These changes remove execution friction without changing authority:

```text
RGP producer
    ↓
validated candidate
    ↓
Steward reconciliation and transaction plan
    ↓
RGP Admission Proof workflow
    ↓
validated deterministic proof bundle
    ↓
Steward disposition / explicit canonical installation
```

CI proves transformation integrity. The Steward governs memory.