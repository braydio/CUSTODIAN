#!/usr/bin/env python3
"""Scaffold canonical CUSTODIAN humanoid rigid-cutout skin files."""

from __future__ import annotations

import argparse
import binascii
import re
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PARTS = (
    "head", "torso", "pelvis", "back_attachment", "front_attachment",
    "upper_arm_back", "forearm_back", "hand_back", "upper_arm_front",
    "forearm_front", "hand_front", "thigh_back", "shin_back", "foot_back",
    "thigh_front", "shin_front", "foot_front", "weapon", "cape", "reserved",
)
DIRECTIONS = ("s", "n", "e")


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(
        ">I", binascii.crc32(kind + payload) & 0xFFFFFFFF
    )


def placeholder_png(direction: str) -> bytes:
    width, height = 480, 384
    pixels = bytearray()
    direction_colors = {
        "s": (74, 204, 120), "n": (86, 150, 230),
        "e": (235, 164, 62), "w": (194, 96, 220),
    }
    base = direction_colors[direction]
    for y in range(height):
        pixels.append(0)
        for x in range(width):
            cell_x, cell_y = x // 96, y // 96
            local_x, local_y = x % 96, y % 96
            part = cell_y * 5 + cell_x
            # Deliberately crude, transparent geometric DEV-ONLY silhouettes.
            inside = (
                35 + (part % 3) <= local_x <= 60 - (part % 2)
                and 22 + (part % 5) <= local_y <= 78 - (part % 4)
            )
            if inside:
                shade = min(255, 25 + part * 7)
                pixels.extend((*base, 220 if shade < 170 else 255))
            else:
                pixels.extend((0, 0, 0, 0))
    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return signature + png_chunk(b"IHDR", ihdr) + png_chunk(
        b"IDAT", zlib.compress(bytes(pixels), 9)
    ) + png_chunk(b"IEND", b"")


def skin_text(enemy_id: str, with_placeholders: bool) -> str:
    profile_path = "res://game/actors/enemies/visuals/humanoid_cutout_rig_profile.gd"
    atlas_lines = []
    resources = [
        f'[ext_resource type="Script" path="res://game/actors/enemies/visuals/humanoid_cutout_rig_skin.gd" id="1_skin"]',
        f'[ext_resource type="Script" path="{profile_path}" id="2_profile"]',
    ]
    if with_placeholders:
        for index, direction in enumerate(DIRECTIONS, start=3):
            name = f"{enemy_id}__rig_atlas__base__{direction}__5x4__96.png"
            resources.append(
                f'[ext_resource type="Texture2D" path="res://content/sprites/enemies/{enemy_id}/runtime/body/rig/{name}" id="{index}_{direction}"]'
            )
            property_name = {"s": "south", "n": "north", "e": "east"}[direction]
            atlas_lines.append(f'{property_name}_atlas = ExtResource("{index}_{direction}")')
    return "\n".join([
        f"[gd_resource type=\"Resource\" load_steps={len(resources) + 2} format=3]",
        "", *resources, "",
        '[sub_resource type="Resource" id="Resource_profile"]',
        'script = ExtResource("2_profile")', "",
        "[resource]",
        'script = ExtResource("1_skin")',
        f'skin_id = &"{enemy_id}_base"',
        *atlas_lines,
        'profile = SubResource("Resource_profile")',
        "",
    ])


def readme_text(enemy_id: str) -> str:
    files = "\n".join(
        f"- `{enemy_id}__rig_atlas__base__{d}__5x4__96.png`"
        for d in ("s", "n", "e", "w")
    )
    return f"""# {enemy_id} humanoid cutout skin

DEV/authoring scaffold. Real sources are 96×96, one frame, transparent, with
these exact layers:

{", ".join(PARTS)}

Export with `tools/aseprite/export_humanoid_rig_atlas.lua` after creating or
checking the source with `tools/aseprite/new_humanoid_rig_source.lua`. Each
complete 96×96 layer image is copied to its fixed cell in a 480×384 (5×4)
atlas; never crop, scale, filter, or palette-convert the parts.

Expected runtime atlases:

{files}

Assign S/N/E to `{enemy_id}_humanoid_rig_skin.tres`. W is optional: if absent
and mirroring is enabled, Godot mirrors the complete east visual root. An
authored W atlas disables mirroring.

The rigid rig reuses pivot motion without deforming pixels. Perspective-extreme
and high-impact poses should use replacement part cells or an authored
full-body fallback strip. Gameplay collision and timing never belong to limbs.
"""


def write(path: Path, data: bytes | str, replace: bool, dry_run: bool) -> None:
    action = "replace" if path.exists() else "create"
    if path.exists() and not replace:
        if dry_run:
            print(f"skip existing (requires --replace): {path.relative_to(ROOT)}")
            return
        raise FileExistsError(f"refusing to overwrite {path}; pass --replace")
    print(f"{action}: {path.relative_to(ROOT)}")
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data if isinstance(data, bytes) else data.encode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--enemy-id", required=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--placeholder", action="store_true")
    parser.add_argument("--replace", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9]+(?:_[a-z0-9]+)*", args.enemy_id):
        parser.error("--enemy-id must be lowercase snake_case")
    runtime = ROOT / "custodian/content/sprites/enemies" / args.enemy_id / "runtime/body/rig"
    source = ROOT / "custodian/content/_aseprite/sprites/enemies" / args.enemy_id / "source/rig"
    print("mode:", "apply" if args.apply else "dry-run")
    if args.apply:
        runtime.mkdir(parents=True, exist_ok=True)
        source.mkdir(parents=True, exist_ok=True)
    else:
        print(f"create directory: {runtime.relative_to(ROOT)}")
        print(f"create directory: {source.relative_to(ROOT)}")
    try:
        write(runtime / f"{args.enemy_id}_humanoid_rig_skin.tres",
              skin_text(args.enemy_id, args.placeholder), args.replace, not args.apply)
        write(runtime / "README.md", readme_text(args.enemy_id),
              args.replace, not args.apply)
        if args.placeholder:
            for direction in DIRECTIONS:
                name = f"{args.enemy_id}__rig_atlas__base__{direction}__5x4__96.png"
                write(runtime / name, placeholder_png(direction),
                      args.replace, not args.apply)
    except FileExistsError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print("No production PNGs were created." if not args.placeholder
          else "Generated geometric DEV-ONLY placeholder atlases.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
