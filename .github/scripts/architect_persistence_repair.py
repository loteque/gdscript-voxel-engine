from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, "/tmp/accepted-pems-cove")
from tools.cove.cove_v1 import decode, encode
from tools.cove.jcs_v1 import canonicalize, parse_canonical, serialize_cove
from tools.pems import normalize_document, semantic_identity, validate_schema, validate_semantics
from tools.pems.human_export import render_human_markdown

ROOT = Path(".")
BASE_EXPANDED = ROOT / "docs/project-chat-handoff.json"
BASE_COVE = ROOT / "docs/project-chat-handoff.cove.json"
SCHEMA = json.loads((ROOT / "docs/handoff/pems/pems-v1.schema.json").read_text())


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()


def assert_base() -> tuple[bytes, bytes, dict]:
    expanded = BASE_EXPANDED.read_bytes()
    cove = BASE_COVE.read_bytes()
    assert len(expanded) == 65793
    assert sha256(expanded) == "bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038"
    assert git_blob_sha(expanded) == "10de73e29e0118b63a365dd47b566307c9a0b98b"
    assert len(cove) == 38053
    assert sha256(cove) == "ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa"
    assert git_blob_sha(cove) == "0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be"
    base = normalize_document(json.loads(expanded))
    assert canonicalize(base) == expanded
    assert len(base["records"]) == 163 and len(base["relations"]) == 0
    assert validate_schema(base, schema=SCHEMA).valid
    assert validate_semantics(base).valid
    return expanded, cove, base


OLD_PENDING = "pems:decision:abe7b5d5efc6d7232e72"
CAND_DEC = "candidate:decision:5fa3241c8b9bc2787b6d"
ADM_DEC = "pems:decision:5fa3241c8b9bc2787b6d"
CAND_OBS = "candidate:source_observation:15b32d4adb9bcfa4fc94"
ADM_OBS = "pems:source_observation:15b32d4adb9bcfa4fc94"
OLD_SENTENCE = "Phase 8 technical cutover is complete and final Steward governance closeout is pending."
NEW_SENTENCE = "Phase 8 technical cutover and final Steward governance closeout are complete."
DECISION_SUMMARY = "Engineering-memory representation workstream field 'phase8_status' is \"accepted_complete\"."


def build(base: dict, admitted: bool) -> dict:
    doc = copy.deepcopy(base)
    did = ADM_DEC if admitted else CAND_DEC
    oid = ADM_OBS if admitted else CAND_OBS
    for r in doc["records"]:
        if r["id"] == OLD_PENDING:
            assert r["data"]["summary"] == "Engineering-memory representation workstream field 'phase8_status' is \"technical_cutover_complete_pending_steward_governance_closeout\"."
            r["lifecycle"] = "superseded"
            r["superseded_by"] = [did]
            r["observation_refs"] = sorted(set(r.get("observation_refs", []) + [oid]), key=str.encode)
        elif r["id"] == "pems:chat:7da38ee068988502fe3b":
            assert OLD_SENTENCE in r["data"]["summary"]
            r["data"]["summary"] = r["data"]["summary"].replace(OLD_SENTENCE, NEW_SENTENCE)
            r["observation_refs"] = sorted(set(r.get("observation_refs", []) + [oid]), key=str.encode)
        elif r["id"] == "pems:continuation:7da38ee068988502fe3b":
            assert OLD_SENTENCE in r["data"]["current_focus"]
            r["data"]["current_focus"] = r["data"]["current_focus"].replace(OLD_SENTENCE, NEW_SENTENCE)
            r["observation_refs"] = sorted(set(r.get("observation_refs", []) + [oid]), key=str.encode)
    doc["records"].append({
        "data": {"decision_state": "accepted", "rationale": None, "summary": DECISION_SUMMARY},
        "id": did, "kind": "decision", "lifecycle": "current",
        "observation_refs": [oid], "supersedes": [OLD_PENDING],
    })
    doc["records"].append({
        "data": {
            "captured_fingerprint": "sha256:ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa",
            "evidence_locator": {"commit": "3ad4794f6ef89ecdde5077acee49c7d6844961f8", "path": "docs/project-chat-handoff.cove.json", "repository": "loteque/gdscript-voxel-engine"},
            "evidence_state": "immutable_snapshot", "observed_at": "2026-08-14T10:03:17-07:00",
            "source_id": "pems:source:eb92b21e7f3c92db6d23",
        },
        "id": oid, "kind": "source_observation", "lifecycle": "historical", "observation_refs": [],
    })
    return normalize_document(doc)


EXPECTED = {
    "candidate_pems": (66895, "1d2378cf19a247256c327dd8f12ed639c7508dba555fa7c7a92df44fd98b98ba"),
    "candidate_cove": (38628, "0b4a7478469c28e9d44b8358dd0ca21ec8cbb1135bb33ba29afe14f2bddb0a43"),
    "candidate_human": (68552, "2d63d2c6765bd92d906a330864e8f59c0350c885d824f56279a660184675f9f0"),
    "contingent_pems": (66860, "090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7"),
    "contingent_cove": (38618, "a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a"),
    "contingent_human": (68522, "f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c"),
}


def make_artifacts(candidate: dict, contingent: dict) -> dict[str, bytes]:
    result = {
        "candidate_pems": canonicalize(candidate),
        "candidate_cove": serialize_cove(encode(candidate, profile="pems/1", serializer="jcs/1")),
        "candidate_human": render_human_markdown(candidate).encode(),
        "contingent_pems": canonicalize(contingent),
        "contingent_cove": serialize_cove(encode(contingent, profile="pems/1", serializer="jcs/1")),
        "contingent_human": render_human_markdown(contingent).encode(),
    }
    for key, payload in result.items():
        size, digest = EXPECTED[key]
        assert len(payload) == size, (key, len(payload), size)
        assert sha256(payload) == digest, (key, sha256(payload), digest)
    return result


def validate_variants(base: dict, candidate: dict, contingent: dict, artifacts: dict[str, bytes]) -> None:
    base_records = {r["id"]: r for r in base["records"]}
    base_ids = set(base_records)
    assert len(base_ids) == 163
    for doc, prefix in ((candidate, "candidate"), (contingent, "contingent")):
        ids = [r["id"] for r in doc["records"]]
        assert len(doc["records"]) == 165 and len(doc["relations"]) == 0
        assert len(ids) == len(set(ids)) == 165
        assert base_ids.issubset(ids)
        schema_result = validate_schema(doc, schema=SCHEMA)
        semantics_result = validate_semantics(doc)
        assert schema_result.valid, schema_result.diagnostics
        assert semantics_result.valid, semantics_result.diagnostics
        now = {r["id"]: r for r in doc["records"]}
        rebound = [rid for rid in sorted(base_ids) if semantic_identity(now[rid]) != semantic_identity(base_records[rid])]
        assert rebound == [], rebound
        for hid in (OLD_PENDING, "pems:decision:b54a6445b1ce2b815b56", "pems:source_observation:5b206d4358781f93074b", "pems:source_observation:8c186a6ca2398e0cfe5e", "pems:source_observation:be6819991bf46e7cc226"):
            assert hid in now
        compact = artifacts[prefix + "_cove"]
        decoded = decode(parse_canonical(compact), supported_profiles={"pems/1"})
        assert decoded == doc
        assert serialize_cove(encode(decoded, profile="pems/1", serializer="jcs/1")) == compact
        assert canonicalize(normalize_document(doc)) == artifacts[prefix + "_pems"]
        assert render_human_markdown(doc).encode() == artifacts[prefix + "_human"]


def persist(artifacts: dict[str, bytes]) -> tuple[dict, bytes]:
    path_map = {
        "candidate_pems": Path("docs/handoff/pems/final-closeout.candidate.pems.json"),
        "candidate_cove": Path("docs/handoff/pems/final-closeout.candidate.cove.json"),
        "candidate_human": Path("docs/handoff/pems/final-closeout.candidate.md"),
        "contingent_pems": Path("docs/handoff/pems/final-closeout.contingent-admitted.pems.json"),
        "contingent_cove": Path("docs/handoff/pems/final-closeout.contingent-admitted.cove.json"),
        "contingent_human": Path("docs/handoff/pems/final-closeout.contingent-admitted.md"),
    }
    manifest = {}
    for key, path in path_map.items():
        path.write_bytes(artifacts[key])
        payload = path.read_bytes()
        manifest[str(path)] = {"bytes": len(payload), "sha256": sha256(payload), "git_blob_sha": git_blob_sha(payload)}
    for key, path in (("candidate_pems", Path("docs/handoff/pems/final-closeout.candidate.expanded.json")), ("contingent_pems", Path("docs/handoff/pems/final-closeout.contingent-admitted.expanded.json"))):
        path.write_bytes(artifacts[key])
        payload = path.read_bytes()
        manifest[str(path)] = {"bytes": len(payload), "sha256": sha256(payload), "git_blob_sha": git_blob_sha(payload)}
    evidence = {
        "status": "persisted_ready_for_steward_confirmation",
        "authority": {"architect_admission_performed": False, "canonical_authority_unchanged": "docs/project-chat-handoff.cove.json", "contingent_admitted_variant_requires_steward_confirmation": True},
        "base_canonical": {
            "commit": "3ad4794f6ef89ecdde5077acee49c7d6844961f8", "record_count": 163,
            "cove": {"path": "docs/project-chat-handoff.cove.json", "git_blob_sha": "0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be", "bytes": 38053, "sha256": "ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa"},
            "expanded": {"path": "docs/project-chat-handoff.json", "git_blob_sha": "10de73e29e0118b63a365dd47b566307c9a0b98b", "bytes": 65793, "sha256": "bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038"},
        },
        "candidate_to_contingent_admitted_id_map": {CAND_DEC: ADM_DEC, CAND_OBS: ADM_OBS},
        "record_count_before": 163, "record_count_after": 165, "relation_count": 0,
        "existing_ids_preserved": 163, "missing_existing_ids": [], "rebound_existing_ids": [], "identity_collisions": [],
        "history_preserved_ids": [OLD_PENDING, "pems:decision:b54a6445b1ce2b815b56", "pems:source_observation:5b206d4358781f93074b", "pems:source_observation:8c186a6ca2398e0cfe5e", "pems:source_observation:be6819991bf46e7cc226"],
        "pending_status_supersession": {"from": OLD_PENDING, "candidate_to": CAND_DEC, "contingent_admitted_to": ADM_DEC, "new_summary": DECISION_SUMMARY},
        "new_source_observation": {"candidate_id": CAND_OBS, "contingent_admitted_id": ADM_OBS, "source_id": "pems:source:eb92b21e7f3c92db6d23", "captured_commit": "3ad4794f6ef89ecdde5077acee49c7d6844961f8", "captured_sha256": "ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa", "observed_at": "2026-08-14T10:03:17-07:00"},
        "artifacts": manifest,
        "validation": {"schema_valid": True, "semantic_valid": True, "all_references_resolve": True, "supersession_reciprocal": True, "candidate_cove_round_trip_valid": True, "contingent_admitted_cove_round_trip_valid": True, "candidate_expanded_byte_repeat_identical": True, "candidate_canonical_byte_repeat_identical": True, "candidate_human_reconstruction_repeat_identical": True, "contingent_admitted_expanded_byte_repeat_identical": True, "contingent_admitted_canonical_byte_repeat_identical": True, "contingent_admitted_human_reconstruction_repeat_identical": True, "recovery_hashes_match_exactly": True},
        "accepted_tooling_source": "origin/post-cutover-admitted-regeneration",
        "recovery_evidence_commits": ["894844702668f2ef6c1e4e2c58f3de2bef33d377", "8d51cec4fd19bd62ebbb8a4132675c7cb3a6760d"],
    }
    evidence_path = Path("docs/handoff/pems/final-closeout-regeneration.persisted.evidence.json")
    evidence_bytes = (json.dumps(evidence, indent=2, sort_keys=True) + "\n").encode()
    evidence_path.write_bytes(evidence_bytes)
    return manifest, evidence_bytes


def append_notes(manifest: dict, evidence_bytes: bytes) -> None:
    notes = Path("docs/handoff/architect_notes.md")
    prior = notes.read_bytes()
    assert git_blob_sha(prior) == "cc835535407a39f6a69e3d1accb2ed5a0ba1360e"
    recovery = Path("docs/handoff/pems/final-closeout-architect-notes-append.md").read_bytes()
    marker = b"## ARCH-20260814T100300-0700-019"
    assert marker not in prior
    exact_append = recovery[recovery.index(marker):]
    sep = b"" if prior.endswith(b"\n\n") else (b"\n" if prior.endswith(b"\n") else b"\n\n")
    repaired = prior + sep + exact_append
    assert repaired[:len(prior)] == prior
    def line(path: str) -> str:
        m = manifest[path]
        return f"- `{path}`: Git blob `{m['git_blob_sha']}`, {m['bytes']:,} bytes, SHA-256 `{m['sha256']}`."
    final_note = f'''\n## ARCH-20260814T123200-0700-021

- timestamp: `2026-08-14T12:32:00-07:00`
- author: Engineering Knowledge Systems Architect
- type: handoff
- status: resolved
- acknowledges: `ARCH-20260814T100300-0700-019`, `ARCH-20260814T100300-0700-020`, and project-owner persistence-repair authorization
- subject: Final governance-closeout persistence repair complete; Steward-ready artifacts durable

### Assessment

The prior persistence blocker is resolved using bounded repository-native execution. The final 165-record post-closeout transition was independently reproduced from the exact 163-record canonical base with the accepted PEMS normalizer, COVE v1 codec, and `jcs/1` serializer. Candidate and contingent-admitted artifacts match all six recovery byte counts and SHA-256 hashes exactly.

All 163 existing admitted semantic identities are preserved with zero missing identities, collisions, or rebindings. `pems:decision:abe7b5d5efc6d7232e72` remains superseded history and gains provenance to the new canonical observation. The new current decision has exact summary `Engineering-memory representation workstream field 'phase8_status' is "accepted_complete".` The Steward chat and continuation retain their semantic identities while their mutable current summary/focus now states governance closeout is complete.

### Confirmed contingent admission map

- `candidate:decision:5fa3241c8b9bc2787b6d` -> `pems:decision:5fa3241c8b9bc2787b6d`
- `candidate:source_observation:15b32d4adb9bcfa4fc94` -> `pems:source_observation:15b32d4adb9bcfa4fc94`

The Architect has not admitted these identities. The `pems:` forms remain contingent until Project Engineering Steward confirmation.

### Persisted Steward-ready artifacts

{line('docs/handoff/pems/final-closeout.candidate.pems.json')}
{line('docs/handoff/pems/final-closeout.candidate.cove.json')}
{line('docs/handoff/pems/final-closeout.candidate.md')}
{line('docs/handoff/pems/final-closeout.contingent-admitted.pems.json')}
{line('docs/handoff/pems/final-closeout.contingent-admitted.cove.json')}
{line('docs/handoff/pems/final-closeout.contingent-admitted.md')}

Machine-readable persistence evidence is `docs/handoff/pems/final-closeout-regeneration.persisted.evidence.json`, expected Git blob `{git_blob_sha(evidence_bytes)}`.

### Validation evidence

Both variants contain 165 records and zero relations. Schema and semantic validation pass; all references resolve; reciprocal supersession is valid; historical records and prior source observations are preserved; COVE decode reproduces normalized PEMS; repeated expanded `jcs/1`, compact `jcs/1`, and human reconstruction are byte-identical. Contingent-admitted hashes are expanded `090466c8a5683bb01c7038531f4cfdf59a2793a65fa344da13721ed294a7a6f7`, COVE `a7ca5962c354161840822ce406bddd405296e4855afd2b0481f05f904291dc1a`, human `f2a71b0606711de6f94fc0c598c43b4549e03708556ba9f94c3eacd991511e0c`.

Canonical Steward-owned files remain unchanged at the 163-record base: COVE blob `0ed7fd47dc5bf6a81078389cd9bc65e0864ad3be` / SHA-256 `ef8951e67a7219bf829a5667f562f0f552360ce5c220cb5202b6eb84e806eaaa`; expanded derivative blob `10de73e29e0118b63a365dd47b566307c9a0b98b` / SHA-256 `bbbf623aa01608ce30680d4be55ba4f4cff275f5a46ae0ef2c724efb15845038`.

### Steward handoff

Verify the machine-readable evidence and persisted blob identities. If the two new identities are accepted, confirm the namespace-preserving map and install `docs/handoff/pems/final-closeout.contingent-admitted.cove.json` as `docs/project-chat-handoff.cove.json` and the byte-identical contingent expanded/PEMS artifact as `docs/project-chat-handoff.json`. Then post-write verify exact blobs/hashes and record governance closeout in Steward-owned history.

### Human reasoning

Repository-native execution can generate and commit large deterministic blobs without manually retranscribing them through the connector. The first independent reconstruction correctly hard-stopped on a hash mismatch; the exact prior mutation was then recovered cryptographically and revalidated through accepted implementation code before persistence. This turns computed-only evidence into independently fetchable Git evidence without crossing the Steward admission boundary.
'''.encode()
    final = repaired.rstrip(b"\n") + b"\n" + final_note
    notes.write_bytes(final)
    assert final[:len(prior)] == prior
    assert final.count(b"## ARCH-20260814T100300-0700-019") == 1
    assert final.count(b"## ARCH-20260814T100300-0700-020") == 1
    assert final.count(b"## ARCH-20260814T123200-0700-021") == 1


def main() -> None:
    base_expanded_bytes, base_cove_bytes, base = assert_base()
    candidate = build(base, False)
    contingent = build(base, True)
    artifacts = make_artifacts(candidate, contingent)
    validate_variants(base, candidate, contingent, artifacts)
    manifest, evidence_bytes = persist(artifacts)
    append_notes(manifest, evidence_bytes)
    assert BASE_EXPANDED.read_bytes() == base_expanded_bytes
    assert BASE_COVE.read_bytes() == base_cove_bytes
    print(json.dumps({"status": "validated_ready_to_commit", "artifacts": manifest, "evidence_blob": git_blob_sha(evidence_bytes), "notes_blob": git_blob_sha(Path('docs/handoff/architect_notes.md').read_bytes())}, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
