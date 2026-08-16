# PEMS/2 Canonical Adoption Readiness

Status: **noncanonical design/evidence**

Authority: `STEWARD-20260816-023` authorizes canonical-adoption-readiness design and proof only. This document does not change canonical authority.

## Recommendation

PEMS/2 is technically ready for a future owner adoption decision **without introducing COVE/2**.

Use the independently versioned tuple:

```text
semantic profile: pems/2
structural codec: cove/1
byte serializer: jcs/1
```

This is not a reinterpretation of COVE/1. COVE/1 is explicitly domain-agnostic and treats its envelope `p` field as an opaque semantic/profile identifier. Its encoding operates only on normalized JSON strings, arrays, objects, numbers, booleans, and null. Therefore normalized PEMS/2 is within the existing COVE/1 structural domain.

A COVE/1 decoder presented with `p: "pems/2"` must still fail closed unless it has explicit support for the PEMS/2 semantic validator. Supporting a new semantic profile is not the same as changing the codec contract.

## Scoped grounding profiles

PEMS/2 does not impose universal `primary` provenance. Grounding strength is an admission/conformance concern.

Three profiles are defined in `GROUNDING_PROFILES.json`:

1. `legacy_preservation` — accepts preserved migrated semantics with untyped provenance when no stronger role can be established without invention.
2. `grounded_current_claim` — requires at least one `primary` provenance observation for newly admitted current claims whose truth depends on external/repository evidence.
3. `derived_interpretation` — requires explicit support/dependency provenance appropriate to the derivation; primary evidence may be inherited only through explicit graph rules, never manufactured.

Provenance insufficiency blocks admission under a profile; it does not mutate proposition kind, lifecycle, authority, or semantic identity.

## COVE/1 compatibility conclusion

COVE/1 can losslessly encode PEMS/2 without contract modification because:

- the `p` field is an opaque semantic/profile identifier;
- COVE/1 does not interpret PEMS record kinds, provenance roles, lifecycle states, relation semantics, or schema vocabulary;
- all PEMS/2 additions are ordinary normalized JSON structures representable by existing COVE/1 value tags;
- deterministic dictionary and object-shape construction is independent of semantic vocabulary;
- JCS remains an independently versioned serializer and PEMS/2 introduces no non-JSON or non-finite-number requirement.

Therefore a new `cove/2` would be unjustified unless a future requirement changes structural encoding behavior, envelope semantics, determinism rules, or the supported JSON value model.

## Dual-read compatibility

During any future cutover window, readers should support both profile tuples:

```text
(cove/1, pems/1, jcs/1)
(cove/1, pems/2, jcs/1)
```

Dispatch sequence:

1. parse and verify serializer/codec identifiers;
2. decode COVE/1 structurally;
3. inspect decoded/declared semantic profile;
4. dispatch to the matching PEMS semantic validator;
5. fail closed on unknown semantic major/profile;
6. never coerce PEMS/2 into PEMS/1 or vice versa.

## Candidate cutover sequence

A future owner-authorized cutover should be transactional at the governance level:

1. freeze one accepted canonical PEMS/1 source identity;
2. migrate deterministically to normalized PEMS/2;
3. validate PEMS/2 schema/semantics and identity/history/provenance invariants;
4. encode normalized PEMS/2 using frozen COVE/1 with envelope `p: "pems/2"` and `s: "jcs/1"`;
5. repeat migration + encoding independently and require byte-identical output;
6. decode candidate COVE/1 back to PEMS/2 and require exact normalized semantic equality;
7. produce deterministic human reconstruction and compatibility derivative;
8. verify dual-read behavior against the prior PEMS/1 canonical artifact and candidate PEMS/2 artifact;
9. obtain explicit owner approval and Steward admission of the exact candidate bytes/blobs;
10. atomically install canonical authority and record governance closeout.

## Rollback sequence

Rollback remains possible while the prior accepted PEMS/1 canonical artifact and governance identity are retained:

1. hard-stop new PEMS/2 admission;
2. re-establish the exact prior accepted PEMS/1 canonical artifact by immutable identity;
3. restore the matching deterministic derivative;
4. verify exact prior hashes/blobs and PEMS/1 semantic validation;
5. record rollback as a new Steward governance event without rewriting history.

No reverse semantic migration from newly admitted PEMS/2-only meaning is assumed. Once PEMS/2-only admissions exist, rollback requires an explicit compatibility/retention disposition rather than lossy down-conversion.

## Authority-transfer checks

Before canonical adoption, all must pass:

- exact source canonical identity fixed;
- all source semantic IDs preserved or explicitly governed;
- zero silent identity rebinding;
- lifecycle/history/provenance preserved;
- scoped grounding profiles pass for newly admitted material;
- PEMS/2 schema and semantic validation pass;
- COVE/1 structural round trip is lossless;
- repeated COVE/JCS candidate bytes are identical;
- deterministic human reconstruction is identical;
- readers reject unsupported profiles rather than coercing them;
- previous canonical artifact remains recoverable by immutable identity;
- owner approves the authority change;
- Steward admits exact candidate artifacts and records closeout.

## Owner-facing adoption recommendation

**Recommend eventual PEMS/2 adoption once the Steward verifies the readiness evidence and prepares an exact candidate cutover package.**

Human meaning: PEMS/2 can add stronger provenance/admission semantics without changing the compact codec. The project can evolve the meaning layer while keeping the proven COVE/1 structural format and JCS byte contract stable.

The owner decision should be about **when to move canonical authority from PEMS/1 to PEMS/2**, not about inventing another codec version.

## Not authorized here

This document does not:

- make PEMS/2 canonical;
- change canonical project memory;
- modify or reinterpret COVE/1;
- change JCS/1;
- admit new canonical identities;
- authorize production changes.
