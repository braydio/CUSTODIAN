#!/usr/bin/env python3
"""Pose accepted Custodian semantic cels without changing their source pixels."""
from __future__ import annotations

import importlib.util
from pathlib import Path

import numpy as np

from .pose_map import NEUTRAL, SIDES

W = H = 128
LIMB_PARTS = ("thigh_near_visible", "shin_near_visible", "foot_near_visible",
              "thigh_far_visible", "shin_far_visible", "foot_far_visible")
ROBE_PARTS = ("robe_far", "robe_center", "robe_near")
MOVING_PARTS = tuple(f"__RIG_PART_{name}" for name in (
    "thigh_far_visible", "shin_far_visible", "foot_far_visible", "robe_far",
    "thigh_near_visible", "shin_near_visible", "foot_near_visible", "robe_center", "robe_near"))
DRAW_ORDER = ("thigh_far_visible", "shin_far_visible", "foot_far_visible", "robe_far",
              "thigh_near_visible", "shin_near_visible", "foot_near_visible", "robe_center", "robe_near")


def _r2_helpers():
    path = Path(__file__).resolve().parents[1] / "clean_silhouette_r2.py"
    spec = importlib.util.spec_from_file_location("operator_ne_r2_raster_helpers", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load the accepted R2 raster helpers")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_rig(path: Path) -> dict[str, np.ndarray]:
    return _r2_helpers().parse_aseprite_rig(path, enforce_sha=True)


def source_palette(image: np.ndarray) -> set[tuple[int, int, int, int]]:
    return {tuple(map(int, px)) for px in image.reshape(-1, 4) if int(px[3]) > 0}


def validate_candidate_pixels(image: np.ndarray, palette: set[tuple[int, int, int, int]]) -> None:
    if image.shape != (H, W, 4):
        raise ValueError("candidate spilled outside its 128x128 cell")
    if not np.isin(image[:, :, 3], (0, 255)).all():
        raise ValueError("candidate alpha is not binary")
    if not source_palette(image).issubset(palette):
        raise ValueError("candidate introduced color outside accepted Custodian palette")


def ensure_fresh_output(path: Path) -> None:
    if path.exists():
        raise FileExistsError(f"output folder already exists; refusing overwrite: {path}")


def validate_expected_occlusion(frame: int, side: str, nearest_visible: bool,
                                occluded_pixels: int) -> None:
    # F07's accepted far support can be occluded by the crossing near leg.
    # Preserve semantic draw order; never expose it with an alpha patch.
    if frame == 7 and side == "far" and nearest_visible:
        raise ValueError("F07 far support unexpectedly exposed; retain semantic occlusion")
    if not nearest_visible and occluded_pixels <= 0:
        raise ValueError("hidden support lacks semantic occlusion evidence")


def validate_rig_and_neutral(rig: dict[str, np.ndarray]) -> dict:
    """Create a static upper-body residual and prove exact neutral reassembly."""
    full_name = "__RIG_REFERENCE_LOCKED_FULL_BODY"
    if full_name not in rig:
        raise ValueError("accepted rig missing locked full-body layer")
    full = rig[full_name]
    if full.shape != (H, W, 4) or not np.isin(full[:, :, 3], (0, 255)).all():
        raise ValueError("locked full-body layer must be 128x128 with binary alpha")
    for name in MOVING_PARTS:
        if name not in rig:
            raise ValueError(f"accepted rig missing semantic part {name}")
        part = rig[name]
        if part.shape != (H, W, 4) or not np.isin(part[:, :, 3], (0, 255)).all():
            raise ValueError(f"{name}: invalid dimensions or nonbinary alpha")
        if np.count_nonzero(part[:, :, 3]) < 4:
            raise ValueError(f"{name}: empty semantic owner")
    dynamic_union = np.zeros((H, W), dtype=bool)
    for name in MOVING_PARTS:
        mask = rig[name][:, :, 3] > 0
        if np.any(dynamic_union & mask):
            raise ValueError(f"semantic moving owners overlap before composition: {name}")
        dynamic_union |= mask
    residual = full.copy()
    residual[dynamic_union] = 0
    neutral = residual.copy()
    for name in DRAW_ORDER:
        cel = rig[f"__RIG_PART_{name}"]
        mask = cel[:, :, 3] > 0
        neutral[mask] = cel[mask]
    diff = np.any(neutral != full, axis=2)
    if diff.any():
        y, x = np.where(diff)
        raise ValueError(f"neutral owner reassembly mismatch: {len(x)} pixels; bbox "
                         f"({x.min()},{y.min()})-({x.max()},{y.max()})")
    return {"full": full.copy(), "residual": residual,
            "palette": source_palette(full), "neutral_reassembly_changed_pixels": 0,
            "dynamic_owner_pixels": int(dynamic_union.sum()),
            "static_residual_pixels": int(np.count_nonzero(residual[:, :, 3]))}


def _translate_nearest(image: np.ndarray, delta: tuple[float, float]) -> np.ndarray:
    dx, dy = (int(np.rint(float(v))) for v in delta)
    out = np.zeros_like(image)
    sx0, sy0 = max(0, -dx), max(0, -dy)
    sx1, sy1 = min(W, W - dx), min(H, H - dy)
    if sx0 < sx1 and sy0 < sy1:
        out[sy0 + dy:sy1 + dy, sx0 + dx:sx1 + dx] = image[sy0:sy1, sx0:sx1]
    return out


def _row_shear(src: np.ndarray, kind: str, stride: float) -> np.ndarray:
    out = np.zeros_like(src)
    _, xx = np.mgrid[0:H, 0:W]
    for y in range(H):
        v = min(1.0, max(0.0, (y - 73) / 24.0))
        if kind == "near":
            shift = int(np.rint(v * min(2.0, max(-2.0, 0.25 * stride))))
        elif kind == "far":
            shift = int(np.rint(v * min(2.0, max(-2.0, -0.15 * stride))))
        elif kind == "center":
            near_shift = int(np.rint(v * min(2.0, max(-2.0, 0.25 * stride))))
            shift = int(np.rint(near_shift / 2.0))
        else:
            raise ValueError(f"unknown robe semantic owner: {kind}")
        sx = xx[y] - shift
        inside = (sx >= 0) & (sx < W)
        out[y, inside] = src[y, sx[inside]]
    return out


def _component_owner_join(owner: np.ndarray, left: int, right: int) -> tuple[bool, int]:
    mask = (owner == left) | (owner == right)
    seen = np.zeros(mask.shape, dtype=bool)
    h, w = mask.shape
    components = 0
    for y, x in zip(*np.where(mask & ~seen)):
        if seen[y, x]:
            continue
        components += 1
        stack = [(int(y), int(x))]
        seen[y, x] = True
        has_left = has_right = False
        while stack:
            cy, cx = stack.pop()
            has_left |= owner[cy, cx] == left
            has_right |= owner[cy, cx] == right
            for ny in range(max(0, cy - 1), min(h, cy + 2)):
                for nx in range(max(0, cx - 1), min(w, cx + 2)):
                    if mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if has_left and has_right:
            return True, components
    return False, components


def _owner_id(name: str) -> int:
    return DRAW_ORDER.index(name) + 2


def render_pose(rig_state: dict, posed: dict) -> tuple[np.ndarray, np.ndarray, dict]:
    """Render one actual Custodian pose; Knight pixels never enter this function."""
    r2 = _r2_helpers()
    rig = rig_state["rig"]
    delta = tuple(posed["translation"])
    canvas = _translate_nearest(rig_state["residual"], delta)
    owner = np.zeros((H, W), dtype=np.uint8)
    owner[canvas[:, :, 3] > 0] = 1  # static locked torso/hood/arms/pelvis residual
    warped: dict[str, np.ndarray] = {}
    for side in SIDES:
        points = posed["posed"][side]
        neutral = NEUTRAL[side]
        for part, a, b in ((f"thigh_{side}_visible", "hip", "knee"),
                           (f"shin_{side}_visible", "knee", "ankle"),
                           (f"foot_{side}_visible", "ankle", "toe")):
            source = rig[f"__RIG_PART_{part}"]
            warped[part] = r2.rigid_warp(source, neutral[a], neutral[b], points[a], points[b])
    near = posed["posed"]["near"]
    far = posed["posed"]["far"]
    stride = ((near["ankle"][0] - near["hip"][0]) -
              (far["ankle"][0] - far["hip"][0]))
    for robe in ("robe_far", "robe_center", "robe_near"):
        warped[robe] = _row_shear(rig[f"__RIG_PART_{robe}"], robe.removeprefix("robe_"), stride)
        warped[robe] = _translate_nearest(warped[robe], delta)
    # Limb/robe source parts move around the fixed residual; apron changes are
    # restricted to the three named semantic cloth owners.
    for name in DRAW_ORDER:
        layer = warped[name]
        mask = layer[:, :, 3] > 0
        canvas[mask] = layer[mask]
        owner[mask] = _owner_id(name)
    validate_candidate_pixels(canvas, rig_state["palette"])
    colors = source_palette(canvas)

    links = {}
    for side in SIDES:
        shin_id = _owner_id(f"shin_{side}_visible")
        foot_id = _owner_id(f"foot_{side}_visible")
        linked, components = _component_owner_join(owner, shin_id, foot_id)
        visible_foot = int(np.count_nonzero(owner == foot_id))
        links[side] = {"boot_connected_to_shin": linked, "distal_owner_components": components,
                       "visible_boot_pixels": visible_foot}

    support = posed["support"]
    foot_id = _owner_id(f"foot_{support}_visible")
    source_foot = warped[f"foot_{support}_visible"]
    support_mask = source_foot[:, :, 3] > 0
    visible = support_mask & (owner == foot_id)
    covered = support_mask & (owner != foot_id) & (owner != 0)
    target = np.asarray(posed["target"], dtype=float)
    yy, xx = np.where(support_mask)
    if len(xx):
        distances = (xx - target[0]) ** 2 + (yy - target[1]) ** 2
        nearest = int(np.argmin(distances))
        nearest_pixel = [int(xx[nearest]), int(yy[nearest])]
        raster_delta = [float(xx[nearest] - target[0]), float(yy[nearest] - target[1])]
    else:
        nearest_pixel, raster_delta = None, None
    nearest_visible = bool(nearest_pixel and owner[nearest_pixel[1], nearest_pixel[0]] == foot_id)
    occluders, counts = np.unique(owner[covered], return_counts=True)
    occlusion = {str(int(k)): int(v) for k, v in zip(occluders, counts)}
    part_reports = {}
    for name in DRAW_ORDER:
        code = _owner_id(name)
        ys, xs = np.where(owner == code)
        part_reports[name] = {"visible_pixels": int(len(xs)),
                              "bbox": ([int(xs.min()), int(ys.min()), int(xs.max()) + 1,
                                        int(ys.max()) + 1] if len(xs) else None)}
    details = {"pixel_owner_ids": {"static_upper_body_residual": 1,
                                   **{name: _owner_id(name) for name in DRAW_ORDER}},
               "visible_part_reports": part_reports,
               "limb_linkage": links,
               "support_raster": {"side": support, "target": target.tolist(),
                                  "nearest_source_foot_pixel": nearest_pixel,
                                  "nearest_pixel_delta": raster_delta,
                                  "nearest_pixel_visible": nearest_visible,
                                  "visible_support_pixels": int(visible.sum()),
                                  "occluded_support_pixels": int(covered.sum()),
                                  "occluded_by_owner_id": occlusion,
                                  "geometric_toe_residual": posed["contact_geometry_residual"]},
               "robe_stride": float(stride), "palette_colors": len(colors),
               "alpha_values": sorted(int(v) for v in np.unique(canvas[:, :, 3])),
               "ownerless_opaque_pixels": int(np.count_nonzero((canvas[:, :, 3] > 0) & (owner == 0))),
               "knight_source_pixels": 0}
    for side in SIDES:
        if links[side]["visible_boot_pixels"] and not links[side]["boot_connected_to_shin"]:
            raise ValueError(f"visible {side} boot is disconnected from its shin after composition")
    if details["ownerless_opaque_pixels"]:
        raise ValueError("opaque output pixels lack semantic source ownership")
    if nearest_pixel is None:
        raise ValueError(f"{support} support foot raster is empty after transformation")
    if nearest_visible and (abs(raster_delta[0]) > 2 or abs(raster_delta[1]) > 1):
        raise ValueError("visible support sole raster exceeds the 2px/1px target tolerance")
    return canvas, owner, details
