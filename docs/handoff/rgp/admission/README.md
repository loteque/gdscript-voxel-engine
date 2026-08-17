# RGP → PEMS/2 Admission Transaction Tool

This directory provides a deterministic execution surface for a **Steward-authorized, already-reconciled** RGP admission transaction.

It does not perform semantic identity reconciliation and does not decide admission. The Steward supplies a complete transaction plan containing the exact canonical records and relations to add or reuse. The tool proves that this plan can be applied atomically to one exact PEMS/2 base snapshot and emits complete replacement artifacts for inspection and installation.

## Contract

Transaction plan contract:

```text
rgp-pems2-admission-transaction/1
```

Executable:

```text
docs/handoff/rgp/admission/apply_admission_transaction.py
```

## Inputs

```bash
python3 docs/handoff/rgp/admission/apply_admission_transaction.py \
  --base docs/project-chat-handoff.json \
  --plan /path/to/steward-transaction.json \
  --schema docs/handoff/pems/v2/pems-v2.schema.json \
  --out-dir /tmp/rgp-admission
```

The plan includes:

- `expected_base_sha256`: exact JCS bytes expected for the input PEMS/2 snapshot;
- `reuse_record_ids`: existing canonical records that the transaction depends on but must not modify;
- `new_records`: complete PEMS/2 record envelopes approved by the Steward;
- `new_relations`: complete PEMS/2 relation envelopes approved by the Steward.

No canonical IDs are invented by the tool. Identity remains a Steward decision.

## Outputs

On success the output directory contains:

- `candidate.pems2.jcs.json`: complete normalized expanded PEMS/2 candidate;
- `candidate.cove.json`: complete `cove/1 | pems/2 | jcs/1` encoding;
- `admission-proof.json`: hashes, counts, base-binding proof, COVE round-trip proof, and graph-integrity proof.

The tool writes nothing to canonical repository paths. The Steward may install the emitted complete artifacts only after inspecting the proof and verifying that the transaction plan represents its authoritative reconciliation.

## Safety Properties

The tool fails closed if:

- the base is not `pems/2`;
- the base JCS hash differs from `expected_base_sha256`;
- a reused record does not exist;
- a new record or relation ID collides with canonical state;
- a relation endpoint does not resolve after the complete transaction;
- a `derived_from`, `supports`, or `contradicts` relation is malformed;
- a contradiction is not stored in canonical lexical endpoint order;
- the resulting PEMS/2 graph fails its JSON Schema;
- deterministic COVE encode/decode does not round-trip exactly;
- repeated generation does not yield identical JCS/COVE bytes.

The generated artifacts are complete-file candidates specifically so the Steward never needs to manually transcribe or partially patch canonical memory.