#!/usr/bin/env python3
"""
CUSTODIAN game32 asset review tool.

Purpose:
  Replace one-off patch scripts with a repeatable workflow:

    1. Build a contact-sheet PNG for a batch of .png assets.
    2. Write a full aggregate game32 review JSON.
    3. Copy the contact sheet image to clipboard.
    4. Accept compact correction JSON from human/LLM review.
    5. Apply corrections to the aggregate JSON.
    6. Apply aggregate JSON to actual .game32.json sidecars.
    7. Move/rename/delete assets when requested.

Core rule:
  entries[].asset is the source of truth. It contains the full
  game32.asset.v2 manifest that will be written to the sidecar.

Main commands:

  Create a review batch:
    python custodian/tools/asset_pipeline/game32_review.py batch \\
      --root custodian/content/tiles/gothic \\
      --batch 0 \\
      --batch-size 24 \\
      --include-without-manifest

  Apply compact corrections to an aggregate JSON:
    python custodian/tools/asset_pipeline/game32_review.py corrections \\
      --aggregate custodian/content/tiles/gothic/.review_batches/game32_asset_review/batch_0000_aggregate.game32.review.json \\
      --corrections /tmp/batch_0000_corrections.json

  Apply aggregate JSON to sidecar manifests:
    python custodian/tools/asset_pipeline/game32_review.py apply \\
      --aggregate custodian/content/tiles/gothic/.review_batches/game32_asset_review/batch_0000_aggregate.game32.review.json

  Interactive next batch:
    python custodian/tools/asset_pipeline/game32_review.py next \\
      --root custodian/content/tiles/gothic \\
      --batch 0 \\
      --batch-size 24 \\
      --include-without-manifest

Compact correction JSON example:

{
  "schema": "game32.review_corrections.v1",
  "entries": {
    "0": {
      "profile": "floor_overlay",
      "display_name": "Blood Floor Detail 001",
      "semantic_role": "blood_floor_decal",
      "tags_add": ["blood", "gore", "distress"],
      "procgen_uses": ["floor_detail", "blood_detail", "combat_aftermath"],
      "weight": 8
    }
  }
}

Rule correction JSON example:

{
  "schema": "game32.review_corrections.v1",
  "rules": [
    {
      "match_filename": "floor_detail_*.png",
      "profile": "floor_overlay",
      "semantic_role": "floor_overlay_or_decal",
      "tags_add": ["floor", "decal", "overlay", "walkable", "no_collision"],
      "procgen_uses": ["floor_detail", "environmental_storytelling"],
      "weight": 10
    }
  ]
}
"""

from __future__ import annotations

import argparse
import copy
import fnmatch
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
VALID_ACTIONS = {"keep", "move", "skip", "delete"}
REVIEW_DIR_NAME = ".review_batches/game32_asset_review"
TRASH_DIR_NAME = ".review_batches/game32_asset_review/_trash"


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


def write_json_atomic(path: Path, payload: Any) -> None:
    """
    Atomic-ish JSON write:
      - write to sibling temp file
      - fsync
      - replace target
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f"{path.name}.tmp-{os.getpid()}")
    with tmp.open("w", encoding="utf-8") as f:
        f.write(json.dumps(payload, indent=2, sort_keys=False) + "\n")
        f.flush()
        os.fsync(f.fileno())
    tmp.replace(path)


def backup_file(path: Path) -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup = path.with_name(f"{path.name}.bak-{stamp}")
    shutil.copy2(path, backup)
    return backup


def project_root_default() -> Path:
    return Path.cwd()


def resolve_project_path(value: str | Path, project_root: Path) -> Path:
    p = Path(value).expanduser()
    if p.is_absolute():
        return p
    if str(value).startswith("res://"):
        return project_root / "custodian" / str(value).removeprefix("res://")
    return project_root / p


def rel_to_project(path: Path, project_root: Path) -> str:
    try:
        return path.resolve().relative_to(project_root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def path_to_res(path: Path, project_root: Path) -> str:
    try:
        rel = path.resolve().relative_to((project_root / "custodian").resolve())
        return "res://" + rel.as_posix()
    except ValueError:
        return rel_to_project(path, project_root)


def normalize_manifest_path_key(value: str | Path | None, project_root: Path) -> str:
    """
    Normalize mixed path styles to the master-manifest comparable key:

      res://content/foo.png                    -> content/foo.png
      custodian/content/foo.png                -> content/foo.png
      /repo/custodian/content/foo.png          -> content/foo.png
      content/foo.png                          -> content/foo.png
    """
    if value is None:
        return ""

    s = str(value).strip()
    if not s:
        return ""

    if s.startswith("res://"):
        s = s.removeprefix("res://")
    else:
        p = Path(s).expanduser()
        if p.is_absolute():
            try:
                s = p.resolve().relative_to(project_root.resolve()).as_posix()
            except ValueError:
                s = p.as_posix()

    if s.startswith("custodian/"):
        s = s.removeprefix("custodian/")
    return Path(s).as_posix()


def manifest_sidecar_for_png(png: Path) -> Path:
    return png.with_suffix(GAME32_SUFFIX)


def find_manifest_for_png(png: Path) -> Path | None:
    candidates = [
        png.with_suffix(GAME32_SUFFIX),
        Path(str(png) + GAME32_SUFFIX),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def image_size(path: Path) -> dict[str, int]:
    try:
        with Image.open(path) as img:
            w, h = img.size
            return {"w": int(w), "h": int(h)}
    except Exception:
        return {"w": 0, "h": 0}


def title_from_stem(stem: str) -> str:
    return stem.replace("_", " ").replace("-", " ").title()


def res_to_relative(res_path: str) -> str:
    """Normalise a res://content/... path to a relative posix path."""
    return res_path.replace("res://", "")


def path_matches_review(
    master_file_path: str, review_png: str, project_root_str: str
) -> bool:
    """Return True if a master manifest file path corresponds to a review entry.

    Master paths are in res://content/... format.
    Review paths are in custodian/content/... or absolute format.
    Both are normalized to content/... for comparison.
    """
    master_rel = res_to_relative(master_file_path)
    master_rel = Path(master_rel).as_posix()

    review_rel = review_png
    if project_root_str and review_rel.startswith(project_root_str):
        review_rel = review_rel[len(project_root_str):].lstrip("/")
    if review_rel.startswith("custodian/"):
        review_rel = review_rel[len("custodian/"):]
    review_rel = Path(review_rel).as_posix()

    return master_rel == review_rel


def unique_list(values: list[Any]) -> list[str]:
    """Return a stable de-duplicated list of non-empty string values."""
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        s = str(value).strip()
        if not s or s in seen:
            continue
        seen.add(s)
        out.append(s)
    return out


def infer_section_subtype(path: Path) -> tuple[str, str]:
    parts = [p.lower() for p in path.parts]

    section = "tiles"
    if "props" in parts:
        section = "props"
    elif "structures" in parts:
        section = "structures"
    elif "doors" in parts:
        section = "doors"
    elif "sprites" in parts:
        section = "sprites"
    elif "tiles" in parts:
        section = "tiles"

    subtype = "uncategorized"
    for candidate in [
        "floors",
        "floor",
        "decals",
        "ritual",
        "walls",
        "wall_tiles",
        "wall_tops_edges",
        "wall_vertical_slice",
        "wall_horizontal_or_cap",
        "wall_corner_or_end",
        "doors",
        "props",
        "structures",
        "vault",
    ]:
        if candidate in parts:
            subtype = candidate
            break

    return section, subtype


def infer_classification(path: Path) -> dict[str, Any]:
    p = path.as_posix().lower()
    name = path.name.lower()

    if "/decals/" in p or "decal" in name:
        return {
            "asset_type": "tiles",
            "semantic_role": "floor_overlay_or_decal",
            "placement_layer": "floor_overlay",
            "tags": ["gothic", "floor", "decal", "overlay", "walkable", "no_collision"],
            "review_status": "needs_review",
        }

    if "/floors/" in p or "floor" in name:
        return {
            "asset_type": "tiles",
            "semantic_role": "walkable_floor_variant",
            "placement_layer": "ground",
            "tags": ["gothic", "floor", "walkable"],
            "review_status": "needs_review",
        }

    if "wall_top" in p or "wall_horizontal_or_cap" in p or "cap" in name:
        return {
            "asset_type": "walls",
            "semantic_role": "wall_top_or_cap",
            "placement_layer": "wall_cap",
            "tags": ["gothic", "wall", "cap", "top", "blocking"],
            "review_status": "needs_review",
        }

    if "wall" in p or "wall" in name:
        return {
            "asset_type": "walls",
            "semantic_role": "wall_segment",
            "placement_layer": "wall",
            "tags": ["gothic", "wall", "blocking"],
            "review_status": "needs_review",
        }

    if "door" in p or "gate" in p or "door" in name or "gate" in name:
        return {
            "asset_type": "doors",
            "semantic_role": "door_or_gate",
            "placement_layer": "door",
            "tags": ["gothic", "door", "gate", "blocking"],
            "review_status": "needs_review",
        }

    if "prop" in p:
        return {
            "asset_type": "props",
            "semantic_role": "environment_prop",
            "placement_layer": "prop",
            "tags": ["gothic", "prop", "environment"],
            "review_status": "needs_review",
        }

    return {
        "asset_type": "tiles",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "ground",
        "tags": ["needs_review"],
        "review_status": "needs_review",
    }


def infer_placement(path: Path, pixel_size: dict[str, int], classification: dict[str, Any]) -> dict[str, Any]:
    tile_size = 32
    w = max(1, int(pixel_size.get("w", 0)))
    h = max(1, int(pixel_size.get("h", 0)))

    layer = classification.get("placement_layer", "")
    asset_type = classification.get("asset_type", "")

    floorlike = layer in {"ground", "ground_detail", "floor", "floor_overlay"}
    y_sort = layer in {"wall", "wall_cap", "door", "prop", "structure"} or asset_type in {
        "walls",
        "doors",
        "props",
        "structures",
    }

    if floorlike:
        origin_mode = "top_left"
        pivot = {"x": 0, "y": 0}
    else:
        origin_mode = "bottom_center"
        pivot = {"x": w // 2, "y": h}

    return {
        "tile_size": tile_size,
        "footprint_tiles": {
            "w": max(1, math.ceil(w / tile_size)),
            "h": max(1, math.ceil(h / tile_size)),
        },
        "origin_mode": origin_mode,
        "snap": "tile",
        "allow_mirror_x": False,
        "allow_rotation": False,
        "y_sort": bool(y_sort),
        "pivot_px": pivot,
        "review_status": "needs_review",
    }


def infer_collision(classification: dict[str, Any]) -> dict[str, Any]:
    layer = classification.get("placement_layer", "")
    asset_type = classification.get("asset_type", "")
    blocks = layer in {"wall", "wall_cap", "door", "structure", "prop"} or asset_type in {
        "walls",
        "doors",
        "structures",
    }

    return {
        "blocks_movement": bool(blocks),
        "blocks_sight": bool(layer in {"wall", "door", "structure"} or asset_type in {"walls", "doors", "structures"}),
        "cover_value": 2 if blocks else 0,
        "review_status": "needs_review",
        "collision_shape": "tile_rect" if blocks else "none",
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
        uses = ["floor_detail", "environmental_storytelling"]
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
        "review_status": "needs_review",
        "supports_gothic_compound": True,
    }


def placeholder_asset_for_png(png: Path, project_root: Path, index: int) -> dict[str, Any]:
    pixel = image_size(png)
    section, subtype = infer_section_subtype(png)
    classification = infer_classification(png)

    return {
        "schema": "game32.asset.v2",
        "id": png.stem,
        "display_name": title_from_stem(png.stem),
        "source": {
            "master_sheet": None,
            "original_path": path_to_res(png, project_root),
            "section": section,
            "subtype": subtype,
            "source_rect_px": {
                "x": 0,
                "y": 0,
                "w": pixel["w"],
                "h": pixel["h"],
            },
            "review_source": "placeholder_generated_from_png_path",
            "review_status": "needs_review",
        },
        "file": {
            "path": path_to_res(png, project_root),
            "pixel_size": pixel,
        },
        "classification": classification,
        "placement": infer_placement(png, pixel, classification),
        "collision": infer_collision(classification),
        "procgen": infer_procgen(classification),
        "master_index": index + 1,
    }


def deep_merge_missing(primary: Any, fallback: Any) -> Any:
    if isinstance(primary, dict) and isinstance(fallback, dict):
        for key, value in fallback.items():
            if key not in primary or primary[key] is None:
                primary[key] = copy.deepcopy(value)
            else:
                primary[key] = deep_merge_missing(primary[key], value)
        return primary
    return primary


def normalize_asset(asset: dict[str, Any], png: Path, project_root: Path, index: int) -> dict[str, Any]:
    fallback = placeholder_asset_for_png(png, project_root, index)
    out = deep_merge_missing(copy.deepcopy(asset), fallback)

    out["schema"] = out.get("schema") or "game32.asset.v2"
    out["id"] = out.get("id") or png.stem
    out["display_name"] = out.get("display_name") or title_from_stem(png.stem)

    out.setdefault("source", {})
    out.setdefault("file", {})
    out.setdefault("classification", {})
    out.setdefault("placement", {})
    out.setdefault("collision", {})
    out.setdefault("procgen", {})

    out["file"].setdefault("path", path_to_res(png, project_root))
    out["file"].setdefault("pixel_size", image_size(png))

    if "master_index" not in out:
        out["master_index"] = index + 1

    return out


def load_asset_for_png(png: Path, project_root: Path, index: int) -> tuple[dict[str, Any], Path | None]:
    sidecar = find_manifest_for_png(png)
    if sidecar:
        try:
            data = read_json(sidecar)
            if isinstance(data, dict) and data.get("schema") == "game32.asset.v2":
                return normalize_asset(data, png, project_root, index), sidecar
        except Exception as exc:
            eprint(f"WARNING: failed reading sidecar {sidecar}: {exc}")

    return placeholder_asset_for_png(png, project_root, index), sidecar


DEFAULT_MASTER_MANIFEST = Path("custodian/content/tiles/gothic/gothic_master_sheet.game32.json")


def load_master_manifest(manifest_path: Path | None, project_root: Path) -> dict[str, Any] | None:
    """Load the master manifest, resolving relative to project_root if needed."""
    if manifest_path is None:
        return None
    p = manifest_path.expanduser()
    if not p.is_absolute():
        p = project_root / p
    if not p.exists():
        eprint(f"WARNING: master manifest not found: {p}")
        return None
    try:
        return read_json(p)
    except Exception as exc:
        eprint(f"WARNING: failed to load master manifest {p}: {exc}")
        return None


def resolve_master_manifest_path(manifest_path: Path | None, project_root: Path) -> Path | None:
    if manifest_path is None:
        return None
    p = manifest_path.expanduser()
    if not p.is_absolute():
        p = project_root / p
    return p.resolve()


def build_master_index(master_data: dict[str, Any], project_root: Path) -> dict[str, dict[str, Any]]:
    """
    Build lookup keys for master assets using file.path and source.original_path.
    This tolerates res://, custodian-relative, and content-relative variants.
    """
    out: dict[str, dict[str, Any]] = {}
    for asset in master_data.get("assets", []):
        if not isinstance(asset, dict):
            continue
        for value in (
            asset.get("file", {}).get("path"),
            asset.get("source", {}).get("original_path"),
        ):
            key = normalize_manifest_path_key(value, project_root)
            if key:
                out[key] = asset
    return out


def is_already_reviewed_in_master(
    png_path: Path, master_data: dict[str, Any] | None, project_root: Path
) -> bool:
    """Check if this PNG's asset already has review_status=reviewed in the master manifest."""
    if master_data is None:
        return False

    png_res = path_to_res(png_path, project_root)
    png_key = normalize_manifest_path_key(png_res, project_root)
    for asset in master_data.get("assets", []):
        fp = normalize_manifest_path_key(asset.get("file", {}).get("path", ""), project_root)
        if fp != png_key:
            continue
        cls = asset.get("classification", {})
        if cls.get("review_status") == "reviewed":
            return True
        col = asset.get("collision", {})
        if col.get("review_status") == "reviewed":
            return True
        # Any of the three blocks being reviewed counts as reviewed
        return False
    return False


def is_already_reviewed_in_sidecar(png_path: Path) -> bool:
    """Check if this PNG has a sidecar already marked reviewed."""
    sidecar = find_manifest_for_png(png_path)
    if sidecar is None:
        return False
    try:
        data = read_json(sidecar)
        if not isinstance(data, dict):
            return False
        cls = data.get("classification", {})
        col = data.get("collision", {})
        pg = data.get("procgen", {})
        # Consider reviewed if any game32 block has review_status=reviewed
        return (
            cls.get("review_status") == "reviewed"
            or col.get("review_status") == "reviewed"
            or pg.get("review_status") == "reviewed"
        )
    except Exception:
        return False


def discover_pngs(
    root: Path,
    project_root: Path,
    include_without_manifest: bool,
    master_data: dict[str, Any] | None = None,
    only_unreviewed: bool = False,
) -> list[AssetItem]:
    pngs: list[Path] = []
    for path in root.rglob("*.png"):
        rel_parts = path.relative_to(root).parts

        if any(part.startswith(".") for part in rel_parts):
            continue
        if ".review_batches" in rel_parts:
            continue
        if path.name.startswith("_review_"):
            continue
        if path.name in {"gothic_master_sheet.png", "gothic_tilesheet.png"}:
            continue
        if path.name.endswith(".import"):
            continue

        sidecar = find_manifest_for_png(path)
        if not include_without_manifest and sidecar is None:
            continue

        if only_unreviewed:
            if is_already_reviewed_in_master(path, master_data, project_root):
                continue
            if is_already_reviewed_in_sidecar(path):
                continue

        pngs.append(path)

    pngs = sorted(pngs, key=lambda p: p.relative_to(root).as_posix())

    items: list[AssetItem] = []
    for idx, png in enumerate(pngs):
        asset, manifest_path = load_asset_for_png(png, project_root, idx)
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
    output: Path,
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
    sheet = make_checkerboard(columns * cell_w, rows * cell_h)

    draw = ImageDraw.Draw(sheet)

    for batch_idx, item in enumerate(items):
        row = batch_idx // columns
        col = batch_idx % columns
        x0 = col * cell_w
        y0 = row * cell_h

        classification = item.asset.get("classification", {})
        role = classification.get("semantic_role") or classification.get("placement_layer") or item.png_path.parent.name

        draw.rectangle([x0, y0, x0 + cell_w - 1, y0 + cell_h - 1], outline=(70, 70, 70, 255), width=2)

        try:
            img = Image.open(item.png_path).convert("RGBA")
        except Exception:
            img = Image.new("RGBA", (thumb_size, thumb_size), (160, 0, 0, 255))

        fitted = fit_image(img, thumb_size, thumb_size)
        px = x0 + padding + (thumb_size - fitted.width) // 2
        py = y0 + padding + (thumb_size - fitted.height) // 2
        sheet.alpha_composite(fitted, (px, py))

        draw.rectangle([x0 + 4, y0 + 4, x0 + 48, y0 + 28], fill=(0, 0, 0, 220))
        draw.text((x0 + 8, y0 + 5), f"#{batch_idx:02d}", fill=(255, 255, 255, 255), font=index_font)

        label_y = y0 + padding + thumb_size + 4
        draw.rectangle([x0 + 2, label_y - 2, x0 + cell_w - 3, y0 + cell_h - 3], fill=(0, 0, 0, 220))
        draw.text((x0 + 6, label_y), item.png_path.name[:34], fill=(255, 255, 255, 255), font=font)
        draw.text((x0 + 6, label_y + 16), str(role)[:34], fill=(200, 220, 255, 255), font=font)

    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def copy_png_to_clipboard(path: Path) -> bool:
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
            eprint(f"WARNING: clipboard copy failed with {cmd[0]}: {exc}")

    eprint("WARNING: no clipboard image tool found. Install wl-clipboard or xclip.")
    return False


def chunk(items: list[AssetItem], size: int) -> list[list[AssetItem]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def build_aggregate(
    batch_items: list[AssetItem],
    batch_number: int,
    project_root: Path,
    root: Path,
    contact_sheet: Path,
) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []

    for idx, item in enumerate(batch_items):
        canonical = manifest_sidecar_for_png(item.png_path)

        entries.append(
            {
                "batch_index": idx,
                "current": {
                    "png": item.png_rel,
                    "manifest": item.manifest_rel,
                    "canonical_manifest": rel_to_project(canonical, project_root),
                    "filename": item.png_path.name,
                    "parent_dir": rel_to_project(item.png_path.parent, project_root),
                    "exists": item.png_path.exists(),
                },
                "review": {
                    "action": "keep",
                    "target_png": item.png_rel,
                    "target_manifest": rel_to_project(canonical, project_root),
                    "delete_import": True,
                    "notes": "",
                },
                "asset": copy.deepcopy(item.asset),
            }
        )

    return {
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
                "Run corrections/apply or return to terminal and press Enter.",
            ],
            "valid_actions": {
                "keep": "Write edited entry.asset to the sidecar manifest. Do not move PNG.",
                "move": "Move/rename PNG to review.target_png, then write edited entry.asset to target manifest.",
                "skip": "Do nothing to this entry.",
                "delete": "Move PNG, manifest, and optionally import sidecar to trash directory.",
            },
            "compact_corrections": {
                "preferred": "Use game32.review_corrections.v1 to edit only changed fields.",
                "commands": [
                    "game32_review.py corrections --aggregate <aggregate.json> --corrections <corrections.json>",
                    "game32_review.py apply --aggregate <aggregate.json>",
                ],
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
        "contact_sheet": rel_to_project(contact_sheet, project_root),
        "batch_number": batch_number,
        "asset_count": len(batch_items),
        "entries": entries,
    }


def batch_command(args: argparse.Namespace) -> int:
    project_root = args.project_root.expanduser().resolve()
    root = resolve_project_path(args.root, project_root).resolve()

    master_data = load_master_manifest(
        getattr(args, "master_manifest", None),
        project_root,
    )

    items = discover_pngs(
        root, project_root, args.include_without_manifest,
        master_data=master_data,
        only_unreviewed=getattr(args, "only_unreviewed", False),
    )
    batches = chunk(items, args.batch_size)

    if not batches:
        print("No assets found.")
        return 0

    if args.batch < 0 or args.batch >= len(batches):
        raise IndexError(f"Batch {args.batch} out of range. Found {len(batches)} batches.")

    review_dir = resolve_review_dir(args.review_dir, root)
    contact = review_dir / f"batch_{args.batch:04d}_contact.png"
    aggregate = review_dir / f"batch_{args.batch:04d}_aggregate.game32.review.json"

    batch_items = batches[args.batch]

    make_contact_sheet(
        batch_items,
        contact,
        thumb_size=args.thumb_size,
        columns=args.columns,
        label_height=args.label_height,
        padding=args.padding,
    )

    payload = build_aggregate(batch_items, args.batch, project_root, root, contact)
    write_json(aggregate, payload)

    print(f"Assets found: {len(items)}")
    print(f"Batches: {len(batches)}")
    print(f"Batch: {args.batch}")
    print(f"Contact sheet: {contact}")
    print(f"Aggregate JSON: {aggregate}")

    if not args.no_clipboard:
        copy_png_to_clipboard(contact)

    return 0


def resolve_review_dir(value: str | Path, root: Path) -> Path:
    p = Path(value).expanduser()
    if p.is_absolute():
        return p
    return root / p


def normalize_target(value: str | None, project_root: Path, fallback: Path) -> Path:
    if not value:
        return fallback
    s = str(value)
    if s.startswith("res://"):
        return project_root / "custodian" / s.removeprefix("res://")
    p = Path(s).expanduser()
    if p.is_absolute():
        return p
    return project_root / p


def update_asset_location(asset: dict[str, Any], png: Path, project_root: Path, preserve_source: bool) -> dict[str, Any]:
    out = copy.deepcopy(asset)

    out["schema"] = out.get("schema") or "game32.asset.v2"
    out.setdefault("id", png.stem)
    out.setdefault("display_name", title_from_stem(png.stem))

    out.setdefault("file", {})
    out["file"]["path"] = path_to_res(png, project_root)
    out["file"]["pixel_size"] = image_size(png) if png.exists() else out["file"].get("pixel_size", {"w": 0, "h": 0})

    out.setdefault("source", {})
    if not preserve_source:
        out["source"]["original_path"] = path_to_res(png, project_root)

    out.setdefault("classification", {})
    out.setdefault("placement", {})
    out.setdefault("collision", {})
    out.setdefault("procgen", {})

    return out


def merge_reviewed_asset_into_master(master_entry: dict[str, Any], final_asset: dict[str, Any], action: str) -> None:
    """
    Merge reviewed fields into a master manifest asset entry while preserving
    master-sheet provenance such as source.sheet / source.bbox_px / visual index.
    """
    for field in ("id", "display_name"):
        if field in final_asset:
            master_entry[field] = copy.deepcopy(final_asset[field])

    for field in ("classification", "placement", "collision", "procgen"):
        if field in final_asset:
            value = copy.deepcopy(final_asset[field])
            if isinstance(value, dict) and "review_status" not in value:
                value["review_status"] = "reviewed"
            master_entry[field] = value

    master_source = master_entry.setdefault("source", {})
    final_source = final_asset.get("source", {})
    if isinstance(final_source, dict):
        # Preserve source.sheet / bbox / visual index, but keep review metadata.
        for key in ("review_source", "review_status", "section", "subtype"):
            if key in final_source:
                master_source[key] = copy.deepcopy(final_source[key])
        master_source.setdefault("review_source", "human_llm_compact_review")
        master_source.setdefault("review_status", "reviewed")

    master_file = master_entry.setdefault("file", {})
    final_file = final_asset.get("file", {})
    if isinstance(final_file, dict):
        if "pixel_size" in final_file:
            master_file["pixel_size"] = copy.deepcopy(final_file["pixel_size"])
        if action == "move" and final_file.get("path"):
            master_file["path"] = final_file["path"]


def resolve_target_manifest_path(pathish: str | None, project_root: Path, fallback: Path) -> Path:
    if not pathish:
        return fallback
    p = normalize_target(pathish, project_root, fallback)
    if p.suffix.lower() != ".json":
        return manifest_sidecar_for_png(p)
    return p


def move_import_sidecar(old_png: Path, new_png: Path, delete_import: bool, move_import: bool) -> str:
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
    raise RuntimeError(f"Could not create unique path for {path}")


def apply_command(args: argparse.Namespace) -> int:
    project_root = args.project_root.expanduser().resolve()
    aggregate_path = resolve_project_path(args.aggregate, project_root).resolve()
    data = read_json(aggregate_path)

    trash_dir = resolve_project_path(args.trash_dir, project_root).resolve()
    results: list[dict[str, Any]] = []

    # ── Master manifest integration ──
    master_data = None
    master_path = None
    master_backup = None
    if hasattr(args, "master_manifest") and args.master_manifest:
        master_path = resolve_master_manifest_path(args.master_manifest, project_root)
        master_data = load_master_manifest(args.master_manifest, project_root)

    master_by_path: dict[str, dict[str, Any]] = {}
    if master_data is not None:
        master_by_path = build_master_index(master_data, project_root)

    master_updates: list[dict[str, Any]] = []

    for entry in data.get("entries", []):
        current = entry.get("current", {})
        review = entry.get("review", {})
        asset = entry.get("asset", {})

        action = str(review.get("action", "keep")).lower().strip()
        old_png = normalize_target(current.get("png"), project_root, Path("__missing__"))
        old_manifest = normalize_target(
            current.get("manifest") or current.get("canonical_manifest"),
            project_root,
            manifest_sidecar_for_png(old_png),
        )

        result = {
            "batch_index": entry.get("batch_index"),
            "action": action,
            "old_png": rel_to_project(old_png, project_root),
            "old_manifest": rel_to_project(old_manifest, project_root),
            "status": "pending",
        }

        try:
            if action not in VALID_ACTIONS:
                result["status"] = "invalid_action"
                results.append(result)
                continue

            if action == "skip":
                result["status"] = "skipped"
                results.append(result)
                continue

            if not old_png.exists():
                result["status"] = "missing_png"
                results.append(result)
                continue

            if action == "delete":
                target_png = unique_path(trash_dir / old_png.name)
                target_manifest = target_png.with_suffix(GAME32_SUFFIX)

                result["target_png"] = rel_to_project(target_png, project_root)
                result["target_manifest"] = rel_to_project(target_manifest, project_root)

                if not args.dry_run:
                    trash_dir.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(old_png), str(target_png))
                    if old_manifest.exists():
                        shutil.move(str(old_manifest), str(target_manifest))
                    old_import = Path(str(old_png) + ".import")
                    if old_import.exists():
                        shutil.move(str(old_import), str(unique_path(trash_dir / old_import.name)))

                result["status"] = "deleted_to_trash"
                results.append(result)
                continue

            target_png = normalize_target(review.get("target_png"), project_root, old_png)
            if target_png.suffix.lower() != ".png":
                target_png = target_png.with_suffix(".png")

            if action == "keep":
                target_png = old_png

            result["target_png"] = rel_to_project(target_png, project_root)

            if not args.dry_run:
                target_png.parent.mkdir(parents=True, exist_ok=True)

                if action == "move" and old_png.resolve() != target_png.resolve():
                    if target_png.exists():
                        target_png = unique_path(target_png)
                    result["target_png"] = rel_to_project(target_png, project_root)
                    shutil.move(str(old_png), str(target_png))

                    result["import_status"] = move_import_sidecar(
                        old_png,
                        target_png,
                        delete_import=bool(review.get("delete_import", True)),
                        move_import=args.move_import,
                    )

            # Resolve target manifest only after any unique-path move finalizes target_png.
            target_manifest = resolve_target_manifest_path(
                review.get("target_manifest"),
                project_root,
                manifest_sidecar_for_png(target_png),
            )
            result["target_manifest"] = rel_to_project(target_manifest, project_root)

            final_asset = update_asset_location(
                asset,
                target_png,
                project_root,
                preserve_source=args.preserve_source_original_path,
            )

            if not args.dry_run:
                target_manifest.parent.mkdir(parents=True, exist_ok=True)

                if action == "move" and old_manifest.exists() and old_manifest.resolve() != target_manifest.resolve():
                    old_manifest.unlink()
                write_json(target_manifest, final_asset)

            # Track for master manifest update (both dry-run and real)
            if master_data is not None and action in ("keep", "move"):
                master_updates.append({
                    "review_png": current.get("png", ""),
                    "final_asset": final_asset,
                    "action": action,
                    "target_png_rel": result["target_png"],
                    "target_manifest_rel": result["target_manifest"],
                    "target_manifest_abs": str(target_manifest),
                    "master_matched": False,
                })

            result["status"] = "updated" if action == "keep" else "moved"
            results.append(result)

        except Exception as exc:
            result["status"] = "error"
            result["error"] = str(exc)
            results.append(result)

    # ── Apply to master manifest ──
    master_applied = 0
    master_skipped = 0
    master_unmatched: list[str] = []
    if master_data is not None and master_updates:
        for mu in master_updates:
            review_png = mu["review_png"]
            final_asset = mu["final_asset"]
            action = mu["action"]

            match_keys = [
                normalize_manifest_path_key(review_png, project_root),
                normalize_manifest_path_key(mu.get("target_png_rel"), project_root),
                normalize_manifest_path_key(final_asset.get("file", {}).get("path"), project_root),
                normalize_manifest_path_key(final_asset.get("source", {}).get("original_path"), project_root),
            ]

            master_entry = None
            for key in match_keys:
                if key in master_by_path:
                    master_entry = master_by_path[key]
                    break

            if master_entry is None:
                master_skipped += 1
                master_unmatched.append(review_png)
                continue

            merge_reviewed_asset_into_master(master_entry, final_asset, action)
            mu["master_matched"] = True
            master_applied += 1

        # Write updated master manifest
        if not args.dry_run and master_applied > 0 and master_path is not None:
            master_backup = backup_file(master_path)
            write_json_atomic(master_path, master_data)

    # ── Cleanup per-PNG sidecar manifests ──
    cleanup_deleted = 0
    cleanup_skipped_dry_run = 0
    cleanup_skipped_not_mastered = 0
    cleanup_skipped_due_errors = 0

    error_statuses = {"error", "missing_png", "invalid_action"}
    had_apply_errors = any(r.get("status") in error_statuses for r in results)
    cleanup_allowed = (
        getattr(args, "cleanup", False)
        and master_data is not None
        and not had_apply_errors
    )

    if getattr(args, "cleanup", False) and master_data is not None:
        for mu in master_updates:
            if had_apply_errors:
                cleanup_skipped_due_errors += 1
                continue
            if not mu.get("master_matched"):
                cleanup_skipped_not_mastered += 1
                continue
            target_manifest_abs = Path(mu["target_manifest_abs"])
            if target_manifest_abs.exists():
                if not args.dry_run:
                    target_manifest_abs.unlink()
                    cleanup_deleted += 1
                else:
                    cleanup_skipped_dry_run += 1

    # ── Build report ──
    report: dict[str, Any] = {
        "schema": "game32.aggregate_review_apply_report.v1",
        "aggregate": rel_to_project(aggregate_path, project_root),
        "applied_utc": iso_now(),
        "dry_run": args.dry_run,
        "results": results,
    }

    if master_data is not None:
        report["master_manifest"] = {
            "path": str(master_path) if master_path else None,
            "backup": str(master_backup) if master_backup else None,
            "assets_applied": master_applied,
            "assets_skipped_unmatched": master_skipped,
            "unmatched": master_unmatched,
            "total_assets": len(master_data.get("assets", [])),
        }

    if getattr(args, "cleanup", False) and master_data is not None:
        report["cleanup"] = {
            "sidecars_deleted": cleanup_deleted,
            "sidecars_skipped_dry_run": cleanup_skipped_dry_run,
            "sidecars_skipped_not_mastered": cleanup_skipped_not_mastered,
            "sidecars_skipped_due_errors": cleanup_skipped_due_errors,
            "cleanup_allowed": cleanup_allowed,
        }

    report_path = aggregate_path.with_name(aggregate_path.stem + ".apply_report.json")
    write_json(report_path, report)

    print(f"Apply report: {report_path}")
    print_summary(results)

    if master_data is not None:
        print(f"  Master manifest: {master_applied} applied, {master_skipped} unmatched")
        if master_backup:
            print(f"  Master backup: {master_backup}")
        if getattr(args, "cleanup", False):
            if not args.dry_run:
                print(f"  Cleanup: {cleanup_deleted} sidecar(s) deleted")
                if cleanup_skipped_not_mastered:
                    print(f"  Cleanup skipped: {cleanup_skipped_not_mastered} sidecar(s) not represented in master")
                if cleanup_skipped_due_errors:
                    print(f"  Cleanup skipped: {cleanup_skipped_due_errors} sidecar(s) due apply errors")
            else:
                print(f"  Cleanup: {cleanup_skipped_dry_run} sidecar(s) would be deleted (dry-run)")

    return 0


def print_summary(results: list[dict[str, Any]]) -> None:
    counts: dict[str, int] = {}
    for r in results:
        status = str(r.get("status", "unknown"))
        counts[status] = counts.get(status, 0) + 1

    print("Summary:")
    for key, value in sorted(counts.items()):
        print(f"  {key}: {value}")


def profile_floor_overlay(entry: dict[str, Any], correction: dict[str, Any]) -> None:
    asset = entry.setdefault("asset", {})
    classification = asset.setdefault("classification", {})
    placement = asset.setdefault("placement", {})
    collision = asset.setdefault("collision", {})
    procgen = asset.setdefault("procgen", {})

    classification["asset_type"] = correction.get("asset_type", "tiles")
    classification["placement_layer"] = correction.get("placement_layer", "floor_overlay")
    classification["review_status"] = "reviewed"

    placement["tile_size"] = correction.get("tile_size", placement.get("tile_size", 32))
    placement["origin_mode"] = "top_left"
    placement["snap"] = "tile"
    placement["allow_mirror_x"] = bool(correction.get("allow_mirror_x", placement.get("allow_mirror_x", False)))
    placement["allow_rotation"] = bool(correction.get("allow_rotation", placement.get("allow_rotation", False)))
    placement["y_sort"] = False
    placement["pivot_px"] = {"x": 0, "y": 0}
    placement["review_status"] = "reviewed"

    collision["blocks_movement"] = False
    collision["blocks_sight"] = False
    collision["cover_value"] = 0
    collision["collision_shape"] = "none"
    collision["review_status"] = "reviewed"

    procgen["can_spawn_indoor"] = correction.get("can_spawn_indoor", procgen.get("can_spawn_indoor", True))
    procgen["can_spawn_outdoor"] = correction.get("can_spawn_outdoor", procgen.get("can_spawn_outdoor", True))
    procgen["supports_gothic_compound"] = correction.get(
        "supports_gothic_compound",
        procgen.get("supports_gothic_compound", True),
    )
    procgen["review_status"] = "reviewed"


def profile_floor_base(entry: dict[str, Any], correction: dict[str, Any]) -> None:
    asset = entry.setdefault("asset", {})
    classification = asset.setdefault("classification", {})
    placement = asset.setdefault("placement", {})
    collision = asset.setdefault("collision", {})
    procgen = asset.setdefault("procgen", {})

    classification["asset_type"] = correction.get("asset_type", "tiles")
    classification["placement_layer"] = correction.get("placement_layer", "ground")
    classification["review_status"] = "reviewed"

    placement["origin_mode"] = "top_left"
    placement["snap"] = "tile"
    placement["allow_mirror_x"] = bool(correction.get("allow_mirror_x", False))
    placement["allow_rotation"] = bool(correction.get("allow_rotation", False))
    placement["y_sort"] = False
    placement["pivot_px"] = {"x": 0, "y": 0}
    placement["review_status"] = "reviewed"

    collision["blocks_movement"] = False
    collision["blocks_sight"] = False
    collision["cover_value"] = 0
    collision["collision_shape"] = "none"
    collision["review_status"] = "reviewed"

    procgen["can_spawn_indoor"] = correction.get("can_spawn_indoor", procgen.get("can_spawn_indoor", True))
    procgen["can_spawn_outdoor"] = correction.get("can_spawn_outdoor", procgen.get("can_spawn_outdoor", True))
    procgen["supports_gothic_compound"] = correction.get("supports_gothic_compound", True)
    procgen["review_status"] = "reviewed"


def profile_wall(entry: dict[str, Any], correction: dict[str, Any]) -> None:
    asset = entry.setdefault("asset", {})
    classification = asset.setdefault("classification", {})
    placement = asset.setdefault("placement", {})
    collision = asset.setdefault("collision", {})
    procgen = asset.setdefault("procgen", {})

    layer = correction.get("placement_layer", "wall")
    classification["asset_type"] = correction.get("asset_type", "walls")
    classification["placement_layer"] = layer
    classification["review_status"] = "reviewed"

    placement["origin_mode"] = correction.get("origin_mode", "bottom_center")
    placement["snap"] = "tile"
    placement["allow_mirror_x"] = bool(correction.get("allow_mirror_x", False))
    placement["allow_rotation"] = bool(correction.get("allow_rotation", False))
    placement["y_sort"] = True
    placement.setdefault("pivot_px", {"x": 0, "y": 0})
    placement["review_status"] = "reviewed"

    collision["blocks_movement"] = bool(correction.get("blocks_movement", True))
    collision["blocks_sight"] = bool(correction.get("blocks_sight", layer == "wall"))
    collision["cover_value"] = int(correction.get("cover_value", 2))
    collision["collision_shape"] = correction.get("collision_shape", "tile_rect")
    collision["review_status"] = "reviewed"

    procgen["can_spawn_indoor"] = correction.get("can_spawn_indoor", True)
    procgen["can_spawn_outdoor"] = correction.get("can_spawn_outdoor", True)
    procgen["supports_gothic_compound"] = correction.get("supports_gothic_compound", True)
    procgen["review_status"] = "reviewed"


def profile_prop(entry: dict[str, Any], correction: dict[str, Any]) -> None:
    asset = entry.setdefault("asset", {})
    classification = asset.setdefault("classification", {})
    placement = asset.setdefault("placement", {})
    collision = asset.setdefault("collision", {})
    procgen = asset.setdefault("procgen", {})

    classification["asset_type"] = correction.get("asset_type", "props")
    classification["placement_layer"] = correction.get("placement_layer", "prop")
    classification["review_status"] = "reviewed"

    placement["origin_mode"] = correction.get("origin_mode", "bottom_center")
    placement["snap"] = correction.get("snap", "tile_or_free")
    placement["allow_mirror_x"] = bool(correction.get("allow_mirror_x", False))
    placement["allow_rotation"] = bool(correction.get("allow_rotation", False))
    placement["y_sort"] = True
    placement["review_status"] = "reviewed"

    collision["blocks_movement"] = bool(correction.get("blocks_movement", True))
    collision["blocks_sight"] = bool(correction.get("blocks_sight", False))
    collision["cover_value"] = int(correction.get("cover_value", 1 if collision["blocks_movement"] else 0))
    collision["collision_shape"] = correction.get("collision_shape", "footprint")
    collision["review_status"] = "reviewed"

    procgen["can_spawn_indoor"] = correction.get("can_spawn_indoor", True)
    procgen["can_spawn_outdoor"] = correction.get("can_spawn_outdoor", True)
    procgen["supports_gothic_compound"] = correction.get("supports_gothic_compound", True)
    procgen["review_status"] = "reviewed"


PROFILES = {
    "floor_overlay": profile_floor_overlay,
    "floor_base": profile_floor_base,
    "wall": profile_wall,
    "wall_cap": profile_wall,
    "prop": profile_prop,
}


def get_entry_filename(entry: dict[str, Any]) -> str:
    current = entry.get("current", {})
    if current.get("filename"):
        return str(current["filename"])
    png = current.get("png") or entry.get("review", {}).get("target_png", "")
    return Path(str(png)).name


def apply_one_correction(entry: dict[str, Any], correction: dict[str, Any]) -> None:
    review = entry.setdefault("review", {})
    asset = entry.setdefault("asset", {})
    source = asset.setdefault("source", {})
    classification = asset.setdefault("classification", {})
    procgen = asset.setdefault("procgen", {})

    if "action" in correction:
        review["action"] = correction["action"]

    if "target_png" in correction:
        review["target_png"] = correction["target_png"]

    if "target_manifest" in correction:
        review["target_manifest"] = correction["target_manifest"]

    if "review_notes" in correction:
        review["notes"] = correction["review_notes"]

    if "notes" in correction and "review_notes" not in correction:
        review["notes"] = correction["notes"]

    profile = correction.get("profile")
    if profile:
        func = PROFILES.get(str(profile))
        if func is None:
            raise ValueError(f"Unknown profile: {profile}")
        func(entry, correction)

    if "id" in correction:
        asset["id"] = correction["id"]

    if "display_name" in correction:
        asset["display_name"] = correction["display_name"]

    if "asset_type" in correction:
        classification["asset_type"] = correction["asset_type"]

    if "semantic_role" in correction:
        classification["semantic_role"] = correction["semantic_role"]

    if "placement_layer" in correction:
        classification["placement_layer"] = correction["placement_layer"]

    if "category" in correction:
        classification["category"] = correction["category"]

    if "tags" in correction:
        classification["tags"] = unique_list(correction["tags"])

    existing_tags = classification.get("tags", [])
    if "tags_add" in correction:
        existing_tags = unique_list(list(existing_tags) + list(correction["tags_add"]))

    if "tags_remove" in correction:
        remove = {str(x) for x in correction["tags_remove"]}
        existing_tags = [tag for tag in existing_tags if tag not in remove]

    classification["tags"] = unique_list(existing_tags)

    if "procgen_uses" in correction:
        procgen["uses"] = unique_list(correction["procgen_uses"])

    if "uses" in correction:
        procgen["uses"] = unique_list(correction["uses"])

    if "uses_add" in correction:
        procgen["uses"] = unique_list(list(procgen.get("uses", [])) + list(correction["uses_add"]))

    if "uses_remove" in correction:
        remove_uses = {str(x) for x in correction["uses_remove"]}
        procgen["uses"] = [u for u in procgen.get("uses", []) if u not in remove_uses]

    for key in [
        "weight",
        "can_spawn_indoor",
        "can_spawn_outdoor",
        "supports_gothic_compound",
    ]:
        if key in correction:
            procgen[key] = correction[key]

    if "collision" in correction and isinstance(correction["collision"], dict):
        asset.setdefault("collision", {}).update(correction["collision"])

    if "placement" in correction and isinstance(correction["placement"], dict):
        asset.setdefault("placement", {}).update(correction["placement"])

    source["review_source"] = correction.get("review_source", "human_llm_compact_review")
    source["review_status"] = correction.get("review_status", "reviewed")
    classification["review_status"] = correction.get("review_status", "reviewed")
    procgen["review_status"] = correction.get("review_status", "reviewed")
    asset.setdefault("collision", {})["review_status"] = correction.get("review_status", "reviewed")
    asset.setdefault("placement", {})["review_status"] = correction.get("review_status", "reviewed")


def corrections_command(args: argparse.Namespace) -> int:
    project_root = args.project_root.expanduser().resolve()
    aggregate_path = resolve_project_path(args.aggregate, project_root).resolve()
    corrections_path = resolve_project_path(args.corrections, project_root).resolve()

    aggregate = read_json(aggregate_path)
    corrections = read_json(corrections_path)

    entries = aggregate.get("entries", [])
    changed = 0

    for rule in corrections.get("rules", []):
        pattern = rule.get("match_filename")
        if not pattern:
            continue
        for entry in entries:
            filename = get_entry_filename(entry)
            if fnmatch.fnmatch(filename, pattern):
                apply_one_correction(entry, rule)
                changed += 1

    raw_entries = corrections.get("entries", {})
    if isinstance(raw_entries, dict):
        iterable = []
        for key, correction in raw_entries.items():
            c = dict(correction)
            c["batch_index"] = int(key)
            iterable.append(c)
    elif isinstance(raw_entries, list):
        iterable = raw_entries
    else:
        iterable = []

    for correction in iterable:
        idx = correction.get("batch_index")
        if idx is None:
            continue
        idx = int(idx)
        if idx < 0 or idx >= len(entries):
            eprint(f"WARNING: correction batch_index out of range: {idx}")
            continue
        apply_one_correction(entries[idx], correction)
        changed += 1

    write_json(aggregate_path, aggregate)
    print(f"Applied {changed} compact corrections to {aggregate_path}")

    if args.apply:
        apply_args = argparse.Namespace(
            project_root=project_root,
            aggregate=aggregate_path,
            trash_dir=args.trash_dir,
            dry_run=args.dry_run,
            move_import=args.move_import,
            preserve_source_original_path=args.preserve_source_original_path,
            master_manifest=getattr(args, "master_manifest", None),
            cleanup=getattr(args, "cleanup", False),
        )
        return apply_command(apply_args)

    return 0


def validate_command(args: argparse.Namespace) -> int:
    project_root = args.project_root.expanduser().resolve()
    aggregate_path = resolve_project_path(args.aggregate, project_root).resolve()
    data = read_json(aggregate_path)

    errors: list[str] = []
    if data.get("schema") != "game32.aggregate_review.v2":
        errors.append("Aggregate schema is not game32.aggregate_review.v2")

    for i, entry in enumerate(data.get("entries", [])):
        asset = entry.get("asset", {})
        for key in [
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
        ]:
            if key not in asset:
                errors.append(f"entry {i}: missing asset.{key}")

        if asset.get("schema") != "game32.asset.v2":
            errors.append(f"entry {i}: asset.schema is not game32.asset.v2")

        classification = asset.get("classification", {})
        if not classification.get("semantic_role"):
            errors.append(f"entry {i}: missing classification.semantic_role")

        if not classification.get("placement_layer"):
            errors.append(f"entry {i}: missing classification.placement_layer")

    if errors:
        print("Validation failed:")
        for err in errors:
            print(f"  - {err}")
        return 1

    print(f"Validation passed: {aggregate_path}")
    return 0


def next_command(args: argparse.Namespace) -> int:
    rc = batch_command(args)
    if rc != 0:
        return rc

    project_root = args.project_root.expanduser().resolve()
    root = resolve_project_path(args.root, project_root).resolve()
    review_dir = resolve_review_dir(args.review_dir, root)
    aggregate = review_dir / f"batch_{args.batch:04d}_aggregate.game32.review.json"

    print()
    print("Review workflow:")
    print("  1. Paste/view the contact sheet from clipboard.")
    print("  2. Ask for compact corrections JSON.")
    print("  3. Run: game32_review.py corrections --aggregate <aggregate> --corrections <corrections.json>")
    print("  4. Press Enter here to apply the aggregate.")
    print()
    print(f"Aggregate: {aggregate}")

    response = input("Press Enter to apply now, 's' to skip, or 'q' to quit: ").strip().lower()
    if response == "q":
        return 0
    if response == "s":
        print("Skipped apply.")
        return 0

    apply_args = argparse.Namespace(
        project_root=project_root,
        aggregate=aggregate,
        trash_dir=args.trash_dir,
        dry_run=args.dry_run,
        move_import=args.move_import,
        preserve_source_original_path=args.preserve_source_original_path,
        master_manifest=getattr(args, "master_manifest", None),
        cleanup=getattr(args, "cleanup", False),
    )
    return apply_command(apply_args)


def write_example_corrections_command(args: argparse.Namespace) -> int:
    example = {
        "schema": "game32.review_corrections.v1",
        "notes": "Compact corrections file. Use batch_index from the contact sheet labels.",
        "rules": [
            {
                "match_filename": "floor_detail_*.png",
                "profile": "floor_overlay",
                "semantic_role": "floor_overlay_or_decal",
                "tags_add": ["gothic", "floor", "decal", "overlay", "walkable", "no_collision"],
                "procgen_uses": ["floor_detail", "environmental_storytelling"],
                "weight": 10,
                "review_notes": "Reviewed as non-blocking floor overlay/decal.",
            }
        ],
        "entries": {
            "0": {
                "profile": "floor_overlay",
                "display_name": "Blood Floor Detail 001",
                "semantic_role": "blood_floor_decal",
                "tags_add": ["blood", "gore", "distress"],
                "procgen_uses": ["floor_detail", "blood_detail", "combat_aftermath"],
                "weight": 8,
            }
        },
    }

    out = resolve_project_path(args.output, args.project_root.expanduser().resolve())
    write_json(out, example)
    print(f"Wrote example corrections: {out}")
    return 0


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--project-root",
        type=Path,
        default=project_root_default(),
        help="Repo root. Default: current working directory.",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="CUSTODIAN game32 asset review tool.")
    sub = parser.add_subparsers(dest="command", required=True)

    p_batch = sub.add_parser("batch", help="Create contact sheet + aggregate review JSON.")
    add_common_args(p_batch)
    p_batch.add_argument("--root", type=Path, required=True)
    p_batch.add_argument("--batch", type=int, default=0)
    p_batch.add_argument("--batch-size", type=int, default=24)
    p_batch.add_argument("--columns", type=int, default=6)
    p_batch.add_argument("--thumb-size", type=int, default=160)
    p_batch.add_argument("--label-height", type=int, default=44)
    p_batch.add_argument("--padding", type=int, default=10)
    p_batch.add_argument("--review-dir", type=Path, default=Path(REVIEW_DIR_NAME))
    p_batch.add_argument("--include-without-manifest", action="store_true")
    p_batch.add_argument("--only-unreviewed", action="store_true",
                         help="Skip assets already marked reviewed in the master manifest or sidecar.")
    p_batch.add_argument("--master-manifest", type=Path, default=None,
                         help="Path to the master manifest for cross-referencing review status. "
                              "Relative to project root unless absolute. "
                              f"Default: {DEFAULT_MASTER_MANIFEST}")
    p_batch.add_argument("--no-clipboard", action="store_true")
    p_batch.set_defaults(func=batch_command)

    p_next = sub.add_parser("next", help="Create batch, copy contact sheet, wait, then apply.")
    add_common_args(p_next)
    p_next.add_argument("--root", type=Path, required=True)
    p_next.add_argument("--batch", type=int, default=0)
    p_next.add_argument("--batch-size", type=int, default=24)
    p_next.add_argument("--columns", type=int, default=6)
    p_next.add_argument("--thumb-size", type=int, default=160)
    p_next.add_argument("--label-height", type=int, default=44)
    p_next.add_argument("--padding", type=int, default=10)
    p_next.add_argument("--review-dir", type=Path, default=Path(REVIEW_DIR_NAME))
    p_next.add_argument("--trash-dir", type=Path, default=Path(TRASH_DIR_NAME))
    p_next.add_argument("--include-without-manifest", action="store_true")
    p_next.add_argument("--only-unreviewed", action="store_true",
                        help="Skip assets already marked reviewed in the master manifest or sidecar.")
    p_next.add_argument("--master-manifest", type=Path, default=None,
                        help="Path to the master manifest for cross-referencing review status "
                             "and updating during the apply step.")
    p_next.add_argument("--cleanup", action="store_true",
                        help="Delete per-PNG .game32.json sidecar manifests after applying "
                             "to the master manifest (requires --master-manifest).")
    p_next.add_argument("--no-clipboard", action="store_true")
    p_next.add_argument("--dry-run", action="store_true")
    p_next.add_argument("--move-import", action="store_true")
    p_next.add_argument("--preserve-source-original-path", action="store_true", default=True)
    p_next.add_argument("--update-source-original-path", dest="preserve_source_original_path", action="store_false")
    p_next.set_defaults(func=next_command)

    p_apply = sub.add_parser("apply", help="Apply aggregate review JSON to assets/sidecars.")
    add_common_args(p_apply)
    p_apply.add_argument("--aggregate", type=Path, required=True)
    p_apply.add_argument("--trash-dir", type=Path, default=Path(TRASH_DIR_NAME))
    p_apply.add_argument("--dry-run", action="store_true")
    p_apply.add_argument("--move-import", action="store_true")
    p_apply.add_argument("--preserve-source-original-path", action="store_true", default=True)
    p_apply.add_argument("--update-source-original-path", dest="preserve_source_original_path", action="store_false")
    p_apply.add_argument("--master-manifest", type=Path, default=None,
                         help="Path to the master sheet manifest to update. "
                              "Relative to project root unless absolute. "
                              f"Default: {DEFAULT_MASTER_MANIFEST}")
    p_apply.add_argument("--cleanup", action="store_true",
                         help="Delete per-PNG .game32.json sidecar manifests after applying "
                              "to the master manifest (requires --master-manifest).")
    p_apply.set_defaults(func=apply_command)

    p_corr = sub.add_parser("corrections", help="Apply compact correction JSON to aggregate JSON.")
    add_common_args(p_corr)
    p_corr.add_argument("--aggregate", type=Path, required=True)
    p_corr.add_argument("--corrections", type=Path, required=True)
    p_corr.add_argument("--apply", action="store_true", help="Apply sidecar writes after correcting aggregate.")
    p_corr.add_argument("--trash-dir", type=Path, default=Path(TRASH_DIR_NAME))
    p_corr.add_argument("--dry-run", action="store_true")
    p_corr.add_argument("--move-import", action="store_true")
    p_corr.add_argument("--preserve-source-original-path", action="store_true", default=True)
    p_corr.add_argument("--update-source-original-path", dest="preserve_source_original_path", action="store_false")
    p_corr.add_argument("--master-manifest", type=Path, default=None,
                        help="Path to the master sheet manifest to update when --apply is used.")
    p_corr.add_argument("--cleanup", action="store_true",
                        help="Delete per-PNG sidecar manifests after applying to the master manifest. "
                             "Only meaningful with --apply and --master-manifest.")
    p_corr.set_defaults(func=corrections_command)

    p_validate = sub.add_parser("validate", help="Validate aggregate review JSON.")
    add_common_args(p_validate)
    p_validate.add_argument("--aggregate", type=Path, required=True)
    p_validate.set_defaults(func=validate_command)

    p_example = sub.add_parser("example-corrections", help="Write an example compact corrections JSON.")
    add_common_args(p_example)
    p_example.add_argument("--output", type=Path, default=Path("/tmp/game32_review_corrections.example.json"))
    p_example.set_defaults(func=write_example_corrections_command)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
