"""Synthetic adapter checks that failed ROI metrics reach the process status."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

SCRIPT = Path(__file__).with_name("awakening_late_seams_evidence.py")
SPEC = importlib.util.spec_from_file_location("awakening_late_seams_evidence_tests", SCRIPT)
adapter = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = adapter
SPEC.loader.exec_module(adapter)


def _write_keyframes(run_dir: Path, color: tuple[int, int, int, int]) -> None:
    keyframes = run_dir / "keyframes"
    keyframes.mkdir(parents=True)
    for _, tick in adapter.SEAMS:
        Image.new("RGBA", (840, 460), color).save(keyframes / f"tick_{tick:06d}.png")


class AwakeningEvidenceAdapterTests(unittest.TestCase):
    def test_failed_roi_checks_return_nonzero_and_list_indices(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            run_dir = root / "run"
            output_dir = root / "out"
            _write_keyframes(run_dir, (0, 0, 0, 0))
            stdout = io.StringIO()
            stderr = io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                code = adapter.main([str(run_dir), "--output-dir", str(output_dir)])

            self.assertEqual(code, 1)
            self.assertIn("failed check indices: 0, 1, 2, 3, 4", stderr.getvalue())
            self.assertTrue((output_dir / "awakening_late_seams_roi_sheet.png").is_file())
            manifest = output_dir / "awakening_late_seams_roi_metrics.json"
            self.assertTrue(manifest.is_file())

    def test_passing_roi_checks_write_sheet_and_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            run_dir = root / "run"
            output_dir = root / "out"
            _write_keyframes(run_dir, (10, 20, 30, 255))
            stdout = io.StringIO()
            stderr = io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                code = adapter.main([str(run_dir), "--output-dir", str(output_dir)])

            self.assertEqual(code, 0)
            self.assertEqual(stderr.getvalue(), "")
            self.assertTrue((output_dir / "awakening_late_seams_roi_sheet.png").is_file())
            manifest = output_dir / "awakening_late_seams_roi_metrics.json"
            self.assertTrue(manifest.is_file())


if __name__ == "__main__":
    unittest.main()
