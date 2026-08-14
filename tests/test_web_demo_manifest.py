import json
import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MANIFEST_SCRIPT = REPOSITORY_ROOT / ".github" / "scripts" / "build_demo_manifest.py"
PREVIEW_WORKER_SCRIPT = REPOSITORY_ROOT / ".github" / "scripts" / "prepare_mutable_preview_service_worker.py"
DEPLOY_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "deploy-web-demo.yml"
EXPORT_PRESETS = REPOSITORY_ROOT / "export_presets.cfg"


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

    def test_deployment_workflow_exports_latest_streaming_validation_to_existing_path(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        bake_command = "godot --headless --path . --script demo/tools/BakeStreamingDemoFixture.gd"
        streaming_target = "build/web/streaming/index.html"
        current_scene = 'run/main_scene="res://demo/RuntimeWorkloadExperiment.tscn"'
        self.assertIn(bake_command, workflow)
        self.assertIn(streaming_target, workflow)
        self.assertIn(current_scene, workflow)
        self.assertLess(workflow.index(bake_command), workflow.index(streaming_target))
        self.assertIn('"$ARCHIVE/$ARCHIVE_PATH/streaming"', workflow)
        self.assertNotIn("build/web/residency/index.html", workflow)
        self.assertNotIn('"$ARCHIVE/$ARCHIVE_PATH/residency"', workflow)

    def test_current_streaming_feature_branch_publishes_existing_integration_preview(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("      - resource-loading-analysis", workflow)
        self.assertIn("      - runtime-workload-isolation", workflow)
        self.assertIn('[ "$GITHUB_REF_NAME" = "runtime-workload-isolation" ]', workflow)
        self.assertIn('echo "archive_path=preview/integration"', workflow)
        self.assertIn('echo "publication_type=preview"', workflow)
        self.assertNotIn("      - chunk-residency-hysteresis", workflow)

    def test_streaming_preview_uses_thread_capable_web_export(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        presets = EXPORT_PRESETS.read_text(encoding="utf-8")
        self.assertIn('--export-release "Web Threads"', workflow)
        self.assertIn('name="Web Threads"', presets)
        self.assertIn('variant/thread_support=true', presets)
        self.assertIn('progressive_web_app/enabled=true', presets)
        self.assertIn('progressive_web_app/ensure_cross_origin_isolation_headers=true', presets)

    def test_mutable_streaming_preview_promotes_new_service_worker(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Refresh mutable streaming preview clients", workflow)
        self.assertIn("if: steps.publication.outputs.publication_type == 'preview'", workflow)
        self.assertIn("prepare_mutable_preview_service_worker.py", workflow)
        self.assertIn("build/web/streaming/index.service.worker.js", workflow)

        with tempfile.TemporaryDirectory() as temporary_directory:
            worker = Path(temporary_directory) / "index.service.worker.js"
            worker.write_text(
                "const CACHE_VERSION = 'test';\n"
                "self.addEventListener('install', (event) => {});\n"
                "self.addEventListener('activate', (event) => {});\n"
                "self.addEventListener(\n\t'fetch',\n\t(event) => {}\n);\n",
                encoding="utf-8",
            )
            command = ["python", str(PREVIEW_WORKER_SCRIPT), str(worker)]
            subprocess.run(command, cwd=REPOSITORY_ROOT, check=True)
            once = worker.read_text(encoding="utf-8")
            subprocess.run(command, cwd=REPOSITORY_ROOT, check=True)
            twice = worker.read_text(encoding="utf-8")

            self.assertEqual(once, twice)
            self.assertIn("MUTABLE_PREVIEW_IMMEDIATE_UPDATE", once)
            self.assertIn("self.skipWaiting()", once)
            self.assertIn("self.clients.claim()", once)
            self.assertIn("client.navigate(client.url)", once)

    def _build_manifest(self, archive: Path) -> None:
        subprocess.run(["python", str(MANIFEST_SCRIPT), str(archive)], cwd=REPOSITORY_ROOT, check=True)

    def _write_index(self, directory: Path) -> None:
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "index.html").write_text("<!doctype html>\n", encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
