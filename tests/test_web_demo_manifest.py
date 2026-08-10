import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_SCRIPT = REPOSITORY_ROOT / ".github" / "scripts" / "build_demo_manifest.py"
DEPLOY_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "deploy-web-demo.yml"


class WebDemoManifestTests(unittest.TestCase):
    def test_manifest_exposes_streaming_preview_and_preserves_existing_demos(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            archive = Path(temporary_directory)
            self._write_index(archive / "0.2.0")
            self._write_index(archive / "0.2.0" / "chunks")
            self._write_index(archive / "preview" / "integration")
            self._write_index(archive / "preview" / "integration" / "chunks")
            self._write_index(archive / "preview" / "integration" / "streaming")

            self._build_manifest(archive)
            manifest = json.loads((archive / "versions.json").read_text(encoding="utf-8"))
            demos = {demo["key"]: demo for demo in manifest["demos"]}

            self.assertEqual(
                list(demos),
                ["terrain", "chunks", "streaming"],
            )
            self.assertEqual(demos["terrain"]["name"], "Terrain / Surface Nets Demo")
            self.assertEqual(demos["chunks"]["name"], "Chunk Validation Demo")
            self.assertEqual(demos["streaming"]["name"], "Chunk Streaming Demo")
            self.assertEqual(
                demos["streaming"]["releases"][0]["path"],
                "preview/integration/streaming/",
            )

    def test_manifest_only_lists_streaming_for_releases_that_have_it(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            archive = Path(temporary_directory)
            self._write_index(archive / "0.1.0")
            self._write_index(archive / "0.1.0" / "chunks")
            self._write_index(archive / "0.2.0")
            self._write_index(archive / "0.2.0" / "chunks")
            self._write_index(archive / "0.2.0" / "streaming")

            self._build_manifest(archive)
            manifest = json.loads((archive / "versions.json").read_text(encoding="utf-8"))
            streaming = next(demo for demo in manifest["demos"] if demo["key"] == "streaming")

            self.assertEqual(
                [release["id"] for release in streaming["releases"]],
                ["0.2.0"],
            )
            self.assertEqual(streaming["releases"][0]["path"], "0.2.0/streaming/")

    def test_deployment_workflow_exports_and_archives_streaming_demo(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")

        self.assertIn("res://demo/ChunkStreamingValidationDemo.tscn", workflow)
        self.assertIn("build/web/streaming/index.html", workflow)
        self.assertIn("streaming_manifest_url=../../versions.json", workflow)
        self.assertIn("streaming_manifest_url=../../../versions.json", workflow)
        self.assertIn("streaming \\", workflow)
        self.assertIn('"Chunk Streaming Demo"', workflow)
        self.assertIn('"$ARCHIVE/$ARCHIVE_PATH/streaming"', workflow)

    def _build_manifest(self, archive: Path) -> None:
        subprocess.run(
            ["python", str(MANIFEST_SCRIPT), str(archive)],
            cwd=REPOSITORY_ROOT,
            check=True,
        )

    def _write_index(self, directory: Path) -> None:
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "index.html").write_text("<!doctype html>\n", encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
