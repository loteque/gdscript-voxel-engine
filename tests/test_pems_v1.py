from __future__ import annotations

import copy
import unittest

from tools.pems import (
    admit_candidate,
    load_json,
    normalize_document,
    run_fixture_suite,
    validate_schema,
    validate_semantics,
)
from tools.pems.pems_v1 import default_success_fixture_path


MAX_INTEROPERABLE_INTEGER = 9007199254740991


class PemsV1Phase2Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.success = load_json(default_success_fixture_path())

    def test_frozen_fixture_suite_passes(self) -> None:
        failures = [result for result in run_fixture_suite() if not result.passed]
        self.assertEqual([], failures, "Frozen PEMS fixture failures: %r" % (failures,))

    def test_success_fixture_is_structurally_and_semantically_valid(self) -> None:
        self.assertTrue(validate_schema(self.success).valid)
        self.assertTrue(validate_semantics(self.success).valid)

    def test_interoperable_integer_boundary_is_enforced_by_schema(self) -> None:
        safe = copy.deepcopy(self.success)
        unsafe = copy.deepcopy(self.success)

        safe_observation = next(
            record for record in safe["records"] if record["kind"] == "source_observation"
        )
        unsafe_observation = next(
            record for record in unsafe["records"] if record["kind"] == "source_observation"
        )
        safe_observation["data"]["evidence_locator"]["line_start"] = MAX_INTEROPERABLE_INTEGER
        unsafe_observation["data"]["evidence_locator"]["line_start"] = MAX_INTEROPERABLE_INTEGER + 1

        self.assertTrue(validate_schema(safe).valid)
        unsafe_result = validate_schema(unsafe)
        self.assertFalse(unsafe_result.valid)
        self.assertTrue(
            any(diagnostic.path.endswith("/data/evidence_locator/line_start") for diagnostic in unsafe_result.diagnostics),
            unsafe_result.diagnostics,
        )

    def test_normalization_is_idempotent(self) -> None:
        normalized = normalize_document(self.success)
        self.assertEqual(normalized, normalize_document(normalized))

    def test_normalization_is_independent_of_record_relation_and_set_order(self) -> None:
        reordered = copy.deepcopy(self.success)
        reordered["records"] = list(reversed(reordered["records"]))
        reordered["relations"] = list(reversed(reordered["relations"]))
        for record in reordered["records"]:
            for key in ("observation_refs", "supersedes", "superseded_by"):
                if key in record:
                    record[key] = list(reversed(record[key]))
        for relation in reordered["relations"]:
            for key in ("observation_refs", "supersedes", "superseded_by"):
                if key in relation:
                    relation[key] = list(reversed(relation[key]))
        self.assertEqual(normalize_document(self.success), normalize_document(reordered))

    def test_admission_reuses_provisional_candidate_for_existing_identity(self) -> None:
        canonical = self.success["records"][0]
        candidate = copy.deepcopy(canonical)
        candidate["id"] = "candidate:existing"
        decision = admit_candidate(candidate, [canonical])
        self.assertTrue(decision.valid)
        self.assertEqual("reuse_existing_id", decision.code)
        self.assertEqual(canonical["id"], decision.canonical_id)

    def test_admission_rejects_canonical_id_rebinding(self) -> None:
        canonical = next(
            record
            for record in self.success["records"]
            if record["id"] == "module:chunk-streamer"
        )
        candidate = copy.deepcopy(canonical)
        candidate["data"] = copy.deepcopy(candidate["data"])
        candidate["data"]["path"] = "voxel/chunking/DifferentChunkStreamer.gd"
        decision = admit_candidate(candidate, [canonical])
        self.assertFalse(decision.valid)
        self.assertEqual("canonical_id_collision", decision.code)


if __name__ == "__main__":
    unittest.main()
