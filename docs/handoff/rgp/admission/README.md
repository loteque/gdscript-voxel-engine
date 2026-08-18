# RGP → PEMS/2 Admission

Generic deterministic admission/proof implementations have moved to `loteque/reasoning-distiller`.

Voxel-engine pins framework commit `fb7290622d6a9d929a059f111cdd60cd50496fcf`. The active Steward-authorized executor consumes `admission/apply_admission_transaction.py`, `admission/apply_admission_transaction_v2.py`, and the PEMS/COVE backend from that pinned checkout.

This directory remains project-owned for Steward reconciliation transactions and historical admission evidence. The Steward retains semantic reconciliation and admission authority; deterministic tooling does not perform semantic reconciliation.
