# Phase 6 Current Handoff Import

Status: implemented and validated on `phase6-current-handoff-importer`.

Phase 6 adds a one-way converter from the current canonical `docs/project-chat-handoff.json` representation into normalized `pems/1` evidence. The converter is intentionally non-authoritative: generated PEMS is test/migration evidence only, and `docs/project-chat-handoff.json` remains canonical until a later separately approved adoption stage.

## Command

```bash
python -m tools.pems.import_current_handoff path/to/project-chat-handoff.json \
  --source-commit <commit-containing-that-snapshot> \
  --output /tmp/imported-pems.json
```

When `--source-commit` is supplied, the importer creates a stable `source` identity for the canonical handoff and a distinct `source_observation` with `immutable_snapshot` evidence bound to that commit. Without a commit, the observation is explicitly `unversioned_observation`; the importer never fabricates immutable provenance.

## Identity and authority

All generated record IDs use the `import:` provisional namespace. The importer checks each generated record through the existing PEMS admission API and requires `candidate_requires_steward_confirmation`. Conversion therefore cannot silently allocate canonical semantic IDs.

The importer validates generated output with both the frozen PEMS JSON Schema and semantic validator before returning it. Unsupported current-handoff schema majors, malformed project identity, invalid timestamps, malformed module records, malformed chats, and other required-field failures produce explicit stable importer error codes rather than best-effort guessing.

## Mapped continuity

The Phase 6 mapping preserves the current handoff's project identity and summary, owner expectations, repository snapshot branch/head, module inventory, chat titles/summaries/time ranges, chat role context, key decisions/outcomes, external supporting files, and a continuation record per imported chat. Imported semantic records reference the handoff source observation so their migration provenance remains inspectable.

The converter does not claim that every nested legacy field already has a canonical PEMS identity or that generated decisions have been independently re-adjudicated beyond the authority of the source handoff. Phase 7 may exercise repeated shadow generation, but that stage is not authorized by this implementation.

## Validation evidence

`.github/workflows/pems-phase6-import.yml` runs focused malformed-input, provenance, determinism, continuity, and admission tests. It also fetches the real canonical handoff from `project-chat-handoff`, materializes that exact branch snapshot with its commit SHA, converts it twice, compares outputs byte-for-byte, validates the resulting normalized PEMS, and verifies that all generated IDs remain pending Steward confirmation.

Successful run `31765990031` validated commit `12927b6b585ad53dc69e6af03034478f30f51954`. The live handoff produced 138 normalized PEMS records covering 14 chats and 23 modules. No canonical artifact was replaced or created by the workflow.

## Stage boundary

Phase 6 stops at deterministic one-way conversion tooling and evidence. It does not authorize Phase 7 shadow generation across Steward reconciliations, canonical adoption of `docs/project-chat-handoff.cove.json`, replacement/removal of the current handoff, autonomous-agent runtime infrastructure, production voxel-engine changes, PR creation, or merge.
