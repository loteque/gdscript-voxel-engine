import json
import math
import unittest

from tools.cove.cove_v1 import decode, encode
from tools.cove.jcs_v1 import JcsError, canonicalize, measure_utf8_bytes, parse_canonical, serialize_cove


class JcsV1Tests(unittest.TestCase):
    def test_rfc8785_sample(self):
        value = {
            "numbers": [333333333.33333329, 1e30, 4.50, 2e-3, 1e-27],
            "string": "€$\u000f\nA'B\"\\\"/",
            "literals": [None, True, False],
        }
        expected = b'{"literals":[null,true,false],"numbers":[333333333.3333333,1e+30,4.5,0.002,1e-27],"string":"\xe2\x82\xac$\\u000f\\nA\'B\\\"\\\\\\\"/"}'
        self.assertEqual(canonicalize(value), expected)

    def test_rfc8785_number_samples(self):
        samples = [
            (0.0, b"0"),
            (-0.0, b"0"),
            (1e30, b"1e+30"),
            (1e-7, b"1e-7"),
            (1e-6, b"0.000001"),
            (1e20, b"100000000000000000000"),
            (1e21, b"1e+21"),
        ]
        for value, expected in samples:
            with self.subTest(value=value):
                self.assertEqual(canonicalize(value), expected)

    def test_safe_and_unsafe_integer_boundary(self):
        self.assertEqual(canonicalize(9007199254740991), b"9007199254740991")
        with self.assertRaises(JcsError):
            canonicalize(9007199254740992)

    def test_deterministic_bytes_and_key_order(self):
        left = {"z": 1, "a": {"b": 2, "a": 1}}
        right = {"a": {"a": 1, "b": 2}, "z": 1}
        expected = b'{"a":{"a":1,"b":2},"z":1}'
        self.assertEqual(canonicalize(left), expected)
        self.assertEqual(canonicalize(right), expected)
        self.assertEqual(canonicalize(left), canonicalize(left))

    def test_noncanonical_input_rejected(self):
        with self.assertRaisesRegex(JcsError, "JCS_NONCANONICAL_INPUT"):
            parse_canonical(b'{"b":2, "a":1}')

    def test_malformed_input_rejected(self):
        with self.assertRaisesRegex(JcsError, "JCS_PARSE_ERROR"):
            parse_canonical(b'{')

    def test_cove_byte_round_trip_and_measurement(self):
        value = {"hello": "world", "nested": [None, True, 1.5]}
        artifact = encode(value, profile="generic/1", serializer="jcs/1")
        data = serialize_cove(artifact)
        reparsed = parse_canonical(data)
        self.assertEqual(decode(reparsed, supported_profiles={"generic/1"}), value)
        measurement = measure_utf8_bytes(value, artifact)
        self.assertEqual(measurement["expanded_jcs_bytes"], len(canonicalize(value)))
        self.assertEqual(measurement["cove_jcs_bytes"], len(data))

    def test_serializer_metadata_required(self):
        artifact = encode({"a": 1}, profile="generic/1")
        with self.assertRaisesRegex(JcsError, "JCS_SERIALIZER_MISMATCH"):
            serialize_cove(artifact)

    def test_nonfinite_numbers_rejected(self):
        for value in [math.inf, -math.inf, math.nan]:
            with self.subTest(value=value):
                with self.assertRaises(JcsError):
                    canonicalize(value)


if __name__ == "__main__":
    unittest.main()
