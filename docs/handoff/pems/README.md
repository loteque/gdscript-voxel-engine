# PEMS v1 Normative Semantic Contract

Status: **Phase 1 frozen implementation contract**

Semantic identifier: `pems/1`

This directory defines the normalized expanded Project Engineering Memory Schema (PEMS) v1 contract approved by the project owner. It is intentionally independent of COVE and deterministic byte serialization. COVE may later encode a normalized PEMS value, but it does not define PEMS meaning.

## Artifacts

- `pems-v1.schema.json` — machine-readable JSON Schema 2020-12 structural contract.
- `fixtures/success/full-project.json` — normative success fixture exercising the full admitted v1 record vocabulary.
- `fixtures/failure-cases.json` — deterministic semantic/schema/admission/retention failure cases, expressed as JSON Patch-style mutations against the success fixture or as explicit Steward-admission scenarios.

## Closed v1 record vocabulary

Every record kind admitted into `pems/1` has a closed `data` schema in `pems-v1.schema.json`:

- `project`
- `chat`
- `role`
- `expectation`
- `requirement`
- `decision`
- `unresolved_item`
- `external_file`
- `module`
- `environment_variable`
- `database_table`
- `database_column`
- `branch`
- `pull_request`
- `validation`
- `architecture_adjustment`
- `roadmap_adjustment`
- `continuation`
- `source`
- `source_observation`

No recognized v1 kind may use arbitrary extra members in `data`. Adding a new record kind requires a PEMS schema revision or a separately approved extension mechanism.

## Common record contract

All records contain:

- `id`: stable Steward-admitted semantic ID;
- `kind`: one closed v1 kind;
- `lifecycle`: `current`, `historical`, `superseded`, or `tombstoned`;
- `observation_refs`: zero or more IDs of `source_observation` records;
- `data`: kind-specific closed data object.

Optional common fields are `supersedes`, `superseded_by`, `effective_at`, and `recorded_at`.

All relations contain a stable Steward-admitted `id`, a closed relation `kind`, `from` and `to` record IDs, lifecycle, observation provenance, and a closed relation `data` object.

## Structural validation versus semantic validation

JSON Schema validates field presence, types, enums, closed objects, nullable fields, numeric interoperability bounds, and secret-disposition shape. It deliberately does **not** pretend to perform graph reconciliation.

The PEMS validator/normalizer must additionally enforce:

1. record IDs and relation IDs are globally unique within their respective collections;
2. every intrinsic record reference and relation endpoint resolves to the required record kind;
3. every `observation_refs` target resolves to a `source_observation`, never directly to `source`;
4. every `source_observation.data.source_id` resolves to `source`;
5. already admitted `source_observation` identities are immutable and cannot be reused for later evidence;
6. Steward admission resolves semantic identity, reuses existing IDs for the same object, rejects one ID for different meanings, and rejects duplicate semantic identities under parallel IDs unless an explicit migration rule exists;
7. supersession references resolve and do not silently rebind identities;
8. ordinary normalization never deletes historical, superseded, tombstoned, or observation records;
9. destructive historical compaction fails unless an explicit Steward retention policy authorizes it;
10. set-like ID arrays are deduplicated and normalized in bytewise UTF-8 lexical order; record and relation arrays are likewise normalized by `id`;
11. strings are preserved exactly with no implicit Unicode normalization;
12. candidate/import IDs remain provisional until Steward admission.

These rules are represented as named cases in `fixtures/failure-cases.json` so Phase 2 can implement them explicitly.

## Interoperable numeric domain

PEMS v1 JSON-number integers are restricted to the inclusive range `[-9007199254740991, 9007199254740991]`. This is a semantic portability rule approved in `STEWARD-20260813-006`, not a COVE transform or a JCS-library workaround.

Exact integers outside that range must not be silently rounded, clamped, truncated, or stringified. If a future record kind legitimately requires a larger exact integer, its normative schema must model that value explicitly as a string representation. In the current closed pems/1 vocabulary, the only integer-valued schema members are evidence-locator line numbers; their schema bounds therefore enforce the complete currently admitted numeric-integer surface.

This bound keeps canonical PEMS reproducible across implementations whose JSON number handling follows the interoperable IEEE-754 binary64 model used by RFC 8785 JCS.

## Source and observation provenance

A `source` identifies the stable thing being observed. Observation-specific revision data must not be placed in the source identity locator.

A `source_observation` is immutable evidence about that source. Its `evidence_state` is one of:

- `immutable_snapshot`
- `unversioned_observation`
- `owner_attestation`

Claims point through `observation_refs` to observations. An observation points through `data.source_id` to its stable source. If immutable revision evidence is unavailable, tooling creates an `unversioned_observation`; it does not point claims directly at a mutable source.

## Null, absent, and empty

PEMS preserves three distinct states:

- an absent optional member means unspecified;
- a present nullable member with `null` means explicitly no/unknown value according to that field's schema;
- an empty array means the collection is explicitly known to contain zero members.

Normalizers must not collapse these states. The success fixture contains all three forms, and the failure suite includes invalid null/empty substitutions for required non-null fields.

## Secret-safe environment variables

`environment_variable.data.value_state` is one of `literal`, `redacted`, `external_secret`, `unset`, or `unknown`.

- `literal` requires a non-null `value` and forbids `external_ref`.
- `external_secret` requires a non-null safe `external_ref` and requires `value` to be absent or `null`.
- `redacted`, `unset`, and `unknown` require `value` to be absent or `null`.

A schema cannot recognize every credential-looking string. Phase 2 semantic validation may add conservative secret-leak checks, but PEMS is not a secret store.

## Deterministic normalization

The normalized semantic document keeps JSON object property ordering non-semantic. Arrays with set semantics are sorted and deduplicated by bytewise UTF-8 lexical ordering of IDs. Ordered domain sequences retain their defined order. Record and relation collections are sorted by their canonical IDs.

This is semantic normalization only. Exact JSON byte serialization belongs to the independent `jcs/1` serializer contract and is not defined by PEMS.

## Fixture protocol

`fixtures/success/full-project.json` is expected to pass structural and semantic validation after Steward admission.

`fixtures/failure-cases.json` declares each negative test with:

- stable case `id`;
- `mode` (`document_patch`, `admission`, or `retention`);
- base success fixture where applicable;
- deterministic mutation/context;
- expected validation `stage` and machine-readable error `code`.

`document_patch` operations use RFC 6902 operation semantics. Phase 2's fixture runner may implement only the operations present in this suite, but their meaning must match RFC 6902.

Admission fixtures explicitly separate candidate identity handling from JSON Schema validation. A syntactically valid candidate can still fail Steward admission.

## Historical preservation

Historical preservation is the pems/1 default. Neither schema validation nor ordinary normalization is garbage collection. Any later destructive compaction requires an explicit Steward retention policy, policy identifier, provenance for the compaction decision, reference migration rules, and its own validation fixtures.

## Canonicality during implementation

These schemas and fixtures define the frozen pems/1 implementation contract, but they do not make a PEMS or COVE artifact the project's canonical continuity memory. `docs/project-chat-handoff.json` remains canonical until a later explicit owner/Steward migration decision after shadow validation.
