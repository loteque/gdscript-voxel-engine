"""Execute COVE v1 Phase 3 generic and normalized-PEMS fixture evidence."""

from __future__ import annotations

import json
from pathlib import Path

from tools.cove import CoveError, decode, encode, measure_structural_json
from tools.pems import load_json, normalize_document
from tools.pems.pems_v1 import default_success_fixture_path


ROOT = Path(__file__).resolve().parents[2]
SUCCESS_PATH = ROOT / "docs" / "handoff" / "cove" / "fixtures" / "generic-success.json"
FAILURE_PATH = ROOT / "docs" / "handoff" / "cove" / "fixtures" / "generic-failure.json"


def main() -> int:
    success = json.loads(SUCCESS_PATH.read_text(encoding="utf-8"))
    failure = json.loads(FAILURE_PATH.read_text(encoding="utf-8"))

    generic_passed = 0
    for case in success["cases"]:
        artifact = encode(case["value"], profile=success["profile"])
        decoded = decode(artifact, supported_profiles={success["profile"]})
        if decoded != case["value"]:
            raise AssertionError(f"generic round trip failed: {case['name']}")
        generic_passed += 1

    malformed_passed = 0
    supported = set(failure["supported_profiles"])
    for case in failure["cases"]:
        try:
            decode(case["artifact"], supported_profiles=supported)
        except CoveError as exc:
            if exc.diagnostic.code != case["expected_code"]:
                raise AssertionError(
                    f"{case['name']}: expected {case['expected_code']}, got {exc.diagnostic.code}"
                ) from exc
        else:
            raise AssertionError(f"malformed fixture unexpectedly decoded: {case['name']}")
        malformed_passed += 1

    pems = normalize_document(load_json(default_success_fixture_path()))
    pems_artifact = encode(pems, profile="pems/1")
    pems_decoded = decode(pems_artifact, supported_profiles={"pems/1"})
    if pems_decoded != pems:
        raise AssertionError("normalized PEMS round trip failed")

    generic_measurement = measure_structural_json(success["cases"][5]["value"], encode(success["cases"][5]["value"], profile="generic/1"))
    pems_measurement = measure_structural_json(pems, pems_artifact)

    print(f"generic_success={generic_passed}/{len(success['cases'])}")
    print(f"generic_malformed={malformed_passed}/{len(failure['cases'])}")
    print("normalized_pems_round_trip=PASS")
    print(
        "generic_structural_chars="
        f"{generic_measurement['expanded_json_chars']}->{generic_measurement['cove_json_chars']}"
    )
    print(
        "pems_structural_chars="
        f"{pems_measurement['expanded_json_chars']}->{pems_measurement['cove_json_chars']}"
    )
    print("NOTE: character counts are observational, not canonical byte measurements.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
