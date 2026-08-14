from __future__ import annotations

import copy
import json
import unittest

from tools.pems.import_current_handoff import HandoffImportError, import_handoff
from tools.pems.pems_v1 import admit_candidate, validate_schema, validate_semantics


BASE_HANDOFF = {
    "schema_version": "1.1.0",
    "document_type": "voxel_terrain_project_chat_handoff",
    "generated_at": "2026-08-13T13:08:00-07:00",
    "project_level": {
        "project_name": "GDScript Voxel Terrain",
        "repository": "loteque/gdscript-voxel-engine",
        "project_summary": "Representative continuity summary.",
        "project_owner_expectations": [
            "Verify repository truth before claiming current state.",
            "Preserve architecture boundaries.",
        ],
        "external_files_used_in_project_context": ["Architecture.txt"],
    },
    "repository_snapshot": {
        "ref": "main",
        "main_commit_sha": "abc123",
        "modules": [
            {"name": "PointFieldResource", "path": "voxel/field/PointFieldResource.gd", "domain": "field"}
        ],
    },
    "chats": [
        {
            "chat_id": "architecture",
            "title": "Architecture",
            "date": "2026-08-06 to 2026-08-13",
            "role": "Senior engine architect",
            "summary": "Review architecture and continuity.",
            "key_decisions_or_outcomes": ["Keep generation offline."],
            "external_file_names_used": ["Architecture.txt", "Notes.txt"],
        }
    ],
}


class CurrentHandoffImportTests(unittest.TestCase):
    def test_import_is_deterministic_and_valid(self) -> None:
        first = import_handoff(BASE_HANDOFF, source_commit="deadbeef")
        second = import_handoff(copy.deepcopy(BASE_HANDOFF), source_commit="deadbeef")
        self.assertEqual(first.document, second.document)
        self.assertEqual(first.provisional_ids, second.provisional_ids)
        self.assertTrue(validate_schema(first.document).valid)
        self.assertTrue(validate_semantics(first.document).valid)
        self.assertTrue(all(record["id"].startswith("import:") for record in first.document["records"]))

    def test_source_identity_and_observation_are_distinct(self) -> None:
        report = import_handoff(BASE_HANDOFF, source_commit="deadbeef")
        sources = [record for record in report.document["records"] if record["kind"] == "source"]
        observations = [record for record in report.document["records"] if record["kind"] == "source_observation"]
        self.assertEqual(len(sources), 1)
        self.assertEqual(len(observations), 1)
        observation = observations[0]
        self.assertEqual(observation["data"]["source_id"], sources[0]["id"])
        self.assertEqual(observation["data"]["evidence_state"], "immutable_snapshot")
        self.assertEqual(observation["data"]["evidence_locator"]["commit"], "deadbeef")
        for record in report.document["records"]:
            if record["kind"] not in {"source", "source_observation"}:
                self.assertEqual(record["observation_refs"], [observation["id"]])

    def test_without_commit_uses_unversioned_observation(self) -> None:
        report = import_handoff(BASE_HANDOFF)
        observation = next(record for record in report.document["records"] if record["kind"] == "source_observation")
        self.assertEqual(observation["data"]["evidence_state"], "unversioned_observation")
        self.assertNotIn("commit", observation["data"]["evidence_locator"])

    def test_every_imported_id_remains_pending_steward_confirmation(self) -> None:
        report = import_handoff(BASE_HANDOFF, source_commit="deadbeef")
        for record in report.document["records"]:
            decision = admit_candidate(record, [])
            self.assertTrue(decision.valid)
            self.assertEqual(decision.code, "candidate_requires_steward_confirmation")

    def test_continuity_fields_survive_mapping(self) -> None:
        report = import_handoff(BASE_HANDOFF, source_commit="deadbeef")
        records = report.document["records"]
        project = next(record for record in records if record["kind"] == "project")
        chat = next(record for record in records if record["kind"] == "chat")
        continuation = next(record for record in records if record["kind"] == "continuation")
        module = next(record for record in records if record["kind"] == "module")
        external_files = {record["data"]["name"] for record in records if record["kind"] == "external_file"}
        decisions = {record["data"]["summary"] for record in records if record["kind"] == "decision"}
        expectations = {record["data"]["summary"] for record in records if record["kind"] == "expectation"}
        self.assertEqual(project["data"]["repository"], "loteque/gdscript-voxel-engine")
        self.assertEqual(chat["data"]["title"], "Architecture")
        self.assertEqual(module["data"]["path"], "voxel/field/PointFieldResource.gd")
        self.assertEqual(external_files, {"Architecture.txt", "Notes.txt"})
        self.assertIn("Keep generation offline.", decisions)
        self.assertIn("Preserve architecture boundaries.", expectations)
        self.assertEqual(continuation["data"]["chat_id"], chat["id"])
        self.assertIn(chat["id"], continuation["data"]["high_value_record_ids"])

    def test_input_order_does_not_change_normalized_output(self) -> None:
        reordered = copy.deepcopy(BASE_HANDOFF)
        reordered["project_level"]["project_owner_expectations"].reverse()
        reordered["repository_snapshot"]["modules"].reverse()
        self.assertEqual(
            import_handoff(BASE_HANDOFF, source_commit="deadbeef").document,
            import_handoff(reordered, source_commit="deadbeef").document,
        )

    def test_rejects_unsupported_schema_major(self) -> None:
        invalid = copy.deepcopy(BASE_HANDOFF)
        invalid["schema_version"] = "2.0.0"
        with self.assertRaises(HandoffImportError) as caught:
            import_handoff(invalid)
        self.assertEqual(caught.exception.code, "unsupported_schema_version")

    def test_rejects_missing_project_identity(self) -> None:
        invalid = copy.deepcopy(BASE_HANDOFF)
        del invalid["project_level"]["repository"]
        with self.assertRaises(HandoffImportError) as caught:
            import_handoff(invalid)
        self.assertEqual(caught.exception.code, "missing_repository")

    def test_rejects_bad_timestamp(self) -> None:
        invalid = copy.deepcopy(BASE_HANDOFF)
        invalid["generated_at"] = "yesterday"
        with self.assertRaises(HandoffImportError) as caught:
            import_handoff(invalid)
        self.assertEqual(caught.exception.code, "invalid_generated_at")

    def test_rejects_malformed_module(self) -> None:
        invalid = copy.deepcopy(BASE_HANDOFF)
        invalid["repository_snapshot"]["modules"][0].pop("path")
        with self.assertRaises(HandoffImportError) as caught:
            import_handoff(invalid)
        self.assertEqual(caught.exception.code, "invalid_module")


if __name__ == "__main__":
    unittest.main()
