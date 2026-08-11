import importlib.util
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
CLASSIFIER_PATH = REPOSITORY_ROOT / ".github" / "scripts" / "classify_release_changes.py"
VERSION_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "validate-version.yml"

spec = importlib.util.spec_from_file_location("classify_release_changes", CLASSIFIER_PATH)
classifier = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(classifier)


class ReleaseChangeClassificationTests(unittest.TestCase):
    def test_markdown_only_changes_do_not_require_versioned_release(self) -> None:
        self.assertFalse(
            classifier.requires_versioned_release(
                ["README.md", "CONTRIBUTING.md", "docs/performance/README.md"]
            )
        )

    def test_docs_tree_changes_do_not_require_versioned_release(self) -> None:
        self.assertFalse(
            classifier.requires_versioned_release(
                ["docs/performance/result.json", "docs/images/streaming-baseline.png"]
            )
        )

    def test_code_or_workflow_change_requires_versioned_release(self) -> None:
        self.assertTrue(
            classifier.requires_versioned_release(
                ["docs/performance/README.md", "voxel/chunk/ChunkStreamer.gd"]
            )
        )
        self.assertTrue(
            classifier.requires_versioned_release(
                [".github/workflows/validate-version.yml"]
            )
        )

    def test_workflow_uses_classifier_to_gate_release_validation(self) -> None:
        workflow = VERSION_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("classify_release_changes.py", workflow)
        self.assertIn("versioned: ${{ steps.changes.outputs.versioned }}", workflow)
        self.assertIn("if: steps.changes.outputs.versioned == 'true'", workflow)
        self.assertIn("if: needs.validate-version.outputs.versioned == 'true'", workflow)


if __name__ == "__main__":
    unittest.main()
