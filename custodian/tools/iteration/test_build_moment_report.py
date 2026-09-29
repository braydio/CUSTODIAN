"""Focused tests for the compact ROI/contact-sheet builder."""

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

SCRIPT = Path(__file__).with_name("build_moment_report.py")
SPEC = importlib.util.spec_from_file_location("custodian_build_moment_report_tests", SCRIPT)
report = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = report
SPEC.loader.exec_module(report)


class BuildRoiContactSheetTests(unittest.TestCase):
    def test_compact_sheet_is_far_smaller_than_full_frames(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            frame_path = root / "frame.png"
            Image.new("RGBA", (1280, 720), (20, 20, 20, 255)).save(frame_path)
            cells = [
                {"label": "seam a", "image": frame_path, "rect": [0, 0, 120, 90]},
                {"label": "seam b", "image": frame_path, "rect": [200, 100, 120, 90]},
            ]
            output = root / "roi_sheet.png"
            report.build_roi_contact_sheet(cells, output, columns=2)
            with Image.open(output) as sheet:
                self.assertEqual(sheet.size, (240, 112))
            self.assertLess(output.stat().st_size, frame_path.stat().st_size)

    def test_empty_cells_raise(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                report.build_roi_contact_sheet([], Path(tmp) / "out.png")


if __name__ == "__main__":
    unittest.main()
