# PEMS/2 Successor Semantic Contract

## Status and authority

This directory is a **normative successor-contract draft** produced under `STEWARD-20260815-020`. It defines `pems/2` for review and conformance testing. It does **not** migrate canonical project memory, reinterpret `pems/1`, change `cove/1` or `jcs/1`, or authorize canonical cutover.

`pems/1`, `cove/1`, and the current canonical project memory remain authoritative until a separate owner/Steward migration decision.

## Design goals

PEMS/2 adds only the semantics demonstrated by the RGP/Distiller evidence that cannot be represented losslessly in `pems/1`:

1. generic durable propositions with closed proposition kinds;
2. epistemic role distinct from proposition kind;
3. typed provenance distinct from source authority;
4. explicit reasoning relations;
5. a closed `depends_on` profile;
6. snapshot-scoped, lossless RGP/1 compatibility rules.

Admission state is not proposition truth, epistemic role, authority, or lifecycle. It remains a governance outcome at the Steward boundary.

## Document shape

A normalized PEMS/2 document has:

```json
{
  "semantic": "pems/2",
  "project_id": "pems:project:...",
  "records": [],
  "relations": []
}
```

Record and relation envelopes retain stable semantic identifiers and lifecycle fields from PEMS/1. PEMS/2 replaces the v1 `observation_refs` provenance list with the `provenance` envelope. Migration moves every v1 observation reference to `provenance.untyped` without inventing evidence roles.

### Provenance envelope

```json
{
  "primary": ["pems:source_observation:..."],
  "corroborating": ["pems:source_observation:..."],
  "context": ["pems:source_observation:..."],
  "untyped": ["pems:source_observation:..."]
}
```

Roles are optional. Empty role arrays are semantically invalid and must be omitted. A source-observation ID must occur in at most one role in a single envelope.

All provenance references terminate at immutable or otherwise explicitly modeled `source_observation` records. Source `authority` remains a property of the source chain and is never inferred from provenance role.

## Generic proposition

PEMS/2 adds record kind `proposition`:

```json
{
  "id": "pems:proposition:...",
  "kind": "proposition",
  "lifecycle": "current",
  "provenance": {"primary": ["pems:source_observation:..."]},
  "data": {
    "statement": "The measured loader wait dominates this trace.",
    "proposition_kind": "observation",
    "epistemic_role": "derived",
    "about_ids": ["pems:module:..."]
  }
}
```

`proposition_kind` is closed to:

- `observation`: an empirical or evidentiary proposition;
- `assumption`: a proposition intentionally relied upon without being established as fact;
- `claim`: a durable logical, interpretive, evidentiary-scope, or compliance proposition not accurately modeled as observation or assumption.

`epistemic_role` is orthogonal:

- `asserted`: represented directly rather than derived from an admitted premise graph;
- `derived`: depends on one or more `derived_from` premise relations. A derived proposition must have at least one current or historically resolvable premise according to the snapshot being validated.

A generic proposition does not acquire project authority merely through admission. Authority is recovered through source/source-observation provenance and governed project sources.

## Domain propositions and RGP/1

The initial compatibility profile permits direct RGP proposition projection from exactly two existing domain kinds, under strict state conditions:

- PEMS `decision` -> RGP `decision` only when the record is `lifecycle == "current"` **and** `data.decision_state == "accepted"`.
- PEMS `unresolved_item` -> RGP `uncertainty` only when the record is `lifecycle == "current"` and `data.resolution_state` is `open`, `blocked`, or `deferred`.

Proposed, rejected, superseded, tombstoned, or historical decisions are not bare current RGP decisions. Resolved or historical unresolved items are not current RGP uncertainties. Historical reasoning reconstruction uses the corresponding historical PEMS snapshot or source-observation boundary.

No other project-domain record kind is implicitly promoted to a proposition because it contains prose.

## Reasoning relations

PEMS/2 retains PEMS/1 relations and adds:

- `supports`: `from` strengthens `to` without constituting it as a derivation premise;
- `contradicts`: semantically symmetric disagreement between propositions;
- `derived_from`: retained and used as the RGP `premise` mapping;
- `depends_on`: retained with a required closed `dependency_kind`.

`depends_on.data.dependency_kind` is exactly:

- `conditional_validity`: validity/applicability of `from` may require revision if `to` changes; this is the RGP/1 meaning;
- `structural`: project-domain structural/operational dependency without RGP conditional-validity semantics;
- `legacy_untyped`: migration-only state for PEMS/1 dependencies whose narrower semantics were never encoded.

Native PEMS/2 creation must not create `legacy_untyped`; only deterministic migration may do so pending later governed reconciliation.

### Contradiction canonical form

`contradicts` is symmetric in meaning but stored once. Canonical endpoint order is lexical stable-ID order:

```text
from = min(endpoint_a, endpoint_b)
to   = max(endpoint_a, endpoint_b)
```

Self-contradiction and duplicate opposite-direction contradiction edges are invalid.

## Identity and refinement

Schema evolution does not change semantic identity. The PEMS/1 -> PEMS/2 migration reuses every existing record and relation ID because migration changes representation shape, not the represented semantic object.

A generic proposition must never be mutated in place into a different domain record kind. If later governance establishes a more precise domain record, that record receives or reconciles its own stable identity. Reviewed supersession/refinement links the new domain identity to the preserved generic proposition. Reasoning edges move only through an explicit reconciliation transaction; wording similarity is not sufficient.

## Provenance updates

Adding new evidence without changing proposition/relation meaning may enrich the same identity atomically.

- Adding new `corroborating`, `context`, or additional `primary` evidence is ordinary enrichment.
- Moving `untyped` evidence into a typed role is a governed classification operation and must remove it from `untyped` atomically.
- Changing one typed role to another, deleting typed provenance, or replacing incorrect grounding is semantic correction requiring review.
- Changed source content creates a new `source_observation`; an old observation is never mutated to represent new source bytes.

## Version compatibility

The initial interchange profile is exactly `rgp/1`.

Unknown RGP major versions fail closed. PEMS tooling may not infer compatibility from similar field names or version numbers. PEMS and RGP version lines are independent.

PEMS/2 -> PEMS/1 downgrade is permitted only when every v2-only semantic can be represented without loss. Typed provenance, generic propositions, `supports`, `contradicts`, and semantically typed dependencies are v2-only and therefore normally make downgrade fail explicitly rather than silently erase meaning.

## Deterministic normalization

For one semantic graph, normalization must produce one structural result:

1. validate all IDs and references before ordering;
2. sort records by `id`;
3. sort relations by `id`, after enforcing canonical contradiction endpoint order;
4. sort every ID/reference array lexically and reject duplicates;
5. order is semantically irrelevant except where a future field explicitly says otherwise;
6. omit empty optional provenance roles rather than serializing empty arrays;
7. reject unsupported semantic/RGP major versions rather than guessing.

`jcs/1` remains the independent canonical-byte contract if and only if a later migration chooses to serialize PEMS/2 through the existing JCS layer. This draft does not modify JCS or COVE.

## Admission boundary

Validation proves conformance; admission decides whether a conforming candidate becomes canonical.

Admission must preserve:

- stable semantic identity or explicitly create a distinct new identity;
- complete provenance;
- lifecycle/history;
- premise and relation graph integrity;
- source-derived authority;
- conflicts and supersession rather than overwriting them.

Admission must not turn well-formed agent output into truth or authority. Decisions, claims, conflicts, provenance reclassification, supersession, or changes to current canonical understanding are review-required unless a later policy proves a narrower deterministic rule safe.

## Normative companion artifacts

- `pems-v2.schema.json`: JSON Schema 2020-12 structural contract.
- `MIGRATION.md`: deterministic PEMS/1 -> PEMS/2 migration contract.
- `RGP_COMPATIBILITY_FIXTURES.json`: positive/negative compatibility pressure cases.
- `ADMISSION_CONFORMANCE.md`: admission, validation, and conformance requirements.
- `validate_pems2_contract.py`: executable deterministic fixture/contract validator.

## Explicit non-goals

This draft does not:

- change current canonical project memory;
- authorize PEMS/2 canonical adoption;
- reinterpret any PEMS/1 record or relation;
- change COVE/1 or JCS/1;
- automatically admit Distiller output;
- make provenance role equivalent to authority;
- make admission state equivalent to truth or epistemic certainty.
