# PEMS v1 Phase 2 Tooling

Status: **Phase 2 implementation work in progress**

This package implements the semantic layer that sits between the frozen `pems/1` Phase 1 schema/fixtures and any future COVE representation. It deliberately contains no COVE encoding, JCS serialization, canonical handoff conversion, or autonomous-agent runtime behavior.

## Responsibilities

`tools.pems.pems_v1` exposes separate contracts for:

- `validate_schema()` — validates a document against `docs/handoff/pems/pems-v1.schema.json` using JSON Schema 2020-12 and explicit RFC 3339 `date-time` format checking;
- `validate_semantics()` — validates graph integrity, intrinsic references, relation endpoints, provenance target kinds, supersession consistency, lifecycle requirements, and conservative secret policy not safely expressible in ordinary JSON Schema;
- `normalize_document()` — deterministically sorts records/relations by UTF-8 bytewise semantic ID and sorts/deduplicates set-like ID arrays while preserving absent/null/empty distinctions and ordered sequences;
- `semantic_identity()` / `admit_candidate()` — implements the Steward admission boundary for semantic identity reuse, canonical-ID collision rejection, duplicate-identity rejection, immutable observation rebinding rejection, and explicit confirmation of new candidates;
- `validate_retention_operation()` — rejects destructive record removal unless an explicitly caller-approved Steward retention policy is supplied;
- `run_fixture_suite()` — consumes the frozen Phase 1 success and failure/admission/retention fixtures and checks their declared validation stage/code plus normalization idempotence and traversal-order independence.

These APIs are intentionally distinct. Structural validity, graph truth, canonical normalization, and Steward identity admission are different responsibilities and must remain independently testable.

## Deterministic diagnostics

Diagnostics contain:

- `stage`: `schema`, `semantic`, `normalization`, `admission`, or `retention`;
- `code`: stable machine-readable identifier used by fixtures/tooling;
- `path`: JSON Pointer-like location where practical;
- `message`: human-readable explanation.

Diagnostics are sorted deterministically by stage, path, code, and message using UTF-8 byte ordering.

## Identity admission

Admission does not make a candidate canonical merely because it parses or carries an externally stable-looking ID. New candidates return `candidate_requires_steward_confirmation`. A provisional `candidate:` or `import:` ID that matches an existing semantic identity may resolve to the existing canonical ID. A second canonical-looking ID for the same identity is rejected instead of silently creating an alias.

`source_observation` receives stricter handling: reusing an admitted observation ID for different immutable evidence returns `immutable_observation_rebound`.

## Dependencies

Phase 2 uses the widely adopted `jsonschema` package only for validation against the frozen machine-readable schema. It does not introduce the later JCS dependency decision.

Install the repository-scoped tooling dependency with:

```bash
python -m pip install -r tools/pems/requirements.txt
```

The intended fixture command is:

```bash
python -m tools.pems.run_fixtures
```

At the time this branch was authored, GitHub safety classification blocked the durable runner/test-file writes after the owner-approved single retry. The core library and this documentation can therefore be reviewed independently, but Phase 2 must remain **blocked** until a durable automated fixture runner/test artifact lands and executes successfully.

## Architectural boundary

The package must not:

- encode/decode COVE;
- serialize canonical JSON bytes or choose JCS tooling;
- mutate `docs/project-chat-handoff.json`;
- allocate canonical IDs without the Steward admission decision;
- garbage-collect historical records during normalization;
- contain runtime leases, retries, budget meters, provider IDs, or activation state.

The existing human handoff remains canonical until a later explicit owner/Steward migration decision after shadow validation.
