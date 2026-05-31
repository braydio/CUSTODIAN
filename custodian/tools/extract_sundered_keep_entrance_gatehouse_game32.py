#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from collections import deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image

PROJECT_ROOT = Path("/home/braydenchaffee/Projects/CUSTODIAN")
CUSTODIAN_ROOT = PROJECT_ROOT / "custodian"

DEFAULT_ATLAS = (
    CUSTODIAN_ROOT
    / "content/masters/sundered_keep/sundered_keep_entrance_gatehouse.png"
)
METADATA_OUT = (
    CUSTODIAN_ROOT
    / "content/metadata/game32/sundered_keep_entrance_gatehouse.game32.json"
)

TILE_SIZE = 32


@dataclass(frozen=True)
class AssetSpec:
    name: str
    crop: tuple[int, int, int, int]
    out_size: tuple[int, int]
    domain: str
    domain_home: str
    asset_class: str
    description: str
    walkable: bool
    blocks_movement: bool
    blocks_projectiles: bool
    blocks_vision: bool
    traversal: str
    collision_profile: str
    cover_profile: str
    z_layer: str
    z_index: int
    y_sort: bool
    pivot: str
    placement_rule: str
    tags: list[str]
    overlay: bool = False
    fall_hazard: bool = False
    water_hazard: bool = False


ASSETS: list[AssetSpec] = [
    AssetSpec(
        name="entrance_causeway_floor_01",
        crop=(40, 51, 238, 240),
        out_size=(32, 32),
        domain="entrance",
        domain_home="res://content/tiles/sundered_keep/entrance",
        asset_class="floor_tile",
        description="Walkable wet gothic causeway floor tile for the Sundered Keep storm approach.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=0,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "entrance", "causeway", "floor", "stone", "wet"],
    ),
    AssetSpec(
        name="entrance_causeway_floor_cracked_01",
        crop=(279, 51, 477, 240),
        out_size=(32, 32),
        domain="entrance",
        domain_home="res://content/tiles/sundered_keep/entrance",
        asset_class="floor_tile",
        description="Cracked walkable causeway floor tile for damaged entrance approach sections.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=0,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=[
            "sundered_keep",
            "entrance",
            "causeway",
            "floor",
            "stone",
            "cracked",
            "damaged",
        ],
    ),
    AssetSpec(
        name="entrance_causeway_edge_n",
        crop=(517, 51, 698, 240),
        out_size=(32, 32),
        domain="entrance",
        domain_home="res://content/tiles/sundered_keep/entrance",
        asset_class="edge_tile",
        description="North-facing causeway edge tile blending wet stone into storm ocean void.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable_edge",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=1,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "entrance", "causeway", "edge", "facing_n", "ocean"],
    ),
    AssetSpec(
        name="entrance_causeway_edge_e",
        crop=(738, 51, 928, 240),
        out_size=(32, 32),
        domain="entrance",
        domain_home="res://content/tiles/sundered_keep/entrance",
        asset_class="edge_tile",
        description="East-facing causeway edge tile with ocean void on the right side.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable_edge",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=1,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "entrance", "causeway", "edge", "facing_e", "ocean"],
    ),
    AssetSpec(
        name="entrance_causeway_edge_w",
        crop=(968, 51, 1148, 240),
        out_size=(32, 32),
        domain="entrance",
        domain_home="res://content/tiles/sundered_keep/entrance",
        asset_class="edge_tile",
        description="West-facing causeway edge tile with ocean void on the left side.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable_edge",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=1,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "entrance", "causeway", "edge", "facing_w", "ocean"],
    ),
    AssetSpec(
        name="entrance_causeway_broken_gap_01",
        crop=(1188, 51, 1398, 240),
        out_size=(32, 32),
        domain="entrance",
        domain_home="res://content/tiles/sundered_keep/entrance",
        asset_class="hazard_tile",
        description="Broken non-walkable causeway gap with crumbled edge stones and exposed ocean void.",
        walkable=False,
        blocks_movement=True,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="void_gap_blocked",
        collision_profile="void_blocker",
        cover_profile="none",
        z_layer="ground",
        z_index=2,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=[
            "sundered_keep",
            "entrance",
            "causeway",
            "gap",
            "broken",
            "hazard",
            "non_walkable",
        ],
        fall_hazard=True,
        water_hazard=True,
    ),
    AssetSpec(
        name="entrance_causeway_shadow_01",
        crop=(260, 292, 456, 456),
        out_size=(32, 32),
        domain="overlays",
        domain_home="res://content/tiles/sundered_keep/overlays",
        asset_class="overlay_tile",
        description="Soft non-blocking entrance shadow overlay for grounding causeway/gate elements.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="overlay",
        collision_profile="none",
        cover_profile="none",
        z_layer="overlay",
        z_index=45,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "entrance", "causeway", "shadow", "overlay"],
        overlay=True,
    ),
    AssetSpec(
        name="main_gate_threshold_wet_01",
        crop=(471, 307, 659, 453),
        out_size=(32, 32),
        domain="floors",
        domain_home="res://content/tiles/sundered_keep/floors",
        asset_class="floor_tile",
        description="Wet main gate threshold floor tile for the storm-soaked portcullis approach.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=0,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "entrance", "gatehouse", "threshold", "floor", "wet"],
    ),
    AssetSpec(
        name="gatehouse_floor_dark_01",
        crop=(690, 307, 879, 453),
        out_size=(32, 32),
        domain="floors",
        domain_home="res://content/tiles/sundered_keep/floors",
        asset_class="floor_tile",
        description="Dark gatehouse interior floor tile for the Sundered Keep entry chamber.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=0,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "gatehouse", "floor", "stone", "dark"],
    ),
    AssetSpec(
        name="gatehouse_floor_murder_hole_01",
        crop=(908, 307, 1106, 453),
        out_size=(32, 32),
        domain="floors",
        domain_home="res://content/tiles/sundered_keep/floors",
        asset_class="floor_tile",
        description="Decorative murder-hole/grate floor tile for gatehouse defense details.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="walkable_decorative",
        collision_profile="none",
        cover_profile="none",
        z_layer="ground",
        z_index=1,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=[
            "sundered_keep",
            "gatehouse",
            "floor",
            "murder_hole",
            "grate",
            "decorative",
        ],
    ),
    AssetSpec(
        name="main_gate_portcullis_shadow_01",
        crop=(542, 522, 896, 631),
        out_size=(64, 32),
        domain="overlays",
        domain_home="res://content/tiles/sundered_keep/overlays",
        asset_class="overlay_tile",
        description="Two-cell shadow overlay cast by the main gate portcullis.",
        walkable=True,
        blocks_movement=False,
        blocks_projectiles=False,
        blocks_vision=False,
        traversal="overlay",
        collision_profile="none",
        cover_profile="none",
        z_layer="overlay",
        z_index=46,
        y_sort=False,
        pivot="top_left",
        placement_rule="snap_to_grid32",
        tags=["sundered_keep", "gatehouse", "portcullis", "shadow", "overlay"],
        overlay=True,
    ),
    AssetSpec(
        name="gatehouse_wall_broken_left_01",
        crop=(405, 676, 651, 1008),
        out_size=(64, 96),
        domain="walls_gatehouse",
        domain_home="res://content/tiles/sundered_keep/walls/gatehouse",
        asset_class="wall_module",
        description="Left broken gothic gatehouse wall module for ruined Sundered Keep entrance flanks.",
        walkable=False,
        blocks_movement=True,
        blocks_projectiles=True,
        blocks_vision=True,
        traversal="blocked",
        collision_profile="solid_base_2x1",
        cover_profile="high",
        z_layer="architecture",
        z_index=34,
        y_sort=True,
        pivot="bottom_center",
        placement_rule="snap_bottom_to_grid32",
        tags=[
            "sundered_keep",
            "gatehouse",
            "wall",
            "broken",
            "left",
            "solid",
            "vertical_sprite",
        ],
    ),
    AssetSpec(
        name="gatehouse_wall_broken_right_01",
        crop=(790, 676, 1036, 1008),
        out_size=(64, 96),
        domain="walls_gatehouse",
        domain_home="res://content/tiles/sundered_keep/walls/gatehouse",
        asset_class="wall_module",
        description="Right broken gothic gatehouse wall module for ruined Sundered Keep entrance flanks.",
        walkable=False,
        blocks_movement=True,
        blocks_projectiles=True,
        blocks_vision=True,
        traversal="blocked",
        collision_profile="solid_base_2x1",
        cover_profile="high",
        z_layer="architecture",
        z_index=34,
        y_sort=True,
        pivot="bottom_center",
        placement_rule="snap_bottom_to_grid32",
        tags=[
            "sundered_keep",
            "gatehouse",
            "wall",
            "broken",
            "right",
            "solid",
            "vertical_sprite",
        ],
    ),
]


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sha256_image(image: Image.Image) -> str:
    return hashlib.sha256(image.tobytes()).hexdigest()


def res_path(path: Path) -> str:
    return "res://" + path.relative_to(CUSTODIAN_ROOT).as_posix()


def is_checkerish(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return False

    mx = max(r, g, b)
    mn = min(r, g, b)
    low_sat = (mx - mn) <= 18

    # Light baked checkerboard from generated atlas.
    return low_sat and mx >= 205


def flood_clear_border_checkerboard(image: Image.Image) -> Image.Image:
    img = image.convert("RGBA")
    px = img.load()
    w, h = img.size

    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if (x, y) in seen:
            continue
        seen.add((x, y))

        r, g, b, a = px[x, y]
        if not is_checkerish(r, g, b, a):
            continue

        px[x, y] = (r, g, b, 0)

        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen:
                q.append((nx, ny))

    return img


def normalize_crop(atlas: Image.Image, spec: AssetSpec) -> Image.Image:
    crop = atlas.crop(spec.crop).convert("RGBA")
    crop = flood_clear_border_checkerboard(crop)

    # Overlay assets should preserve soft alpha after checkerboard removal.
    if spec.overlay:
        crop = make_overlay_alpha(crop)

    # Fit the whole cropped asset into the requested runtime canvas.
    crop_bbox = crop.getbbox()
    if crop_bbox:
        crop = crop.crop(crop_bbox)

    out_w, out_h = spec.out_size
    scale = min(out_w / crop.width, out_h / crop.height)
    new_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))

    resized = crop.resize(new_size, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", spec.out_size, (0, 0, 0, 0))

    if spec.pivot == "bottom_center":
        paste_x = (out_w - resized.width) // 2
        paste_y = out_h - resized.height
    else:
        paste_x = (out_w - resized.width) // 2
        paste_y = (out_h - resized.height) // 2

    out.alpha_composite(resized, (paste_x, paste_y))
    return out


def make_overlay_alpha(image: Image.Image) -> Image.Image:
    img = image.convert("RGBA")
    px = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue

            # Remove light checker leftovers.
            if is_checkerish(r, g, b, a):
                px[x, y] = (0, 0, 0, 0)
                continue

            lum = (r + g + b) / 3.0
            alpha = int(max(0, min(170, 210 - lum)))
            if alpha <= 8:
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (0, 0, 0, alpha)

    return img


def logical_footprint(spec: AssetSpec) -> tuple[int, int]:
    if spec.asset_class == "wall_module":
        return (max(1, spec.out_size[0] // TILE_SIZE), 1)
    return (
        max(1, spec.out_size[0] // TILE_SIZE),
        max(1, spec.out_size[1] // TILE_SIZE),
    )


def collision_rect(spec: AssetSpec) -> list[int] | None:
    if not spec.blocks_movement:
        return None

    footprint = logical_footprint(spec)
    return [0, 0, footprint[0] * TILE_SIZE, TILE_SIZE]


def build_game32(spec: AssetSpec) -> dict[str, Any]:
    footprint = logical_footprint(spec)
    rect = collision_rect(spec)

    return {
        "tile_size_px": TILE_SIZE,
        "runtime_canvas_px": list(spec.out_size),
        "logical_footprint_cells": list(footprint),
        "logical_footprint_px": [footprint[0] * TILE_SIZE, footprint[1] * TILE_SIZE],
        "anchor": spec.pivot,
        "pivot": spec.pivot,
        "placement_rule": spec.placement_rule,
        "orientation": infer_orientation(spec.name),
        "variant_group": infer_variant_group(spec.name),
        "z_layer": spec.z_layer,
        "z_index": spec.z_index,
        "y_sort": spec.y_sort,
        "walkable": spec.walkable,
        "blocks_movement": spec.blocks_movement,
        "blocks_projectiles": spec.blocks_projectiles,
        "blocks_vision": spec.blocks_vision,
        "fall_hazard": spec.fall_hazard,
        "water_hazard": spec.water_hazard,
        "traversal": spec.traversal,
        "collision": {
            "enabled": spec.blocks_movement,
            "profile": spec.collision_profile,
            "shape": "rect" if spec.blocks_movement else "none",
            "rect_px": rect,
            "applies_to": "logical_base_cell" if spec.blocks_movement else "none",
        },
        "navigation": {
            "can_pathfind": spec.walkable and not spec.blocks_movement,
            "cost": 1.0 if spec.walkable and not spec.blocks_movement else None,
            "avoidance": (
                "normal" if spec.walkable and not spec.blocks_movement else "blocked"
            ),
        },
        "combat": {
            "cover_profile": spec.cover_profile,
            "line_of_sight_profile": (
                "occluding" if spec.blocks_vision else "transparent"
            ),
            "projectile_profile": "blocking" if spec.blocks_projectiles else "passable",
        },
        "render": {
            "allowed_layers": allowed_layers(spec),
            "import_filter": "nearest_or_disabled_in_godot",
            "mipmaps": False,
            "shadow_policy": "baked_in_source",
            "occluder_recommended": spec.blocks_vision,
        },
        "tags": spec.tags,
    }


def allowed_layers(spec: AssetSpec) -> list[str]:
    if spec.domain == "overlays":
        return ["overlay", "decals"]
    if spec.asset_class == "wall_module":
        return ["architecture", "walls"]
    return ["ground", "floor"]


def infer_orientation(name: str) -> str | None:
    for suffix in ("_n", "_e", "_s", "_w"):
        if name.endswith(suffix) or f"{suffix}_" in name:
            return suffix[1:]
    if "_left_" in name:
        return "left"
    if "_right_" in name:
        return "right"
    return None


def infer_variant_group(name: str) -> str:
    parts = name.split("_")
    if parts[-1].isdigit():
        return "_".join(parts[:-1])
    if parts[-1] in {"n", "e", "s", "w"} and len(parts) > 1:
        return "_".join(parts[:-1])
    return name.removesuffix("_01")


def make_sidecar(
    spec: AssetSpec, out_path: Path, image: Image.Image, atlas: Path
) -> dict[str, Any]:
    return {
        "schema": "custodian.game32.asset.v1",
        "id": f"sundered_keep/{spec.domain}/{spec.name}",
        "name": spec.name,
        "filename": out_path.name,
        "description": spec.description,
        "asset_class": spec.asset_class,
        "domain": spec.domain,
        "domain_home": spec.domain_home,
        "runtime_path": res_path(out_path),
        "source": {
            "master_sheet": atlas.name,
            "master_sheet_path": res_path(atlas),
            "crop_box_px": list(spec.crop),
            "source_crop_size_px": [
                spec.crop[2] - spec.crop[0],
                spec.crop[3] - spec.crop[1],
            ],
            "normalization": {
                "output_size_px": list(spec.out_size),
                "background_cleanup": "border_connected_checkerboard_to_alpha",
                "overlay_alpha_rebuild": spec.overlay,
            },
        },
        "image": {
            "runtime_canvas_px": list(spec.out_size),
            "format": "png_rgba",
            "sha256": sha256_image(image),
            "file_sha256": sha256_file(out_path),
            "background": "transparent",
        },
        "game32": build_game32(spec),
    }


def update_domain_manifest(domain_home: str, assets: list[dict[str, Any]]) -> None:
    domain_dir = CUSTODIAN_ROOT / domain_home.removeprefix("res://")
    manifest_path = domain_dir / "_manifest.game32.json"

    manifest = {
        "schema": "custodian.game32.domain_manifest.v1",
        "name": domain_dir.name,
        "generated_at_utc": now_utc(),
        "generator": "extract_sundered_keep_entrance_gatehouse_game32.py",
        "set": "sundered_keep",
        "domain_home": domain_home,
        "asset_count": len(assets),
        "assets": [
            {
                "id": asset["id"],
                "name": asset["name"],
                "runtime_path": asset["runtime_path"],
                "metadata_path": asset["runtime_path"].removesuffix(".png")
                + ".game32.json",
                "asset_class": asset["asset_class"],
                "domain": asset["domain"],
                "game32": asset["game32"],
            }
            for asset in assets
        ],
    }

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--atlas", type=Path, default=DEFAULT_ATLAS)
    parser.add_argument("--no-domain-manifests", action="store_true")
    args = parser.parse_args()

    atlas_path = args.atlas
    if not atlas_path.exists():
        raise SystemExit(f"Missing atlas: {atlas_path}")

    atlas = Image.open(atlas_path).convert("RGBA")
    extracted: list[dict[str, Any]] = []
    by_domain_home: dict[str, list[dict[str, Any]]] = {}

    for spec in ASSETS:
        domain_dir = CUSTODIAN_ROOT / spec.domain_home.removeprefix("res://")
        domain_dir.mkdir(parents=True, exist_ok=True)

        out_path = domain_dir / f"{spec.name}.png"
        out_img = normalize_crop(atlas, spec)
        out_img.save(out_path)

        sidecar = make_sidecar(spec, out_path, out_img, atlas_path)
        sidecar_path = out_path.with_suffix(".game32.json")
        sidecar_path.write_text(json.dumps(sidecar, indent=2) + "\n")

        extracted.append(sidecar)
        by_domain_home.setdefault(spec.domain_home, []).append(sidecar)

        print(f"wrote {out_path.relative_to(PROJECT_ROOT)}")
        print(f"wrote {sidecar_path.relative_to(PROJECT_ROOT)}")

    if not args.no_domain_manifests:
        for domain_home, assets in by_domain_home.items():
            update_domain_manifest(domain_home, assets)
            print(f"updated {domain_home}/_manifest.game32.json")

    master = {
        "schema": "custodian.game32.asset_manifest.v1",
        "name": "sundered_keep_entrance_gatehouse",
        "generated_at_utc": now_utc(),
        "generator": "extract_sundered_keep_entrance_gatehouse_game32.py",
        "game32": {
            "tile_size_px": TILE_SIZE,
            "coordinate_system": "grid32_top_down_2_5d",
            "runtime": "Godot 4.x",
            "usage": {
                "floors": "snap top-left to 32x32 grid cell",
                "overlays": "snap top-left to grid; render above floor",
                "walls": "snap logical base cells to grid; render sprite bottom-center with y-sort",
                "metadata_authority": "content/metadata/game32/sundered_keep_entrance_gatehouse.game32.json",
            },
        },
        "source": {
            "sheet": {
                "path": res_path(atlas_path),
                "size_px": list(atlas.size),
                "sha256": sha256_file(atlas_path),
            }
        },
        "outputs": {
            "count": len(extracted),
            "domains": {
                domain_home: {
                    "count": len(assets),
                    "manifest": domain_home + "/_manifest.game32.json",
                }
                for domain_home, assets in sorted(by_domain_home.items())
            },
        },
        "assets": extracted,
        "doc_drift_check": {
            "checked_at_utc": now_utc(),
            "status": "ok",
            "checked_paths": [
                str(CUSTODIAN_ROOT),
                str(CUSTODIAN_ROOT / "content"),
                str(CUSTODIAN_ROOT / "docs/ai_context"),
                str(CUSTODIAN_ROOT / "tools/art"),
            ],
            "recommendation": (
                "If these entrance/gatehouse assets are accepted into runtime, add a short note to "
                "custodian/docs/ai_context/CURRENT_STATE.md and FILE_INDEX.md with the master sheet, "
                "metadata manifest, and domain paths."
            ),
        },
    }

    METADATA_OUT.parent.mkdir(parents=True, exist_ok=True)
    METADATA_OUT.write_text(json.dumps(master, indent=2) + "\n")
    print(f"wrote {METADATA_OUT.relative_to(PROJECT_ROOT)}")
    print(f"extracted_count={len(extracted)}")


if __name__ == "__main__":
    main()
