# Deterministic PEMS/1 -> PEMS/2 Migration Draft

Status: **normative successor draft; no canonical migration authorized**.

## Preconditions

The migrator accepts only a structurally and semantically valid `pems/1` document. The exact input bytes or immutable source identity must be known before migration. The migrator must not repair malformed v1 input implicitly.

## Deterministic transform

Given input document `V1`, produce `V2` as follows.

1. Set top-level `semantic` from `pems/1` to `pems/2`.
2. Preserve `project_id` exactly.
3. Preserve every record `id`, `kind`, `lifecycle`, `data`, `supersedes`, `superseded_by`, `effective_at`, and `recorded_at` exactly when present.
4. Replace each record's v1 `observation_refs`:
   - if non-empty, set `provenance.untyped` to the same IDs in deterministic sorted order;
   - if empty, omit `provenance`;
   - remove `observation_refs`.
5. Preserve every relation `id`, `kind`, `from`, `to`, `lifecycle`, `supersedes`, `superseded_by`, `effective_at`, and `recorded_at` exactly when present.
6. Replace each relation's v1 `observation_refs` using the same `provenance.untyped` rule and remove `observation_refs`.
7. Preserve relation `data.qualifier` exactly when present.
8. For every v1 relation whose `kind == "depends_on"`:
   - set `data.dependency_kind = "legacy_untyped"`;
   - set `data.migration_origin = "pems/1"`;
   - never infer `conditional_validity` or `structural`.
9. Do not create generic `proposition` records during deterministic migration.
10. Do not create `supports` or `contradicts` relations during deterministic migration.
11. Do not assign typed provenance roles during deterministic migration.
12. Sort `records` by stable `id` and `relations` by stable `id` for normalized successor output. Sorting is representational only and does not alter identity or meaning.

## Identity invariant

For every v1 record or relation semantic object `x`, the successor representation retains `x.id`.

The migration must fail if two v1 objects share an ID, if an ID changes, or if a reference that resolved in v1 would become dangling in v2.

Schema shape is not identity. Moving `observation_refs` into `provenance.untyped` is representation evolution of the same semantic object.

## Provenance invariant

Migration carries the same source-observation references forward without assigning a role that v1 did not encode.

The mapping is exactly:

```text
v1 observation_refs = [a, b, ...]
        ->
v2 provenance.untyped = sorted_unique([a, b, ...])
```

If v1 contains duplicate observation refs, the v1 input is semantically invalid and migration must fail rather than silently normalize evidence.

## Dependency invariant

Every v1 `depends_on` maps to `legacy_untyped`.

This rule is intentionally conservative. A later governed reconciliation may replace the migrated relation with a semantically narrower relation or reclassify its dependency envelope, but the deterministic migration itself cannot infer meaning from endpoint kinds, prose, qualifiers, or current repository state.

## Supersession and lifecycle

Migration preserves all historical lifecycle and supersession fields exactly. It does not decide which record should now be current and does not collapse historical records.

A v1 decision that is `proposed`, `rejected`, `superseded`, or historical remains exactly that after migration. Migration does not make it RGP-exportable.

## Source observations

`source_observation` records preserve immutable evidence locators and fingerprints exactly. The migrator never updates a source observation to point at newer source content.

If newer source content is needed, that is a separate observation/reconciliation operation after migration.

## Deterministic failure conditions

Migration fails closed when:

- input semantic is not exactly `pems/1`;
- v1 schema/semantic validation fails;
- IDs collide;
- a record/relation ID would change;
- references are dangling;
- provenance references do not resolve to source observations;
- v1 duplicate observation refs would require silent normalization;
- output does not validate as PEMS/2;
- a second migration of the same normalized v1 input produces different normalized v2 output.

## Downgrade rule

A general PEMS/2 -> PEMS/1 downgrade is **not** defined.

A restricted compatibility downgrade may be implemented only for a v2 document containing no v2-only semantics. It must fail if any of the following are present:

- `proposition` records;
- `supports` or `contradicts` relations;
- typed provenance (`primary`, `corroborating`, or `context`);
- `depends_on` with `conditional_validity` or `structural`;
- any other future v2-only meaning.

For an otherwise v1-equivalent v2 document, `provenance.untyped` may map back to `observation_refs` and migration-only `legacy_untyped` metadata may be removed. Such a downgrade is a compatibility utility, not canonical authority.

## Conformance proof

`fixtures/rgp-compatibility.json` contains a miniature v1 document and exact expected v2 output. `validate_pems2_contract.py` verifies exact structural equality after migration and verifies that all stable IDs survive unchanged.
