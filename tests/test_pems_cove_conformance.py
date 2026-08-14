from __future__ import annotations

import copy
import json
import unittest

from tools.cove.cove_v1 import CoveError, decode, encode
from tools.cove.jcs_v1 import JcsError, canonicalize, measure_utf8_bytes, parse_canonical, serialize_cove
from tools.pems import admit_candidate, load_json, normalize_document, validate_schema, validate_semantics
from tools.pems.human_export import render_human_markdown
from tools.pems.pems_v1 import default_success_fixture_path


class Phase5ConformanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = load_json(default_success_fixture_path())
        cls.normalized = normalize_document(cls.source)

    def round_trip(self, document):
        artifact = encode(document, profile="pems/1", serializer="jcs/1")
        wire = serialize_cove(artifact)
        reparsed = parse_canonical(wire)
        return wire, decode(reparsed, supported_profiles={"pems/1"})

    def test_semantic_and_canonical_byte_round_trip(self):
        wire1, decoded = self.round_trip(self.normalized)
        self.assertEqual(self.normalized, decoded)
        wire2, decoded2 = self.round_trip(decoded)
        self.assertEqual(wire1, wire2)
        self.assertEqual(decoded, decoded2)

    def test_round_trip_preserves_provenance_history_identity_and_secret_disposition(self):
        _, decoded = self.round_trip(self.normalized)
        records = {record["id"]: record for record in decoded["records"]}
        self.assertEqual("source_observation", records["observation:roadmap:r1"]["kind"])
        self.assertEqual("historical", records["observation:roadmap:r1"]["lifecycle"])
        self.assertEqual("current", records["observation:roadmap:r2"]["lifecycle"])
        self.assertEqual(["decision:canonical-path-new"], records["decision:canonical-path-old"]["superseded_by"])
        secret = records["env:example-token"]["data"]
        self.assertEqual("external_secret", secret["value_state"])
        self.assertIsNone(secret["value"])
        self.assertEqual("secret-store:example-token", secret["external_ref"])
        self.assertEqual("tombstoned", records["table:memory-events"]["lifecycle"])

    def test_invalid_provenance_is_rejected_before_encoding_claim(self):
        invalid = copy.deepcopy(self.normalized)
        target = next(record for record in invalid["records"] if record["id"] == "decision:pems-design-freeze")
        target["observation_refs"] = ["source:steward-notes"]
        result = validate_semantics(invalid)
        self.assertFalse(result.valid)
        self.assertTrue(any(item.code == "observation_ref_wrong_kind" for item in result.diagnostics))

    def test_secret_like_literal_is_rejected(self):
        invalid = copy.deepcopy(self.normalized)
        target = next(record for record in invalid["records"] if record["id"] == "env:example-token")
        target["data"] = {"name": "EXAMPLE_TOKEN", "value_state": "literal", "value": "do-not-store", "external_ref": None, "purpose": "negative fixture"}
        self.assertTrue(validate_schema(invalid).valid)
        result = validate_semantics(invalid)
        self.assertFalse(result.valid)
        self.assertTrue(any(item.code == "literal_secret_disallowed" for item in result.diagnostics))

    def test_canonical_identity_rebinding_is_rejected(self):
        canonical = next(record for record in self.normalized["records"] if record["id"] == "module:chunk-streamer")
        candidate = copy.deepcopy(canonical)
        candidate["data"]["path"] = "voxel/chunking/Rebound.gd"
        decision = admit_candidate(candidate, [canonical])
        self.assertFalse(decision.valid)
        self.assertEqual("canonical_id_collision", decision.code)

    def test_human_reconstruction_is_deterministic_and_searchable(self):
        first = render_human_markdown(self.source)
        second = render_human_markdown(copy.deepcopy(self.source))
        self.assertEqual(first, second)
        for semantic_id in ["project:gdscript-voxel-terrain", "decision:pems-design-freeze", "observation:roadmap:r2", "env:example-token"]:
            self.assertIn(semantic_id, first)
        self.assertIn("secret-store:example-token", first)
        self.assertNotIn("do-not-store", first)

    def test_malformed_and_noncanonical_wire_input_rejected(self):
        with self.assertRaisesRegex(JcsError, "JCS_PARSE_ERROR"):
            parse_canonical(b"{")
        with self.assertRaisesRegex(JcsError, "JCS_NONCANONICAL_INPUT"):
            parse_canonical(b'{"z":1, "a":2}')

    def test_unknown_cove_profile_rejected(self):
        artifact = encode({"a": 1}, profile="future/9", serializer="jcs/1")
        with self.assertRaises(CoveError):
            decode(artifact, supported_profiles={"pems/1"})

    def test_size_measurement_is_reproducible_and_uses_utf8_bytes(self):
        artifact = encode(self.normalized, profile="pems/1", serializer="jcs/1")
        first = measure_utf8_bytes(self.normalized, artifact)
        second = measure_utf8_bytes(self.normalized, artifact)
        self.assertEqual(first, second)
        self.assertEqual(first["expanded_jcs_bytes"], len(canonicalize(self.normalized)))
        self.assertEqual(first["cove_jcs_bytes"], len(serialize_cove(artifact)))
        self.assertGreater(first["expanded_jcs_bytes"], 0)
        self.assertGreater(first["cove_jcs_bytes"], 0)
        print("PHASE5_SIZE expanded=%d cove=%d" % (first["expanded_jcs_bytes"], first["cove_jcs_bytes"]))

    def test_migration_oriented_fixture_does_not_change_canonical_authority(self):
        sources = {record["id"]: record for record in self.normalized["records"] if record["kind"] == "source"}
        handoff = sources["source:handoff"]
        self.assertEqual("generated_derivative", handoff["data"]["authority"])
        self.assertEqual("docs/project-chat-handoff.json", handoff["data"]["identity_locator"]["path"])
        self.assertFalse(any(record.get("data", {}).get("identity_locator", {}).get("path") == "docs/project-chat-handoff.cove.json" and record.get("data", {}).get("authority") == "canonical" for record in sources.values()))


if __name__ == "__main__":
    unittest.main()
