#!/usr/bin/env python3
"""
Interactive CUSTODIAN game32 asset review batcher.

This version supports full game32.asset.v2 manifests, including:

  schema
  id
  display_name
  source
  file
  classification
  placement
  collision
  procgen
  master_index

It creates review batches:
  - contact-sheet PNG for visual review
  - aggregate JSON containing one FULL editable manifest per PNG
  - optional clipboard copy of the contact sheet
  - after you edit/save aggregate JSON, it applies:
      - full manifest updates
      - recategorization
      - move/rename/delete/skip actions
      - PNG movement
      - manifest sidecar rewriting
      - optional .png.import handling

Typical use:

  cd /home/braydenchaffee/Projects/CUSTODIAN

  python custodian/tools/asset_pipeline/review_game32_png_batches.py \\
    --root custodian/content/tiles/gothic \\
    --batch-size 24 \\
    --columns 6 \\
    --thumb-size 160 \\
    --include-without-manifest \\
    --reference-manifest custodian/content/tiles/gothic/gothic_master_sheet.game32.json \\
    --reference-manifest custodian/content/tiles/gothic/gothic_tilesheet_manifest.game32.json

Review JSON model:

  Each entry has:

    "review": {
      "action": "keep" | "move" | "skip" | "delete",
      "target_png": "...optional path...",
      "target_manifest": "...optional path...",
      "delete_import": true,
      "notes": ""
    },

    "asset": {
      FULL game32.asset.v2 manifest here.
      Edit this directly.
    }

The script uses entry.asset as the source of truth when applying the batch.

Important:
  - If review.action == "move", the asset PNG moves to review.target_png if set.
    Otherwise it moves to asset.file.path.
  - If review.action == "keep", the PNG stays where it is, but the sidecar
    manifest is overwritten with the edited full asset manifest.
  - If a PNG has no sidecar manifest, the script tries to hydrate it from
    reference manifests by matching file.path/source.original_path.
  - If no reference is found, the script creates a complete game32.asset.v2
    placeholder with every required field.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


GAME32_SUFFIX = ".game32.json"
DEFAULT_REVIEW_EXCLUDE_PREFIXES = ("_review_",)
DEFAULT_REVIEW_EXCLUDE_DIRS = {".review_batches"}
VALID_ACTIONS = {"keep", "move", "skip", "delete"}


@dataclass
class AssetItem:
    png_path: Path
    manifest_path: Path | None
    png_rel: str
    manifest_rel: str | None
    asset: dict[str, Any]
    discovered_index: int


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def resolve_under_project(pathish: str | Path, project_root: Path) -> Path:
    p = Path(pathish).expanduser()
    if p.is_absolute():
        return p
    return project_root / p


def rel_to_project(path: Path, project_root: Path) -> str:
    try:
        return path.resolve().relative_to(project_root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def godot_res_path(path: Path, project_root: Path) -> str:
    """
    Convert /repo/custodian/content/foo.png to res://content/foo.png when possible.
    Otherwise return a project-relative path.
    """
    try:
        rel = path.resolve().relative_to((project_root / "custodian").resolve())
        return "res://" + rel.as_posix()
    except ValueError:
        return rel_to_project(path, project_root)


def path_variants_for_lookup(path: Path, project_root: Path) -> set[str]:
    rel_project = rel_to_project(path, project_root)
    variants = {
        path.as_posix(),
        rel_project,
        godot_res_path(path, project_root),
    }

    # If path is under custodian/content, also index content-relative variants.
    try:
        rel_content = path.resolve().relative_to((project_root / "custodian" / "content").resolve())
        variants.add("custodian/content/" + rel_content.as_posix())
        variants.add("res://content/" + rel_content.as_posix())
        variants.add(rel_content.as_posix())
    except ValueError:
        pass

    return variants


def manifest_sidecar_for_png(png: Path) -> Path:
    """
    Canonical sidecar:
      thing.png -> thing.game32.json
    """
    return png.with_suffix(GAME32_SUFFIX)


def alternate_manifest_sidecars_for_png(png: Path) -> list[Path]:
    return [
        png.with_suffix(GAME32_SUFFIX),
        Path(str(png) + GAME32_SUFFIX),
    ]


def find_manifest_for_png(png: Path) -> Path | None:
    for candidate in alternate_manifest_sidecars_for_png(png):
        if candidate.exists():
            return candidate
    return None


def load_image_size(path: Path) -> dict[str, int]:
    try:
        with Image.open(path) as img:
            w, h = img.size
        return {"w": int(w), "h": int(h)}
    except Exception:
        return {"w": 0, "h": 0}


def display_name_from_stem(stem: str) -> str:
    return stem.replace("_", " ").replace("-", " ").title()


def infer_section_subtype_from_path(path: Path) -> tuple[str, str]:
    parts = [p.lower() for p in path.parts]

    section = "tiles"
    subtype = "uncategorized"

    if "tiles" in parts:
        section = "tiles"
    if "props" in parts:
        section = "props"
    if "structures" in parts:
        section = "structures"
    if "doors" in parts:
        section = "doors"
    if "roads" in parts:
        section = "roads"
    if "rooms" in parts:
        section = "rooms"
    if "animations" in parts or "sprites" in parts:
        section = "animations"

    for candidate in [
        "floors",
        "floor",
        "floor_overlay",
        "decals",
        "ritual",
        "wall_tiles",
        "wall_tops_edges",
        "wall_vertical_slice",
        "wall_horizontal_or_cap",
        "wall_corner_or_end",
        "walls",
        "doors",
        "props",
        "structures",
        "roads",
        "rooms",
    ]:
        if candidate in parts:
            subtype = candidate
            break

    return section, subtype


def infer_classification(path: Path) -> dict[str, Any]:
    p = path.as_posix().lower()
    name = path.name.lower()

    if "/decals/" in p or "/floor_overlay/" in p or "decal" in name:
        return {
            "asset_type": "tiles",
            "semantic_role": "floor_overlay_or_decal",
            "placement_layer": "ground_detail",
            "tags": unique_sorted(["gothic", "floor", "overlay", "decal", "walkable"]),
            "review_status": "needs_game32_enrichment",
        }

    if "/floors/" in p or "floor" in name:
        return {
            "asset_type": "tiles",
            "semantic_role": "walkable_floor_variant",
            "placement_layer": "ground",
            "tags": unique_sorted(["gothic", "floor", "walkable"]),
            "review_status": "needs_game32_enrichment",
        }

    if "wall_top" in p or "wall_horizontal_or_cap" in p or "cap" in name:
        return {
            "asset_type": "walls",
            "semantic_role": "wall_top_or_cap",
            "placement_layer": "wall_cap",
            "tags": unique_sorted(["gothic", "wall", "cap", "top", "blocking"]),
            "review_status": "needs_game32_enrichment",
        }

    if "wall" in p or "wall" in name:
        return {
            "asset_type": "walls",
            "semantic_role": "wall_segment",
            "placement_layer": "wall",
            "tags": unique_sorted(["gothic", "wall", "blocking"]),
            "review_status": "needs_game32_enrichment",
        }

    if "door" in p or "gate" in p or "door" in name or "gate" in name:
        return {
            "asset_type": "doors",
            "semantic_role": "door_or_gate",
            "placement_layer": "door",
            "tags": unique_sorted(["gothic", "door", "gate", "blocking"]),
            "review_status": "needs_game32_enrichment",
        }

    if "prop" in p:
        return {
            "asset_type": "props",
            "semantic_role": "environment_prop",
            "placement_layer": "prop",
            "tags": unique_sorted(["gothic", "prop", "environment"]),
            "review_status": "needs_game32_enrichment",
        }

    return {
        "asset_type": "tiles",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "ground",
        "tags": ["needs_review"],
        "review_status": "needs_game32_enrichment",
    }


def infer_placement(path: Path, pixel_size: dict[str, int], classification: dict[str, Any]) -> dict[str, Any]:
    tile_size = 32
    w = max(1, int(pixel_size.get("w", 0)))
    h = max(1, int(pixel_size.get("h", 0)))
    footprint = {
        "w": max(1, math.ceil(w / tile_size)),
        "h": max(1, math.ceil(h / tile_size)),
    }

    placement_layer = classification.get("placement_layer", "")
    is_y_sorted = placement_layer in {"wall", "wall_cap", "prop", "door", "structure"}

    if placement_layer in {"ground", "ground_detail", "floor", "floor_overlay"}:
        origin_mode = "top_left"
        pivot = {"x": 0, "y": 0}
    else:
        origin_mode = "bottom_center"
        pivot = {"x": w // 2, "y": h}

    return {
        "tile_size": tile_size,
        "footprint_tiles": footprint,
        "origin_mode": origin_mode,
        "pivot_px": pivot,
        "snap": "tile",
        "allow_mirror_x": False,
        "allow_rotation": False,
        "y_sort": bool(is_y_sorted),
    }


def infer_collision(classification: dict[str, Any]) -> dict[str, Any]:
    layer = classification.get("placement_layer", "")
    asset_type = classification.get("asset_type", "")

    blocks = layer in {"wall", "wall_cap", "door", "structure"} or asset_type in {"walls", "doors", "structures"}

    return {
        "blocks_movement": bool(blocks),
        "blocks_sight": bool(layer in {"wall", "door", "structure"} or asset_type in {"walls", "doors", "structures"}),
        "cover_value": 2 if blocks else 0,
        "collision_shape": "tile_rect" if blocks else "none",
        "review_status": "needs_game32_enrichment",
    }


def infer_procgen(classification: dict[str, Any]) -> dict[str, Any]:
    layer = classification.get("placement_layer", "")
    tags = set(classification.get("tags", []))

    if layer in {"ground", "floor"} or "walkable" in tags:
        uses = ["compound_floor", "courtyard_floor", "interior_floor"]
        weight = 40
        indoor = True
        outdoor = True
    elif layer in {"ground_detail", "floor_overlay"} or "decal" in tags:
        uses = ["floor_detail", "environmental_storytelling", "visual_variation"]
        weight = 10
        indoor = True
        outdoor = True
    elif layer in {"wall", "wall_cap"}:
        uses = ["compound_wall", "interior_wall", "boundary"]
        weight = 30
        indoor = True
        outdoor = True
    else:
        uses = ["needs_review"]
        weight = 5
        indoor = True
        outdoor = True

    return {
        "uses": uses,
        "weight": weight,
        "can_spawn_indoor": indoor,
        "can_spawn_outdoor": outdoor,
        "supports_gothic_compound": True,
        "review_status": "needs_game32_enrichment",
    }


def make_placeholder_asset(
    png: Path,
    project_root: Path,
    *,
    discovered_index: int,
) -> dict[str, Any]:
    pixel_size = load_image_size(png)
    section, subtype = infer_section_subtype_from_path(png)
    classification = infer_classification(png)
    placement = infer_placement(png, pixel_size, classification)
    collision = infer_collision(classification)
    procgen = infer_procgen(classification)

    return {
        "schema": "game32.asset.v2",
        "id": png.stem,
        "display_name": display_name_from_stem(png.stem),
        "source": {
            "master_sheet": None,
            "original_path": godot_res_path(png, project_root),
            "section": section,
            "subtype": subtype,
            "source_rect_px": {
                "x": 0,
                "y": 0,
                "w": pixel_size["w"],
                "h": pixel_size["h"],
            },
            "review_source": "placeholder_generated_from_png_path",
        },
        "file": {
            "path": godot_res_path(png, project_root),
            "pixel_size": pixel_size,
        },
        "classification": classification,
        "placement": placement,
        "collision": collision,
        "procgen": procgen,
        "master_index": discovered_index,
    }


def unique_sorted(values: list[str]) -> list[str]:
    seen = set()
    out = []
    for v in values:
        if v is None:
            continue
        s = str(v).strip()
        if not s:
            continue
        if s not in seen:
            seen.add(s)
            out.append(s)
    return out


def normalize_asset_manifest(asset: dict[str, Any], png: Path, project_root: Path, discovered_index: int) -> dict[str, Any]:
    """
    Ensure a manifest has all major game32.asset.v2 blocks while preserving existing data.
    """
    base = make_placeholder_asset(png, project_root, discovered_index=discovered_index)
    merged = deep_merge_missing(copy.deepcopy(asset), base)

    merged["schema"] = merged.get("schema") or "game32.asset.v2"
    merged["id"] = merged.get("id") or png.stem
    merged["display_name"] = merged.get("display_name") or display_name_from_stem(png.stem)

    # Normalize file block to current known path and actual image size unless existing file path is intentional.
    merged.setdefault("file", {})
    merged["file"].setdefault("path", godot_res_path(png, project_root))
    merged["file"].setdefault("pixel_size", load_image_size(png))

    # Make sure required nested keys exist.
    merged.setdefault("source", {})
    merged.setdefault("classification", {})
    merged.setdefault("placement", {})
    merged.setdefault("collision", {})
    merged.setdefault("procgen", {})

    if "master_index" not in merged:
        merged["master_index"] = discovered_index

    # Some manifests use pixel_size.w/h. Preserve but fill if missing.
    pixel_size = merged["file"].get("pixel_size")
    if not isinstance(pixel_size, dict):
        merged["file"]["pixel_size"] = load_image_size(png)

    # Some manifests lack pivot_px in placement; fill it.
    placement = merged["placement"]
    if "pivot_px" not in placement:
        inferred = infer_placement(png, merged["file"]["pixel_size"], merged["classification"])
        placement["pivot_px"] = inferred["pivot_px"]

    if "collision_shape" not in merged["collision"]:
        inferred_col = infer_collision(merged["classification"])
        merged["collision"]["collision_shape"] = inferred_col["collision_shape"]

    return merged


def deep_merge_missing(primary: Any, fallback: Any) -> Any:
    """
    Fill missing keys in primary from fallback without replacing existing values.
    """
    if isinstance(primary, dict) and isinstance(fallback, dict):
        for k, v in fallback.items():
            if k not in primary or primary[k] is None:
                primary[k] = copy.deepcopy(v)
            else:
                primary[k] = deep_merge_missing(primary[k], v)
        return primary
    return primary


def build_reference_index(reference_manifest_paths: list[Path], project_root: Path) -> dict[str, dict[str, Any]]:
    """
    Index reference manifests by multiple path forms:
      - file.path
      - source.original_path
      - content-relative
      - basename
    """
    index: dict[str, dict[str, Any]] = {}

    for path in reference_manifest_paths:
        if not path.exists():
            eprint(f"WARNING: reference manifest does not exist: {path}")
            continue

        try:
            data = read_json(path)
        except Exception as exc:
            eprint(f"WARNING: could not load reference manifest {path}: {exc}")
            continue

        assets = data.get("assets") if isinstance(data, dict) else None
        if not isinstance(assets, list):
            eprint(f"WARNING: reference manifest has no assets list: {path}")
            continue

        for asset in assets:
            if not isinstance(asset, dict):
                continue

            keys: set[str] = set()

            file_path = asset.get("file", {}).get("path") if isinstance(asset.get("file"), dict) else None
            original_path = asset.get("source", {}).get("original_path") if isinstance(asset.get("source"), dict) else None

            for value in [file_path, original_path]:
                if not value:
                    continue
                value = str(value)
                keys.add(value)
                keys.add(value.replace("res://", "custodian/"))
                keys.add(value.replace("res://content/", "custodian/content/"))
                keys.add(Path(value).name)

            asset_id = asset.get("id")
            if asset_id:
                keys.add(str(asset_id))

            for key in keys:
                if key and key not in index:
                    index[key] = asset

    return index


def hydrate_asset_from_reference(
    png: Path,
    project_root: Path,
    reference_index: dict[str, dict[str, Any]],
) -> dict[str, Any] | None:
    variants = path_variants_for_lookup(png, project_root)
    variants.add(png.name)
    variants.add(png.stem)

    for key in variants:
        if key in reference_index:
            return copy.deepcopy(reference_index[key])

    return None


def load_asset_for_png(
    png: Path,
    project_root: Path,
    reference_index: dict[str, dict[str, Any]],
    discovered_index: int,
) -> tuple[dict[str, Any], Path | None]:
    sidecar = find_manifest_for_png(png)

    if sidecar:
        try:
            data = read_json(sidecar)
            if isinstance(data, dict) and data.get("schema") == "game32.asset.v2":
                return normalize_asset_manifest(data, png, project_root, discovered_index), sidecar
        except Exception as exc:
            eprint(f"WARNING: failed reading sidecar {sidecar}: {exc}")

    ref_asset = hydrate_asset_from_reference(png, project_root, reference_index)
    if ref_asset:
        return normalize_asset_manifest(ref_asset, png, project_root, discovered_index), sidecar

    return make_placeholder_asset(png, project_root, discovered_index=discovered_index), sidecar


def discover_pngs(
    *,
    root: Path,
    project_root: Path,
    include_without_manifest: bool,
    exclude_review: bool,
    reference_index: dict[str, dict[str, Any]],
) -> list[AssetItem]:
    pngs: list[Path] = []

    for path in root.rglob("*.png"):
        rel_parts = path.relative_to(root).parts

        if any(part in DEFAULT_REVIEW_EXCLUDE_DIRS for part in rel_parts):
            continue

        if any(part.startswith(".") for part in rel_parts):
            continue

        if path.name.endswith(".import"):
            continue

        if exclude_review and any(path.name.startswith(prefix) for prefix in DEFAULT_REVIEW_EXCLUDE_PREFIXES):
            continue

        if exclude_review and path.name in {
            "gothic_master_sheet.png",
            "gothic_tilesheet.png",
        }:
            continue

        sidecar = find_manifest_for_png(path)
        has_ref = hydrate_asset_from_reference(path, project_root, reference_index) is not None

        if not include_without_manifest and not sidecar and not has_ref:
            continue

        pngs.append(path)

    pngs = sorted(pngs, key=lambda p: p.relative_to(root).as_posix())

    items: list[AssetItem] = []

    for idx, png in enumerate(pngs):
        asset, manifest_path = load_asset_for_png(
            png,
            project_root,
            reference_index,
            discovered_index=idx,
        )

        items.append(
            AssetItem(
                png_path=png,
                manifest_path=manifest_path,
                png_rel=rel_to_project(png, project_root),
                manifest_rel=rel_to_project(manifest_path, project_root) if manifest_path else None,
                asset=asset,
                discovered_index=idx,
            )
        )

    return items


def safe_font(size: int) -> ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/LiberationSans-Regular.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for candidate in candidates:
        p = Path(candidate)
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


def make_checkerboard(w: int, h: int, cell: int = 16) -> Image.Image:
    img = Image.new("RGBA", (w, h), (238, 238, 238, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            if ((x // cell) + (y // cell)) % 2:
                draw.rectangle([x, y, x + cell - 1, y + cell - 1], fill=(210, 210, 210, 255))
    return img


def fit_image(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    if w <= 0 or h <= 0:
        return Image.new("RGBA", (max_w, max_h), (0, 0, 0, 0))

    scale = min(max_w / w, max_h / h, 1.0)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))

    if (new_w, new_h) == (w, h):
        return img

    return img.resize((new_w, new_h), Image.Resampling.NEAREST)


def make_contact_sheet(
    items: list[AssetItem],
    output_path: Path,
    *,
    project_root: Path,
    thumb_size: int,
    columns: int,
    label_height: int,
    padding: int,
) -> None:
    font = safe_font(13)
    index_font = safe_font(18)

    rows = max(1, math.ceil(len(items) / columns))
    cell_w = thumb_size + padding * 2
    cell_h = thumb_size + label_height + padding * 2
    sheet_w = columns * cell_w
    sheet_h = rows * cell_h

    sheet = make_checkerboard(sheet_w, sheet_h, 16).convert("RGBA")
    draw = ImageDraw.Draw(sheet)

    for batch_idx, item in enumerate(items):
        row = batch_idx // columns
        col = batch_idx % columns
        x0 = col * cell_w
        y0 = row * cell_h

        asset = item.asset
        classification = asset.get("classification", {})
        semantic_role = classification.get("semantic_role", "")
        placement_layer = classification.get("placement_layer", "")

        draw.rectangle(
            [x0, y0, x0 + cell_w - 1, y0 + cell_h - 1],
            outline=(80, 80, 80, 255),
            width=2,
        )

        try:
            img = Image.open(item.png_path).convert("RGBA")
        except Exception:
            img = Image.new("RGBA", (thumb_size, thumb_size), (160, 0, 0, 255))

        fitted = fit_image(img, thumb_size, thumb_size)
        paste_x = x0 + padding + (thumb_size - fitted.width) // 2
        paste_y = y0 + padding + (thumb_size - fitted.height) // 2
        sheet.alpha_composite(fitted, (paste_x, paste_y))

        draw.rectangle([x0 + 4, y0 + 4, x0 + 48, y0 + 28], fill=(0, 0, 0, 220))
        draw.text((x0 + 8, y0 + 5), f"#{batch_idx:02d}", fill=(255, 255, 255, 255), font=index_font)

        label_y = y0 + padding + thumb_size + 4
        draw.rectangle(
            [x0 + 2, label_y - 2, x0 + cell_w - 3, y0 + cell_h - 3],
            fill=(0, 0, 0, 210),
        )

        label_lines = [
            item.png_path.name[:32],
            str(semantic_role or placement_layer or item.png_path.parent.name)[:32],
        ]

        draw.text((x0 + 6, label_y), label_lines[0], fill=(255, 255, 255, 255), font=font)
        draw.text((x0 + 6, label_y + 16), label_lines[1], fill=(200, 220, 255, 255), font=font)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)


def clipboard_copy_png(path: Path) -> bool:
    commands = [
        ["wl-copy", "--type", "image/png"],
        ["xclip", "-selection", "clipboard", "-t", "image/png", "-i"],
    ]

    for cmd in commands:
        if shutil.which(cmd[0]) is None:
            continue

        try:
            with path.open("rb") as f:
                subprocess.run(cmd, stdin=f, check=True)
            print(f"Copied contact sheet to clipboard using {cmd[0]}.")
            return True
        except Exception as exc:
            eprint(f"Clipboard command failed with {cmd[0]}: {exc}")

    eprint("WARNING: Could not copy image to clipboard. Install wl-clipboard or xclip.")
    return False


def build_review_entry(
    *,
    item: AssetItem,
    batch_index: int,
    project_root: Path,
) -> dict[str, Any]:
    canonical_manifest = manifest_sidecar_for_png(item.png_path)

    return {
        "batch_index": batch_index,
        "current": {
            "png": item.png_rel,
            "manifest": item.manifest_rel,
            "canonical_manifest": rel_to_project(canonical_manifest, project_root),
            "filename": item.png_path.name,
            "parent_dir": rel_to_project(item.png_path.parent, project_root),
            "exists": item.png_path.exists(),
        },
        "review": {
            "action": "keep",
            "target_png": item.png_rel,
            "target_manifest": rel_to_project(canonical_manifest, project_root),
            "delete_import": True,
            "notes": "",
        },
        "asset": copy.deepcopy(item.asset),
    }


def write_aggregate_review_json(
    *,
    batch_items: list[AssetItem],
    batch_number: int,
    output_json: Path,
    contact_sheet_path: Path,
    project_root: Path,
    root: Path,
) -> None:
    payload = {
        "schema": "game32.aggregate_review.v2",
        "id": f"gothic_tiles_review_batch_{batch_number:04d}",
        "created_utc": iso_now(),
        "instructions": {
            "edit_this_file": True,
            "source_of_truth": "entries[].asset is the full manifest that will be written to each .game32.json sidecar.",
            "workflow": [
                "Review the contact sheet image.",
                "Edit each entry.review.action if needed.",
                "Edit each entry.review.target_png if moving/renaming the PNG.",
                "Edit each entry.asset directly. It contains the full game32.asset.v2 manifest.",
                "Save/overwrite this aggregate JSON.",
                "Return to terminal and press Enter.",
            ],
            "valid_actions": {
                "keep": "Write edited entry.asset to the sidecar manifest. Do not move PNG.",
                "move": "Move/rename PNG to review.target_png, then write edited entry.asset to target manifest.",
                "skip": "Do nothing to this entry.",
                "delete": "Move PNG, manifest, and optionally import sidecar to trash directory.",
            },
            "required_asset_blocks": [
                "schema",
                "id",
                "display_name",
                "source",
                "file",
                "classification",
                "placement",
                "collision",
                "procgen",
                "master_index",
            ],
            "path_rule": "review.target_png and asset.file.path may be res://, project-relative, or absolute. Project-relative is recommended.",
        },
        "project_root": project_root.as_posix(),
        "scan_root": rel_to_project(root, project_root),
        "contact_sheet": rel_to_project(contact_sheet_path, project_root),
        "batch_number": batch_number,
        "asset_count": len(batch_items),
        "entries": [
            build_review_entry(item=item, batch_index=idx, project_root=project_root)
            for idx, item in enumerate(batch_items)
        ],
    }

    write_json(output_json, payload)


def normalize_target_path(value: str | None, *, project_root: Path, fallback: Path) -> Path:
    if not value:
        return fallback

    s = str(value)

    if s.startswith("res://"):
        return project_root / "custodian" / s.removeprefix("res://")

    return resolve_under_project(s, project_root)


def asset_file_path_to_project_path(asset: dict[str, Any], project_root: Path, fallback: Path) -> Path:
    file_block = asset.get("file", {})
    if isinstance(file_block, dict):
        value = file_block.get("path")
        if value:
            return normalize_target_path(str(value), project_root=project_root, fallback=fallback)
    return fallback


def update_asset_for_new_location(
    *,
    asset: dict[str, Any],
    new_png: Path,
    project_root: Path,
    preserve_source_original_path: bool,
) -> dict[str, Any]:
    updated = copy.deepcopy(asset)

    updated["schema"] = updated.get("schema") or "game32.asset.v2"
    updated.setdefault("id", new_png.stem)
    updated.setdefault("display_name", display_name_from_stem(new_png.stem))

    updated.setdefault("file", {})
    updated["file"]["path"] = godot_res_path(new_png, project_root)
    updated["file"]["pixel_size"] = load_image_size(new_png) if new_png.exists() else updated["file"].get("pixel_size", {"w": 0, "h": 0})

    updated.setdefault("source", {})
    if not preserve_source_original_path:
        updated["source"]["original_path"] = godot_res_path(new_png, project_root)

    updated.setdefault("classification", {})
    updated.setdefault("placement", {})
    updated.setdefault("collision", {})
    updated.setdefault("procgen", {})

    # Fill missing fields after edits.
    normalized = normalize_asset_manifest(updated, new_png, project_root, discovered_index=int(updated.get("master_index", 0) or 0))
    normalized["updated_utc"] = iso_now()

    return normalized


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path

    parent = path.parent
    stem = path.stem
    suffix = path.suffix

    for i in range(1, 10000):
        candidate = parent / f"{stem}__dup{i:03d}{suffix}"
        if not candidate.exists():
            return candidate

    raise RuntimeError(f"Could not find unique path for {path}")


def move_or_copy_import_sidecar(
    *,
    old_png: Path,
    new_png: Path,
    delete_import: bool,
    move_import: bool,
) -> str:
    old_import = Path(str(old_png) + ".import")
    if not old_import.exists():
        return "no_import"

    if move_import:
        new_import = Path(str(new_png) + ".import")
        if new_import.exists():
            new_import = unique_path(new_import)
        shutil.move(str(old_import), str(new_import))
        return "moved_import"

    if delete_import:
        old_import.unlink()
        return "deleted_import"

    return "left_import"


def apply_review_batch(
    *,
    aggregate_json_path: Path,
    project_root: Path,
    trash_dir: Path,
    dry_run: bool,
    move_import: bool,
    preserve_source_original_path: bool,
) -> dict[str, Any]:
    data = read_json(aggregate_json_path)
    entries = data.get("entries", [])

    report = {
        "schema": "game32.aggregate_review_apply_report.v1",
        "aggregate_json": rel_to_project(aggregate_json_path, project_root),
        "applied_utc": iso_now(),
        "dry_run": dry_run,
        "results": [],
    }

    for entry in entries:
        batch_index = entry.get("batch_index")
        current = entry.get("current", {})
        review = entry.get("review", {})
        asset = entry.get("asset", {})

        action = str(review.get("action", "keep")).strip().lower()
        old_png = normalize_target_path(current.get("png"), project_root=project_root, fallback=Path("__missing__"))
        old_manifest = normalize_target_path(
            current.get("manifest") or current.get("canonical_manifest"),
            project_root=project_root,
            fallback=manifest_sidecar_for_png(old_png),
        )

        result: dict[str, Any] = {
            "batch_index": batch_index,
            "action": action,
            "old_png": rel_to_project(old_png, project_root),
            "old_manifest": rel_to_project(old_manifest, project_root),
            "status": "pending",
        }

        try:
            if action not in VALID_ACTIONS:
                result["status"] = "unknown_action"
                result["error"] = f"Invalid action: {action}"
                report["results"].append(result)
                continue

            if action == "skip":
                result["status"] = "skipped"
                report["results"].append(result)
                continue

            if not old_png.exists():
                result["status"] = "missing_png"
                report["results"].append(result)
                continue

            if action == "delete":
                target_png = unique_path(trash_dir / old_png.name)
                target_manifest = target_png.with_suffix(GAME32_SUFFIX)

                result["target_png"] = rel_to_project(target_png, project_root)
                result["target_manifest"] = rel_to_project(target_manifest, project_root)

                if not dry_run:
                    trash_dir.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(old_png), str(target_png))

                    if old_manifest.exists():
                        shutil.move(str(old_manifest), str(target_manifest))

                    old_import = Path(str(old_png) + ".import")
                    if old_import.exists():
                        shutil.move(str(old_import), str(unique_path(trash_dir / old_import.name)))

                result["status"] = "deleted_to_trash"
                report["results"].append(result)
                continue

            fallback_target = old_png
            if action == "move":
                fallback_target = asset_file_path_to_project_path(asset, project_root, fallback=old_png)

            target_png = normalize_target_path(
                review.get("target_png"),
                project_root=project_root,
                fallback=fallback_target,
            )

            if target_png.suffix.lower() != ".png":
                target_png = target_png.with_suffix(".png")

            if action == "keep":
                target_png = old_png

            target_manifest = normalize_target_path(
                review.get("target_manifest"),
                project_root=project_root,
                fallback=manifest_sidecar_for_png(target_png),
            )

            if target_manifest.suffix != ".json":
                target_manifest = manifest_sidecar_for_png(target_png)

            if target_png.name.endswith(".game32.png"):
                raise ValueError(f"Suspicious target_png name: {target_png}")

            result["target_png"] = rel_to_project(target_png, project_root)
            result["target_manifest"] = rel_to_project(target_manifest, project_root)

            if not dry_run:
                target_png.parent.mkdir(parents=True, exist_ok=True)
                target_manifest.parent.mkdir(parents=True, exist_ok=True)

                if action == "move" and old_png.resolve() != target_png.resolve():
                    if target_png.exists():
                        target_png = unique_path(target_png)
                        target_manifest = manifest_sidecar_for_png(target_png)
                        result["target_png"] = rel_to_project(target_png, project_root)
                        result["target_manifest"] = rel_to_project(target_manifest, project_root)

                    shutil.move(str(old_png), str(target_png))

                    # Remove or move stale import.
                    import_status = move_or_copy_import_sidecar(
                        old_png=old_png,
                        new_png=target_png,
                        delete_import=bool(review.get("delete_import", True)),
                        move_import=move_import,
                    )
                    result["import_status"] = import_status

                    # Remove old sidecar if it differs from target.
                    if old_manifest.exists() and old_manifest.resolve() != target_manifest.resolve():
                        old_manifest.unlink()

                # Write full edited manifest.
                final_asset = update_asset_for_new_location(
                    asset=asset,
                    new_png=target_png,
                    project_root=project_root,
                    preserve_source_original_path=preserve_source_original_path,
                )
                write_json(target_manifest, final_asset)

            result["status"] = "updated" if action == "keep" else "moved"
            report["results"].append(result)

        except Exception as exc:
            result["status"] = "error"
            result["error"] = str(exc)
            report["results"].append(result)

    return report


def chunked(items: list[AssetItem], size: int) -> list[list[AssetItem]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def summarize_report(report: dict[str, Any]) -> dict[str, int]:
    summary: dict[str, int] = {}
    for item in report.get("results", []):
        status = item.get("status", "unknown")
        summary[status] = summary.get(status, 0) + 1
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description="Review and recategorize full game32.asset.v2 PNG manifests in batches.")
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Repo root. Default: current working directory.",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("custodian/content/tiles/gothic"),
        help="Root folder to scan, relative to project root unless absolute.",
    )
    parser.add_argument(
        "--reference-manifest",
        type=Path,
        action="append",
        default=[],
        help="Optional aggregate/reference manifest with assets[] to hydrate missing sidecars. Can be passed multiple times.",
    )
    parser.add_argument("--batch-size", type=int, default=24)
    parser.add_argument("--columns", type=int, default=6)
    parser.add_argument("--thumb-size", type=int, default=160)
    parser.add_argument("--label-height", type=int, default=44)
    parser.add_argument("--padding", type=int, default=10)
    parser.add_argument(
        "--review-dir",
        type=Path,
        default=Path(".review_batches/game32_asset_review"),
        help="Review output dir inside scan root unless absolute.",
    )
    parser.add_argument(
        "--trash-dir",
        type=Path,
        default=Path(".review_batches/game32_asset_review/_trash"),
        help="Trash dir inside scan root unless absolute.",
    )
    parser.add_argument(
        "--include-without-manifest",
        action="store_true",
        help="Include PNGs without sidecars or reference manifest entries by generating full placeholder manifests.",
    )
    parser.add_argument(
        "--move-import",
        action="store_true",
        help="Move .png.import files when assets move. Default deletes stale imports so Godot regenerates them.",
    )
    parser.add_argument(
        "--preserve-source-original-path",
        action="store_true",
        default=True,
        help="Keep source.original_path as historical provenance when moving assets. Default true.",
    )
    parser.add_argument(
        "--update-source-original-path",
        dest="preserve_source_original_path",
        action="store_false",
        help="Rewrite source.original_path to the new PNG path when moving.",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--start-batch", type=int, default=0)
    parser.add_argument("--only-batch", type=int, default=-1)
    parser.add_argument("--no-clipboard", action="store_true")
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Non-interactive: write aggregate JSON and immediately apply without waiting for edits.",
    )
    parser.add_argument(
        "--exclude-review",
        action="store_true",
        default=True,
        help="Exclude _review_ PNGs and review directories.",
    )

    args = parser.parse_args()

    project_root = args.project_root.expanduser().resolve()
    root = args.root.expanduser()
    if not root.is_absolute():
        root = project_root / root
    root = root.resolve()

    if not root.exists():
        eprint(f"ERROR: root does not exist: {root}")
        return 2

    reference_paths = [
        resolve_under_project(p, project_root).resolve()
        for p in args.reference_manifest
    ]

    reference_index = build_reference_index(reference_paths, project_root)

    review_dir = args.review_dir.expanduser()
    if not review_dir.is_absolute():
        review_dir = root / review_dir
    review_dir.mkdir(parents=True, exist_ok=True)

    trash_dir = args.trash_dir.expanduser()
    if not trash_dir.is_absolute():
        trash_dir = root / trash_dir

    items = discover_pngs(
        root=root,
        project_root=project_root,
        include_without_manifest=args.include_without_manifest,
        exclude_review=args.exclude_review,
        reference_index=reference_index,
    )

    if not items:
        print("No PNG assets found.")
        return 0

    batches = chunked(items, args.batch_size)

    print(f"Project root: {project_root}")
    print(f"Scan root: {root}")
    print(f"Reference assets indexed: {len(reference_index)}")
    print(f"Discovered PNG assets: {len(items)}")
    print(f"Batches: {len(batches)}")
    print(f"Review dir: {review_dir}")

    for batch_number, batch_items in enumerate(batches):
        if batch_number < args.start_batch:
            continue
        if args.only_batch >= 0 and batch_number != args.only_batch:
            continue

        contact_sheet = review_dir / f"batch_{batch_number:04d}_contact.png"
        aggregate_json = review_dir / f"batch_{batch_number:04d}_aggregate.game32.review.json"
        apply_report_json = review_dir / f"batch_{batch_number:04d}_apply_report.json"

        make_contact_sheet(
            batch_items,
            contact_sheet,
            project_root=project_root,
            thumb_size=args.thumb_size,
            columns=args.columns,
            label_height=args.label_height,
            padding=args.padding,
        )

        write_aggregate_review_json(
            batch_items=batch_items,
            batch_number=batch_number,
            output_json=aggregate_json,
            contact_sheet_path=contact_sheet,
            project_root=project_root,
            root=root,
        )

        print("\n" + "=" * 96)
        print(f"Batch {batch_number:04d}/{len(batches) - 1:04d}")
        print(f"Contact sheet:  {contact_sheet}")
        print(f"Aggregate JSON: {aggregate_json}")
        print("=" * 96)

        if not args.no_clipboard:
            clipboard_copy_png(contact_sheet)

        if not args.yes:
            print("\nReview workflow:")
            print("  1. View/paste the contact sheet from clipboard.")
            print("  2. Edit the aggregate JSON.")
            print("  3. Edit entries[].asset directly for full game32 fields.")
            print("  4. Set entries[].review.action to keep/move/skip/delete.")
            print("  5. Save the aggregate JSON.")
            print("  6. Return here and press Enter.")
            response = input("\nPress Enter to apply this batch, 's' to skip, or 'q' to quit: ").strip().lower()

            if response == "q":
                print("Stopped before applying this batch.")
                return 0
            if response == "s":
                print("Skipped batch.")
                continue

        report = apply_review_batch(
            aggregate_json_path=aggregate_json,
            project_root=project_root,
            trash_dir=trash_dir,
            dry_run=args.dry_run,
            move_import=args.move_import,
            preserve_source_original_path=args.preserve_source_original_path,
        )
        write_json(apply_report_json, report)

        print(f"Apply report: {apply_report_json}")
        print("Batch summary:")
        for status, count in sorted(summarize_report(report).items()):
            print(f"  {status}: {count}")

        if args.only_batch >= 0:
            break

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
