#!/usr/bin/env python3
"""Stage the user-approved Lords of Pain DEMO subset through Asset V2."""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asset_contract import load_family  # noqa: E402
from asset_plan import generate_plan  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN = ROOT / "custodian"
SOURCE = ROOT / "archive/dev/LordsOfPain"
FAMILIES = CUSTODIAN / "content/metadata/assets/families"
SOURCE_WORK = CUSTODIAN / "asset_drop/source_work/dev/lords_of_pain"
INBOX = CUSTODIAN / "asset_drop/inbox"
MANIFEST = CUSTODIAN / "content/data/dev/lords_of_pain/gallery_manifest.json"
LICENSE = "archive/dev/LordsOfPain/Licence.txt"
DIRECTIONS = ("N", "NNE", "NE", "NEE", "E", "SEE", "SE", "SSE", "S", "SSW", "SW", "SWW", "W", "NWW", "NW", "NNW")
ANGLE_RE = re.compile(r"_(N|NNE|NE|NEE|E|SEE|SE|SSE|S|SSW|SW|SWW|W|NWW|NW|NNW)_([0-9.]+)_([0-9]+)\.png$", re.I)


def _source_state(state: str, glob: str) -> dict[str, list[Path]]:
    grouped: dict[str, list[Path]] = {}
    for path in sorted(SOURCE.glob(glob)):
        match = ANGLE_RE.search(path.name)
        if not match:
            raise ValueError(f"source frame has no direction/index suffix: {path}")
        direction = match.group(1).upper()
        grouped.setdefault(direction, []).append(path)
    if tuple(d for d in DIRECTIONS if d in grouped) != DIRECTIONS:
        raise ValueError(f"{state}: expected all 16 directions, found {sorted(grouped)}")
    for direction, paths in grouped.items():
        paths.sort(key=lambda path: int(ANGLE_RE.search(path.name).group(3)))
        indices = [int(ANGLE_RE.search(path.name).group(3)) for path in paths]
        if indices != list(range(len(paths))):
            raise ValueError(f"{state}/{direction}: non-contiguous frame indices {indices}")
    return grouped


def _contract(family_id: str, kind: str, states: dict[str, dict], width: int, height: int) -> dict:
    return {
        "schema": "custodian.asset_family.v2",
        "id": family_id,
        "kind": kind,
        "priority": "P2",
        "runtime": {"domain": "sprites/dev/lords_of_pain", "owner": family_id},
        "canvas": {"width": width, "height": height},
        "direction_policy": "omni",
        "auto_mirror": False,
        "states": states,
        "aliases": {},
        "consumers": [{"type": "manifest", "path": "res://content/data/dev/lords_of_pain/gallery_manifest.json"}],
    }


def _stage_family(family_id: str, kind: str, specs: list[dict]) -> list[dict]:
    source_dir = SOURCE_WORK / family_id
    inbox_dir = INBOX / family_id
    source_dir.mkdir(parents=True, exist_ok=True)
    inbox_dir.mkdir(parents=True, exist_ok=True)
    states: dict[str, dict] = {}
    manifest_states: list[dict] = []
    family_size: tuple[int, int] | None = None
    for spec in specs:
        state_id = spec["id"]
        originals = spec["files"]
        if spec["animated"]:
            images = [Image.open(path).convert("RGBA") for path in originals]
            sizes = {image.size for image in images}
            if len(sizes) != 1:
                raise ValueError(f"{family_id}/{state_id}: inconsistent frame sizes {sizes}")
            frame_width, frame_height = images[0].size
            strip = Image.new("RGBA", (frame_width * len(images), frame_height), (0, 0, 0, 0))
            for index, image in enumerate(images):
                strip.alpha_composite(image, (index * frame_width, 0))
            layout = "horizontal_strip"
        else:
            if len(originals) != 1:
                raise ValueError(f"{family_id}/{state_id}: static state must have one source")
            image = Image.open(originals[0]).convert("RGBA")
            frame_width, frame_height = image.size
            strip = image.copy()
            layout = "copy"
        size = (frame_width, frame_height)
        if family_size is None:
            family_size = size
        elif family_size != size:
            raise ValueError(f"{family_id}: states must share a canvas, got {size} vs {family_size}")
        master = source_dir / f"{state_id}_source.png"
        normalized = inbox_dir / f"{state_id}.png"
        strip.save(master, optimize=False)
        shutil.copy2(master, normalized)
        state = {
            "required": True,
            "layer": spec["layer"],
            "action_group": spec["group"],
            "variant": state_id,
            "layout": layout,
            "frame_width": frame_width,
            "frame_height": frame_height,
        }
        if spec["animated"]:
            state.update({"animation": True, "frames": len(originals), "fps": spec["fps"]})
        states[state_id] = state
        manifest_states.append({
            **{key: spec[key] for key in ("semantic", "logical_state", "direction", "animation_name", "fps", "loop") if key in spec},
            "family_id": family_id,
            "state_id": state_id,
            "source_files": [path.relative_to(ROOT).as_posix() for path in originals],
            "source_master": master.relative_to(ROOT).as_posix(),
            "inbox_path": normalized.relative_to(ROOT).as_posix(),
            "dimensions": [strip.width, strip.height],
            "frame_size": [frame_width, frame_height],
            "frame_count": len(originals),
            "animated": spec["animated"],
            "directions": [spec["direction"]] if spec.get("direction") else ["omni"],
            "license": LICENSE,
        })
    assert family_size is not None
    contract = _contract(family_id, kind, states, *family_size)
    path = FAMILIES / f"{family_id}.asset.json"
    path.write_text(json.dumps(contract, indent=2) + "\n")
    return manifest_states


def _animation_specs(semantic: str, family_id: str, state: str, glob: str, logical: str, fps: int, loop: bool) -> tuple[str, list[dict]]:
    grouped = _source_state(state, glob)
    specs = []
    for direction in DIRECTIONS:
        state_id = f"{logical}_{direction.lower()}"
        specs.append({
            "id": state_id,
            "semantic": semantic,
            "logical_state": logical,
            "animation_name": state,
            "direction": direction,
            "files": grouped[direction],
            "animated": len(grouped[direction]) > 1,
            "layer": "body" if semantic in {"warrior", "skeleton"} else "body",
            "group": "actor" if semantic in {"warrior", "skeleton"} else "pickup",
            "fps": fps,
            "loop": loop,
        })
    return family_id, specs


def main() -> int:
    families: dict[str, tuple[str, list[dict]]] = {}
    for state, glob, semantic, family_id, logical, fps, loop in (
        ("warrior_armed_idle", "playable character/warrior/warrior_armed_idle/**/*.png", "warrior", "dev_lop_warrior", "armed_idle", 6, True),
        ("warrior_armed_walk", "playable character/warrior/warrior_armed_walk/**/*.png", "warrior", "dev_lop_warrior", "armed_walk", 8, True),
        ("skeleton_default_walk", "enemy/skeleton/skeleton_default_walk*.png", "skeleton", "dev_lop_skeleton", "default_walk", 8, True),
        ("skeleton_special_death", "enemy/skeleton/skeleton_special_death/**/*.png", "skeleton", "dev_lop_skeleton", "special_death", 8, False),
        ("gold_drop", "prop/gold_drop/**/*.png", "gold_drop", "dev_lop_gold_drop", "idle", 8, True),
    ):
        fid, specs = _animation_specs(semantic, family_id, state, glob, logical, fps, loop)
        families.setdefault(fid, ("enemy" if semantic in {"warrior", "skeleton"} else "world_prop", []))[1].extend(specs)

    static_specs = (
        ("dev_lop_glint", "effect", "glint", "glint", "vfx/glint/glint_*.png", "fx", "effect"),
        ("dev_lop_ground_stone", "tile", "ground_stone", "ground_stone", "environment/ground_stone1.png", "underlay", "ground"),
        ("dev_lop_highlight", "ui", "highlight", "highlight_yellow", "user interface/highlight/highlight_yellow.png", "ui", "highlight"),
        ("dev_lop_loot_indicator", "ui", "loot_indicator", "loot_indicator_yellow", "user interface/loot-indicator/loot_indicator_yellow.png", "ui", "loot_indicator"),
    )
    for family_id, kind, semantic, state_id, glob, layer, group in static_specs:
        files = sorted(SOURCE.glob(glob))
        if family_id == "dev_lop_glint":
            files.sort(key=lambda path: int(path.stem.rsplit("_", 1)[1]))
            state_id = "glint"
            specs = [{"id": state_id, "semantic": semantic, "logical_state": state_id, "files": files, "animated": True, "layer": layer, "group": group, "fps": 8, "loop": True}]
        else:
            if len(files) != 1:
                raise ValueError(f"{family_id}: expected exactly one source, found {len(files)}")
            specs = [{"id": state_id, "semantic": semantic, "logical_state": state_id, "files": files, "animated": False, "layer": layer, "group": group}]
        families[family_id] = (kind, specs)

    rows = []
    for family_id, (kind, specs) in sorted(families.items()):
        rows.extend(_stage_family(family_id, kind, specs))
    for family_id in sorted(families):
        family = load_family(FAMILIES / f"{family_id}.asset.json")
        plan = generate_plan(family, INBOX / family_id, CUSTODIAN, no_mirror=True)
        if not plan.can_apply:
            raise ValueError(f"{family_id}: Asset V2 plan failed: {list(plan.errors)}")
        for asset in plan.assets:
            matching = [row for row in rows if row["family_id"] == family_id and row["state_id"] == asset.state_id]
            if len(matching) != 1 or not asset.outputs:
                raise ValueError(f"{family_id}/{asset.state_id}: manifest/runtime plan mismatch")
            matching[0]["runtime_path"] = "res://" + asset.outputs[0].target_relative_path.as_posix()
    payload = {
        "schema": "custodian.dev_lop_gallery_manifest.v1",
        "scope": "Asset Index (DEMO) and Animation Index (DEMO); user-approved exclusions applied",
        "source_pack": "archive/dev/LordsOfPain",
        "license_path": LICENSE,
        "asset_index": "archive/dev/LordsOfPain/Asset Index (DEMO).txt",
        "animation_index": "archive/dev/LordsOfPain/Animation Index (DEMO).txt",
        "excluded_by_user": [
            {"semantic_id": item, "index_entry": entry, "reason": "no matching source files in hydrated DEMO pack; excluded by user direction"}
            for item, entry in (("cursor_gauntlet", "Cursor Gauntlet x1"), ("rocks", "Rocks"), ("mushrooms", "Mushrooms"))
        ],
        "included_semantics": ["warrior", "skeleton", "highlight", "loot_indicator", "gold_drop", "glint", "ground_stone"],
        "animation_entries": sorted({row["animation_name"] for row in rows if "animation_name" in row}),
        "states": rows,
    }
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"staged {len(rows)} Asset V2 states across {len(families)} families")
    print(MANIFEST.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
