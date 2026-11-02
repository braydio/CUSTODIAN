"""Synthetic-fixture tests for the presentation-image-metrics helper."""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

SCRIPT = Path(__file__).with_name("presentation_image_metrics.py")
SPEC = importlib.util.spec_from_file_location("custodian_presentation_image_metrics_tests", SCRIPT)
metrics = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = metrics
SPEC.loader.exec_module(metrics)


def _solid(size, color) -> Image.Image:
    return Image.new("RGBA", size, color)


class AlphaBoundsTests(unittest.TestCase):
    def test_bbox_and_coverage_match_known_opaque_rect(self) -> None:
        image = _solid((40, 20), (0, 0, 0, 0))
        for x in range(10, 30):
            for y in range(5, 15):
                image.putpixel((x, y), (255, 0, 0, 255))
        result = metrics.alpha_bounds(image)
        self.assertEqual(result["bbox"], [10, 5, 30, 15])
        self.assertAlmostEqual(result["coverage_ratio"], (20 * 10) / (40 * 20))

    def test_fully_transparent_image_has_no_bbox(self) -> None:
        image = _solid((10, 10), (0, 0, 0, 0))
        result = metrics.alpha_bounds(image)
        self.assertIsNone(result["bbox"])
        self.assertEqual(result["coverage_ratio"], 0.0)

    def test_both_coverage_bounds_are_enforced(self) -> None:
        check = {"min_coverage_ratio": 0.25, "max_coverage_ratio": 0.75}
        opaque = metrics.alpha_bounds(_solid((4, 4), (0, 0, 0, 255)))
        empty = metrics.alpha_bounds(_solid((4, 4), (0, 0, 0, 0)))
        half = _solid((4, 4), (0, 0, 0, 0))
        for y in range(2):
            for x in range(4):
                half.putpixel((x, y), (0, 0, 0, 255))
        middle = metrics.alpha_bounds(half)
        self.assertFalse(metrics._apply_threshold("alpha_bounds", empty, check))
        self.assertFalse(metrics._apply_threshold("alpha_bounds", opaque, check))
        self.assertTrue(metrics._apply_threshold("alpha_bounds", middle, check))


class CropBoundsTests(unittest.TestCase):
    def test_crop_rejects_negative_origin_and_right_or_bottom_overflow(self) -> None:
        image = _solid((20, 10), (0, 0, 0, 255))
        for rect in [(-1, 0, 5, 5), (0, -1, 5, 5), (15, 0, 25, 5), (0, 5, 5, 11)]:
            with self.subTest(rect=rect), self.assertRaises(metrics.MetricsError):
                metrics.alpha_bounds(image, rect)

    def test_crop_rejects_zero_or_negative_dimensions(self) -> None:
        image = _solid((20, 10), (0, 0, 0, 255))
        for rect in [(5, 2, 5, 8), (5, 2, 3, 8)]:
            with self.subTest(rect=rect), self.assertRaises(metrics.MetricsError):
                metrics.alpha_bounds(image, rect)


class MatteVoidTests(unittest.TestCase):
    def test_fully_transparent_roi_is_pure_void(self) -> None:
        image = _solid((20, 20), (0, 0, 0, 0))
        result = metrics.matte_void_check(image)
        self.assertEqual(result["void_ratio"], 1.0)

    def test_uniform_border_is_detected_as_matte(self) -> None:
        image = _solid((20, 20), (12, 12, 12, 255))
        for x in range(5, 15):
            for y in range(5, 15):
                image.putpixel((x, y), (200, 40, 40, 255))
        result = metrics.matte_void_check(image)
        self.assertEqual(result["matte_color"], [12, 12, 12, 255])

    def test_noisy_border_is_not_a_matte(self) -> None:
        image = _solid((10, 10), (0, 0, 0, 255))
        for x in range(10):
            image.putpixel((x, 0), (x * 20, 0, 0, 255))
        result = metrics.matte_void_check(image)
        self.assertIsNone(result["matte_color"])


class RoiDiffTests(unittest.TestCase):
    def test_identical_regions_have_zero_diff(self) -> None:
        image = _solid((10, 10), (5, 5, 5, 255))
        result = metrics.roi_diff(image, image.copy())
        self.assertEqual(result["changed_pixel_ratio"], 0.0)
        self.assertEqual(result["mean_absolute_difference"], 0.0)

    def test_single_pixel_change_is_detected(self) -> None:
        image_a = _solid((10, 10), (5, 5, 5, 255))
        image_b = image_a.copy()
        image_b.putpixel((0, 0), (255, 255, 255, 255))
        result = metrics.roi_diff(image_a, image_b)
        self.assertGreater(result["changed_pixel_ratio"], 0.0)
        self.assertGreater(result["mean_absolute_difference"], 0.0)

    def test_mismatched_sizes_raise(self) -> None:
        image_a = _solid((10, 10), (0, 0, 0, 255))
        image_b = _solid((8, 8), (0, 0, 0, 255))
        with self.assertRaises(metrics.MetricsError):
            metrics.roi_diff(image_a, image_b)


class SeamDiscontinuityTests(unittest.TestCase):
    def test_hard_vertical_edge_is_a_high_discontinuity(self) -> None:
        image = Image.new("RGBA", (20, 10), (0, 0, 0, 255))
        for x in range(10, 20):
            for y in range(10):
                image.putpixel((x, y), (255, 255, 255, 255))
        result = metrics.seam_discontinuity(image, None, "vertical", boundary=10, band=2)
        self.assertGreater(result["mean_absolute_delta"], 150)

    def test_uniform_image_has_no_discontinuity(self) -> None:
        image = _solid((20, 10), (40, 40, 40, 255))
        result = metrics.seam_discontinuity(image, None, "vertical", boundary=10, band=2)
        self.assertEqual(result["mean_absolute_delta"], 0.0)

    def test_single_pixel_vertical_seam_on_boundary_is_detected(self) -> None:
        image = _solid((20, 10), (0, 0, 0, 255))
        for y in range(10):
            image.putpixel((10, y), (255, 0, 0, 255))
        result = metrics.seam_discontinuity(image, None, "vertical", boundary=10, band=2)
        self.assertGreater(result["mean_absolute_delta"], 0.0)
        self.assertEqual(result["samples"], 10)

    def test_single_pixel_horizontal_seam_on_boundary_is_detected(self) -> None:
        image = _solid((20, 10), (0, 0, 0, 255))
        for x in range(20):
            image.putpixel((x, 5), (255, 0, 0, 255))
        result = metrics.seam_discontinuity(image, None, "horizontal", boundary=5, band=1)
        self.assertGreater(result["mean_absolute_delta"], 0.0)
        self.assertEqual(result["samples"], 20)

    def test_boundary_too_close_to_edge_raises(self) -> None:
        image = _solid((20, 10), (0, 0, 0, 255))
        with self.assertRaises(metrics.MetricsError):
            metrics.seam_discontinuity(image, None, "vertical", boundary=1, band=2)


class CropExtractTests(unittest.TestCase):
    def test_crop_matches_requested_rect_size(self) -> None:
        image = _solid((40, 40), (1, 2, 3, 255))
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "crop.png"
            metrics.crop_extract(image, (5, 5, 15, 15), output)
            with Image.open(output) as cropped:
                self.assertEqual(cropped.size, (10, 10))


class AnalyzeSpecTests(unittest.TestCase):
    def test_end_to_end_spec_reports_pass_and_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            opaque = _solid((20, 20), (200, 0, 0, 255))
            opaque.save(root / "a.png")
            spec = {
                "images": {"a": "a.png"},
                "rois": {
                    "full": {"image": "a"},
                    "corner": {"image": "a", "rect": [0, 0, 5, 5]},
                },
                "checks": [
                    {"type": "alpha_bounds", "roi": "full", "min_coverage_ratio": 0.9},
                    {"type": "alpha_bounds", "roi": "corner", "max_coverage_ratio": 0.0},
                ],
            }
            result = metrics.analyze(spec, root)
            self.assertTrue(result["checks"][0]["passed"])
            self.assertFalse(result["checks"][1]["passed"])

    def test_unknown_roi_reference_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _solid((5, 5), (0, 0, 0, 255)).save(root / "a.png")
            spec = {
                "images": {"a": "a.png"},
                "rois": {},
                "checks": [{"type": "alpha_bounds", "roi": "missing"}],
            }
            with self.assertRaises(metrics.MetricsError):
                metrics.analyze(spec, root)


class CliTests(unittest.TestCase):
    def test_main_returns_nonzero_on_failing_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _solid((10, 10), (0, 0, 0, 0)).save(root / "a.png")
            spec_path = root / "spec.json"
            spec_path.write_text(
                json.dumps(
                    {
                        "images": {"a": "a.png"},
                        "rois": {"full": {"image": "a"}},
                        "checks": [{"type": "alpha_bounds", "roi": "full", "min_coverage_ratio": 0.5}],
                    }
                ),
                encoding="utf-8",
            )
            output_path = root / "out.json"
            code = metrics.main([str(spec_path), "--output", str(output_path)])
            self.assertEqual(code, 1)
            payload = json.loads(output_path.read_text(encoding="utf-8"))
            self.assertFalse(payload["checks"][0]["passed"])

    def test_main_returns_zero_on_passing_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _solid((10, 10), (200, 0, 0, 255)).save(root / "a.png")
            spec_path = root / "spec.json"
            spec_path.write_text(
                json.dumps(
                    {
                        "images": {"a": "a.png"},
                        "rois": {"full": {"image": "a"}},
                        "checks": [{"type": "alpha_bounds", "roi": "full", "min_coverage_ratio": 0.5}],
                    }
                ),
                encoding="utf-8",
            )
            code = metrics.main([str(spec_path)])
            self.assertEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
