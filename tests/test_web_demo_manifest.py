import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_SCRIPT = REPOSITORY_ROOT / ".github" / "scripts" / "build_demo_manifest.py"
DEPLOY_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "deploy-web-demo.yml"


class WebDemoManifestTests(unittest.TestCase):
    def test_manifest_keeps_latest_streaming_validation_in_existing_slot(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            archive = Path(temporary_directory)
            self._write_index(archive / "0.8.0")
            self._write_index(archive / "0.8.0" / "chunks")
            self._write_index(archive / "0.8.0" / "streaming")
            self._write_index(archive / "preview" / "integration")
            self._write_index(archive / "preview" / "integration" / "chunks")
            self._write_index(archive / "preview" / "integration" / "streaming")
            self._build_manifest(archive)
            manifest = json.loads((archive / "versions.json").read_text(encoding="utf-8"))
            demos = {demo["key"]: demo for demo in manifest["demos"]}
            self.assertEqual(list(demos), ["terrain", "chunks", "streaming"])
            self.assertEqual(demos["streaming"]["name"], "Runtime Streaming Validation Demo")
            self.assertEqual(demos["streaming"]["releases"][0]["path"], "preview/integration/streaming/")

    def test_manifest_only_lists_streaming_for_releases_that_have_it(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            archive = Path(temporary_directory)
            self._write_index(archive / "0.7.0")
            self._write_index(archive / "0.8.0")
            self._write_index(archive / "0.8.0" / "streaming")
            self._build_manifest(archive)
            manifest = json.loads((archive / "versions.json").read_text(encoding="utf-8"))
            streaming = next(demo for demo in manifest["demos"] if demo["key"] == "streaming")
            self.assertEqual([release["id"] for release in streaming["releases"]], ["0.8.0"])

    def test_deployment_workflow_exports_latest_residency_scene_to_streaming_path(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        bake_command = "godot --headless --path . --script demo/tools/BakeStreamingDemoFixture.gd"
        streaming_target = "build/web/streaming/index.html"
        residency_scene = 'run/main_scene="res://demo/ChunkStreamingValidationDemo.tscn"'
        self.assertIn(bake_command, workflow)
        self.assertIn(streaming_target, workflow)
        self.assertIn(residency_scene, workflow)
        self.assertLess(workflow.index(bake_command), workflow.index(streaming_target))
        self.assertIn('"Runtime Streaming Validation Demo"', workflow)
        self.assertIn('"$ARCHIVE/$ARCHIVE_PATH/streaming"', workflow)
        self.assertNotIn("build/web/residency/index.html", workflow)
        self.assertNotIn('"$ARCHIVE/$ARCHIVE_PATH/residency"', workflow)

    def test_async_loading_branch_publishes_existing_integration_preview(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("      - async-chunk-loading", workflow)
        self.assertIn(
            'elif [ "$GITHUB_REF_NAME" = "nf/integration" ] || [ "$GITHUB_REF_NAME" = "async-chunk-loading" ]; then',
            workflow,
        )
        self.assertIn('echo "archive_path=preview/integration"', workflow)
        self.assertIn('echo "publication_type=preview"', workflow)

    def _build_manifest(self, archive: Path) -> None:
        subprocess.run(["python", str(MANIFEST_SCRIPT), str(archive)], cwd=REPOSITORY_ROOT, check=True)

    def _write_index(self, directory: Path) -> None:
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "index.html").write_text("<!doctype html>\n", encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
