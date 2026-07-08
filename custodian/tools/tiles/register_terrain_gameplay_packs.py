#!/usr/bin/env python3
"""Register terrain gameplay pack PNGs (connector, ascent, chasm+bridge) as TileSet atlas sources.

For each runtime PNG not already present in procgen_world_tileset.tres, this script
generates a new ext_resource entry, a TileSetAtlasSource sub_resource, and a sources/N
mapping, then writes a JSON mapping report to reports/terrain_pack_ingest/.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TILESET_PATH = ROOT / "content/tiles/tilesets/procgen_world_tileset.tres"
TILESET_RES = "res://content/tiles/tilesets/procgen_world_tileset.tres"
REPORT_DIR = ROOT.parent / "reports/terrain_pack_ingest"

PACKS = [
    {
        "name": "connector",
        "resources_prefix": "res://content/tiles/terrain/runtime/connector/",
        "runtime_dir": ROOT / "content/tiles/terrain/runtime/connector",
        "source_id_start": 60,
        "id_prefix": "connector",
        "sub_prefix": "TileSetAtlasSource_connector_",
    },
    {
        "name": "ascent",
        "resources_prefix": "res://content/tiles/terrain/runtime/ascent/",
        "runtime_dir": ROOT / "content/tiles/terrain/runtime/ascent",
        "source_id_start": 80,
        "id_prefix": "ascent",
        "sub_prefix": "TileSetAtlasSource_ascent_",
    },
    {
        "name": "chasm_bridge",
        "resources_prefix": "res://content/tiles/terrain/runtime/chasm_bridge/",
        "runtime_dir": ROOT / "content/tiles/terrain/runtime/chasm_bridge",
        "source_id_start": 100,
        "id_prefix": "chasm_bridge",
        "sub_prefix": "TileSetAtlasSource_chasm_bridge_",
    },
]

EXT_RE = re.compile(
    r'^\[ext_resource type="Texture2D"(?: uid="[^"]+")? path="([^"]+)" id="([^"]+)"\]$'
)
SUB_RE = re.compile(r'^\[sub_resource type="TileSetAtlasSource" id="([^"]+)"\]$')
TEXTURE_RE = re.compile(r'^texture = ExtResource\("([^"]+)"\)$')
SOURCE_RE = re.compile(r'^sources/(\d+) = SubResource\("([^"]+)"\)$')


def _slug(path: Path) -> str:
    return re.sub(r"[^a-zA-Z0-9_]+", "_", path.stem).strip("_")


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def _parse_tileset(text: str) -> tuple[dict[str, str], dict[str, str], dict[int, str]]:
    ext_id_to_path: dict[str, str] = {}
    sub_id_to_ext_id: dict[str, str] = {}
    source_id_to_sub_id: dict[int, str] = {}

    current_sub_id = ""
    for raw_line in text.splitlines():
        line = raw_line.strip()
        ext_match = EXT_RE.match(line)
        if ext_match:
            path_str, ext_id = ext_match.groups()
            ext_id_to_path[ext_id] = path_str
            continue

        sub_match = SUB_RE.match(line)
        if sub_match:
            current_sub_id = sub_match.group(1)
            continue

        if current_sub_id:
            texture_match = TEXTURE_RE.match(line)
            if texture_match:
                sub_id_to_ext_id[current_sub_id] = texture_match.group(1)
                continue

        source_match = SOURCE_RE.match(line)
        if source_match:
            source_id_to_sub_id[int(source_match.group(1))] = source_match.group(2)

    return ext_id_to_path, sub_id_to_ext_id, source_id_to_sub_id


def _build_path_to_source_id(
    ext_id_to_path: dict[str, str],
    sub_id_to_ext_id: dict[str, str],
    source_id_to_sub_id: dict[int, str],
) -> dict[str, int]:
    path_to_source_id: dict[str, int] = {}
    for source_id, sub_id in source_id_to_sub_id.items():
        ext_id = sub_id_to_ext_id.get(sub_id, "")
        path_str = ext_id_to_path.get(ext_id, "")
        if path_str:
            path_to_source_id[path_str] = source_id
    return path_to_source_id


def _insert_before_first_subresource(text: str, block: str) -> str:
    marker = "\n[sub_resource "
    index = text.find(marker)
    if index < 0:
        raise RuntimeError("Could not find sub_resource section in TileSet")
    return text[:index] + "\n" + block.rstrip() + "\n" + text[index:]


def _insert_before_resource(text: str, block: str) -> str:
    marker = "\n[resource]"
    index = text.find(marker)
    if index < 0:
        raise RuntimeError("Could not find resource section in TileSet")
    return text[:index] + "\n" + block.rstrip() + "\n" + text[index:]


def _insert_sources_after_last_source(text: str, lines: list[str]) -> str:
    matches = list(
        re.finditer(r'^sources/\d+ = SubResource\("[^"]+"\)$', text, re.MULTILINE)
    )
    if not matches:
        raise RuntimeError("Could not find existing TileSet source entries")
    last = matches[-1]
    return text[: last.end()] + "\n" + "\n".join(lines) + text[last.end() :]


def _register_tile_source(
    path: Path,
    pack: dict,
    path_to_source_id: dict[str, int],
    used_ext_ids: set[str],
    used_sub_ids: set[str],
    used_source_ids: set[int],
    next_source_id: int,
    new_ext_lines: list[str],
    new_sub_blocks: list[str],
    new_source_lines: list[str],
) -> tuple[int, int]:
    res_path = pack["resources_prefix"] + path.name
    existing_source_id = path_to_source_id.get(res_path)
    if existing_source_id is not None:
        return existing_source_id, next_source_id

    source_id = next_source_id
    while source_id in used_source_ids:
        source_id += 1
    used_source_ids.add(source_id)

    slug = _slug(path)
    ext_id = f"{source_id}_{pack['id_prefix']}_{slug}"
    suffix = 1
    while ext_id in used_ext_ids:
        suffix += 1
        ext_id = f"{source_id}_{pack['id_prefix']}_{slug}_{suffix}"
    used_ext_ids.add(ext_id)

    sub_id = f"{pack['sub_prefix']}{slug}"
    suffix = 1
    while sub_id in used_sub_ids:
        suffix += 1
        sub_id = f"{pack['sub_prefix']}{slug}_{suffix}"
    used_sub_ids.add(sub_id)

    new_ext_lines.append(
        f'[ext_resource type="Texture2D" path="{res_path}" id="{ext_id}"]'
    )
    new_sub_blocks.append(
        "\n".join(
            [
                f'[sub_resource type="TileSetAtlasSource" id="{sub_id}"]',
                f'texture = ExtResource("{ext_id}")',
                "texture_region_size = Vector2i(32, 32)",
                "0:0/0 = 0",
            ]
        )
    )
    new_source_lines.append(f'sources/{source_id} = SubResource("{sub_id}")')

    next_source_id = source_id + 1
    return source_id, next_source_id


def register(dry_run: bool = False) -> int:
    tileset_text = _read(TILESET_PATH)
    ext_id_to_path, sub_id_to_ext_id, source_id_to_sub_id = _parse_tileset(tileset_text)
    path_to_source_id = _build_path_to_source_id(
        ext_id_to_path, sub_id_to_ext_id, source_id_to_sub_id
    )
    used_ext_ids = set(ext_id_to_path.keys())
    used_sub_ids = set(sub_id_to_ext_id.keys()) | set(source_id_to_sub_id.values())
    used_source_ids = set(source_id_to_sub_id.keys())

    new_ext_lines: list[str] = []
    new_sub_blocks: list[str] = []
    new_source_lines: list[str] = []

    report_packs: dict[str, dict] = {}
    summaries: list[dict] = []

    for pack in PACKS:
        pngs = sorted(pack["runtime_dir"].glob("*.png"))
        if not pngs:
            print(f"[{pack['name']}] No PNGs found in {pack['runtime_dir']}")
            summaries.append(
                {
                    "pack": pack["name"],
                    "source_id_start": pack["source_id_start"],
                    "files": [],
                    "count": 0,
                    "new_count": 0,
                }
            )
            report_packs[pack["name"]] = {
                "source_id_start": pack["source_id_start"],
                "tiles": {},
            }
            continue

        pack_next = pack["source_id_start"]
        tile_map: dict[str, int] = {}
        new_count = 0

        for png_path in pngs:
            res_path = pack["resources_prefix"] + png_path.name
            was_new = path_to_source_id.get(res_path) is None

            source_id, pack_next = _register_tile_source(
                png_path,
                pack,
                path_to_source_id,
                used_ext_ids,
                used_sub_ids,
                used_source_ids,
                pack_next,
                new_ext_lines,
                new_sub_blocks,
                new_source_lines,
            )
            tile_map[png_path.stem] = source_id
            if was_new:
                new_count += 1

        summaries.append(
            {
                "pack": pack["name"],
                "source_id_start": pack["source_id_start"],
                "files": sorted(tile_map.keys()),
                "count": len(pngs),
                "new_count": new_count,
            }
        )
        report_packs[pack["name"]] = {
            "source_id_start": pack["source_id_start"],
            "tiles": tile_map,
        }

    if new_ext_lines:
        tileset_text = _insert_before_first_subresource(
            tileset_text, "\n".join(new_ext_lines)
        )
        tileset_text = _insert_before_resource(
            tileset_text, "\n\n".join(new_sub_blocks)
        )
        tileset_text = _insert_sources_after_last_source(
            tileset_text, new_source_lines
        )

    print("Terrain gameplay pack registration summary:")
    for s in summaries:
        print(f"\n  {s['pack']}:")
        print(f"    Source ID range: {s['source_id_start']}+")
        print(f"    Files: {s['count']} total, {s['new_count']} new")
        for fname in s["files"]:
            print(f"      - {fname}")

    if new_source_lines:
        print("\n  Added TileSet sources:")
        for line in new_source_lines:
            print(f"    {line}")
    else:
        print("\n  No new TileSet sources needed")

    report = {
        "report_time": datetime.now(timezone.utc).isoformat(),
        "tileset_path": TILESET_RES,
        "packs": report_packs,
    }
    report_path = REPORT_DIR / "terrain_gameplay_tileset_sources.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"\n  Report written to {report_path}")

    if not dry_run and new_ext_lines:
        _write(TILESET_PATH, tileset_text)
        print(f"  Wrote updated {TILESET_PATH}")
    elif dry_run and new_ext_lines:
        print("  (dry-run: tileset not modified)")
    else:
        print("  Tileset not modified (nothing to register)")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="report changes without writing the tileset file",
    )
    args = parser.parse_args()
    return register(dry_run=args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
