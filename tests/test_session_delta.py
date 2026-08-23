#!/usr/bin/env python3
"""Session auto-delta accumulates fingerprints across skills."""

import shutil
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "kit"
SCRIPTS = KIT / "corebase-specharness" / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from core._lib.artifacts import canonical_feature_dir
from core.context_engine import build_context_pack
from core.context_state import (
    create_session,
    default_session_path,
    last_pack_manifest,
    record_context_pack,
)


class SessionDeltaTests(unittest.TestCase):
    feature = "delta-reuse"

    def setUp(self):
        self.root = KIT
        self.feature_dir = canonical_feature_dir(self.root, self.feature)
        self.feature_dir.mkdir(parents=True, exist_ok=True)
        (self.feature_dir / "status.md").write_text(
            "# Status\n\n- Phase: Specifying\n", encoding="utf-8"
        )
        (self.feature_dir / "analysis.md").write_text(
            "# Analysis\n\n## Findings\n\nProbe finding.\n", encoding="utf-8"
        )
        (self.feature_dir / "spec.md").write_text(
            "# Spec\n\n## Acceptance Criteria\n\n- AC-01 ok\n", encoding="utf-8"
        )
        self.session_path = default_session_path(self.root, self.feature)
        create_session(
            self.session_path,
            {
                "feature": self.feature,
                "skill": "spec-requirements",
                "phase": "Spec",
                "created_by": "test",
            },
        )
        self.addCleanup(self._cleanup)

    def _cleanup(self):
        shutil.rmtree(self.feature_dir, ignore_errors=True)
        if self.session_path:
            shutil.rmtree(self.session_path.parent, ignore_errors=True)

    def _paths(self, pack):
        return {item["path"] for item in pack.get("selected") or []}

    def test_plan_skips_sources_already_loaded_by_requirements(self):
        requirements = build_context_pack(
            root=self.root, skill="spec-requirements", feature=self.feature,
        )
        record_context_pack(self.root, self.feature, requirements)
        self.assertIn("corebase-specharness/rules/caveman.md", self._paths(requirements))
        self.assertIn(
            "corebase-specharness/memories/repo/core-policies.md",
            self._paths(requirements),
        )

        plan = build_context_pack(
            root=self.root,
            skill="spec-plan",
            feature=self.feature,
            delta_from=last_pack_manifest(self.root, self.feature),
        )
        selected = self._paths(plan)
        self.assertTrue(plan.get("delta"))
        self.assertNotIn("corebase-specharness/rules/caveman.md", selected)
        self.assertNotIn("corebase-specharness/memories/repo/core-policies.md", selected)
        self.assertNotIn("artifacts/features/delta-reuse/status.md", selected)
        self.assertIn("artifacts/features/delta-reuse/spec.md", selected)
        self.assertIn("corebase-specharness/project/architecture.md", selected)
        self.assertIn("corebase-specharness/rules/code-design.md", selected)
        omitted = {item["path"] for item in plan.get("delta_omitted") or []}
        self.assertIn("corebase-specharness/rules/caveman.md", omitted)

    def test_plan_injects_only_new_architecture_section_after_research(self):
        research = build_context_pack(
            root=self.root, skill="spec-research", feature=self.feature,
        )
        record_context_pack(self.root, self.feature, research)
        requirements = build_context_pack(
            root=self.root,
            skill="spec-requirements",
            feature=self.feature,
            delta_from=last_pack_manifest(self.root, self.feature),
        )
        record_context_pack(self.root, self.feature, requirements)

        plan = build_context_pack(
            root=self.root,
            skill="spec-plan",
            feature=self.feature,
            delta_from=last_pack_manifest(self.root, self.feature),
        )
        architecture = [
            item for item in plan["selected"]
            if item["path"] == "corebase-specharness/project/architecture.md"
        ]
        self.assertEqual(len(architecture), 1, plan.get("delta_omitted"))
        self.assertEqual(architecture[0].get("sections"), ["Safe Change Guidance"])
        self.assertEqual(architecture[0].get("delta_reason"), "changed")

    def test_full_pack_is_unchanged_without_delta(self):
        plan = build_context_pack(
            root=self.root, skill="spec-plan", feature=self.feature,
        )
        self.assertFalse(plan.get("delta"))
        self.assertIn("corebase-specharness/rules/caveman.md", self._paths(plan))
        self.assertIn("corebase-specharness/project/architecture.md", self._paths(plan))
        architecture = next(
            item for item in plan["selected"]
            if item["path"] == "corebase-specharness/project/architecture.md"
        )
        self.assertEqual(
            architecture.get("sections"),
            [
                "System Snapshot",
                "Top-Level Components",
                "Runtime Boundaries",
                "Safe Change Guidance",
            ],
        )


if __name__ == "__main__":
    unittest.main()
