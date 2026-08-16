# Deterministic PEMS/1 -> PEMS/2 Migration Contract

## Status

This is a normative successor migration draft under `STEWARD-20260815-020`. It defines a deterministic transform for testing and later Steward review. Running the transform does not change canonical authority.

## Preconditions

A migrator must accept only a structurally and semantically valid normalized `pems/1` document. Invalid v1 input fails before transformation. The migrator must not repair, reinterpret, or infer missing v1 meaning.

Input semantic version must be exactly `pems/1`.

## Output invariants

A successful migration produces exactly one normalized `pems/2` document such that:

- `project_id` is unchanged;
- every PEMS/1 record ID is present exactly once with the same represented semantic object;
- every PEMS/1 relation ID is present exactly once with the same endpoints and represented relation meaning;
- lifecycle, supersession, effective/recorded timestamps, and type-specific data are preserved unless an explicitly listed structural migration rule changes only representation shape;
- source and source-observation identities/data remain unchanged;
- no new source observation, evidence role, authority, lifecycle state, domain meaning, or narrower dependency meaning is invented;
- historical/tombstoned/superseded records remain historical/tombstoned/superseded;
- no candidate is admitted and no canonical identity is allocated by migration.

## Transform

For a valid normalized PEMS/1 document `V1`:

### 1. Root

Copy `project_id`, records, and relations. Set:

```text
semantic = "pems/2"
```

### 2. Records

For each v1 record, preserve:

```text
id
kind
lifecycle
data
supersedes
superseded_by
effective_at
recorded_at
```

when present.

Convert provenance structurally:

```text
v1 observation_refs = []          -> omit provenance
v1 observation_refs = [a, b, ...] -> provenance.untyped = sorted(unique([a, b, ...]))
```

Remove `observation_refs` from the v2 record.

Migration must not populate `primary`, `corroborating`, or `context`. The v1 list did not encode those distinctions.

No v1 record is automatically converted to the new `proposition` kind. In particular, requirements, expectations, validations, decisions, unresolved items, adjustments, chats, and modules keep their domain kinds and IDs.

### 3. Relations

For each v1 relation, preserve:

```text
id
kind
from
to
lifecycle
supersedes
superseded_by
effective_at
recorded_at
```

when present.

Convert relation provenance exactly as for records and remove `observation_refs`.

For relation `data`:

- if `kind != "depends_on"`, preserve v1 `data` exactly;
- if `kind == "depends_on"`, preserve any v1 `qualifier` and add:
  `dependency_kind = "legacy_untyped"`.

A migrator must not inspect endpoint kinds, qualifier prose, relation IDs, or source text to guess `conditional_validity` or `structural`.

### 4. Contradiction/support/proposition creation

Migration creates **none** of the new PEMS/2 proposition kinds or reasoning relation kinds. They did not exist in PEMS/1 and therefore cannot be reconstructed without new semantic evidence.

### 5. Normalization

After transformation:

- sort records lexically by `id`;
- sort relations lexically by `id`;
- sort all ID/reference arrays lexically and reject duplicates;
- omit empty provenance envelopes/roles;
- validate every reference and semantic invariant.

The same normalized v1 input must always yield byte-identical normalized v2 JSON under the same canonical JSON serialization.

## Identity preservation

PEMS/1 -> PEMS/2 is schema evolution, not semantic replacement. Existing IDs are reused because the semantic objects remain the same.

The migrator must reject any rule or implementation that:

- changes an existing ID solely because its envelope changed from `observation_refs` to `provenance`;
- replaces a v1 domain record with a generic proposition;
- narrows a v1 `depends_on` relation from unknown semantics into `conditional_validity` or `structural`;
- changes lifecycle or state to make a record RGP-exportable;
- rewrites history to current state.

## RGP export after migration

Migration and RGP export are separate operations.

A migrated decision is directly exportable as a current RGP/1 `decision` only if:

```text
record.kind == "decision"
record.lifecycle == "current"
record.data.decision_state == "accepted"
```

A migrated unresolved item is directly exportable as a current RGP/1 `uncertainty` only if:

```text
record.kind == "unresolved_item"
record.lifecycle == "current"
record.data.resolution_state in {"open", "blocked", "deferred"}
```

Migration must not alter records to satisfy these predicates. Proposed, rejected, superseded, historical, tombstoned, resolved, or otherwise non-current domain records remain faithfully represented but are not flattened into current RGP propositions.

## Provenance reclassification after migration

`provenance.untyped` is a preservation state, not a quality defect that migration may guess away.

A later governed reconciliation may move a source-observation reference from `untyped` to `primary`, `corroborating`, or `context` when the role is established. The transaction must:

- use the same immutable source-observation ID;
- remove the ID from `untyped` and add it to exactly one typed role atomically;
- preserve all unrelated provenance;
- be separately reviewable as semantic provenance classification.

## Downgrade contract

A deterministic PEMS/2 -> PEMS/1 downgrade may be offered only for a v2 graph in the lossless v1 subset.

At minimum downgrade must fail when any of these are present:

- a `proposition` record;
- `supports` or `contradicts`;
- `depends_on` with `dependency_kind != "legacy_untyped"`;
- typed provenance (`primary`, `corroborating`, or `context`);
- any future v2-only record/relation/data semantics.

For a lossless subset graph, `provenance.untyped` is reconstructed as v1 `observation_refs` and `dependency_kind: legacy_untyped` is removed from v1 `depends_on` data.

Failure must be explicit and machine-readable; lossy field dropping is forbidden.

## Determinism fixture requirements

Conformance must prove:

1. repeated migration of the same normalized v1 input is structurally and byte identical;
2. record/relation ID sets are exactly preserved;
3. all v1 observation refs become only `provenance.untyped`;
4. no typed provenance appears;
5. all v1 dependencies become only `legacy_untyped`;
6. domain lifecycle/state remains unchanged;
7. migration creates no generic propositions, supports, or contradictions;
8. downgrade of the lossless subset round-trips to normalized v1;
9. downgrade with any v2-only meaning fails closed.
