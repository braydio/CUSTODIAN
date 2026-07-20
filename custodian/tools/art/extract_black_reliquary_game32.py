#!/usr/bin/env python3
"""
extract_ui_black_reliquary_game32.py

Extracts the generated CUSTODIAN gothic/brass UI component sheet into runtime
UI domains with detailed game32 metadata.

Input image reference size: 1448x1086.

Outputs:
  custodian/content/masters/ui/ui_black_reliquary_components.png
  custodian/content/ui/black_reliquary/panels/
  custodian/content/ui/black_reliquary/panels/pieces/
  custodian/content/ui/black_reliquary/dividers/
  custodian/content/ui/black_reliquary/ornaments/
  custodian/content/ui/black_reliquary/icons/
  custodian/content/ui/black_reliquary/prompts/
  custodian/content/ui/black_reliquary/minimap/
  custodian/content/ui/black_reliquary/_manifest.game32.json
  custodian/content/metadata/game32/ui_black_reliquary.game32.json
"""

from __future__ import annotations

import argparse
import json
import shutil
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

REFERENCE_SIZE = (1448, 1086)


@dataclass(frozen=True)
class UISpec:
    asset_id: str
    domain: str
    crop: tuple[int, int, int, int]
    out_subdir: str
    ui_role: str
    godot_node_hint: str
    ninepatch_group: str | None = None
    ninepatch_slot: str | None = None
    tags: list[str] = field(default_factory=list)
    notes: str = ""


SPECS: list[UISpec] = [
    # ---------------------------------------------------------------------
    # SHEET 1 — PANEL 9-SLICE PIECES: DARK GOLD
    # ---------------------------------------------------------------------
    UISpec("ui_panel_9slice_dark_gold_piece_tl", "panel_piece", (38, 96, 113, 176), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "tl", ["panel", "dark_gold", "corner"]),
    UISpec("ui_panel_9slice_dark_gold_piece_t",  "panel_piece", (119, 96, 264, 176), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "t",  ["panel", "dark_gold", "edge"]),
    UISpec("ui_panel_9slice_dark_gold_piece_tr", "panel_piece", (267, 96, 342, 176), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "tr", ["panel", "dark_gold", "corner"]),

    UISpec("ui_panel_9slice_dark_gold_piece_l",  "panel_piece", (38, 181, 113, 324), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "l",  ["panel", "dark_gold", "edge"]),
    UISpec("ui_panel_9slice_dark_gold_piece_c",  "panel_piece", (119, 181, 264, 324), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "c",  ["panel", "dark_gold", "center"]),
    UISpec("ui_panel_9slice_dark_gold_piece_r",  "panel_piece", (267, 181, 342, 324), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "r",  ["panel", "dark_gold", "edge"]),

    UISpec("ui_panel_9slice_dark_gold_piece_bl", "panel_piece", (38, 330, 113, 407), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "bl", ["panel", "dark_gold", "corner"]),
    UISpec("ui_panel_9slice_dark_gold_piece_b",  "panel_piece", (119, 330, 264, 407), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "b",  ["panel", "dark_gold", "edge"]),
    UISpec("ui_panel_9slice_dark_gold_piece_br", "panel_piece", (267, 330, 342, 407), "panels/pieces", "nine_slice_piece", "TextureRect", "dark_gold", "br", ["panel", "dark_gold", "corner"]),

    # ---------------------------------------------------------------------
    # SHEET 1 — PANEL 9-SLICE PIECES: DEEP
    # ---------------------------------------------------------------------
    UISpec("ui_panel_9slice_deep_piece_tl", "panel_piece", (397, 96, 473, 176), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "tl", ["panel", "deep", "corner"]),
    UISpec("ui_panel_9slice_deep_piece_t",  "panel_piece", (480, 96, 626, 176), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "t",  ["panel", "deep", "edge"]),
    UISpec("ui_panel_9slice_deep_piece_tr", "panel_piece", (630, 96, 705, 176), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "tr", ["panel", "deep", "corner"]),

    UISpec("ui_panel_9slice_deep_piece_l",  "panel_piece", (397, 181, 473, 324), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "l",  ["panel", "deep", "edge"]),
    UISpec("ui_panel_9slice_deep_piece_c",  "panel_piece", (480, 181, 626, 324), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "c",  ["panel", "deep", "center"]),
    UISpec("ui_panel_9slice_deep_piece_r",  "panel_piece", (630, 181, 705, 324), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "r",  ["panel", "deep", "edge"]),

    UISpec("ui_panel_9slice_deep_piece_bl", "panel_piece", (397, 330, 473, 407), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "bl", ["panel", "deep", "corner"]),
    UISpec("ui_panel_9slice_deep_piece_b",  "panel_piece", (480, 330, 626, 407), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "b",  ["panel", "deep", "edge"]),
    UISpec("ui_panel_9slice_deep_piece_br", "panel_piece", (630, 330, 705, 407), "panels/pieces", "nine_slice_piece", "TextureRect", "deep", "br", ["panel", "deep", "corner"]),

    # ---------------------------------------------------------------------
    # SHEET 1 — DIVIDERS / ORNAMENTS
    # ---------------------------------------------------------------------
    UISpec("ui_divider_gold_horizontal", "divider", (36, 452, 357, 476), "dividers", "separator", "TextureRect", tags=["gold", "horizontal"]),
    UISpec("ui_divider_gold_vertical",   "divider", (202, 492, 229, 592), "dividers", "separator", "TextureRect", tags=["gold", "vertical"]),

    UISpec("ui_corner_ornament_ne", "ornament", (324, 499, 384, 562), "ornaments", "corner_ornament", "TextureRect", tags=["corner", "ne"]),
    UISpec("ui_corner_ornament_nw", "ornament", (431, 499, 491, 562), "ornaments", "corner_ornament", "TextureRect", tags=["corner", "nw"]),
    UISpec("ui_corner_ornament_se", "ornament", (536, 499, 597, 562), "ornaments", "corner_ornament", "TextureRect", tags=["corner", "se"]),
    UISpec("ui_corner_ornament_sw", "ornament", (646, 499, 706, 562), "ornaments", "corner_ornament", "TextureRect", tags=["corner", "sw"]),

    # ---------------------------------------------------------------------
    # SHEET 2 — ICONS
    # ---------------------------------------------------------------------
    UISpec("icon_gate_locked",     "icon", (795, 101, 925, 220), "icons", "world_icon", "TextureRect", tags=["gate", "locked", "red"]),
    UISpec("icon_gate_open",       "icon", (965, 101, 1094, 220), "icons", "world_icon", "TextureRect", tags=["gate", "open", "cyan"]),
    UISpec("icon_stairs_up",       "icon", (1153, 101, 1264, 220), "icons", "world_icon", "TextureRect", tags=["stairs", "up", "green"]),
    UISpec("icon_stairs_down",     "icon", (1302, 101, 1416, 220), "icons", "world_icon", "TextureRect", tags=["stairs", "down", "purple"]),

    UISpec("icon_return_mooring",  "icon", (808, 294, 928, 405), "icons", "world_icon", "TextureRect", tags=["return", "mooring", "cyan"]),
    UISpec("icon_key_item",        "icon", (982, 292, 1058, 405), "icons", "world_icon", "TextureRect", tags=["key", "item"]),
    UISpec("icon_choke_point",     "icon", (1135, 292, 1256, 405), "icons", "world_icon", "TextureRect", tags=["choke", "point"]),
    UISpec("icon_hazard",          "icon", (1294, 292, 1418, 405), "icons", "world_icon", "TextureRect", tags=["hazard", "red"]),

    UISpec("icon_objective",       "icon", (807, 448, 925, 562), "icons", "world_icon", "TextureRect", tags=["objective", "gold"]),
    UISpec("compass_rose_small",   "icon", (962, 440, 1112, 577), "icons", "map_icon", "TextureRect", tags=["compass", "map"]),

    # ---------------------------------------------------------------------
    # SHEET 3 — PROMPT / PLAQUE COMPONENTS
    # ---------------------------------------------------------------------
    UISpec("plaque_header_small",  "prompt", (63, 690, 279, 750), "prompts", "header_plaque", "TextureRect", tags=["plaque", "header"]),
    UISpec("plaque_body_small",    "prompt", (35, 788, 276, 1022), "prompts", "body_panel", "TextureRect", tags=["plaque", "body"]),
    UISpec("input_key_badge",      "prompt", (343, 704, 423, 782), "prompts", "input_badge", "TextureRect", tags=["input", "badge"]),
    UISpec("lock_badge_small",     "prompt", (510, 704, 590, 782), "prompts", "lock_badge", "TextureRect", tags=["lock", "badge"]),
    UISpec("status_badge_ready",   "prompt", (299, 885, 440, 950), "prompts", "status_badge", "TextureRect", tags=["ready", "green"]),
    UISpec("status_badge_active",  "prompt", (476, 885, 630, 950), "prompts", "status_badge", "TextureRect", tags=["active", "cyan"]),

    # ---------------------------------------------------------------------
    # SHEET 4 — MINIMAP FRAME
    # ---------------------------------------------------------------------
    UISpec("minimap_frame_corner_tl", "minimap", (700, 708, 767, 775), "minimap", "frame_corner", "TextureRect", tags=["minimap", "corner", "tl"]),
    UISpec("minimap_frame_corner_tr", "minimap", (833, 708, 900, 775), "minimap", "frame_corner", "TextureRect", tags=["minimap", "corner", "tr"]),
    UISpec("minimap_frame_corner_bl", "minimap", (700, 780, 767, 842), "minimap", "frame_corner", "TextureRect", tags=["minimap", "corner", "bl"]),
    UISpec("minimap_frame_corner_br", "minimap", (833, 780, 900, 842), "minimap", "frame_corner", "TextureRect", tags=["minimap", "corner", "br"]),

    UISpec("minimap_frame_edge_top",    "minimap", (944, 709, 1134, 736), "minimap", "frame_edge", "TextureRect", tags=["minimap", "edge", "top"]),
    UISpec("minimap_frame_edge_bottom", "minimap", (944, 797, 1134, 825), "minimap", "frame_edge", "TextureRect", tags=["minimap", "edge", "bottom"]),
    UISpec("minimap_frame_edge_left",   "minimap", (907, 710, 933, 837), "minimap", "frame_edge", "TextureRect", tags=["minimap", "edge", "left"]),
    UISpec("minimap_frame_edge_right",  "minimap", (1150, 710, 1177, 837), "minimap", "frame_edge", "TextureRect", tags=["minimap", "edge", "right"]),

    UISpec("minimap_fill_dark",         "minimap", (792, 840, 966, 1012), "minimap", "map_fill", "TextureRect", tags=["minimap", "fill"]),
    UISpec("minimap_title_plaque",      "minimap", (1020, 1002, 1304, 1058), "minimap", "title_plaque", "TextureRect", tags=["minimap", "title"]),

    # ---------------------------------------------------------------------
    # SHEET 4 — MINIMAP MARKERS
    # ---------------------------------------------------------------------
    UISpec("minimap_marker_player",         "minimap_marker", (1226, 815, 1288, 891), "minimap", "map_marker", "TextureRect", tags=["player", "cyan"]),
    UISpec("minimap_marker_gate_locked",    "minimap_marker", (1320, 815, 1384, 884), "minimap", "map_marker", "TextureRect", tags=["gate", "locked"]),
    UISpec("minimap_marker_return_mooring", "minimap_marker", (1388, 815, 1447, 884), "minimap", "map_marker", "TextureRect", tags=["return", "mooring"]),
    UISpec("minimap_marker_objective",      "minimap_marker", (1227, 925, 1281, 980), "minimap", "map_marker", "TextureRect", tags=["objective"]),
    UISpec("minimap_marker_stair_up",       "minimap_marker", (1321, 925, 1379, 980), "minimap", "map_marker", "TextureRect", tags=["stairs", "up"]),
    UISpec("minimap_marker_stair_down",     "minimap_marker", (1390, 925, 1447, 980), "minimap", "map_marker", "TextureRect", tags=["stairs", "down"]),
]


NINEPATCH_GROUP_OUTPUTS = {
    "dark_gold": {
        "asset_id": "ui_panel_9slice_dark_gold",
        "domain": "panel",
        "out_subdir": "panels",
        "ui_role": "nine_patch_panel",
        "godot_node_hint": "NinePatchRect",
        "notes": "Primary dark charcoal panel with brass/gold trim.",
    },
    "deep": {
        "asset_id": "ui_panel_9slice_deep",
        "domain": "panel",
        "out_subdir": "panels",
        "ui_role": "nine_patch_panel",
        "godot_node_hint": "NinePatchRect",
        "notes": "Deeper/less ornate charcoal panel with brass trim.",
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def project_res_path(project_root: Path, disk_path: Path) -> str:
    custodian_root = project_root / "custodian"
    return "res://" + disk_path.relative_to(custodian_root).as_posix()


def scale_crop(crop: tuple[int, int, int, int], src_size: tuple[int, int]) -> tuple[int, int, int, int]:
    sx = src_size[0] / REFERENCE_SIZE[0]
    sy = src_size[1] / REFERENCE_SIZE[1]
    x0, y0, x1, y1 = crop
    return (
        int(round(x0 * sx)),
        int(round(y0 * sy)),
        int(round(x1 * sx)),
        int(round(y1 * sy)),
    )


def is_backgroundish(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return True

    # Generated sheet background is black. Remove it.
    if r <= 10 and g <= 10 and b <= 10:
        return True

    # Also tolerate very dark antialiasing halo around labels/background.
    if r <= 18 and g <= 18 and b <= 18:
        return True

    # Some transparent-preview renders may have checkerboard/white remnants.
    mx = max(r, g, b)
    mn = min(r, g, b)
    if mx >= 210 and (mx - mn) <= 35:
        return True

    return False


def remove_background(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_backgroundish(r, g, b, a):
                px[x, y] = (r, g, b, 0)

    return rgba


def trim_alpha(img: Image.Image, pad: int = 1) -> Image.Image:
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if bbox is None:
        return rgba

    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(rgba.width, x1 + pad)
    y1 = min(rgba.height, y1 + pad)
    return rgba.crop((x0, y0, x1, y1))


def crop_asset(source: Image.Image, crop: tuple[int, int, int, int], trim: bool = True) -> Image.Image:
    raw = source.crop(crop)
    cleaned = remove_background(raw)
    return trim_alpha(cleaned) if trim else cleaned


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def build_sidecar(
    project_root: Path,
    spec: UISpec,
    output_png: Path,
    source_sheet: Path,
    crop: tuple[int, int, int, int],
    image: Image.Image,
) -> dict[str, Any]:
    return {
        "schema": "custodian.game32.ui_asset.v1",
        "id": spec.asset_id,
        "name": spec.asset_id,
        "set": "ui_black_reliquary",
        "domain": spec.domain,
        "ui_role": spec.ui_role,
        "godot_node_hint": spec.godot_node_hint,
        "runtime_path": project_res_path(project_root, output_png),
        "source": {
            "sheet_path": project_res_path(project_root, source_sheet),
            "crop_box_px": list(crop),
            "reference_sheet_size_px": list(REFERENCE_SIZE),
        },
        "size_px": [image.width, image.height],
        "anchor": "top_left",
        "import": {
            "filter": "nearest",
            "mipmaps": False,
            "repeat": False,
        },
        "ninepatch": {
            "group": spec.ninepatch_group,
            "slot": spec.ninepatch_slot,
        } if spec.ninepatch_group else None,
        "tags": spec.tags,
        "notes": spec.notes,
        "generated_at_utc": utc_now(),
        "generator": "custodian/tools/art/extract_ui_black_reliquary_game32.py",
    }


def assemble_ninepatch(
    project_root: Path,
    group_name: str,
    pieces: dict[str, tuple[UISpec, Image.Image, Path, Path]],
    source_sheet: Path,
) -> tuple[Path, Path, dict[str, Any]]:
    required = ["tl", "t", "tr", "l", "c", "r", "bl", "b", "br"]
    missing = [slot for slot in required if slot not in pieces]
    if missing:
        raise RuntimeError(f"ninepatch group {group_name} missing slots: {missing}")

    tl = pieces["tl"][1]
    t = pieces["t"][1]
    tr = pieces["tr"][1]
    l = pieces["l"][1]
    c = pieces["c"][1]
    r = pieces["r"][1]
    bl = pieces["bl"][1]
    b = pieces["b"][1]
    br = pieces["br"][1]

    col_w = [max(tl.width, l.width, bl.width), max(t.width, c.width, b.width), max(tr.width, r.width, br.width)]
    row_h = [max(tl.height, t.height, tr.height), max(l.height, c.height, r.height), max(bl.height, b.height, br.height)]

    total_w = sum(col_w)
    total_h = sum(row_h)

    out = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))

    slots = {
        "tl": (0, 0, tl),
        "t": (col_w[0], 0, t),
        "tr": (col_w[0] + col_w[1], 0, tr),
        "l": (0, row_h[0], l),
        "c": (col_w[0], row_h[0], c),
        "r": (col_w[0] + col_w[1], row_h[0], r),
        "bl": (0, row_h[0] + row_h[1], bl),
        "b": (col_w[0], row_h[0] + row_h[1], b),
        "br": (col_w[0] + col_w[1], row_h[0] + row_h[1], br),
    }

    for _slot, (x, y, img) in slots.items():
        out.alpha_composite(img, (x, y))

    info = NINEPATCH_GROUP_OUTPUTS[group_name]
    out_dir = project_root / "custodian/content/ui/black_reliquary" / info["out_subdir"]
    out_dir.mkdir(parents=True, exist_ok=True)

    png_path = out_dir / f"{info['asset_id']}.png"
    json_path = out_dir / f"{info['asset_id']}.game32.json"
    out.save(png_path)

    margins = {
        "left": col_w[0],
        "top": row_h[0],
        "right": col_w[2],
        "bottom": row_h[2],
    }

    data = {
        "schema": "custodian.game32.ui_asset.v1",
        "id": info["asset_id"],
        "name": info["asset_id"],
        "set": "ui_black_reliquary",
        "domain": info["domain"],
        "ui_role": info["ui_role"],
        "godot_node_hint": info["godot_node_hint"],
        "runtime_path": project_res_path(project_root, png_path),
        "source": {
            "sheet_path": project_res_path(project_root, source_sheet),
            "assembled_from": {
                slot: project_res_path(project_root, pieces[slot][2])
                for slot in required
            },
            "reference_sheet_size_px": list(REFERENCE_SIZE),
        },
        "size_px": [out.width, out.height],
        "ninepatch": {
            "stretch_margins_px": margins,
            "godot_patch_margin_left": margins["left"],
            "godot_patch_margin_top": margins["top"],
            "godot_patch_margin_right": margins["right"],
            "godot_patch_margin_bottom": margins["bottom"],
        },
        "import": {
            "filter": "nearest",
            "mipmaps": False,
            "repeat": False,
        },
        "tags": ["panel", "ninepatch", group_name],
        "notes": info["notes"],
        "generated_at_utc": utc_now(),
        "generator": "custodian/tools/art/extract_ui_black_reliquary_game32.py",
    }

    write_json(json_path, data)
    return png_path, json_path, data


def write_domain_manifests(
    project_root: Path,
    all_assets: list[dict[str, Any]],
) -> None:
    by_domain: dict[str, list[dict[str, Any]]] = {}

    for asset in all_assets:
        by_domain.setdefault(asset["domain"], []).append(asset)

    for domain, assets in sorted(by_domain.items()):
        # Infer a stable domain folder.
        if domain == "panel":
            domain_dir = project_root / "custodian/content/ui/custodian/panels"
        elif domain == "panel_piece":
            domain_dir = project_root / "custodian/content/ui/custodian/panels/pieces"
        elif domain == "divider":
            domain_dir = project_root / "custodian/content/ui/custodian/dividers"
        elif domain == "ornament":
            domain_dir = project_root / "custodian/content/ui/custodian/ornaments"
        elif domain == "icon":
            domain_dir = project_root / "custodian/content/ui/custodian/icons"
        elif domain == "prompt":
            domain_dir = project_root / "custodian/content/ui/custodian/prompts"
        elif domain in {"minimap", "minimap_marker"}:
            domain_dir = project_root / "custodian/content/ui/custodian/minimap"
        else:
            domain_dir = project_root / "custodian/content/ui/custodian" / domain

        manifest = {
            "schema": "custodian.game32.ui_domain_manifest.v1",
            "set": "ui_black_reliquary",
            "domain": domain,
            "base_path": project_res_path(project_root, domain_dir),
            "asset_count": len(assets),
            "assets": [
                {
                    "id": asset["id"],
                    "runtime_path": asset["runtime_path"],
                    "metadata_path": asset["metadata_path"],
                    "size_px": asset["size_px"],
                    "ui_role": asset["ui_role"],
                    "godot_node_hint": asset["godot_node_hint"],
                    "tags": asset.get("tags", []),
                }
                for asset in assets
            ],
            "generated_at_utc": utc_now(),
            "generator": "custodian/tools/art/extract_ui_black_reliquary_game32.py",
        }

        write_json(domain_dir / "_manifest.game32.json", manifest)


def write_top_level_manifest(project_root: Path, all_assets: list[dict[str, Any]], source_sheet: Path) -> None:
    out_path = project_root / "custodian/content/ui/custodian/_manifest.game32.json"
    metadata_path = project_root / "custodian/content/metadata/game32/ui_black_reliquary.game32.json"

    domains: dict[str, int] = {}
    for asset in all_assets:
        domains[asset["domain"]] = domains.get(asset["domain"], 0) + 1

    manifest = {
        "schema": "custodian.game32.ui_pack_manifest.v1",
        "set": "ui_black_reliquary",
        "display_name": "CUSTODIAN Gothic Brass UI Kit",
        "source_sheet": project_res_path(project_root, source_sheet),
        "base_path": "res://content/ui/custodian",
        "asset_count": len(all_assets),
        "domains": domains,
        "assets": [
            {
                "id": asset["id"],
                "domain": asset["domain"],
                "ui_role": asset["ui_role"],
                "runtime_path": asset["runtime_path"],
                "metadata_path": asset["metadata_path"],
                "size_px": asset["size_px"],
                "godot_node_hint": asset["godot_node_hint"],
                "tags": asset.get("tags", []),
            }
            for asset in all_assets
        ],
        "recommended_godot_paths": {
            "theme_scripts": "res://game/ui/theme/",
            "components": "res://game/ui/components/",
            "hud": "res://game/ui/hud/",
        },
        "notes": [
            "Use assembled ui_panel_9slice_dark_gold/ui_panel_9slice_deep with NinePatchRect.",
            "Use panel pieces only if building custom frame controls.",
            "Use icons for HUD/world callouts/minimap markers.",
            "Do not bake HUD text into map art.",
        ],
        "doc_drift_check": {
            "status": "needs_doc_update_if_accepted",
            "recommended_docs": [
                "custodian/docs/ai_context/CURRENT_STATE.md",
                "custodian/docs/ai_context/CONTEXT.md",
                "custodian/docs/ai_context/FILE_INDEX.md",
            ],
        },
        "generated_at_utc": utc_now(),
        "generator": "custodian/tools/art/extract_ui_black_reliquary_game32.py",
    }

    write_json(out_path, manifest)
    write_json(metadata_path, manifest)


def write_doc_drift_review(project_root: Path) -> None:
    review_path = project_root / "custodian/content/ui/custodian/_doc_drift_review.json"
    review = {
        "schema": "custodian.doc_drift_review.v1",
        "subject": "ui_black_reliquary_kit",
        "status": "needs_doc_update_if_accepted",
        "runtime_outputs": {
            "ui_assets": "custodian/content/ui/custodian/",
            "metadata_authority": "custodian/content/metadata/game32/ui_black_reliquary.game32.json",
            "master_sheet": "custodian/content/masters/ui/ui_black_reliquary_components.png",
        },
        "recommended_doc_updates": [
            "custodian/docs/ai_context/CURRENT_STATE.md",
            "custodian/docs/ai_context/CONTEXT.md",
            "custodian/docs/ai_context/FILE_INDEX.md",
        ],
        "note": "If the UI kit is wired into active Godot HUD scenes, update active AI context docs.",
        "generated_at_utc": utc_now(),
    }
    write_json(review_path, review)


def make_debug_preview(
    project_root: Path,
    source: Image.Image,
    source_size: tuple[int, int],
) -> None:
    out = source.convert("RGBA").copy()
    draw = ImageDraw.Draw(out)

    for spec in SPECS:
        crop = scale_crop(spec.crop, source_size)
        draw.rectangle(crop, outline=(255, 0, 0, 255), width=3)
        draw.text((crop[0] + 2, crop[1] + 2), spec.asset_id, fill=(255, 255, 0, 255))

    debug_path = project_root / ".ai/ui_black_reliquary_extract_boxes.png"
    debug_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(debug_path)
    print(f"Wrote debug preview: {debug_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".", help="Repo root containing custodian/.")
    parser.add_argument("--sheet", required=True, help="Path to the generated UI sheet image.")
    parser.add_argument("--debug", action="store_true", help="Write crop-box debug preview to .ai/.")
    parser.add_argument("--dry-run", action="store_true", help="Only write debug preview and print planned outputs.")
    parser.add_argument("--no-master-copy", action="store_true", help="Do not copy input sheet into content/masters/ui/.")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    if not (project_root / "custodian").exists():
        raise SystemExit(f"Project root must contain custodian/: {project_root}")

    input_sheet = Path(args.sheet)
    if not input_sheet.is_absolute():
        input_sheet = project_root / input_sheet
    input_sheet = input_sheet.resolve()

    if not input_sheet.exists():
        raise SystemExit(f"Sheet not found: {input_sheet}")

    master_sheet = project_root / "custodian/content/masters/ui/ui_black_reliquary_components.png"
    master_sheet.parent.mkdir(parents=True, exist_ok=True)

    if args.no_master_copy:
        source_sheet = input_sheet
    else:
        shutil.copy2(input_sheet, master_sheet)
        source_sheet = master_sheet
        print(f"Copied master sheet: {source_sheet}")

    source = Image.open(source_sheet).convert("RGBA")
    source_size = source.size

    if args.debug:
        make_debug_preview(project_root, source, source_size)

    extracted_records: list[dict[str, Any]] = []
    ninepatch_pieces: dict[str, dict[str, tuple[UISpec, Image.Image, Path, Path]]] = {}

    for spec in SPECS:
        crop = scale_crop(spec.crop, source_size)
        image = crop_asset(source, crop, trim=True)

        out_dir = project_root / "custodian/content/ui/custodian" / spec.out_subdir
        out_dir.mkdir(parents=True, exist_ok=True)

        png_path = out_dir / f"{spec.asset_id}.png"
        json_path = out_dir / f"{spec.asset_id}.game32.json"

        print(f"{spec.asset_id}: crop={crop} size={image.size} -> {png_path}")

        if args.dry_run:
            continue

        image.save(png_path)

        sidecar = build_sidecar(
            project_root=project_root,
            spec=spec,
            output_png=png_path,
            source_sheet=source_sheet,
            crop=crop,
            image=image,
        )
        write_json(json_path, sidecar)

        record = {
            "id": spec.asset_id,
            "domain": spec.domain,
            "ui_role": spec.ui_role,
            "godot_node_hint": spec.godot_node_hint,
            "runtime_path": project_res_path(project_root, png_path),
            "metadata_path": project_res_path(project_root, json_path),
            "size_px": [image.width, image.height],
            "tags": spec.tags,
        }
        extracted_records.append(record)

        if spec.ninepatch_group and spec.ninepatch_slot:
            ninepatch_pieces.setdefault(spec.ninepatch_group, {})[spec.ninepatch_slot] = (
                spec,
                image,
                png_path,
                json_path,
            )

    if args.dry_run:
        print("Dry run complete.")
        return

    # Assemble real Godot-friendly NinePatchRect source images.
    for group_name, pieces in sorted(ninepatch_pieces.items()):
        png_path, json_path, data = assemble_ninepatch(project_root, group_name, pieces, source_sheet)
        extracted_records.append(
            {
                "id": data["id"],
                "domain": data["domain"],
                "ui_role": data["ui_role"],
                "godot_node_hint": data["godot_node_hint"],
                "runtime_path": project_res_path(project_root, png_path),
                "metadata_path": project_res_path(project_root, json_path),
                "size_px": data["size_px"],
                "tags": data["tags"],
            }
        )
        print(f"Assembled ninepatch: {png_path}")

    write_domain_manifests(project_root, extracted_records)
    write_top_level_manifest(project_root, extracted_records, source_sheet)
    write_doc_drift_review(project_root)

    print("\nDone.")
    print("Suggested checks:")
    print("  find custodian/content/ui/custodian -type f | sort")
    print("  python - <<'PY'")
    print("from pathlib import Path")
    print("import json")
    print("p=Path('custodian/content/metadata/game32/ui_black_reliquary.game32.json')")
    print("data=json.loads(p.read_text())")
    print("print(data['asset_count'], data['domains'])")
    print("PY")


if __name__ == "__main__":
    main()
