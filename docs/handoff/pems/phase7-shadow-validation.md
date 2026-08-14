# Phase 7 Shadow Validation

Phase 7 evaluates successive real Steward reconciliations without changing project-memory authority. `docs/project-chat-handoff.json` remains canonical throughout this phase. Generated PEMS, COVE/JCS bytes, reports, and human exports are noncanonical evidence.

`tools/pems/shadow_validate.py` accepts labeled canonical handoff snapshots bound to their repository commits. For each observation it performs the Phase 6 import twice, requires deterministic normalized PEMS, encodes through COVE and `jcs/1`, requires semantic round-trip equality, reconstructs deterministic human-readable Markdown, records hashes and actual byte sizes, and retains the complete provisional candidate-ID set and source-observation identity.

Transitions surface stable, added, and removed candidate IDs; source-observation evolution; expanded and compact byte deltas; and byte/human-export stability when the source commit is unchanged. A changed source intentionally does not assert byte equality because immutable provenance changes are themselves semantic evidence.

Synthetic tests may prove tooling behavior, but they do not satisfy the Phase 7 completion gate. Completion requires multiple real Steward reconciliation observations of the canonical handoff. Those observations must be captured rather than simulated, and discrepancies must remain visible in the evidence report.

Phase 7 does not admit provisional IDs, switch canonical authority, create `docs/project-chat-handoff.cove.json` as canonical, or authorize Phase 8. Steward identity admission and Phase 8 canonical adoption remain separate governance decisions.