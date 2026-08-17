# RGP → PEMS/2 Admission Transaction Tool

This directory provides deterministic execution surfaces for **Steward-authorized, already-reconciled** RGP admission transactions.

The tools do not perform semantic identity reconciliation and do not decide admission. The Steward supplies the canonical identities, provenance, lifecycle changes, and relations. The tooling proves that the supplied plan can be applied atomically to one exact PEMS/2 base snapshot and emits complete replacement artifacts for inspection and installation.

## Contracts

### v1: additive transactions

```text
rgp-pems2-admission-transaction/1
```

Executable:

```text
docs/handoff/rgp/admission/apply_admission_transaction.py
```

v1 supports `reuse_record_ids`, `new_records`, and `new_relations`. Reused records are assertions only and cannot be modified.

### v2: exact guarded reused-record updates

```text
rgp-pems2-admission-transaction/2
```

Executable:

```text
docs/handoff/rgp/admission/apply_admission_transaction_v2.py
```

v2 adds:

```json
{
  "record_updates": [
    {
      "record_id": "pems:...",
      "expected_before_sha256": "sha256-of-the-exact-normalized-record-envelope",
      "replacement": {
        "id": "same-pems-id",
        "kind": "same-kind",
        "lifecycle": "Steward-selected lifecycle",
        "data": {}
      }
    }
  ]
}
```

Every update target must also appear in `reuse_record_ids`. The exact existing record envelope is JCS-hashed before replacement. A mismatch aborts the whole transaction. Replacement may not change stable identity or record kind. The tool does not infer what fields should change; it applies only the complete Steward-selected replacement envelope.

## Inputs

Both contracts require:

- `expected_base_sha256`: exact normalized PEMS/2 JCS hash for the complete base snapshot;
- `reuse_record_ids`: canonical records whose stable identities have already been reconciled by the Steward;
- `new_records`: complete PEMS/2 record envelopes selected by the Steward;
- `new_relations`: complete PEMS/2 relation envelopes selected by the Steward.

v2 additionally requires `record_updates` (which may be empty).

No canonical IDs, provenance classifications, lifecycle decisions, conflicts, or supersessions are invented by either tool.

## Outputs

On success the output directory contains:

- `candidate.pems2.jcs.json`: complete normalized expanded PEMS/2 candidate;
- `candidate.cove.json`: complete `cove/1 | pems/2 | jcs/1` encoding;
- `admission-proof.json`: hashes, counts, base-binding proof, guarded-update proof, COVE round-trip proof, and graph-integrity proof.

The tools write nothing to canonical repository paths. Only the Steward may install emitted artifacts as canonical state.

## Safety properties

The tools fail closed on base-hash mismatch, missing reuse identities, record/relation ID collision, dangling graph endpoints, malformed reasoning relations, noncanonical contradictions, schema failure, COVE round-trip failure, or nondeterministic regeneration.

v2 additionally fails on update-target duplication, undeclared reuse, before-state mismatch, identity rebinding, or record-kind rebinding.

Pressure tests for v2 are in:

```text
docs/handoff/rgp/admission/test_admission_transaction_v2.py
```

They cover valid lifecycle transition plus incorrect base, incorrect before-state, identity rebinding, kind rebinding, undeclared reuse, and duplicate update rejection.

The generated artifacts are complete-file candidates specifically so the Steward never needs to manually transcribe or partially patch canonical memory.