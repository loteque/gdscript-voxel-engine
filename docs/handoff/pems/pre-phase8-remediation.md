# Pre-Phase-8 PEMS/COVE remediation

This tranche addresses the two adoption findings surfaced by Phase 7 without changing canonical project-memory authority.

## Authority boundary

`docs/project-chat-handoff.json` remains canonical. The migration seed produced here is noncanonical evidence only. `docs/project-chat-handoff.cove.json` is not created or adopted by this tranche, and all imported or seeded semantic IDs remain provisional until explicit Project Engineering Steward admission.

## Direct structured engineering-memory mapping

The migration importer maps `project_level.engineering_memory.representation_workstream` directly into ordinary `pems/1` `decision` records, one deterministic record per structured field. The field name and canonical JSON value are represented in the decision summary so the value is visible to schema validation, COVE/JCS round trip, human reconstruction, and search without adding an arbitrary-data escape hatch.

`project_level.engineering_memory.repository_write_safety` maps directly into a `pems/1` `requirement` record. The legacy status maps to the existing `requirement_state` vocabulary; an unsupported status fails explicitly rather than silently inventing semantics.

No new record kind or schema extension is required.

## Deterministic migration seeding

`tools.pems.migration_seed.seed_migration()` accepts ordered validated handoff snapshots. Each snapshot is imported independently with immutable source/source-observation provenance where a source commit is supplied.

The newest snapshot supplies the current semantic records. Earlier records whose semantic IDs are absent from the newest snapshot are retained with `historical` lifecycle, including earlier immutable `source_observation` records and decisions that disappeared from the newest handoff. Stable IDs present in the newest snapshot retain the newest current representation and are not duplicated.

This makes the first future canonical corpus seed capable of carrying validated pre-adoption provenance and removed historical records forward instead of starting with only the newest source observation.

## Identity admission

Seeding does not admit identity. Every record is checked against an empty canonical admission set and must return `candidate_requires_steward_confirmation`. The eventual Phase 8 cutover, if separately authorized, must define the actual Steward admission set and canonical IDs.

## Validation gate

The remediation is acceptable only if the real Phase 7 before/after canonical handoffs demonstrate:

- both immutable handoff source observations survive the seed;
- structured representation-workstream and repository-write-safety values have direct normative PEMS records;
- removed earlier records are retained as historical records;
- schema and semantic validation pass;
- repeated seed generation is deterministic;
- every generated identity remains provisional;
- PEMS -> COVE -> `jcs/1` -> parse -> COVE decode returns identical PEMS;
- deterministic human reconstruction contains the directly mapped values;
- actual expanded and compact UTF-8 byte sizes are measured reproducibly.

Passing this gate makes the two Phase 7 findings remediated. It does not itself authorize Phase 8 canonical adoption.
