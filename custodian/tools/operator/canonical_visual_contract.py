from __future__ import annotations

import hashlib
import json
import colorsys
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
DIRECTIONS = ("n", "ne", "e", "se", "s", "sw", "w", "nw")
DESIGN_PATH = ROOT / "custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png"
ANIMATION_PATH = ROOT / "custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png"
REFERENCE = ROOT / "custodian/content/sprites/operator/reference/operator_2_5d/operator_2_5d_rotation_lock_128.png"
EVIDENCE = ROOT / "reports/operator_presentation/canonical_visual_contract"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def alpha_metrics(image: Image.Image) -> dict[str, Any]:
    alpha = image.convert("RGBA").getchannel("A")
    bbox = alpha.getbbox()
    values = list(alpha.get_flattened_data())
    return {
        "alpha_bbox": list(bbox) if bbox else None,
        "opaque_pixels": sum(value == 255 for value in values),
        "intermediate_alpha_pixels": sum(0 < value < 255 for value in values),
        "alpha_values": sorted(set(values)),
    }


def connected_components(image: Image.Image) -> int:
    alpha = image.convert("RGBA").getchannel("A")
    pixels = alpha.load()
    width, height = alpha.size
    seen: set[tuple[int, int]] = set()
    components = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == 0 or (x, y) in seen:
                continue
            components += 1
            seen.add((x, y))
            todo = [(x, y)]
            while todo:
                px, py = todo.pop()
                for ny in range(max(0, py - 1), min(height, py + 2)):
                    for nx in range(max(0, px - 1), min(width, px + 2)):
                        if pixels[nx, ny] and (nx, ny) not in seen:
                            seen.add((nx, ny))
                            todo.append((nx, ny))
    return components


def candidate_landmarks(image: Image.Image) -> dict[str, Any]:
    alpha = image.convert("RGBA").getchannel("A")
    bbox = alpha.getbbox()
    supports = []
    for x0, x1 in ((0, 64), (64, 128)):
        pixels = [(x, y) for x in range(x0, x1) for y in range(128) if alpha.getpixel((x, y)) > 0]
        if pixels:
            y = max(py for _, py in pixels)
            xs = [px for px, py in pixels if py == y]
            supports.append([round(sum(xs) / len(xs)), y])
        else:
            supports.append(None)
    hip_y = round(bbox[1] + (bbox[3] - bbox[1]) * 0.60) if bbox else None
    return {
        "projected_world_root_candidate": [64, 106],
        "shadow_origin_candidate": [64, 107],
        "hip_center_heuristic": [64, hip_y] if hip_y is not None else None,
        "left_right_lowest_alpha_candidates": supports,
        "interpretation": "heuristic image coordinates for human calibration only; lowest alpha is not semantic registration evidence",
    }


def build() -> dict[str, Any]:
    design = Image.open(DESIGN_PATH).convert("RGBA")
    animation = Image.open(ANIMATION_PATH).convert("RGBA")
    reference = Image.open(REFERENCE).convert("RGBA")
    assert design.size == (2048, 256) and animation.size == (1920, 1024)
    assert reference.size == (1024, 128)

    source_root = DESIGN_PATH.parent
    cell_dir = source_root / "source_cells"
    cell_dir.mkdir(parents=True, exist_ok=True)
    design_cells = {}
    for index, direction in enumerate(DIRECTIONS):
        cell = design.crop((index * 256, 0, (index + 1) * 256, 256))
        path = cell_dir / f"{direction}_source.png"
        cell.save(path, format="PNG", optimize=False)
        design_cells[direction] = {"path": str(path.relative_to(ROOT)), "sha256": sha256(path), **alpha_metrics(cell)}
    reconstructed = Image.new("RGBA", design.size)
    for index, direction in enumerate(DIRECTIONS):
        reconstructed.paste(Image.open(cell_dir / f"{direction}_source.png").convert("RGBA"), (index * 256, 0))
    assert reconstructed.tobytes() == design.tobytes(), "source cells do not reconstruct the immutable master"

    (source_root / "operator_2_5d_design_reference_manifest.json").write_text(json.dumps({
        "schema": "custodian.operator_source_work_manifest.v1",
        "authority_id": "operator_2_5d_design_reference",
        "source_file": DESIGN_PATH.name,
        "dropbox_path": "/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png",
        "sha256": sha256(DESIGN_PATH), "bytes": DESIGN_PATH.stat().st_size,
        "dimensions": [2048, 256], "mode": "RGBA", "grid": [8, 1], "cell_size": [256, 256],
        "direction_order": list(DIRECTIONS), "provenance": "user_approved_visual_lock",
        "authoring_chat": "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb",
    }, indent=2) + "\n")
    animation_root = ANIMATION_PATH.parent
    (animation_root / "unarmed_posture_idle_relaxed_01_full_body_v1_manifest.json").write_text(json.dumps({
        "schema": "custodian.operator_source_work_manifest.v1",
        "authority_id": "operator_2_5d_unarmed_posture_idle_relaxed_01",
        "source_file": ANIMATION_PATH.name,
        "dropbox_path": "/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png",
        "sha256": sha256(ANIMATION_PATH), "bytes": ANIMATION_PATH.stat().st_size,
        "dimensions": [1920, 1024], "mode": "RGBA", "grid": [15, 8], "cell_size": [128, 128],
        "direction_order": list(DIRECTIONS), "frames_per_direction": 15, "loop": True,
        "fps": None, "timing_note": "No authoritative timing metadata is embedded in the PNG; FPS is unresolved and was not inferred.",
        "provenance": "user_supplied_canonical_animation",
        "authoring_chat": "https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb",
    }, indent=2) + "\n")

    directions_dir = REFERENCE.parent / "directions"
    directions_dir.mkdir(parents=True, exist_ok=True)
    design_ref_metrics = {}
    idle_metrics = {}
    for index, direction in enumerate(DIRECTIONS):
        ref_cell = reference.crop((index * 128, 0, (index + 1) * 128, 128))
        ref_path = directions_dir / f"{direction}.png"
        ref_cell.save(ref_path, format="PNG", optimize=False)
        design_ref_metrics[direction] = {"sha256": sha256(ref_path), **alpha_metrics(ref_cell), "components": connected_components(ref_cell)}
        idle = animation.crop((0, index * 128, 128, (index + 1) * 128))
        idle_metrics[direction] = {"f01_sha256": hashlib.sha256(idle.tobytes()).hexdigest(), **alpha_metrics(idle), "components": connected_components(idle)}

    palette = {}
    for direction in DIRECTIONS:
        cell = reference.crop((DIRECTIONS.index(direction) * 128, 0, (DIRECTIONS.index(direction) + 1) * 128, 128))
        counts = sorted((item for item in (cell.getcolors(128 * 128) or []) if item[1][3]), key=lambda item: (-item[0], item[1]))
        cool_candidates = []
        opaque_luminance = []
        for y in range(128):
            for x in range(128):
                red, green, blue, alpha = cell.getpixel((x, y))
                if not alpha:
                    continue
                hue, saturation, value = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
                opaque_luminance.append(round(0.2126 * red + 0.7152 * green + 0.0722 * blue))
                if 90 <= hue * 360 <= 250 and saturation > 0.18 and max(red, green, blue) > 30:
                    cool_candidates.append({"xy": [x, y], "rgba": [red, green, blue, alpha]})
        opaque_luminance.sort()
        palette[direction] = {
            "unique_opaque_rgba": len(counts),
            "alpha_values": sorted(set(cell.getchannel("A").get_flattened_data())),
            "luminance_p10_p50_p90": [opaque_luminance[int((len(opaque_luminance) - 1) * q)] for q in (0.1, 0.5, 0.9)] if opaque_luminance else [],
            "most_common_rgba": [{"rgba": list(color), "pixels": count} for count, color in counts[:16]],
            "cool_hue_candidates_review_only": cool_candidates,
        }

    profile_doc = json.loads((ROOT / "custodian/content/data/operator/authoring/operator_art_profile.json").read_text())
    profile_128 = profile_doc["profiles"]["operator_2_5d_128"]

    report = {
        "schema": "custodian.operator_2_5d_visual_contract_measurements.v1",
        "sources": {
            "design": {"path": str(DESIGN_PATH.relative_to(ROOT)), "sha256": sha256(DESIGN_PATH), "bytes": DESIGN_PATH.stat().st_size, "size": list(design.size), "mode": "RGBA", "directions": list(DIRECTIONS), "cells": design_cells},
            "first_animation": {"path": str(ANIMATION_PATH.relative_to(ROOT)), "sha256": sha256(ANIMATION_PATH), "bytes": ANIMATION_PATH.stat().st_size, "size": list(animation.size), "mode": "RGBA", "cell_size": [128, 128], "columns": 15, "rows": 8, "frames_per_direction": 15, "direction_order": list(DIRECTIONS), "loop": True, "fps": None, "timing_note": "No authoritative FPS/timing metadata is embedded in the supplied PNG; not inferred."},
        },
        "normalized_reference": {"path": str(REFERENCE.relative_to(ROOT)), "sha256": sha256(REFERENCE), "size": list(reference.size), "method": "pixelart alias --choose 1, shared sheet scale, center anchor, nearest preparation", "directions": design_ref_metrics},
        "profile": {"id": "operator_2_5d_128", "status": profile_128["status"], "sha256": profile_128["profile_sha256"]},
        "first_animation_f01": idle_metrics,
        "calibration_candidates": {direction: candidate_landmarks(animation.crop((0, index * 128, 128, (index + 1) * 128))) for index, direction in enumerate(DIRECTIONS)},
        "palette": {"method": "compact per-direction RGBA/luminance summary; HSV 90..250 degree pixels are review candidates, not automatic cleanup targets", "directions": palette, "cleanup_applied": False},
        "registration": {"status": "provisional", "frame_size": [128, 128], "center_x": 64, "candidate_anchor": [64, 106], "candidate_ground_y": 107, "semantic_landmarks": ["hip_center", "left_foot_contact", "right_foot_contact", "projected_world_root", "shadow_origin"], "accepted_by_human": False},
        "action_envelope": {"status": "not_proven", "required_pose_classes": ["deep_dodge_or_crouch", "fast_chain_extension", "wide_block_reaction", "overhead_melee", "long_1h_reach", "ranged_aim", "hit_reaction_recoil", "downed_or_death"]},
        "pixel_cleanup": {"status": "pending_human_review", "normalized_reference_mutated": False},
    }
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    (EVIDENCE / "operator_2_5d_measurement_summary.json").write_text(json.dumps(report, indent=2) + "\n")
    (EVIDENCE / "operator_2_5d_palette_summary.json").write_text(json.dumps(report["palette"], indent=2) + "\n")
    overlay = Image.new("RGBA", (512, 386), (28, 29, 34, 255))
    draw = ImageDraw.Draw(overlay)
    for index, direction in enumerate(DIRECTIONS):
        col, row = index % 4, index // 4
        x0, y0 = col * 128, row * 176 + 18
        tile = animation.crop((0, index * 128, 128, (index + 1) * 128))
        overlay.alpha_composite(tile, (x0, y0))
        color = (90, 220, 255, 220)
        draw.rectangle((x0, y0, x0 + 127, y0 + 127), outline=(150, 150, 150, 210), width=1)
        draw.line((x0 + 64, y0, x0 + 64, y0 + 127), fill=color, width=1)
        draw.line((x0, y0 + 106, x0 + 127, y0 + 106), fill=(255, 220, 80, 210), width=1)
        draw.line((x0, y0 + 107, x0 + 127, y0 + 107), fill=(255, 120, 90, 210), width=1)
        bbox = idle_metrics[direction]["alpha_bbox"]
        if bbox:
            draw.rectangle((x0 + bbox[0], y0 + bbox[1], x0 + bbox[2] - 1, y0 + bbox[3] - 1), outline=(80, 255, 130, 220), width=1)
            # These points are explicitly candidate visual landmarks; final semantic
            # interpretation belongs to the human calibration review.
            draw.ellipse((x0 + 61, y0 + bbox[1] + int((bbox[3] - bbox[1]) * 0.60) - 2,
                          x0 + 67, y0 + bbox[1] + int((bbox[3] - bbox[1]) * 0.60) + 2), outline=(255, 80, 240, 255), width=1)
        tile_alpha = tile.getchannel("A")
        for side_x in (range(0, 64), range(64, 128)):
            candidates = [(x, y) for x in side_x for y in range(128) if tile_alpha.getpixel((x, y)) > 0]
            if candidates:
                lowest_y = max(y for _, y in candidates)
                xs = [x for x, y in candidates if y == lowest_y]
                cx = round(sum(xs) / len(xs))
                draw.ellipse((x0 + cx - 2, y0 + lowest_y - 2, x0 + cx + 2, y0 + lowest_y + 2), outline=(255, 80, 80, 255), width=1)
        draw.line((x0 + 60, y0 + 106, x0 + 68, y0 + 106), fill=(255, 255, 255, 255), width=1)
        draw.line((x0 + 64, y0 + 102, x0 + 64, y0 + 110), fill=(255, 255, 255, 255), width=1)
        draw.rectangle((x0 + 62, y0 + 105, x0 + 66, y0 + 109), outline=(80, 220, 255, 255), width=1)
        draw.text((x0 + 4, y0 - 14), direction.upper(), fill=(255, 255, 255, 255), font=ImageFont.load_default())
        draw.text((x0 + 4, y0 + 130), "root106? ground107?", fill=(255, 255, 255, 255), font=ImageFont.load_default())
    draw.text((4, 358), "F01 source, unchanged scale per direction. Markers are candidates, not accepted semantics:", fill=(255, 255, 255, 255), font=ImageFont.load_default())
    draw.text((4, 370), "green bbox; cyan x64; white root; gold y106; coral y107; blue shadow; red support; magenta estimated hip.", fill=(255, 255, 255, 255), font=ImageFont.load_default())
    overlay_path = EVIDENCE / "operator_2_5d_landmark_overlay.png"
    overlay.save(overlay_path)
    turnaround = Image.new("RGBA", (1024, 150), (28, 29, 34, 255))
    tdraw = ImageDraw.Draw(turnaround)
    for index, direction in enumerate(DIRECTIONS):
        x0 = index * 128
        turnaround.alpha_composite(reference.crop((x0, 0, x0 + 128, 128)), (x0, 12))
        tdraw.rectangle((x0, 12, x0 + 127, 139), outline=(120, 120, 120, 255))
        tdraw.line((x0 + 64, 12, x0 + 64, 139), fill=(60, 190, 230, 170))
        tdraw.line((x0, 118, x0 + 127, 118), fill=(220, 190, 80, 170))
        tdraw.text((x0 + 4, 1), direction.upper(), fill=(255, 255, 255, 255), font=ImageFont.load_default())
    turnaround.save(EVIDENCE / "operator_2_5d_reference_turnaround.png")
    (EVIDENCE / "OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_REPORT.md").write_text(
        "# Operator 2.5D canonical visual contract evidence\n\n"
        f"Design source SHA-256: `{report['sources']['design']['sha256']}`.\n\n"
        f"First animation source SHA-256: `{report['sources']['first_animation']['sha256']}`.\n\n"
        f"Normalized reference SHA-256: `{report['normalized_reference']['sha256']}`.\n\n"
        f"Provisional 128px profile SHA-256: `{report['profile']['sha256']}`.\n\n"
        "The design-derived 128px reference uses one sheet-wide crisp scale and is measurement evidence only. "
        "Root/floor remains provisional: the candidate guide is x=64, root y=106, ground y=107. "
        "The supplied PNG has no authoritative timing metadata, so FPS is unresolved. Universal action envelope and pixel cleanup review remain open.\n"
    )
    return report


if __name__ == "__main__":
    print(json.dumps(build(), indent=2))
