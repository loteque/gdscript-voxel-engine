# PEMS v1 and COVE v1 Design Proposal

## Status

**Architect proposal for project-owner and Steward review. Not yet canonical.**

This document specifies a proposed v1 semantic model and compact encoding contract for durable project engineering memory. It does **not** authorize conversion of `docs/project-chat-handoff.json`, implementation of the autonomous agent runtime, or replacement of existing continuity artifacts.

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

PEMS answers **what the project memory means**. COVE answers **how an arbitrary normalized structured value is represented compactly and reversibly**. The serializer answers **which exact UTF-8 bytes represent that COVE value**.

---

## 1. Design Goals

### Normative v1 requirements

PEMS v1 MUST:

1. preserve project continuity semantics without depending on one conversation transcript;
2. distinguish current state, historical state, proposals, accepted decisions, superseded decisions, unresolved work, implementation state, validation state, and source authority structurally rather than through prose conventions alone;
3. provide stable semantic identifiers independent of array position and mutable display names;
4. provide first-class source/provenance references;
5. represent the project-level context and chat/workstream continuity needed to reconstruct a role-faithful receiving session;
6. preserve absent, explicit `null`, and empty collection as distinct JSON states;
7. validate all semantic references and reject duplicate IDs;
8. exclude transient agent-runtime mechanics from the semantic model;
9. support deterministic lossless expansion into human-readable/searchable JSON;
10. preserve the project authority hierarchy rather than becoming a competing authority for current Git/ADR/roadmap/test truth.

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

- Adopt RFC 8785 JSON Canonicalization Scheme (JCS) as `jcs/1` for COVE byte serialization.
- Keep one canonical COVE project-memory artifact in v1 rather than sharding immediately.
- Keep a generated, pretty-printed expanded PEMS derivative during migration and for human debugging/onboarding.
- Target at least a 20% aggregate byte reduction versus the equivalent expanded normalized PEMS JSON on representative fixtures before COVE becomes canonical. This threshold is a proposed acceptance target, not yet an owner-approved invariant.

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

The exact order can vary by claim type. For example, an owner instruction can intentionally supersede a prior roadmap direction before `ROADMAP.md` is updated. PEMS therefore stores source authority categories and provenance, while reconciliation logic belongs to the Steward.

### 3.2 Source records

Every durable claim whose truth depends on an external source SHOULD reference one or more `source` records.

A normalized source record has the common record envelope plus source-specific data:

```json
{
  "id": "source:adr-001",
  "kind": "source",
  "lifecycle": "current",
  "source_refs": [],
  "data": {
    "source_kind": "git_file",
    "authority": "accepted_architecture",
    "locator": {
      "repository": "loteque/gdscript-voxel-engine",
      "ref": "main",
      "path": "docs/architecture/decisions/ADR-001-offline-runtime-terrain-boundary.md",
      "commit": "<commit-sha>",
      "line_start": null,
      "line_end": null
    },
    "observed_at": "2026-08-13T15:40:00-07:00"
  }
}
```

`authority` is a semantic category, not an instruction to COVE. Proposed v1 categories are:

- `repository_state`
- `accepted_architecture`
- `roadmap_intent`
- `executable_validation`
- `owner_instruction`
- `chat_history`
- `external_file`
- `generated_derivative`
- `other`

### 3.3 Provenance granularity

PEMS v1 uses **record-level provenance**. If two fields of what appears to be one object have materially different provenance or lifecycle, they SHOULD be represented as separate semantic records or relations rather than inventing field-level mini-provenance.

This is a normalization rule. It trades some record count for clearer authority and simpler tooling.

---

## 4. PEMS v1 Normalized Semantic Model

### 4.1 Root document

The normalized expanded PEMS document is proposed as:

```json
{
  "semantic": "pems/1",
  "project_id": "project:gdscript-voxel-terrain",
  "records": [],
  "relations": []
}
```

The root is intentionally small. Project data is itself a record so that all durable semantic objects share identity, lifecycle, provenance, and reference rules.

### 4.2 Common record envelope

Every PEMS record MUST have:

```json
{
  "id": "<stable semantic ID>",
  "kind": "<record kind>",
  "lifecycle": "current",
  "source_refs": ["source:..."],
  "data": {}
}
```

Optional common fields are:

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

`lifecycle` does not replace type-specific state. A `decision` record can be `current` with `decision_state: "proposed"`, and later become `superseded` when an accepted replacement decision exists.

### 4.3 Stable IDs

PEMS IDs MUST:

- be strings;
- be unique within one project-memory document;
- remain stable across display-name changes;
- never be derived from current array position;
- use a type-oriented prefix where practical for readability, e.g. `chat:procedural-terrain-architecture`, `role:engineering-knowledge-systems-architect`, `decision:offline-runtime-boundary`;
- reject duplicates during normalization.

IDs MAY initially be human-selected slugs. UUIDs are not required. The invariant is stability, not randomness.

Renaming a record changes `data.name` or equivalent display data, not `id`.

If an identity was created incorrectly and must be replaced, the old record SHOULD be superseded or tombstoned and the replacement SHOULD be linked explicitly rather than silently reusing the old ID for different meaning.

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

This is a bounded v1 vocabulary, not an unrestricted free-form type bag. New record kinds require a PEMS schema revision or an explicitly namespaced extension mechanism approved later.

### 4.5 Type-specific states

PEMS avoids one overloaded universal `status` enum. Each semantic type uses the smallest state machine that describes its domain.

Examples:

#### Decision

```json
{
  "kind": "decision",
  "data": {
    "title": "Use COVE as the compact codec name",
    "decision_state": "accepted",
    "summary": "COVE is the working codec name; CCJ remains fallback."
  }
}
```

Allowed `decision_state` values:

- `proposed`
- `accepted`
- `rejected`
- `superseded`

#### Unresolved item

```json
{
  "kind": "unresolved_item",
  "data": {
    "title": "Select canonical serializer",
    "resolution_state": "open",
    "summary": "Confirm JCS compatibility with implementation fixtures."
  }
}
```

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

Validation evidence belongs in source references and structured data, not only prose.

### 4.6 Relations

Cross-record relationships are normalized into a separate relation list when the relationship itself has durable meaning or provenance.

A relation is:

```json
{
  "id": "relation:architect-owns-cove-contract",
  "kind": "owns",
  "from": "role:engineering-knowledge-systems-architect",
  "to": "requirement:cove-contract",
  "lifecycle": "current",
  "source_refs": ["source:architect-directive"],
  "data": {}
}
```

Relation IDs are stable semantic IDs and MUST be unique.

Proposed core relation kinds include:

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

Direct ID fields remain appropriate where the relationship is intrinsic to the record schema, such as `project_id` in a chat record or `table_id` in a database-column record. The normalizer SHOULD avoid representing the same semantic edge both as an intrinsic field and a relation unless the duplication is explicitly required.

---

## 5. Required Continuity Semantics

The current human handoff is requirements input, not a shape to freeze. PEMS v1 should normalize its useful concepts as follows.

### Project-level context

Represent as a `project` record plus project-scoped `expectation`, `requirement`, `decision`, `module`, `source`, and related records.

### Chats / workstreams

Each chat/workstream becomes a `chat` record with stable identity, title, date/range, summary, and references to its active role and continuation information.

### Roles

Roles are independent records so multiple chats can reference one role without duplicating role semantics. Role directives remain Git artifacts and are referenced by sources rather than copied wholesale into PEMS.

### Owner relationship / expectations

Use explicit `expectation` records scoped to project, chat, or role through relations. Repeated expectations should be one record referenced from multiple scopes when semantically identical.

### Requirements and decisions

Use typed records with state and provenance. Proposed, accepted, rejected, and superseded outcomes are explicit.

### Unresolved items

Use `unresolved_item` records with structured resolution state, owner/scope relations, and provenance.

### External files

Use `external_file` records describing logical identity, title/name, source locator if available, purpose, and provenance. File content itself is not embedded merely because it was used in a chat.

### Modules

Use `module` records with repository path, domain, public role, and source references. Current existence/path claims should reference repository-state sources.

### Environment variables

Use `environment_variable` records with secret-safe value semantics defined in Section 10.

### Database tables / columns

Use separate `database_table` and `database_column` records. Columns reference a stable table ID. This avoids nesting that makes individual columns hard to identify or supersede.

### Branches / pull requests

Use `branch` and `pull_request` records for continuity claims that matter beyond a single retrieval. Current GitHub truth should always be revalidated before operational decisions.

### Validation responsibilities and state

Use `validation` records linked to the requirement/feature they validate and to evidence sources such as test files, validation scenes, CI runs, or published demo paths.

### Architecture / roadmap adjustments

Use `architecture_adjustment` and `roadmap_adjustment` records only for continuity around changes or pending reconciliation. Accepted current architecture and roadmap intent remain authoritative in ADRs/docs and `ROADMAP.md`.

### Continuation state

Use a `continuation` record to express the minimal state required to resume a chat/role: active role, current focus, known blockers, pending owner decisions, and pointers to the highest-value semantic records. It must not become a second project summary that duplicates the entire project memory.

---

## 6. Null, Absence, and Empty Semantics

These states MUST remain distinguishable through PEMS normalization and COVE round trips:

```json
{}
```

means a field is **absent** and therefore unspecified/not represented by this schema instance.

```json
{"value": null}
```

means the field is explicitly present with **no value / unknown / intentionally empty semantic scalar**, as defined by that field's schema.

```json
{"items": []}
```

means the collection is explicitly present and **known to contain zero members**.

Schemas MUST state whether a field is required, optional, nullable, or collection-valued. Normalization MUST NOT silently replace absent values with `null` or empty arrays unless that defaulting behavior is part of the PEMS version contract.

---

## 7. Deterministic PEMS Normalization

For one semantically equivalent PEMS input under `pems/1`, normalization MUST produce one equivalent normalized expanded JSON value.

### Normative rules

1. Duplicate record IDs and relation IDs fail normalization.
2. All intrinsic references and relation endpoints must resolve unless the schema explicitly marks the reference as external.
3. Record arrays are sorted by `id` using bytewise lexicographic ordering of their UTF-8 encoding.
4. Relation arrays are sorted by `id` using the same rule.
5. Set-like ID arrays, such as `source_refs`, `supersedes`, and `superseded_by`, are deduplicated and sorted by the same rule.
6. Ordered domain sequences retain their semantic order and MUST be identified as ordered by the schema.
7. JSON object property order is not semantic. Deterministic byte property order is the serializer's responsibility.
8. Strings are preserved exactly; PEMS v1 does not apply Unicode normalization implicitly.
9. Numeric fields must be finite JSON numbers compatible with the selected serializer. Stable IDs, commit SHAs, timestamps, and potentially large integer-like identifiers are strings.
10. Invalid type-specific states fail normalization.
11. A `superseded` record SHOULD identify at least one replacement through `superseded_by` unless the absence is explicitly justified by a schema rule.
12. A tombstoned record MUST retain its ID and kind but SHOULD minimize data to what is necessary to preserve identity/provenance.

### Why normalization happens before COVE

COVE must not decide that two project records are duplicates, infer which decision supersedes another, sort unordered project concepts, or validate project authority. Those are PEMS semantics. COVE receives a normalized JSON value and treats it as structured data only.

---

## 8. COVE v1 Structural Encoding

### 8.1 Design choice

COVE v1 intentionally uses only two compaction mechanisms in its core:

1. **global string interning**;
2. **deterministic object-shape factoring**.

This is smaller and simpler than a broad token language while remaining completely domain-agnostic. Enums, IDs, paths, repeated prose, object keys, and repeated reference strings naturally benefit from the string dictionary. Repeated keyed record layouts benefit from shape factoring.

PEMS-specific enum ordinals, record-type opcodes, or semantic reference types are **not** part of COVE v1. If later measurements justify a typed profile extension, that should be a separate codec revision or profile rather than hidden semantic coupling.

### 8.2 COVE artifact envelope

Proposed v1 envelope:

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

Fields:

- `c` — COVE codec identifier;
- `p` — opaque semantic/profile identifier; COVE does not interpret it;
- `s` — serializer identifier for canonical bytes;
- `d` — global string dictionary;
- `h` — object-shape dictionary;
- `x` — encoded root value.

A non-PEMS user of COVE could set `p` to another profile identifier without changing the codec.

### 8.3 String dictionary `d`

The dictionary contains **every distinct string appearing anywhere in the normalized input**, including object property names and string values.

Rules:

1. Strings are byte-for-byte exact Unicode strings from the parsed normalized value.
2. No Unicode normalization is applied by COVE.
3. Distinct strings are sorted by bytewise lexicographic order of their UTF-8 encoding.
4. Dictionary index is the zero-based position in that sorted array.
5. Duplicate strings are forbidden.

Interning every string adds a small reference overhead for one-off values, but removes the need for a heuristic whose output could depend on serializer-size estimation. Shape factoring removes repeated object keys entirely from object instances. The size requirement is validated empirically before canonical adoption.

### 8.4 Object-shape dictionary `h`

Each distinct JSON object key set becomes one shape.

A shape is an array of string-dictionary indexes, sorted ascending. Since the string dictionary itself is sorted deterministically, this defines deterministic key ordering inside a shape.

Example:

```json
[3, 7, 11]
```

means an object whose keys are dictionary strings `d[3]`, `d[7]`, and `d[11]`.

Shape construction rules:

1. gather every distinct object key set in the normalized input, including the normalized root if it is an object;
2. convert each key to its string dictionary index;
3. sort indexes ascending within the shape;
4. deduplicate identical shapes;
5. sort shapes lexicographically by integer sequence; where one sequence is an exact prefix of another, the shorter sequence sorts first;
6. shape index is zero-based position in this sorted list.

### 8.5 Encoded values

JSON primitives use these rules:

- `null`, `true`, `false`, and numbers remain raw JSON literals;
- strings encode as `[0, <dictionary-index>]`;
- arrays encode as `[1, <encoded-item-0>, <encoded-item-1>, ...]`;
- objects encode as `[2, <shape-index>, <encoded-value-for-key-0>, <encoded-value-for-key-1>, ...]`.

The numeric tags are normative for `cove/1`:

- `0` = string reference
- `1` = array
- `2` = object

No other tag is valid in v1.

For an object, values are emitted in the order of key indexes in its referenced shape.

This representation is unambiguous because every composite input value is replaced with a tagged encoded array. A raw JSON array never appears as an encoded semantic array without tag `1`.

### 8.6 Decoder validation

A COVE v1 decoder MUST reject:

- unknown codec major version;
- unsupported profile when the caller requires a specific profile;
- malformed envelope fields;
- duplicate dictionary strings;
- dictionary strings not in canonical order;
- malformed or duplicate shapes;
- shape key indexes outside `d`;
- unsorted shape key indexes;
- shape dictionary entries not in canonical order;
- unknown value tags;
- wrong tag arity;
- string indexes outside `d`;
- object shape indexes outside `h`;
- object value counts not matching the referenced shape;
- non-finite numeric values at the parsed-data boundary;
- decoded object duplicate keys, which should be impossible after valid shape checks but remains a defensive invariant.

After COVE decoding, the resulting expanded value MUST pass its profile validator, e.g. PEMS validation for `pems/1`.

### 8.7 Deterministic construction

The same normalized input MUST produce the same `d`, `h`, and `x` independent of traversal order used internally by an encoder.

A conforming encoder may collect strings/shapes in any implementation order, but it MUST apply the sorting and index-assignment rules above before producing the COVE value.

---

## 9. Serializer: RFC 8785 JCS Evaluation

RFC 8785 JCS is recommended for `jcs/1` because it already defines deterministic JSON serialization, including recursive property sorting, no insignificant whitespace, deterministic primitive serialization, and UTF-8 output.

Its important constraints are compatible with the proposed PEMS/COVE design if we deliberately remain inside them:

- object property names must be unique;
- strings must be valid Unicode and are preserved as-is rather than Unicode-normalized;
- numbers must be representable as IEEE 754 double precision;
- non-finite values are invalid;
- property sorting follows JCS rules rather than application-specific order.

PEMS v1 avoids numeric identities and timestamps, uses strings for commit hashes and semantic IDs, and has no requirement for arbitrary-precision JSON numbers. Therefore no known PEMS requirement currently conflicts with JCS.

### Recommendation

Adopt RFC 8785 JCS as the normative byte serializer for the first implementation, subject to implementation fixtures proving identical output across at least two independent JCS implementations or one implementation plus RFC test vectors.

Do **not** make COVE responsible for JSON property ordering or numeric textual rendering. COVE structural determinism exists before serialization; JCS byte determinism is a separate test.

---

## 10. Security and Secret Handling

PEMS is continuity memory, not a credential vault.

An environment-variable record MUST model value disposition explicitly:

```json
{
  "id": "env:example-token",
  "kind": "environment_variable",
  "lifecycle": "current",
  "source_refs": [],
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

- `literal` MAY contain a value only when the value is non-secret and intentionally appropriate for durable repository storage.
- `redacted` MUST NOT contain the secret value.
- `external_secret` MUST NOT contain the secret value; `external_ref` may identify an external secret slot only when that locator is itself safe to commit.
- `unset` means the variable is intentionally not configured in the represented environment.
- `unknown` means continuity knows the variable exists but not its current value/disposition.

Normalizers SHOULD reject obvious credential fields placed in a record type that does not permit secret-bearing data, but no schema validator can reliably detect every secret. Role directives and review remain necessary.

---

## 11. Versioning and Compatibility

PEMS, COVE, and the serializer are independently versioned.

### Identifier format

V1 uses stable namespace identifiers of the form:

```text
pems/1
cove/1
jcs/1
```

Minor compatibility rules may later be represented in schema metadata or implementation capability ranges, but the artifact identifier itself remains a major contract boundary in v1.

### Unknown versions

- Unknown PEMS major/profile: fail closed before semantic use.
- Unknown COVE major: fail closed before decoding.
- Unknown serializer identifier: canonical-byte verification fails; a parser may still inspect JSON structurally, but must not claim canonical-byte conformance.

### Migration

Preferred migration boundary:

```text
old semantic artifact
   ↓ decode with old codec/profile
old normalized expanded PEMS
   ↓ semantic migration
new normalized expanded PEMS
   ↓ encode with current COVE
new compact artifact
```

Semantic migrations belong to PEMS versions. COVE migrations should be rare and purely representational. Do not accumulate PEMS history inside COVE.

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

- a small semantic change can rewrite dictionary/shape indexes and therefore produce a large compact diff;
- corruption affects the whole artifact;
- selective retrieval generally requires reading dictionaries/shapes and at least structurally traversing the document;
- concurrent writers would conflict at file level.

The project already uses a single-writer Steward for canonical knowledge, so write concurrency is not currently a reason to shard.

### Partial decoding

COVE v1 does not promise O(1) extraction of one PEMS record from raw bytes. Global dictionaries and shapes are document-scoped.

A decoder can avoid materializing unrelated records after parsing the envelope and root structure, but the canonical JCS JSON artifact still needs to be parsed enough to reach the requested region.

Do not add shard manifests, byte offsets, or multiple canonical documents in v1 solely for hypothetical scale. If measured artifact size or retrieval cost becomes material, introduce a deterministic derived search index first. Sharding the canonical memory should require a separate design review because it changes atomicity and reference-integrity boundaries.

---

## 13. Human-Readable and Searchable Derivatives

There are two distinct expansion stages:

### Lossless normalized expansion

```text
COVE artifact
   ↓ COVE decode
normalized expanded PEMS JSON
```

This expansion MUST be semantically lossless and deterministic.

### Presentation / documentation transformation

```text
normalized expanded PEMS
   ↓ presentation exporters
pretty JSON / Markdown / onboarding docs / search index
```

Presentation exporters MAY:

- group records by kind or chat;
- resolve IDs into display labels;
- add navigation indexes;
- derive summaries or tables deterministically from structured fields;
- expose source links and provenance next to human-readable claims.

Presentation output MUST preserve semantic IDs and provenance links so humans can trace generated material back to canonical records.

### Migration recommendation for `docs/project-chat-handoff.json`

During migration, keep the existing human-readable `docs/project-chat-handoff.json` as the **canonical Steward artifact** while a COVE artifact is generated in shadow mode.

After the new validator/encoder/decoder passes conformance and the Steward explicitly adopts COVE, recommended paths are:

- canonical compact memory: `docs/project-chat-handoff.cove.json`
- generated compatibility/human derivative: `docs/project-chat-handoff.json`

The existing path should remain available as a generated derivative until project startup instructions, tooling, onboarding flows, and human review no longer depend on it. It may cease being canonical only through an explicit migration decision, never merely because an encoder exists.

---

## 14. Illustrative PEMS Fixture

This fixture is **near-normative**: its semantics and edge cases are required, while exact prose IDs may be refined before implementation fixtures are frozen.

```json
{
  "semantic": "pems/1",
  "project_id": "project:voxel",
  "records": [
    {
      "id": "chat:architecture",
      "kind": "chat",
      "lifecycle": "current",
      "source_refs": ["source:chat-architecture"],
      "data": {
        "title": "Procedural Terrain Architecture",
        "project_id": "project:voxel",
        "role_id": "role:architect"
      }
    },
    {
      "id": "chat:stewardship",
      "kind": "chat",
      "lifecycle": "current",
      "source_refs": ["source:chat-stewardship"],
      "data": {
        "title": "Project Stewardship",
        "project_id": "project:voxel",
        "role_id": "role:steward"
      }
    },
    {
      "id": "column:chunks-path",
      "kind": "database_column",
      "lifecycle": "current",
      "source_refs": [],
      "data": {
        "name": "asset_path",
        "table_id": "table:chunks",
        "type": "text",
        "nullable": false
      }
    },
    {
      "id": "decision:codec-cove",
      "kind": "decision",
      "lifecycle": "current",
      "source_refs": ["source:architect-notes"],
      "data": {
        "title": "Use COVE",
        "decision_state": "accepted",
        "summary": "Use COVE as the working compact-codec name."
      },
      "supersedes": ["decision:codec-jolt"]
    },
    {
      "id": "decision:codec-jolt",
      "kind": "decision",
      "lifecycle": "superseded",
      "source_refs": ["source:architect-notes"],
      "data": {
        "title": "Use JOLT",
        "decision_state": "superseded",
        "summary": "Earlier codec naming proposal."
      },
      "superseded_by": ["decision:codec-cove"]
    },
    {
      "id": "env:deploy-token",
      "kind": "environment_variable",
      "lifecycle": "current",
      "source_refs": [],
      "data": {
        "name": "DEPLOY_TOKEN",
        "value_state": "external_secret",
        "value": null,
        "external_ref": "secret-store:deploy-token"
      }
    },
    {
      "id": "item:serializer",
      "kind": "unresolved_item",
      "lifecycle": "current",
      "source_refs": ["source:architect-notes"],
      "data": {
        "title": "Confirm JCS serializer",
        "resolution_state": "open",
        "summary": "Validate RFC 8785 compatibility with fixtures."
      }
    },
    {
      "id": "project:voxel",
      "kind": "project",
      "lifecycle": "current",
      "source_refs": ["source:repo"],
      "data": {
        "name": "GDScript Voxel Terrain",
        "repository": "loteque/gdscript-voxel-engine",
        "description": "Procedural voxel terrain engine"
      }
    },
    {
      "id": "role:architect",
      "kind": "role",
      "lifecycle": "current",
      "source_refs": ["source:architect-directive"],
      "data": {
        "name": "Engineering Knowledge Systems Architect"
      }
    },
    {
      "id": "role:steward",
      "kind": "role",
      "lifecycle": "current",
      "source_refs": [],
      "data": {
        "name": "Project Engineering Steward"
      }
    },
    {
      "id": "source:architect-directive",
      "kind": "source",
      "lifecycle": "current",
      "source_refs": [],
      "data": {
        "source_kind": "git_file",
        "authority": "owner_instruction",
        "locator": {
          "path": "docs/handoff/architect_directive.md",
          "ref": "project-chat-handoff"
        }
      }
    },
    {
      "id": "table:chunks",
      "kind": "database_table",
      "lifecycle": "current",
      "source_refs": [],
      "data": {
        "name": "terrain_chunks",
        "purpose": "Example fixture table"
      }
    }
  ],
  "relations": [
    {
      "id": "relation:architect-owns-cove",
      "kind": "owns",
      "from": "role:architect",
      "to": "decision:codec-cove",
      "lifecycle": "current",
      "source_refs": ["source:architect-directive"],
      "data": {}
    }
  ]
}
```

The fixture intentionally contains repeated strings (`current`, record keys, role/source structure), semantic references, two chats/roles, an environment variable, table/column, supersession, an unresolved item, provenance, and an explicit `null`.

A separate fixture MUST demonstrate the difference between:

```json
{"data": {}}
```

```json
{"data": {"summary": null}}
```

and:

```json
{"data": {"tags": []}}
```

No normalizer or codec is allowed to collapse those three states.

---

## 15. Illustrative COVE Encoding

A tiny generic input:

```json
{
  "kind": "role",
  "name": "Architect"
}
```

might yield a dictionary conceptually ordered as:

```json
["Architect", "kind", "name", "role"]
```

with shape:

```json
[[1, 2]]
```

and encoded root:

```json
[2, 0, [0, 3], [0, 0]]
```

inside an envelope:

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

This example is normative for tag meaning and value/shape mechanics, but implementation fixtures must recompute exact dictionary ordering using the specified UTF-8 byte comparison rather than copying examples blindly.

---

## 16. Required Failure Fixtures

At minimum, conformance fixtures MUST include:

### PEMS failures

- duplicate record ID;
- duplicate relation ID;
- dangling relation endpoint;
- dangling `source_refs` entry;
- invalid type-specific state;
- invalid supersession reference;
- environment variable marked `external_secret` while containing a literal secret value;
- unknown `pems/<major>` profile.

### COVE failures

- unknown `cove/<major>`;
- duplicate dictionary string;
- unsorted dictionary;
- out-of-range string index;
- out-of-range shape index;
- duplicate or unsorted shape key index;
- non-canonical shape dictionary order;
- unknown tag;
- wrong object arity;
- malformed tagged array.

A specific malformed-reference fixture SHOULD decode successfully at the COVE layer and then fail PEMS validation, proving that codec validity and semantic validity are distinct boundaries.

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

The final normalized expanded PEMS value MUST equal the initial normalized value structurally and semantically.

### Structured determinism

Two independent encoder executions with different internal traversal/insertion order MUST produce identical COVE JSON values.

### Byte determinism

The chosen serializer MUST produce identical UTF-8 bytes for the same COVE value. JCS RFC vectors SHOULD be included when `jcs/1` is adopted.

### Migration

At least one fixture MUST exercise an explicit prior semantic version to `pems/1` migration before any future PEMS version is declared supported. Migration tests are added with every supported version transition.

### Human reconstruction

Generated pretty JSON and Markdown/search projections MUST retain semantic IDs and source references, and repeated generation from the same canonical memory MUST be deterministic.

### Size regression

Measure size using **exact UTF-8 byte length** of:

1. JCS serialization of normalized expanded PEMS JSON;
2. JCS serialization of its COVE artifact.

Report:

```text
ratio = cove_bytes / expanded_bytes
reduction = 1 - ratio
```

Do not compare pretty-printed expanded JSON against minified COVE; that would exaggerate compression.

Recommended adoption criterion pending measured fixtures:

- aggregate representative corpus reduction >= 20%;
- no representative fixture larger by more than 5% unless explicitly accepted as a small-fixture overhead case;
- future COVE changes that regress aggregate size by more than a configured tolerance require deliberate review.

Correctness and provenance outrank marginal byte savings.

---

## 18. Selective Retrieval and Future Indexing

PEMS's normalized record IDs make selective semantic retrieval straightforward *after expansion*. A derived search/index artifact can map:

- record ID → kind/title/source refs;
- chat → scoped records;
- role → owned/scoped records;
- module → requirements/decisions/validations;
- unresolved state → open items.

The index MUST be deterministically reconstructable from PEMS and MUST NOT become canonical project memory.

COVE v1 does not add byte offsets or per-record compressed blocks. If future measurements show that full-artifact parsing dominates agent context preparation, evaluate one of these in order:

1. generated deterministic semantic index;
2. cached decoded PEMS;
3. canonical sharding only if the first two are insufficient.

This keeps v1 practical and avoids turning a continuity file into a miniature database engine prematurely.

---

## 19. Cost and Agent-Context Implications

The `$10/month` autonomous-agent budget is not a codec requirement, but it changes what should be measured.

COVE can reduce repository/storage bytes, but model cost is driven by the **selected semantic context actually presented to a model**, not merely the canonical file size. Therefore:

- compact canonical storage should reduce deterministic transport/parsing overhead;
- selective retrieval and generated summaries/indexes should reduce repeated context expansion;
- agents SHOULD decode/select only semantically relevant PEMS records before model invocation;
- never feed raw COVE token arrays to a model merely because they are smaller on disk if expanded selected records are clearer and cheaper in model-token terms;
- model-context cost should be benchmarked separately from UTF-8 artifact size.

The representation architecture supports budget control, but deterministic event filtering and selective semantic context remain the larger cost levers.

---

## 20. Open Questions Requiring Owner or Implementation Evidence

1. **Size threshold:** Is the proposed >=20% aggregate reduction an appropriate minimum for canonical adoption, or should acceptance be purely evidence-based after fixtures exist?
2. **Canonical file path after migration:** Approve `docs/project-chat-handoff.cove.json` as the eventual compact canonical path while retaining `docs/project-chat-handoff.json` as a generated human/compatibility derivative.
3. **JCS implementation dependency:** Confirm willingness to adopt an RFC 8785 implementation/tooling dependency if Godot/GDScript does not provide exact JCS serialization natively.
4. **Extension policy:** v1 deliberately has a closed record-kind vocabulary. Decide later whether project-local extension kinds are needed or whether PEMS revisions are sufficiently cheap.
5. **Historical retention:** Define Steward policy for when superseded/historical records remain in canonical PEMS versus being compacted into higher-level historical summaries. This is continuity policy, not codec behavior.

---

## 21. Implementation Sequence After Approval

Do not implement out of order merely to obtain a compact artifact quickly.

### Phase 1 — Freeze semantic fixtures

Create expanded PEMS fixtures covering the current handoff requirements, edge states, provenance, secret handling, and failures.

### Phase 2 — PEMS validator and normalizer

Implement deterministic validation/normalization without COVE. The normalized expanded representation becomes independently testable.

### Phase 3 — COVE encoder/decoder

Implement `cove/1` as a generic structured-data codec against generic JSON fixtures first, then PEMS fixtures.

### Phase 4 — Deterministic serializer

Adopt/test JCS or, only if a demonstrated incompatibility appears, specify the smallest alternative byte-serialization contract.

### Phase 5 — Conformance suite

Add round-trip, structured determinism, byte determinism, malformed input, semantic-reference failure, secret-policy, migration, human-export, and size-regression tests.

### Phase 6 — Existing handoff conversion tooling

Build a one-way importer from the current handoff schema into normalized PEMS plus generated human-readable export. Do not make the output canonical yet.

### Phase 7 — Shadow generation

For multiple Steward reconciliations, generate:

- existing canonical human handoff;
- shadow normalized PEMS;
- shadow COVE artifact;
- regenerated human derivative.

Compare semantic equivalence, continuation usability, diffs, retrieval quality, and size.

### Phase 8 — Canonical adoption decision

Only after evidence is satisfactory should the owner/Steward approve switching canonical memory to COVE and updating project startup instructions/tooling.

---

## 22. Architectural Decisions Recommended by This Proposal

### Recommend acceptance

1. **PEMS v1 uses normalized typed records, explicit relations, stable IDs, and record-level provenance.**
2. **The current nested handoff JSON is requirements input, not the future schema.**
3. **COVE v1 uses global string interning plus deterministic object-shape factoring as its deliberately small generic core.**
4. **COVE remains completely PEMS-agnostic.**
5. **JCS is the preferred deterministic JSON serializer, separate from COVE.**
6. **One canonical compact document is preferable to sharding in v1.**
7. **Human-readable/searchable artifacts remain deterministic derivatives and preserve semantic IDs/provenance.**
8. **The current human handoff remains canonical throughout migration and shadow validation.**
9. **Secret values are explicitly excluded from PEMS except non-secret values intentionally classified as `literal`.**
10. **Runtime leases, retries, receipts, queues, and budget meters remain outside PEMS.**

### Steward recommendations refined

The Steward requested dictionary encoding, enums, stable references, positional records, and repeated-shape factoring as candidates. This proposal deliberately **does not** give COVE semantic enum tables or PEMS-specific positional record layouts in v1. Generic shape factoring already removes repeated keys while preserving domain independence. Adding semantic opcodes now would save more bytes at the cost of coupling codec and schema evolution.

The Steward also suggested selective retrieval considerations. This proposal treats whole-document parsing as an acceptable v1 tradeoff and recommends deterministic derived indexes before canonical sharding.

These are refinements, not rejections of the underlying requirements.

---

## 23. Decision Gate

This document is ready for owner/Steward review as a design proposal.

Before implementation begins, the project owner should approve or amend:

- the PEMS typed-record normalization model;
- the small generic COVE mechanism;
- JCS as preferred serializer;
- the single-artifact v1 boundary;
- migration/shadow-generation strategy;
- the proposed size-acceptance policy or an instruction to defer the numeric threshold until fixtures are measured.

Until that review occurs, `docs/project-chat-handoff.json` remains the canonical continuity artifact and no PEMS/COVE representation should be treated as authoritative.