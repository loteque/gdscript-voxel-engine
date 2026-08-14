import subprocess
import tempfile
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
PATCH_SCRIPT = REPOSITORY_ROOT / ".github" / "scripts" / "prepare_mutable_preview_service_worker.py"
DEPLOY_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "deploy-web-demo.yml"


class MutablePreviewServiceWorkerTests(unittest.TestCase):
    def test_patch_promotes_worker_and_reloads_open_clients(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            worker = Path(temporary_directory) / "index.service.worker.js"
            worker.write_text(
                "const CACHE_VERSION = 'test';\n"
                "self.addEventListener('install', (event) => {});\n"
                "self.addEventListener('activate', (event) => {});\n"
                "self.addEventListener(\n\t'fetch',\n\t(event) => {}\n);\n",
                encoding="utf-8",
            )

            subprocess.run(
                ["python", str(PATCH_SCRIPT), str(worker)],
                cwd=REPOSITORY_ROOT,
                check=True,
            )
            patched = worker.read_text(encoding="utf-8")

            self.assertIn("MUTABLE_PREVIEW_IMMEDIATE_UPDATE", patched)
            self.assertIn("self.skipWaiting()", patched)
            self.assertIn("self.clients.claim()", patched)
            self.assertIn("client.navigate(client.url)", patched)

    def test_patch_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            worker = Path(temporary_directory) / "index.service.worker.js"
            worker.write_text(
                "const CACHE_VERSION = 'test';\n"
                "self.addEventListener('install', (event) => {});\n"
                "self.addEventListener('activate', (event) => {});\n"
                "self.addEventListener(\n\t'fetch',\n\t(event) => {}\n);\n",
                encoding="utf-8",
            )

            command = ["python", str(PATCH_SCRIPT), str(worker)]
            subprocess.run(command, cwd=REPOSITORY_ROOT, check=True)
            once = worker.read_text(encoding="utf-8")
            subprocess.run(command, cwd=REPOSITORY_ROOT, check=True)
            twice = worker.read_text(encoding="utf-8")

            self.assertEqual(once, twice)

    def test_workflow_only_applies_patch_to_preview_publications(self) -> None:
        workflow = DEPLOY_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Refresh mutable streaming preview clients", workflow)
        self.assertIn("if: steps.publication.outputs.publication_type == 'preview'", workflow)
        self.assertIn("prepare_mutable_preview_service_worker.py", workflow)
        self.assertIn("build/web/streaming/index.service.worker.js", workflow)


if __name__ == "__main__":
    unittest.main()
