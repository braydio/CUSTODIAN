#!/usr/bin/env python3
"""Build the bespoke Forlorn Ritualant encounter SpriteFrames resource."""
from __future__ import annotations

import argparse
import struct
import sys
from dataclasses import dataclass
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[2]
RUNTIME_DIR = PROJECT_DIR / "content/sprites/enemies/forlorn_ritualant/runtime"
OUTPUT_PATH = PROJECT_DIR / "content/tiles/encounters/ritualant_set/runtime/forlorn_ritualant_animations.tres"
FRAME_SIZE = 128


@dataclass(frozen=True)
class Animation:
    name: str
    relative_path: str
    frames: int
    fps: float
    loop: bool


ANIMATIONS = (
    Animation("dissolve", "body/death/enemy_forlorn_ritualant__body__death__dissolve__s__8f__128.png", 8, 6.0, False),
    Animation("hostile_idle", "enemy_forlorn_ritualant__body__hostile_idle__s__6f__128.png", 6, 5.0, True),
    Animation("idle", "enemy_forlorn_ritualant__body__idle__s__7f__128.png", 8, 5.0, True),
    Animation("kneel_idle", "enemy_forlorn_ritualant__body__idle__s__7f__128.png", 8, 5.0, True),
    Animation("ninth_answer", "body/special/enemy_forlorn_ritualant__body__special__ninth_answer__s__8f__128.png", 8, 8.0, False),
    Animation("orra_late", "body/special/enemy_forlorn_ritualant__body__special__orra_late__s__8f__128.png", 8, 8.0, False),
    Animation("pin_strike", "enemy_forlorn_ritualant__body__pin_strike__s__10f__128.png", 10, 5.0, False),
    Animation("rise", "enemy_forlorn_ritualant__body__rise__s__4f__128.png", 4, 5.0, False),
    Animation("thread_pull", "enemy_forlorn_ritualant__body__thread_pull__s__9f__128.png", 9, 5.0, False),
    Animation("death_violent", "body/death/enemy_forlorn_ritualant__body__death__death_violent__s__8f__128.png", 8, 8.0, False),
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if the generated resource differs from disk.")
    parser.add_argument("--dry-run", action="store_true", help="Validate and print the owned output without writing it.")
    args = parser.parse_args()
    try:
        _validate_inputs()
        rendered = _render()
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return 1

    if args.check:
        if not OUTPUT_PATH.is_file() or OUTPUT_PATH.read_text(encoding="utf-8") != rendered:
            print(f"stale generated resource: {OUTPUT_PATH.relative_to(PROJECT_DIR)}", file=sys.stderr)
            return 1
        print(f"[OK] {OUTPUT_PATH.relative_to(PROJECT_DIR)}")
        return 0
    if args.dry_run:
        print(f"[DRY RUN] {OUTPUT_PATH.relative_to(PROJECT_DIR)} ({len(ANIMATIONS)} animations)")
        return 0
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(rendered, encoding="utf-8")
    print(f"[WROTE] {OUTPUT_PATH.relative_to(PROJECT_DIR)} ({len(ANIMATIONS)} animations)")
    return 0


def _validate_inputs() -> None:
    for animation in ANIMATIONS:
        path = RUNTIME_DIR / animation.relative_path
        if not path.is_file():
            raise ValueError(f"missing required Ritualant strip: {path.relative_to(PROJECT_DIR)}")
        width, height = _png_size(path)
        expected_width = animation.frames * FRAME_SIZE
        if (width, height) != (expected_width, FRAME_SIZE):
            raise ValueError(
                f"{path.relative_to(PROJECT_DIR)}: expected {animation.frames} x "
                f"{FRAME_SIZE}x{FRAME_SIZE} frames ({expected_width}x{FRAME_SIZE}), found {width}x{height}"
            )


def _png_size(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not a PNG: {path.relative_to(PROJECT_DIR)}")
    return struct.unpack(">II", header[16:24])


def _render() -> str:
    unique_paths = tuple(dict.fromkeys(animation.relative_path for animation in ANIMATIONS))
    ext_ids = {path: index for index, path in enumerate(unique_paths, start=1)}
    lines = ['[gd_resource type="SpriteFrames" format=3 uid="uid://htpgv207bj6s"]', ""]
    for path, ext_id in ext_ids.items():
        resource_path = "res://" + (RUNTIME_DIR / path).relative_to(PROJECT_DIR).as_posix()
        lines.append(f'[ext_resource type="Texture2D" path="{resource_path}" id="{ext_id}"]')
    lines.append("")

    sub_ids: dict[tuple[str, int], str] = {}
    sub_index = 1
    for animation in ANIMATIONS:
        for frame in range(animation.frames):
            key = (animation.name, frame)
            sub_id = f"AtlasTexture_{sub_index}"
            sub_ids[key] = sub_id
            lines.extend([
                f'[sub_resource type="AtlasTexture" id="{sub_id}"]',
                f'atlas = ExtResource("{ext_ids[animation.relative_path]}")',
                f"region = Rect2({frame * FRAME_SIZE}, 0, {FRAME_SIZE}, {FRAME_SIZE})",
                "",
            ])
            sub_index += 1

    lines.extend(["[resource]", "animations = ["])
    for index, animation in enumerate(ANIMATIONS):
        if index:
            lines.append(",")
        lines.extend(["{", '"frames": ['])
        for frame in range(animation.frames):
            if frame:
                lines.append(",")
            lines.extend([
                "{",
                '"duration": 1.0,',
                f'"texture": SubResource("{sub_ids[(animation.name, frame)]}")',
                "}",
            ])
        lines.extend([
            "],",
            f'"loop": {str(animation.loop).lower()},',
            f'"name": &"{animation.name}",',
            f'"speed": {animation.fps:.1f}',
            "}",
        ])
    lines.extend(["]", ""])
    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
