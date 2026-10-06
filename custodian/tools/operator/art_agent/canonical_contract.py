"""Operator 2.5D canonical visual contract: preservation, normalization, measurement and drift QA.

The approved eight-direction turnaround is the single projection authority for 2.5D Operator
authoring. This module is deterministic: identical source bytes and annotations always yield
identical 128x128 references, measurements and reports.

Coordinate spaces
-----------------
source cell  : 480x480 cell inside the preserved 3840x480 master
normalized   : 128x128 authoring frame, one shared 0.2 scale, integer translation per direction
"""
from __future__ import annotations

import hashlib
import json
import math
import shutil
import sys
from collections import deque
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw

CUSTODIAN = Path(__file__).resolve().parents[3]
REPO = CUSTODIAN.parent
sys.path.insert(0, str(CUSTODIAN / "tools/art"))
import custodian_pixelart_converter as converter  # noqa: E402

DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")
SOURCE_CELL = 480
SOURCE_SIZE = (SOURCE_CELL * len(DIRECTIONS), SOURCE_CELL)
FRAME = 128
SCALE_NUM, SCALE_DEN = 1, 5            # provisional candidate A: 480px source cell -> 96px content
PRIMARY_SCALE = (SCALE_NUM, SCALE_DEN)
SCALE_CANDIDATES = {"A": (1, 5), "B": (9, 40)}   # 0.200 and 0.225 (480 -> 96 / 108 px); human chooses
CENTER_X = FRAME // 2
SUPPORT_ROW = 111                      # current support-foot baseline (lowest toe sole). NOT a proven world root.
GROUND_Y = SUPPORT_ROW + 1             # provisional candidate ground rail, pending human calibration
ROOT_CANDIDATE_ROWS = (106, 107, 108)  # comparison rows around the median foot-contact midpoint
FAMILY_HUE = (25.0, 110.0)             # gold/amber family incl. yellow speculars (observed up to ~104 deg)
GOLD_HUE = (40.0, 110.0)
AUTHORITY = {
    "visual_design": "locked", "camera_projection": "locked", "profile_128": "provisional",
    "root_floor": "pending_human_calibration", "shared_body_scale": "pending_ab_approval",
    "universal_128_envelope": "pending_proof", "final_normalized_hash": "pending_cleanup_certification",
}
ALPHA_CUTOFF = 128
LANDMARK_NOISE_PX = 1.0                # one crisp pixel of quantization at 128px
TOLERANCE_K = 2.0
SEVERITIES = ("HARD_FAIL", "STRUCTURAL_WARN", "ART_DIRECTION_WARN", "INFO")
PROFILE_ID = "operator_2_5d_128"
LEGACY_PROFILE_ID = "legacy_96"

SOURCE_DIR = CUSTODIAN / "asset_drop/source_work/operator/operator_2_5d_design_reference"
MASTER_NAME = "OPERATOR_DESIGN_REFERENCE_480.png"
MANIFEST_PATH = SOURCE_DIR / "operator_2_5d_design_reference_manifest.json"
REFERENCE_DIR = CUSTODIAN / "content/sprites/operator/reference/operator_2_5d"
AUTHORING_DIR = CUSTODIAN / "content/data/operator/authoring"
ANNOTATIONS_PATH = AUTHORING_DIR / "operator_2_5d_landmark_annotations.json"
REFERENCE_JSON_PATH = AUTHORING_DIR / "operator_2_5d_design_reference.json"
PROFILE_PATH = AUTHORING_DIR / "operator_art_profile.json"
REPORT_DIR = REPO / "reports/operator_presentation/canonical_visual_contract"

LANDMARK_ORDER = (
    "hood_top", "head_center", "shoulder_near", "shoulder_far", "elbow_near", "elbow_far",
    "hand_near", "hand_far", "hip_center", "hip_near", "hip_far", "knee_near", "knee_far",
    "ankle_near", "ankle_far", "toe_near", "toe_far", "cloak_tip_near", "cloak_tip_far",
)
SEGMENTS = (
    ("hood_top", "head_center"), ("head_center", "hip_center"), ("shoulder_far", "shoulder_near"),
    ("hip_far", "hip_near"), ("shoulder_near", "elbow_near"), ("elbow_near", "hand_near"),
    ("shoulder_far", "elbow_far"), ("elbow_far", "hand_far"), ("hip_near", "knee_near"),
    ("knee_near", "ankle_near"), ("ankle_near", "toe_near"), ("hip_far", "knee_far"),
    ("knee_far", "ankle_far"), ("ankle_far", "toe_far"),
)
WIDTH_PERCENTS = (20, 35, 50, 65, 80)
CONFIDENT = 0.6                        # landmarks below this are evidence-only for QA
IDENTITY_LOCKS = (
    "faceless hood: no skin, eyes, nose or mouth ever exposed",
    "hood crown readable under the fixed elevated camera",
    "visor strongest S, partial SE/SW, narrow E/W, minimal NE/NW, absent/near-absent N",
    "lean athletic proportions", "angular shoulder plates",
    "graphite/black plate and cloth with restrained antique-gold/amber trim",
    "layered split cloak/tabard", "fixed belt-ring language",
    "stable shoulder/forearm/knee/greave plate segmentation",
    "one screen-space lighting language", "exactly eight authored directions",
    "no direction collapses into a side-on camera",
)


# --------------------------------------------------------------------------- helpers
def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def rel(path: Path) -> str:
    return path.resolve().relative_to(REPO.resolve()).as_posix()


def _r(value: float, places: int = 3) -> float:
    return round(float(value), places)


def _percentiles(values: np.ndarray, points=(5, 50, 95, 99)) -> dict[str, float]:
    if values.size == 0:
        return {f"p{p:02d}": None for p in points}
    return {f"p{p:02d}": _r(np.percentile(values, p)) for p in points}


def _rgba(image: Image.Image) -> np.ndarray:
    return np.array(image.convert("RGBA"))


def srgb_to_oklab(rgb: np.ndarray) -> np.ndarray:
    """rgb: (...,3) uint8 -> (...,3) OKLab."""
    c = rgb.astype(np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    r, g, b = lin[..., 0], lin[..., 1], lin[..., 2]
    l_ = np.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m_ = np.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s_ = np.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return np.stack([0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
                     1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
                     0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_], axis=-1)


def _luma(rgb: np.ndarray) -> np.ndarray:
    c = rgb.astype(np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


# --------------------------------------------------------------------------- source preservation
def verify_master(master: Path) -> dict[str, Any]:
    data = master.read_bytes()
    with Image.open(master) as image:
        size, mode = image.size, image.mode
    if size != SOURCE_SIZE or mode != "RGBA":
        raise ValueError(f"approved master must be {SOURCE_SIZE} RGBA, got {size} {mode}")
    return {"filename": MASTER_NAME, "sha256": sha256_bytes(data), "bytes": len(data),
            "dimensions": list(size), "mode": mode}


def split_cells(master: Path) -> list[Image.Image]:
    with Image.open(master) as image:
        sheet = image.convert("RGBA")
    return [sheet.crop((i * SOURCE_CELL, 0, (i + 1) * SOURCE_CELL, SOURCE_CELL)) for i in range(len(DIRECTIONS))]


def reconstruct(cells: list[Image.Image]) -> Image.Image:
    sheet = Image.new("RGBA", SOURCE_SIZE, (0, 0, 0, 0))
    for index, cell in enumerate(cells):
        sheet.paste(cell, (index * SOURCE_CELL, 0))
    return sheet


def preserve_source(master: Path) -> dict[str, Any]:
    identity = verify_master(master)
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    target = SOURCE_DIR / MASTER_NAME
    if not target.exists() or target.read_bytes() != master.read_bytes():
        shutil.copyfile(master, target)  # byte-for-byte; never recompress
    cells = split_cells(target)
    cell_dir = SOURCE_DIR / "source_cells"
    cell_dir.mkdir(exist_ok=True)
    cell_records = {}
    for direction, cell in zip(DIRECTIONS, cells):
        path = cell_dir / f"{direction}_source.png"
        cell.save(path, optimize=False)
        cell_records[direction] = {"path": rel(path), "sha256": sha256_file(path), "size": [SOURCE_CELL, SOURCE_CELL]}
    if reconstruct([Image.open(cell_dir / f"{d}_source.png").convert("RGBA") for d in DIRECTIONS]).tobytes() \
            != Image.open(target).convert("RGBA").tobytes():
        raise ValueError("source cells do not reconstruct the master pixel-for-pixel")
    manifest = {
        "schema": "custodian.operator_2_5d_design_reference_manifest.v1",
        **identity,
        "path": rel(target),
        "layout": "8x1", "cell_size": [SOURCE_CELL, SOURCE_CELL], "order": list(DIRECTIONS),
        "approval_date": "2026-10-06",
        "provenance": "user_approved_visual_lock",
        "authoring_chat": "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff",
        "filename_note": "The `480` token matches the measured 480x480 cell size of this master.",
        "packet_supersession": {
            "packet_recorded_attachment": {"dimensions": [2048, 256], "cell": 256,
                                           "sha256": "2d5de16d5d2eb3cde5ab36586a33414a613f214441c8b2ec2430e37d1af25323"},
            "decision": "User confirmed on 2026-10-06 that the 3840x480 repository-root file is the approved lock; "
                        "the packet's 2048x256 identity was a mistaken reference.",
        },
        "cells": cell_records,
    }
    write_json(MANIFEST_PATH, manifest)
    return manifest


# --------------------------------------------------------------------------- normalization
def _bottom_in_band(alpha: np.ndarray, x: float, half: int) -> int | None:
    lo, hi = max(0, int(x) - half), min(alpha.shape[1], int(x) + half + 1)
    rows = np.where((alpha[:, lo:hi] >= ALPHA_CUTOFF).any(axis=1))[0]
    return int(rows.max()) if rows.size else None


def _top_in_band(alpha: np.ndarray, x: float, half: int) -> int | None:
    lo, hi = max(0, int(x) - half), min(alpha.shape[1], int(x) + half + 1)
    rows = np.where((alpha[:, lo:hi] >= ALPHA_CUTOFF).any(axis=1))[0]
    return int(rows.min()) if rows.size else None


def load_annotations() -> dict[str, Any]:
    value = json.loads(ANNOTATIONS_PATH.read_text(encoding="utf-8"))
    if tuple(value["directions"]) != DIRECTIONS:
        raise ValueError("landmark annotations must list exactly the eight directions in canonical order")
    return value


def refine_source_landmarks(cell: Image.Image, annotation: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Return source-cell landmarks with deterministic alpha refinement of hood_top and toe contact."""
    alpha = _rgba(cell)[..., 3]
    points = {name: {"x": float(p["x"]), "y": float(p["y"]), "confidence": float(p["confidence"]),
                     "provenance": "agent_visual_annotation"}
              for name, p in annotation["landmarks"].items()}
    head = points["head_center"]
    top = _top_in_band(alpha, head["x"], 40)
    points["hood_top"] = {"x": head["x"], "y": float(top), "confidence": 0.9, "provenance": "alpha_topmost_under_head_center"}
    for name in ("toe_near", "toe_far"):
        p = points[name]
        bottom = _bottom_in_band(alpha, p["x"], 22)
        if bottom is not None and abs(bottom - p["y"]) <= 40:
            p["y"] = float(bottom)
            p["provenance"] = "agent_visual_annotation_snapped_to_alpha_sole"
    return {name: points[name] for name in LANDMARK_ORDER}


def _scale(scale: tuple[int, int]) -> float:
    return scale[0] / scale[1]


def normalize_cell(cell: Image.Image, scale: tuple[int, int] = PRIMARY_SCALE) -> Image.Image:
    """Shared crisp conversion: one area reduction, binary alpha. No rotation, shear or per-direction scale."""
    size = int(round(SOURCE_CELL * scale[0] / scale[1]))
    reduced = cell.resize((size, size), Image.Resampling.BOX)
    return converter.clamp_alpha_binary(reduced, cutoff=ALPHA_CUTOFF)


def support_contact_row(reduced: Image.Image, points: dict[str, dict[str, Any]], scale_pair: tuple[int, int] = PRIMARY_SCALE) -> tuple[int, str]:
    alpha = _rgba(reduced)[..., 3]
    scale = _scale(scale_pair)
    rows = []
    for name in ("toe_near", "toe_far"):
        p = points[name]
        if p["confidence"] >= 0.5:
            bottom = _bottom_in_band(alpha, p["x"] * scale, 5)
            if bottom is not None:
                rows.append(bottom)
    if rows:
        return max(rows), "semantic_toe_landmarks"
    rows_all = np.where((alpha >= ALPHA_CUTOFF).any(axis=1))[0]
    return int(rows_all.max()), "alpha_bottom_fallback"


def normalize_direction(cell: Image.Image, points: dict[str, dict[str, Any]], scale_pair: tuple[int, int] = PRIMARY_SCALE) -> dict[str, Any]:
    reduced = normalize_cell(cell, scale_pair)
    scale = _scale(scale_pair)
    hip_x = points["hip_center"]["x"] * scale
    ox = CENTER_X - int(round(hip_x))
    support, basis = support_contact_row(reduced, points, scale_pair)
    oy = SUPPORT_ROW - support
    canvas = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    canvas.alpha_composite(reduced, (ox, oy))
    bbox = canvas.getchannel("A").getbbox()
    if bbox is None or bbox[0] < 0 or bbox[1] < 0 or bbox[2] > FRAME or bbox[3] > FRAME:
        raise ValueError("normalized direction would clip the 128 frame")
    # clipping check on the placed content (alpha_composite clips silently)
    if int((_rgba(reduced)[..., 3] > 0).sum()) != int((_rgba(canvas)[..., 3] > 0).sum()):
        raise ValueError("normalized direction lost pixels to the 128 frame")
    normalized_points = {name: {"x": _r(p["x"] * scale + ox, 2), "y": _r(p["y"] * scale + oy, 2),
                                "confidence": p["confidence"], "provenance": p["provenance"],
                                "source_xy": [p["x"], p["y"]]} for name, p in points.items()}
    return {"image": canvas, "offset": [ox, oy], "support_basis": basis, "points": normalized_points}


# --------------------------------------------------------------------------- measurements
def _alpha_mask(image: Image.Image) -> np.ndarray:
    return _rgba(image)[..., 3] >= ALPHA_CUTOFF


def _perimeter(mask: np.ndarray) -> np.ndarray:
    padded = np.pad(mask, 1, constant_values=False)
    inner = padded[:-2, 1:-1] & padded[2:, 1:-1] & padded[1:-1, :-2] & padded[1:-1, 2:]
    return mask & ~inner


def _components(mask: np.ndarray) -> list[int]:
    seen = np.zeros_like(mask, dtype=bool)
    sizes = []
    height, width = mask.shape
    for y, x in zip(*np.where(mask)):
        if seen[y, x]:
            continue
        queue, count = deque([(y, x)]), 0
        seen[y, x] = True
        while queue:
            cy, cx = queue.popleft()
            count += 1
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < height and 0 <= nx < width and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((ny, nx))
        sizes.append(count)
    return sorted(sizes, reverse=True)


def silhouette_metrics(image: Image.Image) -> dict[str, Any]:
    mask = _alpha_mask(image)
    ys, xs = np.where(mask)
    if ys.size == 0:
        raise ValueError("empty silhouette")
    left, top, right, bottom = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    height, width = bottom - top, right - left
    area = int(mask.sum())
    widths = {}
    for percent in WIDTH_PERCENTS:
        row = min(bottom - 1, top + int(round(height * percent / 100.0)))
        cols = np.where(mask[row])[0]
        widths[str(percent)] = {"row": row, "extent": int(cols.max() - cols.min() + 1) if cols.size else 0,
                                "opaque": int(mask[row].sum())}
    perimeter = int(_perimeter(mask).sum())
    return {
        "alpha_bbox": [left, top, right, bottom], "centroid": [_r(xs.mean(), 2), _r(ys.mean(), 2)],
        "area": area, "occupancy_ratio": _r(area / (width * height), 4),
        "margins": {"top": top, "bottom": FRAME - bottom, "left": left, "right": FRAME - right},
        "apparent_height": height, "apparent_width": width,
        "widths_at_percent_height": widths, "perimeter_pixels": perimeter,
        "edge_density": _r(perimeter / area, 4),
    }


def anatomy_metrics(points: dict[str, dict[str, Any]], silhouette: dict[str, Any]) -> dict[str, Any]:
    head_hip = math.dist((points["head_center"]["x"], points["head_center"]["y"]),
                         (points["hip_center"]["x"], points["hip_center"]["y"]))
    height = silhouette["apparent_height"]
    segments = {}
    for a, b in SEGMENTS:
        pa, pb = points[a], points[b]
        length = math.dist((pa["x"], pa["y"]), (pb["x"], pb["y"]))
        confidence = min(pa["confidence"], pb["confidence"])
        segments[f"{a}:{b}"] = {
            "px": _r(length, 2), "ratio_to_head_hip": _r(length / head_hip, 4), "ratio_to_height": _r(length / height, 4),
            "tolerance_ratio_to_head_hip": _r(TOLERANCE_K * LANDMARK_NOISE_PX * math.sqrt(2) / head_hip, 4),
            "confidence": _r(confidence, 2), "reliable": confidence >= CONFIDENT}
    mid_shoulder = ((points["shoulder_near"]["x"] + points["shoulder_far"]["x"]) / 2,
                    (points["shoulder_near"]["y"] + points["shoulder_far"]["y"]) / 2)
    hip = (points["hip_center"]["x"], points["hip_center"]["y"])
    torso = math.dist(mid_shoulder, hip)
    support = max(points["toe_near"]["y"], points["toe_far"]["y"])
    leg = max(0.0, support - hip[1])
    cloak = {}
    for side in ("near", "far"):
        tip = points[f"cloak_tip_{side}"]
        cloak[side] = {"dx": _r(tip["x"] - hip[0], 2), "dy": _r(tip["y"] - hip[1], 2),
                       "px": _r(math.dist((tip["x"], tip["y"]), hip), 2),
                       "ratio_to_height": _r(math.dist((tip["x"], tip["y"]), hip) / height, 4)}
    return {
        "head_hip_px": _r(head_hip, 2), "hood_top_to_head_center_px": segments["hood_top:head_center"]["px"],
        "torso_length_px": _r(torso, 2), "torso_ratio_to_head_hip": _r(torso / head_hip, 4),
        "apparent_leg_length_px": _r(leg, 2), "apparent_leg_ratio_to_height": _r(leg / height, 4),
        "shoulder_span_px": segments["shoulder_far:shoulder_near"]["px"],
        "hip_span_px": segments["hip_far:hip_near"]["px"],
        "segments": segments, "cloak_tip_displacement": cloak,
        "foreshortening_note": "direction-specific: compare N to N, E to E; never equalize across bearings",
    }


def head_band(points: dict[str, dict[str, Any]]) -> list[int]:
    """Rows that can contain the visor: hood top down to just below head_center."""
    return [int(points["hood_top"]["y"]), int(round(points["head_center"]["y"])) + 6]


def color_metrics(image: Image.Image, head_rows: list[int] | None = None) -> dict[str, Any]:
    data = _rgba(image)
    opaque = data[..., 3] >= ALPHA_CUTOFF
    rgb = data[..., :3][opaque]
    lab = srgb_to_oklab(rgb)
    lightness, chroma = lab[:, 0], np.hypot(lab[:, 1], lab[:, 2])
    hue = (np.degrees(np.arctan2(lab[:, 2], lab[:, 1])) + 360.0) % 360.0
    luma = _luma(rgb)
    quant = (rgb >> 5).astype(np.int64)
    keys = quant[:, 0] * 64 + quant[:, 1] * 8 + quant[:, 2]
    clusters = []
    for key, count in sorted(zip(*np.unique(keys, return_counts=True)), key=lambda kv: (-kv[1], kv[0]))[:8]:
        sel = keys == key
        clusters.append({"srgb": [int(v) for v in np.round(rgb[sel].mean(axis=0))], "share": _r(count / keys.size, 4)})
    gold = (hue >= GOLD_HUE[0]) & (hue <= GOLD_HUE[1]) & (chroma >= 0.07)
    visor = gold & (lightness >= 0.78) & (chroma >= 0.12)
    if head_rows is not None:
        rows = np.broadcast_to(((np.arange(FRAME) >= head_rows[0]) & (np.arange(FRAME) <= head_rows[1]))[:, None], opaque.shape)[opaque]
        visor &= rows
    gold_trim = gold & ~visor
    graphite = (chroma < 0.045) & ~gold
    cloth = ~gold & ~graphite
    body = ~gold

    def band(mask, edges, labels):
        if not mask.any():
            return {label: 0.0 for label in labels}
        picks = np.digitize(lightness[mask], edges)
        return {label: _r((picks == i).sum() / keys.size, 4) for i, label in enumerate(labels)}

    def med(mask, source=lightness):
        return _r(np.median(source[mask]), 4) if mask.any() else None

    def hi(mask):
        return _r(np.percentile(lightness[mask], 95), 4) if mask.any() else None

    outline = _perimeter(opaque)[opaque]
    outline_l = lightness[outline]
    tiers = {"visor_core_p95": hi(visor), "gold_specular_p95": hi(gold_trim), "gold_trim_median": med(gold_trim),
             "graphite_highlight_p95": hi(graphite), "cloth_mid_median": med(cloth),
             "outline_median": _r(np.median(outline_l), 4)}
    order = [tiers[k] for k in ("visor_core_p95", "gold_specular_p95", "gold_trim_median",
                                "graphite_highlight_p95", "cloth_mid_median", "outline_median")]
    present = [v for v in order if v is not None]
    return {
        "opaque_pixels": int(keys.size),
        "alpha_histogram": _alpha_histogram(data[..., 3]),
        "dominant_srgb_clusters": clusters,
        "oklab_lightness": {**_percentiles(lightness), "mean": _r(lightness.mean())},
        "luminance": _percentiles(luma, (5, 50, 95, 99)),
        "chroma": {**_percentiles(chroma, (5, 50, 95, 99)), "mean": _r(chroma.mean())},
        "highlight_occupancy": {"L_ge_0.75": _r((lightness >= 0.75).mean(), 4), "L_ge_0.85": _r((lightness >= 0.85).mean(), 4)},
        "bands": {
            "graphite_cloth": band(~gold, [0.25, 0.40], ["dark", "mid", "light"]),
            "gold": band(gold_trim, [0.55, 0.75], ["dark", "mid", "highlight"]),
            "visor_share": _r(visor.sum() / keys.size, 4),
            "gold_share": _r(gold_trim.sum() / keys.size, 4),
            "graphite_share": _r(graphite.sum() / keys.size, 4),
            "cloth_share": _r(cloth.sum() / keys.size, 4),
        },
        "gold": {"median_L": med(gold_trim), "median_chroma": med(gold_trim, chroma),
                 "median_hue": med(gold_trim, hue)},
        "darkest_outline_band": {**_percentiles(outline_l, (5, 50, 95)), "perimeter_pixels": int(outline.sum())},
        "contrast": {
            "gold_minus_graphite_L": _diff(med(gold_trim), med(body)),
            "visor_minus_gold_L": _diff(med(visor), med(gold_trim)),
            "visor_minus_body_L": _diff(med(visor), med(body)),
        },
        "hierarchy_tiers_L": tiers,
        "hierarchy_monotonic": bool(all(a >= b for a, b in zip(present, present[1:]))),
        "visor_present": bool(visor.sum() >= 1),
    }


def _diff(a, b):
    return None if a is None or b is None else _r(a - b, 4)


def _alpha_histogram(alpha: np.ndarray) -> dict[str, Any]:
    counts, _ = np.histogram(alpha, bins=16, range=(0, 256))
    return {"bins16": [int(c) for c in counts], "zero": int((alpha == 0).sum()), "full": int((alpha == 255).sum()),
            "distinct_values": int(np.unique(alpha).size)}


def outline_metrics(image: Image.Image) -> dict[str, Any]:
    data = _rgba(image)
    mask = data[..., 3] >= ALPHA_CUTOFF
    lab = srgb_to_oklab(data[..., :3])
    lightness = lab[..., 0]
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    hue = (np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) + 360.0) % 360.0
    perimeter = _perimeter(mask)
    ring_lightness = lightness[perimeter]
    dark = lightness < 0.30
    ring2 = mask & ~perimeter & _perimeter(mask & ~perimeter)
    ring3_base = mask & ~perimeter & ~ring2
    ring3 = ring3_base & _perimeter(ring3_base)
    contaminants = mask & (chroma > 0.05) & ~((hue >= FAMILY_HUE[0]) & (hue <= FAMILY_HUE[1]))
    sizes = _components(mask)
    return {
        "alpha_perimeter_pixels": int(perimeter.sum()),
        "dark_outline_coverage": _r((perimeter & dark).sum() / max(1, perimeter.sum()), 4),
        "outline_lightness": _percentiles(ring_lightness, (5, 50, 95)),
        "ring_dark_share": {"ring1": _r((perimeter & dark).sum() / max(1, perimeter.sum()), 4),
                            "ring2": _r((ring2 & dark).sum() / max(1, ring2.sum()), 4),
                            "ring3": _r((ring3 & dark).sum() / max(1, ring3.sum()), 4)},
        "outlier_hue_contaminant_pixels": int(contaminants.sum()),
        "detached_islands_1_2px": int(sum(1 for s in sizes if s <= 2)),
        "alpha_components": len(sizes), "largest_component_area": sizes[0] if sizes else 0,
        "semitransparent_fringe_pixels": int(((data[..., 3] > 0) & (data[..., 3] < 255)).sum()),
        "thick_outline_warning_evidence": _r((ring3 & dark).sum() / max(1, ring3.sum()), 4),
    }


def rotational_continuity(per_direction: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    result = []
    for index, name in enumerate(DIRECTIONS):
        other = DIRECTIONS[(index + 1) % len(DIRECTIONS)]
        a, b = per_direction[name], per_direction[other]

        def rel_delta(x, y):
            return _r((y - x) / x, 4) if x else None

        cloak_a = a["geometry"]["cloak_mass_ratio"]
        cloak_b = b["geometry"]["cloak_mass_ratio"]
        result.append({
            "from": name, "to": other,
            "apparent_height_delta": rel_delta(a["geometry"]["apparent_height"], b["geometry"]["apparent_height"]),
            "head_scale_delta": rel_delta(a["anatomy"]["hood_top_to_head_center_px"], b["anatomy"]["hood_top_to_head_center_px"]),
            "shoulder_span_delta": rel_delta(a["anatomy"]["shoulder_span_px"], b["anatomy"]["shoulder_span_px"]),
            "hip_placement_delta_px": _r(b["registration"]["hip_center_x_offset"] - a["registration"]["hip_center_x_offset"], 2),
            "cloak_mass_delta": rel_delta(cloak_a, cloak_b),
            "overall_scale_delta": rel_delta(math.sqrt(a["geometry"]["area"]), math.sqrt(b["geometry"]["area"])),
        })
    return result


def cloak_mass_ratio(image: Image.Image, hip_y: float) -> float:
    mask = _alpha_mask(image)
    below = mask[int(round(hip_y)):, :].sum()
    return _r(below / max(1, mask.sum()), 4)


def derive_tolerances(per_direction: dict[str, dict[str, Any]]) -> dict[str, Any]:
    lightness = [d["color"]["oklab_lightness"]["mean"] for d in per_direction.values()]
    chroma = [d["color"]["chroma"]["mean"] for d in per_direction.values()]
    gold_l = [d["color"]["gold"]["median_L"] for d in per_direction.values() if d["color"]["gold"]["median_L"] is not None]
    gold_h = [d["color"]["gold"]["median_hue"] for d in per_direction.values() if d["color"]["gold"]["median_hue"] is not None]
    return {
        "basis": f"landmark/silhouette noise = {LANDMARK_NOISE_PX}px at 128 (one crisp pixel); structural tolerance = "
                 f"{TOLERANCE_K} x noise; palette tolerance = observed cross-direction spread of the approved reference with a floor",
        "frame_size": [FRAME, FRAME],
        "apparent_height_px": TOLERANCE_K * LANDMARK_NOISE_PX,
        "support_contact_px": TOLERANCE_K * LANDMARK_NOISE_PX,
        "hip_center_x_px": TOLERANCE_K * LANDMARK_NOISE_PX,
        "silhouette_area_ratio": 0.08,
        "per_frame_scale_ratio": 0.03,
        "palette": {
            "mean_lightness": _r(max(0.02, max(lightness) - min(lightness))),
            "mean_chroma": _r(max(0.01, max(chroma) - min(chroma))),
            "gold_median_lightness": _r(max(0.03, max(gold_l) - min(gold_l))) if gold_l else 0.03,
            "gold_median_hue_deg": _r(max(4.0, max(gold_h) - min(gold_h))) if gold_h else 4.0,
        },
        "enforcement": {"HARD_FAIL": ["frame_size", "alpha_contract", "clipping", "per_frame_scale", "profile_identity"],
                        "STRUCTURAL_WARN": ["apparent_height", "support_contact", "hip_center_x", "limb_ratio", "silhouette_area"],
                        "ART_DIRECTION_WARN": ["mean_lightness", "mean_chroma", "gold_lightness", "gold_hue"],
                        "INFO": ["pose_motion"]},
    }


# --------------------------------------------------------------------------- build
def root_model(points: dict[str, dict[str, Any]], support_row: int) -> dict[str, Any]:
    """Explicit, separate root/floor concepts. The projected world root is a candidate, never inferred from the front foot."""
    def contact(side: str) -> dict[str, Any]:
        p = points[f"toe_{side}"]
        return {"x": p["x"], "y": p["y"], "semantic": f"toe_{side}", "confidence": p["confidence"], "provenance": p["provenance"]}

    near, far = contact("near"), contact("far")
    left, right = sorted((near, far), key=lambda c: (c["x"], c["semantic"]))
    mid_x, mid_y = _r((near["x"] + far["x"]) / 2, 2), _r((near["y"] + far["y"]) / 2, 2)
    hip = points["hip_center"]
    return {
        "hip_center": {"x": hip["x"], "y": hip["y"], "confidence": hip["confidence"]},
        "left_foot_contact": {**left, "screen_side": "left"},
        "right_foot_contact": {**right, "screen_side": "right"},
        "foot_contact_midpoint": {"x": mid_x, "y": mid_y},
        "support_baseline_row": support_row,
        "projected_world_root": {
            "x": hip["x"], "y": mid_y, "status": "candidate_pending_human_calibration", "proven": False,
            "basis": "hip_center x; foot-contact midpoint y. Not the front/lowest toe and not the ground rail."},
        "shadow_origin": {
            "x": hip["x"], "y": mid_y, "status": "candidate_follows_projected_world_root_pending_human_calibration", "proven": False},
    }


def global_root_model(per_direction: dict[str, dict[str, Any]]) -> dict[str, Any]:
    mids = {d: v["root_model"]["foot_contact_midpoint"]["y"] for d, v in per_direction.items()}
    return {
        "status": "pending_human_calibration",
        "concepts": ["hip_center", "left_foot_contact", "right_foot_contact", "projected_world_root", "shadow_origin",
                     "support_baseline_row", "candidate_ground_rail"],
        "current_support_baseline_row": SUPPORT_ROW,
        "current_candidate_ground_rail": GROUND_Y,
        "foot_contact_midpoint_y": mids,
        "median_foot_contact_midpoint_y": _r(float(np.median(list(mids.values()))), 2),
        "comparison_candidate_root_rows": list(ROOT_CANDIDATE_ROWS),
        "finding": "y=111 is the lowest support-toe baseline of the current normalization; it is not yet a semantic "
                   "projected_world_root. The median foot-contact midpoint is the evidence for a root row, and does not "
                   "by itself define root_y.",
    }


def build_reference(master: Path | None = None, *, write_reports: bool = True) -> dict[str, Any]:
    master = master or (SOURCE_DIR / MASTER_NAME)
    manifest = preserve_source(master)
    annotations = load_annotations()
    cells = split_cells(SOURCE_DIR / MASTER_NAME)
    per_direction: dict[str, dict[str, Any]] = {}
    images: dict[str, Image.Image] = {}
    (REFERENCE_DIR / "directions").mkdir(parents=True, exist_ok=True)
    for direction, cell in zip(DIRECTIONS, cells):
        source_points = refine_source_landmarks(cell, annotations["directions"][direction])
        normalized = normalize_direction(cell, source_points)
        image = normalized["image"]
        images[direction] = image
        path = REFERENCE_DIR / "directions" / f"{direction}.png"
        image.save(path, optimize=False)
        geometry = silhouette_metrics(image)
        points = normalized["points"]
        geometry["cloak_mass_ratio"] = cloak_mass_ratio(image, points["hip_center"]["y"])
        registration = {
            "offset_xy": normalized["offset"], "support_basis": normalized["support_basis"],
            "support_contact_y": _support_row(image),
            "hip_center_x": points["hip_center"]["x"],
            "hip_center_x_offset": _r(points["hip_center"]["x"] - CENTER_X, 2),
            "alpha_bbox_center_x_offset": _r((geometry["alpha_bbox"][0] + geometry["alpha_bbox"][2]) / 2 - CENTER_X, 2),
            "note": "X authority is semantic hip_center; bbox center is evidence only",
        }
        per_direction[direction] = {
            "near_side": annotations["directions"][direction]["near_side"],
            "reference_png": rel(path), "reference_sha256": sha256_file(path),
            "source_cell": manifest["cells"][direction],
            "source_alpha_histogram": _alpha_histogram(_rgba(cell)[..., 3]),
            "landmarks": {"source_coordinate_space": "source_cell_480",
                          "source": {n: {"x": p["x"], "y": p["y"], "confidence": p["confidence"], "provenance": p["provenance"]}
                                     for n, p in source_points.items()},
                          "normalized_128": {n: {k: v for k, v in p.items() if k != "source_xy"} for n, p in points.items()}},
            "registration": registration, "root_model": root_model(points, _support_row(image)), "geometry": geometry,
            "anatomy": anatomy_metrics({n: points[n] for n in points}, geometry),
            "color": color_metrics(image, head_band(points)), "outline": outline_metrics(image),
        }
    sheet_sha = sha256_bytes(canonical_json({d: per_direction[d]["reference_sha256"] for d in DIRECTIONS}).encode())
    lock_path = REFERENCE_DIR / "operator_2_5d_rotation_lock_128.png"
    lock = Image.new("RGBA", (FRAME * len(DIRECTIONS), FRAME), (0, 0, 0, 0))
    for index, d in enumerate(DIRECTIONS):
        lock.paste(images[d], (index * FRAME, 0))
    lock.save(lock_path, optimize=False)
    medians = _median_guide(per_direction)
    tolerances = derive_tolerances(per_direction)
    reference = {
        "schema": "custodian.operator_2_5d_design_reference.v1",
        "source": {"path": manifest["path"], "sha256": manifest["sha256"], "dimensions": manifest["dimensions"],
                   "cell_size": manifest["cell_size"], "order": list(DIRECTIONS)},
        "normalization": {
            "frame_size": [FRAME, FRAME], "scale": f"{SCALE_NUM}/{SCALE_DEN}", "scale_policy": "one shared scale for all eight directions",
            "method": "crisp: BOX area reduction then binary alpha (cutoff 128); integer translation only; no rotation, shear or per-direction scale",
            "center_x": CENTER_X, "support_row": SUPPORT_ROW, "ground_y": GROUND_Y, "anchor": [CENTER_X, SUPPORT_ROW],
            "x_authority": "semantic hip_center", "y_authority": "semantic support contact (toe_near/toe_far); alpha bottom is fallback only",
            "derivation": "PROVISIONAL. Support baseline row 111 is the lowest toe sole after integer placement; it is a support-foot "
                          "baseline, not a proven projected_world_root. Ground rail 112 is a candidate pending human calibration.",
            "scale_status": "provisional candidate A (0.200); candidate B (0.225) compared in the A/B artifacts",
        },
        "authority": dict(AUTHORITY),
        "root_model": global_root_model(per_direction),
        "annotations": {"path": rel(ANNOTATIONS_PATH), "sha256": sha256_file(ANNOTATIONS_PATH),
                        "provenance": "agent visual annotation; confidence recorded per point; occluded points <= 0.4"},
        "rotation_lock": {"path": rel(lock_path), "sha256": sha256_file(lock_path), "directions_sha256": sheet_sha},
        "guide_medians": medians, "tolerances": tolerances,
        "identity_locks": list(IDENTITY_LOCKS),
        "directions": per_direction,
        "rotational_continuity": rotational_continuity(per_direction),
        "human_authority_only": [
            "numeric camera pitch (not derivable from flattened pixels; the turnaround is projection authority)",
            "subjective visor/gold highlight taste", "occluded-landmark placement below confidence 0.6",
            "projected_world_root / shadow_origin row (candidates only)", "canonical shared body scale (A/B)",
            "sign-off on the crisp reduction of the approved render"],
    }
    write_json(REFERENCE_JSON_PATH, reference)
    profile = write_profile(reference)
    if write_reports:
        write_reports_bundle(reference, images, profile)
        from . import canonical_calibration
        canonical_calibration.build_calibration(reference, cells, annotations)
    return reference


def _support_row(image: Image.Image) -> int:
    rows = np.where(_alpha_mask(image).any(axis=1))[0]
    return int(rows.max())


def _median_guide(per_direction: dict[str, dict[str, Any]]) -> dict[str, Any]:
    def values(name, axis):
        return [d["landmarks"]["normalized_128"][name][axis] for d in per_direction.values()
                if d["landmarks"]["normalized_128"][name]["confidence"] >= CONFIDENT]

    def med(name, axis):
        return int(round(float(np.median(values(name, axis)))))

    horizontal = {
        "head_top": med("hood_top", "y"), "head_center": med("head_center", "y"),
        "shoulders": int(round(float(np.median(values("shoulder_near", "y") + values("shoulder_far", "y"))))),
        "hips": med("hip_center", "y"),
        "knees": int(round(float(np.median(values("knee_near", "y") + values("knee_far", "y"))))),
        "feet": SUPPORT_ROW, "ground": GROUND_Y,
    }
    south = per_direction["s"]["landmarks"]["normalized_128"]

    def sx(name):
        return int(round(south[name]["x"]))

    def sy(name):
        return int(round(south[name]["y"]))

    vertical = {"center": CENTER_X, "shoulder_l": sx("shoulder_near"), "shoulder_r": sx("shoulder_far"),
                "hip_l": sx("hip_near"), "hip_r": sx("hip_far")}
    points = {"head_center": [CENTER_X, horizontal["head_center"]], "hip_center": [CENTER_X, horizontal["hips"]],
              "shoulder_l": [sx("shoulder_near"), sy("shoulder_near")], "shoulder_r": [sx("shoulder_far"), sy("shoulder_far")],
              "hip_l": [sx("hip_near"), sy("hip_near")], "hip_r": [sx("hip_far"), sy("hip_far")],
              "knee_l": [sx("knee_near"), sy("knee_near")], "knee_r": [sx("knee_far"), sy("knee_far")],
              "foot_anchor": [CENTER_X, SUPPORT_ROW]}
    head_hip = [d["anatomy"]["head_hip_px"] for d in per_direction.values()
                if d["anatomy"]["segments"]["head_center:hip_center"]["reliable"]]
    return {"horizontal": horizontal, "vertical": vertical, "points": points,
            "head_hip_median_px": _r(float(np.median(head_hip)), 2), "modular_split_reference_y": horizontal["hips"]}


def write_profile(reference: dict[str, Any]) -> dict[str, Any]:
    existing = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
    if existing["schema"] == "custodian.operator_art_profile.v3":
        legacy = existing["profiles"][LEGACY_PROFILE_ID]
    else:
        legacy = {"registration": existing["registration"], "measurements": existing.get("measurements", {}),
                  "note": "Migrated unchanged from operator_art_profile.v2; legacy 96x96 production art remains valid."}
    guide = reference["guide_medians"]
    norm = reference["normalization"]
    profile = {
        "schema": "custodian.operator_art_profile.v3",
        "status": "provisional",
        "enforcement": existing.get("enforcement", {"structural": True, "registration_geometry": True, "artistic": False}),
        "active_authoring_profile": PROFILE_ID,
        "profiles": {
            LEGACY_PROFILE_ID: legacy,
            PROFILE_ID: {
                "registration": {
                    "status": "provisional", "frame_size": [FRAME, FRAME], "anchor": norm["anchor"], "ground_y": GROUND_Y,
                    "anchor_semantics": "support_foot_baseline_provisional (not a proven projected_world_root)",
                    "provenance": {"kind": "agent_derived_from_user_approved_visual_lock", "accepted": False,
                                   "source_sha256": reference["source"]["sha256"]},
                    "authority": dict(AUTHORITY),
                    "guide": {k: guide[k] for k in ("horizontal", "vertical", "points", "modular_split_reference_y")},
                    "normalization": {
                        "mode": "shared_scale", "source_landmark_min_confidence": 0.75,
                        "frame_translation_limit": 12, "auto_frame_translation": False,
                        "canonical_scale": norm["scale"], "canonical_source_cell": SOURCE_CELL,
                        "scale_segments": [{"a": "head_center", "b": "hip_center",
                                            "target_length": guide["head_hip_median_px"], "weight": 1.0}],
                        "scale_segment_note": "Only head_center:hip_center is scale authority; span segments foreshorten by bearing.",
                    },
                },
                "direction_order": list(DIRECTIONS),
                "tolerances_path": rel(REFERENCE_JSON_PATH) + "#/tolerances",
            },
        },
        "canonical_visual_reference": {
            "path": reference["source"]["path"], "sha256": reference["source"]["sha256"],
            "measurements_path": rel(REFERENCE_JSON_PATH),
            "rotation_lock_path": reference["rotation_lock"]["path"],
            "directions_dir": rel(REFERENCE_DIR / "directions"),
        },
        "note": "legacy_96 is accepted. operator_2_5d_128 is PROVISIONAL: it loads for measurement, preview, guides, QA and "
                "calibration but is not human-accepted; root/floor, shared body scale, the universal 128 envelope and the "
                "final normalized hash are pending. New authoring defaults to operator_2_5d_128 for calibration only.",
    }
    write_json(PROFILE_PATH, profile)
    return profile


# --------------------------------------------------------------------------- reports
def _checker(size: tuple[int, int], cell: int = 8) -> Image.Image:
    image = Image.new("RGBA", size, (58, 60, 66, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(70, 72, 80, 255))
    return image


def render_turnaround(images: dict[str, Image.Image], reference: dict[str, Any], *, zoom: int = 3, landmarks: bool = False) -> Image.Image:
    cell = FRAME * zoom
    sheet = _checker((cell * len(DIRECTIONS), cell + 18))
    draw = ImageDraw.Draw(sheet)
    for index, d in enumerate(DIRECTIONS):
        ox = index * cell
        layer = images[d].resize((cell, cell), Image.Resampling.NEAREST)
        sheet.alpha_composite(layer, (ox, 18))
        draw.line((ox + CENTER_X * zoom, 18, ox + CENTER_X * zoom, 18 + cell), fill=(80, 190, 255, 255))
        draw.line((ox, 18 + GROUND_Y * zoom, ox + cell, 18 + GROUND_Y * zoom), fill=(72, 235, 190, 255))
        draw.text((ox + 4, 3), d.upper(), fill=(255, 255, 255, 255))
        if landmarks:
            for name, p in reference["directions"][d]["landmarks"]["normalized_128"].items():
                cx, cy = ox + p["x"] * zoom, 18 + p["y"] * zoom
                color = (255, 225, 95, 255) if p["confidence"] >= CONFIDENT else (255, 90, 100, 255)
                draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), outline=color)
                if "center" in name or "top" in name:
                    draw.text((cx + 4, cy - 5), name.split("_")[0][:4], fill=color)
    return sheet


def _summary_geometry(reference: dict[str, Any]) -> dict[str, Any]:
    return {"schema": "custodian.operator_2_5d_measurement_summary.v1", "source_sha256": reference["source"]["sha256"],
            "frame": reference["normalization"], "tolerances": reference["tolerances"],
            "directions": {d: {"registration": v["registration"], "geometry": v["geometry"], "anatomy": {
                k: v["anatomy"][k] for k in ("head_hip_px", "torso_length_px", "apparent_leg_length_px", "shoulder_span_px",
                                              "hip_span_px", "cloak_tip_displacement")},
                "outline": v["outline"]} for d, v in reference["directions"].items()},
            "rotational_continuity": reference["rotational_continuity"]}


def _summary_palette(reference: dict[str, Any]) -> dict[str, Any]:
    return {"schema": "custodian.operator_2_5d_palette_summary.v1", "source_sha256": reference["source"]["sha256"],
            "tolerances": reference["tolerances"]["palette"],
            "directions": {d: v["color"] for d, v in reference["directions"].items()}}


def write_reports_bundle(reference: dict[str, Any], images: dict[str, Image.Image], profile: dict[str, Any]) -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    render_turnaround(images, reference).save(REPORT_DIR / "operator_2_5d_reference_turnaround.png")
    render_turnaround(images, reference, zoom=4, landmarks=True).save(REPORT_DIR / "operator_2_5d_landmark_overlay.png")
    write_json(REPORT_DIR / "operator_2_5d_measurement_summary.json", _summary_geometry(reference))
    write_json(REPORT_DIR / "operator_2_5d_palette_summary.json", _summary_palette(reference))
    profile_block = profile["profiles"][PROFILE_ID]
    profile_sha = sha256_bytes(canonical_json({"id": PROFILE_ID, "profile": profile_block,
                                               "reference": profile["canonical_visual_reference"]}).encode())
    rows = []
    for d in DIRECTIONS:
        v = reference["directions"][d]
        rows.append(f"| {d.upper()} | {v['geometry']['apparent_height']} | {v['geometry']['apparent_width']} | "
                    f"{v['registration']['support_contact_y']} | {v['registration']['hip_center_x_offset']} | "
                    f"{v['anatomy']['head_hip_px']} | {v['color']['oklab_lightness']['mean']} | {v['color']['visor_present']} | "
                    f"{v['outline']['semitransparent_fringe_pixels']} |")
    worst = max(reference["rotational_continuity"], key=lambda r: abs(r["apparent_height_delta"] or 0))
    unreliable = sorted({f"{d}:{k}" for d, v in reference["directions"].items() for k, s in v["anatomy"]["segments"].items() if not s["reliable"]})
    tol = reference["tolerances"]
    text = f"""# Operator 2.5D Canonical Visual Contract Report

Generated deterministically by `custodian/tools/operator/art_agent/canonical_contract.py`.

## Identity
- Approved source: `{reference['source']['path']}`
- Source SHA-256: `{reference['source']['sha256']}`
- Source geometry: {reference['source']['dimensions'][0]}x{reference['source']['dimensions'][1]} RGBA, eight {SOURCE_CELL}x{SOURCE_CELL} cells
- Direction order: {', '.join(d.upper() for d in DIRECTIONS)}
- Packet deviation: the packet recorded a 2048x256 attachment (`2d5de16d...5323`); the user confirmed the 3840x480 repository-root file as the approved lock.
- Profile registry: `operator_art_profile.v3`, active `{PROFILE_ID}` (**provisional**), legacy `{LEGACY_PROFILE_ID}` (accepted) retained unchanged
- Effective profile hash (`{PROFILE_ID}`): `{profile_sha}`
- Provisional 128 frame: center x = {CENTER_X}, support-foot baseline row = {SUPPORT_ROW}, candidate ground rail = {GROUND_Y}
- Provisional shared scale (candidate A): {SCALE_NUM}/{SCALE_DEN}; candidate B (9/40) is in the A/B artifacts; translation is integer-only per direction

## Status
| Item | State |
|---|---|
{chr(10).join(f"| {k.replace('_', ' ')} | {v.replace('_', ' ')} |" for k, v in AUTHORITY.items())}

Root/floor: y={SUPPORT_ROW} is the lowest support-toe baseline of this normalization, not a proven projected_world_root. Median foot-contact midpoint y = {reference['root_model']['median_foot_contact_midpoint_y']}; this is evidence, not a definition of root_y. See `root_model` in the design reference JSON and `operator_2_5d_registration_overlay.png`.

## Per-direction summary (normalized 128)
| Dir | Height | Width | Support y | Hip x offset | Head-hip px | Mean OKLab L | Visor | Fringe px |
|---|---|---|---|---|---|---|---|---|
{chr(10).join(rows)}

## Tolerances (derived, not invented)
- Basis: {tol['basis']}
- Tolerances are provisional until the profile is accepted.
- Hard: frame size, alpha contract (binary, no clipping), per-frame scale (> {tol['per_frame_scale_ratio']:.0%} ratio spread across baseline frames), profile identity.
- Structural (warn): apparent height +/-{tol['apparent_height_px']}px, support contact +/-{tol['support_contact_px']}px, hip x +/-{tol['hip_center_x_px']}px, silhouette area +/-{tol['silhouette_area_ratio']:.0%}, limb ratios per-segment (see design reference JSON).
- Art-direction (warn): palette tolerances {tol['palette']}.

## Rotational continuity
Largest apparent-height step: {worst['from'].upper()} -> {worst['to'].upper()} ({worst['apparent_height_delta']}). Reported only; no art is warped.

## Human-authority-only
{chr(10).join('- ' + item for item in reference['human_authority_only'])}

Low-confidence (< {CONFIDENT}) segments used as evidence only: {len(unreliable)} segment records (see `anatomy.segments[*].reliable`).

## Evidence
- `operator_2_5d_reference_turnaround.png`, `operator_2_5d_landmark_overlay.png`
- `operator_2_5d_measurement_summary.json`, `operator_2_5d_palette_summary.json`
- Full data: `{rel(REFERENCE_JSON_PATH)}`
"""
    (REPORT_DIR / "OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_REPORT.md").write_text(text, encoding="utf-8")


# --------------------------------------------------------------------------- QA
def load_reference(path: Path = REFERENCE_JSON_PATH) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def finding(severity: str, code: str, message: str, **extra: Any) -> dict[str, Any]:
    assert severity in SEVERITIES
    return {"severity": severity, "code": code, "message": message, **extra}


def frame_measurements(image: Image.Image, head_rows: list[int] | None = None) -> dict[str, Any]:
    geometry = silhouette_metrics(image)
    color = color_metrics(image, head_rows)
    return {"geometry": geometry, "support_contact_y": geometry["alpha_bbox"][3] - 1, "color": color,
            "semitransparent": int(((_rgba(image)[..., 3] > 0) & (_rgba(image)[..., 3] < 255)).sum())}


def evaluate_frame(image: Image.Image, direction: str, *, reference: dict[str, Any] | None = None,
                   landmarks: dict[str, dict[str, Any]] | None = None, baseline: bool = True) -> list[dict[str, Any]]:
    """Classify a frame against the canonical reference of its direction."""
    if direction not in DIRECTIONS:
        raise ValueError(f"unknown direction: {direction}")
    reference = reference or load_reference()
    ref = reference["directions"][direction]
    tol = reference["tolerances"]
    findings: list[dict[str, Any]] = []
    if image.size != (FRAME, FRAME):
        return [finding("HARD_FAIL", "FRAME_SIZE", f"frame is {image.size[0]}x{image.size[1]}; canonical profile requires {FRAME}x{FRAME}")]
    data = _rgba(image)
    if int(((data[..., 3] > 0) & (data[..., 3] < 255)).sum()):
        findings.append(finding("HARD_FAIL", "ALPHA_CONTRACT", "semitransparent pixels present; canonical frames use true binary alpha"))
    mask = data[..., 3] > 0
    if not mask.any():
        return findings + [finding("HARD_FAIL", "EMPTY_FRAME", "frame has no opaque pixels")]
    if mask[0].any() or mask[-1].any() or mask[:, 0].any() or mask[:, -1].any():
        findings.append(finding("HARD_FAIL", "CLIPPING", "opaque pixels touch the frame edge"))
    ref_points = ref["landmarks"]["normalized_128"]
    measured = frame_measurements(image, head_band(ref_points))
    geometry, ref_geometry = measured["geometry"], ref["geometry"]
    if baseline:
        drift = geometry["apparent_height"] - ref_geometry["apparent_height"]
        if abs(drift) > tol["apparent_height_px"]:
            findings.append(finding("STRUCTURAL_WARN", "BODY_SCALE_DRIFT",
                                    f"apparent height {geometry['apparent_height']}px vs reference {ref_geometry['apparent_height']}px",
                                    drift_px=drift, tolerance_px=tol["apparent_height_px"]))
        area_ratio = geometry["area"] / ref_geometry["area"] - 1
        if abs(area_ratio) > tol["silhouette_area_ratio"]:
            findings.append(finding("STRUCTURAL_WARN", "SILHOUETTE_AREA_DRIFT", f"silhouette area differs {area_ratio:+.1%}",
                                    drift_ratio=_r(area_ratio, 4), tolerance_ratio=tol["silhouette_area_ratio"]))
        support = measured["support_contact_y"]
        expected = ref["registration"]["support_contact_y"]
        if landmarks and {"toe_near", "toe_far"} <= landmarks.keys():
            support, evidence = max(landmarks["toe_near"]["y"], landmarks["toe_far"]["y"]), "semantic_toe_landmarks"
        else:
            evidence = "alpha_bottom_fallback"
        if abs(support - expected) > tol["support_contact_px"]:
            findings.append(finding("STRUCTURAL_WARN", "SUPPORT_ROOT_DRIFT",
                                    f"support contact y={support} vs canonical {expected}", drift_px=_r(support - expected, 2),
                                    tolerance_px=tol["support_contact_px"], evidence=evidence))
        if landmarks:
            findings += _landmark_findings(landmarks, ref, tol)
    else:
        findings.append(finding("INFO", "POSE_MOTION", "non-baseline pose frame: joint/root motion is intentional; anatomy checks limited to scale/alpha/clipping"))
        if abs(geometry["apparent_height"] - ref_geometry["apparent_height"]) > 0.6 * ref_geometry["apparent_height"]:
            findings.append(finding("STRUCTURAL_WARN", "BODY_SCALE_DRIFT", "pose frame height diverges far beyond any pose extension"))
    findings += _palette_findings(measured["color"], ref["color"], tol["palette"])
    return findings


def _landmark_findings(landmarks, ref, tol) -> list[dict[str, Any]]:
    out = []
    if "hip_center" in landmarks:
        offset = landmarks["hip_center"]["x"] - CENTER_X
        if abs(offset) > tol["hip_center_x_px"]:
            out.append(finding("STRUCTURAL_WARN", "HIP_CENTER_DRIFT", f"hip_center x offset {offset:+.1f}px from frame center",
                               drift_px=_r(offset, 2), tolerance_px=tol["hip_center_x_px"]))
    if {"head_center", "hip_center"} <= landmarks.keys():
        head_hip = math.dist((landmarks["head_center"]["x"], landmarks["head_center"]["y"]),
                             (landmarks["hip_center"]["x"], landmarks["hip_center"]["y"]))
        for key, seg in ref["anatomy"]["segments"].items():
            a, b = key.split(":")
            if not seg["reliable"] or a not in landmarks or b not in landmarks:
                continue
            length = math.dist((landmarks[a]["x"], landmarks[a]["y"]), (landmarks[b]["x"], landmarks[b]["y"]))
            ratio = length / head_hip
            if abs(ratio - seg["ratio_to_head_hip"]) > max(seg["tolerance_ratio_to_head_hip"], 1e-6) and key != "head_center:hip_center":
                out.append(finding("STRUCTURAL_WARN", "LIMB_RATIO_DRIFT", f"{key} ratio {ratio:.3f} vs {seg['ratio_to_head_hip']:.3f}",
                                   segment=key, observed=_r(ratio, 4), expected=seg["ratio_to_head_hip"],
                                   tolerance=seg["tolerance_ratio_to_head_hip"]))
        expected_hh = ref["anatomy"]["head_hip_px"]
        if abs(head_hip - expected_hh) > TOLERANCE_K * LANDMARK_NOISE_PX * math.sqrt(2):
            out.append(finding("STRUCTURAL_WARN", "HEAD_SCALE_DRIFT", f"head-to-hip {head_hip:.1f}px vs {expected_hh}px",
                               observed=_r(head_hip, 2), expected=expected_hh))
    return out


def _palette_findings(color, ref_color, tol) -> list[dict[str, Any]]:
    out = []
    checks = (("mean_lightness", color["oklab_lightness"]["mean"], ref_color["oklab_lightness"]["mean"], tol["mean_lightness"], "lightness"),
              ("mean_chroma", color["chroma"]["mean"], ref_color["chroma"]["mean"], tol["mean_chroma"], "chroma"),
              ("gold_median_lightness", color["gold"]["median_L"], ref_color["gold"]["median_L"], tol["gold_median_lightness"], "gold lightness"),
              ("gold_median_hue_deg", color["gold"]["median_hue"], ref_color["gold"]["median_hue"], tol["gold_median_hue_deg"], "gold hue"))
    for key, got, want, allowed, label in checks:
        if got is None or want is None:
            if (got is None) != (want is None) and key.startswith("gold"):
                out.append(finding("ART_DIRECTION_WARN", "GOLD_TRIM_PRESENCE", "gold trim presence differs from the approved reference", metric=key))
            continue
        if abs(got - want) > allowed:
            out.append(finding("ART_DIRECTION_WARN", "PALETTE_DRIFT", f"{label} {got} vs reference {want}",
                               metric=key, observed=got, expected=want, tolerance=allowed))
    if ref_color["visor_present"] and not color["visor_present"]:
        out.append(finding("ART_DIRECTION_WARN", "VISOR_MISSING", "visor focal highlight absent where the reference has one"))
    return out


def evaluate_animation(frames: list[Image.Image], direction: str, *, reference: dict[str, Any] | None = None,
                       baseline: list[bool] | None = None, landmarks: list[dict[str, dict[str, Any]] | None] | None = None,
                       profile_sha256: str | None = None, expected_profile_sha256: str | None = None) -> dict[str, Any]:
    reference = reference or load_reference()
    baseline = baseline or [True] * len(frames)
    landmarks = landmarks or [None] * len(frames)
    findings: list[dict[str, Any]] = []
    if profile_sha256 is not None and expected_profile_sha256 is not None and profile_sha256 != expected_profile_sha256:
        findings.append(finding("HARD_FAIL", "PROFILE_IDENTITY", "animation was authored against a different canonical profile hash",
                                recorded=profile_sha256, expected=expected_profile_sha256))
    per_frame = []
    for index, (frame, is_base, points) in enumerate(zip(frames, baseline, landmarks), 1):
        items = evaluate_frame(frame, direction, reference=reference, landmarks=points, baseline=is_base)
        findings += [dict(item, frame=index) for item in items]
        per_frame.append(items)
    ratios = []
    for frame, is_base in zip(frames, baseline):
        if is_base and frame.size == (FRAME, FRAME) and _alpha_mask(frame).any():
            ratios.append(silhouette_metrics(frame)["apparent_height"] / reference["directions"][direction]["geometry"]["apparent_height"])
    if len(ratios) > 1 and max(ratios) - min(ratios) > reference["tolerances"]["per_frame_scale_ratio"]:
        findings.append(finding("HARD_FAIL", "PER_FRAME_SCALE", "baseline frames disagree on body scale; per-frame rescale is forbidden",
                                ratio_spread=_r(max(ratios) - min(ratios), 4),
                                tolerance=reference["tolerances"]["per_frame_scale_ratio"]))
    counts = {s: sum(1 for f in findings if f["severity"] == s) for s in SEVERITIES}
    status = "HARD_FAIL" if counts["HARD_FAIL"] else "WARN" if counts["STRUCTURAL_WARN"] or counts["ART_DIRECTION_WARN"] else "PASS"
    return {"schema": "custodian.operator_2_5d_canonical_qa.v1", "direction": direction, "status": status,
            "counts": counts, "findings": findings}


def load_direction_image(direction: str) -> Image.Image:
    return Image.open(REFERENCE_DIR / "directions" / f"{direction}.png").convert("RGBA")


def effective_profile_hash(profile: dict[str, Any], profile_id: str = PROFILE_ID) -> str:
    return sha256_bytes(canonical_json({"id": profile_id, "profile": profile["profiles"][profile_id],
                                        "reference": profile["canonical_visual_reference"]}).encode())


def main(argv: list[str] | None = None) -> int:
    import argparse
    parser = argparse.ArgumentParser(description="Build or verify the Operator 2.5D canonical visual contract")
    parser.add_argument("command", choices=("build", "verify"))
    parser.add_argument("--master", type=Path, default=None)
    args = parser.parse_args(argv)
    if args.command == "build":
        reference = build_reference(args.master)
        print(f"built canonical visual contract for {reference['source']['sha256']}")
        return 0
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    identity = verify_master(SOURCE_DIR / MASTER_NAME)
    assert identity["sha256"] == manifest["sha256"], "preserved master hash drifted"
    print("verified preserved master", identity["sha256"])
    return 0


if __name__ == "__main__":
    # Re-enter through the package so relative imports (calibration) and module state are single-instance.
    sys.path.insert(0, str(CUSTODIAN / "tools/operator"))
    from art_agent.canonical_contract import main as _package_main
    raise SystemExit(_package_main())
