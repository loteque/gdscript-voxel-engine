#!/usr/bin/env python3
"""Run the frozen PEMS v1 fixture suite and return a process status."""

from __future__ import annotations

from tools.pems import run_fixture_suite


def main() -> int:
    results = run_fixture_suite()
    failures = [result for result in results if not result.passed]

    for result in results:
        marker = "PASS" if result.passed else "FAIL"
        detail = f" ({result.details})" if result.details else ""
        print(
            f"{marker} {result.case_id}: "
            f"stage={result.stage} expected={result.expected_code} "
            f"actual={result.actual_code}{detail}"
        )

    print(f"\n{len(results) - len(failures)}/{len(results)} fixture checks passed.")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
