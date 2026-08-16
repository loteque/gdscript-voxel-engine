#!/usr/bin/env python3
"""Deterministic executable checks for the PEMS/2 successor-contract draft.

This validator intentionally does not mutate canonical memory. It checks the
machine-readable compatibility pressure cases and deterministic v1->v2
migration invariants defined by the adjacent normative documents.
"""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FIXTURES = ROOT / "RGP_COMPATIBILITY_FIXTURES.json"

CURRENT = "current"
UNRESOLVED = {"open", "blocked", "deferred"}
RGP_MAJOR = "rgp/1"


def canonical_json(value) -> bytes:
    # Sufficient for deterministic contract fixtures here. This does not claim
    # to replace or redefine the separately frozen jcs/1 byte contract.
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode()


def classify_domain_export(inp):
    kind = inp["kind"]
    lifecycle = inp.get("lifecycle")
    if kind == "decision":
        if lifecycle == CURRENT and inp.get("decision_state") == "accepted":
            return {"exportable": True, "rgp_kind": "decision"}
        if lifecycle == "historical":
            return {"exportable": False, "reason": "historical_snapshot_required"}
        return {"exportable": False, "reason": "state_or_lifecycle_not_lossless"}
    if kind == "unresolved_item":
        if lifecycle == CURRENT and inp.get("resolution_state") in UNRESOLVED:
            return {"exportable": True, "rgp_kind": "uncertainty"}
        if lifecycle == "historical":
            return {"exportable": False, "reason": "historical_snapshot_required"}
        return {"exportable": False, "reason": "state_or_lifecycle_not_lossless"}
    return {"exportable": False, "reason": "unprofiled_domain_kind"}


def classify_case(case):
    cat, inp = case["category"], case["input"]
    if cat == "domain_export":
        return classify_domain_export(inp)
    if cat == "relation":
        if inp["kind"] == "contradicts":
            if inp["a"] == inp["b"]:
                return {"valid": False, "reason": "self_contradiction"}
            return {"from": min(inp["a"], inp["b"]), "to": max(inp["a"], inp["b"]), "symmetric": True}
    if cat == "migration":
        if inp["v1_kind"] == "depends_on":
            out = {"v2_kind": "depends_on", "dependency_kind": "legacy_untyped"}
            if "qualifier" in inp.get("data", {}):
                out["qualifier"] = inp["data"]["qualifier"]
            return out
    if cat == "rgp_import":
        if inp.get("rgp_version") != RGP_MAJOR:
            return {"accepted": False, "reason": "unsupported_rgp_major"}
        if inp.get("relation") == "depends_on":
            return {"pems_kind": "depends_on", "dependency_kind": "conditional_validity"}
        if inp.get("kind") in {"observation", "assumption", "claim"}:
            return {"pems_kind": "proposition", "proposition_kind": inp["kind"]}
    if cat == "identity":
        return {"reuse_generic_id_for_domain": False, "preserve_generic_historically": True, "reviewed_supersession_required": True}
    if cat == "provenance":
        op = inp["operation"]
        if op == "add" and inp.get("same_meaning"):
            return {"same_identity_permitted": True, "review_class": "ordinary_enrichment"}
        if op == "reclassify" and inp.get("from_role") == "untyped":
            return {"same_identity_permitted": True, "atomic": True, "review_class": "governed_classification"}
        return {"review_class": "semantic_correction"}
    if cat == "downgrade":
        if inp.get("kind") == "proposition":
            return {"lossless": False, "reason": "v2_only_record_kind"}
        if any(k in inp.get("provenance", {}) for k in ("primary", "corroborating", "context")):
            return {"lossless": False, "reason": "v2_only_typed_provenance"}
        if inp.get("kind") == "depends_on":
            if inp.get("dependency_kind") == "legacy_untyped":
                return {"lossless": True}
            return {"lossless": False, "reason": "v2_only_dependency_semantics"}
    raise AssertionError(f"unhandled fixture case {case['id']}")


def migrate_v1_to_v2(doc):
    if doc.get("semantic") != "pems/1":
        raise ValueError("unsupported input semantic")
    out = copy.deepcopy(doc)
    out["semantic"] = "pems/2"
    for item in list(out["records"]) + list(out["relations"]):
        refs = item.pop("observation_refs", [])
        if len(refs) != len(set(refs)):
            raise ValueError("duplicate observation_refs")
        if refs:
            item["provenance"] = {"untyped": sorted(refs)}
    for rel in out["relations"]:
        if rel["kind"] == "depends_on":
            rel.setdefault("data", {})
            rel["data"]["dependency_kind"] = "legacy_untyped"
    out["records"] = sorted(out["records"], key=lambda x: x["id"])
    out["relations"] = sorted(out["relations"], key=lambda x: x["id"])
    return out


def migration_fixture():
    return {
        "semantic": "pems/1",
        "project_id": "pems:project:p",
        "records": [
            {
                "id": "pems:source_observation:o",
                "kind": "source_observation",
                "lifecycle": "historical",
                "observation_refs": [],
                "data": {
                    "source_id": "pems:source:s",
                    "evidence_state": "immutable_snapshot",
                    "observed_at": "2026-08-15T00:00:00Z",
                    "evidence_locator": {"commit": "abc"}
                }
            },
            {
                "id": "pems:source:s",
                "kind": "source",
                "lifecycle": "current",
                "observation_refs": [],
                "data": {
                    "source_kind": "repository",
                    "authority": "repository_state",
                    "identity_locator": {"repository": "o/r"}
                }
            },
            {
                "id": "pems:decision:d",
                "kind": "decision",
                "lifecycle": "historical",
                "observation_refs": ["pems:source_observation:o"],
                "data": {"summary": "A historical decision.", "decision_state": "accepted"}
            }
        ],
        "relations": [
            {
                "id": "pems:relation:r",
                "kind": "depends_on",
                "from": "pems:decision:d",
                "to": "pems:source:s",
                "lifecycle": "historical",
                "observation_refs": ["pems:source_observation:o"],
                "data": {"qualifier": "legacy"}
            }
        ]
    }


def run():
    suite = json.loads(FIXTURES.read_text())
    failures = []
    for case in suite["cases"]:
        actual = classify_case(case)
        if actual != case["expected"]:
            failures.append((case["id"], case["expected"], actual))

    v1 = migration_fixture()
    first = migrate_v1_to_v2(v1)
    second = migrate_v1_to_v2(copy.deepcopy(v1))
    assert canonical_json(first) == canonical_json(second)
    assert {x["id"] for x in first["records"]} == {x["id"] for x in v1["records"]}
    assert {x["id"] for x in first["relations"]} == {x["id"] for x in v1["relations"]}
    d = next(x for x in first["records"] if x["id"] == "pems:decision:d")
    assert d["lifecycle"] == "historical"
    assert d["data"]["decision_state"] == "accepted"
    assert d["provenance"] == {"untyped": ["pems:source_observation:o"]}
    r = first["relations"][0]
    assert r["data"]["dependency_kind"] == "legacy_untyped"
    assert r["provenance"] == {"untyped": ["pems:source_observation:o"]}
    assert all("observation_refs" not in x for x in first["records"] + first["relations"])
    assert all(x["kind"] != "proposition" for x in first["records"])
    assert all(x["kind"] not in {"supports", "contradicts"} for x in first["relations"])

    digest = hashlib.sha256(canonical_json(first)).hexdigest()
    if failures:
        for cid, expected, actual in failures:
            print(f"FAIL {cid}: expected={expected!r} actual={actual!r}")
        raise SystemExit(1)
    print(f"PASS compatibility_cases={len(suite['cases'])}")
    print("PASS deterministic_v1_to_v2_migration")
    print(f"MIGRATION_FIXTURE_SHA256={digest}")


if __name__ == "__main__":
    run()
