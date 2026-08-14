from __future__ import annotations

import argparse
import copy
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from .import_current_handoff import HandoffImportError, ImportReport, import_handoff
from .pems_v1 import admit_candidate, normalize_document, validate_schema, validate_semantics


@dataclass(frozen=True)
class MigrationSeedReport:
    document: dict[str, Any]
    provisional_ids: tuple[str, ...]
    source_observation_ids: tuple[str, ...]
    retained_historical_ids: tuple[str, ...]


def _canonical_text(value: Any) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def _candidate_id(kind: str, identity: Any) -> str:
    digest = hashlib.sha256(_canonical_text(identity).encode("utf-8")).hexdigest()[:20]
    return f"import:{kind}:{digest}"


def _record(record_id: str, kind: str, observation_id: str, data: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "id": record_id,
        "kind": kind,
        "lifecycle": "current",
        "observation_refs": [observation_id],
        "data": dict(data),
    }


def _require_mapping(value: Any, code: str, message: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise HandoffImportError(code, message)
    return value


def _direct_engineering_memory_records(handoff: Mapping[str, Any], observation_id: str) -> list[dict[str, Any]]:
    project_level = _require_mapping(
        handoff.get("project_level"),
        "missing_project_level",
        "Current handoff must contain project_level.",
    )
    engineering_memory = project_level.get("engineering_memory")
    if engineering_memory is None:
        return []
    engineering_memory = _require_mapping(
        engineering_memory,
        "invalid_engineering_memory",
        "project_level.engineering_memory must be an object.",
    )

    records: list[dict[str, Any]] = []
    representation_workstream = engineering_memory.get("representation_workstream")
    if representation_workstream is not None:
        representation_workstream = _require_mapping(
            representation_workstream,
            "invalid_representation_workstream",
            "project_level.engineering_memory.representation_workstream must be an object.",
        )
        for field in sorted(representation_workstream, key=lambda item: str(item).encode("utf-8")):
            if not isinstance(field, str) or not field:
                raise HandoffImportError(
                    "invalid_representation_workstream",
                    "representation_workstream keys must be non-empty strings.",
                )
            value = representation_workstream[field]
            rendered = _canonical_text(value)
            summary = f"Engineering-memory representation workstream field {field!r} is {rendered}."
            records.append(
                _record(
                    _candidate_id(
                        "decision",
                        {
                            "structured_source": "project_level.engineering_memory.representation_workstream",
                            "field": field,
                            "value": value,
                        },
                    ),
                    "decision",
                    observation_id,
                    {"summary": summary, "decision_state": "accepted", "rationale": None},
                )
            )

    repository_write_safety = engineering_memory.get("repository_write_safety")
    if repository_write_safety is not None:
        repository_write_safety = _require_mapping(
            repository_write_safety,
            "invalid_repository_write_safety",
            "project_level.engineering_memory.repository_write_safety must be an object.",
        )
        status = repository_write_safety.get("status")
        rule = repository_write_safety.get("rule")
        if not isinstance(status, str) or not status:
            raise HandoffImportError(
                "invalid_repository_write_safety",
                "repository_write_safety.status must be a non-empty string.",
            )
        if not isinstance(rule, str) or not rule:
            raise HandoffImportError(
                "invalid_repository_write_safety",
                "repository_write_safety.rule must be a non-empty string.",
            )
        state_by_status = {
            "active": "active",
            "satisfied": "satisfied",
            "deprecated": "deprecated",
            "superseded": "superseded",
        }
        if status not in state_by_status:
            raise HandoffImportError(
                "invalid_repository_write_safety",
                f"repository_write_safety.status {status!r} has no pems/1 requirement-state mapping.",
            )
        records.append(
            _record(
                _candidate_id(
                    "requirement",
                    {
                        "structured_source": "project_level.engineering_memory.repository_write_safety",
                        "status": status,
                        "rule": rule,
                    },
                ),
                "requirement",
                observation_id,
                {
                    "summary": f"Repository write safety [{status}]: {rule}",
                    "requirement_state": state_by_status[status],
                },
            )
        )
    return records


def import_handoff_with_engineering_memory(
    handoff: Mapping[str, Any],
    *,
    source_commit: str | None = None,
    source_path: str = "docs/project-chat-handoff.json",
) -> ImportReport:
    base = import_handoff(handoff, source_commit=source_commit, source_path=source_path)
    records = list(base.document["records"])
    records.extend(_direct_engineering_memory_records(handoff, base.source_observation_id))
    document = normalize_document(
        {
            "semantic": base.document["semantic"],
            "project_id": base.document["project_id"],
            "records": records,
            "relations": list(base.document["relations"]),
        }
    )
    schema_result = validate_schema(document)
    if not schema_result.valid:
        diag = schema_result.diagnostics[0]
        raise HandoffImportError("generated_pems_schema_invalid", f"{diag.code} at {diag.path}: {diag.message}")
    semantic_result = validate_semantics(document)
    if not semantic_result.valid:
        diag = semantic_result.diagnostics[0]
        raise HandoffImportError("generated_pems_semantic_invalid", f"{diag.code} at {diag.path}: {diag.message}")

    provisional_ids = tuple(sorted((record["id"] for record in document["records"]), key=lambda item: item.encode("utf-8")))
    for record in document["records"]:
        decision = admit_candidate(record, [])
        if decision.code != "candidate_requires_steward_confirmation":
            raise HandoffImportError(
                "unexpected_admission_behavior",
                f"Imported candidate {record['id']} did not remain provisional: {decision.code}.",
            )
    return ImportReport(document=document, provisional_ids=provisional_ids, source_observation_id=base.source_observation_id)


def seed_migration(
    snapshots: Sequence[tuple[Mapping[str, Any], str | None]],
    *,
    source_path: str = "docs/project-chat-handoff.json",
) -> MigrationSeedReport:
    if not snapshots:
        raise HandoffImportError("missing_seed_snapshots", "Migration seed requires at least one validated handoff snapshot.")

    imports = [
        import_handoff_with_engineering_memory(handoff, source_commit=source_commit, source_path=source_path)
        for handoff, source_commit in snapshots
    ]
    latest = imports[-1]
    by_id = {record["id"]: copy.deepcopy(record) for record in latest.document["records"]}
    retained_historical_ids: set[str] = set()

    for report in imports[:-1]:
        for record in report.document["records"]:
            record_id = record["id"]
            if record_id in by_id:
                continue
            retained = copy.deepcopy(record)
            retained["lifecycle"] = "historical"
            by_id[record_id] = retained
            retained_historical_ids.add(record_id)

    document = normalize_document(
        {
            "semantic": latest.document["semantic"],
            "project_id": latest.document["project_id"],
            "records": list(by_id.values()),
            "relations": list(latest.document["relations"]),
        }
    )
    schema_result = validate_schema(document)
    if not schema_result.valid:
        diag = schema_result.diagnostics[0]
        raise HandoffImportError("seeded_pems_schema_invalid", f"{diag.code} at {diag.path}: {diag.message}")
    semantic_result = validate_semantics(document)
    if not semantic_result.valid:
        diag = semantic_result.diagnostics[0]
        raise HandoffImportError("seeded_pems_semantic_invalid", f"{diag.code} at {diag.path}: {diag.message}")

    provisional_ids = tuple(sorted(by_id, key=lambda item: item.encode("utf-8")))
    for record in document["records"]:
        decision = admit_candidate(record, [])
        if decision.code != "candidate_requires_steward_confirmation":
            raise HandoffImportError(
                "unexpected_admission_behavior",
                f"Seeded candidate {record['id']} did not remain provisional: {decision.code}.",
            )

    source_observation_ids = tuple(
        sorted(
            (record["id"] for record in document["records"] if record["kind"] == "source_observation"),
            key=lambda item: item.encode("utf-8"),
        )
    )
    return MigrationSeedReport(
        document=document,
        provisional_ids=provisional_ids,
        source_observation_ids=source_observation_ids,
        retained_historical_ids=tuple(sorted(retained_historical_ids, key=lambda item: item.encode("utf-8"))),
    )


def _load_snapshot(path: Path) -> Mapping[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, Mapping):
        raise HandoffImportError("invalid_root", f"{path} root must be an object.")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build noncanonical pre-Phase-8 PEMS migration seed evidence from ordered handoff snapshots."
    )
    parser.add_argument(
        "snapshot",
        nargs="+",
        help="Ordered snapshot as COMMIT:PATH; use '-' as COMMIT for unversioned evidence.",
    )
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    snapshots: list[tuple[Mapping[str, Any], str | None]] = []
    try:
        for spec in args.snapshot:
            commit, separator, raw_path = spec.partition(":")
            if not separator or not raw_path:
                raise HandoffImportError("invalid_snapshot_spec", f"Expected COMMIT:PATH, got {spec!r}.")
            snapshots.append((_load_snapshot(Path(raw_path)), None if commit == "-" else commit))
        report = seed_migration(snapshots)
    except (OSError, json.JSONDecodeError, HandoffImportError) as exc:
        code = getattr(exc, "code", "invalid_json_or_io")
        parser.exit(2, f"{code}: {exc}\n")

    output = _canonical_text(report.document) + "\n"
    if args.output:
        args.output.write_text(output, encoding="utf-8")
    else:
        print(output, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
