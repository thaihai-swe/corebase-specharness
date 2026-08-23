"""Tests for Option B: Stateless / inline mechanical verification on closeout."""

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "kit"
SCRIPTS = KIT / "corebase-specharness" / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from core.handlers.envelope import apply_status
from core.handlers.lifecycle import run_verification


class InlineCloseoutTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.root = Path(self.temp_dir)
        source_kit = Path(__file__).resolve().parents[1] / "kit"

        # Copy kit structure into temporary workspace
        shutil.copytree(source_kit / "skills", self.root / "skills")
        shutil.copytree(source_kit / "references", self.root / "references")
        shutil.copytree(source_kit / "corebase-specharness", self.root / "corebase-specharness")
        shutil.copy(source_kit / "manifest.json", self.root / "manifest.json")
        (self.root / "artifacts" / "features").mkdir(parents=True, exist_ok=True)

        # Set up a sample feature in Verifying state
        self.feature = "test-feature"
        self.feature_dir = self.root / "artifacts" / "features" / self.feature
        self.feature_dir.mkdir(parents=True, exist_ok=True)

        (self.feature_dir / "status.md").write_text(
            "# Feature Status: test-feature\n\n- Phase: Verifying\n- Delivery profile: Moderate\n- Status: Active\n- Active task: None\n",
            encoding="utf-8",
        )
        (self.feature_dir / "spec.md").write_text(
            "# Spec\n\n## Metadata\n- Feature: test-feature\n\n## Problem Statement\nTest\n\n## Acceptance Criteria\n- AC-001: First AC\n",
            encoding="utf-8",
        )
        (self.feature_dir / "plan.md").write_text(
            "# Plan\n\n## Metadata\n- Feature: test-feature\n\n## Approach\nApproach details\n",
            encoding="utf-8",
        )
        (self.feature_dir / "tasks.md").write_text(
            "# Tasks\n\n## Metadata\n- Feature: test-feature\n\n## Tasks\n\n- [x] T-001 First task\n  - Status: Done\n  - Depends on: None\n  - Validation evidence: python3 -c 'print(1)'\n  - AC-001\n",
            encoding="utf-8",
        )
        (self.feature_dir / "review.md").write_text(
            "# Review\n\n## Decision\nPass\n\n## Standards Review\nPass\n",
            encoding="utf-8",
        )
        (self.feature_dir / "session-extracts.md").write_text(
            "# Session Extracts: test-feature\n\n## Post-Ship Sync\n- no candidates\n",
            encoding="utf-8",
        )

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_verify_does_not_create_generated_json_files(self):
        """verify command executes and produces no files under .corebase-specharness/generated/."""
        outcome = run_verification(self.root, self.feature, skill="harness-verify")
        # With zero gates configured by default, verified is False
        self.assertFalse(outcome["verified"])

        generated_dir = self.root / ".corebase-specharness" / "generated"
        self.assertFalse(generated_dir.exists())

    def test_done_without_gates_fails_unless_overridden(self):
        """skill-exit to Done runs inline verification and rejects closeout if unverified."""
        res = apply_status(
            self.root,
            self.feature,
            "Done",
            source_skill="harness-verify",
        )
        self.assertEqual(res["status"], "failed")
        self.assertIn("Done requires passing verification", res["errors"][0])

        generated_dir = self.root / ".corebase-specharness" / "generated"
        self.assertFalse(generated_dir.exists())

    def test_done_with_explicit_override_succeeds_without_files(self):
        """skill-exit with explicit override transitions to Done without creating JSON log files."""
        res = apply_status(
            self.root,
            self.feature,
            "Done",
            source_skill="harness-verify",
            verification_override=True,
            override_reason="Advisory test suite with manual QA signoff",
        )
        self.assertEqual(res["status"], "ok")

        # Verify status.md transitioned to Done
        status_text = (self.feature_dir / "status.md").read_text(encoding="utf-8")
        self.assertIn("- Phase: Done", status_text)

        # Confirm zero generated run logs exist
        generated_dir = self.root / ".corebase-specharness" / "generated"
        self.assertFalse(generated_dir.exists())

    def test_done_with_passing_gate_succeeds_inline(self):
        """When confirmed gate passes, inline verification authorizes Done seamlessly."""
        # Add a passing gate to harness-config.yaml
        config_path = self.root / "corebase-specharness" / "project" / "harness-config.yaml"
        config_path.write_text(
            "project_setup:\n  status: ready\ngates:\n  - name: test-gate\n    command: ['true']\n    on_fail: block\n    category: test\nthresholds:\n  timeout_seconds: 30\n",
            encoding="utf-8",
        )

        res = apply_status(
            self.root,
            self.feature,
            "Done",
            source_skill="harness-verify",
        )
        self.assertEqual(res["status"], "ok", f"Expected ok but got errors: {res.get('errors')}")

        status_text = (self.feature_dir / "status.md").read_text(encoding="utf-8")
        self.assertIn("- Phase: Done", status_text)

        generated_dir = self.root / ".corebase-specharness" / "generated"
        self.assertFalse(generated_dir.exists())


if __name__ == "__main__":
    unittest.main()
