#!/usr/bin/env python3
"""Regression coverage for Chromium console result extraction."""

from __future__ import annotations

import importlib.util
import pathlib
import unittest


RUNNER_PATH = pathlib.Path(__file__).parents[1] / "demo" / "tools" / "run_web_resource_loading_experiment.py"
SPEC = importlib.util.spec_from_file_location("web_resource_loading_runner", RUNNER_PATH)
assert SPEC is not None and SPEC.loader is not None
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class ResultExtractionTests(unittest.TestCase):
    def test_extracts_plain_result_line(self) -> None:
        line = 'WEB_RESOURCE_LOADING_EXPERIMENT_JSON={"success":true,"value":7}\n'
        self.assertEqual(RUNNER.extract_result_payload(line), {"success": True, "value": 7})

    def test_extracts_chromium_wrapped_console_line(self) -> None:
        line = (
            '[123:123:INFO:CONSOLE:452] '
            '"WEB_RESOURCE_LOADING_EXPERIMENT_JSON={"success":true,"value":7}", '
            'source: http://127.0.0.1:58511/index.js (452)\n'
        )
        self.assertEqual(RUNNER.extract_result_payload(line), {"success": True, "value": 7})

    def test_ignores_unrelated_browser_noise(self) -> None:
        self.assertIsNone(RUNNER.extract_result_payload("Registration response error: DEPRECATED_ENDPOINT\n"))

    def test_rejects_incomplete_json(self) -> None:
        self.assertIsNone(RUNNER.extract_result_payload('WEB_RESOURCE_LOADING_EXPERIMENT_JSON={"success":'))


if __name__ == "__main__":
    unittest.main()
