#!/usr/bin/env python3
"""
Interactive CUSTODIAN game32 asset review batcher.

What it does:
  1. Scans a root folder for .png files.
  2. Pairs each .png with its .game32.json sidecar when available.
  3. Builds a contact sheet for a sane batch of PNGs.
  4. Writes an aggregate editable game32 review JSON for that batch.
  5. Copies the contact sheet PNG to the system clipboard.
  6. Waits for you to edit/overwrite the aggregate JSON.
  7. Re-reads the edited aggregate JSON.
  8. Applies moves/renames/category updates from the edited entries.
  9. Continues to the next batch.

Default target:
  custodian/content/tiles/gothic

Typical use:
  cd /home/braydenchaffee/Projects/CUSTODIAN

  python custodian/tools/asset_pipeline/review_game32_png_batches.py \\
    --root custodian/content/tiles/gothic \\
    --batch-size 24

Aggregate JSON edit model:
  In each entry, edit one or more of:

    "review": {
      "action": "keep" | "move" | "skip" | "delete",
      "new_relative_dir": "custodian/content/tiles/gothic/floors",
      "new_filename": "gothic_floor_dark_earth_01.png",
      "new_id": "gothic_floor_dark_earth_01",
      "new_asset_type": "tiles",
      "new_semantic_role": "gothic_floor",
      "new_placement_layer": "floor",
      "new_category": "floor",
      "new_tags": ["gothic", "floor", "tile"],
      "notes": ""
    }

  If action is "move", the script moves:
    - the .png
    - the .game32.json
    - optionally the .png.import file, if --move-import is set

  By default it does NOT move .png.import, because Godot import sidecars often contain
  old source paths. The safer default is to let Godot regenerate imports.
"""

from __future__ import annotations

import argparse
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

IMAGE_EXT = ".png"
GAME32_SUFFIX = ".game32.json"


DEFAULT_EXCLUDES = {
    "_review_gothic_contact_sheet.png",
}


@dataclass
class AssetItem:
    png_path: Path
    manifest_path: Path | None
    png_rel: str
    manifest_rel: str | None
    index: int
    manifest: dict[str, Any]


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {
            "_load_error": str(exc),
            "_raw_path": str(path),
        }


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8"
    )


def rel_to_project(path: Path, project_root: Path) -> str:
    try:
        return path.resolve().relative_to(project_root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def find_manifest_for_png(png: Path) -> Path | None:
    # Supports both:
    #   thing.game32.json
    #   thing.png.game32.json
    candidate_1 = png.with_suffix(GAME32_SUFFIX)
    candidate_2 = Path(str(png) + GAME32_SUFFIX)

    if candidate_1.exists():
        return candidate_1
    if candidate_2.exists():
        return candidate_2
    return None


def discover_pngs(
    root: Path, project_root: Path, include_without_manifest: bool, exclude_review: bool
) -> list[AssetItem]:
    pngs: list[Path] = []

    for path in root.rglob("*.png"):
        if any(part.startswith(".") for part in path.relative_to(root).parts):
            continue
        if path.name.endswith(".import"):
            continue
        if exclude_review and (
            path.name in DEFAULT_EXCLUDES or path.name.startswith("_review_")
        ):
            continue
        if ".review_batches" in path.parts:
            continue

        pngs.append(path)

    pngs = sorted(pngs, key=lambda p: p.relative_to(root).as_posix())

    items: list[AssetItem] = []
    for idx, png in enumerate(pngs):
        manifest_path = find_manifest_for_png(png)

        if manifest_path is None and not include_without_manifest:
            continue

        manifest = load_json(manifest_path) if manifest_path else {}

        items.append(
            AssetItem(
                png_path=png,
                manifest_path=manifest_path,
                png_rel=rel_to_project(png, project_root),
                manifest_rel=(
                    rel_to_project(manifest_path, project_root)
                    if manifest_path
                    else None
                ),
                index=idx,
                manifest=manifest,
            )
        )

    return items


def safe_font(size: int = 14) -> ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/LiberationSans-Regular.ttf",
    ]
    for candidate in candidates:
        p = Path(candidate)
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


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


def make_checkerboard(w: int, h: int, cell: int = 16) -> Image.Image:
    img = Image.new("RGBA", (w, h), (238, 238, 238, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            if ((x // cell) + (y // cell)) % 2:
                draw.rectangle(
                    [x, y, x + cell - 1, y + cell - 1], fill=(210, 210, 210, 255)
                )
    return img


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

    rows = math.ceil(len(items) / columns)
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

        id_text = f"#{batch_idx:02d}"
        draw.rectangle([x0 + 4, y0 + 4, x0 + 48, y0 + 28], fill=(0, 0, 0, 190))
        draw.text((x0 + 8, y0 + 5), id_text, fill=(255, 255, 255, 255), font=index_font)

        filename = item.png_path.name
        parent = item.png_path.parent.name
        label_1 = filename[:32]
        label_2 = parent[:32]

        label_y = y0 + padding + thumb_size + 4
        draw.rectangle(
            [x0 + 2, label_y - 2, x0 + cell_w - 3, y0 + cell_h - 3],
            fill=(0, 0, 0, 190),
        )
        draw.text((x0 + 6, label_y), label_1, fill=(255, 255, 255, 255), font=font)
        draw.text((x0 + 6, label_y + 16), label_2, fill=(200, 220, 255, 255), font=font)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)


def clipboard_copy_png(path: Path) -> bool:
    """
    Copy image file bytes to clipboard.

    Hyprland/Wayland:
      wl-copy --type image/png < file

    X11 fallback:
      xclip -selection clipboard -t image/png -i file
    """
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
    item: AssetItem, batch_index: int, project_root: Path, review_root: Path
) -> dict[str, Any]:
    manifest = item.manifest if isinstance(item.manifest, dict) else {}

    existing_classification = (
        manifest.get("classification", {})
        if isinstance(manifest.get("classification", {}), dict)
        else {}
    )
    existing_game32 = (
        manifest.get("game32", {})
        if isinstance(manifest.get("game32", {}), dict)
        else {}
    )

    guessed_asset_type = existing_classification.get("asset_type")
    guessed_semantic_role = existing_classification.get("semantic_role")
    guessed_placement_layer = existing_classification.get("placement_layer")
    guessed_category = existing_classification.get("category")

    if not guessed_asset_type:
        guessed_asset_type = guess_asset_type(item.png_path)
    if not guessed_placement_layer:
        guessed_placement_layer = guess_placement_layer(item.png_path)

    return {
        "batch_index": batch_index,
        "current": {
            "png": item.png_rel,
            "manifest": item.manifest_rel,
            "filename": item.png_path.name,
            "parent_dir": rel_to_project(item.png_path.parent, project_root),
            "exists": item.png_path.exists(),
        },
        "review": {
            "action": "keep",
            "new_relative_dir": rel_to_project(item.png_path.parent, project_root),
            "new_filename": item.png_path.name,
            "new_id": manifest.get("id") or item.png_path.stem,
            "new_asset_type": guessed_asset_type,
            "new_semantic_role": guessed_semantic_role,
            "new_placement_layer": guessed_placement_layer,
            "new_category": guessed_category,
            "new_tags": existing_classification.get("tags", []),
            "notes": "",
        },
        "manifest": manifest,
        "game32_summary": {
            "tile_size_px": existing_game32.get("tile_size_px"),
            "tile_semantics": existing_game32.get("tile_semantics"),
            "collision": existing_game32.get("collision"),
            "procgen": existing_game32.get("procgen"),
        },
    }


def guess_asset_type(path: Path) -> str:
    p = path.as_posix().lower()
    if "/floors" in p or "/floor" in p or "/decals" in p or "/floor_overlay" in p:
        return "tiles"
    if "/wall" in p:
        return "walls"
    if "/props" in p:
        return "props"
    if "/doors" in p:
        return "doors"
    return "tiles"


def guess_placement_layer(path: Path) -> str:
    p = path.as_posix().lower()
    if "/floors" in p or "/floor" in p:
        return "floor"
    if "/decals" in p or "/floor_overlay" in p:
        return "floor_overlay"
    if "/wall_tops" in p or "/wall_horizontal_or_cap" in p:
        return "wall_cap"
    if "/wall" in p:
        return "wall"
    return "tile"


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
        "schema": "game32.aggregate_review.v1",
        "id": f"gothic_tiles_review_batch_{batch_number:04d}",
        "created_utc": iso_now(),
        "instructions": {
            "edit_this_file": True,
            "workflow": [
                "Review the contact sheet image.",
                "For each entry, edit review.action and review.new_* fields as needed.",
                "Save/overwrite this aggregate JSON.",
                "Return to terminal and press Enter.",
            ],
            "valid_actions": {
                "keep": "Update manifest metadata in place but do not move the asset.",
                "move": "Move/rename PNG and manifest to review.new_relative_dir / review.new_filename.",
                "skip": "Do nothing to this entry.",
                "delete": "Move PNG and manifest into the trash directory, not permanent deletion.",
            },
            "path_rule": "review.new_relative_dir is relative to the project root unless absolute.",
        },
        "project_root": project_root.as_posix(),
        "scan_root": rel_to_project(root, project_root),
        "contact_sheet": rel_to_project(contact_sheet_path, project_root),
        "batch_number": batch_number,
        "asset_count": len(batch_items),
        "entries": [
            build_review_entry(item, idx, project_root, root)
            for idx, item in enumerate(batch_items)
        ],
    }

    write_json(output_json, payload)


def normalize_new_path(
    new_relative_dir: str, new_filename: str, project_root: Path
) -> Path:
    target_dir = Path(new_relative_dir).expanduser()
    if not target_dir.is_absolute():
        target_dir = project_root / target_dir
    return target_dir / new_filename


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path

    stem = path.stem
    suffix = path.suffix
    parent = path.parent

    for i in range(1, 10000):
        candidate = parent / f"{stem}__dup{i:03d}{suffix}"
        if not candidate.exists():
            return candidate

    raise RuntimeError(f"Could not create unique path for {path}")


def update_manifest_metadata(
    manifest: dict[str, Any],
    *,
    review: dict[str, Any],
    new_png_path: Path,
    new_manifest_path: Path,
    project_root: Path,
) -> dict[str, Any]:
    m = dict(manifest) if isinstance(manifest, dict) else {}

    if review.get("new_id"):
        m["id"] = review["new_id"]

    m.setdefault("schema", "game32.asset.v2")
    m.setdefault("updated_utc", iso_now())
    m["updated_utc"] = iso_now()

    if "name" not in m or review.get("new_filename"):
        m["name"] = new_png_path.stem

    classification = m.get("classification")
    if not isinstance(classification, dict):
        classification = {}

    for review_key, manifest_key in [
        ("new_asset_type", "asset_type"),
        ("new_semantic_role", "semantic_role"),
        ("new_placement_layer", "placement_layer"),
        ("new_category", "category"),
    ]:
        value = review.get(review_key)
        if value is not None and value != "":
            classification[manifest_key] = value

    if isinstance(review.get("new_tags"), list):
        classification["tags"] = review["new_tags"]

    m["classification"] = classification

    file_block = m.get("file")
    if not isinstance(file_block, dict):
        file_block = {}
    file_block["path"] = rel_to_project(new_png_path, project_root)
    file_block["filename"] = new_png_path.name
    file_block["format"] = "png"
    file_block["has_alpha"] = True
    m["file"] = file_block

    review_notes = review.get("notes")
    if review_notes:
        m.setdefault("review", {})
        if isinstance(m["review"], dict):
            m["review"]["notes"] = review_notes
            m["review"]["last_reviewed_utc"] = iso_now()

    source = m.get("source")
    if not isinstance(source, dict):
        source = {}
    source.setdefault(
        "asset_review_script",
        "custodian/tools/asset_pipeline/review_game32_png_batches.py",
    )
    source["last_recategorized_utc"] = iso_now()
    m["source"] = source

    return m


def apply_review_batch(
    *,
    aggregate_json_path: Path,
    project_root: Path,
    trash_dir: Path,
    dry_run: bool,
    move_import: bool,
) -> dict[str, Any]:
    data = json.loads(aggregate_json_path.read_text(encoding="utf-8"))
    entries = data.get("entries", [])

    report = {
        "aggregate_json": rel_to_project(aggregate_json_path, project_root),
        "applied_utc": iso_now(),
        "dry_run": dry_run,
        "results": [],
    }

    for entry in entries:
        current = entry.get("current", {})
        review = entry.get("review", {})
        manifest = entry.get("manifest", {})

        action = str(review.get("action", "keep")).strip().lower()
        old_png = project_root / current.get("png", "")
        old_manifest = (
            project_root / current.get("manifest", "")
            if current.get("manifest")
            else find_manifest_for_png(old_png)
        )

        result: dict[str, Any] = {
            "batch_index": entry.get("batch_index"),
            "action": action,
            "old_png": rel_to_project(old_png, project_root),
            "old_manifest": (
                rel_to_project(old_manifest, project_root) if old_manifest else None
            ),
            "status": "pending",
        }

        try:
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

                result["new_png"] = rel_to_project(target_png, project_root)
                result["new_manifest"] = rel_to_project(target_manifest, project_root)

                if not dry_run:
                    trash_dir.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(old_png), str(target_png))
                    if old_manifest and old_manifest.exists():
                        shutil.move(str(old_manifest), str(target_manifest))

                    import_path = Path(str(old_png) + ".import")
                    if import_path.exists():
                        import_trash = unique_path(trash_dir / import_path.name)
                        shutil.move(str(import_path), str(import_trash))

                result["status"] = "deleted_to_trash"
                report["results"].append(result)
                continue

            if action not in {"keep", "move"}:
                result["status"] = f"unknown_action:{action}"
                report["results"].append(result)
                continue

            new_filename = review.get("new_filename") or old_png.name
            new_relative_dir = review.get("new_relative_dir") or rel_to_project(
                old_png.parent, project_root
            )
            new_png = normalize_new_path(new_relative_dir, new_filename, project_root)
            if new_png.suffix.lower() != ".png":
                new_png = new_png.with_suffix(".png")

            if action == "keep":
                new_png = old_png

            new_manifest = new_png.with_suffix(GAME32_SUFFIX)

            result["new_png"] = rel_to_project(new_png, project_root)
            result["new_manifest"] = rel_to_project(new_manifest, project_root)

            updated_manifest = update_manifest_metadata(
                manifest,
                review=review,
                new_png_path=new_png,
                new_manifest_path=new_manifest,
                project_root=project_root,
            )

            if not dry_run:
                new_png.parent.mkdir(parents=True, exist_ok=True)

                if action == "move" and new_png.resolve() != old_png.resolve():
                    if new_png.exists():
                        new_png = unique_path(new_png)
                        new_manifest = new_png.with_suffix(GAME32_SUFFIX)
                        result["new_png"] = rel_to_project(new_png, project_root)
                        result["new_manifest"] = rel_to_project(
                            new_manifest, project_root
                        )

                    shutil.move(str(old_png), str(new_png))

                    if (
                        old_manifest
                        and old_manifest.exists()
                        and old_manifest.resolve() != new_manifest.resolve()
                    ):
                        if new_manifest.exists():
                            new_manifest = unique_path(new_manifest)
                            result["new_manifest"] = rel_to_project(
                                new_manifest, project_root
                            )
                        shutil.move(str(old_manifest), str(new_manifest))

                    old_import = Path(str(old_png) + ".import")
                    if old_import.exists():
                        if move_import:
                            new_import = Path(str(new_png) + ".import")
                            if new_import.exists():
                                new_import = unique_path(new_import)
                            shutil.move(str(old_import), str(new_import))
                        else:
                            old_import.unlink()

                write_json(new_manifest, updated_manifest)

            result["status"] = "updated" if action == "keep" else "moved"
            report["results"].append(result)

        except Exception as exc:
            result["status"] = "error"
            result["error"] = str(exc)
            report["results"].append(result)

    return report


def chunked(items: list[AssetItem], size: int) -> list[list[AssetItem]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Review and recategorize game32 PNG assets in batches."
    )
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
        "--batch-size", type=int, default=24, help="How many PNGs per review batch."
    )
    parser.add_argument(
        "--columns", type=int, default=6, help="Columns in contact sheet."
    )
    parser.add_argument(
        "--thumb-size", type=int, default=160, help="Max preview size per asset."
    )
    parser.add_argument(
        "--label-height", type=int, default=44, help="Label area under each thumbnail."
    )
    parser.add_argument("--padding", type=int, default=10, help="Cell padding.")
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
        help="Trash dir for delete action, inside scan root unless absolute.",
    )
    parser.add_argument(
        "--include-without-manifest",
        action="store_true",
        help="Also include PNGs that do not have .game32.json sidecars.",
    )
    parser.add_argument(
        "--move-import",
        action="store_true",
        help="Move .png.import sidecars too. Default deletes stale import sidecar on move so Godot regenerates it.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not actually move/write; only report.",
    )
    parser.add_argument(
        "--start-batch", type=int, default=0, help="Start at batch number."
    )
    parser.add_argument(
        "--only-batch", type=int, default=-1, help="Only process this batch number."
    )
    parser.add_argument(
        "--no-clipboard",
        action="store_true",
        help="Do not copy contact sheet to clipboard.",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Non-interactive: write review JSON and immediately apply it.",
    )
    parser.add_argument(
        "--exclude-review",
        action="store_true",
        default=True,
        help="Exclude _review_ images.",
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
    )

    if not items:
        eprint("No PNG assets found.")
        return 0

    batches = chunked(items, args.batch_size)
    print(f"Found {len(items)} PNG assets across {len(batches)} batches.")
    print(f"Review dir: {review_dir}")

    for batch_number, batch_items in enumerate(batches):
        if batch_number < args.start_batch:
            continue
        if args.only_batch >= 0 and batch_number != args.only_batch:
            continue

        contact_sheet = review_dir / f"batch_{batch_number:04d}_contact.png"
        aggregate_json = (
            review_dir / f"batch_{batch_number:04d}_aggregate.game32.review.json"
        )
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

        print("\n" + "=" * 88)
        print(f"Batch {batch_number:04d}/{len(batches) - 1:04d}")
        print(f"Contact sheet: {contact_sheet}")
        print(f"Aggregate JSON: {aggregate_json}")
        print("=" * 88)

        if not args.no_clipboard:
            clipboard_copy_png(contact_sheet)

        if not args.yes:
            print("\nReview workflow:")
            print("  1. Paste/view the clipboard image wherever useful.")
            print("  2. Edit the aggregate JSON file listed above.")
            print("  3. Set review.action/new_relative_dir/new_filename/new_* fields.")
            print("  4. Save the aggregate JSON.")
            print("  5. Return here and press Enter.")
            response = (
                input(
                    "\nPress Enter to apply this batch, 's' to skip, or 'q' to quit: "
                )
                .strip()
                .lower()
            )

            if response == "q":
                print("Stopping before applying this batch.")
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
        )
        write_json(apply_report_json, report)

        print(f"Apply report: {apply_report_json}")

        summary: dict[str, int] = {}
        for r in report["results"]:
            summary[r["status"]] = summary.get(r["status"], 0) + 1
        print("Batch result summary:")
        for k, v in sorted(summary.items()):
            print(f"  {k}: {v}")

        if args.only_batch >= 0:
            break

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
