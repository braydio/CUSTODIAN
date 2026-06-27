#!/usr/bin/env python3
from __future__ import annotations

import argparse
import struct
import sys
from dataclasses import dataclass
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[2]
CONTENT_SPRITES_DIR = PROJECT_DIR / "content" / "sprites"
ACTORS_DIR = PROJECT_DIR / "game" / "actors"
DEFAULT_LAYERS = ("body", "fx")
NON_LOOPING_ACTIONS = {
    "active",
    "burst",
    "death",
    "disabled",
    "fire",
    "hit",
    "impact",
    "muzzle",
    "muzzle_flash",
    "recover",
    "reload",
    "spark",
    "stagger",
    "strike",
    "windup",
    "wake",
}
DEFAULT_SPEEDS = {
    "idle": 5.0,
    "aim": 8.0,
    "walk": 8.0,
    "run": 10.0,
    "fire": 12.0,
    "hit": 10.0,
    "death": 8.0,
    "disabled": 4.0,
    "muzzle_flash": 18.0,
    "impact_spark": 16.0,
}


@dataclass(frozen=True)
class Sheet:
    path: Path
    layer: str
    animation_name: str
    frame_count: int
    frame_size: int
    speed: float
    loop: bool


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build non-Operator actor SpriteFrames from canonical runtime PNG strips."
    )
    parser.add_argument("--domain", required=True, help="Runtime actor domain, e.g. allies or enemies.")
    parser.add_argument("--owner", required=True, help="Actor slug, e.g. allied_infantry_droid.")
    parser.add_argument(
        "--layer",
        action="append",
        choices=DEFAULT_LAYERS,
        help="Layer to rebuild. Defaults to body and fx.",
    )
    parser.add_argument(
        "--frame-size",
        type=int,
        default=0,
        help="Fallback frame size for legacy <owner>__<animation>__<direction>__Nf__size names.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print planned outputs without writing resources.")
    args = parser.parse_args()

    layers = tuple(args.layer) if args.layer else DEFAULT_LAYERS
    actor_runtime_dir = CONTENT_SPRITES_DIR / args.domain / args.owner / "runtime"
    actor_resource_dir = ACTORS_DIR / args.domain / args.owner

    if not actor_runtime_dir.exists():
        print(f"missing actor runtime directory: {actor_runtime_dir.relative_to(PROJECT_DIR)}", file=sys.stderr)
        return 1

    wrote_any = False
    for layer in layers:
        sheets = _collect_sheets(actor_runtime_dir, args.owner, layer, args.frame_size)
        if not sheets:
            print(f"[SKIP] {args.owner} {layer}: no runtime strips")
            continue
        output_path = actor_resource_dir / f"{args.owner}_{layer}_frames.tres"
        if args.dry_run:
            print(f"[DRY RUN] {output_path.relative_to(PROJECT_DIR)}")
            for sheet in sheets:
                print(
                    "  %s: %d frames @ %dpx from %s"
                    % (
                        sheet.animation_name,
                        sheet.frame_count,
                        sheet.frame_size,
                        sheet.path.relative_to(PROJECT_DIR),
                    )
                )
            wrote_any = True
            continue

        actor_resource_dir.mkdir(parents=True, exist_ok=True)
        output_path.write_text(_render_spriteframes_resource(sheets), encoding="utf-8")
        print(f"[WROTE] {output_path.relative_to(PROJECT_DIR)} ({len(sheets)} animations)")
        wrote_any = True

    return 0 if wrote_any else 1


def _collect_sheets(runtime_dir: Path, owner: str, layer: str, fallback_frame_size: int) -> list[Sheet]:
    layer_dir = runtime_dir / layer
    search_dirs = [layer_dir] if layer_dir.exists() else []
    if not search_dirs and runtime_dir.exists():
        search_dirs.append(runtime_dir)

    sheets: list[Sheet] = []
    for search_dir in search_dirs:
        for path in sorted(search_dir.glob("*.png")):
            sheet = _parse_sheet(path, owner, layer, fallback_frame_size)
            if sheet is not None:
                sheets.append(sheet)
    sheets.sort(key=lambda item: item.animation_name)
    return sheets


def _parse_sheet(path: Path, owner: str, expected_layer: str, fallback_frame_size: int) -> Sheet | None:
    parts = path.stem.split("__")
    if not parts or parts[0] != owner:
        return None

    if len(parts) >= 6 and _is_frames_token(parts[-2]) and parts[-1].isdigit():
        layer = parts[1]
        if layer != expected_layer:
            return None
        variant = "__".join(parts[3:-3])
        direction = parts[-3]
        frames_token = parts[-2]
        frame_size = int(parts[-1])
        animation_base = variant or parts[2]
    elif len(parts) >= 5 and _is_frames_token(parts[-2]) and parts[-1].isdigit():
        layer = "fx" if parts[1].startswith("fx") else "body"
        if layer != expected_layer:
            return None
        animation_base = parts[1].removeprefix("fx_")
        direction = parts[-3]
        frames_token = parts[-2]
        frame_size = int(parts[-1])
    elif len(parts) == 3:
        layer = expected_layer
        animation_base = parts[1]
        direction = parts[2]
        frames_token = ""
        frame_size = fallback_frame_size
    else:
        return None

    width, height = _read_png_size(path)
    if frame_size <= 0:
        frame_size = height
    if height != frame_size:
        raise RuntimeError(f"{path.name}: height {height} does not match frame size {frame_size}")
    if width % frame_size != 0:
        raise RuntimeError(f"{path.name}: width {width} is not divisible by frame size {frame_size}")

    frame_count = int(frames_token[:-1]) if frames_token else width // frame_size
    actual_frame_count = width // frame_size
    if frame_count != actual_frame_count:
        frame_count = actual_frame_count

    animation_name = f"{animation_base}_{direction}" if direction and direction != "omni" else animation_base
    speed = _animation_speed(animation_base)
    loop = _animation_loops(animation_base, expected_layer)
    return Sheet(path=path, layer=expected_layer, animation_name=animation_name, frame_count=frame_count, frame_size=frame_size, speed=speed, loop=loop)


def _render_spriteframes_resource(sheets: list[Sheet]) -> str:
    lines: list[str] = ['[gd_resource type="SpriteFrames" format=3]', ""]
    for index, sheet in enumerate(sheets, start=1):
        lines.append(
            '[ext_resource type="Texture2D" path="%s" id="%d"]'
            % (_resource_path(sheet.path), index)
        )
    lines.append("")

    subresource_ids: dict[tuple[int, int], str] = {}
    subresource_index = 1
    for ext_index, sheet in enumerate(sheets, start=1):
        for frame_index in range(sheet.frame_count):
            sub_id = f"AtlasTexture_{subresource_index}"
            subresource_ids[(ext_index, frame_index)] = sub_id
            lines.extend(
                [
                    f'[sub_resource type="AtlasTexture" id="{sub_id}"]',
                    f'atlas = ExtResource("{ext_index}")',
                    "region = Rect2(%d, 0, %d, %d)" % (frame_index * sheet.frame_size, sheet.frame_size, sheet.frame_size),
                    "",
                ]
            )
            subresource_index += 1

    lines.append("[resource]")
    lines.append("animations = [")
    for sheet_index, sheet in enumerate(sheets, start=1):
        if sheet_index > 1:
            lines.append(",")
        lines.append("{")
        lines.append('"frames": [')
        for frame_index in range(sheet.frame_count):
            if frame_index > 0:
                lines.append(",")
            lines.append('{')
            lines.append('"duration": 1.0,')
            lines.append('"texture": SubResource("%s")' % subresource_ids[(sheet_index, frame_index)])
            lines.append("}")
        lines.append("],")
        lines.append('"loop": %s,' % ("true" if sheet.loop else "false"))
        lines.append('"name": &"%s",' % sheet.animation_name)
        lines.append('"speed": %.1f' % sheet.speed)
        lines.append("}")
    lines.append("]")
    lines.append("")
    return "\n".join(lines)


def _animation_speed(animation_base: str) -> float:
    return DEFAULT_SPEEDS.get(animation_base, 12.0)


def _animation_loops(animation_base: str, layer: str) -> bool:
    if layer == "fx":
        return False
    return not any(animation_base == action or animation_base.endswith("_" + action) for action in NON_LOOPING_ACTIONS)


def _is_frames_token(token: str) -> bool:
    return token.endswith("f") and token[:-1].isdigit()


def _read_png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        signature = handle.read(24)
    if len(signature) < 24 or signature[:8] != b"\x89PNG\r\n\x1a\n":
        raise RuntimeError(f"{path.name}: not a PNG file")
    return struct.unpack(">II", signature[16:24])


def _resource_path(path: Path) -> str:
    return "res://" + path.relative_to(PROJECT_DIR).as_posix()


if __name__ == "__main__":
    raise SystemExit(main())
