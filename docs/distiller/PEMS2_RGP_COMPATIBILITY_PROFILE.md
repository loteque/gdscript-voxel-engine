# PEMS/2 RGP Compatibility Profile

## Status

Design-freeze candidate produced in response to Architect note `ARCH-20260815T193249-0700-025`.

This profile resolves the seven open questions identified in `docs/distiller/PEMS_RGP_ARCHITECTURE_ASSESSMENT.md`. It does not authorize canonical migration. `pems/1` remains frozen.

PEMS/2 targets the current RGP major contract as **`rgp/1`**. The compatibility boundary is major-version exact: an unknown RGP major is rejected rather than interpreted heuristically.

## 1. Domain-record proposition profile

PEMS/2 initially permits exactly these existing domain record kinds to act directly as RGP proposition nodes:

| PEMS record kind | RGP kind | Statement projection | Conditions |
| --- | --- | --- | --- |
| `decision` | `decision` | `data.summary` | The record is a project decision under normal PEMS admission rules. |
| `unresolved_item` | `uncertainty` | `data.summary` | `resolution_state` is `open`, `blocked`, or `deferred` in the exported snapshot. |

No other PEMS/1 domain record is RGP-exportable as a proposition in the initial PEMS/2 profile.

In particular, `requirement`, `expectation`, `validation`, `architecture_adjustment`, `roadmap_adjustment`, `module`, `branch`, `pull_request`, `source`, and `source_observation` do not acquire implicit RGP proposition semantics merely because their data contains prose.

When reasoning about those domain entities is needed, RGP uses an explicit proposition about the entity rather than treating the entity itself as a proposition.

This narrow profile is intentional. It prevents heuristic text projection and preserves reversible meaning.

## 2. Resolved uncertainty export

RGP export is **snapshot-scoped**.

A PEMS `unresolved_item` exports as RGP `uncertainty` only when it is unresolved in the PEMS snapshot being exported:

- `open` -> exportable as `uncertainty`;
- `blocked` -> exportable as `uncertainty`;
- `deferred` -> exportable as `uncertainty`;
- `resolved` -> not exportable as a current RGP `uncertainty`.

A resolved item is not rewritten into a claim or observation. Doing so would invent a new proposition.

Historical RGP reconstruction of the earlier uncertainty requires exporting a historical PEMS snapshot or source-observation state from the time when the item was unresolved. Current-state export must not pretend a resolved uncertainty is still epistemically open.

## 3. Contradiction symmetry

`contradicts` is **semantically symmetric but canonically single-edge**.

PEMS/2 stores one relation record for a contradictory pair. Canonical endpoint ordering is deterministic by stable record ID:

```text
from = min(endpoint_a, endpoint_b)
to   = max(endpoint_a, endpoint_b)
```

Query semantics treat either endpoint as contradicting the other.

Two opposite-direction canonical `contradicts` records for the same pair are invalid duplicates.

Contradiction does not imply supersession, lifecycle mutation, rejection, or winner selection.

## 4. `depends_on` semantic breadth

PEMS/2 retains relation kind `depends_on` but makes its meaning explicit through a closed dependency profile:

```text
dependency_kind:
  conditional_validity
  structural
  legacy_untyped
```

Meanings:

- `conditional_validity`: continued validity, applicability, or revision of `from` is conditional on `to`. This is the only profile that imports/exports RGP `depends_on`.
- `structural`: project-domain dependency where the dependent entity relies on another entity operationally or structurally, without asserting RGP conditional-validity semantics.
- `legacy_untyped`: deterministic migration target for PEMS/1 `depends_on` relations whose exact semantic profile was not encoded in v1.

A valid PEMS/1 -> PEMS/2 migrator maps every existing v1 `depends_on` relation to `legacy_untyped`. Migration must not guess `conditional_validity` from relation wording or endpoint kinds.

PEMS/2 native relations must use `conditional_validity` or `structural`; `legacy_untyped` is reserved for migrated evidence until explicitly reconciled.

## 5. Generic proposition promotion

PEMS/2 does **not mutate a generic proposition record into a domain record** and does not rebind its stable identity.

If a previously admitted generic proposition later has a more precise project-domain representation, the two records represent distinct canonical assertions with distinct identities.

Governed refinement proceeds as follows:

1. create/admit the precise domain record under normal domain admission policy;
2. establish semantic equivalence or replacement through explicit reviewed reconciliation;
3. if the new domain record replaces the generic proposition as current project understanding, admit `supersedes` from the new domain record to the generic proposition;
4. transactionally update lifecycle/supersession metadata under existing PEMS policy;
5. preserve the generic proposition and its original reasoning edges historically;
6. create current reasoning edges to the new domain record only where those relationships are independently established or explicitly transferred by the reconciliation transaction.

No automatic edge retargeting occurs merely because wording is similar.

This is deliberately called **refinement by supersession**, not identity promotion.

## 6. Typed provenance enrichment atomicity

PEMS/2 provenance references always terminate at immutable `source_observation` records.

### Ordinary enrichment

Adding new provenance references to an existing admitted record or relation is ordinary enrichment when:

- proposition/relation semantics are unchanged;
- existing provenance is not deleted or semantically weakened;
- every new reference resolves to a valid source observation;
- the complete provenance update is committed atomically.

Adding `corroborating` or `context` evidence therefore does not create a new proposition.

Adding additional `primary` evidence also does not require a new proposition when the asserted proposition itself is unchanged.

### Reclassification

`untyped` -> one typed role (`primary`, `corroborating`, or `context`) is a governed provenance-classification operation. It may occur in place only when the role classification is explicitly established and the move is atomic. The same source-observation ID must not remain simultaneously in `untyped` and its newly assigned typed role after successful reconciliation.

Changing one typed role to another, removing typed provenance, or replacing grounding because earlier provenance was incorrect is a semantic correction and is review-required. It is not ordinary enrichment.

### Mutable external sources

A changed external source never mutates an existing `source_observation`. It creates a new source observation according to the existing PEMS source model. Whether that new observation enriches the same proposition or establishes a different proposition is decided from proposition semantics, not source recency.

## 7. RGP version binding

The PEMS/2 compatibility profile binds to **RGP major version 1**, identified as `rgp/1`.

Compatibility rules:

- PEMS/2 tooling supporting this profile accepts only RGP major `1` for lossless import/export claims.
- Unknown RGP major versions are rejected explicitly.
- A future RGP minor-compatible revision may be accepted only if the RGP contract explicitly defines minor compatibility and no new semantics fall outside this PEMS/2 profile.
- A future `rgp/2` requires a new explicit PEMS compatibility profile, even if some fields happen to resemble `rgp/1`.
- PEMS and RGP versions remain independent. PEMS/2 does not imply RGP/2, and RGP/1 does not imply PEMS/1.

Before RGP/1 is declared frozen for interchange, its serialized envelope should carry an explicit protocol identifier rather than relying on filename or surrounding context. That serialization change is an RGP contract task, not a PEMS semantic invention.

## Resulting PEMS/2 RGP profile

### RGP kinds

```text
RGP observation   -> PEMS proposition(observation)
RGP assumption    -> PEMS proposition(assumption)
RGP claim         -> PEMS proposition(claim)
RGP decision      -> PEMS decision when losslessly admissible
RGP uncertainty   -> PEMS unresolved_item when consequential and unresolved
```

Candidates that do not meet the domain mapping conditions remain provisional rather than being coerced.

### RGP graph structure

```text
RGP premise       -> PEMS derived_from
RGP supports      -> PEMS supports
RGP contradicts   -> PEMS contradicts (symmetric semantics, one canonical edge)
RGP depends_on    -> PEMS depends_on(dependency_kind=conditional_validity)
RGP supersedes    -> governed PEMS supersession after admission
```

### Provenance

```text
RGP primary        -> PEMS provenance.primary
RGP corroborating  -> PEMS provenance.corroborating
RGP context        -> PEMS provenance.context
PEMS/1 refs        -> PEMS provenance.untyped during deterministic migration
```

## Freeze invariants

The successor schema should not be frozen unless fixtures demonstrate all of the following:

- no heuristic RGP projection from unprofiled PEMS domain kinds;
- resolved uncertainty is absent from current RGP export but reconstructable from an appropriate historical snapshot;
- contradiction has one deterministic canonical identity and symmetric query behavior;
- migrated v1 dependencies remain `legacy_untyped` until reconciled;
- RGP dependencies import only as `conditional_validity`;
- refinement never mutates a proposition's stable kind/identity;
- provenance enrichment cannot delete or silently reclassify evidence;
- `untyped` reclassification is atomic and explicit;
- unknown RGP major versions fail closed;
- PEMS/1 remains unchanged and deterministically migratable.

## Authorization boundary

This document resolves the design questions required for the PEMS/2 semantic-contract tranche. It authorizes neither implementation nor canonical-memory migration by itself.