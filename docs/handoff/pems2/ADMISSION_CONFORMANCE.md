# PEMS/2 Admission, Validation, and Conformance Draft

Status: **normative successor draft; canonical admission not authorized**.

## Separation of concerns

PEMS/2 keeps five axes separate:

- **proposition kind**: observation, assumption, claim, or a profiled domain kind;
- **epistemic role**: direct or derived;
- **lifecycle**: current, historical, superseded, tombstoned;
- **admission outcome**: rejected, provisional, admitted;
- **authority/provenance**: recovered from immutable source chains and governed source metadata.

No axis implies another. An admitted assumption remains an assumption. A derived observation remains an observation. A decision is not accepted merely because it is structurally valid.

## Validation layers

### Structural validation

The JSON Schema proves only shape and closed vocabulary.

### Semantic validation

A conforming semantic validator additionally proves:

- unique record/relation IDs;
- all record/relation references resolve;
- every provenance ID resolves to `source_observation`;
- no source observation occupies more than one provenance role on one object;
- supersession references are internally consistent under the existing PEMS lifecycle policy;
- contradiction edges are canonically ordered and unique by unordered endpoint pair;
- `depends_on` has a valid dependency kind;
- `legacy_untyped` is migration-only and carries `migration_origin=pems/1`;
- RGP-profile proposition relations connect proposition-capable endpoints;
- current-state RGP projection obeys lifecycle/state restrictions.

### Compatibility validation

RGP compatibility additionally proves:

- protocol major is exactly `rgp/1`;
- unknown majors fail closed;
- current accepted decisions may project directly;
- proposed/rejected/superseded/historical decisions do not project as bare current RGP decisions;
- current open/blocked/deferred unresolved items may project as uncertainty;
- resolved/historical unresolved items do not project as current uncertainty;
- contradiction round-trip preserves one canonical edge and symmetric query semantics;
- native RGP dependencies map only to `conditional_validity`.

## Admission transaction

Admission consumes validated provisional candidates plus existing canonical state and policy.

The transaction may:

- reconcile to an existing stable identity;
- enrich permissible provenance;
- admit a distinct compatible proposition;
- admit an explicit contradiction;
- admit reviewed supersession/refinement;
- retain provisional;
- reject.

The transaction must never:

- manufacture normative authority;
- rebind an existing identity to a different semantic object;
- mutate a generic proposition into a different domain kind;
- erase conflicting or superseded history;
- silently retarget reasoning edges because text looks similar;
- admit a relation with unresolved endpoints;
- admit a derived proposition while dropping required premise relations;
- infer typed provenance or dependency meaning from wording.

## Atomicity

Admission is atomic over the connected subgraph required for integrity.

On success, every admitted endpoint, premise, provenance reference, and supersession reference resolves in the resulting graph. On failure, no partial canonical mutation is committed.

## Generic proposition refinement

A later precise domain record is a distinct identity. If governance establishes replacement:

1. admit/reconcile the domain record;
2. preserve the generic proposition;
3. establish reviewed supersession/refinement;
4. preserve the earlier reasoning/provenance graph historically;
5. create current reasoning edges only when independently established.

This prevents ontology refinement from becoming identity rebinding.

## Provenance operations

Ordinary enrichment may add new evidence while meaning is unchanged.

Role reclassification, typed-evidence deletion, or replacement of incorrect grounding is review-required semantic correction. `untyped -> typed` must be atomic, and the same source observation may not remain in both roles.

Authority remains source-chain-derived. A `primary` label does not itself create owner or architectural authority.

## Conformance classes

### PEMS/2 structural

Passes `pems-v2.schema.json`.

### PEMS/2 semantic

Passes structural validation plus all graph/provenance/lifecycle invariants.

### PEMS/1 migration

Produces the exact deterministic successor transform described in `MIGRATION.md`, with stable identities preserved.

### RGP/1 compatibility

Passes semantic conformance plus the complete compatibility fixture suite.

### Canonical migration readiness

Not defined by this tranche. A later gate must additionally prove full-corpus migration, deterministic canonical bytes under an explicitly authorized representation contract, human reconstruction, longitudinal identity/history preservation, rollback/cutover procedure, and Steward/owner authorization.

## Required negative fixtures

A conformance suite must reject or mark non-exportable at least:

- current proposed decision;
- current rejected decision;
- superseded decision;
- historical accepted decision;
- current resolved unresolved item;
- historical open unresolved item;
- duplicate reverse contradiction;
- noncanonical contradiction endpoint order;
- native `legacy_untyped` dependency without migration origin;
- provenance reference to a non-source-observation;
- the same source observation in multiple provenance roles;
- unknown RGP major version.

These negative cases establish that compatibility is semantic rather than merely syntactic.

## Evidence standard for Steward review

A successor contract is ready for the next Steward gate only when:

- all normative artifacts agree;
- schema/semantic fixtures pass deterministically in repeated runs;
- migration exact-output fixture passes;
- negative cases fail for the expected reason;
- no canonical v1 files have changed;
- no stable v1 identities are rebound;
- unresolved ambiguity is listed explicitly rather than hidden behind implementation choice.

The next gate is review/adoption of the successor contract itself, not canonical migration.
