from __future__ import annotations

import copy
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, MutableMapping, Sequence

from jsonschema import Draft202012Validator, FormatChecker
from jsonschema.exceptions import ValidationError


STAGE_ORDER = {
    "schema": 0,
    "semantic": 1,
    "normalization": 2,
    "admission": 3,
    "retention": 4,
}

SET_LIKE_KEYS = {
    "observation_refs",
    "supersedes",
    "superseded_by",
    "blocker_ids",
    "pending_owner_decision_ids",
    "high_value_record_ids",
}

SECRET_NAME_PATTERN = re.compile(
    r"(?:^|_)(?:TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|CREDENTIAL)(?:_|$)",
    re.IGNORECASE,
)

INTRINSIC_REFERENCE_RULES: dict[str, tuple[tuple[str, str | None, bool], ...]] = {
    "chat": (
        ("project_id", "project", False),
        ("active_role_id", "role", True),
    ),
    "role": (("directive_source_id", "source", False),),
    "database_column": (("table_id", "database_table", False),),
    "pull_request": (("head_branch_id", "branch", True),),
    "validation": (("target_id", None, False),),
    "architecture_adjustment": (("authority_target", "source", False),),
    "roadmap_adjustment": (("authority_target", "source", False),),
    "continuation": (
        ("chat_id", "chat", False),
        ("active_role_id", "role", False),
    ),
}

CONTINUATION_ARRAY_REFERENCE_RULES: dict[str, str | None] = {
    "blocker_ids": "unresolved_item",
    "pending_owner_decision_ids": "decision",
    "high_value_record_ids": None,
}


@dataclass(frozen=True, order=True)
class Diagnostic:
    stage: str
    code: str
    path: str
    message: str


@dataclass(frozen=True)
class ValidationResult:
    valid: bool
    diagnostics: tuple[Diagnostic, ...] = ()

    @property
    def first_code(self) -> str | None:
        return self.diagnostics[0].code if self.diagnostics else None


@dataclass(frozen=True)
class AdmissionDecision:
    valid: bool
    code: str
    canonical_id: str | None
    diagnostics: tuple[Diagnostic, ...] = ()


@dataclass(frozen=True)
class FixtureCaseResult:
    case_id: str
    passed: bool
    stage: str
    expected_code: str
    actual_code: str | None
    details: str = ""


class SchemaValidationError(RuntimeError):
    pass


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_schema_path() -> Path:
    return repo_root() / "docs" / "handoff" / "pems" / "pems-v1.schema.json"


def default_success_fixture_path() -> Path:
    return repo_root() / "docs" / "handoff" / "pems" / "fixtures" / "success" / "full-project.json"


def default_failure_fixture_path() -> Path:
    return repo_root() / "docs" / "handoff" / "pems" / "fixtures" / "failure-cases.json"


def load_json(path: str | Path) -> Any:
    with Path(path).open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _utf8_key(value: str) -> bytes:
    return value.encode("utf-8")


def _json_pointer(path: Iterable[Any]) -> str:
    parts = []
    for part in path:
        encoded = str(part).replace("~", "~0").replace("/", "~1")
        parts.append(encoded)
    return "/" + "/".join(parts) if parts else ""


def _diagnostic_sort_key(item: Diagnostic) -> tuple[int, bytes, bytes, bytes]:
    return (
        STAGE_ORDER.get(item.stage, 99),
        item.path.encode("utf-8"),
        item.code.encode("utf-8"),
        item.message.encode("utf-8"),
    )


def _sorted_diagnostics(items: Iterable[Diagnostic]) -> tuple[Diagnostic, ...]:
    return tuple(sorted(items, key=_diagnostic_sort_key))


def _value_at_path(instance: Any, path: Sequence[Any]) -> Any:
    current = instance
    for part in path:
        if isinstance(current, list):
            current = current[int(part)]
        else:
            current = current[part]
    return current


def _record_for_schema_path(document: Mapping[str, Any], path: Sequence[Any]) -> Mapping[str, Any] | None:
    if len(path) < 2 or path[0] != "records" or not isinstance(path[1], int):
        return None
    records = document.get("records", [])
    index = path[1]
    if 0 <= index < len(records):
        record = records[index]
        if isinstance(record, Mapping):
            return record
    return None


def _schema_error_code(document: Mapping[str, Any], error: ValidationError) -> str:
    path = list(error.absolute_path)
    leaf = path[-1] if path else None

    if path == ["semantic"]:
        return "unknown_semantic_profile"
    if leaf == "lifecycle":
        return "invalid_lifecycle"
    if leaf == "evidence_state":
        return "invalid_evidence_state"
    if isinstance(leaf, str) and leaf.endswith("_state"):
        return "invalid_type_state"
    if error.validator == "format":
        return "invalid_timestamp"

    record = _record_for_schema_path(document, path)
    if record and record.get("kind") == "environment_variable":
        data = record.get("data", {})
        if data.get("value_state") == "external_secret" and leaf == "value" and data.get("value") is not None:
            return "external_secret_contains_value"

    if error.validator == "required":
        return "required_field_absent"
    if error.instance is None and error.validator in {"type", "anyOf", "oneOf"}:
        return "required_field_null"
    if error.validator == "minLength" and error.instance == "":
        return "required_string_empty"
    return "schema_validation_failed"


def validate_schema(
    document: Mapping[str, Any],
    schema: Mapping[str, Any] | None = None,
    schema_path: str | Path | None = None,
) -> ValidationResult:
    if schema is None:
        schema = load_json(schema_path or default_schema_path())

    try:
        Draft202012Validator.check_schema(schema)
    except Exception as exc:  # pragma: no cover - repository contract corruption
        raise SchemaValidationError(f"Frozen PEMS schema is invalid: {exc}") from exc

    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    diagnostics: list[Diagnostic] = []
    for error in validator.iter_errors(document):
        path = _json_pointer(error.absolute_path)
        diagnostics.append(
            Diagnostic(
                stage="schema",
                code=_schema_error_code(document, error),
                path=path,
                message=error.message,
            )
        )
    diagnostics_tuple = _sorted_diagnostics(diagnostics)
    return ValidationResult(valid=not diagnostics_tuple, diagnostics=diagnostics_tuple)


def _build_unique_index(
    items: Sequence[Mapping[str, Any]],
    item_type: str,
) -> tuple[dict[str, Mapping[str, Any]], list[Diagnostic]]:
    index: dict[str, Mapping[str, Any]] = {}
    diagnostics: list[Diagnostic] = []
    duplicate_code = "duplicate_record_id" if item_type == "record" else "duplicate_relation_id"
    collection = "records" if item_type == "record" else "relations"
    for position, item in enumerate(items):
        item_id = item.get("id")
        if not isinstance(item_id, str):
            continue
        if item_id in index:
            diagnostics.append(
                Diagnostic(
                    stage="semantic",
                    code=duplicate_code,
                    path=f"/{collection}/{position}/id",
                    message=f"Duplicate {item_type} ID {item_id!r}.",
                )
            )
        else:
            index[item_id] = item
    return index, diagnostics


def _require_record_reference(
    diagnostics: list[Diagnostic],
    records_by_id: Mapping[str, Mapping[str, Any]],
    value: Any,
    path: str,
    expected_kind: str | None,
    missing_code: str = "dangling_intrinsic_reference",
    wrong_kind_code: str = "intrinsic_reference_wrong_kind",
) -> None:
    if value is None:
        return
    target = records_by_id.get(value)
    if target is None:
        diagnostics.append(
            Diagnostic("semantic", missing_code, path, f"Referenced record {value!r} does not exist.")
        )
        return
    if expected_kind is not None and target.get("kind") != expected_kind:
        diagnostics.append(
            Diagnostic(
                "semantic",
                wrong_kind_code,
                path,
                f"Referenced record {value!r} has kind {target.get('kind')!r}; expected {expected_kind!r}.",
            )
        )


def _validate_observation_refs(
    owner: Mapping[str, Any],
    owner_path: str,
    records_by_id: Mapping[str, Mapping[str, Any]],
    diagnostics: list[Diagnostic],
) -> None:
    for index, observation_id in enumerate(owner.get("observation_refs", [])):
        path = f"{owner_path}/observation_refs/{index}"
        target = records_by_id.get(observation_id)
        if target is None:
            diagnostics.append(
                Diagnostic(
                    "semantic",
                    "dangling_observation_ref",
                    path,
                    f"Observation reference {observation_id!r} does not resolve.",
                )
            )
        elif target.get("kind") != "source_observation":
            diagnostics.append(
                Diagnostic(
                    "semantic",
                    "observation_ref_wrong_kind",
                    path,
                    f"Observation reference {observation_id!r} targets {target.get('kind')!r}, not 'source_observation'.",
                )
            )


def _validate_supersession_collection(
    items: Sequence[Mapping[str, Any]],
    index: Mapping[str, Mapping[str, Any]],
    collection: str,
    diagnostics: list[Diagnostic],
) -> None:
    for position, item in enumerate(items):
        item_id = item.get("id")
        base_path = f"/{collection}/{position}"
        superseded_by = item.get("superseded_by", [])
        supersedes = item.get("supersedes", [])

        if item.get("lifecycle") == "superseded" and not superseded_by:
            diagnostics.append(
                Diagnostic(
                    "semantic",
                    "superseded_without_replacement",
                    f"{base_path}/superseded_by",
                    f"Superseded identity {item_id!r} must name at least one replacement.",
                )
            )

        for field_name, targets in (("supersedes", supersedes), ("superseded_by", superseded_by)):
            for target_position, target_id in enumerate(targets):
                target = index.get(target_id)
                path = f"{base_path}/{field_name}/{target_position}"
                if target is None:
                    diagnostics.append(
                        Diagnostic(
                            "semantic",
                            "invalid_supersession_reference",
                            path,
                            f"Supersession target {target_id!r} does not resolve in {collection}.",
                        )
                    )
                    continue
                if item.get("kind") != target.get("kind"):
                    diagnostics.append(
                        Diagnostic(
                            "semantic",
                            "supersession_kind_mismatch",
                            path,
                            f"Supersession crosses kinds {item.get('kind')!r} and {target.get('kind')!r}.",
                        )
                    )
                    continue
                reciprocal_field = "superseded_by" if field_name == "supersedes" else "supersedes"
                if item_id not in target.get(reciprocal_field, []):
                    diagnostics.append(
                        Diagnostic(
                            "semantic",
                            "supersession_not_reciprocal",
                            path,
                            f"Supersession link {item_id!r} -> {target_id!r} is not reciprocal.",
                        )
                    )


def validate_semantics(document: Mapping[str, Any]) -> ValidationResult:
    records = document.get("records", [])
    relations = document.get("relations", [])
    records_by_id, diagnostics = _build_unique_index(records, "record")
    relations_by_id, relation_duplicates = _build_unique_index(relations, "relation")
    diagnostics.extend(relation_duplicates)

    root_project_id = document.get("project_id")
    root_project = records_by_id.get(root_project_id)
    if root_project is None:
        diagnostics.append(
            Diagnostic(
                "semantic",
                "root_project_missing",
                "/project_id",
                f"Root project ID {root_project_id!r} does not resolve.",
            )
        )
    elif root_project.get("kind") != "project":
        diagnostics.append(
            Diagnostic(
                "semantic",
                "root_project_wrong_kind",
                "/project_id",
                f"Root project ID {root_project_id!r} does not target a project record.",
            )
        )

    for position, record in enumerate(records):
        base_path = f"/records/{position}"
        _validate_observation_refs(record, base_path, records_by_id, diagnostics)
        kind = record.get("kind")
        data = record.get("data", {})

        for field_name, expected_kind, nullable in INTRINSIC_REFERENCE_RULES.get(kind, ()):
            value = data.get(field_name)
            if value is None and nullable:
                continue
            _require_record_reference(
                diagnostics,
                records_by_id,
                value,
                f"{base_path}/data/{field_name}",
                expected_kind,
            )

        if kind == "continuation":
            for field_name, expected_kind in CONTINUATION_ARRAY_REFERENCE_RULES.items():
                for ref_index, value in enumerate(data.get(field_name, [])):
                    _require_record_reference(
                        diagnostics,
                        records_by_id,
                        value,
                        f"{base_path}/data/{field_name}/{ref_index}",
                        expected_kind,
                    )

        if kind == "source_observation":
            source_id = data.get("source_id")
            source = records_by_id.get(source_id)
            if source is None:
                diagnostics.append(
                    Diagnostic(
                        "semantic",
                        "observation_source_missing",
                        f"{base_path}/data/source_id",
                        f"Observation source {source_id!r} does not resolve.",
                    )
                )
            elif source.get("kind") != "source":
                diagnostics.append(
                    Diagnostic(
                        "semantic",
                        "observation_source_wrong_kind",
                        f"{base_path}/data/source_id",
                        f"Observation source {source_id!r} targets {source.get('kind')!r}, not 'source'.",
                    )
                )

        if kind == "environment_variable":
            name = data.get("name", "")
            if data.get("value_state") == "literal" and SECRET_NAME_PATTERN.search(name):
                diagnostics.append(
                    Diagnostic(
                        "semantic",
                        "literal_secret_disallowed",
                        f"{base_path}/data/value_state",
                        f"Credential-like environment variable {name!r} cannot use durable literal storage.",
                    )
                )

    for position, relation in enumerate(relations):
        base_path = f"/relations/{position}"
        _validate_observation_refs(relation, base_path, records_by_id, diagnostics)
        for field_name in ("from", "to"):
            target_id = relation.get(field_name)
            if target_id not in records_by_id:
                diagnostics.append(
                    Diagnostic(
                        "semantic",
                        "dangling_relation_endpoint",
                        f"{base_path}/{field_name}",
                        f"Relation endpoint {target_id!r} does not resolve to a record.",
                    )
                )

    _validate_supersession_collection(records, records_by_id, "records", diagnostics)
    _validate_supersession_collection(relations, relations_by_id, "relations", diagnostics)

    diagnostics_tuple = _sorted_diagnostics(diagnostics)
    return ValidationResult(valid=not diagnostics_tuple, diagnostics=diagnostics_tuple)


def _dedupe_sort_strings(values: Sequence[str]) -> list[str]:
    return sorted(set(values), key=_utf8_key)


def _normalize_value(value: Any, parent_key: str | None = None) -> Any:
    if isinstance(value, Mapping):
        normalized: dict[str, Any] = {}
        for key, item in value.items():
            normalized[key] = _normalize_value(item, key)
        return normalized
    if isinstance(value, list):
        normalized_items = [_normalize_value(item, None) for item in value]
        if parent_key in SET_LIKE_KEYS and all(isinstance(item, str) for item in normalized_items):
            return _dedupe_sort_strings(normalized_items)
        return normalized_items
    return copy.deepcopy(value)


def normalize_document(document: Mapping[str, Any]) -> dict[str, Any]:
    normalized = _normalize_value(document)
    normalized["records"] = sorted(normalized.get("records", []), key=lambda item: _utf8_key(item["id"]))
    normalized["relations"] = sorted(normalized.get("relations", []), key=lambda item: _utf8_key(item["id"]))
    return normalized


def _freeze_identity_value(value: Any) -> Any:
    if isinstance(value, Mapping):
        return tuple(
            (key, _freeze_identity_value(value[key]))
            for key in sorted(value.keys(), key=_utf8_key)
        )
    if isinstance(value, list):
        return tuple(_freeze_identity_value(item) for item in value)
    return value


def semantic_identity(record: Mapping[str, Any]) -> tuple[Any, ...]:
    kind = record.get("kind")
    data = record.get("data", {})

    if kind == "project":
        value = (data.get("repository"),)
    elif kind == "chat":
        value = (data.get("project_id"), data.get("title"), data.get("started_at"))
    elif kind == "role":
        value = (data.get("name"), data.get("directive_source_id"))
    elif kind in {"expectation", "requirement", "decision", "unresolved_item"}:
        value = (data.get("summary"),)
    elif kind == "external_file":
        value = (data.get("safe_locator") or data.get("name"),)
    elif kind == "module":
        value = (data.get("path"),)
    elif kind == "environment_variable":
        value = (data.get("name"),)
    elif kind == "database_table":
        value = (data.get("name"),)
    elif kind == "database_column":
        value = (data.get("table_id"), data.get("name"))
    elif kind == "branch":
        value = (data.get("repository"), data.get("name"))
    elif kind == "pull_request":
        value = (data.get("repository"), data.get("number"))
    elif kind == "validation":
        value = (data.get("target_id"), data.get("summary"))
    elif kind in {"architecture_adjustment", "roadmap_adjustment"}:
        value = (data.get("authority_target"), data.get("summary"))
    elif kind == "continuation":
        value = (data.get("chat_id"),)
    elif kind == "source":
        value = (data.get("source_kind"), _freeze_identity_value(data.get("identity_locator", {})))
    elif kind == "source_observation":
        value = (
            data.get("source_id"),
            data.get("evidence_state"),
            data.get("observed_at"),
            _freeze_identity_value(data.get("evidence_locator", {})),
        )
    else:
        value = (_freeze_identity_value(data),)
    return (kind, *value)


def _is_provisional_id(candidate_id: str) -> bool:
    return candidate_id.startswith("candidate:") or candidate_id.startswith("import:")


def admit_candidate(
    candidate: Mapping[str, Any],
    canonical_records: Sequence[Mapping[str, Any]],
) -> AdmissionDecision:
    candidate_id = candidate.get("id")
    if not isinstance(candidate_id, str):
        diagnostic = Diagnostic("admission", "candidate_id_missing", "/id", "Candidate ID must be a string.")
        return AdmissionDecision(False, diagnostic.code, None, (diagnostic,))

    candidate_identity = semantic_identity(candidate)
    by_id = {record.get("id"): record for record in canonical_records if isinstance(record.get("id"), str)}

    existing_same_id = by_id.get(candidate_id)
    if existing_same_id is not None:
        if semantic_identity(existing_same_id) == candidate_identity:
            return AdmissionDecision(True, "reuse_existing_id", candidate_id)
        code = "immutable_observation_rebound" if candidate.get("kind") == "source_observation" else "canonical_id_collision"
        diagnostic = Diagnostic(
            "admission",
            code,
            "/id",
            f"Canonical ID {candidate_id!r} is already bound to a different semantic identity.",
        )
        return AdmissionDecision(False, code, candidate_id, (diagnostic,))

    same_identity = [
        record
        for record in canonical_records
        if semantic_identity(record) == candidate_identity
    ]
    if same_identity:
        existing = sorted(same_identity, key=lambda item: _utf8_key(item["id"]))[0]
        canonical_id = existing["id"]
        if _is_provisional_id(candidate_id):
            return AdmissionDecision(True, "reuse_existing_id", canonical_id)
        diagnostic = Diagnostic(
            "admission",
            "duplicate_semantic_identity",
            "/id",
            f"Semantic identity already exists as {canonical_id!r}; parallel canonical-looking ID {candidate_id!r} is not admitted.",
        )
        return AdmissionDecision(False, diagnostic.code, canonical_id, (diagnostic,))

    return AdmissionDecision(True, "candidate_requires_steward_confirmation", candidate_id)


def validate_retention_operation(
    document: Mapping[str, Any],
    operation: Mapping[str, Any],
    approved_policy_ids: Iterable[str] = (),
) -> ValidationResult:
    remove_ids = operation.get("remove_record_ids", [])
    if not remove_ids:
        return ValidationResult(True)

    policy_id = operation.get("retention_policy_id")
    if not policy_id:
        diagnostic = Diagnostic(
            "retention",
            "retention_policy_required",
            "/retention_policy_id",
            "Destructive historical compaction requires an explicit Steward retention policy.",
        )
        return ValidationResult(False, (diagnostic,))

    if policy_id not in set(approved_policy_ids):
        diagnostic = Diagnostic(
            "retention",
            "retention_policy_not_approved",
            "/retention_policy_id",
            f"Retention policy {policy_id!r} is not in the caller-supplied approved policy set.",
        )
        return ValidationResult(False, (diagnostic,))

    records_by_id = {record.get("id"): record for record in document.get("records", [])}
    diagnostics = []
    for index, record_id in enumerate(remove_ids):
        if record_id not in records_by_id:
            diagnostics.append(
                Diagnostic(
                    "retention",
                    "retention_target_missing",
                    f"/remove_record_ids/{index}",
                    f"Retention target {record_id!r} does not resolve.",
                )
            )
    diagnostics_tuple = _sorted_diagnostics(diagnostics)
    return ValidationResult(not diagnostics_tuple, diagnostics_tuple)


def _decode_pointer_token(token: str) -> str:
    return token.replace("~1", "/").replace("~0", "~")


def _resolve_patch_parent(document: Any, pointer: str) -> tuple[Any, str]:
    if not pointer.startswith("/"):
        raise ValueError(f"RFC 6902 path must start with '/': {pointer!r}")
    tokens = [_decode_pointer_token(token) for token in pointer.split("/")[1:]]
    if not tokens:
        raise ValueError("Root replacement is not required by the frozen fixture suite.")
    current = document
    for token in tokens[:-1]:
        if isinstance(current, list):
            current = current[int(token)]
        else:
            current = current[token]
    return current, tokens[-1]


def apply_json_patch(document: Any, patch: Sequence[Mapping[str, Any]]) -> Any:
    result = copy.deepcopy(document)
    for operation in patch:
        op = operation["op"]
        parent, token = _resolve_patch_parent(result, operation["path"])
        if op == "add":
            value = copy.deepcopy(operation["value"])
            if isinstance(parent, list):
                if token == "-":
                    parent.append(value)
                else:
                    parent.insert(int(token), value)
            else:
                parent[token] = value
        elif op == "replace":
            value = copy.deepcopy(operation["value"])
            if isinstance(parent, list):
                parent[int(token)] = value
            else:
                if token not in parent:
                    raise KeyError(operation["path"])
                parent[token] = value
        elif op == "remove":
            if isinstance(parent, list):
                del parent[int(token)]
            else:
                del parent[token]
        else:
            raise ValueError(f"Unsupported RFC 6902 operation in frozen fixture suite: {op!r}")
    return result


def _first_matching_code(result: ValidationResult, expected_code: str) -> str | None:
    for diagnostic in result.diagnostics:
        if diagnostic.code == expected_code:
            return diagnostic.code
    return result.first_code


def _reverse_set_arrays(value: Any, parent_key: str | None = None) -> Any:
    if isinstance(value, Mapping):
        return {key: _reverse_set_arrays(item, key) for key, item in value.items()}
    if isinstance(value, list):
        items = [_reverse_set_arrays(item, None) for item in value]
        if parent_key in SET_LIKE_KEYS:
            return list(reversed(items))
        return items
    return copy.deepcopy(value)


def _reordered_document(document: Mapping[str, Any]) -> dict[str, Any]:
    result = _reverse_set_arrays(document)
    result["records"] = list(reversed(result.get("records", [])))
    result["relations"] = list(reversed(result.get("relations", [])))
    return result


def _normalization_states_remain_distinct(inputs: Sequence[Any]) -> bool:
    normalized = [_normalize_value(value) for value in inputs]
    for left_index, left in enumerate(normalized):
        for right in normalized[left_index + 1 :]:
            if left == right:
                return False
    return True


def run_fixture_suite(
    success_path: str | Path | None = None,
    failure_path: str | Path | None = None,
    schema_path: str | Path | None = None,
) -> tuple[FixtureCaseResult, ...]:
    success = load_json(success_path or default_success_fixture_path())
    suite = load_json(failure_path or default_failure_fixture_path())
    schema = load_json(schema_path or default_schema_path())
    results: list[FixtureCaseResult] = []

    success_schema = validate_schema(success, schema=schema)
    results.append(
        FixtureCaseResult(
            "success-schema",
            success_schema.valid,
            "schema",
            "valid",
            "valid" if success_schema.valid else success_schema.first_code,
        )
    )
    success_semantic = validate_semantics(success) if success_schema.valid else ValidationResult(False)
    results.append(
        FixtureCaseResult(
            "success-semantic",
            success_semantic.valid,
            "semantic",
            "valid",
            "valid" if success_semantic.valid else success_semantic.first_code,
        )
    )

    if success_schema.valid and success_semantic.valid:
        normalized = normalize_document(success)
        idempotent = normalize_document(normalized) == normalized
        results.append(
            FixtureCaseResult(
                "normalization-idempotence",
                idempotent,
                "normalization",
                "idempotent",
                "idempotent" if idempotent else "non_idempotent",
            )
        )
        traversal_independent = normalize_document(_reordered_document(success)) == normalized
        results.append(
            FixtureCaseResult(
                "normalization-traversal-independence",
                traversal_independent,
                "normalization",
                "traversal_independent",
                "traversal_independent" if traversal_independent else "traversal_dependent",
            )
        )

    records_by_id = {record["id"]: record for record in success.get("records", [])}

    for case in suite.get("cases", []):
        case_id = case["id"]
        expected = case["expected"]
        expected_valid = expected["valid"]
        expected_stage = expected["stage"]
        expected_code = expected["code"]
        mode = case["mode"]

        actual_valid = False
        actual_code: str | None = None
        details = ""

        if mode == "document_patch":
            patched = apply_json_patch(success, case["patch"])
            if expected_stage == "schema":
                validation = validate_schema(patched, schema=schema)
            elif expected_stage == "semantic":
                structural = validate_schema(patched, schema=schema)
                if not structural.valid:
                    validation = structural
                    details = "Expected semantic-stage failure but schema validation failed first."
                else:
                    validation = validate_semantics(patched)
            else:
                validation = ValidationResult(False, (
                    Diagnostic(expected_stage, "unsupported_fixture_stage", "", f"Unsupported fixture stage {expected_stage!r}."),
                ))
            actual_valid = validation.valid
            actual_code = _first_matching_code(validation, expected_code)
        elif mode == "admission":
            canonical_id = case.get("canonical_record_id")
            canonical_records = [records_by_id[canonical_id]] if canonical_id else []
            decision = admit_candidate(case["candidate_record"], canonical_records)
            actual_valid = decision.valid
            actual_code = decision.code
            if expected.get("canonical_id") != decision.canonical_id:
                details = f"Expected canonical ID {expected.get('canonical_id')!r}, got {decision.canonical_id!r}."
        elif mode == "retention":
            validation = validate_retention_operation(success, case["operation"])
            actual_valid = validation.valid
            actual_code = _first_matching_code(validation, expected_code)
        elif mode == "normalization_invariant":
            actual_valid = _normalization_states_remain_distinct(case["inputs"])
            actual_code = "states_remain_distinct" if actual_valid else "states_collapsed"
        else:
            actual_code = "unsupported_fixture_mode"
            details = f"Unsupported fixture mode {mode!r}."

        canonical_ok = not details
        passed = (
            actual_valid == expected_valid
            and actual_code == expected_code
            and canonical_ok
        )
        results.append(
            FixtureCaseResult(
                case_id=case_id,
                passed=passed,
                stage=expected_stage,
                expected_code=expected_code,
                actual_code=actual_code,
                details=details,
            )
        )

    return tuple(results)
