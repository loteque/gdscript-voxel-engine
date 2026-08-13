import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class StreamingExperimentEvidencePipelineTests(unittest.TestCase):
    def test_streaming_preview_uses_selector_without_legacy_banner(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            index = Path(temp_dir) / "index.html"
            index.write_text("<html><body></body></html>", encoding="utf-8")
            subprocess.run(
                [
                    sys.executable,
                    str(ROOT / ".github/scripts/inject_demo_selector.py"),
                    str(index),
                    "integration",
                    "Integration Preview",
                    "streaming",
                    "Runtime Streaming Validation Demo",
                    "../../../versions.json",
                ],
                check=True,
            )
            html = index.read_text(encoding="utf-8")
            self.assertIn("Runtime Streaming Validation Demo · Integration Preview", html)
            self.assertIn('id="voxel-demo-selector"', html)
            self.assertNotIn("CORRECT TEST: ChunkStreamer Lifecycle Experiment", html)
            self.assertNotIn("streaming-experiment-", html)

    def test_strategy_page_explicitly_rejects_lifecycle_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            index = Path(temp_dir) / "index.html"
            index.write_text("<html><body></body></html>", encoding="utf-8")
            subprocess.run(
                [
                    sys.executable,
                    str(ROOT / ".github/scripts/inject_resource_loading_strategy_ui.py"),
                    str(index),
                ],
                check=True,
            )
            html = index.read_text(encoding="utf-8")
            self.assertIn("NOT THE CHUNKSTREAMER LIFECYCLE TEST", html)
            self.assertIn("Open ChunkStreamer Lifecycle Experiment", html)
            self.assertIn("mobile-resource-loading-strategy-comparison-NOT-LIFECYCLE.json", html)

    def test_streaming_export_contract_contains_lifecycle_observations(self) -> None:
        demo_source = (ROOT / "demo/ChunkStreamingValidationDemo.gd").read_text(encoding="utf-8")
        streamer_source = (ROOT / "voxel/chunking/ChunkStreamer.gd").read_text(encoding="utf-8")

        self.assertIn('"experiment": "resource-loading-analysis-web-matrix"', demo_source)
        self.assertIn('"load_observations": _streamer.get_completed_load_observations()', demo_source)
        self.assertIn('"streaming-experiment-%s.json"', demo_source)

        for field in (
            "desired_to_queued_msec",
            "request_to_first_poll_msec",
            "first_poll_to_completion_msec",
            "total_desired_to_resident_msec",
        ):
            self.assertIn(field, streamer_source)


if __name__ == "__main__":
    unittest.main()
