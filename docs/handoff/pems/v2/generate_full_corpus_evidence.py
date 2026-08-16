#!/usr/bin/env python3
"""Generate deterministic noncanonical PEMS/2 full-corpus migration evidence.

This script is intentionally evidence-only. It reads the Steward-admitted
174-record PEMS/1 canonical state, verifies the exact accepted source bytes,
performs the frozen draft migration transform, validates the migrated corpus,
and writes noncanonical evidence artifacts under docs/handoff/pems/v2/.

It MUST NOT modify canonical PEMS/1/COVE files or imply PEMS/2 cutover.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from jsonschema import Draft202012Validator

from validate_pems2_contract import (
    ADMISSION_FIXTURES,
    FIXTURES,
    SCHEMA,
    canonical_json,
    classify_admission_case,
    classify_case,
    migrate_v1_to_v2,
)

ROOT = Path(__file__).resolve().parents[4]
V2 = Path(__file__).resolve().parent
SOURCE_DERIVATIVE = ROOT / "docs/project-chat-handoff.json"
SOURCE_COVE = ROOT / "docs/project-chat-handoff.cove.json"
OUT_MIGRATED = V2 / "FULL_CORPUS_PEMS2.json"
OUT_EVIDENCE = V2 / "FULL_CORPUS_MIGRATION_EVIDENCE.json"
OUT_HUMAN = V2 / "FULL_CORPUS_HUMAN_RECONSTRUCTION.md"

EXPECTED_SOURCE_RECORDS = 174
EXPECTED_COVE_SHA256 = "54bc0549b07ad3b7d2dd678eca64f00585f955d9a65829a33d86c6e552d3a47c"
EXPECTED_DERIVATIVE_SHA256 = "ba3403715bcc0e1c62939e351cb816d9e50b5c3f0624866ebdf48ce4c76b4344"
STEWARD_AUTHORITY_RECORD = "STEWARD-20260816-022"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_item_map(doc: dict) -> dict[str, dict]:
    return {x["id"]: x for x in list(doc["records"]) + list(doc["relations"])}


def verify_identity_and_history(source: dict, migrated: dict) -> dict:
    src = source_item_map(source)
    dst = source_item_map(migrated)
    assert set(src) == set(dst), "semantic identity set changed"

    lifecycle_mismatches = []
    data_mismatches = []
    provenance_mismatches = []
    for sid in sorted(src):
        a, b = src[sid], dst[sid]
        if a.get("lifecycle") != b.get("lifecycle"):
            lifecycle_mismatches.append(sid)
        if a.get("data") != b.get("data"):
            data_mismatches.append(sid)

        refs = a.get("observation_refs", [])
        expected = {"untyped": sorted(refs)} if refs else None
        actual = b.get("provenance")
        if expected != actual:
            provenance_mismatches.append(sid)
        assert "observation_refs" not in b

    assert not lifecycle_mismatches, lifecycle_mismatches
    assert not data_mismatches, data_mismatches
    assert not provenance_mismatches, provenance_mismatches

    return {
        "source_identity_count": len(src),
        "migrated_identity_count": len(dst),
        "identity_sets_identical": True,
        "lifecycle_preserved": True,
        "record_data_preserved": True,
        "observation_refs_moved_only_to_provenance_untyped": True,
        "typed_provenance_inferred": False,
    }


def verify_source_observations(source: dict, migrated: dict) -> dict:
    src = {x["id"]: x for x in source["records"] if x["kind"] == "source_observation"}
    dst = {x["id"]: x for x in migrated["records"] if x["kind"] == "source_observation"}
    assert src.keys() == dst.keys()
    for sid in src:
        assert src[sid]["data"] == dst[sid]["data"]
        assert src[sid]["lifecycle"] == dst[sid]["lifecycle"]
    return {
        "source_observation_count": len(src),
        "ids_preserved": True,
        "evidence_locator_and_fingerprint_data_preserved": True,
        "lifecycle_preserved": True,
    }


def verify_relations(source: dict, migrated: dict) -> dict:
    src = {x["id"]: x for x in source["relations"]}
    dst = {x["id"]: x for x in migrated["relations"]}
    assert src.keys() == dst.keys()
    legacy_depends = 0
    for rid, rel in src.items():
        m = dst[rid]
        assert rel["kind"] == m["kind"]
        assert rel.get("from") == m.get("from")
        assert rel.get("to") == m.get("to")
        assert rel.get("lifecycle") == m.get("lifecycle")
        if rel["kind"] == "depends_on":
            legacy_depends += 1
            assert m.get("data", {}).get("dependency_kind") == "legacy_untyped"
    return {
        "relation_count": len(src),
        "relationship_identity_and_endpoints_preserved": True,
        "legacy_depends_on_count": legacy_depends,
        "legacy_depends_on_migrated_only_as_legacy_untyped": True,
    }


def evaluate_policy_fixtures() -> dict:
    compatibility_suite = json.loads(FIXTURES.read_text())
    admission_suite = json.loads(ADMISSION_FIXTURES.read_text())

    compatibility = []
    for case in compatibility_suite["cases"]:
        actual = classify_case(case)
        assert actual == case["expected"], case["id"]
        compatibility.append({"id": case["id"], "actual": actual})

    admission = []
    for case in admission_suite["cases"]:
        actual = classify_admission_case(case)
        assert actual == case["expected"], case["id"]
        admission.append({"id": case["id"], "actual": actual})

    lifecycle_negative_ids = [
        x["id"] for x in compatibility_suite["cases"]
        if x["category"] == "domain_export" and not x["expected"].get("exportable", False)
    ]
    return {
        "compatibility_cases": len(compatibility),
        "compatibility_all_passed": True,
        "admission_cases": len(admission),
        "admission_all_passed": True,
        "rgp_lifecycle_state_negative_case_ids": lifecycle_negative_ids,
        "policy_results_sha256": sha256_bytes(canonical_json({"compatibility": compatibility, "admission": admission})),
    }


def human_reconstruction(doc: dict) -> bytes:
    lines = [
        "# Noncanonical PEMS/2 Full-Corpus Reconstruction",
        "",
        f"Semantic: `{doc['semantic']}`",
        f"Project: `{doc['project_id']}`",
        f"Records: {len(doc['records'])}",
        f"Relations: {len(doc['relations'])}",
        "",
        "## Records",
        "",
    ]
    for item in sorted(doc["records"], key=lambda x: x["id"]):
        lines.append(f"### `{item['id']}`")
        lines.append(f"- kind: `{item['kind']}`")
        lines.append(f"- lifecycle: `{item['lifecycle']}`")
        if item.get("provenance"):
            lines.append(f"- provenance: `{json.dumps(item['provenance'], sort_keys=True, separators=(',', ':'))}`")
        lines.append(f"- data: `{json.dumps(item['data'], sort_keys=True, separators=(',', ':'), ensure_ascii=False)}`")
        lines.append("")
    lines.extend(["## Relations", ""])
    for item in sorted(doc["relations"], key=lambda x: x["id"]):
        lines.append(f"### `{item['id']}`")
        lines.append(f"- kind: `{item['kind']}`")
        lines.append(f"- from: `{item['from']}`")
        lines.append(f"- to: `{item['to']}`")
        lines.append(f"- lifecycle: `{item['lifecycle']}`")
        if item.get("provenance"):
            lines.append(f"- provenance: `{json.dumps(item['provenance'], sort_keys=True, separators=(',', ':'))}`")
        lines.append(f"- data: `{json.dumps(item.get('data', {}), sort_keys=True, separators=(',', ':'), ensure_ascii=False)}`")
        lines.append("")
    return ("\n".join(lines) + "\n").encode("utf-8")


def main() -> None:
    source_derivative_bytes = SOURCE_DERIVATIVE.read_bytes()
    source_cove_bytes = SOURCE_COVE.read_bytes()
    assert sha256_bytes(source_derivative_bytes) == EXPECTED_DERIVATIVE_SHA256
    assert sha256_bytes(source_cove_bytes) == EXPECTED_COVE_SHA256

    source = json.loads(source_derivative_bytes)
    assert source["semantic"] == "pems/1"
    assert len(source["records"]) + len(source["relations"]) == EXPECTED_SOURCE_RECORDS

    first = migrate_v1_to_v2(source)
    second = migrate_v1_to_v2(copy.deepcopy(source))
    first_bytes = canonical_json(first)
    second_bytes = canonical_json(second)
    assert first_bytes == second_bytes

    schema = json.loads(SCHEMA.read_text())
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema).validate(first)

    identity = verify_identity_and_history(source, first)
    source_obs = verify_source_observations(source, first)
    relations = verify_relations(source, first)
    policies = evaluate_policy_fixtures()

    human_first = human_reconstruction(first)
    human_second = human_reconstruction(second)
    assert human_first == human_second

    typed_roles = {"primary", "corroborating", "context"}
    assert all(not (typed_roles & set(x.get("provenance", {}))) for x in first["records"] + first["relations"])

    evidence = {
        "evidence_contract": "pems2-full-corpus-migration-evidence/1",
        "status": "validated_noncanonical_evidence",
        "authority": {
            "steward_record": STEWARD_AUTHORITY_RECORD,
            "source_semantic": "pems/1",
            "target_semantic": "pems/2",
            "canonical_cutover_authorized": False,
            "cove1_assumed_as_pems2_codec": False,
        },
        "source": {
            "record_count": len(source["records"]),
            "relation_count": len(source["relations"]),
            "identity_count": len(source["records"]) + len(source["relations"]),
            "cove_sha256": sha256_bytes(source_cove_bytes),
            "derivative_sha256": sha256_bytes(source_derivative_bytes),
        },
        "migration": {
            "record_count": len(first["records"]),
            "relation_count": len(first["relations"]),
            "identity_count": len(first["records"]) + len(first["relations"]),
            "migrated_bytes_sha256": sha256_bytes(first_bytes),
            "repeated_migration_bytes_identical": True,
            "schema_valid": True,
            "identity_and_history": identity,
            "source_observations": source_obs,
            "relations": relations,
            "typed_provenance_inferred": False,
            "primary_provenance_manufactured": False,
        },
        "human_reconstruction": {
            "sha256": sha256_bytes(human_first),
            "repeated_bytes_identical": True,
        },
        "policy_fixtures": policies,
        "unresolved": [
            "Universal primary-grounding minimum remains unresolved; this migration does not manufacture typed or primary provenance.",
            "Canonical PEMS/2 serialization/cutover remains separately gated; cove/1 is not assumed to be the PEMS/2 canonical codec.",
        ],
        "next_gate": "Steward reviews this noncanonical full-corpus migration evidence. Canonical PEMS/2 adoption/cutover remains a separate owner/Steward decision.",
    }

    OUT_MIGRATED.write_bytes(first_bytes)
    OUT_HUMAN.write_bytes(human_first)
    OUT_EVIDENCE.write_bytes(canonical_json(evidence))

    print(f"PASS source_records={len(source['records'])} source_relations={len(source['relations'])}")
    print("PASS source_exact_steward_admitted_hashes")
    print("PASS pems2_schema_validation")
    print("PASS all_source_identities_preserved_no_rebinding")
    print("PASS lifecycle_history_and_record_data_preserved")
    print("PASS source_observation_provenance_preserved")
    print("PASS observation_refs_to_untyped_only")
    print("PASS no_typed_or_primary_provenance_manufactured")
    print("PASS relation_meaning_preserved")
    print("PASS deterministic_repeated_migration_bytes")
    print("PASS deterministic_human_reconstruction")
    print(f"PASS compatibility_cases={policies['compatibility_cases']}")
    print(f"PASS admission_cases={policies['admission_cases']}")
    print(f"MIGRATED_SHA256={evidence['migration']['migrated_bytes_sha256']}")
    print(f"HUMAN_SHA256={evidence['human_reconstruction']['sha256']}")
    print(f"EVIDENCE_SHA256={sha256_bytes(canonical_json(evidence))}")


if __name__ == "__main__":
    main()
