"""Tests for the compact late-seam evidence adapter."""
from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

SCRIPT = Path(__file__).with_name("awakening_handoff_seam_evidence.py")
SPEC = importlib.util.spec_from_file_location("awakening_handoff_seam_evidence_tests", SCRIPT)
adapter = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = adapter
SPEC.loader.exec_module(adapter)


class AwakeningHandoffSeamEvidenceTests(unittest.TestCase):
    def test_writes_five_ordered_roi_captures_and_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            run_dir = Path(raw) / "run"
            frames = run_dir / "keyframes"
            frames.mkdir(parents=True)
            for _name, tick, _axis, _boundary in adapter.SEAMS:
                Image.new("RGBA", (1280, 720), (40, 60, 80, 255)).save(
                    frames / f"tick_{tick:06d}.png"
                )

            result = adapter.build(run_dir, run_dir / "output")

            captures = sorted(result["roi_dir"].glob("*.png"))
            self.assertEqual([path.name for path in captures], [item[0] + ".png" for item in adapter.SEAMS])
            self.assertTrue(result["sheet"].is_file())
            self.assertTrue(result["metrics"].is_file())
            self.assertTrue(result["manifest"].is_file())
            manifest = __import__("json").loads(result["manifest"].read_text())
            self.assertEqual([capture["order"] for capture in manifest["captures"]], [1, 2, 3, 4, 5])
            self.assertTrue(manifest["human_approval_required"])
            self.assertFalse(manifest["agent_visual_adjudication"])
            metrics = __import__("json").loads(result["metrics"].read_text())
            self.assertEqual(len(metrics["checks"]), 10)
            self.assertTrue(all(check["type"] in {"matte_void", "seam_discontinuity"} for check in metrics["checks"]))

    def test_missing_keyframe_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            run_dir = Path(raw) / "run"
            (run_dir / "keyframes").mkdir(parents=True)
            with self.assertRaises(FileNotFoundError):
                adapter.build(run_dir, run_dir / "output")


if __name__ == "__main__":
    unittest.main()
