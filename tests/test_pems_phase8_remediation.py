from __future__ import annotations

import copy
import unittest

from tools.cove.cove_v1 import decode, encode
from tools.cove.jcs_v1 import measure_utf8_bytes, parse_canonical, serialize_cove
from tools.pems.human_export import render_human_markdown
from tools.pems.migration_seed import import_handoff_with_engineering_memory, seed_migration
from tools.pems.pems_v1 import admit_candidate, validate_schema, validate_semantics


BASE_HANDOFF = {
    "schema_version": "1.1.0",
    "document_type": "voxel_terrain_project_chat_handoff",
    "generated_at": "2026-08-13T13:08:00-07:00",
    "project_level": {
        "project_name": "GDScript Voxel Terrain",
        "repository": "loteque/gdscript-voxel-engine",
        "project_summary": "Representative continuity summary.",
        "project_owner_expectations": ["Preserve architecture boundaries."],
        "external_files_used_in_project_context": [],
        "engineering_memory": {
            "representation_workstream": {
                "pems_contract": "pems/1",
                "cove_contract": "cove/1",
                "serializer_contract": "jcs/1 (RFC 8785 behavior)",
                "phase7_status": "authorized_in_progress",
                "phase8_status": "not_authorized",
                "current_canonical_authority": "docs/project-chat-handoff.json",
            },
            "repository_write_safety": {
                "status": "active",
                "rule": "History-sensitive writes require complete verified source state and optimistic concurrency.",
            },
        },
    },
    "repository_snapshot": {
        "ref": "main",
        "main_commit_sha": "abc123",
        "modules": [],
    },
    "chats": [
        {
            "chat_id": "project-engineering-steward",
            "title": "Project Engineering Steward / Handoff Memory",
            "date": "2026-08-13",
            "role": "Project Engineering Steward",
            "summary": "Maintain trustworthy engineering continuity.",
            "key_decisions_or_outcomes": ["Keep the current JSON canonical."],
            "external_file_names_used": [],
        }
    ],
}


class Phase8RemediationTests(unittest.TestCase):
    def test_structured_engineering_memory_has_direct_normative_records(self) -> None:
        report = import_handoff_with_engineering_memory(BASE_HANDOFF, source_commit="oldcommit")
        self.assertTrue(validate_schema(report.document).valid)
        self.assertTrue(validate_semantics(report.document).valid)

        decisions = [record for record in report.document["records"] if record["kind"] == "decision"]
        requirements = [record for record in report.document["records"] if record["kind"] == "requirement"]
        summaries = {record["data"]["summary"] for record in decisions}
        self.assertTrue(any("'pems_contract'" in summary and '"pems/1"' in summary for summary in summaries))
        self.assertTrue(any("'phase8_status'" in summary and '"not_authorized"' in summary for summary in summaries))
        self.assertEqual(len(requirements), 1)
        self.assertIn("History-sensitive writes require complete verified source state", requirements[0]["data"]["summary"])
        self.assertEqual(requirements[0]["data"]["requirement_state"], "active")

    def test_migration_seed_retains_prior_observation_and_disappeared_record(self) -> None:
        newer = copy.deepcopy(BASE_HANDOFF)
        newer["generated_at"] = "2026-08-13T21:09:00-07:00"
        newer["project_level"]["engineering_memory"]["representation_workstream"]["phase7_status"] = "complete"
        newer["chats"][0]["key_decisions_or_outcomes"] = ["Phase 7 is complete."]

        older_import = import_handoff_with_engineering_memory(BASE_HANDOFF, source_commit="oldcommit")
        newer_import = import_handoff_with_engineering_memory(newer, source_commit="newcommit")
        seed = seed_migration([(BASE_HANDOFF, "oldcommit"), (newer, "newcommit")])

        self.assertTrue(validate_schema(seed.document).valid)
        self.assertTrue(validate_semantics(seed.document).valid)
        self.assertEqual(len(seed.source_observation_ids), 2)
        self.assertIn(older_import.source_observation_id, seed.source_observation_ids)
        self.assertIn(newer_import.source_observation_id, seed.source_observation_ids)

        older_decision = next(
            record for record in older_import.document["records"]
            if record["kind"] == "decision" and record["data"]["summary"] == "Keep the current JSON canonical."
        )
        seeded = {record["id"]: record for record in seed.document["records"]}
        self.assertIn(older_decision["id"], seed.retained_historical_ids)
        self.assertEqual(seeded[older_decision["id"]]["lifecycle"], "historical")
        self.assertEqual(seeded[older_decision["id"]]["observation_refs"], [older_import.source_observation_id])

    def test_seed_is_deterministic_and_every_identity_remains_provisional(self) -> None:
        newer = copy.deepcopy(BASE_HANDOFF)
        newer["generated_at"] = "2026-08-13T21:09:00-07:00"
        newer["project_level"]["engineering_memory"]["representation_workstream"]["phase7_status"] = "complete"
        first = seed_migration([(BASE_HANDOFF, "oldcommit"), (newer, "newcommit")])
        second = seed_migration([(copy.deepcopy(BASE_HANDOFF), "oldcommit"), (copy.deepcopy(newer), "newcommit")])
        self.assertEqual(first.document, second.document)
        self.assertEqual(first.provisional_ids, second.provisional_ids)
        for record in first.document["records"]:
            decision = admit_candidate(record, [])
            self.assertTrue(decision.valid)
            self.assertEqual(decision.code, "candidate_requires_steward_confirmation")

    def test_seed_round_trips_through_cove_jcs_and_human_export(self) -> None:
        newer = copy.deepcopy(BASE_HANDOFF)
        newer["generated_at"] = "2026-08-13T21:09:00-07:00"
        newer["project_level"]["engineering_memory"]["representation_workstream"]["phase7_status"] = "complete"
        seed = seed_migration([(BASE_HANDOFF, "oldcommit"), (newer, "newcommit")])
        artifact = encode(seed.document, profile="pems/1", serializer="jcs/1")
        wire = serialize_cove(artifact)
        decoded = decode(parse_canonical(wire), supported_profiles={"pems/1"})
        self.assertEqual(seed.document, decoded)
        self.assertEqual(wire, serialize_cove(encode(decoded, profile="pems/1", serializer="jcs/1")))

        human_first = render_human_markdown(seed.document)
        human_second = render_human_markdown(copy.deepcopy(seed.document))
        self.assertEqual(human_first, human_second)
        self.assertIn("phase8_status", human_first)
        self.assertIn("Repository write safety", human_first)

        measured = measure_utf8_bytes(seed.document, artifact)
        self.assertGreater(measured["expanded_jcs_bytes"], 0)
        self.assertGreater(measured["cove_jcs_bytes"], 0)
        print(
            "PRE_PHASE8_SIZE expanded=%d cove=%d"
            % (measured["expanded_jcs_bytes"], measured["cove_jcs_bytes"])
        )


if __name__ == "__main__":
    unittest.main()
