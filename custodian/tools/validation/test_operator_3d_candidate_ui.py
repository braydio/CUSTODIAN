"""Textual pilot for 3D candidate preview controls: examiner and transition keys must stay single-view.

Requires Textual, so run with the repository virtual environment:
  .venv/bin/python -I custodian/tools/validation/test_operator_3d_candidate_ui.py -v

Builds the same synthetic fixture as test_operator_3d_candidate_intake.py.
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_operator_3d_candidate_intake as fixtures  # noqa: E402

from ui.app import OperatorWorkbenchApp  # noqa: E402
from ui.state import AnimationSelection  # noqa: E402


def setUpModule():
    fixtures.setUpModule()


def tearDownModule():
    fixtures.tearDownModule()


class CandidateExaminerControls(fixtures.Fixture, unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        super().setUp()
        # The app's refresh reads the real implementation plan; the synthetic repo needs its own copy.
        plan = fixtures.REPO / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
        target = self.repo / "design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(plan.read_bytes())

    async def test_split_diff_transition_and_compare_keys_never_leave_single_view(self):
        self.run_intake("apply")
        selection = AnimationSelection("unarmed", "locomotion", "walk_01", "s", art_generation="operator_3d_80")
        app = OperatorWorkbenchApp(service=self.service(), startup=selection)
        async with app.run_test(size=(160, 50)) as pilot:
            await pilot.pause(4.0)
            app.set_focus(None)
            app.action_mode_preview()
            await pilot.pause(1.5)
            self.assertEqual(app.preview_view.source, "candidate")
            for key in ("shift+d", "shift+d", "shift+d", "shift+d", "t", "shift+t", "shift+s", "s"):
                await pilot.press(key)
                await pilot.pause(0.2)
            self.assertEqual(app.state.mode, "preview")
            self.assertEqual(app.state.preview_examiner_mode, "single")
            self.assertEqual(app.state.preview_source, "candidate")
            self.assertEqual(app.transition_candidates, ())
            self.assertEqual(app.preview_comparisons, ())
            messages = [event.message for event in app.state.activity]
            self.assertNotEqual(type(app.screen).__name__, "ErrorDialog", [(e.severity, e.message) for e in app.state.activity][-6:])
            self.assertTrue(any("single preview only" in message for message in messages), messages[-5:])

    async def test_stale_split_state_is_reset_when_a_candidate_session_loads(self):
        self.run_intake("apply")
        selection = AnimationSelection("unarmed", "locomotion", "walk_01", "s", art_generation="operator_3d_80")
        app = OperatorWorkbenchApp(service=self.service(), startup=selection)
        async with app.run_test(size=(160, 50)) as pilot:
            await pilot.pause(4.0)
            app.state.preview_examiner_mode = "split"
            await app._load_session(selection)
            await pilot.pause(0.3)
            self.assertEqual(app.state.preview_examiner_mode, "single")


if __name__ == "__main__":
    unittest.main()
