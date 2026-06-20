#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNTIME_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "animation_review"
DEFAULT_DIRECTIONS = ("s", "se", "e", "ne", "n", "nw", "w", "sw")
BODY_LAYERS = ("lower_body", "upper_body")


@dataclass
class Strip:
    path: Path
    frames: int
    frame_size: int
    image: Image.Image


@dataclass
class ActionPreview:
    action: str
    direction: str
    body_source: str | None = None
    fx_source: str | None = None
    missing_layers: list[str] = field(default_factory=list)
    frames: int = 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Compose Operator modular/action runtime strips for QA preview.")
    parser.add_argument("--loadout", default="unarmed")
    parser.add_argument("--action")
    parser.add_argument("--sequence")
    parser.add_argument("--directions", default=",".join(DEFAULT_DIRECTIONS))
    parser.add_argument("--include-fx", action="store_true")
    parser.add_argument("--no-fx", action="store_true")
    parser.add_argument("--runtime-root", type=Path, default=DEFAULT_RUNTIME_ROOT)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--frame-size", type=int, default=96)
    parser.add_argument("--missing-placeholder", action="store_true")
    args = parser.parse_args()

    actions = parse_actions(args.action, args.sequence)
    directions = [d.strip() for d in args.directions.split(",") if d.strip()]
    include_fx = args.include_fx and not args.no_fx

    args.output_dir.mkdir(parents=True, exist_ok=True)
    strips: dict[str, Image.Image] = {}
    report: list[ActionPreview] = []
    for direction in directions:
        strip, direction_report = build_direction_strip(
            args.runtime_root,
            args.loadout,
            actions,
            direction,
            args.frame_size,
            include_fx,
            args.missing_placeholder,
        )
        strips[direction] = strip
        report.extend(direction_report)
        suffix = "_".join(actions)
        out_path = args.output_dir / f"operator_preview__{args.loadout}__{suffix}__{direction}.png"
        strip.save(out_path)

    grid = build_grid(strips, args.frame_size)
    suffix = "_".join(actions)
    grid_path = args.output_dir / f"operator_preview__{args.loadout}__{suffix}__grid.png"
    grid.save(grid_path)

    report_path = args.output_dir / f"operator_preview__{args.loadout}__{suffix}__report.json"
    report_payload = {
        "loadout": args.loadout,
        "actions": actions,
        "directions": directions,
        "include_fx": include_fx,
        "output_dir": str(args.output_dir),
        "grid": str(grid_path),
        "previews": [asdict(item) for item in report],
    }
    report_path.write_text(json.dumps(report_payload, indent=2), encoding="utf-8")

    missing = sum(1 for item in report if item.missing_layers)
    print(f"Wrote {len(directions)} direction previews and grid to {args.output_dir}")
    print(f"Missing action/direction records: {missing}")
    print(f"Report: {report_path}")
    return 0


def parse_actions(action: str | None, sequence: str | None) -> list[str]:
    if sequence:
        actions = [part.strip() for part in sequence.split(",") if part.strip()]
    elif action:
        actions = [action.strip()]
    else:
        raise SystemExit("Pass --action or --sequence.")
    if not actions:
        raise SystemExit("No actions requested.")
    return actions


def build_direction_strip(
    runtime_root: Path,
    loadout: str,
    actions: list[str],
    direction: str,
    frame_size: int,
    include_fx: bool,
    missing_placeholder: bool,
) -> tuple[Image.Image, list[ActionPreview]]:
    frames: list[Image.Image] = []
    report: list[ActionPreview] = []
    for action in actions:
        composed, preview = compose_action(runtime_root, loadout, action, direction, frame_size, include_fx)
        if composed:
            frames.extend(split_frames(composed, frame_size))
        elif missing_placeholder:
            frames.append(Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0)))
        report.append(preview)

    if not frames:
        frames = [Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))]
    strip = Image.new("RGBA", (len(frames) * frame_size, frame_size), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * frame_size, 0))
    return strip, report


def compose_action(
    runtime_root: Path,
    loadout: str,
    action: str,
    direction: str,
    frame_size: int,
    include_fx: bool,
) -> tuple[Image.Image | None, ActionPreview]:
    preview = ActionPreview(action=action, direction=direction)

    lower = find_module_strip(runtime_root, "lower_body", loadout, action, direction, frame_size)
    upper = find_module_strip(runtime_root, "upper_body", loadout, action, direction, frame_size)
    combined = find_module_strip(runtime_root, "combined_body", loadout, action, direction, frame_size)
    action_body = find_action_body_strip(runtime_root, loadout, action, direction, frame_size)

    base: Strip | None = None
    upper_strip: Strip | None = None
    if lower and upper:
        base = lower
        upper_strip = upper
        preview.body_source = f"{lower.path.as_posix()} + {upper.path.as_posix()}"
    elif combined:
        base = combined
        preview.body_source = combined.path.as_posix()
        preview.missing_layers.extend([layer for layer, strip in (("lower_body", lower), ("upper_body", upper)) if not strip])
    elif action_body:
        base = action_body
        preview.body_source = action_body.path.as_posix()
        preview.missing_layers.extend([layer for layer, strip in (("lower_body", lower), ("upper_body", upper)) if not strip])
    else:
        preview.missing_layers.extend(["lower_body", "upper_body"])

    if not base:
        return None, preview

    base_frames = split_frames(base.image, frame_size)
    if upper_strip:
        upper_frames = split_frames(upper_strip.image, frame_size)
        base_frames = composite_frame_lists(base_frames, upper_frames, frame_size)

    if include_fx:
        fx = find_module_strip(runtime_root, "upper_fx", loadout, action, direction, frame_size)
        if not fx:
            fx = find_action_fx_strip(runtime_root, loadout, action, direction, frame_size)
        if fx:
            preview.fx_source = fx.path.as_posix()
            base_frames = composite_frame_lists(base_frames, split_frames(fx.image, frame_size), frame_size)
        else:
            preview.missing_layers.append("upper_fx")

    preview.frames = len(base_frames)
    return join_frames(base_frames, frame_size), preview


def find_module_strip(runtime_root: Path, layer: str, loadout: str, action: str, direction: str, frame_size: int) -> Strip | None:
    module_root = runtime_root / "modules/new_operator" / layer
    patterns = [
        f"actions/{loadout}/{action}/operator__modular_{layer}__{loadout}__{action}__{direction}__*f__{frame_size}.png",
        f"locomotion/{action}/operator__modular_{layer}__{loadout}__{action}__{direction}__*f__{frame_size}.png",
    ]
    if layer == "upper_fx":
        patterns.append(
            f"actions/{loadout}/fast_attack/{action}/operator__modular_upper_fx__{loadout}__{action}__{direction}__*f__{frame_size}.png"
        )
    if layer == "upper_body":
        patterns.append(
            f"actions/{loadout}/fast_attack/{action}/operator__modular_upper_body__{loadout}__{action}__{direction}__*f__{frame_size}.png"
        )
    for pattern in patterns:
        strip = first_matching_strip(module_root, pattern, frame_size)
        if strip:
            return strip
    return None


def find_action_body_strip(runtime_root: Path, loadout: str, action: str, direction: str, frame_size: int) -> Strip | None:
    roots = [
        runtime_root / "actions" / loadout / "fast_attack" / "body",
        runtime_root / "actions" / action.replace("_01", "") / "body",
        runtime_root / "actions" / "dodge" / "body",
    ]
    loadouts = [loadout]
    if action.startswith("dodge"):
        loadouts.append("full")
    for root in roots:
        for candidate_loadout in loadouts:
            pattern = f"operator__body__{candidate_loadout}__{action}__{direction}__*f__{frame_size}.png"
            strip = first_matching_strip(root, pattern, frame_size)
            if strip:
                return strip
    return None


def find_action_fx_strip(runtime_root: Path, loadout: str, action: str, direction: str, frame_size: int) -> Strip | None:
    roots = [
        runtime_root / "actions" / loadout / "fast_attack" / "overlay",
        runtime_root / "actions" / action.replace("_01", "") / "fx",
        runtime_root / "actions" / "dodge" / "fx",
    ]
    loadouts = [loadout]
    if action.startswith("dodge"):
        loadouts.append("full")
    for root in roots:
        for candidate_loadout in loadouts:
            pattern = f"operator__fx__{candidate_loadout}__{action}__{direction}__*f__{frame_size}.png"
            strip = first_matching_strip(root, pattern, frame_size)
            if strip:
                return strip
    return None


def first_matching_strip(root: Path, pattern: str, frame_size: int) -> Strip | None:
    if not root.exists():
        return None
    matches = sorted(root.glob(pattern))
    if not matches:
        return None
    return load_strip(matches[-1], frame_size)


def load_strip(path: Path, default_frame_size: int) -> Strip:
    match = re.search(r"__(\d+)f__(\d+)\.png$", path.name)
    frames = int(match.group(1)) if match else max(1, Image.open(path).width // default_frame_size)
    frame_size = int(match.group(2)) if match else default_frame_size
    image = Image.open(path).convert("RGBA")
    return Strip(path=path, frames=frames, frame_size=frame_size, image=image)


def split_frames(strip: Image.Image, frame_size: int) -> list[Image.Image]:
    frames = max(1, strip.width // frame_size)
    out: list[Image.Image] = []
    for index in range(frames):
        frame = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        crop = strip.crop((index * frame_size, 0, min((index + 1) * frame_size, strip.width), min(frame_size, strip.height)))
        frame.alpha_composite(crop, (0, 0))
        out.append(frame)
    return out


def composite_frame_lists(base_frames: list[Image.Image], overlay_frames: list[Image.Image], frame_size: int) -> list[Image.Image]:
    frame_count = max(len(base_frames), len(overlay_frames))
    out: list[Image.Image] = []
    for index in range(frame_count):
        frame = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        if index < len(base_frames):
            frame.alpha_composite(base_frames[index])
        if index < len(overlay_frames):
            frame.alpha_composite(overlay_frames[index])
        out.append(frame)
    return out


def join_frames(frames: list[Image.Image], frame_size: int) -> Image.Image:
    strip = Image.new("RGBA", (len(frames) * frame_size, frame_size), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * frame_size, 0))
    return strip


def build_grid(strips: dict[str, Image.Image], frame_size: int) -> Image.Image:
    width = max((strip.width for strip in strips.values()), default=frame_size)
    height = max(1, len(strips)) * frame_size
    grid = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    for row, strip in enumerate(strips.values()):
        grid.alpha_composite(strip, (0, row * frame_size))
    return grid


if __name__ == "__main__":
    raise SystemExit(main())
