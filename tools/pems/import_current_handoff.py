from __future__ import annotations

import argparse
import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from .pems_v1 import admit_candidate, normalize_document, validate_schema, validate_semantics

SUPPORTED_SCHEMA_MAJOR = 1


class HandoffImportError(ValueError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class ImportReport:
    document: dict[str, Any]
    provisional_ids: tuple[str, ...]
    source_observation_id: str


def _canonical_text(value: Any) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def _candidate_id(kind: str, identity: Any) -> str:
    digest = hashlib.sha256(_canonical_text(identity).encode("utf-8")).hexdigest()[:20]
    return f"import:{kind}:{digest}"


def _require_mapping(value: Any, code: str, message: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise HandoffImportError(code, message)
    return value


def _require_string(value: Any, code: str, message: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise HandoffImportError(code, message)
    return value


def _timestamp(value: str, code: str = "invalid_generated_at") -> str:
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})", value):
        return value
    raise HandoffImportError(code, f"Expected RFC 3339 timestamp, got {value!r}.")


def _date_range(value: str, fallback: str) -> tuple[str, str | None]:
    dates = re.findall(r"\d{4}-\d{2}-\d{2}", value or "")
    if not dates:
        return fallback, None
    start = dates[0] + "T00:00:00Z"
    end = dates[-1] + "T23:59:59Z" if len(dates) > 1 else None
    return start, end


def _record(record_id: str, kind: str, observation_id: str, data: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "id": record_id,
        "kind": kind,
        "lifecycle": "current",
        "observation_refs": [observation_id] if kind != "source_observation" else [],
        "data": dict(data),
    }


def import_handoff(
    handoff: Mapping[str, Any],
    *,
    source_commit: str | None = None,
    source_path: str = "docs/project-chat-handoff.json",
) -> ImportReport:
    schema_version = _require_string(
        handoff.get("schema_version"),
        "missing_schema_version",
        "Current handoff must contain schema_version.",
    )
    try:
        major = int(schema_version.split(".", 1)[0])
    except ValueError as exc:
        raise HandoffImportError("unsupported_schema_version", f"Unparseable schema_version {schema_version!r}.") from exc
    if major != SUPPORTED_SCHEMA_MAJOR:
        raise HandoffImportError(
            "unsupported_schema_version",
            f"Phase 6 importer supports current handoff schema major {SUPPORTED_SCHEMA_MAJOR}, got {schema_version!r}.",
        )

    generated_at = _timestamp(
        _require_string(handoff.get("generated_at"), "missing_generated_at", "Current handoff must contain generated_at.")
    )
    project_level = _require_mapping(
        handoff.get("project_level"),
        "missing_project_level",
        "Current handoff must contain project_level.",
    )
    project_name = _require_string(
        project_level.get("project_name"),
        "missing_project_name",
        "project_level.project_name is required.",
    )
    repository = _require_string(
        project_level.get("repository"),
        "missing_repository",
        "project_level.repository is required.",
    )
    project_summary = _require_string(
        project_level.get("project_summary"),
        "missing_project_summary",
        "project_level.project_summary is required.",
    )

    source_id = _candidate_id("source", {"repository": repository, "path": source_path})
    observation_identity = {
        "source_id": source_id,
        "generated_at": generated_at,
        "source_commit": source_commit,
        "path": source_path,
    }
    observation_id = _candidate_id("source_observation", observation_identity)

    records: list[dict[str, Any]] = []
    records.append(
        {
            "id": source_id,
            "kind": "source",
            "lifecycle": "current",
            "observation_refs": [],
            "data": {
                "source_kind": "canonical_project_handoff",
                "authority": "other",
                "identity_locator": {"repository": repository, "path": source_path},
            },
        }
    )
    evidence_locator: dict[str, Any] = {"repository": repository, "path": source_path}
    evidence_state = "unversioned_observation"
    if source_commit:
        evidence_locator["commit"] = source_commit
        evidence_state = "immutable_snapshot"
    records.append(
        {
            "id": observation_id,
            "kind": "source_observation",
            "lifecycle": "historical",
            "observation_refs": [],
            "data": {
                "source_id": source_id,
                "evidence_state": evidence_state,
                "observed_at": generated_at,
                "evidence_locator": evidence_locator,
                "captured_fingerprint": "sha256:" + hashlib.sha256(_canonical_text(handoff).encode("utf-8")).hexdigest(),
            },
        }
    )

    project_id = _candidate_id("project", {"repository": repository})
    records.append(
        _record(
            project_id,
            "project",
            observation_id,
            {"name": project_name, "repository": repository, "summary": project_summary},
        )
    )

    for index, summary in enumerate(project_level.get("project_owner_expectations", []) or []):
        if not isinstance(summary, str) or not summary:
            raise HandoffImportError("invalid_expectation", f"project_owner_expectations[{index}] must be a non-empty string.")
        records.append(
            _record(
                _candidate_id("expectation", {"summary": summary}),
                "expectation",
                observation_id,
                {"summary": summary, "expectation_state": "active"},
            )
        )

    snapshot = _require_mapping(
        handoff.get("repository_snapshot", {}),
        "invalid_repository_snapshot",
        "repository_snapshot must be an object.",
    )
    ref = snapshot.get("ref")
    if isinstance(ref, str) and ref:
        records.append(
            _record(
                _candidate_id("branch", {"repository": repository, "name": ref}),
                "branch",
                observation_id,
                {
                    "repository": repository,
                    "name": ref,
                    "head_commit": snapshot.get("main_commit_sha") if isinstance(snapshot.get("main_commit_sha"), str) else None,
                },
            )
        )

    for index, module in enumerate(snapshot.get("modules", []) or []):
        module = _require_mapping(module, "invalid_module", f"repository_snapshot.modules[{index}] must be an object.")
        name = _require_string(module.get("name"), "invalid_module", f"module[{index}].name is required.")
        path = _require_string(module.get("path"), "invalid_module", f"module[{index}].path is required.")
        domain = _require_string(module.get("domain"), "invalid_module", f"module[{index}].domain is required.")
        records.append(
            _record(
                _candidate_id("module", {"path": path}),
                "module",
                observation_id,
                {"name": name, "path": path, "domain": domain, "public_role": f"Imported module in {domain}."},
            )
        )

    external_names: set[str] = set()
    for name in project_level.get("external_files_used_in_project_context", []) or []:
        if isinstance(name, str) and name:
            external_names.add(name)

    chats = handoff.get("chats", []) or []
    if not isinstance(chats, Sequence) or isinstance(chats, (str, bytes)):
        raise HandoffImportError("invalid_chats", "chats must be an array.")

    for index, chat in enumerate(chats):
        chat = _require_mapping(chat, "invalid_chat", f"chats[{index}] must be an object.")
        chat_key = _require_string(chat.get("chat_id"), "invalid_chat", f"chats[{index}].chat_id is required.")
        title = _require_string(chat.get("title"), "invalid_chat", f"chats[{index}].title is required.")
        summary = _require_string(chat.get("summary"), "invalid_chat", f"chats[{index}].summary is required.")
        role_text = _require_string(chat.get("role"), "invalid_chat", f"chats[{index}].role is required.")
        started_at, ended_at = _date_range(str(chat.get("date") or ""), generated_at)

        role_id = _candidate_id("role", {"chat_id": chat_key, "role": role_text})
        chat_id = _candidate_id("chat", {"chat_id": chat_key})
        records.append(
            _record(
                role_id,
                "role",
                observation_id,
                {
                    "name": role_text,
                    "responsibility": role_text,
                    "directive_source_id": source_id,
                },
            )
        )
        records.append(
            _record(
                chat_id,
                "chat",
                observation_id,
                {
                    "project_id": project_id,
                    "title": title,
                    "summary": summary,
                    "started_at": started_at,
                    "ended_at": ended_at,
                    "active_role_id": role_id,
                },
            )
        )

        high_value_ids = [chat_id, role_id]
        for decision_index, decision_summary in enumerate(chat.get("key_decisions_or_outcomes", []) or []):
            if not isinstance(decision_summary, str) or not decision_summary:
                raise HandoffImportError(
                    "invalid_chat_decision",
                    f"chats[{index}].key_decisions_or_outcomes[{decision_index}] must be a non-empty string.",
                )
            decision_id = _candidate_id(
                "decision",
                {"chat_id": chat_key, "summary": decision_summary},
            )
            records.append(
                _record(
                    decision_id,
                    "decision",
                    observation_id,
                    {"summary": decision_summary, "decision_state": "accepted", "rationale": None},
                )
            )
            high_value_ids.append(decision_id)

        continuation_id = _candidate_id("continuation", {"chat_id": chat_key})
        records.append(
            _record(
                continuation_id,
                "continuation",
                observation_id,
                {
                    "chat_id": chat_id,
                    "active_role_id": role_id,
                    "current_focus": summary,
                    "blocker_ids": [],
                    "pending_owner_decision_ids": [],
                    "high_value_record_ids": high_value_ids,
                },
            )
        )

        for name in chat.get("external_file_names_used", []) or []:
            if isinstance(name, str) and name:
                external_names.add(name)

    for name in sorted(external_names, key=lambda item: item.encode("utf-8")):
        records.append(
            _record(
                _candidate_id("external_file", {"name": name}),
                "external_file",
                observation_id,
                {"name": name, "purpose": "Imported supporting project/chat context.", "safe_locator": name},
            )
        )

    document = normalize_document(
        {
            "semantic": "pems/1",
            "project_id": project_id,
            "records": records,
            "relations": [],
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
    return ImportReport(document=document, provisional_ids=provisional_ids, source_observation_id=observation_id)


def load_and_import(path: str | Path, *, source_commit: str | None = None) -> ImportReport:
    with Path(path).open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, Mapping):
        raise HandoffImportError("invalid_root", "Current handoff root must be an object.")
    return import_handoff(value, source_commit=source_commit)


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert current canonical handoff JSON into noncanonical normalized PEMS evidence.")
    parser.add_argument("input", type=Path)
    parser.add_argument("--source-commit")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    try:
        report = load_and_import(args.input, source_commit=args.source_commit)
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
