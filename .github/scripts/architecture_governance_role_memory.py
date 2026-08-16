from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
CANONICAL = ROOT / "docs/project-chat-handoff.cove.json"
DERIVATIVE = ROOT / "docs/project-chat-handoff.json"
EVIDENCE = ROOT / "docs/handoff/pems/architecture-governance-role-memory.evidence.json"
ACCEPTED_REF = "origin/pems-phase8-remediation"
OWNER_INSTRUCTION_ID = "owner:architecture-governance-role-memory:2026-08-15"
OBSERVED_AT = "2026-08-15T21:11:58-07:00"
HISTORICAL_ROLE_ID = "pems:role:96953bd2d91f10def711"
CHAT_ID = "pems:chat:c55923a23d38b4ef7955"
CONTINUATION_ID = "pems:continuation:c55923a23d38b4ef7955"

ROLE_NAME = "Project Architecture and Governance Mentor"
ROLE_RESPONSIBILITY = (
    "Ongoing architectural mentorship and project governance: review completed milestones and current main; "
    "assess engineering and architectural quality; maintain ADR and roadmap coherence; review proposed work; "
    "mentor implementation agents as capable professionals; identify evidence-driven next priorities. Planning "
    "communicates problems, evidence, constraints, architectural boundaries, desired outcomes, and unresolved "
    "questions without prescribing implementation details unless specifically requested."
)
CURRENT_FOCUS = (
    "Provide ongoing architecture and governance mentorship by reviewing completed milestones and current main, "
    "assessing engineering and architectural quality, maintaining ADR and roadmap coherence, reviewing proposed "
    "work, mentoring implementation agents as capable professionals, and identifying evidence-driven next "
    "priorities. Communicate problems, evidence, constraints, architectural boundaries, desired outcomes, and "
    "unresolved questions without prescribing implementation details unless specifically requested."
)
CHAT_SUMMARY = (
    "Primary architecture-governance thread. Historically reviewed prior work as an engineering mentor, assessed "
    "engineering behavior, established ADR/roadmap recording, and reviewed planning proposals. It now continues "
    "under the Project Architecture and Governance Mentor role for evidence-driven architectural mentorship and "
    "project governance while preserving the historical role record and terminology."
)


def run(*args: str) -> str:
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def materialize_accepted(path: str, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    content = subprocess.check_output(["git", "show", f"{ACCEPTED_REF}:{path}"], cwd=ROOT)
    target.write_bytes(content)


def import_from(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def semantic_id(kind: str, identity: str) -> str:
    digest = hashlib.sha256((kind + "\0" + identity).encode("utf-8")).hexdigest()[:20]
    return f"pems:{kind}:{digest}"


def assert_unique_new_id(records_by_id: dict[str, dict], record_id: str, semantic_name: str) -> None:
    if record_id in records_by_id:
        raise RuntimeError(f"identity collision for {semantic_name}: {record_id}")


def main() -> None:
    # Complete-source identity: bind generation to the exact checked-out canonical blob before mutation.
    base_commit = run("git", "rev-parse", "HEAD")
    base_cove_blob = run("git", "hash-object", str(CANONICAL.relative_to(ROOT)))
    base_derivative_blob = run("git", "hash-object", str(DERIVATIVE.relative_to(ROOT)))
    canonical_bytes = CANONICAL.read_bytes()
    derivative_bytes = DERIVATIVE.read_bytes()

    tmp = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "accepted-pems-cove"
    materialize_accepted("tools/cove/cove_v1.py", tmp / "cove_v1.py")
    materialize_accepted("tools/cove/jcs_v1.py", tmp / "jcs_v1.py")
    materialize_accepted("tools/pems/pems_v1.py", tmp / "pems_v1.py")

    cove = import_from(tmp / "cove_v1.py", "accepted_cove_v1")
    jcs = import_from(tmp / "jcs_v1.py", "accepted_jcs_v1")
    pems = import_from(tmp / "pems_v1.py", "accepted_pems_v1")

    artifact = jcs.parse_canonical(canonical_bytes)
    if artifact.get("c") != "cove/1" or artifact.get("p") != "pems/1" or artifact.get("s") != "jcs/1":
        raise RuntimeError("canonical envelope contract mismatch")
    expanded = cove.decode(artifact, supported_profiles={"pems/1"})
    if jcs.canonicalize(expanded) != derivative_bytes:
        raise RuntimeError("existing compatibility derivative is not deterministic decode of canonical COVE")

    schema = json.loads((ROOT / "docs/handoff/pems/pems-v1.schema.json").read_text(encoding="utf-8"))
    before_schema = pems.validate_schema(expanded, schema=schema)
    before_semantic = pems.validate_semantics(expanded)
    if not before_schema.valid or not before_semantic.valid:
        raise RuntimeError(f"base canonical PEMS invalid: schema={before_schema.diagnostics} semantic={before_semantic.diagnostics}")

    before = copy.deepcopy(expanded)
    records = expanded["records"]
    records_by_id = {r["id"]: r for r in records}
    original_ids = set(records_by_id)
    historical_role_before = copy.deepcopy(records_by_id[HISTORICAL_ROLE_ID])

    role_id = semantic_id("role", ROLE_NAME)
    source_id = semantic_id("source", OWNER_INSTRUCTION_ID)
    observation_id = semantic_id("source_observation", OWNER_INSTRUCTION_ID + "\0attestation")

    existing_named_roles = [
        r for r in records
        if r.get("kind") == "role" and r.get("data", {}).get("name") == ROLE_NAME
    ]
    already_applied = bool(existing_named_roles)

    if not already_applied:
        assert_unique_new_id(records_by_id, role_id, ROLE_NAME)
        assert_unique_new_id(records_by_id, source_id, OWNER_INSTRUCTION_ID)
        assert_unique_new_id(records_by_id, observation_id, OWNER_INSTRUCTION_ID + " attestation")

        source_record = {
            "id": source_id,
            "kind": "source",
            "lifecycle": "current",
            "observation_refs": [],
            "data": {
                "source_kind": "owner_instruction",
                "authority": "owner_instruction",
                "identity_locator": {"owner_instruction_id": OWNER_INSTRUCTION_ID},
            },
        }
        observation_record = {
            "id": observation_id,
            "kind": "source_observation",
            "lifecycle": "current",
            "observation_refs": [],
            "data": {
                "source_id": source_id,
                "evidence_state": "owner_attestation",
                "observed_at": OBSERVED_AT,
                "evidence_locator": {"owner_instruction_id": OWNER_INSTRUCTION_ID},
            },
        }
        role_record = {
            "id": role_id,
            "kind": "role",
            "lifecycle": "current",
            "observation_refs": [observation_id],
            "data": {
                "name": ROLE_NAME,
                "responsibility": ROLE_RESPONSIBILITY,
                "directive_source_id": source_id,
            },
        }
        records.extend([source_record, observation_record, role_record])

        chat = records_by_id[CHAT_ID]
        chat["data"]["active_role_id"] = role_id
        chat["data"]["ended_at"] = None
        chat["data"]["summary"] = CHAT_SUMMARY
        chat["observation_refs"] = sorted(set(chat.get("observation_refs", [])) | {observation_id})

        continuation = records_by_id[CONTINUATION_ID]
        continuation["data"]["active_role_id"] = role_id
        continuation["data"]["current_focus"] = CURRENT_FOCUS
        continuation["data"]["high_value_record_ids"] = sorted(
            set(continuation["data"].get("high_value_record_ids", [])) | {role_id, HISTORICAL_ROLE_ID}
        )
        continuation["observation_refs"] = sorted(set(continuation.get("observation_refs", [])) | {observation_id})

    normalized = pems.normalize_document(expanded)
    records_after = {r["id"]: r for r in normalized["records"]}

    # Historical preservation: every prior identity remains, and the old role bytes/meaning are untouched.
    missing = sorted(original_ids - set(records_after))
    if missing:
        raise RuntimeError(f"historical preservation failure, missing IDs: {missing}")
    if records_after[HISTORICAL_ROLE_ID] != historical_role_before:
        raise RuntimeError("historical architecture-mentor role was rewritten")

    after_schema = pems.validate_schema(normalized, schema=schema)
    after_semantic = pems.validate_semantics(normalized)
    if not after_schema.valid or not after_semantic.valid:
        raise RuntimeError(f"updated PEMS invalid: schema={after_schema.diagnostics} semantic={after_semantic.diagnostics}")

    new_artifact = cove.encode(normalized, profile="pems/1", serializer="jcs/1")
    new_cove_bytes = jcs.serialize_cove(new_artifact)
    roundtrip_artifact = jcs.parse_canonical(new_cove_bytes)
    roundtrip = cove.decode(roundtrip_artifact, supported_profiles={"pems/1"})
    if roundtrip != normalized:
        raise RuntimeError("COVE semantic round trip failed")
    if jcs.serialize_cove(cove.encode(normalized, profile="pems/1", serializer="jcs/1")) != new_cove_bytes:
        raise RuntimeError("canonical COVE regeneration is nondeterministic")

    new_derivative_bytes = jcs.canonicalize(roundtrip)
    if jcs.canonicalize(roundtrip) != new_derivative_bytes:
        raise RuntimeError("compatibility derivative regeneration is nondeterministic")

    CANONICAL.write_bytes(new_cove_bytes)
    DERIVATIVE.write_bytes(new_derivative_bytes)

    evidence = {
        "status": "validated_proposed_canonical_memory_change",
        "branch": "architecture-governance-role-memory",
        "base_commit": base_commit,
        "complete_source": {
            "canonical_path": str(CANONICAL.relative_to(ROOT)),
            "canonical_blob_sha": base_cove_blob,
            "derivative_blob_sha": base_derivative_blob,
            "prechange_decode_matches_derivative": True,
        },
        "accepted_tooling_ref": ACCEPTED_REF,
        "contracts": {"pems": "pems/1", "cove": "cove/1", "serializer": "jcs/1"},
        "semantic_changes": {
            "added_ids": sorted(set(records_after) - original_ids),
            "new_role_id": role_id,
            "owner_source_id": source_id,
            "owner_observation_id": observation_id,
            "updated_chat_id": CHAT_ID,
            "updated_continuation_id": CONTINUATION_ID,
            "preserved_historical_role_id": HISTORICAL_ROLE_ID,
            "preserved_historical_role_exact": True,
        },
        "validation": {
            "base_schema": before_schema.valid,
            "base_semantic": before_semantic.valid,
            "updated_schema": after_schema.valid,
            "updated_semantic": after_semantic.valid,
            "all_original_ids_preserved": not missing,
            "cove_round_trip": True,
            "cove_repeated_bytes_identical": True,
            "derivative_repeated_bytes_identical": True,
        },
        "counts": {"before_records": len(before["records"]), "after_records": len(normalized["records"])},
        "hashes": {
            "canonical_sha256": hashlib.sha256(new_cove_bytes).hexdigest(),
            "derivative_sha256": hashlib.sha256(new_derivative_bytes).hexdigest(),
            "canonical_bytes": len(new_cove_bytes),
            "derivative_bytes": len(new_derivative_bytes),
        },
        "merge_state": "not_merged",
    }
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print(json.dumps(evidence, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
