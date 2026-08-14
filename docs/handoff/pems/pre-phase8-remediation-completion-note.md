
## ARCH-20260813T235900-0700-015

- timestamp: `2026-08-13T23:59:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `STEWARD-20260813-012`, `STEWARD-20260813-013`, `ARCH-20260813T220800-0700-014`
- subject: Pre-Phase-8 PEMS/COVE remediation complete

### Assessment

The two adoption findings surfaced by Phase 7 are remediated on branch `pems-phase8-remediation` without changing project-memory authority or extending the frozen `pems/1` record vocabulary.

The structured legacy engineering-memory fields now have direct normative PEMS projection in the migration path. Each `project_level.engineering_memory.representation_workstream` field becomes a deterministic `decision` record using the existing closed decision schema, and `repository_write_safety` becomes a deterministic `requirement` record using the existing requirement-state vocabulary. Unsupported repository-write-safety status values fail explicitly rather than being stored in an arbitrary data escape hatch.

The migration-seeding path now accepts ordered validated handoff snapshots. The newest snapshot supplies current semantic records; earlier semantic IDs absent from the newest snapshot are retained with historical lifecycle. This preserves validated prior immutable source observations and removed historical records while avoiding duplicate current identities. Stable IDs present in the newest snapshot remain represented by the newest state.

All imported and seeded IDs remain provisional and return `candidate_requires_steward_confirmation`; this remediation does not perform Steward admission.

### Validation evidence

GitHub Actions run `31778186729` (`PEMS Pre-Phase-8 Remediation`) completed successfully against remediation head `e272d1eaff8c782ffad02554705d86a526cdcf25` before this completion-record append. The regression gate reported `55 passed, 41 subtests passed`.

The real Phase 7 handoff pair was used as migration input:

- prior source commit `18ece6c5791da00ff5c14eb79172cf6d7fea5860`, handoff blob `7f848c9259c63d8095a4b310bcfe6fab11495a88`;
- current source commit `ff2718a00b3a267407beb446607ea6eeb664e66e`, handoff blob `e54e268cdd4fc4dad9a340c5a19958b734a74186`.

The resulting noncanonical migration seed contains 156 records and 156 provisional IDs. It preserves both immutable source-observation candidates:

- `import:source_observation:5b206d4358781f93074b`;
- `import:source_observation:8c186a6ca2398e0cfe5e`.

The prior source observation and removed decision `import:decision:b54a6445b1ce2b815b56` are retained as historical records. The workflow directly asserts structured engineering-memory mapping, historical seeding, provisional admission behavior, schema and semantic validity, deterministic repeat generation, PEMS/COVE/`jcs/1` semantic round trip, deterministic human reconstruction, and canonical-byte repeatability.

The seeded corpus measures 62,995 expanded JCS bytes and 36,184 COVE + `jcs/1` bytes. Its normalized PEMS SHA-256 is `57f1ee06478b15fe873e067f03b021bee2586d9c77cc19e01dece9df96efd5b4`; compact SHA-256 is `6437419c6ccacf5e057698f3c3da51e01e7d805e203cc636e8d029422ba1da9c`; deterministic human reconstruction SHA-256 is `1addd8efcdfadeda8dd39ef122670e13d6a67b72abedf76bef9459ae96639737`.

The uploaded evidence artifact is `pems-pre-phase8-remediation-evidence`, artifact ID `9210677542`, ZIP digest `sha256:014db6ca637f17d416bf3eedc9546d6fd2b985bae9ea5adf1d98248c1967c4f1`.

### Schema and design outcome

No contradiction requiring a `pems/1` schema change was found. The existing `decision`, `requirement`, `source_observation`, lifecycle, provenance, normalization, COVE, and JCS contracts are sufficient for the remediation.

This tranche adds a migration-specific importer/seeding layer rather than redefining the Phase 6 per-snapshot importer. The original Phase 6 importer remains useful as a single-snapshot evidence converter; Phase 8 migration, if authorized, should use the remediated migration-seed path so structured fields and validated shadow history are not dropped.

### Remaining Phase 8 gate

The two Phase 7 adoption discrepancies no longer block a Phase 8 decision. The remaining work is governance, not representation repair: the owner and Project Engineering Steward must separately decide whether to adopt, defer, or further constrain canonical PEMS/COVE migration, and the Steward must define/perform canonical identity admission as part of any authorized cutover.

`docs/project-chat-handoff.json` remains canonical. No `docs/project-chat-handoff.cove.json` authority artifact was created or adopted, no production voxel-engine behavior changed, no autonomous-agent runtime work was performed, and no pull request or merge was created.

### Human reasoning

Phase 7 showed that the representation worked but exposed two sharp migration edges: a newest-snapshot-only conversion would forget earlier source observations, and two newly structured Steward fields survived only indirectly. The remediation fixes those edges without redesigning PEMS. Think of it as packing the old photo album into the moving boxes and labeling two boxes that previously relied on someone remembering what was inside.

The system is now technically ready for a separate Phase 8 adoption decision, but technical readiness is not authority. The switch remains closed until the owner and Steward explicitly open it.
