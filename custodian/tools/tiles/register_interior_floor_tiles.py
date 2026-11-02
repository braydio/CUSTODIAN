#!/usr/bin/env python3
"""Register runtime interior tile PNGs as TileSet sources.

Convention:
  custodian/content/tiles/interiors/runtime/floor_*_32.png
  custodian/content/tiles/interiors/runtime/threshold_*_32.png
  custodian/content/tiles/interiors/runtime/doorway_*_32.png
  custodian/content/tiles/interiors/runtime/wall_*_32.png
  custodian/content/tiles/interiors/runtime/wall_*corner*_32.png

The script adds missing one-tile TileSetAtlasSource entries to the canonical
world TileSet and refreshes ProcGenTilemap interior floor/wall/opening source
IDs in proc_gen_map.tscn. Wall files with "corner" in the filename are routed
to interior_wall_corner_source_id; other wall files are routed to
interior_wall_source_ids.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNTIME_DIR = ROOT / "content/tiles/interiors/runtime"
TILESET_PATH = ROOT / "content/tiles/tilesets/procgen_world_tileset.tres"
PROCGEN_SCENE_PATH = ROOT / "game/world/procgen/proc_gen_map.tscn"
RES_PREFIX = "res://content/tiles/interiors/runtime/"
FLOOR_GLOB = "floor_*_32.png"
THRESHOLD_GLOB = "threshold_*_32.png"
DOORWAY_GLOB = "doorway_*_32.png"
WALL_GLOB = "wall_*_32.png"


EXT_RE = re.compile(r'^\[ext_resource type="Texture2D"(?: uid="[^"]+")? path="([^"]+)" id="([^"]+)"\]$')
SUB_RE = re.compile(r'^\[sub_resource type="TileSetAtlasSource" id="([^"]+)"\]$')
TEXTURE_RE = re.compile(r'^texture = ExtResource\("([^"]+)"\)$')
SOURCE_RE = re.compile(r'^sources/(\d+) = SubResource\("([^"]+)"\)$')
INTERIOR_FLOOR_IDS_RE = re.compile(r'interior_floor_source_ids = Array\[int\]\(\[([^\]]*)\]\)')
INTERIOR_THRESHOLD_IDS_RE = re.compile(r'interior_threshold_source_ids = Array\[int\]\(\[([^\]]*)\]\)')
INTERIOR_DOORWAY_IDS_RE = re.compile(r'interior_doorway_source_ids = Array\[int\]\(\[([^\]]*)\]\)')
INTERIOR_WALL_IDS_RE = re.compile(r'interior_wall_source_ids = Array\[int\]\(\[([^\]]*)\]\)')
INTERIOR_WALL_ID_RE = re.compile(r'interior_wall_source_id = -?\d+')
INTERIOR_WALL_CORNER_ID_RE = re.compile(r'interior_wall_corner_source_id = -?\d+')


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
            path, ext_id = ext_match.groups()
            ext_id_to_path[ext_id] = path
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
        path = ext_id_to_path.get(ext_id, "")
        if path:
            path_to_source_id[path] = source_id
            if path.startswith("res://content/tiles/interiors/"):
                path_to_source_id.setdefault(RES_PREFIX + Path(path).name, source_id)
    return path_to_source_id


def _res_path_exists(res_path: str) -> bool:
    if not res_path.startswith("res://"):
        return True
    return (ROOT / res_path.removeprefix("res://")).exists()


def _remove_stale_interior_sources(
    text: str,
    ext_id_to_path: dict[str, str],
    sub_id_to_ext_id: dict[str, str],
    source_id_to_sub_id: dict[int, str],
) -> tuple[str, list[str]]:
    stale_ext_ids = [
        ext_id
        for ext_id, res_path in ext_id_to_path.items()
        if res_path.startswith(RES_PREFIX) and not _res_path_exists(res_path)
    ]
    if not stale_ext_ids:
        return text, []

    stale_ext_id_set = set(stale_ext_ids)
    stale_sub_ids = {
        sub_id
        for sub_id, ext_id in sub_id_to_ext_id.items()
        if ext_id in stale_ext_id_set
    }
    stale_source_ids = {
        source_id
        for source_id, sub_id in source_id_to_sub_id.items()
        if sub_id in stale_sub_ids
    }

    for ext_id in stale_ext_ids:
        text = re.sub(
            rf'^\[ext_resource type="Texture2D"(?: uid="[^"]+")? path="[^"]+" id="{re.escape(ext_id)}"\]\n?',
            "",
            text,
            flags=re.MULTILINE,
        )

    for sub_id in stale_sub_ids:
        text = re.sub(
            rf'\n?\[sub_resource type="TileSetAtlasSource" id="{re.escape(sub_id)}"\]\n(?:[^\[]|\[(?!sub_resource|\w+_resource|\w+\]))*',
            "\n",
            text,
        )

    for source_id in stale_source_ids:
        text = re.sub(
            rf'^sources/{source_id} = SubResource\("[^"]+"\)\n?',
            "",
            text,
            flags=re.MULTILINE,
        )

    stale_paths = [ext_id_to_path[ext_id] for ext_id in stale_ext_ids]
    return text, sorted(stale_paths)


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
    matches = list(re.finditer(r'^sources/\d+ = SubResource\("[^"]+"\)$', text, re.MULTILINE))
    if not matches:
        raise RuntimeError("Could not find existing TileSet source entries")
    last = matches[-1]
    return text[:last.end()] + "\n" + "\n".join(lines) + text[last.end():]


def _format_id_list(ids: list[int]) -> str:
    return "Array[int]([" + ", ".join(str(value) for value in ids) + "])"


def _replace_or_insert_after(text: str, pattern: re.Pattern[str], replacement: str, anchor_pattern: str) -> tuple[str, int]:
    new_text, count = pattern.subn(replacement, text)
    if count > 0:
        return new_text, count
    matches = list(re.finditer(anchor_pattern, text, re.MULTILINE))
    if not matches:
        return text, 0
    offset = 0
    for match in matches:
        insert_at = match.end() + offset
        new_text = new_text[:insert_at] + "\n" + replacement + new_text[insert_at:]
        offset += len(replacement) + 1
    return new_text, len(matches)


def _refresh_procgen_scene(
    text: str,
    floor_source_ids: list[int],
    threshold_source_ids: list[int],
    doorway_source_ids: list[int],
    wall_source_ids: list[int],
    wall_corner_source_id: int,
) -> tuple[str, dict[str, int]]:
    counts: dict[str, int] = {}

    text, counts["floor"] = INTERIOR_FLOOR_IDS_RE.subn(
        "interior_floor_source_ids = " + _format_id_list(floor_source_ids),
        text,
    )

    text, counts["threshold"] = _replace_or_insert_after(
        text,
        INTERIOR_THRESHOLD_IDS_RE,
        "interior_threshold_source_ids = " + _format_id_list(threshold_source_ids),
        r'^interior_floor_source_ids = Array\[int\]\(\[[^\]]*\]\)$',
    )

    text, counts["doorway"] = _replace_or_insert_after(
        text,
        INTERIOR_DOORWAY_IDS_RE,
        "interior_doorway_source_ids = " + _format_id_list(doorway_source_ids),
        r'^interior_threshold_source_ids = Array\[int\]\(\[[^\]]*\]\)$',
    )

    text, counts["wall_array"] = _replace_or_insert_after(
        text,
        INTERIOR_WALL_IDS_RE,
        "interior_wall_source_ids = " + _format_id_list(wall_source_ids),
        r'^interior_floor_source_ids = Array\[int\]\(\[[^\]]*\]\)$',
    )

    fallback_wall_id = wall_source_ids[0] if wall_source_ids else -1
    text, counts["wall"] = INTERIOR_WALL_ID_RE.subn(
        "interior_wall_source_id = " + str(fallback_wall_id),
        text,
    )
    text, counts["corner"] = INTERIOR_WALL_CORNER_ID_RE.subn(
        "interior_wall_corner_source_id = " + str(wall_corner_source_id),
        text,
    )
    return text, counts


def _next_source_id(used_source_ids: set[int], start: int) -> tuple[int, int]:
    source_id = start
    while source_id in used_source_ids:
        source_id += 1
    used_source_ids.add(source_id)
    return source_id, source_id + 1


def _register_tile_source(
    path: Path,
    path_to_source_id: dict[str, int],
    used_ext_ids: set[str],
    used_sub_ids: set[str],
    used_source_ids: set[int],
    next_source_id: int,
    new_ext_lines: list[str],
    new_sub_blocks: list[str],
    new_source_lines: list[str],
) -> tuple[int, int]:
    res_path = RES_PREFIX + path.name
    existing_source_id = path_to_source_id.get(res_path)
    if existing_source_id is not None:
        return existing_source_id, next_source_id

    source_id, next_source_id = _next_source_id(used_source_ids, next_source_id)
    slug = _slug(path)
    ext_id = f"{source_id}_interior_{slug}"
    suffix = 1
    while ext_id in used_ext_ids:
        suffix += 1
        ext_id = f"{source_id}_interior_{slug}_{suffix}"
    used_ext_ids.add(ext_id)

    sub_id = f"TileSetAtlasSource_interior_{slug}"
    suffix = 1
    while sub_id in used_sub_ids:
        suffix += 1
        sub_id = f"TileSetAtlasSource_interior_{slug}_{suffix}"
    used_sub_ids.add(sub_id)

    new_ext_lines.append(f'[ext_resource type="Texture2D" path="{res_path}" id="{ext_id}"]')
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
    return source_id, next_source_id


def register(dry_run: bool = False) -> int:
    floor_candidates = sorted(RUNTIME_DIR.glob(FLOOR_GLOB))
    threshold_candidates = sorted(RUNTIME_DIR.glob(THRESHOLD_GLOB))
    doorway_candidates = sorted(RUNTIME_DIR.glob(DOORWAY_GLOB))
    wall_candidates = sorted(RUNTIME_DIR.glob(WALL_GLOB))
    if not floor_candidates and not threshold_candidates and not doorway_candidates and not wall_candidates:
        raise RuntimeError(
            f"No {FLOOR_GLOB}, {THRESHOLD_GLOB}, {DOORWAY_GLOB}, or {WALL_GLOB} files found under {RUNTIME_DIR}"
        )

    tileset_text = _read(TILESET_PATH)
    ext_id_to_path, sub_id_to_ext_id, source_id_to_sub_id = _parse_tileset(tileset_text)
    tileset_text, pruned_paths = _remove_stale_interior_sources(
        tileset_text,
        ext_id_to_path,
        sub_id_to_ext_id,
        source_id_to_sub_id,
    )
    if pruned_paths:
        ext_id_to_path, sub_id_to_ext_id, source_id_to_sub_id = _parse_tileset(tileset_text)
    path_to_source_id = _build_path_to_source_id(ext_id_to_path, sub_id_to_ext_id, source_id_to_sub_id)
    used_ext_ids = set(ext_id_to_path.keys())
    used_sub_ids = set(sub_id_to_ext_id.keys()) | set(source_id_to_sub_id.values())
    used_source_ids = set(source_id_to_sub_id.keys())

    next_source_id = max(used_source_ids, default=-1) + 1
    new_ext_lines: list[str] = []
    new_sub_blocks: list[str] = []
    new_source_lines: list[str] = []
    floor_source_ids: list[int] = []
    threshold_source_ids: list[int] = []
    doorway_source_ids: list[int] = []
    wall_source_ids: list[int] = []
    wall_corner_source_ids: list[int] = []

    for path in floor_candidates:
        source_id, next_source_id = _register_tile_source(
            path,
            path_to_source_id,
            used_ext_ids,
            used_sub_ids,
            used_source_ids,
            next_source_id,
            new_ext_lines,
            new_sub_blocks,
            new_source_lines,
        )
        floor_source_ids.append(source_id)

    for path in threshold_candidates:
        source_id, next_source_id = _register_tile_source(
            path,
            path_to_source_id,
            used_ext_ids,
            used_sub_ids,
            used_source_ids,
            next_source_id,
            new_ext_lines,
            new_sub_blocks,
            new_source_lines,
        )
        threshold_source_ids.append(source_id)

    for path in doorway_candidates:
        source_id, next_source_id = _register_tile_source(
            path,
            path_to_source_id,
            used_ext_ids,
            used_sub_ids,
            used_source_ids,
            next_source_id,
            new_ext_lines,
            new_sub_blocks,
            new_source_lines,
        )
        doorway_source_ids.append(source_id)

    for path in wall_candidates:
        source_id, next_source_id = _register_tile_source(
            path,
            path_to_source_id,
            used_ext_ids,
            used_sub_ids,
            used_source_ids,
            next_source_id,
            new_ext_lines,
            new_sub_blocks,
            new_source_lines,
        )
        if "corner" in path.stem:
            wall_corner_source_ids.append(source_id)
        else:
            wall_source_ids.append(source_id)

    if new_ext_lines:
        tileset_text = _insert_before_first_subresource(tileset_text, "\n".join(new_ext_lines))
        tileset_text = _insert_before_resource(tileset_text, "\n\n".join(new_sub_blocks))
        tileset_text = _insert_sources_after_last_source(tileset_text, new_source_lines)

    procgen_text = _read(PROCGEN_SCENE_PATH)
    wall_corner_source_id = wall_corner_source_ids[0] if wall_corner_source_ids else -1
    procgen_text, replaced_counts = _refresh_procgen_scene(
        procgen_text,
        floor_source_ids,
        threshold_source_ids,
        doorway_source_ids,
        wall_source_ids,
        wall_corner_source_id,
    )
    missing_keys = [key for key, count in replaced_counts.items() if count == 0]
    if missing_keys:
        raise RuntimeError("Could not refresh proc_gen_map.tscn fields: " + ", ".join(missing_keys))

    print("Interior floor source IDs: " + ", ".join(str(value) for value in floor_source_ids))
    print("Interior threshold source IDs: " + (", ".join(str(value) for value in threshold_source_ids) if threshold_source_ids else "<none>"))
    print("Interior doorway source IDs: " + (", ".join(str(value) for value in doorway_source_ids) if doorway_source_ids else "<none>"))
    print("Interior wall source IDs: " + (", ".join(str(value) for value in wall_source_ids) if wall_source_ids else "<none>"))
    print("Interior wall corner source ID: " + (str(wall_corner_source_id) if wall_corner_source_id >= 0 else "<none>"))
    if new_source_lines:
        print("Added TileSet sources:")
        for line in new_source_lines:
            print("  " + line)
    else:
        print("No new TileSet sources needed")
    if pruned_paths:
        print("Pruned missing interior TileSet sources:")
        for path in pruned_paths:
            print("  " + path)

    if not dry_run:
        _write(TILESET_PATH, tileset_text)
        _write(PROCGEN_SCENE_PATH, procgen_text)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="report changes without writing files")
    args = parser.parse_args()
    return register(dry_run=args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
