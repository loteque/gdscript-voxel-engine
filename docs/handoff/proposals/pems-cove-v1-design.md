# PEMS v1 and COVE v1 Design Proposal

## Status

**Architect proposal amended after project-owner and Steward review. Not yet canonical.**

This document specifies a proposed v1 semantic model and compact encoding contract for durable project engineering memory. It does **not** authorize conversion of `docs/project-chat-handoff.json`, implementation of the autonomous agent runtime, or replacement of existing continuity artifacts.

Owner-approved amendments incorporated in this revision:

1. canonical PEMS semantic IDs are allocated or confirmed by the Project Engineering Steward during reconciliation;
2. stable source identity is distinct from immutable source observation/evidence;
3. historical preservation is the safe v1 default unless an explicit Steward retention policy authorizes compaction;
4. JCS remains preferred subject to conformance evidence;
5. one canonical compact document remains the v1 recommendation;
6. no fixed 20% compression threshold is owner-approved before representative measurements exist.

Working identifiers:

- semantic model: `pems/1`
- compact codec: `cove/1`
- deterministic serializer: `jcs/1` if RFC 8785 compatibility is confirmed by fixtures and implementation tests

The design deliberately separates three contracts:

```text
project knowledge
      ↓
PEMS semantic normalization
      ↓
normalized expanded PEMS JSON value
      ↓
COVE structural encoding
      ↓
canonical COVE JSON value
      ↓
JCS deterministic JSON serialization
      ↓
canonical UTF-8 bytes
```

PEMS answers **what project memory means**. COVE answers **how an arbitrary normalized structured value is represented compactly and reversibly**. The serializer answers **which exact UTF-8 bytes represent that COVE value**.

---

## 1. Design Goals

### Normative v1 requirements

PEMS v1 MUST:

1. preserve project continuity semantics without depending on one conversation transcript;
2. distinguish current state, historical state, proposals, accepted decisions, superseded decisions, unresolved work, implementation state, validation state, and source authority structurally rather than through prose conventions alone;
3. provide stable semantic identifiers independent of array position and mutable display names;
4. make canonical semantic-ID admission a Steward reconciliation responsibility;
5. distinguish stable source identity from concrete source observations;
6. make provenance references point to observations rather than ambiguously to mutable source identities;
7. represent project-level context and chat/workstream continuity needed to reconstruct a role-faithful receiving session;
8. preserve absent, explicit `null`, and empty collection as distinct JSON states;
9. validate all semantic references and reject duplicate IDs;
10. exclude transient agent-runtime mechanics from the semantic model;
11. support deterministic lossless expansion into human-readable/searchable JSON;
12. preserve the project authority hierarchy rather than becoming a competing authority for current Git/ADR/roadmap/test truth;
13. preserve historical/superseded semantic records by default unless an explicit Steward retention policy authorizes compaction.

COVE v1 MUST:

1. remain domain-agnostic;
2. encode any supported normalized JSON value reversibly;
3. produce one deterministic COVE structured value for one normalized input value;
4. use actual JSON as its structured representation;
5. compact repeated structure without relying on opaque compression as the canonical representation;
6. reject malformed dictionaries, shapes, indexes, records, and unsupported versions;
7. decode without PEMS-specific logic;
8. be independently versioned from PEMS.

The serializer MUST be independently identified and versioned when byte-for-byte canonicality is required.

### Recommendations

- Adopt RFC 8785 JSON Canonicalization Scheme (JCS) as `jcs/1` for COVE byte serialization, subject to conformance evidence.
- Keep one canonical COVE project-memory artifact in v1 rather than sharding immediately.
- Keep a generated, pretty-printed expanded PEMS derivative during migration and for human debugging/onboarding.
- Measure compression on representative fixtures before setting a numeric canonical-adoption threshold. A 20% aggregate reduction remains a useful experimental target, not an owner-approved invariant.

---

## 2. Explicit Non-Goals

PEMS v1 is not:

- a replacement for Git repository truth;
- an ADR system;
- a roadmap authority;
- an execution queue, lease table, retry ledger, budget meter, or workflow engine;
- a raw transcript archive;
- a secrets manager;
- an attempt to preserve every accidental field in the current handoff JSON.

COVE v1 is not:

- a PEMS-aware compression algorithm;
- a semantic reconciliation engine;
- a content-addressed object database;
- a binary transport;
- a cryptographic signature system;
- a general-purpose schema language.

The autonomous agent runtime is a separate architecture. Runtime receipts may later project stable outcomes into PEMS when those outcomes are genuine project knowledge, but runtime state itself does not belong in PEMS.

---

## 3. Authority and Provenance Model

### 3.1 Authority remains external

PEMS records durable continuity *about* authoritative sources. It does not silently outrank them.

For this project, current authority remains conceptually:

1. current Git/repository state for repository facts;
2. accepted ADRs/current architecture documentation for accepted architecture;
3. `ROADMAP.md` for current roadmap intent;
4. tests and validation scenes for executable/validated behavior;
5. explicit project-owner instructions for owner intent and policy;
6. PEMS continuity memory for reconstructed context and cross-source synthesis.

The exact order varies by claim type. For example, an owner instruction can intentionally supersede a prior roadmap direction before `ROADMAP.md` is updated. PEMS stores authority categories and provenance evidence; reconciliation logic belongs to the Steward.

### 3.2 Stable source identity

A `source` record identifies the durable thing from which evidence can be observed. It does not represent a particular observation of that thing.

Example:

```json
{
  "id": "source:adr-offline-runtime-boundary",
  "kind": "source",
  "lifecycle": "current",
  "observation_refs": [],
  "data": {
    "source_kind": "git_file",
    "authority": "accepted_architecture",
    "identity_locator": {
      "repository": "loteque/gdscript-voxel-engine",
      "path": "docs/architecture/decisions/ADR-001-offline-runtime-terrain-boundary.md"
    }
  }
}
```

`identity_locator` contains fields needed to identify the source across observations. It MUST NOT contain observation-specific revision data such as a commit SHA when the source identity itself persists across commits.

Proposed v1 `authority` categories:

- `repository_state`
- `accepted_architecture`
- `roadmap_intent`
- `executable_validation`
- `owner_instruction`
- `chat_history`
- `external_file`
- `generated_derivative`
- `other`

### 3.3 Source observations

A `source_observation` record is immutable evidence that a source had a particular observed representation or state.

Example:

```json
{
  "id": "observation:adr-offline-runtime-boundary:abc123",
  "kind": "source_observation",
  "lifecycle": "historical",
  "observation_refs": [],
  "data": {
    "source_id": "source:adr-offline-runtime-boundary",
    "evidence_state": "immutable_snapshot",
    "observed_at": "2026-08-13T15:40:00-07:00",
    "evidence_locator": {
      "repository": "loteque/gdscript-voxel-engine",
      "commit": "abc123",
      "path": "docs/architecture/decisions/ADR-001-offline-runtime-terrain-boundary.md",
      "line_start": null,
      "line_end": null
    }
  }
}
```

Once admitted to canonical PEMS, a `source_observation` MUST NOT be mutated to describe a later observation. A later observation is a new record with a new Steward-admitted ID.

Proposed v1 `evidence_state` values:

- `immutable_snapshot` — the locator identifies immutable or content-addressed evidence such as a commit, immutable release, immutable note entry, or equivalent;
- `unversioned_observation` — the observation was made at a recorded time but no immutable revision was available;
- `owner_attestation` — the evidence is an explicit owner decision or instruction whose durable provenance is represented by the observation.

`unversioned_observation` is intentionally weaker evidence, not a shortcut that collapses source and observation. Its `observed_at` and captured locator MUST remain immutable after admission.

### 3.4 Provenance references

The common record and relation envelope uses `observation_refs`, not ambiguous `source_refs`.

Every durable claim whose truth depends on evidence SHOULD reference one or more `source_observation` records through `observation_refs`.

Direct provenance references from semantic claims to `source` records are **not valid in pems/1**. When an immutable revision cannot be captured, tooling MUST create an `unversioned_observation` instead. This gives every consumer one uniform rule:

```text
semantic claim
    ↓ observation_refs
source_observation
    ↓ data.source_id
source
```

A source record itself normally has `observation_refs: []` because it is an identity object rather than a claim about a particular source state. A source identity MAY have provenance only when its own existence/identity is derived from evidence that must be retained.

### 3.5 Record-level provenance

PEMS v1 uses record-level provenance. If two fields of what appears to be one semantic object have materially different provenance or lifecycle, they SHOULD be represented as separate semantic records or relations rather than inventing field-level mini-provenance.

This trades some record count for clearer authority, auditability, and simpler tooling.

---

## 4. PEMS v1 Normalized Semantic Model

### 4.1 Root document

```json
{
  "semantic": "pems/1",
  "project_id": "project:gdscript-voxel-terrain",
  "records": [],
  "relations": []
}
```

Project data is itself a record so all durable semantic objects share identity, lifecycle, provenance, and reference rules.

### 4.2 Common record envelope

Every PEMS record MUST have:

```json
{
  "id": "<stable semantic ID>",
  "kind": "<record kind>",
  "lifecycle": "current",
  "observation_refs": ["observation:..."],
  "data": {}
}
```

Optional common fields:

```json
{
  "supersedes": ["<record-id>"],
  "superseded_by": ["<record-id>"],
  "effective_at": "<RFC3339 timestamp or null>",
  "recorded_at": "<RFC3339 timestamp or null>"
}
```

#### `lifecycle`

Allowed v1 values:

- `current` — part of the current semantic view;
- `historical` — preserved history, no longer current, but not semantically superseded by a specific replacement;
- `superseded` — replaced by another identified semantic record;
- `tombstoned` — identity intentionally retained while the semantic object has been removed and must not be treated as active.

`lifecycle` does not replace type-specific state. A `decision` can be `current` with `decision_state: "proposed"`, then become `superseded` when a replacement decision is accepted.

A `source_observation` normally becomes `historical` when it no longer represents the newest known state of its source. Historical observations remain valid evidence for claims made from them.

### 4.3 Stable IDs and canonical admission

PEMS IDs MUST:

- be strings;
- be unique within one project-memory document;
- remain stable across display-name changes;
- never be derived from current array position;
- use a type-oriented prefix where practical for readability;
- reject duplicates during normalization.

Canonical PEMS semantic IDs are **allocated or confirmed by the Project Engineering Steward during reconciliation**. Other roles, tools, importers, and agents MAY propose candidate IDs, but those candidates are not canonical until admitted by the Steward.

The Steward admission boundary MUST:

1. resolve candidate identity against existing canonical semantic objects;
2. reuse an existing ID when the candidate represents the same semantic object;
3. allocate or confirm a new ID when the semantic object is genuinely new;
4. reject collisions where one ID would represent two meanings;
5. reject silent alias creation where two IDs would represent one known semantic object unless an explicit supersession/alias migration rule authorizes it.

IDs MAY be human-readable slugs. UUIDs are not required. The invariant is stable meaning, not randomness.

Externally stable identity MAY contribute to deterministic candidate IDs, for example repository-qualified pull-request numbers or immutable commit SHAs. External identity does not bypass Steward admission or collision handling.

Renaming changes display data, not identity. An existing canonical ID MUST NEVER be silently reassigned to a different semantic meaning.

If an identity was created incorrectly, the old record SHOULD be superseded or tombstoned and a replacement linked explicitly rather than reusing the old ID for new meaning.

### 4.4 Proposed record kinds

PEMS v1 SHOULD define schemas for at least:

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

This is a bounded v1 vocabulary. New record kinds require a PEMS schema revision or an explicitly approved namespaced extension mechanism.

### 4.5 Type-specific states

PEMS avoids one overloaded universal `status` enum.

#### Decision

Allowed `decision_state` values:

- `proposed`
- `accepted`
- `rejected`
- `superseded`

#### Unresolved item

Allowed `resolution_state` values:

- `open`
- `blocked`
- `resolved`
- `deferred`

#### Requirement / expectation

Recommended states:

- `active`
- `satisfied`
- `deprecated`
- `superseded`

#### Validation

Recommended `validation_state` values:

- `planned`
- `implemented`
- `passing`
- `failing`
- `not_applicable`

Validation evidence belongs in `observation_refs` and structured data, not only prose.

### 4.6 Relations

Cross-record relationships are normalized into a separate relation list when the relationship itself has durable meaning or provenance.

```json
{
  "id": "relation:architect-owns-cove-contract",
  "kind": "owns",
  "from": "role:engineering-knowledge-systems-architect",
  "to": "requirement:cove-contract",
  "lifecycle": "current",
  "observation_refs": ["observation:architect-directive:commit-abc"],
  "data": {}
}
```

Relation IDs are Steward-admitted semantic IDs and MUST be unique.

Proposed core relation kinds:

- `owns`
- `scoped_to`
- `depends_on`
- `implements`
- `validates`
- `references`
- `continues_as`
- `member_of`
- `supersedes`
- `derived_from`

Direct ID fields remain appropriate where the relationship is intrinsic to a record schema, such as `project_id`, `table_id`, or `source_id`. The normalizer SHOULD avoid representing the same semantic edge both intrinsically and as a relation unless duplication is explicitly required.

---

## 5. Required Continuity Semantics

The current human handoff is requirements input, not a shape to freeze.

### Project-level context

Represent as a `project` record plus project-scoped expectations, requirements, decisions, modules, sources, observations, and related records.

### Chats / workstreams

Each chat/workstream becomes a `chat` record with stable identity, title, date/range, summary, active-role reference, and continuation information.

### Roles

Roles are independent records so multiple chats can reference one role without duplicating role semantics. Role directives remain Git artifacts represented as stable `source` records with concrete observations.

### Owner relationship / expectations

Use explicit `expectation` records scoped to project, chat, or role through relations. Repeated expectations should be one record referenced from multiple scopes when semantically identical.

### Requirements and decisions

Use typed records with state and observation provenance. Proposed, accepted, rejected, and superseded outcomes are explicit.

### Unresolved items

Use `unresolved_item` records with structured resolution state, owner/scope relations, and provenance.

### External files

Use `external_file` records describing logical identity, title/name, safe locator if available, purpose, and provenance. File content is not embedded merely because it was used in a chat.

### Modules

Use `module` records with repository path, domain, public role, and repository-state observations.

### Environment variables

Use `environment_variable` records with secret-safe value semantics defined in Section 10.

### Database tables / columns

Use separate `database_table` and `database_column` records. Columns reference stable table IDs.

### Branches / pull requests

Use `branch` and `pull_request` records for continuity claims that matter beyond one retrieval. Current GitHub truth must be revalidated before operational decisions; observations capture what was known at reconciliation time.

### Validation responsibilities and state

Use `validation` records linked to requirements/features and to evidence observations such as test-file commits, validation-scene commits, CI runs, or published immutable release artifacts where available.

### Architecture / roadmap adjustments

Use `architecture_adjustment` and `roadmap_adjustment` only for continuity around changes or pending reconciliation. Accepted architecture and roadmap intent remain authoritative in ADRs/docs and `ROADMAP.md`.

### Continuation state

Use a `continuation` record to express the minimal state needed to resume a chat/role: active role, current focus, blockers, pending owner decisions, and pointers to high-value semantic records. It must not become a duplicate project summary.

---

## 6. Null, Absence, and Empty Semantics

These states MUST remain distinguishable through PEMS normalization and COVE round trips:

```json
{}
```

means a field is absent and unspecified.

```json
{"value": null}
```

means the field is explicitly present with no value / unknown / intentionally empty scalar according to its schema.

```json
{"items": []}
```

means the collection is explicitly present and known to contain zero members.

Schemas MUST state whether fields are required, optional, nullable, or collection-valued. Normalization MUST NOT silently replace absent values with `null` or empty arrays unless that default is part of the PEMS contract.

---

## 7. Deterministic PEMS Normalization

For one semantically equivalent PEMS input under `pems/1`, normalization MUST produce one equivalent normalized expanded JSON value.

### Normative rules

1. Duplicate record IDs and relation IDs fail normalization.
2. Every admitted semantic ID must satisfy Steward admission rules; import/candidate IDs are not canonical merely because they parse.
3. All intrinsic references and relation endpoints must resolve unless explicitly external by schema.
4. Every `observation_refs` value must resolve to a `source_observation` record.
5. Every `source_observation.data.source_id` must resolve to a `source` record.
6. A semantic record or relation MUST NOT use a `source` ID directly in `observation_refs`.
7. `source_observation` records are immutable after canonical admission except for a separately versioned corrective migration that preserves the prior erroneous identity/history.
8. Record arrays are sorted by `id` using bytewise lexicographic ordering of UTF-8 encoding.
9. Relation arrays are sorted by `id` using the same rule.
10. Set-like ID arrays such as `observation_refs`, `supersedes`, and `superseded_by` are deduplicated and sorted by the same rule.
11. Ordered domain sequences retain semantic order and MUST be marked as ordered by schema.
12. JSON object property order is not semantic; byte property order belongs to the serializer.
13. Strings are preserved exactly; PEMS v1 performs no implicit Unicode normalization.
14. Numeric fields must be finite JSON numbers compatible with the selected serializer. Stable IDs, commit SHAs, timestamps, and potentially large integer-like identifiers are strings.
15. Invalid type-specific states fail normalization.
16. A `superseded` record SHOULD identify at least one replacement through `superseded_by` unless schema explicitly permits otherwise.
17. A tombstoned record MUST retain ID and kind and SHOULD minimize data while preserving identity/provenance.
18. Normalization MUST NOT delete, coalesce, or summarize away historical, superseded, tombstoned, or observation records as a side effect of ordinary canonicalization.

### Historical preservation default

Historical retention is a Steward continuity policy, not a codec behavior.

For pems/1, the safe default is **preserve history**. Destructive compaction is allowed only when an explicit Steward retention policy authorizes it. Such a policy MUST define:

- which record kinds/states are eligible;
- minimum retention or evidence requirements;
- how provenance of the compaction decision is recorded;
- whether a deterministic historical-summary record is required;
- how references to compacted records are migrated without dangling identities;
- validation fixtures for the policy.

COVE MUST encode whatever normalized PEMS it receives and MUST NOT prune historical data itself.

### Why normalization happens before COVE

COVE must not decide that project records are duplicates, allocate IDs, infer supersession, determine source authority, select historical retention, or validate provenance semantics. Those are PEMS/Steward responsibilities.

---

## 8. COVE v1 Structural Encoding

### 8.1 Design choice

COVE v1 uses only two compaction mechanisms in its core:

1. global string interning;
2. deterministic object-shape factoring.

This remains smaller and simpler than a broad token language while staying domain-agnostic. PEMS-specific enum ordinals, record-type opcodes, or semantic reference types are not part of COVE v1.

### 8.2 COVE artifact envelope

```json
{
  "c": "cove/1",
  "p": "pems/1",
  "s": "jcs/1",
  "d": [],
  "h": [],
  "x": null
}
```

- `c` — codec identifier;
- `p` — opaque semantic/profile identifier;
- `s` — serializer identifier;
- `d` — global string dictionary;
- `h` — object-shape dictionary;
- `x` — encoded root value.

COVE does not interpret the semantic profile.

### 8.3 String dictionary `d`

The dictionary contains every distinct string appearing anywhere in normalized input, including property names and string values.

Rules:

1. strings are exact Unicode strings from parsed normalized input;
2. COVE applies no Unicode normalization;
3. distinct strings sort by bytewise UTF-8 lexicographic order;
4. dictionary index is zero-based sorted position;
5. duplicate strings are forbidden.

Interning every string may add overhead for one-off values. This is intentionally measured rather than heuristically optimized in v1.

### 8.4 Object-shape dictionary `h`

Each distinct JSON object key set becomes one shape.

A shape is an array of string-dictionary indexes sorted ascending.

Shape construction:

1. gather every distinct object key set;
2. convert keys to dictionary indexes;
3. sort indexes ascending within each shape;
4. deduplicate identical shapes;
5. sort shapes lexicographically by integer sequence, shorter-prefix first;
6. assign zero-based shape indexes.

### 8.5 Encoded values

- `null`, `true`, `false`, numbers remain raw JSON literals;
- strings encode as `[0, <dictionary-index>]`;
- arrays encode as `[1, <encoded-item-0>, ...]`;
- objects encode as `[2, <shape-index>, <value-for-key-0>, ...]`.

Normative tags:

- `0` = string reference
- `1` = array
- `2` = object

No other tag is valid in cove/1.

### 8.6 Decoder validation

A decoder MUST reject:

- unknown codec major version;
- unsupported required profile;
- malformed envelope fields;
- duplicate or non-canonically ordered dictionary strings;
- malformed, duplicate, unsorted, or non-canonically ordered shapes;
- out-of-range dictionary or shape indexes;
- unknown tags or wrong tag arity;
- object value counts not matching referenced shapes;
- non-finite numeric values;
- decoded duplicate object keys.

After COVE decoding, expanded data MUST pass its semantic profile validator.

### 8.7 Deterministic construction

The same normalized input MUST produce identical `d`, `h`, and `x` independent of internal traversal order.

---

## 9. Serializer: RFC 8785 JCS Evaluation

RFC 8785 JCS remains preferred for `jcs/1` because it already defines deterministic JSON serialization including recursive property sorting, no insignificant whitespace, deterministic primitive serialization, and UTF-8 output.

Compatible constraints include:

- unique object property names;
- valid Unicode strings preserved without Unicode normalization;
- IEEE-754-compatible numbers;
- no non-finite numbers;
- serializer-defined property ordering rather than application ordering.

No known pems/1 requirement conflicts with JCS.

### Recommendation

Adopt JCS as the normative byte serializer for the first implementation **only after conformance evidence**, using at least RFC test vectors and preferably cross-implementation comparison.

COVE remains responsible for structural determinism, not JSON textual rendering.

---

## 10. Security and Secret Handling

PEMS is continuity memory, not a credential vault.

Environment variables model value disposition explicitly:

```json
{
  "id": "env:example-token",
  "kind": "environment_variable",
  "lifecycle": "current",
  "observation_refs": [],
  "data": {
    "name": "EXAMPLE_TOKEN",
    "value_state": "external_secret",
    "value": null,
    "external_ref": "secret-store:example-token",
    "purpose": "Authenticates the external service."
  }
}
```

Proposed `value_state` values:

- `literal`
- `redacted`
- `external_secret`
- `unset`
- `unknown`

Rules:

- `literal` MAY contain only a non-secret value intentionally suitable for durable repository storage;
- `redacted` MUST NOT contain the secret value;
- `external_secret` MUST NOT contain the secret value and may contain only a safe external locator;
- `unset` means intentionally unconfigured;
- `unknown` means the variable is known but current value/disposition is not.

Normalizers SHOULD reject obvious credential fields in record types that do not permit secret-bearing data, while recognizing that schema validation cannot detect every secret.

---

## 11. Versioning and Compatibility

PEMS, COVE, and serializer are independently versioned.

V1 identifiers:

```text
pems/1
cove/1
jcs/1
```

### Unknown versions

- unknown PEMS major/profile: fail closed before semantic use;
- unknown COVE major: fail closed before decoding;
- unknown serializer identifier: canonical-byte verification fails, though structural JSON inspection may still occur without claiming canonical-byte conformance.

### Migration

Preferred boundary:

```text
old semantic artifact
   ↓ decode old codec/profile
old normalized expanded PEMS
   ↓ semantic migration
new normalized expanded PEMS
   ↓ encode current COVE
new compact artifact
```

Semantic migrations belong to PEMS versions. COVE migrations are purely representational.

The current handoff importer MUST create separate `source` and `source_observation` records where historical input previously combined stable locator and observation/revision metadata. Candidate semantic IDs generated by import tooling remain provisional until Steward admission.

Every supported migration path requires fixtures.

---

## 12. Artifact Boundaries and Retrieval

### Recommendation: one canonical COVE document in v1

Use one project-memory COVE artifact initially.

Benefits:

- atomic project-memory replacement;
- one semantic consistency boundary;
- simple versioning and validation;
- no cross-shard dangling-reference protocol;
- easy full-memory hashing and reproducibility.

Costs:

- a small semantic change can rewrite many dictionary/shape indexes;
- corruption affects the whole artifact;
- selective retrieval generally requires parsing the envelope/root sufficiently to locate records;
- concurrent writers conflict at file level.

The single-writer Steward makes write concurrency an insufficient reason to shard in v1.

### Partial decoding

COVE v1 does not promise O(1) record extraction. If retrieval becomes material, evaluate in order:

1. deterministic derived semantic index;
2. cached decoded PEMS;
3. canonical sharding only if the first two are insufficient.

---

## 13. Human-Readable and Searchable Derivatives

### Lossless normalized expansion

```text
COVE artifact
   ↓ decode
normalized expanded PEMS JSON
```

This expansion MUST be lossless and deterministic.

### Presentation/documentation transformation

```text
normalized expanded PEMS
   ↓ exporters
pretty JSON / Markdown / onboarding docs / search index
```

Presentation exporters MAY group records, resolve labels, add navigation indexes, derive deterministic summaries/tables, and expose source/evidence links.

Presentation output MUST preserve semantic IDs and provenance paths through observations to stable sources.

### Migration recommendation for `docs/project-chat-handoff.json`

During migration, keep `docs/project-chat-handoff.json` as the canonical Steward artifact while COVE is generated in shadow mode.

After validator/encoder/decoder conformance and explicit Steward/owner adoption, recommended paths are:

- canonical compact memory: `docs/project-chat-handoff.cove.json`
- generated compatibility/human derivative: `docs/project-chat-handoff.json`

The existing path may cease being canonical only through an explicit migration decision.

---

## 14. Near-Normative PEMS Fixture Requirements

Implementation fixtures MUST include at least:

- one project;
- two chats/workstreams;
- two roles;
- repeated strings sufficient to exercise COVE compaction;
- semantic references between records;
- one non-secret environment variable or secret-safe disposition record;
- one database table and one separately identified column;
- one proposed decision that later becomes accepted/superseded;
- one unresolved item;
- one stable `source` with at least two `source_observation` records showing different observed revisions;
- at least one claim whose `observation_refs` points to an immutable snapshot observation;
- at least one `unversioned_observation` fixture showing weaker but structurally explicit evidence;
- null/absent/empty distinctions;
- at least one malformed provenance reference;
- at least one candidate-ID collision rejected at Steward admission/normalization.

Illustrative provenance fragment:

```json
{
  "records": [
    {
      "id": "source:roadmap",
      "kind": "source",
      "lifecycle": "current",
      "observation_refs": [],
      "data": {
        "source_kind": "git_file",
        "authority": "roadmap_intent",
        "identity_locator": {
          "repository": "loteque/gdscript-voxel-engine",
          "path": "ROADMAP.md"
        }
      }
    },
    {
      "id": "observation:roadmap:abc123",
      "kind": "source_observation",
      "lifecycle": "historical",
      "observation_refs": [],
      "data": {
        "source_id": "source:roadmap",
        "evidence_state": "immutable_snapshot",
        "observed_at": "2026-08-13T15:00:00-07:00",
        "evidence_locator": {
          "commit": "abc123",
          "path": "ROADMAP.md"
        }
      }
    },
    {
      "id": "requirement:streaming-preview",
      "kind": "requirement",
      "lifecycle": "current",
      "observation_refs": ["observation:roadmap:abc123"],
      "data": {
        "requirement_state": "active",
        "summary": "Runtime streaming validation is exposed in Integration Preview."
      }
    }
  ]
}
```

A separate fixture MUST distinguish:

```json
{"data": {}}
```

```json
{"data": {"summary": null}}
```

```json
{"data": {"tags": []}}
```

No normalizer or codec may collapse them.

---

## 15. Illustrative COVE Encoding

For generic input:

```json
{
  "kind": "role",
  "name": "Architect"
}
```

one valid cove/1 construction is conceptually:

```json
{
  "c": "cove/1",
  "p": "example/1",
  "s": "jcs/1",
  "d": ["Architect", "kind", "name", "role"],
  "h": [[1, 2]],
  "x": [2, 0, [0, 3], [0, 0]]
}
```

Exact dictionary ordering is determined by the UTF-8 byte comparison rules, not by illustrative prose order.

---

## 16. Required Failure Fixtures

### PEMS failures

- duplicate record ID;
- duplicate relation ID;
- candidate canonical-ID collision representing different semantic meanings;
- known duplicate semantic identity proposed under a second ID without an authorized migration/alias rule;
- dangling relation endpoint;
- dangling `observation_refs` entry;
- `observation_refs` pointing directly to a `source` record;
- `source_observation.data.source_id` pointing to a non-source or missing record;
- mutation of an already admitted source observation into a later revision;
- invalid `evidence_state`;
- invalid type-specific state;
- invalid supersession reference;
- unauthorized destructive historical compaction;
- environment variable marked `external_secret` while containing a literal secret value;
- unknown `pems/<major>` profile.

### COVE failures

- unknown `cove/<major>`;
- duplicate dictionary string;
- unsorted dictionary;
- out-of-range string index;
- out-of-range shape index;
- duplicate/unsorted shape key index;
- non-canonical shape order;
- unknown tag;
- wrong object arity;
- malformed tagged array.

At least one malformed provenance fixture SHOULD decode successfully at COVE and then fail PEMS validation, proving codec validity and semantic validity are separate boundaries.

---

## 17. Conformance and Acceptance Tests

No PEMS/COVE representation becomes canonical before these tests exist.

### Semantic round trip

```text
expanded input
 → PEMS normalize
 → COVE encode
 → serialize
 → parse
 → COVE decode
 → PEMS validate/normalize
```

The final normalized value MUST equal the initial normalized value structurally and semantically.

### Steward ID-admission fixtures

Tests MUST prove:

- candidate IDs do not become canonical merely by parsing;
- same-meaning candidates reuse/confirm existing IDs;
- conflicting meanings cannot share one ID;
- existing canonical IDs are not silently rebound;
- external stable identity may inform candidate ID generation without bypassing admission.

### Provenance fixtures

Tests MUST prove:

- source identity survives multiple observations;
- observations remain immutable;
- claims target observations, not sources;
- immutable and unversioned observations remain distinguishable;
- historical claims retain their original evidence observation after a newer source observation appears.

### Structured determinism

Two encoder executions with different insertion/traversal order MUST produce identical COVE JSON values.

### Byte determinism

The selected serializer MUST produce identical UTF-8 bytes for identical COVE values. JCS RFC vectors SHOULD be included.

### Migration

Every supported version transition requires explicit fixtures. The current-handoff importer must demonstrate source/observation splitting and provisional-to-Steward-admitted identity handling.

### Human reconstruction

Pretty JSON and Markdown/search projections MUST retain semantic IDs and observation→source provenance, and repeated generation MUST be deterministic.

### Historical retention

Ordinary normalization MUST preserve historical/superseded/tombstoned/observation records. Any future retention-policy compaction requires its own fixture suite and explicit policy identifier.

### Size regression

Measure exact UTF-8 byte length of:

1. JCS serialization of normalized expanded PEMS;
2. JCS serialization of its COVE artifact.

Report:

```text
ratio = cove_bytes / expanded_bytes
reduction = 1 - ratio
```

Do not compare pretty expanded JSON against compact COVE.

The prior `>=20%` aggregate reduction remains a **measurement hypothesis**, not a normative acceptance gate. After representative fixtures exist, the project owner/Steward should set or explicitly waive a numeric threshold based on evidence. Correctness, provenance, deterministic recoverability, and useful context selection outrank marginal byte savings.

---

## 18. Selective Retrieval and Future Indexing

A derived index can map:

- record ID → kind/title/observation refs;
- source → observations;
- observation → dependent claims;
- chat → scoped records;
- role → owned/scoped records;
- module → requirements/decisions/validations;
- unresolved state → open items.

The index MUST be deterministically reconstructable and MUST NOT become canonical memory.

Do not add canonical sharding, byte offsets, or per-record blocks in v1 without measured need.

---

## 19. Cost and Agent-Context Implications

The `$10/month` autonomous-agent budget is not a codec requirement but affects measurement priorities.

Model cost is driven by selected semantic context, not canonical file byte size. Therefore:

- compact storage may reduce transport/parsing overhead;
- deterministic indexes/summaries should reduce repeated context expansion;
- agents SHOULD decode/select only relevant PEMS records before model invocation;
- raw COVE arrays SHOULD NOT be fed to a model merely because they are smaller on disk;
- context-token cost should be benchmarked separately from UTF-8 artifact size.

---

## 20. Remaining Open Questions Requiring Owner or Implementation Evidence

Owner decisions incorporated in this revision remove ID-allocation ownership, source/observation separation, default historical retention, and the predeclared 20% threshold from the open list.

Remaining questions:

1. **Canonical file path after migration:** approve `docs/project-chat-handoff.cove.json` as eventual compact canonical path while retaining `docs/project-chat-handoff.json` as generated compatibility/human derivative.
2. **JCS implementation dependency:** confirm willingness to adopt an RFC 8785 implementation/tooling dependency if Godot/GDScript does not provide exact JCS serialization natively. Architectural preference is approved; dependency choice remains implementation evidence.
3. **Extension policy:** v1 deliberately has a closed record-kind vocabulary. Decide later whether project-local extension kinds are needed or PEMS revisions are sufficiently cheap.
4. **Numeric compression threshold:** select only after representative fixture measurements exist; no fixed threshold is currently normative.
5. **Future retention policy details:** preservation is the v1 default. Any destructive compaction policy requires separate Steward approval and fixtures.

---

## 21. Implementation Sequence After Approval

Do not implement out of order merely to obtain a compact artifact quickly.

### Phase 1 — Freeze semantic fixtures

Create expanded PEMS fixtures covering current handoff requirements, source/observation provenance, Steward ID admission, historical retention, secret handling, edge states, and failures.

### Phase 2 — PEMS validator and normalizer

Implement deterministic validation/normalization without COVE. Include ID-admission boundary contracts and provenance validation.

### Phase 3 — COVE encoder/decoder

Implement cove/1 against generic JSON fixtures first, then PEMS fixtures.

### Phase 4 — Deterministic serializer

Adopt/test JCS or, only if demonstrated incompatibility appears, specify the smallest alternative byte-serialization contract.

### Phase 5 — Conformance suite

Add round-trip, structured determinism, byte determinism, malformed input, semantic/provenance failure, ID admission, historical retention, secret policy, migration, human export, and size-regression tests.

### Phase 6 — Existing handoff conversion tooling

Build a one-way importer from the current handoff schema into candidate normalized PEMS. Split source identity from observations and treat generated IDs as provisional until Steward admission. Do not make output canonical.

### Phase 7 — Shadow generation

For multiple Steward reconciliations generate:

- existing canonical human handoff;
- shadow normalized PEMS;
- shadow COVE artifact;
- regenerated human derivative.

Compare semantic equivalence, continuation usability, provenance auditability, ID stability, diffs, retrieval quality, and measured size.

### Phase 8 — Canonical adoption decision

Only after evidence is satisfactory should owner/Steward approve switching canonical memory to COVE and updating startup/tooling instructions.

---

## 22. Architectural Decisions Recommended by This Proposal

### Owner-approved / recommend locked for v1 design

1. **PEMS uses normalized typed records, explicit relations, stable IDs, type-specific states, and record-level provenance.**
2. **Canonical semantic IDs are allocated or confirmed by the Steward during reconciliation.**
3. **Stable source identity and source observations are distinct record kinds.**
4. **Semantic provenance references target observations, never mutable source identities directly.**
5. **Historical preservation is the safe v1 default; destructive compaction requires explicit Steward retention policy.**
6. **The current nested handoff is requirements input, not the future schema.**
7. **COVE uses global string interning plus deterministic object-shape factoring as a deliberately small generic core.**
8. **COVE remains PEMS-agnostic.**
9. **JCS is preferred as the separate deterministic serializer, subject to conformance evidence.**
10. **One canonical compact document is preferred to sharding in v1.**
11. **Human-readable/searchable artifacts are deterministic derivatives preserving semantic IDs and provenance.**
12. **The current human handoff remains canonical throughout migration and shadow validation.**
13. **Secret values are excluded except intentionally non-secret values classified as `literal`.**
14. **Runtime leases, retries, receipts, queues, and budget meters remain outside PEMS.**
15. **No fixed 20% compression threshold is normative before representative measurements exist.**

### Architect critique of owner-approved amendments

No architectural objection.

Steward-owned canonical ID admission is consistent with the existing single-writer reconciliation boundary and prevents identity split-brain without forcing UUID complexity into every producer.

Separating source identity from source observation materially improves provenance. The one refinement made by this proposal is stricter than the minimum request: pems/1 does not allow claims to point directly to sources even when immutable evidence is unavailable. Instead it uses an `unversioned_observation`. This avoids a polymorphic provenance pointer whose meaning would depend on target kind.

Historical preservation by default is also appropriate. Canonical normalization should not perform garbage collection. Retention can be added later as an explicit policy with its own evidence and migrations.

---

## 23. Decision Gate

This amended proposal is ready for final owner/Steward design review.

Before implementation begins, the owner should approve or amend the remaining design package as a whole:

- typed-record PEMS model including Steward ID admission;
- source/source_observation provenance model;
- small generic COVE mechanism;
- JCS as preferred serializer pending conformance evidence;
- single-artifact v1 boundary;
- migration/shadow-generation strategy;
- historical-preservation default;
- evidence-based rather than predeclared numeric compression threshold.

Until final design approval and later explicit migration approval, `docs/project-chat-handoff.json` remains the canonical continuity artifact and no PEMS/COVE representation is authoritative.