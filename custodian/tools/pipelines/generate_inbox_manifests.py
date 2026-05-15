#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


PROJECT_DIR = Path(__file__).resolve().parents[2]
PIPELINE_DIR = PROJECT_DIR / "content" / "sprites" / "_pipeline"
INBOX_DIR = PIPELINE_DIR / "inbox"
INGEST_SCRIPT = Path(__file__).resolve().parent / "ingest.py"


@dataclass(frozen=True)
class SheetInfo:
    basename: str
    owner: str
    layer: str
    action_group: str
    variant: str
    direction: str
    frame_count: int
    frame_size: int
    source_kind: str


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate sprite pipeline manifests for inbox PNGs, then run ingest."
    )
    parser.add_argument("--regen", action="store_true", help="Regenerate manifests even when they already exist.")
    parser.add_argument("--dry-run", action="store_true", help="Generate manifests only and run ingest in dry-run mode.")
    parser.add_argument("--skip-post", action="store_true", help="Forward --skip-post to ingest.py.")
    parser.add_argument(
        "--manifest",
        action="append",
        default=[],
        help="Limit generation to one or more inbox manifests or PNG basenames.",
    )
    args = parser.parse_args()

    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    targets = _resolve_targets(args.manifest)
    if not targets:
        print(f"no inbox PNGs found in {INBOX_DIR}")
        return 0

    generated = 0
    skipped = 0
    for png_path in targets:
        manifest_path = png_path.with_suffix(".json")
        if manifest_path.exists() and not args.regen:
            skipped += 1
            continue

        manifest = _build_manifest(png_path)
        generated += 1
        if args.dry_run:
            print(f"[dry-run] would write {manifest_path.relative_to(PROJECT_DIR)}")
        else:
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
            print(f"wrote {manifest_path.relative_to(PROJECT_DIR)}")

    if generated == 0 and skipped > 0:
        print("all selected inbox PNGs already have manifests; nothing to generate")

    if args.dry_run:
        print("dry-run complete; ingest was not run")
        return 0

    ingest_args = [sys.executable, str(INGEST_SCRIPT)]
    if args.skip_post:
        ingest_args.append("--skip-post")

    result = subprocess.run(ingest_args, cwd=PROJECT_DIR, check=False)
    return result.returncode


def _resolve_targets(requested: list[str]) -> list[Path]:
    pngs = sorted(INBOX_DIR.glob("*.png"))
    if not requested:
        return pngs

    allowed: set[str] = set()
    for item in requested:
        candidate = Path(item)
        allowed.add(candidate.name)
        if candidate.suffix != ".png":
            allowed.add(candidate.with_suffix(".png").name)
            allowed.add(candidate.with_suffix(".json").with_suffix(".png").name)

    return [path for path in pngs if path.name in allowed]


def _build_manifest(png_path: Path) -> dict:
    info = _inspect_sheet(png_path)
    manifest: dict = {
        "source": png_path.name,
        "mode": "copy" if info.source_kind == "copy" else "strip",
        "outputs": _build_outputs(info),
    }
    if info.source_kind != "copy":
        manifest["frame_size"] = [info.frame_size, info.frame_size]
    post_process = _build_post_process(info)
    if post_process:
        manifest["post_process"] = post_process
    return manifest


def _inspect_sheet(png_path: Path) -> SheetInfo:
    basename = png_path.name
    stem = png_path.stem
    parts = stem.split("__")
    if len(parts) >= 6 and parts[0] == "props" and parts[1] == "harvesting_nodes":
        return _inspect_harvesting_node_sheet(png_path, parts)
    if len(parts) < 6:
        if len(parts) < 2:
            raise RuntimeError(
                f"{basename}: expected canonical sprite name or item filename"
            )
        return _inspect_item_sheet(png_path, parts)
    owner = parts[0]
    layer = parts[1]
    action_group = parts[2]
    variant = parts[3]
    direction = parts[4]
    frames_token = parts[5]
    size_token = parts[6] if len(parts) > 6 else ""

    frame_count = _parse_token_count(frames_token, "f", basename)
    frame_size = _parse_token_count(size_token, "", basename)
    source_kind = "copy" if "4dir" in direction or frame_count == 1 else "strip"

    with Image.open(png_path) as image:
        width, height = image.size
    if source_kind == "strip" and height != frame_size:
        raise RuntimeError(
            f"{basename}: strip height {height} does not match declared frame size {frame_size}"
        )
    if source_kind == "strip" and width % frame_size != 0:
        raise RuntimeError(
            f"{basename}: strip width {width} is not divisible by frame size {frame_size}"
        )
    if source_kind == "strip" and width // frame_size != frame_count:
        frame_count = width // frame_size

    return SheetInfo(
        basename=basename,
        owner=owner,
        layer=layer,
        action_group=action_group,
        variant=variant,
        direction=direction,
        frame_count=frame_count,
        frame_size=frame_size,
        source_kind=source_kind,
    )


def _inspect_item_sheet(png_path: Path, parts: list[str]) -> SheetInfo:
    basename = png_path.name
    if len(parts) < 4:
        raise RuntimeError(
            f"{basename}: item filenames should follow <item_type>__<item_name>__<frames>f__<size>.png"
        )
    item_type = parts[0]
    item_name = ("__".join(parts[1:-2]) if len(parts) > 3 else parts[1]).replace("__", "_")
    frames_token = parts[-2]
    size_token = parts[-1]
    with Image.open(png_path) as image:
        width, height = image.size
    frame_count = _parse_token_count(frames_token, "f", basename)
    frame_size = _parse_token_count(size_token, "", basename)
    if frame_count <= 0:
        raise RuntimeError(f"{basename}: item frame count must be positive")
    if height != frame_size:
        raise RuntimeError(f"{basename}: item strip height {height} must equal frame size {frame_size}")
    if width % frame_size != 0:
        raise RuntimeError(f"{basename}: item strip width {width} must be divisible by frame size {frame_size}")
    if width // frame_size != frame_count:
        frame_count = width // frame_size
    return SheetInfo(
        basename=basename,
        owner="items",
        layer=item_type,
        action_group="item",
        variant=item_name,
        direction="omni",
        frame_count=frame_count,
        frame_size=frame_size,
        source_kind="strip",
    )


def _inspect_harvesting_node_sheet(png_path: Path, parts: list[str]) -> SheetInfo:
    basename = png_path.name
    if len(parts) < 7:
        raise RuntimeError(
            f"{basename}: harvesting node filenames should follow props__harvesting_nodes__<node_type>__node__<state>__<frames>f__<size>.png"
        )
    node_type = parts[2]
    if parts[3] != "node":
        raise RuntimeError(f"{basename}: harvesting node filenames must include __node__")
    state = "__".join(parts[4:-2]) if len(parts) > 6 else parts[4]
    frames_token = parts[-2]
    size_token = parts[-1]
    with Image.open(png_path) as image:
        width, height = image.size
    frame_count = _parse_token_count(frames_token, "f", basename)
    frame_size = _parse_token_count(size_token, "", basename)
    if height != frame_size:
        raise RuntimeError(
            f"{basename}: harvesting node strip height {height} must equal frame size {frame_size}"
        )
    if width % frame_size != 0:
        raise RuntimeError(
            f"{basename}: harvesting node strip width {width} must be divisible by frame size {frame_size}"
        )
    if width // frame_size != frame_count:
        frame_count = width // frame_size
    return SheetInfo(
        basename=basename,
        owner="props",
        layer="harvesting_nodes",
        action_group=node_type,
        variant=state,
        direction="omni",
        frame_count=frame_count,
        frame_size=frame_size,
        source_kind="strip",
    )


def _parse_token_count(token: str, suffix: str, basename: str) -> int:
    if suffix and not token.endswith(suffix):
        raise RuntimeError(f"{basename}: expected token ending in {suffix!r}, got {token!r}")
    raw = token[: -len(suffix)] if suffix else token
    if not raw.isdigit():
        raise RuntimeError(f"{basename}: expected numeric token, got {token!r}")
    return int(raw)


def _build_outputs(info: SheetInfo) -> list[dict]:
    source_rel = _canonical_runtime_path(info)
    outputs = [
        {
            "path": source_rel,
            "layout": "copy" if info.source_kind == "copy" else "horizontal_strip",
            **(
                {}
                if info.source_kind == "copy"
                else {"select": {"type": "range", "start": 0, "count": info.frame_count}}
            ),
        }
    ]

    compatibility = _compatibility_outputs(info)
    outputs.extend(compatibility)
    return outputs


def _canonical_runtime_path(info: SheetInfo) -> str:
    if info.owner == "operator":
        if info.layer == "body":
            return f"operator/runtime/body/{info.action_group}/{info.basename}"
        if info.layer == "weapon":
            return f"operator/runtime/weapon/{info.action_group}/{info.basename}"
        if info.layer == "fx":
            return f"operator/runtime/overlays/{info.action_group}/{info.basename}"
    if info.owner == "enemy" or info.owner.startswith("enemy_") or info.owner == "drone":
        return f"enemies/{info.owner}/runtime/{info.layer}/{info.basename}"
    if info.owner in {"fallen_star_katana", "carbine_rifle", "carbine_rifle_mk1"}:
        return f"weapons/{info.owner}/animations/{info.basename}"
    if info.owner in {"command_terminal", "fabricator_terminal", "computer_terminal", "builder_terminal"}:
        return f"environment/props/terminal/runtime/body/{info.basename}"
    if info.owner in {"portal_ring", "hit_spark", "muzzle_flash", "block_spark"} or info.owner.endswith("_spark") or info.owner.endswith("_ring"):
        return f"effects/runtime/{info.basename}"
    if info.owner in {"hover_buggy", "vehicle", "buggy"}:
        return f"vehicles/{info.owner}/runtime/{info.basename}"
    if info.owner in {"turret", "gunner", "repeater", "sniper"} or info.layer == "turret":
        return f"turrets/{info.owner}/{info.basename}"
    if info.owner == "props" and info.layer == "harvesting_nodes":
        return f"props/harvesting_nodes/{info.action_group}/{info.action_group}__node__{info.variant}__{info.frame_count}f__{info.frame_size}.png"
    if info.owner == "items" or info.layer == "item" or info.action_group == "item":
        return _items_runtime_path(info)
    return f"{info.owner}/runtime/{info.layer}/{info.basename}"


def _compatibility_outputs(info: SheetInfo) -> list[dict]:
    outputs: list[dict] = []
    if info.owner.startswith("enemy_") or info.owner == "drone":
        outputs.append({"path": f"enemies/{info.owner}/{info.basename}", "layout": "copy"})
    return outputs


def _items_runtime_path(info: SheetInfo) -> str:
    return f"items/{info.layer}/{info.variant}.png"


def _build_post_process(info: SheetInfo) -> list[str]:
    post_process: list[str] = []
    if info.owner == "operator" and info.layer == "body":
        post_process.append("operator_curated_resources")
    if info.owner.startswith("enemy_") or info.owner == "drone":
        post_process.append("enemy_runtime_import")
    return post_process


if __name__ == "__main__":
    raise SystemExit(main())
