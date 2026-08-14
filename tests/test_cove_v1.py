from __future__ import annotations

import copy
import json
from pathlib import Path
import unittest

from tools.cove import CoveError, decode, encode, measure_structural_json
from tools.pems import load_json, normalize_document, validate_schema, validate_semantics
from tools.pems.pems_v1 import default_success_fixture_path


ROOT = Path(__file__).resolve().parents[1]
SUCCESS_FIXTURES = ROOT / "docs" / "handoff" / "cove" / "fixtures" / "generic-success.json"
FAILURE_FIXTURES = ROOT / "docs" / "handoff" / "cove" / "fixtures" / "generic-failure.json"
COVE_SOURCE = ROOT / "tools" / "cove" / "cove_v1.py"


class CoveV1Phase3Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.success_fixtures = json.loads(SUCCESS_FIXTURES.read_text(encoding="utf-8"))
        cls.failure_fixtures = json.loads(FAILURE_FIXTURES.read_text(encoding="utf-8"))

    def test_generic_success_fixtures_round_trip(self) -> None:
        profile = self.success_fixtures["profile"]
        for case in self.success_fixtures["cases"]:
            with self.subTest(case=case["name"]):
                artifact = encode(case["value"], profile=profile)
                self.assertEqual(case["value"], decode(artifact, supported_profiles={profile}))

    def test_generic_failure_fixtures_report_declared_diagnostic(self) -> None:
        supported = set(self.failure_fixtures["supported_profiles"])
        for case in self.failure_fixtures["cases"]:
            with self.subTest(case=case["name"]):
                with self.assertRaises(CoveError) as caught:
                    decode(case["artifact"], supported_profiles=supported)
                self.assertEqual(case["expected_code"], caught.exception.diagnostic.code)

    def test_encoding_is_independent_of_object_insertion_order(self) -> None:
        left = {
            "outer": {
                "zeta": "last",
                "alpha": "first",
                "items": [{"b": 2, "a": 1}, {"a": 3, "b": 4}],
            },
            "flag": True,
        }
        right = {
            "flag": True,
            "outer": {
                "items": [{"a": 1, "b": 2}, {"b": 4, "a": 3}],
                "alpha": "first",
                "zeta": "last",
            },
        }
        self.assertEqual(encode(left, profile="generic/1"), encode(right, profile="generic/1"))

    def test_strings_are_global_and_utf8_sorted(self) -> None:
        value = {"é": "repeat", "z": "repeat", "😀": "other"}
        artifact = encode(value, profile="generic/1")
        expected = sorted({"é", "z", "😀", "repeat", "other"}, key=lambda item: item.encode("utf-8"))
        self.assertEqual(expected, artifact["d"])
        self.assertEqual(1, artifact["d"].count("repeat"))

    def test_repeated_object_shapes_are_factored_once(self) -> None:
        value = [{"name": "a", "value": 1}, {"value": 2, "name": "b"}]
        artifact = encode(value, profile="generic/1")
        self.assertEqual(1, len(artifact["h"]))
        self.assertEqual(value, decode(artifact, supported_profiles={"generic/1"}))

    def test_empty_object_and_array_round_trip(self) -> None:
        value = {"object": {}, "array": []}
        artifact = encode(value, profile="generic/1")
        self.assertIn([], artifact["h"])
        self.assertEqual(value, decode(artifact, supported_profiles={"generic/1"}))

    def test_profile_is_opaque_and_versioned_independently(self) -> None:
        artifact = encode({"value": 1}, profile="anything/37")
        self.assertEqual("cove/1", artifact["c"])
        self.assertEqual("anything/37", artifact["p"])
        self.assertEqual({"value": 1}, decode(artifact, supported_profiles={"anything/37"}))

    def test_normalized_pems_round_trips_through_generic_codec(self) -> None:
        pems = load_json(default_success_fixture_path())
        self.assertTrue(validate_schema(pems).valid)
        self.assertTrue(validate_semantics(pems).valid)
        normalized = normalize_document(pems)
        artifact = encode(normalized, profile="pems/1")
        decoded = decode(artifact, supported_profiles={"pems/1"})
        self.assertEqual(normalized, decoded)

    def test_cove_source_contains_no_pems_domain_vocabulary(self) -> None:
        source = COVE_SOURCE.read_text(encoding="utf-8").lower()
        forbidden = (
            "source_observation",
            "observation_refs",
            "decision_state",
            "project_id",
            "chunkstreamer",
            "pointfieldresource",
            "steward",
        )
        for token in forbidden:
            with self.subTest(token=token):
                self.assertNotIn(token, source)

    def test_non_finite_numbers_are_rejected(self) -> None:
        for value in (float("nan"), float("inf"), float("-inf")):
            with self.subTest(value=value):
                with self.assertRaises(CoveError) as caught:
                    encode(value, profile="generic/1")
                self.assertEqual("COVE_NON_FINITE_NUMBER", caught.exception.diagnostic.code)

    def test_structural_size_measurement_is_observational_only(self) -> None:
        value = [{"name": "alpha", "kind": "entry"}, {"name": "beta", "kind": "entry"}]
        artifact = encode(value, profile="generic/1")
        measurement = measure_structural_json(value, artifact)
        self.assertGreater(measurement["expanded_json_chars"], 0)
        self.assertGreater(measurement["cove_json_chars"], 0)


if __name__ == "__main__":
    unittest.main()
