from __future__ import annotations

import copy
import json
from pathlib import Path

from tools.pems.shadow_validate import build_report


FIXTURE = Path("docs/project-chat-handoff.json")


def _handoff():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def test_unchanged_observation_is_byte_stable():
    handoff = _handoff()
    report = build_report([("a", "commit-a", handoff), ("b", "commit-a", copy.deepcopy(handoff))])
    transition = report["transitions"][0]
    assert transition["source_changed"] is False
    assert transition["canonical_bytes_stable_when_source_unchanged"] is True
    assert transition["human_export_stable_when_source_unchanged"] is True
    assert transition["added_candidate_ids"] == []
    assert transition["removed_candidate_ids"] == []


def test_reconciliation_change_surfaces_identity_and_provenance_delta():
    before = _handoff()
    after = copy.deepcopy(before)
    after["generated_at"] = "2026-08-13T21:00:00-07:00"
    after["project_level"]["project_owner_expectations"].append("Phase 7 synthetic reconciliation marker.")
    report = build_report([("before", "commit-a", before), ("after", "commit-b", after)])
    transition = report["transitions"][0]
    assert transition["source_changed"] is True
    assert transition["source_observation_changed"] is True
    added = transition["added_candidate_ids"]
    assert len(added) == 2
    assert sum(item.startswith("import:expectation:") for item in added) == 1
    assert sum(item.startswith("import:source_observation:") for item in added) == 1
    assert transition["removed_candidate_ids"] == []
    assert transition["canonical_bytes_stable_when_source_unchanged"] is None


def test_shadow_report_never_claims_authority():
    report = build_report([("a", "commit-a", _handoff())])
    assert report["authority"] == "noncanonical_evidence"
