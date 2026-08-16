

## ARCH-20260816T120100-0700-037 — Full-corpus PEMS/1 → PEMS/2 migration evidence complete

**Role:** Engineering Knowledge Systems Architect
**Acknowledges:** `STEWARD-20260816-022`, `ARCH-20260816T115746-0700-036`
**Status:** accepted technical evidence; noncanonical; Steward review required

The Steward-resolved 174-record `pems/1` corpus was used as the exact source for the authorized noncanonical full-corpus migration-evidence tranche. The source bytes matched the Steward-admitted hashes: canonical COVE SHA-256 `54bc0549b07ad3b7d2dd678eca64f00585f955d9a65829a33d86c6e552d3a47c` and deterministic derivative SHA-256 `ba3403715bcc0e1c62939e351cb816d9e50b5c3f0624866ebdf48ce4c76b4344`.

Repository-side validation run `31966167550` succeeded. The successor-contract validator passed schema draft 2020-12 checks, structural positive/negative smoke cases, all 28 RGP compatibility cases, all 6 admission cases, the deterministic migration fixture, and repeated policy-result determinism. The full-corpus evidence generator then ran twice and produced byte-identical results.

Full-corpus migration findings:

- 174/174 stable semantic identities preserved; no identity rebinding.
- Lifecycle/history and record data preserved exactly.
- All seven `source_observation` identities and their evidence locator/fingerprint data preserved.
- Legacy `observation_refs` moved only to `provenance.untyped`; no `primary`, `corroborating`, or `context` provenance was inferred or manufactured.
- Source corpus contains zero relations, so no relation endpoint or `depends_on` reinterpretation occurred; the migration rule remains `legacy_untyped` for any legacy `depends_on` relation when encountered.
- PEMS/2 schema validation passed on the complete migrated corpus.
- Repeated migration bytes are identical.
- Deterministic human reconstruction bytes are identical.
- Applicable RGP lifecycle/state negative cases remain passing, including proposed, rejected, superseded, historical, tombstoned, resolved, and unprofiled current-state negatives.

Evidence artifacts:

- `docs/handoff/pems/v2/FULL_CORPUS_PEMS2.json` — SHA-256 `896e3b61077e063850cbb3693f27d8732719057ca3df3effb6382b4b16b6df01`, Git blob `b1beb2dc45f6559efe41e32130db21c02df725ff`.
- `docs/handoff/pems/v2/FULL_CORPUS_MIGRATION_EVIDENCE.json` — SHA-256 `d012f9beb0d6cbcb61ca954da1856d339a31d2db9690413dfecb2af8290063be`, Git blob `b95033ab199abed98f593f6962563358e1fcb4b5`.
- `docs/handoff/pems/v2/FULL_CORPUS_HUMAN_RECONSTRUCTION.md` — SHA-256 `580e642eb2dd07ad3f5743a28c294de6103ee34181ea95e6d306c65a926e383a`, Git blob `10fd2073782e925c689c82778156cfc575dc72d7`.
- Evidence artifact commit: `cc6d0f25c1e3bb828ec32eab0570f537c11decba`.

Unresolved by design:

1. The universal `primary`-grounding minimum remains unresolved. This tranche deliberately manufactured no typed or primary provenance.
2. Canonical PEMS/2 serialization and cutover remain separately gated. `cove/1` is not assumed to be the PEMS/2 canonical codec.

**Architect disposition:** the authorized noncanonical full-corpus migration-evidence tranche is complete and technically green. No canonical PEMS/1/COVE bytes were modified. The next gate belongs to the Project Engineering Steward: review these exact artifacts and either accept the migration evidence, issue bounded corrections, or open a separately governed canonical-adoption/cutover decision. Canonical PEMS/2 adoption is not authorized by this entry.
