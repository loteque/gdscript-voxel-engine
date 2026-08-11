import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_SCRIPT = REPOSITORY_ROOT / ".github" / "scripts" / "build_demo_manifest.py"
DEPLOY_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "deploy-web-demo.yml"


class WebDemoManifestTests(unittest.TestCase):
    def test_manifest_exposes_residency_preview_and_preserves_existing_demos(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            archive = Path(temporary_directory)
            self._write_index(archive / "0.2.0")
            self._write_index(archive / "0.2.0" / "chunks")
            self._write_index(archive / "preview" / "integration")
            self._write_index(archive / "preview" / "integration" / "chunks")
            self._write_index(archive / "preview" / "integration" / "streaming")
            self._write_index(archive / "preview" / "integration" / "residency")
            self._build_manifest(archive)
            manifest = json.loads((archive / "versions.json").read_text(encoding="utf-8"))
            demos = {demo["key"]: demo for demo in manifest["demos"]}
            self.assertEqual(list(demos), ["terrain", "chunks", "streaming", "residency"])
            self.assertEqual(demos["streaming"]["name"], "Chunk Streaming Demo")
            self.assertEqual(demos["streaming"]["releases"][0]["path"], "preview/integration/streaming/")
            self.assertEqual(demos["residency"]["name"], "Chunk Residency Validation Demo")
            self.assertEqual(demos["residency"]["releases"][0]["path"], "preview/integration/residency/")

    def test_manifest_only_lists_residency_for_releases_that_have_it(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            archive = Path(temporary_directory)
            self._write_index(archive / "0.8.0")
            self._write_index(archive / "0.8.0" / "streaming")
            self._write_index(archive / "0.9.0")
            self._write_index(archive / "0.9.0" / "streaming")
            self._write_index(archive / "0.9.0" / "residency")
            self._build_manifest(archive)
            manifest = json.loads((archive / "versions.json").read_text(encoding="utf-8"))
            residency = next(demo for demo in manifest["demos"] if demo["key"] == "residency")
            self.assertEqual([release["id"] for release in residency["releases"]], ["0.9.0"])

    def test_deployment_workflow_exports_residency_demo_after_bake(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        bake_command = "godot --headless --path . --script demo/tools/BakeStreamingDemoFixture.gd"
        streaming_target = "build/web/streaming/index.html"
        residency_target = "build/web/residency/index.html"
        self.assertIn(bake_command, workflow)
        self.assertIn(streaming_target, workflow)
        self.assertIn(residency_target, workflow)
        self.assertLess(workflow.index(bake_command), workflow.index(streaming_target))
        self.assertLess(workflow.index(bake_command), workflow.index(residency_target))
        self.assertIn('"Chunk Streaming Demo"', workflow)
        self.assertIn('"Chunk Residency Validation Demo"', workflow)
        self.assertIn('"$ARCHIVE/$ARCHIVE_PATH/streaming"', workflow)
        self.assertIn('"$ARCHIVE/$ARCHIVE_PATH/residency"', workflow)

    def _build_manifest(self, archive: Path) -> None:
        subprocess.run(["python", str(MANIFEST_SCRIPT), str(archive)], cwd=REPOSITORY_ROOT, check=True)

    def _write_index(self, directory: Path) -> None:
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "index.html").write_text("<!doctype html>\n", encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
