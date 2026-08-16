

## ARCH-20260816T124900-0700-038 — PEMS/2 canonical-adoption readiness design complete

**Role:** Engineering Knowledge Systems Architect
**Acknowledges:** `STEWARD-20260816-023`, `ARCH-20260816T120100-0700-037`
**Status:** design/evidence complete; noncanonical; Steward review required

The Steward accepted the 174-record noncanonical PEMS/1 → PEMS/2 migration evidence and authorized a bounded canonical-adoption-readiness design tranche. That tranche is complete without changing canonical authority.

The decisive codec result is that frozen `cove/1` can represent normalized `pems/2` without contract reinterpretation. COVE/1 is explicitly domain-agnostic: its `p` field is an opaque semantic/profile identifier, and its core encoding understands only JSON structural value classes via global string interning and deterministic object-shape factoring. PEMS/2 introduces new semantic/schema vocabulary but no non-JSON structural value type. Therefore the recommended future canonical tuple is `cove/1` + `pems/2` + `jcs/1`; a `cove/2` successor is not justified by the current evidence.

This does not weaken fail-closed behavior. A COVE/1 reader presented with `p: "pems/2"` must explicitly support the PEMS/2 validator or reject the artifact. Semantic-profile support is independently versioned from structural codec support.

Scoped grounding policy is now explicit rather than universal. `GROUNDING_PROFILES.json` defines:

- `legacy_preservation`: preserved migrated semantics may retain only untyped provenance when stronger roles cannot be established without invention;
- `grounded_current_claim`: newly admitted current claims whose truth depends on repository/external evidence require at least one primary `source_observation`;
- `derived_interpretation`: derived durable propositions require explicit derivation/support structure; evidence roles are never manufactured merely to obtain admission.

Admission failure under a grounding profile blocks admission only; it must not retype a proposition, rebind identity, alter lifecycle, or manufacture provenance.

The readiness design defines dual-read behavior for `(cove/1,pems/1,jcs/1)` and `(cove/1,pems/2,jcs/1)`, fail-closed unknown-profile behavior, exact future cutover/rollback sequencing, authority-transfer checks, deterministic byte/round-trip requirements, and the owner-facing adoption criteria. Reverse migration of future PEMS/2-only admissions is deliberately not assumed; rollback after such admissions requires an explicit retention/compatibility disposition rather than lossy down-conversion.

Durable artifacts:

- `docs/handoff/pems/v2/CANONICAL_ADOPTION_READINESS.md` — Git blob `748ab352fd6b053e686eb9b52d088fff97f5c80a`.
- `docs/handoff/pems/v2/GROUNDING_PROFILES.json` — Git blob `ab49f7574a68d0bd9bb922931420b9bab9fc03c9`.
- `docs/handoff/pems/v2/ADOPTION_READINESS_EVIDENCE.json` — Git blob `93722fc2be927f51dfb96ae937ee604dbacee47e`.

The accepted full-corpus migration evidence remains unchanged: 174/174 identities preserved, no rebinding, no typed/primary provenance manufactured, 28/28 RGP compatibility cases, and 6/6 admission cases.

**Architect recommendation:** return this package to the Steward. If the Steward accepts the readiness design, the next bounded technical gate should be an exact noncanonical cutover-candidate generation/proof tranche against one frozen canonical PEMS/1 revision, producing the candidate `cove/1` envelope with `p: "pems/2"`, deterministic `jcs/1` bytes, structural decode → exact normalized PEMS/2 equality, dual-read fixtures, rollback artifact identities, and owner-facing exact candidate hashes. Actual canonical adoption must still require explicit owner approval followed by Steward admission of those exact bytes and governance closeout.

No canonical PEMS/1/COVE artifact, Steward-owned file, production code, ADR, ROADMAP, demo, test, or `main` state was modified by this tranche.
