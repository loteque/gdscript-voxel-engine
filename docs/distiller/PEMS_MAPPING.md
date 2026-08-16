# Distiller to PEMS Mapping and Reconciliation Contract

## Purpose

This contract defines how validated reasoning-distiller candidates may be reconciled with and projected into canonical `pems/1` memory.

The distiller and PEMS are different ontologies:

- the distiller represents generic atomic propositions and reasoning relationships;
- PEMS represents closed project-engineering memory entities, lifecycle, provenance observations, and domain relationships.

Therefore mapping is deliberately **partial**. A candidate that has no lossless `pems/1` representation remains provisional rather than being coerced into a nearby PEMS kind.

This contract does not revise `pems/1` and does not change COVE encoding.

## Governing Principle

```text
semantic preservation > admission rate
```

A mapping is valid only when the resulting PEMS graph preserves the candidate's durable meaning, provenance, derivation requirements, authority boundary, and relevant lifecycle semantics.

Similarity of labels is not sufficient.

## Mapping Outcomes

Every validated candidate record or relation receives one mapping outcome before admission:

- `mapped_existing`: reconciles to an already admitted PEMS identity;
- `mapped_new`: can be represented losslessly as a new PEMS record/relation;
- `provisional_no_mapping`: valid distiller meaning has no lossless `pems/1` representation;
- `review_required`: a possible PEMS representation exists but semantic or authority judgment is required;
- `rejected`: mapping would violate the distiller contract, PEMS contract, or admission policy.

Mapping outcome and admission outcome are separate. `mapped_new` does not imply `admitted`.

## Record Mapping

Distiller `kind` does not mechanically become PEMS `kind`. The two fields classify different ontologies.

### `decision`

A distiller `decision` may map to PEMS `decision` when it is actually a project decision and its state can be established without invention.

```text
distiller.statement -> pems.decision.data.summary
```

`decision_state` must come from explicit evidence/admission context. The mapper must not infer `accepted` merely because the distiller classified the proposition as a decision.

If the candidate represents an architecture or roadmap adjustment and the corresponding PEMS kind is more precise, mapping may target `architecture_adjustment` or `roadmap_adjustment` after review.

### `uncertainty`

A distiller `uncertainty` may map to PEMS `unresolved_item` when it denotes a consequential unresolved project item.

An unresolved candidate establishes `resolution_state: open` unless supplied evidence specifically establishes `blocked` or `deferred`. Resolution into `resolved` requires later evidence and lifecycle reconciliation.

Uncertainty must not be converted into a decision or ordinary claim merely to obtain a PEMS representation.

### `observation`

There is no generic proposition-level `observation` record in `pems/1`.

An observation may map to a domain PEMS record only when the proposition itself is naturally one of the closed PEMS entities, for example a `validation`, `branch`, `pull_request`, or module-state record whose required PEMS fields are supplied by evidence.

A generic empirical proposition does **not** map to `source_observation`. PEMS `source_observation` represents immutable evidence capture about a source, not the proposition asserted from that evidence.

Generic observations without a domain PEMS representation remain `provisional_no_mapping`.

### `claim`

There is no generic `claim` record in `pems/1`.

A claim may map only when its semantics independently satisfy a closed PEMS domain kind such as `requirement`, `expectation`, `architecture_adjustment`, or `roadmap_adjustment`, and the required authority/state fields can be established.

Logical, evidentiary-scope, or interpretive claims with no closed PEMS domain representation remain `provisional_no_mapping`.

### `assumption`

There is no lossless generic assumption record in `pems/1`.

A consequential assumption therefore remains `provisional_no_mapping` under this contract. The mapper must not turn an assumption into an unresolved item, decision, expectation, or requirement merely to admit it.

This is an explicit PEMS v1 coverage gap, not a distiller defect.

## Provenance Mapping

Distiller provenance references opaque external `source-id` values. PEMS claims use `observation_refs` that point to immutable `source_observation` records.

For every mapped provenance source:

1. resolve the external source ID through the source registry;
2. reconcile or create the stable PEMS `source` identity;
3. reconcile or create the applicable immutable/unversioned/owner-attested PEMS `source_observation`;
4. add that `source_observation` ID to the mapped PEMS record/relation `observation_refs`.

Never point PEMS `observation_refs` directly at `source`.

### Provenance role preservation

PEMS v1 `observation_refs` are untyped, while the distiller distinguishes:

- `primary`
- `corroborating`
- `context`

A mapping that only copies IDs into `observation_refs` loses information.

Until a canonical PEMS convention for typed provenance roles is approved, the mapper must preserve the original distiller candidate graph in admission diagnostics and treat typed-role loss as a mapping limitation. It must not silently claim a lossless round trip.

This does not prevent a mapped PEMS record from being admitted when admission policy considers the untyped PEMS provenance sufficient, but the mapping result must record that the distiller-specific role detail is not represented in `pems/1`.

## Premise Mapping

A distiller premise is constitutive derivation:

```text
candidate B premise [A]
```

maps to a PEMS relation:

```text
kind: derived_from
from: canonical(B)
to: canonical(A)
```

Every premise must resolve to an admitted canonical identity in the resulting transaction.

Premise relationships must not be flattened into rationale prose or provenance.

If any required premise has no canonical mapping, the derived candidate remains provisional unless an already admitted semantically equivalent premise can be substituted through reconciliation.

## General Relation Mapping

### `depends_on`

Maps directly to PEMS `depends_on` when both endpoints resolve canonically and the conditional-validity semantics are preserved.

### `supersedes`

May map to PEMS `supersedes` only after supersession is established by admission review or explicit policy.

When supersession changes canonical lifecycle, reconciliation must also update the applicable PEMS lifecycle/supersession fields consistently and preserve the superseded record historically.

Recency alone never establishes supersession.

### `supports`

PEMS v1 has no equivalent non-derivational proposition-to-proposition support relation.

`supports` must not be mapped to `derived_from`, because that would strengthen the logical claim. It must not be turned into provenance, because both endpoints are propositions.

The relation remains `provisional_no_mapping` unless a later PEMS extension defines support semantics.

### `contradicts`

PEMS v1 has no contradiction relation.

A contradiction must not be rewritten as `supersedes`; conflicting propositions can coexist without either replacing the other.

The conflict remains explicit in the provisional distiller graph and requires review. Canonical contradiction representation requires a PEMS extension or separately approved mapping convention.

## Reconciliation

Mapping always reconciles against current canonical PEMS before allocating new identity.

### Equivalent identity

A candidate maps to an existing canonical record only when the Steward/admission layer establishes semantic identity, not merely similar wording.

Relevant checks include:

- same project entity or proposition meaning;
- compatible domain kind;
- compatible lifecycle/state;
- compatible authority/source chain;
- no contradictory identity-defining fields;
- provenance that refers to the same evidence or valid additional evidence.

Equivalent candidates reuse the existing PEMS ID.

### Material overlap

If a candidate partially overlaps an existing record but changes scope, state, authority, or meaning, do not merge automatically.

Outcome: `review_required`.

### Conflict

If a candidate conflicts with existing canonical meaning and no established supersession exists, preserve both meanings outside any destructive merge.

If PEMS v1 cannot represent the conflict edge losslessly, the new candidate or relation remains provisional pending review/extension.

### Additional provenance

Additional evidence may enrich an existing PEMS record only when it supports the same semantic identity. Evidence must not be used to smuggle a meaning change into an existing ID.

## Temporary to Canonical Identity

Admission constructs a transaction-local mapping:

```text
temp_id -> canonical PEMS id
```

The map is complete for every admitted candidate record before premise/general-relation rewriting begins.

`temp_id` is never serialized as canonical identity.

## Transaction Order

A reconciliation/admission transaction proceeds in this order:

1. validate the distiller graph;
2. resolve external provenance sources;
3. reconcile/create PEMS `source` and `source_observation` identities;
4. classify candidate-to-PEMS record mapping outcomes;
5. reconcile equivalent canonical record identities;
6. allocate new PEMS identities only for approved lossless mappings;
7. construct the complete `temp_id -> PEMS id` map;
8. map premises to `derived_from` relations;
9. map supported general relations;
10. apply approved lifecycle/supersession changes;
11. run full PEMS structural and semantic validation;
12. regenerate canonical COVE and compatibility artifacts through existing Steward rules;
13. commit atomically or commit nothing.

## PEMS v1 Coverage Gaps Exposed by the Distiller

The current distiller can express durable reasoning that `pems/1` cannot losslessly represent:

- generic assumptions;
- generic observations as propositions;
- generic logical/evidentiary claims;
- proposition-to-proposition `supports`;
- proposition-to-proposition `contradicts`;
- typed provenance roles (`primary`, `corroborating`, `context`).

These gaps must not be hidden by lossy coercion.

They provide concrete evidence for a future PEMS revision or an approved reasoning-profile extension if shadow operation demonstrates that canonical retention of these structures is valuable.

## Initial Automation Boundary

Deterministic mapping may automatically identify obvious structural correspondences, but initial canonical admission remains conservative.

Automatically mapable structure includes:

- premise -> `derived_from` after endpoint identity is known;
- `depends_on` -> PEMS `depends_on` after endpoint identity is known;
- source ID -> reconciled `source`/`source_observation` chain when resolver identity is deterministic.

Review remains required for:

- new decisions;
- requirements/expectations;
- architecture/roadmap adjustments;
- supersession;
- semantic equivalence that is not identity-locator based;
- any candidate affected by a PEMS coverage gap.

## Success Criterion

The mapping succeeds when the admission layer can answer, for every validated distiller node and edge:

```text
Where does this meaning live in PEMS?
```

with one of:

- an exact canonical identity;
- a lossless new PEMS representation;
- an explicit reason it must remain provisional.

"Closest available PEMS type" is not an acceptable answer.