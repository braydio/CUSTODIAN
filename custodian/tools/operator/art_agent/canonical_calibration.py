"""Calibration evidence for the provisional operator_2_5d_128 profile.

Everything here is evidence for a human decision; nothing is accepted or frozen by this module:

* technical registration overlay (root/floor candidates are shown, not chosen)
* deterministic scale A/B in the same 128 canvas and root model
* action body-envelope projection from the current runtime art
* pixel cleanup certification (zero-change receipt or a non-applied proposal)
"""
from __future__ import annotations

import json
import statistics
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw

from . import canonical_contract as cc

SCALE_DIR = cc.REFERENCE_DIR / "scale_candidates"
SCALE_DIRNAMES = {"A": "scale_a_0200", "B": "scale_b_0225"}
RUNTIME_MANIFEST = cc.CUSTODIAN / "content/sprites/operator/runtime/operator_runtime_manifest.generated.json"
PREVIOUS_RUNTIME_CANDIDATE_HEIGHT = (84, 88)   # previously reviewed runtime candidate body height (px)
BODY_LAYERS = ("full_body", "lower_body", "upper_body")
PRESENTATION_LAYERS = ("weapon", "fx", "cape")
ENVELOPE_CLASSES = {
    "deepest_dodge_crouch": ["shared/transition/dodge_01", "shared/attack/dodge_charge_windup_01",
                             "shared/transition/dodge_chain_link_01", "unarmed/attack/dodge_fast_attack_01"],
    "fast_chain_body_extension": ["unarmed/attack/fast_01", "unarmed/attack/fast_02", "unarmed/attack/fast_03",
                                  "unarmed/attack/fast_04", "unarmed/attack/fast_strike_01", "unarmed/attack/fast_windup_01",
                                  "unarmed/attack/fast_recovery_01"],
    "block_hit_reaction": ["unarmed/defense/block_hit_01", "melee_1h/defense/block_hit_01", "unarmed/defense/parry_01",
                           "melee_1h_heavy/defense/block_enter_01", "melee_1h_heavy/defense/block_hold_01",
                           "melee_1h_heavy/defense/block_exit_01"],
    "raised_overhead_melee": ["melee_1h_heavy/attack/heavy_01", "melee_1h_heavy/attack/heavy_windup_01", "unarmed/attack/heavy_01"],
    "longest_1h_body_reach": ["melee_1h/attack/fast_01", "melee_1h/attack/fast_02", "melee_1h/attack/fast_03",
                              "melee_1h_heavy/attack/fast_01", "melee_1h_heavy/attack/fast_02", "melee_1h_heavy/attack/fast_03"],
    "ranged_aim": ["ranged_2h/cosmetic/aim_01", "ranged_2h/cosmetic/fire_01", "ranged_2h/cosmetic/fire_walk_01",
                   "ranged_2h/cosmetic/reload_01"],
    "large_hit_react": ["unarmed/reaction/light_hitreact_01", "unarmed/locomotion/idle_hitreact_01",
                        "unarmed/reaction/bodyslam_knockdown_01"],
    "downed_death_extent": ["unarmed/reaction/death_01", "unarmed/reaction/bodyslam_knockdown_01"],
}
NEUTRAL_REFERENCE_ACTION = "unarmed/locomotion/idle_01"


def _tuple_hash(files: dict[str, Path]) -> str:
    return cc.sha256_bytes(cc.canonical_json({d: cc.sha256_file(p) for d, p in files.items()}).encode())


# ------------------------------------------------------------------ scale candidates
def build_scale_candidates(cells, annotations) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, pair in cc.SCALE_CANDIDATES.items():
        folder = SCALE_DIR / SCALE_DIRNAMES[key]
        folder.mkdir(parents=True, exist_ok=True)
        images, files, rows = {}, {}, {}
        for direction, cell in zip(cc.DIRECTIONS, cells):
            points = cc.refine_source_landmarks(cell, annotations["directions"][direction])
            normalized = cc.normalize_direction(cell, points, pair)   # raises if the body would clip the 128 frame
            image = normalized["image"]
            path = folder / f"{direction}.png"
            image.save(path, optimize=False)
            images[direction], files[direction] = image, path
            geometry = cc.silhouette_metrics(image)
            norm_points = normalized["points"]
            rows[direction] = {
                "png": cc.rel(path), "sha256": cc.sha256_file(path), "offset_xy": normalized["offset"],
                "apparent_height": geometry["apparent_height"], "apparent_width": geometry["apparent_width"],
                "alpha_bbox": geometry["alpha_bbox"], "margins": geometry["margins"],
                "head_hip_px": cc.anatomy_metrics(norm_points, geometry)["head_hip_px"],
                "toe_near_y": norm_points["toe_near"]["y"], "toe_far_y": norm_points["toe_far"]["y"],
            }
        heights = [r["apparent_height"] for r in rows.values()]
        low, high = PREVIOUS_RUNTIME_CANDIDATE_HEIGHT
        result[key] = {
            "scale": f"{pair[0]}/{pair[1]}", "scale_value": pair[0] / pair[1],
            "reduced_cell_px": int(round(cc.SOURCE_CELL * pair[0] / pair[1])),
            "directions": rows, "images": images, "files": files,
            "directions_sha256": _tuple_hash(files),
            "height_px": {"min": min(heights), "max": max(heights), "median": float(statistics.median(heights))},
            "within_previous_runtime_candidate_range": bool(low <= statistics.median(heights) <= high),
            "min_margin_px": min(min(r["margins"].values()) for r in rows.values()),
            "clips": False,
        }
    return result


def render_scale_ab(candidates: dict[str, Any], *, zoom: int = 3) -> Image.Image:
    cell = cc.FRAME * zoom
    label = 16
    sheet = cc._checker((cell * len(cc.DIRECTIONS), (cell + label) * 3))
    draw = ImageDraw.Draw(sheet)
    rows = (("A  scale 0.200", candidates["A"]["images"]), ("B  scale 0.225", candidates["B"]["images"]), ("A outline over B", None))
    for row, (title, images) in enumerate(rows):
        top = row * (cell + label)
        draw.text((4, top + 2), title, fill=(255, 255, 255, 255))
        for index, d in enumerate(cc.DIRECTIONS):
            ox = index * cell
            if images is not None:
                layer = images[d].resize((cell, cell), Image.Resampling.NEAREST)
            else:
                layer = candidates["B"]["images"][d].resize((cell, cell), Image.Resampling.NEAREST)
            sheet.alpha_composite(layer, (ox, top + label))
            if images is None:
                mask = np.array(candidates["A"]["images"][d].getchannel("A")) >= cc.ALPHA_CUTOFF
                edge = cc._perimeter(mask)
                for y, x in zip(*np.where(edge)):
                    draw.rectangle((ox + x * zoom, top + label + y * zoom, ox + x * zoom + zoom - 1, top + label + y * zoom + zoom - 1),
                                   outline=(80, 220, 255, 255))
            draw.line((ox + cc.CENTER_X * zoom, top + label, ox + cc.CENTER_X * zoom, top + label + cell), fill=(80, 190, 255, 255))
            draw.line((ox, top + label + cc.SUPPORT_ROW * zoom, ox + cell, top + label + cc.SUPPORT_ROW * zoom), fill=(72, 235, 190, 255))
            draw.text((ox + cell - 24, top + 2), d.upper(), fill=(255, 255, 255, 255))
    return sheet


# ------------------------------------------------------------------ registration overlay
def render_registration_overlay(reference: dict[str, Any], images: dict[str, Image.Image], *, zoom: int = 4) -> Image.Image:
    cell = cc.FRAME * zoom
    cols, rows, head, foot = 4, 2, 22, 40
    sheet = cc._checker((cell * cols, (cell + head) * rows + foot))
    draw = ImageDraw.Draw(sheet)
    legend = ("cell bounds | x=64 | LEFT/RIGHT foot contacts | hip center | projected_world_root CANDIDATE (diamond) | "
              "shadow_origin CANDIDATE (ring) | rails: 106/107/108 candidate, 111 current support baseline, 112 current ground rail | "
              f"alpha bbox | shared scale {cc.SCALE_NUM}/{cc.SCALE_DEN} (candidate A)")
    draw.text((4, (cell + head) * rows + 4), legend, fill=(255, 255, 255, 255))
    draw.text((4, (cell + head) * rows + 20), "PROVISIONAL: no root row is chosen here; the human picks root/floor.", fill=(255, 205, 70, 255))
    rails = {106: (255, 205, 70, 255), 107: (255, 150, 60, 255), 108: (255, 110, 160, 255), 111: (72, 235, 190, 255), 112: (120, 255, 120, 255)}
    for index, d in enumerate(cc.DIRECTIONS):
        col, row = index % cols, index // cols
        ox, oy = col * cell, row * (cell + head) + head
        sheet.alpha_composite(images[d].resize((cell, cell), Image.Resampling.NEAREST), (ox, oy))
        draw.rectangle((ox, oy, ox + cell - 1, oy + cell - 1), outline=(200, 200, 200, 255))
        draw.line((ox + cc.CENTER_X * zoom, oy, ox + cc.CENTER_X * zoom, oy + cell), fill=(80, 190, 255, 255))
        for y, color in rails.items():
            for x in range(0, cell, 12):
                draw.line((ox + x, oy + y * zoom, ox + x + 6, oy + y * zoom), fill=color)
            draw.text((ox + cell - 22, oy + y * zoom - 10), str(y), fill=color)
        entry = reference["directions"][d]
        bbox = entry["geometry"]["alpha_bbox"]
        draw.rectangle((ox + bbox[0] * zoom, oy + bbox[1] * zoom, ox + bbox[2] * zoom - 1, oy + bbox[3] * zoom - 1), outline=(255, 255, 255, 160))
        model = entry["root_model"]

        def at(p):
            return ox + p["x"] * zoom, oy + p["y"] * zoom

        for tag, key, color in (("L", "left_foot_contact", (255, 90, 100, 255)), ("R", "right_foot_contact", (90, 160, 255, 255))):
            x, y = at(model[key])
            draw.ellipse((x - 4, y - 4, x + 4, y + 4), outline=color, width=2)
            draw.text((x + 6, y - 6), tag, fill=color)
        hx, hy = at(model["hip_center"])
        draw.line((hx - 5, hy, hx + 5, hy), fill=(255, 225, 95, 255)); draw.line((hx, hy - 5, hx, hy + 5), fill=(255, 225, 95, 255))
        rx, ry = at(model["projected_world_root"])
        draw.polygon([(rx, ry - 6), (rx + 6, ry), (rx, ry + 6), (rx - 6, ry)], outline=(255, 255, 255, 255))
        sx, sy = at(model["shadow_origin"])
        draw.ellipse((sx - 9, sy - 3, sx + 9, sy + 3), outline=(200, 160, 255, 255))
        draw.text((ox + 4, oy + 2), f"{d.upper()}  feet {model['left_foot_contact']['y']:.1f}/{model['right_foot_contact']['y']:.1f}  mid {model['foot_contact_midpoint']['y']}  "
                  f"bbox {bbox[2] - bbox[0]}x{bbox[3] - bbox[1]}", fill=(255, 255, 255, 255))
    return sheet


# ------------------------------------------------------------------ pixel cleanup certification
def _topology(image: Image.Image) -> list[int]:
    return cc._components(cc._alpha_mask(image))


def propose_cleanup(image: Image.Image) -> dict[str, Any]:
    """Non-destructive: report what a cleanup WOULD change. Never applied to the references."""
    data = np.array(image.convert("RGBA"))
    mask = data[..., 3] >= cc.ALPHA_CUTOFF
    lab = cc.srgb_to_oklab(data[..., :3])
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    hue = (np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) + 360.0) % 360.0
    contaminant = mask & (chroma > 0.05) & ~((hue >= cc.FAMILY_HUE[0]) & (hue <= cc.FAMILY_HUE[1]))
    fringe = (data[..., 3] > 0) & (data[..., 3] < 255)
    islands = np.zeros_like(mask)
    small = [pt for pt in zip(*np.where(mask))]
    labels: dict[tuple[int, int], int] = {}
    # label 8-connected components to locate detached 1-2 px islands
    seen = np.zeros_like(mask)
    from collections import deque
    for start in small:
        if seen[start]:
            continue
        queue, cells = deque([start]), []
        seen[start] = True
        while queue:
            y, x = queue.popleft(); cells.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True; queue.append((ny, nx))
        if len(cells) <= 2:
            for cell in cells:
                islands[cell] = True
    cleaned = data.copy()
    changed: list[dict[str, Any]] = []
    for y, x in zip(*np.where(contaminant)):
        window = data[max(0, y - 1):y + 2, max(0, x - 1):x + 2]
        wmask = (window[..., 3] >= cc.ALPHA_CUTOFF) & ~contaminant[max(0, y - 1):y + 2, max(0, x - 1):x + 2]
        if wmask.any():
            color = np.median(window[..., :3][wmask], axis=0).astype(np.uint8)
            cleaned[y, x, :3] = color
            changed.append({"x": int(x), "y": int(y), "kind": "contaminant_recolor", "before": data[y, x].tolist(), "after": cleaned[y, x].tolist()})
    for y, x in zip(*np.where(islands)):
        cleaned[y, x] = (0, 0, 0, 0)
        changed.append({"x": int(x), "y": int(y), "kind": "island_removed", "before": data[y, x].tolist(), "after": [0, 0, 0, 0]})
    after = Image.fromarray(cleaned, "RGBA")
    return {"cleaned": after, "changed": changed,
            "counts": {"contaminant_pixels": int(contaminant.sum()), "detached_islands_1_2px": int(islands.sum()),
                       "semitransparent_fringe_pixels": int(fringe.sum())}}


def certify_cleanup(candidates: dict[str, Any]) -> dict[str, Any]:
    receipt: dict[str, Any] = {
        "schema": "custodian.operator_2_5d_cleanup_certification.v1",
        "checks": ["outlier hue contaminants", "detached 1-2 px islands", "semitransparent fringe after crisp normalization",
                   "alpha-mask equality", "component-topology equality"],
        "family_hue_deg": list(cc.FAMILY_HUE),
        "contaminant_review": "Pixels flagged by the earlier narrower 30-100 deg gold band (6 px across ne,e,sw,w,nw at hue 101-104 deg, "
                              "bright yellow specular highlights) were inspected: they are in-family gold speculars, so the family band is "
                              "now 25-110 deg. No colour was edited.",
        "trivial_change_rule": "pause for human review if any alpha-mask/topology change, or > 3 changed pixels in a direction",
        "candidates": {}, "applied": False,
    }
    for key, candidate in candidates.items():
        per_direction, status = {}, "zero_change"
        for d in cc.DIRECTIONS:
            image = candidate["images"][d]
            proposal = propose_cleanup(image)
            after = proposal["cleaned"]
            before_sha = cc.sha256_bytes(image.convert("RGBA").tobytes())
            after_sha = cc.sha256_bytes(after.tobytes())
            alpha_equal = bool(np.array_equal(np.array(image.getchannel("A")), np.array(after.getchannel("A"))))
            topology_equal = _topology(image) == _topology(after)
            changed = proposal["changed"]
            pause = bool((not alpha_equal) or (not topology_equal) or len(changed) > 3)
            entry = {"before_rgba_sha256": before_sha, "after_rgba_sha256": after_sha, "file_sha256": candidate["directions"][d]["sha256"],
                     "changed_pixels": changed, "alpha_mask_equal": alpha_equal, "component_topology_equal": topology_equal,
                     **proposal["counts"], "pause_required": pause,
                     "status": "zero_change" if not changed else ("pause_for_human_review" if pause else "trivial_change_proposed_not_applied")}
            if changed:
                status = "pause_for_human_review" if pause or status == "pause_for_human_review" else "trivial_change_proposed_not_applied"
                marked = image.convert("RGBA").resize((cc.FRAME * 4, cc.FRAME * 4), Image.Resampling.NEAREST)
                mdraw = ImageDraw.Draw(marked)
                for item in changed:
                    mdraw.rectangle((item["x"] * 4 - 2, item["y"] * 4 - 2, item["x"] * 4 + 5, item["y"] * 4 + 5), outline=(255, 0, 255, 255))
                diff_path = cc.REPORT_DIR / f"cleanup_diff_{key.lower()}_{d}.png"
                marked.save(diff_path)
                entry["marked_diff"] = cc.rel(diff_path)
            per_direction[d] = entry
        receipt["candidates"][key] = {
            "scale": candidate["scale"], "directions_sha256": candidate["directions_sha256"], "status": status,
            "total_changed_pixels": sum(len(v["changed_pixels"]) for v in per_direction.values()),
            "directions": per_direction}
    receipt["status"] = ("zero_change" if all(c["status"] == "zero_change" for c in receipt["candidates"].values())
                         else "pause_for_human_review")
    receipt["final_normalized_hash"] = "pending: certified per candidate above; the final hash is set only after the human chooses the scale and root"
    return receipt


# ------------------------------------------------------------------ action envelope
def _layer_tiles(path: Path, frames: int, frame_size: list[int]) -> list[np.ndarray]:
    fw, fh = frame_size
    with Image.open(path) as sheet:
        data = np.array(sheet.convert("RGBA"))[..., 3] > 0
    if data.shape[0] % fh or data.shape[1] % fw:
        raise ValueError(f"sheet {path.name} is not an exact grid of {fw}x{fh}")
    columns = data.shape[1] // fw
    tiles = []
    for index in range(frames):
        row, col = divmod(index, columns)
        tiles.append(data[row * fh:(row + 1) * fh, col * fw:(col + 1) * fw])
    return tiles


def _box(tile: np.ndarray) -> list[int] | None:
    ys, xs = np.where(tile)
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1] if ys.size else None


def _union(boxes: list[list[int] | None]) -> list[int] | None:
    live = [b for b in boxes if b]
    if not live:
        return None
    return [min(b[0] for b in live), min(b[1] for b in live), max(b[2] for b in live), max(b[3] for b in live)]


FEET_BAND = 12


def measure_runtime_action(manifest_entry: dict[str, Any]) -> dict[str, Any] | None:
    """Body extents about a per-sheet root anchor (median feet-band x centre, median body bottom row).

    Deriving the anchor per sheet avoids assuming that wide 128/156 frames are centred on the body.
    """
    layers = manifest_entry["layers"]
    # Prefer the split body modules (they exclude the held weapon); full_body can have the weapon baked in
    # (e.g. melee_1h attack sheets), which would overstate body reach.
    split = [n for n in ("lower_body", "upper_body") if n in layers]
    body_names = split if len(split) == 2 else (["full_body"] if "full_body" in layers else split)
    if not body_names:
        return None
    first = layers[body_names[0]]
    fw, fh = first["frame_size"]
    frames = int(first["frames"])
    loaded: dict[str, list[np.ndarray]] = {}
    for name in body_names + [n for n in PRESENTATION_LAYERS if n in layers]:
        meta = layers[name]
        path = cc.CUSTODIAN / meta["path"].replace("res://", "")
        if not path.is_file() or path.stat().st_size < 200:
            return {"error": f"layer art unavailable: {name}"}
        loaded[name] = _layer_tiles(path, int(meta["frames"]), meta["frame_size"])
    body_tiles = []
    for index in range(frames):
        tile = np.zeros((fh, fw), dtype=bool)
        for name in body_names:
            if index < len(loaded[name]) and loaded[name][index].shape == tile.shape:
                tile |= loaded[name][index]
        body_tiles.append(tile)
    body_boxes = [_box(t) for t in body_tiles]
    feet_x, bottoms = [], []
    for tile, box in zip(body_tiles, body_boxes):
        if box is None:
            continue
        band = tile[max(box[1], box[3] - FEET_BAND):box[3]]
        xs = np.where(band.any(axis=0))[0]
        feet_x.append((xs.min() + xs.max() + 1) / 2.0)
        bottoms.append(box[3] - 1)
    if not feet_x:
        return None
    anchor = [float(statistics.median(feet_x)), float(statistics.median(bottoms))]
    pres_boxes = [_box(t) for n in PRESENTATION_LAYERS if n in loaded for t in loaded[n]]
    return {"frame_size": [fw, fh], "frames": frames, "body_layers": body_names, "anchor_xy": anchor,
            "anchor_basis": f"median feet-band ({FEET_BAND} rows) x centre and median body bottom row across frames",
            "body_union": _union(body_boxes), "presentation_union": _union(pres_boxes),
            "presentation_layers": [n for n in PRESENTATION_LAYERS if n in loaded]}


def _extents(box: list[int] | None, anchor: list[float]) -> dict[str, float] | None:
    if box is None:
        return None
    return {"up": round(anchor[1] - box[1], 1), "down": round(box[3] - 1 - anchor[1], 1),
            "left": round(anchor[0] - box[0], 1), "right": round(box[2] - anchor[0], 1)}


def build_envelope(candidates: dict[str, Any]) -> dict[str, Any]:
    manifest = json.loads(RUNTIME_MANIFEST.read_text(encoding="utf-8"))["animations"]
    neutral = []
    for key, entry in manifest.items():
        if key.startswith(NEUTRAL_REFERENCE_ACTION + "/"):
            measured = measure_runtime_action(entry)
            if measured and "error" not in measured:
                box = measured["body_union"]
                neutral.append(box[3] - box[1])
    if not neutral:
        raise ValueError("legacy neutral body height is unavailable; runtime art is not materialized")
    legacy_height = float(statistics.median(neutral))
    projection = {}
    for key, c in candidates.items():
        projection[key] = {"canonical_body_height_px": c["height_px"]["median"], "legacy_neutral_body_height_px": legacy_height,
                           "factor": c["height_px"]["median"] / legacy_height}
    classes: dict[str, Any] = {}
    for name, actions in ENVELOPE_CLASSES.items():
        records, missing = [], []
        for action in actions:
            keys = [k for k in manifest if k.startswith(action + "/")]
            if not keys:
                missing.append(action)
            for key in sorted(keys):
                measured = measure_runtime_action(manifest[key])
                if measured is None or "error" in measured:
                    missing.append(key + (": " + measured["error"] if measured else ": no body layer"))
                    continue
                records.append({"key": key, **measured,
                                "body_extents": _extents(measured["body_union"], measured["anchor_xy"]),
                                "presentation_extents": _extents(measured["presentation_union"], measured["anchor_xy"])})
        worst = {}
        for side in ("up", "down", "left", "right"):
            best = max((r for r in records if r["body_extents"]), key=lambda r: r["body_extents"][side], default=None)
            worst[side] = {"legacy_px": best["body_extents"][side], "key": best["key"]} if best else None
        pres = {}
        for side in ("up", "down", "left", "right"):
            best = max((r for r in records if r["presentation_extents"]), key=lambda r: r["presentation_extents"][side], default=None)
            pres[side] = {"legacy_px": best["presentation_extents"][side], "key": best["key"]} if best else None
        classes[name] = {"sheets_measured": len(records), "missing_or_unavailable": missing, "body_worst": worst,
                         "presentation_worst": pres,
                         "records": records}
    rooms = {}
    for row in (106, 107, 108, cc.SUPPORT_ROW):
        rooms[str(row)] = {"up": row, "down": cc.FRAME - 1 - row, "left": cc.CENTER_X, "right": cc.FRAME - cc.CENTER_X}
    verdicts: dict[str, Any] = {}
    for key, factor in ((k, v["factor"]) for k, v in projection.items()):
        verdicts[key] = {}
        for name, info in classes.items():
            by_row = {}
            for row, room in rooms.items():
                checks = {}
                for side in ("up", "down", "left", "right"):
                    worst = info["body_worst"][side]
                    need = None if worst is None else round(max(0.0, worst["legacy_px"]) * factor, 1)
                    pres_worst = info["presentation_worst"][side]
                    pres_need = None if pres_worst is None else round(max(0.0, pres_worst["legacy_px"]) * factor, 1)
                    checks[side] = {"body_projected_px": need, "room_px": room[side],
                                    "body_fits": None if need is None else bool(need <= room[side]),
                                    "presentation_projected_px": pres_need,
                                    "presentation_fits": None if pres_need is None else bool(pres_need <= room[side])}
                by_row[row] = checks
            verdicts[key][name] = by_row
    status = {}
    for key in verdicts:
        status[key] = {name: ("no_authored_art" if info["sheets_measured"] == 0 else
                              "body_fits_projected" if all(c["body_fits"] in (True, None) for c in verdicts[key][name][str(cc.SUPPORT_ROW)].values())
                              else "body_overflow") for name, info in classes.items()}
    return {
        "schema": "custodian.operator_2_5d_action_envelope_projection.v1",
        "status": "projected_feasibility_evidence_only; universal 128 envelope is NOT proven until canonical frames are authored",
        "method": ("Measure body-layer alpha extents of the current 96-based runtime art about a per-sheet root anchor (feet band), "
                   "scale by canonical/legacy neutral body height, compare to the 128 canvas room below each candidate root row. "
                   "The body is never shrunk to fit; weapon/fx/cape layers are reported separately as presentation overflow."),
        "projection": projection, "canvas_room_by_root_row": rooms, "classes": classes, "verdicts": verdicts, "class_status": status,
        "anchor_basis": "per sheet: median feet-band x centre and median body bottom row (no frame-centre assumption)",
    }


def render_envelope(envelope: dict[str, Any], *, zoom: int = 3) -> Image.Image:
    cell = cc.FRAME * zoom
    sheet = cc._checker((cell * 2 + 8, cell + 20))
    draw = ImageDraw.Draw(sheet)
    palette = [(255, 90, 100), (90, 160, 255), (255, 205, 70), (120, 255, 160), (200, 160, 255), (255, 150, 60), (80, 220, 255), (255, 110, 200)]
    for col, key in enumerate(("A", "B")):
        ox = col * (cell + 8)
        factor = envelope["projection"][key]["factor"]
        draw.text((ox + 4, 4), f"candidate {key}: projected body extents (factor {factor:.3f}) about [64,{cc.SUPPORT_ROW}]", fill=(255, 255, 255, 255))
        draw.rectangle((ox, 20, ox + cell - 1, 20 + cell - 1), outline=(220, 220, 220, 255))
        draw.line((ox + cc.CENTER_X * zoom, 20, ox + cc.CENTER_X * zoom, 20 + cell), fill=(80, 190, 255, 255))
        draw.line((ox, 20 + cc.SUPPORT_ROW * zoom, ox + cell, 20 + cc.SUPPORT_ROW * zoom), fill=(72, 235, 190, 255))
        for index, (name, info) in enumerate(envelope["classes"].items()):
            worst = info["body_worst"]
            if any(worst[s] is None for s in worst):
                continue
            x0, x1 = cc.CENTER_X - worst["left"]["legacy_px"] * factor, cc.CENTER_X + worst["right"]["legacy_px"] * factor
            y0, y1 = cc.SUPPORT_ROW - worst["up"]["legacy_px"] * factor, cc.SUPPORT_ROW + worst["down"]["legacy_px"] * factor
            draw.rectangle((ox + x0 * zoom, 20 + y0 * zoom, ox + x1 * zoom, 20 + y1 * zoom), outline=palette[index % len(palette)] + (255,))
            draw.text((ox + 4, 20 + 4 + index * 11), name, fill=palette[index % len(palette)] + (255,))
    return sheet


# ------------------------------------------------------------------ orchestration
def _md_calibration(candidates, cleanup, envelope, reference) -> str:
    rows = []
    for key in ("A", "B"):
        c = candidates[key]
        rows.append(f"| {key} | {c['scale']} ({c['scale_value']:.4f}) | {c['height_px']['min']}-{c['height_px']['max']} (median {c['height_px']['median']}) | "
                    f"{c['within_previous_runtime_candidate_range']} | {c['min_margin_px']} | `{c['directions_sha256'][:16]}` |")
    env_rows = []
    for name, info in envelope["classes"].items():
        over = {k: [side for side, c in envelope["verdicts"][k][name][str(cc.SUPPORT_ROW)].items() if c["presentation_fits"] is False]
                for k in ("A", "B")}
        env_rows.append(f"| {name} | {info['sheets_measured']} | A: {envelope['class_status']['A'][name]} / B: {envelope['class_status']['B'][name]} | "
                        f"A: {', '.join(over['A']) or 'fits'} / B: {', '.join(over['B']) or 'fits'} |")
    mids = reference["root_model"]["foot_contact_midpoint_y"]
    return f"""
## Calibration evidence (pending human decisions; nothing below is accepted)

### Root / floor
Foot-contact midpoint y per direction: {', '.join(f'{d.upper()} {mids[d]}' for d in cc.DIRECTIONS)}; median {reference['root_model']['median_foot_contact_midpoint_y']}.
y={cc.SUPPORT_ROW} is the lowest support-toe baseline, not a proven projected_world_root; the median midpoint is evidence and does not by itself define root_y.
Each direction persists `hip_center`, `left_foot_contact`, `right_foot_contact`, `projected_world_root` (candidate), `shadow_origin` (candidate) separately (`root_model`).
See `operator_2_5d_registration_overlay.png` (rails 106/107/108 vs the current 111/112).

### Scale A/B (same 128 canvas, same provisional root model, one scale per candidate)
| Cand | Scale | Body height px | In previous runtime range 84-88 | Min margin | Directions hash |
|---|---|---|---|---|---|
{chr(10).join(rows)}

See `operator_2_5d_scale_ab_comparison.png` and `operator_2_5d_scale_ab_summary.json`. The human chooses the canonical body scale.

### 128 action body-envelope (projection from current runtime art; not a proof)
Legacy neutral body height {envelope['projection']['A']['legacy_neutral_body_height_px']} px; factors A {envelope['projection']['A']['factor']:.3f}, B {envelope['projection']['B']['factor']:.3f}.
| Class | Sheets measured | Projected body verdict (root 111) | Weapon/FX/cape sides overflowing 128 |
|---|---|---|---|
{chr(10).join(env_rows)}
Body layers use the split lower/upper modules when present (full_body can have the held weapon baked in). 'Up' includes airborne frames. Weapon/FX/cape overflow is reported separately in `operator_2_5d_action_envelope.json` (`presentation_worst`) and must use its own presentation envelope; the body is never shrunk to fit.

### Pixel cleanup certification
Status: **{cleanup['status']}** (applied: {cleanup['applied']}). {cleanup['contaminant_review']}
Final normalized hash: {cleanup['final_normalized_hash']}.
"""


def build_calibration(reference: dict[str, Any], cells, annotations) -> dict[str, Any]:
    cc.REPORT_DIR.mkdir(parents=True, exist_ok=True)
    primary = {d: cc.load_direction_image(d) for d in cc.DIRECTIONS}
    render_registration_overlay(reference, primary).save(cc.REPORT_DIR / "operator_2_5d_registration_overlay.png")
    candidates = build_scale_candidates(cells, annotations)
    render_scale_ab(candidates).save(cc.REPORT_DIR / "operator_2_5d_scale_ab_comparison.png")
    summary = {"schema": "custodian.operator_2_5d_scale_ab_summary.v1", "status": "pending_human_scale_choice",
               "root_model": "same provisional model for both: hip_center x=64, lowest toe sole on row 111",
               "previous_runtime_candidate_height_px": list(PREVIOUS_RUNTIME_CANDIDATE_HEIGHT),
               "candidates": {k: {kk: vv for kk, vv in v.items() if kk not in ("images", "files")} for k, v in candidates.items()}}
    cc.write_json(cc.REPORT_DIR / "operator_2_5d_scale_ab_summary.json", summary)
    cleanup = certify_cleanup(candidates)
    cc.write_json(cc.REPORT_DIR / "operator_2_5d_cleanup_certification.json", cleanup)
    envelope = build_envelope(candidates)
    cc.write_json(cc.REPORT_DIR / "operator_2_5d_action_envelope.json", envelope)
    render_envelope(envelope).save(cc.REPORT_DIR / "operator_2_5d_action_envelope.png")
    report = cc.REPORT_DIR / "OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_REPORT.md"
    text = report.read_text(encoding="utf-8")
    marker = "\n## Calibration evidence"
    text = text.split(marker)[0].rstrip("\n") + "\n" + _md_calibration(candidates, cleanup, envelope, reference)
    report.write_text(text, encoding="utf-8")
    return {"scale_candidates": summary, "cleanup": cleanup["status"], "envelope": envelope["class_status"]}
