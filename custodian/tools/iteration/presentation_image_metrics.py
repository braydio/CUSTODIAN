#!/usr/bin/env python3
"""Deterministic offline presentation-image metrics for Visual Validation Economy.

Turns full-resolution renderer PNGs into small, threshold-configurable JSON
facts (alpha bounds/coverage, matte/void detection, ROI diff, seam
discontinuity, exact crop) so agents can settle most objective visual
acceptance without model-vision inspection of every frame. See the Visual
Validation Economy section of `custodian/AGENTS.md` and
`design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`.

These are technical pixel measurements, not aesthetic scoring. Subjective
art-direction/baseline decisions stay human-owned.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from PIL import Image

SCHEMA = "custodian.presentation_image_metrics.v1"

Rect = tuple[int, int, int, int]


class MetricsError(ValueError):
    """Raised for a malformed spec, unusable image, or invalid ROI."""


def _rect_from_list(raw: Any) -> Rect:
    if not isinstance(raw, (list, tuple)) or len(raw) != 4:
        raise MetricsError(f"rect must be [x, y, width, height]: {raw!r}")
    x, y, w, h = (int(value) for value in raw)
    if w <= 0 or h <= 0:
        raise MetricsError(f"rect width/height must be positive: {raw!r}")
    return (x, y, x + w, y + h)


def load_image(path: Path) -> Image.Image:
    if not path.is_file():
        raise MetricsError(f"image not found: {path}")
    return Image.open(path).convert("RGBA")


def _crop(image: Image.Image, rect: Rect | None) -> Image.Image:
    if rect is None:
        return image
    left, top, right, bottom = rect
    if left < 0 or top < 0 or right > image.width or bottom > image.height:
        raise MetricsError(
            f"ROI {rect!r} lies outside image bounds [0, 0, {image.width}, {image.height}]"
        )
    if right <= left or bottom <= top:
        raise MetricsError(f"ROI must have positive width and height: {rect!r}")
    return image.crop(rect)


def alpha_bounds(image: Image.Image, rect: Rect | None = None, threshold: int = 0) -> dict[str, Any]:
    """Bounding box and coverage ratio of pixels with alpha > threshold within an ROI."""
    region = _crop(image, rect)
    alpha = region.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    opaque_pixels = sum(count for value, count in enumerate(mask.histogram()) if value > 0)
    total_pixels = max(1, region.width * region.height)
    return {
        "size": [region.width, region.height],
        "bbox": list(bbox) if bbox else None,
        "opaque_pixel_count": opaque_pixels,
        "coverage_ratio": opaque_pixels / total_pixels,
    }


def _border_pixels(image: Image.Image) -> list[tuple[int, int, int, int]]:
    width, height = image.size
    if width == 0 or height == 0:
        return []
    pixels = image.load()
    border: list[tuple[int, int, int, int]] = []
    for x in range(width):
        border.append(pixels[x, 0])
        border.append(pixels[x, height - 1])
    for y in range(height):
        border.append(pixels[0, y])
        border.append(pixels[width - 1, y])
    return border


def matte_void_check(
    image: Image.Image,
    rect: Rect | None = None,
    void_alpha_max: int = 8,
    matte_tolerance: int = 6,
) -> dict[str, Any]:
    """Detect a fully-transparent void or a uniform-color matte border within an ROI."""
    region = _crop(image, rect)
    pixels = list(region.getdata())
    total = max(1, len(pixels))
    void_pixels = sum(1 for pixel in pixels if pixel[3] <= void_alpha_max)
    border_pixels = _border_pixels(region)
    matte_color = None
    matte_border_ratio = 0.0
    if border_pixels:
        reference = border_pixels[0]
        matching = sum(
            1
            for pixel in border_pixels
            if all(abs(pixel[channel] - reference[channel]) <= matte_tolerance for channel in range(4))
        )
        matte_border_ratio = matching / len(border_pixels)
        if matte_border_ratio >= 0.98:
            matte_color = list(reference)
    return {
        "void_ratio": void_pixels / total,
        "matte_color": matte_color,
        "matte_border_ratio": matte_border_ratio,
    }


def roi_diff(
    image_a: Image.Image,
    image_b: Image.Image,
    rect_a: Rect | None = None,
    rect_b: Rect | None = None,
) -> dict[str, Any]:
    """Changed-pixel ratio and mean absolute difference between two same-size regions."""
    region_a = _crop(image_a, rect_a)
    region_b = _crop(image_b, rect_b)
    if region_a.size != region_b.size:
        raise MetricsError(f"roi_diff regions differ in size: {region_a.size} vs {region_b.size}")
    data_a = region_a.getdata()
    data_b = region_b.getdata()
    total = max(1, len(data_a))
    changed = 0
    accumulator = 0
    for pixel_a, pixel_b in zip(data_a, data_b):
        delta = sum(abs(component_a - component_b) for component_a, component_b in zip(pixel_a, pixel_b))
        accumulator += delta
        if delta > 8:
            changed += 1
    return {
        "changed_pixel_ratio": changed / total,
        "mean_absolute_difference": accumulator / (total * 4),
    }


def seam_discontinuity(
    image: Image.Image,
    rect: Rect | None,
    axis: str,
    boundary: int,
    band: int = 2,
) -> dict[str, Any]:
    """Mean strongest adjacent-pixel delta near a declared seam line.

    For each scanline, inspect adjacent pixel pairs within ``band`` pixels of
    the boundary and retain the strongest edge. This preserves the legacy
    magnitude for a hard split while detecting a narrow discontinuity that
    exists only on the boundary pixel.
    """
    if axis not in {"horizontal", "vertical"}:
        raise MetricsError("axis must be 'horizontal' or 'vertical'")
    if band < 1:
        raise MetricsError("band must be a positive integer")
    region = _crop(image, rect)
    width, height = region.size
    pixels = region.load()
    accumulator = 0
    samples = 0
    if axis == "vertical":
        if boundary - band < 0 or boundary + band + 1 >= width:
            raise MetricsError("boundary is too close to the ROI edge for the requested band")
        for y in range(height):
            strongest = 0
            for x in range(boundary - band, boundary + band + 1):
                before = pixels[x, y]
                after = pixels[x + 1, y]
                strongest = max(
                    strongest,
                    sum(abs(component_a - component_b) for component_a, component_b in zip(before, after)),
                )
            accumulator += strongest
            samples += 1
    else:
        if boundary - band < 0 or boundary + band + 1 >= height:
            raise MetricsError("boundary is too close to the ROI edge for the requested band")
        for x in range(width):
            strongest = 0
            for y in range(boundary - band, boundary + band + 1):
                before = pixels[x, y]
                after = pixels[x, y + 1]
                strongest = max(
                    strongest,
                    sum(abs(component_a - component_b) for component_a, component_b in zip(before, after)),
                )
            accumulator += strongest
            samples += 1
    return {"mean_absolute_delta": accumulator / max(1, samples * 4), "samples": samples}


def crop_extract(image: Image.Image, rect: Rect, output: Path) -> Path:
    output.parent.mkdir(parents=True, exist_ok=True)
    _crop(image, rect).save(output)
    return output


def _resolve_rect(entry: dict[str, Any]) -> Rect | None:
    rect = entry.get("rect")
    return _rect_from_list(rect) if rect is not None else None


def _apply_threshold(kind: str, metrics: dict[str, Any], check: dict[str, Any]) -> bool | None:
    """Fold a check's own threshold fields into a pass/fail bool, or None if undeclared."""
    if kind == "alpha_bounds":
        thresholds = []
        if "min_coverage_ratio" in check:
            thresholds.append(metrics["coverage_ratio"] >= float(check["min_coverage_ratio"]))
        if "max_coverage_ratio" in check:
            thresholds.append(metrics["coverage_ratio"] <= float(check["max_coverage_ratio"]))
        return all(thresholds) if thresholds else None
    if kind == "matte_void" and "max_void_ratio" in check:
        return metrics["void_ratio"] <= float(check["max_void_ratio"])
    if kind == "roi_diff" and "max_changed_pixel_ratio" in check:
        return metrics["changed_pixel_ratio"] <= float(check["max_changed_pixel_ratio"])
    if kind == "seam_discontinuity" and "max_mean_absolute_delta" in check:
        return metrics["mean_absolute_delta"] <= float(check["max_mean_absolute_delta"])
    return None


def analyze(spec: dict[str, Any], root: Path) -> dict[str, Any]:
    """Run every check in a spec and return deterministic JSON-serializable results.

    Spec shape (`custodian.presentation_image_metrics.v1`):
      images: {name: path relative to `root`}
      rois:   {name: {image: <image name>, rect: [x, y, w, h] | omitted for full frame}}
      checks: [{type: alpha_bounds|matte_void|roi_diff|seam_discontinuity|crop, ...}]
    """
    images_spec = spec.get("images")
    if not isinstance(images_spec, dict) or not images_spec:
        raise MetricsError("spec.images must be a non-empty object of name -> path")
    images = {name: load_image(root / path) for name, path in images_spec.items()}
    rois_spec = spec.get("rois", {})
    if not isinstance(rois_spec, dict):
        raise MetricsError("spec.rois must be an object")

    def rect_for(roi_name: str) -> tuple[Image.Image, Rect | None]:
        roi = rois_spec.get(roi_name)
        if roi is None:
            raise MetricsError(f"unknown roi: {roi_name}")
        image_name = roi.get("image")
        if image_name not in images:
            raise MetricsError(f"roi {roi_name} references unknown image: {image_name}")
        return images[image_name], _resolve_rect(roi)

    results = []
    for index, check in enumerate(spec.get("checks", [])):
        kind = check.get("type")
        if kind == "alpha_bounds":
            image, rect = rect_for(check["roi"])
            metrics = alpha_bounds(image, rect, int(check.get("threshold", 0)))
        elif kind == "matte_void":
            image, rect = rect_for(check["roi"])
            metrics = matte_void_check(
                image, rect,
                int(check.get("void_alpha_max", 8)),
                int(check.get("matte_tolerance", 6)),
            )
        elif kind == "roi_diff":
            image_a, rect_a = rect_for(check["roi_a"])
            image_b, rect_b = rect_for(check["roi_b"])
            metrics = roi_diff(image_a, image_b, rect_a, rect_b)
        elif kind == "seam_discontinuity":
            image, rect = rect_for(check["roi"])
            metrics = seam_discontinuity(
                image, rect, str(check["axis"]), int(check["boundary"]), int(check.get("band", 2))
            )
        elif kind == "crop":
            image, rect = rect_for(check["roi"])
            if rect is None:
                raise MetricsError("crop checks require an roi with a rect")
            output = root / str(check["output"])
            crop_extract(image, rect, output)
            metrics = {"output": str(check["output"])}
        else:
            raise MetricsError(f"checks[{index}] has unsupported type: {kind}")
        entry: dict[str, Any] = {"index": index, "type": kind, "metrics": metrics}
        passed = _apply_threshold(kind, metrics, check)
        if passed is not None:
            entry["passed"] = passed
        results.append(entry)
    return {"schema": SCHEMA, "checks": results}


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path, help="path to a presentation-image-metrics spec JSON file")
    parser.add_argument("--output", type=Path, help="write results JSON here instead of stdout")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        spec = json.loads(args.spec.read_text(encoding="utf-8"))
        results = analyze(spec, args.spec.resolve().parent)
    except (MetricsError, OSError, json.JSONDecodeError) as exc:
        print(f"presentation_image_metrics error: {exc}", file=sys.stderr)
        return 2
    payload = json.dumps(results, indent=2, sort_keys=True)
    if args.output:
        args.output.write_text(payload + "\n", encoding="utf-8")
    else:
        print(payload)
    failed = [entry for entry in results["checks"] if entry.get("passed") is False]
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
