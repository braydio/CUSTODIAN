"""Downsample Blender renders with one declared method and build compact QA.

This is a regular Python 3 script and uses Pillow from the system environment.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from surface_contract import FRAME_SIZE, GROUND_Y, ORTHO_SCALE, ROOT_PIXEL, SUPERSAMPLE

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
SOURCE_DIR = REPO / "custodian/asset_drop/source_work/actors/broken_warrant_playable_knight_3d"
DEFAULT_OUT = SOURCE_DIR / "proof"
ANGLES = ("front", "three_quarter", "back")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--proof-dir", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--source-glb", type=Path, default=SOURCE_DIR / "Broken_Warrant_3D_Master_source.glb")
    parser.add_argument("--reference", type=Path, default=SOURCE_DIR / "broken_warrant_turnaround_source.png")
    parser.add_argument("--blend", type=Path, default=SOURCE_DIR / "broken_warrant_material_master_source.blend")
    parser.add_argument("--palette", type=Path, default=HERE / "material_palette.json")
    return parser.parse_args()


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def image_metrics(image: Image.Image):
    rgba = np.asarray(image.convert("RGBA"))
    alpha = rgba[:, :, 3]
    ys, xs = np.nonzero(alpha)
    if not len(xs):
        bbox = None
    else:
        bbox = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
    colors = Counter(tuple(int(value) for value in row) for row in rgba[alpha > 0, :3])
    top_colors = [{"rgb": list(color), "pixels": count} for color, count in colors.most_common(8)]
    return {
        "width": image.width,
        "height": image.height,
        "mode": image.mode,
        "alpha_pixels": int((alpha > 0).sum()),
        "nonzero_alpha_fraction": round(float((alpha > 0).mean()), 6),
        "transparent_corner_alpha": [int(alpha[0, 0]), int(alpha[0, -1]), int(alpha[-1, 0]), int(alpha[-1, -1])],
        "alpha_bbox_inclusive": bbox,
        "touches_frame_edge": bool(bbox and (bbox[0] == 0 or bbox[1] == 0 or bbox[2] == image.width - 1 or bbox[3] == image.height - 1)),
        "dominant_rgb": top_colors,
        "sha256": hashlib.sha256(image.tobytes()).hexdigest(),
    }


def alpha_iou(a: Image.Image, b: Image.Image) -> float:
    aa = np.asarray(a.convert("RGBA"))[:, :, 3] > 0
    bb = np.asarray(b.convert("RGBA"))[:, :, 3] > 0
    union = np.logical_or(aa, bb).sum()
    return float(np.logical_and(aa, bb).sum() / union) if union else 1.0


def rgb_mean_difference(a: Image.Image, b: Image.Image) -> float:
    aa = np.asarray(a.convert("RGBA"), dtype=np.int16)
    bb = np.asarray(b.convert("RGBA"), dtype=np.int16)
    return float(np.abs(aa - bb).mean())


def make_sheet(native_paths, reduced_paths, output: Path):
    tile = FRAME_SIZE * SUPERSAMPLE
    label_h = 32
    gutter = 10
    sheet = Image.new("RGB", (tile * 3 + gutter * 4, (tile + label_h) * 2 + gutter * 3), (25, 26, 29))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    for row, (label, paths) in enumerate((("NATIVE 128 → 4× NEAREST DISPLAY", native_paths), ("512 → 128 NEAREST → 4× DISPLAY", reduced_paths))):
        for column, (angle, path) in enumerate(zip(ANGLES, paths)):
            x = gutter + column * (tile + gutter)
            y = gutter + row * (tile + label_h + gutter)
            draw.text((x + 5, y + 4), f"{angle.upper()}  |  {label}", fill=(235, 226, 214), font=font)
            image = Image.open(path).convert("RGBA")
            if image.size != (FRAME_SIZE, FRAME_SIZE):
                raise ValueError(f"Expected a 128x128 image at {path}; got {image.size}")
            image = image.resize((tile, tile), Image.Resampling.NEAREST)
            checker = Image.new("RGB", (tile, tile), (28, 29, 32))
            checker.paste(image, mask=image.getchannel("A"))
            sheet.paste(checker, (x, y + label_h))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, optimize=True)


def main():
    cfg = parse_args()
    native_dir = cfg.proof_dir / "native_128"
    super_dir = cfg.proof_dir / "supersampled_512"
    down_dir = cfg.proof_dir / "supersampled_downsampled_128"
    mask_raw_dir = cfg.proof_dir / "emission_mask_512_raw"
    mask_dir = cfg.proof_dir / "emission_mask_128"
    down_dir.mkdir(parents=True, exist_ok=True)
    mask_dir.mkdir(parents=True, exist_ok=True)

    view_metrics = {}
    native_paths, reduced_paths = [], []
    all_passed = True
    for angle in ANGLES:
        native_path = native_dir / f"{angle}.png"
        super_path = super_dir / f"{angle}_512.png"
        mask_path = mask_raw_dir / f"{angle}_emission_mask_512.png"
        for path in (native_path, super_path, mask_path):
            if not path.is_file():
                raise FileNotFoundError(path)
        native = Image.open(native_path).convert("RGBA")
        supersampled = Image.open(super_path).convert("RGBA")
        if native.size != (FRAME_SIZE, FRAME_SIZE) or supersampled.size != (FRAME_SIZE * SUPERSAMPLE, FRAME_SIZE * SUPERSAMPLE):
            raise ValueError(f"Unexpected render dimensions for {angle}: native={native.size}; 4x={supersampled.size}")
        # One fixed, non-blurring pixelation operation: nearest-neighbor 4x reduction.
        reduced = supersampled.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.NEAREST)
        reduced_path = down_dir / f"{angle}_128_from_512_nearest.png"
        reduced.save(reduced_path, optimize=True)

        raw_mask = Image.open(mask_path).convert("RGBA")
        raw_pixels = np.asarray(raw_mask)
        white = (raw_pixels[:, :, :3].min(axis=2) >= 200) & (raw_pixels[:, :, 3] > 0)
        mask_rgba = np.zeros_like(raw_pixels)
        mask_rgba[white, :3] = 255
        mask_rgba[white, 3] = 255
        mask_512 = Image.fromarray(mask_rgba, "RGBA")
        mask_128 = mask_512.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.NEAREST)
        mask_128.save(mask_dir / f"{angle}_emission_mask.png", optimize=True)

        native_metric = image_metrics(native)
        reduced_metric = image_metrics(reduced)
        mask_metric = image_metrics(mask_128)
        bounds = native_metric["alpha_bbox_inclusive"]
        root = json.loads((cfg.proof_dir / "render_only_lod.json").read_text())["views"][angle]["root_px"]
        registration_ok = abs(root[0] - ROOT_PIXEL[0]) <= 0.1 and abs(root[1] - ROOT_PIXEL[1]) <= 0.1
        alpha_ok = native_metric["alpha_pixels"] > 0 and native_metric["transparent_corner_alpha"] == [0, 0, 0, 0]
        framing_ok = bool(bounds and not native_metric["touches_frame_edge"] and 0 < bounds[0] < bounds[2] < FRAME_SIZE - 1 and 0 < bounds[1] < bounds[3] < FRAME_SIZE - 1)
        ground_ok = bool(bounds and abs(bounds[3] - GROUND_Y) <= 4)
        mask_ok = mask_metric["alpha_pixels"] > 0 and mask_metric["transparent_corner_alpha"] == [0, 0, 0, 0]
        view_passed = registration_ok and alpha_ok and framing_ok and ground_ok and mask_ok
        all_passed = all_passed and view_passed
        view_metrics[angle] = {
            "native_128": native_metric,
            "supersampled_512": image_metrics(supersampled),
            "supersampled_downsampled_128": reduced_metric,
            "emission_mask_128": mask_metric,
            "supersample_native_alpha_iou": round(alpha_iou(native, reduced), 6),
            "supersample_native_mean_abs_rgba_difference": round(rgb_mean_difference(native, reduced), 6),
            "projected_root_px": root,
            "registration_ok": registration_ok,
            "alpha_ok": alpha_ok,
            "framing_ok": framing_ok,
            "ground_registration_ok": ground_ok,
            "emission_mask_ok": mask_ok,
            "passed": view_passed,
        }
        native_paths.append(native_path)
        reduced_paths.append(reduced_path)

    sheet_path = cfg.proof_dir / "three_angle_comparison.png"
    make_sheet(native_paths, reduced_paths, sheet_path)
    lod = json.loads((cfg.proof_dir / "render_only_lod.json").read_text())
    material_path = cfg.proof_dir / "material_master_validation.json"
    material_report = json.loads(material_path.read_text()) if material_path.is_file() else None
    source_hash = sha256(cfg.source_glb)
    reference_hash = sha256(cfg.reference)
    checks = {
        "source_hash_unchanged": source_hash == "e1a9ef843561a7a31b0ba60600de97d909fbfe8a780b9c0882b3ef7bc6ea4ea6",
        "reference_hash_unchanged": reference_hash == "5f7eaf60f54164896fe7284f8963cab13c00b18fc934fe982c5a1acb309cc7ac",
        "material_master_validation_passed": bool(material_report and material_report.get("passed")),
        "render_only_lod_recorded": lod.get("master_geometry_modified") is False and lod.get("lod_visibility_saved_to_master") is False and len(lod.get("hidden_objects", [])) == lod.get("hidden_count"),
        "three_views_passed": len(view_metrics) == 3 and all(view["passed"] for view in view_metrics.values()),
        "comparison_sheet_created": sheet_path.is_file() and Image.open(sheet_path).size == (3 * FRAME_SIZE * SUPERSAMPLE + 4 * 10, 2 * (FRAME_SIZE * SUPERSAMPLE + 32) + 3 * 10),
        "native_and_supersampled_proofs_differ_by_angle": len({view_metrics[a]["native_128"]["sha256"] for a in ANGLES}) == 3,
        "camera_scale_fixed": all(abs(lod["views"][a]["ortho_scale"] - ORTHO_SCALE) < 1e-6 for a in ANGLES),
        "registration_profile_fixed": lod.get("frame_size") == FRAME_SIZE and lod.get("pixelation_method", "").startswith("Pillow NEAREST 4x reduction"),
    }
    report = {
        "schema": "custodian.broken_warrant.pixel_proof_validation.v1",
        "source_glb_sha256": source_hash,
        "reference_sha256": reference_hash,
        "blend_sha256": sha256(cfg.blend),
        "palette_sha256": sha256(cfg.palette),
        "counts": {"native_128_views": len(list(native_dir.glob("*.png"))), "supersampled_512_views": len(list(super_dir.glob("*.png"))), "emission_masks": len(list(mask_dir.glob("*.png"))), "render_only_hidden": lod["hidden_count"]},
        "profile": {"frame": [FRAME_SIZE, FRAME_SIZE], "root": list(ROOT_PIXEL), "ground_y": GROUND_Y, "orthographic_scale": ORTHO_SCALE, "supersample_factor": SUPERSAMPLE, "pixelation": "nearest-neighbor 4x reduction; no filtering or palette dithering"},
        "views": view_metrics,
        "checks": checks,
        "passed": all(checks.values()),
        "comparison_sheet": {"path": str(sheet_path), "sha256": sha256(sheet_path), "dimensions": list(Image.open(sheet_path).size)},
        "render_only_lod_report": str(cfg.proof_dir / "render_only_lod.json"),
        "human_art_acceptance": "pending",
    }
    out = cfg.proof_dir / "pixel_proof_validation.json"
    out.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"passed": report["passed"], "checks": checks, "view_status": {angle: metric["passed"] for angle, metric in view_metrics.items()}, "comparison_sheet": report["comparison_sheet"], "hidden_render_only": lod["hidden_count"]}, indent=2))
    if not report["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
