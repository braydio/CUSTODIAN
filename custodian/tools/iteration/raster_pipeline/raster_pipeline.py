#!/usr/bin/env python3
"""Deterministic, review-only humanoid raster extraction and QA.

This tool reuses the repository pixel-art converter. It never writes to the
source, checked-in comparison previews, runtime art, or Asset V2 directories.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Any
from PIL import __version__ as PILLOW_VERSION

from PIL import Image
from PIL import ImageDraw

REPO = Path(__file__).resolve().parents[4]
CONVERTER_PATH = REPO / "custodian/tools/art/custodian_pixelart_converter.py"
sys.path.insert(0, str(CONVERTER_PATH.parent))
import custodian_pixelart_converter as converter  # noqa: E402

TOOL_VERSION = "custodian.humanoid_raster_pipeline.v1"
MODE_NAMES = {"crisp": "1", "balanced": "2", "clustered": "3"}


class RasterError(ValueError):
    pass


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _inside(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def _ensure_contained(path: Path, root: Path, label: str) -> None:
    resolved_root = root.resolve()
    resolved_path = path.resolve()
    if not _inside(resolved_path, resolved_root):
        raise RasterError(f"{label} resolves outside the review workspace")


def _rect(raw: Any, size: tuple[int, int]) -> tuple[int, int, int, int]:
    if not isinstance(raw, list) or len(raw) != 4 or any(type(v) is not int for v in raw):
        raise RasterError("ROI must be integer [x, y, width, height]")
    x, y, w, h = raw
    if x < 0 or y < 0 or w <= 0 or h <= 0 or x + w > size[0] or y + h > size[1]:
        raise RasterError(f"ROI {raw} lies outside source dimensions {list(size)}")
    return x, y, x + w, y + h


def _row_occupancy(image: Image.Image, alpha_threshold: int) -> list[int]:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > alpha_threshold else 0)
    return [sum(1 for x in range(image.width) if mask.getpixel((x, y))) for y in range(image.height)]


def _contact(image: Image.Image, contact: dict[str, Any]) -> dict[str, Any]:
    threshold = contact["alpha_threshold"]
    min_pixels = contact["minimum_row_pixels"]
    rows = _row_occupancy(image, threshold)
    matching = [y for y, count in enumerate(rows) if count >= min_pixels]
    if not matching:
        raise RasterError("No meaningful foot-contact row meets declared alpha/coverage thresholds")
    bottom = matching[-1]
    band = [y for y in matching if y >= bottom - contact["band_height"] + 1]
    row_pixels = [x for x in range(image.width) if image.getpixel((x, bottom))[3] > threshold]
    return {"row": bottom, "band_rows": band, "pixels_on_row": rows[bottom], "contact_pixels": [[x, bottom] for x in row_pixels], "row_occupancy": rows}


def _connected_components(mask: set[tuple[int, int]]) -> list[list[tuple[int, int]]]:
    remaining = set(mask)
    result = []
    while remaining:
        seed = min(remaining, key=lambda item: (item[1], item[0]))
        remaining.remove(seed)
        component = [seed]
        stack = [seed]
        while stack:
            x, y = stack.pop()
            for ny in range(y - 1, y + 2):
                for nx in range(x - 1, x + 2):
                    point = (nx, ny)
                    if point in remaining:
                        remaining.remove(point)
                        component.append(point)
                        stack.append(point)
        result.append(component)
    return result


def pixel_qa(image: Image.Image, alpha_threshold: int, baseline_y: int | None = None) -> dict[str, Any]:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    alpha_hist = rgba.getchannel("A").histogram()
    opaque = [(x, y) for y in range(rgba.height) for x in range(rgba.width) if pixels[x, y][3] > alpha_threshold]
    bounds = None if not opaque else [min(x for x, _ in opaque), min(y for _, y in opaque), max(x for x, _ in opaque) + 1, max(y for _, y in opaque) + 1]
    bright = set()
    fringe = []
    near_black = []
    opaque_rgb = set()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a > alpha_threshold:
                opaque_rgb.add((r, g, b))
                if min(r, g, b) >= 210:
                    bright.add((x, y))
                if baseline_y is not None and y >= baseline_y - 4 and max(r, g, b) <= 22:
                    near_black.append([x, y])
            if 0 < a < 255:
                fringe.append([x, y, a])
    outliers = []
    for component in _connected_components(bright):
        if len(component) <= 2:
            outliers.append({"bounds": [min(x for x, _ in component), min(y for _, y in component), max(x for x, _ in component) + 1, max(y for _, y in component) + 1], "pixels": [[x, y] for x, y in sorted(component, key=lambda p: (p[1], p[0]))], "severity": "low" if len(component) == 1 else "review"})
    black_bounds = None if not near_black else [min(p[0] for p in near_black), min(p[1] for p in near_black), max(p[0] for p in near_black) + 1, max(p[1] for p in near_black) + 1]
    findings = []
    if outliers:
        findings.append({"type": "bright_isolated_pixels", "severity": "review", "components": outliers})
    if near_black:
        findings.append({"type": "near_black_foot_region", "severity": "review", "bounds": black_bounds, "pixel_count": len(near_black), "coordinates": near_black})
    if fringe:
        findings.append({"type": "partial_alpha_fringe", "severity": "review", "pixel_count": len(fringe), "coordinates_alpha": fringe})
    return {
        "size": list(rgba.size), "alpha_bounds": bounds,
        "alpha_histogram": {"zero": alpha_hist[0], "one_to_15": sum(alpha_hist[1:16]), "16_to_254": sum(alpha_hist[16:255]), "255": alpha_hist[255]},
        "palette_rgb_count": len(opaque_rgb),
        "bright_isolated_outliers": outliers,
        "near_black_foot_pixels": near_black, "near_black_foot_bounds": black_bounds,
        "alpha_fringe_pixels": fringe,
        "findings": findings,
        "art_approval": "NOT_PERFORMED",
    }


def validate_plan(plan: dict[str, Any], source: Path, out: Path, allow_verified_fallback: bool = False) -> tuple[dict[str, Any], Image.Image, str]:
    if plan.get("schema") != "custodian.humanoid_raster_plan.v1":
        raise RasterError("unsupported/missing plan schema")
    source_resolved = source.resolve(strict=True)
    out_resolved = out.resolve()
    if source_resolved == out_resolved or (_inside(source_resolved, out_resolved) and not allow_verified_fallback):
        raise RasterError("source cannot equal or be inside the output directory")
    raw = source_resolved.read_bytes()
    digest = sha256(raw)
    if digest != plan.get("source", {}).get("sha256"):
        raise RasterError(f"source SHA-256 mismatch: expected {plan.get('source', {}).get('sha256')}, got {digest}")
    opened = Image.open(source_resolved)
    opened.verify()
    image = Image.open(source_resolved).convert("RGBA")
    if image.width <= 0 or image.height <= 0:
        raise RasterError("source image is empty")
    target = plan.get("target", {})
    if target.get("cell") != [96, 96]:
        raise RasterError("this workflow requires the declared 96x96 target cell")
    heights = target.get("body_heights")
    if not isinstance(heights, list) or not heights or any(type(h) is not int or h <= 0 or h >= 96 for h in heights):
        raise RasterError("body_heights must be positive integers smaller than 96")
    modes = plan.get("reduction_modes")
    if not isinstance(modes, list) or not modes or len(set(modes)) != len(modes) or any(mode not in MODE_NAMES for mode in modes):
        raise RasterError("reduction_modes must explicitly list unique supported converter modes")
    contact = plan.get("registration", {}).get("contact", {})
    for field in ("alpha_threshold", "minimum_row_pixels", "band_height"):
        if type(contact.get(field)) is not int or contact[field] < (0 if field == "alpha_threshold" else 1):
            raise RasterError(f"invalid registration.contact.{field}")
    if contact["alpha_threshold"] > 254:
        raise RasterError("alpha threshold must be in 0..254")
    anchor = plan.get("registration", {})
    baseline = anchor.get("frame_ground_y")
    if type(baseline) is not int or not (0 < baseline < 96):
        raise RasterError("registration.frame_ground_y must lie inside the target cell")
    for field in ("sprite_offset_y", "sprite_center_y", "grunt_collision_ground_y"):
        if type(anchor.get(field)) not in (int, float):
            raise RasterError(f"registration.{field} must be numeric")
    tolerance = anchor.get("ground_tolerance_px")
    if type(tolerance) not in (int, float) or tolerance < 0:
        raise RasterError("registration.ground_tolerance_px must be a non-negative number")
    views = plan.get("views")
    if not isinstance(views, dict) or set(views) != {"s", "n", "e", "w"}:
        raise RasterError("views must explicitly define s, n, e, and w")
    for direction in ("s", "n", "e", "w"):
        view = views[direction]
        if not isinstance(view.get("label"), str) or not view["label"].strip():
            raise RasterError(f"view {direction} needs a descriptive label")
        view["_rect"] = _rect(view.get("roi"), image.size)
    return plan, image, digest


def _converter_candidate(image: Image.Image, size: tuple[int, int], mode: str, colors: int, cutoff: int) -> Image.Image:
    candidates = converter.make_single_candidates(image, size, colors, cutoff, edge_cleanup=False)
    return candidates[MODE_NAMES[mode]]


def _source_or_verified_fallback(plan: dict[str, Any], out: Path, repo_root: Path) -> Path:
    source_path = repo_root / plan["source"]["path"]
    expected = plan["source"]["sha256"]
    if source_path.is_file():
        raw = source_path.read_bytes()
        if sha256(raw) == expected:
            return source_path
        if not raw.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
            return source_path  # the normal hash check reports the mismatch
    fallback = plan["source"].get("fallback")
    if not isinstance(fallback, dict) or not fallback.get("zip") or not fallback.get("member"):
        raise RasterError("source is missing or an unhydrated LFS pointer and no checked-in fallback is declared")
    archive_path = (repo_root / fallback["zip"]).resolve(strict=True)
    try:
        with zipfile.ZipFile(archive_path) as archive:
            payload = archive.read(fallback["member"])
    except (OSError, KeyError, zipfile.BadZipFile) as exc:
        raise RasterError(f"cannot read declared fallback member: {exc}") from exc
    if sha256(payload) != expected:
        raise RasterError("checked-in fallback member does not match the pinned source SHA-256")
    scratch = out / "verified_source_fallback" / Path(fallback["member"]).name
    _ensure_contained(scratch.parent, out, "fallback source directory")
    if scratch.is_symlink():
        raise RasterError("fallback source destination cannot be a symlink")
    scratch.parent.mkdir(parents=True, exist_ok=True)
    scratch.write_bytes(payload)
    return scratch


def build(plan_path: Path, out: Path, repo_root: Path = REPO) -> dict[str, Any]:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    plan_digest = sha256(canonical_json(plan))
    out_abs = out if out.is_absolute() else repo_root / out
    out_abs = out_abs.resolve()
    review_root = (repo_root / ".ai/grunt-candidate-raster-workflow-v1").resolve()
    if not _inside(out_abs, review_root) or out_abs == review_root:
        raise RasterError("output must be a child of .ai/grunt-candidate-raster-workflow-v1")
    ignored = subprocess.run(["git", "check-ignore", "-q", "--", str(out_abs.relative_to(repo_root))], cwd=repo_root, check=False)
    if ignored.returncode != 0:
        raise RasterError("output directory must be git-ignored review workspace")
    forbidden = ("custodian/asset_drop/source_work", "custodian/asset_drop/inbox", "custodian/content/sprites", "custodian/tools/iteration/grunt_candidate_ab/generated")
    if any(_inside(out_abs, (repo_root / item).resolve()) for item in forbidden):
        raise RasterError("output directory overlaps source, inbox, runtime sprites, or checked-in Grunt baselines")
    source = _source_or_verified_fallback(plan, out_abs, repo_root).resolve()
    canonical_source = (repo_root / plan["source"]["path"]).resolve()
    plan, source_image, source_hash = validate_plan(plan, source, out_abs, allow_verified_fallback=source != canonical_source)
    contact_spec = plan["registration"]["contact"]
    baseline_y = plan["registration"]["frame_ground_y"]
    registration = plan["registration"]
    actor_ground_projection = registration["sprite_offset_y"] + (baseline_y - registration["sprite_center_y"])
    actor_ground_residual = actor_ground_projection - registration["grunt_collision_ground_y"]
    ground_severity = "within_declared_tolerance" if abs(actor_ground_residual) <= registration["ground_tolerance_px"] else "review"
    colors = plan["conversion"].get("colors", 32)
    cutoff = plan["conversion"].get("alpha_cutoff", 0)
    if type(colors) is not int or colors < 2 or colors > 256 or type(cutoff) is not int or not 0 <= cutoff <= 254:
        raise RasterError("conversion colors/alpha_cutoff outside supported limits")
    outputs: dict[str, Any] = {}
    sheet_images: dict[tuple[str, str], Image.Image] = {}
    for direction in ("s", "n", "e", "w"):
        view = plan["views"][direction]
        rect = view["_rect"]
        crop = source_image.crop(rect)
        alpha_box = crop.getchannel("A").point(lambda v: 255 if v > contact_spec["alpha_threshold"] else 0).getbbox()
        if alpha_box is None:
            raise RasterError(f"view {direction} has no visible alpha above declared threshold")
        tight = crop.crop(alpha_box)
        source_contact = _contact(tight, contact_spec)
        outputs[direction] = {"label": view["label"], "roi": view["roi"], "tight_bounds_in_roi": list(alpha_box), "tight_size": list(tight.size), "source_contact": {k: v for k, v in source_contact.items() if k != "row_occupancy"}, "source_qa": pixel_qa(tight, contact_spec["alpha_threshold"]), "candidates": {}}
        for height in plan["target"]["body_heights"]:
            width = max(1, round(tight.width * height / tight.height))
            if width > 96:
                raise RasterError(f"view {direction} at height {height} exceeds 96px cell width")
            size = (width, height)
            for mode in plan["reduction_modes"]:
                reduced = _converter_candidate(tight, size, mode, colors, cutoff)
                measured = _contact(reduced, contact_spec)
                nearest_reference = tight.resize(size, Image.Resampling.NEAREST)
                reference_contact = _contact(nearest_reference, contact_spec)
                reduced_mask = reduced.getchannel("A").point(lambda value: 255 if value > contact_spec["alpha_threshold"] else 0)
                reference_mask = nearest_reference.getchannel("A").point(lambda value: 255 if value > contact_spec["alpha_threshold"] else 0)
                left = (96 - width) // 2
                drift_points = []
                for py in range(height):
                    for px in range(width):
                        if bool(reduced_mask.getpixel((px, py))) != bool(reference_mask.getpixel((px, py))):
                            drift_points.append([px, py])
                contact_drift = measured["row"] - reference_contact["row"]
                top = baseline_y - measured["row"]
                if left < 0 or top < 0 or left + width > 96 or top + height > 96:
                    raise RasterError(f"{direction} {height}px {mode} would clip in 96x96 cell")
                frame = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
                frame.alpha_composite(reduced, (left, top))
                if height == 72:
                    sheet_images[(direction, mode)] = frame.copy()
                name = f"candidate_{direction}_{height}px.png"
                mode_dir = out_abs / mode
                _ensure_contained(mode_dir, out_abs, "candidate mode directory")
                mode_dir.mkdir(parents=True, exist_ok=True)
                target_path = mode_dir / name
                _ensure_contained(target_path, out_abs, "candidate output")
                if target_path.is_symlink() or target_path.resolve() == source.resolve():
                    raise RasterError("refusing to overwrite source or checked-in baseline preview")
                frame.save(target_path)
                output_contact = _contact(frame, contact_spec)
                qa = pixel_qa(frame, contact_spec["alpha_threshold"], baseline_y)
                outputs[direction]["candidates"].setdefault(str(height), {})[mode] = {
                    "path": target_path.relative_to(repo_root).as_posix(),
                    "file_sha256": sha256(target_path.read_bytes()),
                    "decoded_pixel_sha256": sha256(frame.tobytes()),
                    "scale": [width, height], "placement_xy": [left, top],
                    "source_contact_row": source_contact["row"],
                    "candidate_contact_row_in_cell": output_contact["row"],
                    "contact_error_px": output_contact["row"] - baseline_y,
                    "foot_registration": {"reference_contact_row": reference_contact["row"], "candidate_contact_row": measured["row"], "converter_drift_px": contact_drift, "severity": "none" if contact_drift == 0 else "review", "actor_ground_projection_y": actor_ground_projection, "grunt_collision_ground_y": registration["grunt_collision_ground_y"], "actor_ground_residual_px": actor_ground_residual, "ground_tolerance_px": registration["ground_tolerance_px"], "ground_severity": ground_severity, "contact_pixels_in_cell": [[left + x, top + y] for x, y in measured["contact_pixels"]]},
                    "silhouette_drift": {"changed_pixel_count": len(drift_points), "ratio": len(drift_points) / max(1, width * height), "coordinates_in_cell": [[left + px, top + py] for px, py in drift_points], "severity": "none" if not drift_points else "review"},
                    "qa": qa,
                }
    tile_width, tile_height = 128, 116
    contact_sheet = Image.new("RGBA", (tile_width * len(plan["reduction_modes"]), tile_height * 4), (24, 27, 35, 255))
    draw = ImageDraw.Draw(contact_sheet)
    for row, direction in enumerate(("s", "n", "e", "w")):
        for column, mode in enumerate(plan["reduction_modes"]):
            x, y = column * tile_width, row * tile_height
            draw.text((x + 4, y + 3), f"{direction.upper()} / {mode} / 72px", fill=(235, 235, 240, 255))
            contact_sheet.alpha_composite(sheet_images[(direction, mode)], (x + 16, y + 18))
    result = {
        "schema": "custodian.humanoid_raster_report.v1",
        "status": "DEV_ONLY_NOT_ASSET_V2_RUNTIME",
        "tool_version": TOOL_VERSION,
        "converter": {"path": "custodian/tools/art/custodian_pixelart_converter.py", "sha256": sha256(CONVERTER_PATH.read_bytes()), "methods": plan["reduction_modes"], "colors": colors, "alpha_cutoff": cutoff, "edge_cleanup": False, "pillow_version": PILLOW_VERSION},
        "source": {"path": plan["source"]["path"], "sha256": source_hash, "size": list(source_image.size)},
        "plan_sha256": plan_digest,
        "registration": {**registration, "actor_ground_projection_y": actor_ground_projection, "actor_ground_residual_px": actor_ground_residual, "ground_severity": ground_severity},
        "outputs": outputs,
        "cleanup": {"status": "REPORT_ONLY", "art_approval": "NOT_PERFORMED"},
    }
    out_abs.mkdir(parents=True, exist_ok=True)
    sheet_path = out_abs / "contact_sheet_72px.png"
    report_path = out_abs / "raster_report.json"
    for path in (sheet_path, report_path):
        _ensure_contained(path, out_abs, "report output")
        if path.is_symlink():
            raise RasterError("report output cannot be a symlink")
    contact_sheet.save(sheet_path)
    result["contact_sheet"] = {"path": sheet_path.relative_to(repo_root).as_posix(), "sha256": sha256(sheet_path.read_bytes())}
    report_path.write_bytes(canonical_json(result))
    return result


def apply_cleanup(approval_path: Path, out: Path, repo_root: Path = REPO) -> dict[str, Any]:
    approval = json.loads(approval_path.read_text(encoding="utf-8"))
    if approval.get("schema") != "custodian.raster_cleanup_approval.v1" or not approval.get("reviewed_by"):
        raise RasterError("cleanup requires a reviewed custodian.raster_cleanup_approval.v1 file")
    image_path = (repo_root / approval["candidate_path"]).resolve(strict=True)
    output_root = (repo_root / out).resolve() if not out.is_absolute() else out.resolve()
    review_root = (repo_root / ".ai/grunt-candidate-raster-workflow-v1").resolve()
    if not _inside(output_root, review_root) or output_root == review_root:
        raise RasterError("cleanup output must be a child of .ai/grunt-candidate-raster-workflow-v1")
    if not _inside(image_path, output_root):
        raise RasterError("cleanup candidate must be inside the selected output workspace")
    original = image_path.read_bytes()
    if sha256(original) != approval.get("candidate_sha256"):
        raise RasterError("cleanup candidate SHA mismatch; approval is stale")
    image = Image.open(image_path).convert("RGBA")
    pixels = image.load()
    edits = approval.get("edits")
    if not isinstance(edits, list) or not edits:
        raise RasterError("cleanup approval must enumerate exact pixel edits")
    changed = []
    seen = set()
    for edit in edits:
        x, y = edit.get("x"), edit.get("y")
        before, after = edit.get("before"), edit.get("after")
        if type(x) is not int or type(y) is not int or (x, y) in seen or x < 0 or y < 0 or x >= image.width or y >= image.height:
            raise RasterError("cleanup coordinates must be unique in-bounds integers")
        if not all(isinstance(c, list) and len(c) == 4 and all(type(v) is int and 0 <= v <= 255 for v in c) for c in (before, after)):
            raise RasterError("cleanup before/after values must be RGBA byte arrays")
        if list(pixels[x, y]) != before or before == after:
            raise RasterError(f"cleanup preimage mismatch or no-op at {(x, y)}")
        seen.add((x, y))
        changed.append({"x": x, "y": y, "before": before, "after": after})
    for edit in changed:
        pixels[edit["x"], edit["y"]] = tuple(edit["after"])
    cleaned = output_root / "approved_cleanup" / image_path.relative_to(output_root)
    _ensure_contained(cleaned, output_root, "cleaned candidate output")
    if cleaned.is_symlink():
        raise RasterError("cleaned candidate destination cannot be a symlink")
    cleaned.parent.mkdir(parents=True, exist_ok=True)
    image.save(cleaned)
    audit = {"schema": "custodian.raster_cleanup_audit.v1", "reviewed_by": approval["reviewed_by"], "original_path": image_path.relative_to(repo_root).as_posix(), "original_sha256": sha256(original), "cleaned_path": cleaned.relative_to(repo_root).as_posix(), "cleaned_sha256": sha256(cleaned.read_bytes()), "changed_pixels": len(changed), "edits": changed, "reversible_source_sha256": sha256(original), "art_approval": "NOT_PERFORMED"}
    (cleaned.parent / "cleanup_audit.json").write_bytes(canonical_json(audit))
    return audit


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--cleanup-approval", type=Path)
    args = parser.parse_args()
    try:
        if args.cleanup_approval:
            result = apply_cleanup(args.cleanup_approval, args.out)
        else:
            result = build(args.plan, args.out)
    except (RasterError, OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"raster_pipeline: BLOCKED: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": "PASS", "schema": result["schema"], "report": str(args.out / "raster_report.json") if not args.cleanup_approval else result["cleaned_path"]}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
