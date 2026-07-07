#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from shutil import copy2

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = PROJECT_ROOT / "content/sprites/operator/new_operator/modular"
RUNTIME_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime"
MODULE_ROOT = RUNTIME_ROOT / "modules/new_operator"
ACTION_ROOT = RUNTIME_ROOT / "actions/unarmed/fast_attack"
DODGE_ROOT = RUNTIME_ROOT / "actions/dodge"

DIRECTIONS = ("s", "se", "e", "ne", "n", "nw", "w", "sw")
DIRECTION_TO_SUFFIX = {
    "s": "down",
    "se": "down_right",
    "e": "right",
    "ne": "up_right",
    "n": "up",
    "nw": "up_left",
    "w": "left",
    "sw": "down_left",
}
MODULAR_LAYER_OUTPUTS = {
    "modular_body_lower": "lower_body",
    "modular_body_upper": "upper_body",
    "modular_combined_body": "combined_body",
    "modular_lower_body": "lower_body",
    "modular_ranged_weapon": "ranged_weapon",
    "modular_sidearm": "sidearm",
    "modular_upper_body": "upper_body",
    "modular_upper_fx": "upper_fx",
    "modular_wardrobe_cape": "wardrobe_cape",
}
KNOWN_LOADOUTS = {"unarmed", "sidearm", "ranged_2h"}


@dataclass(frozen=True)
class SheetSpec:
    path: Path
    frames: int
    direction: str
    frame_width: int
    frame_height: int


def main() -> int:
    parser = argparse.ArgumentParser(description="Build stable runtime assets from modular operator source sheets.")
    parser.add_argument("--source-root", type=Path, default=SOURCE_ROOT)
    parser.add_argument("--module-root", type=Path, default=MODULE_ROOT)
    parser.add_argument("--action-root", type=Path, default=ACTION_ROOT)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--remove-superseded",
        action="store_true",
        help="Remove older generated sibling modules with the same semantic animation identity.",
    )
    args = parser.parse_args()

    source_root = args.source_root
    module_root = args.module_root
    action_root = args.action_root

    if not source_root.exists():
        raise SystemExit(f"missing source root: {source_root}")

    generated: list[Path] = []
    generated.extend(_build_lower_body_modules(source_root, module_root, args.dry_run))
    generated.extend(_build_upper_body_modules(source_root, module_root, args.dry_run))
    generated.extend(_build_upper_body_action_modules(source_root, module_root, args.dry_run))
    generated.extend(_build_sidearm_action_modules(source_root, module_root, args.dry_run))
    generated.extend(_build_ranged_2h_stance_modules(source_root, module_root, args.dry_run))
    generated.extend(_build_full_dodge_runtime(source_root, DODGE_ROOT, args.dry_run))
    generated.extend(_build_fast_attack_runtime(source_root, action_root, args.dry_run))
    generated.extend(_build_generic_action_modules(source_root, module_root, args.dry_run))
    if args.remove_superseded:
        _remove_superseded_generated(generated, args.dry_run)

    for path in generated:
        print(path.relative_to(PROJECT_ROOT))
    print(f"built {len(generated)} modular operator runtime sheets")
    return 0


def _build_lower_body_modules(source_root: Path, module_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    lower_root = module_root / "lower_body"

    for direction in DIRECTIONS:
        generated.extend(
            _copy_lower_module(
                source_root,
                lower_root,
                canonical_action="run_01",
                direction=direction,
                output_group="locomotion/run_01",
                fallbacks=("action_01",),
                dry_run=dry_run,
            )
        )
        generated.extend(
            _copy_lower_module(
                source_root,
                lower_root,
                canonical_action="walk_01",
                direction=direction,
                output_group="locomotion/walk_01",
                fallbacks=("action_01", "run_01"),
                dry_run=dry_run,
            )
        )
        generated.extend(
            _copy_lower_module(
                source_root,
                lower_root,
                canonical_action="idle_01",
                direction=direction,
                output_group="locomotion/idle_01",
                fallbacks=("action_01", "run_01"),
                dry_run=dry_run,
            )
        )

    return generated


def _build_upper_body_action_modules(source_root: Path, module_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    fast_root = source_root / "fast_attack"
    layer_actions = {
        "lower_body": ("fast_windup_01", "fast_strike_01", "fast_recovery_01"),
        "upper_body": ("fast_windup_01", "fast_strike_01", "fast_recovery_01"),
        "upper_fx": ("fast_strike_01",),
    }
    for layer, actions in layer_actions.items():
        for action in actions:
            output_root = module_root / layer / "actions/unarmed/fast_attack" / action
            for direction in DIRECTIONS:
                source = _find_part(fast_root, layer, action, direction)
                if source is None:
                    continue
                output = output_root / f"operator__modular_{layer}__unarmed__{action}__{direction}__3f__96.png"
                if not dry_run:
                    output.parent.mkdir(parents=True, exist_ok=True)
                    _write_or_copy_sheet(source, output, frames=3, target_frame_width=96, target_frame_height=96)
                generated.append(output)
    return generated


def _build_sidearm_action_modules(source_root: Path, module_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    sidearm_root = source_root / "sidearm"
    layer_specs = {
        "modular_lower_body": ("operator__modular_lower_body__sidearm", module_root / "lower_body/actions/sidearm"),
        "modular_upper_body": ("operator__modular_upper_body__sidearm", module_root / "upper_body/actions/sidearm"),
        "modular_upper_fx": ("operator__modular_upper_fx__sidearm", module_root / "upper_fx/actions/sidearm"),
        "modular_sidearm": ("operator__weapon__sidearm_pistol", module_root / "sidearm/actions"),
    }
    for output_layer, (source_prefix, output_root) in layer_specs.items():
        for source in sorted(sidearm_root.glob(f"{source_prefix}__*__*__*f__*.png")):
            spec = _sheet_spec_from_path(source, _direction_from_path(source))
            action = _action_from_path(source)
            output_name = f"operator__{output_layer}__sidearm__{action}__{spec.direction}__{spec.frames}f__96.png"
            output = output_root / action / output_name
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _write_or_copy_sheet(spec.path, output, frames=spec.frames, target_frame_width=96, target_frame_height=96)
            generated.append(output)
    return generated


def _build_ranged_2h_stance_modules(source_root: Path, module_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    ranged_root = source_root / "ranged"
    layer_specs = {
        # Old naming: operator__modular_<bodypart>__stance__ranged_2h__<dir>__5f__96.png
        "lower_body": "operator__modular_lower_body__stance__ranged_2h",
        "upper_body": "operator__modular_upper_body__stance__ranged_2h",
        "ranged_weapon": "operator__modular_upper_body__weapon__ranged_2h",
    }
    # New naming: operator__modular_<layer>__ranged_2h__stance_01__<dir>__5f__96.png
    new_style_prefixes = {
        "lower_body": "operator__modular_lower_body__ranged_2h__stance_01",
        "upper_body": "operator__modular_upper_body__ranged_2h__stance_01",
        "ranged_weapon": "operator__modular_ranged_weapon__ranged_2h__stance_01",
    }
    for output_layer, source_prefix in layer_specs.items():
        output_root = module_root / output_layer / "actions/ranged_2h/stance_01"
        for direction in DIRECTIONS:
            matches = sorted(ranged_root.glob(f"{source_prefix}__{direction}__5f__96*.png"))
            new_prefix = new_style_prefixes.get(output_layer)
            if not matches and new_prefix:
                matches = sorted(ranged_root.glob(f"{new_prefix}__{direction}__5f__96*.png"))
            if not matches:
                continue
            output = output_root / f"operator__modular_{output_layer}__ranged_2h__stance_01__{direction}__5f__96.png"
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _write_or_copy_sheet(matches[0], output, frames=5, target_frame_width=96, target_frame_height=96)
            generated.append(output)
    return generated


def _build_full_dodge_runtime(source_root: Path, dodge_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    source_dodge_root = source_root / "dodge"
    for layer, output_layer in (("body", "body"), ("fx", "fx")):
        for direction in ("n", "s"):
            source = source_dodge_root / f"operator__{layer}__full__dodge_01__{direction}__9f__96.png"
            if not source.exists():
                continue
            output = dodge_root / output_layer / f"operator__{output_layer}__full__dodge_01__{direction}__9f__96.png"
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _write_or_copy_sheet(source, output, frames=9, target_frame_width=96, target_frame_height=96)
            generated.append(output)
    return generated


def _build_upper_body_modules(source_root: Path, module_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    upper_root = module_root / "upper_body"

    for direction in DIRECTIONS:
        generated.extend(
            _copy_upper_module(
                source_root,
                upper_root,
                canonical_action="run_01",
                direction=direction,
                output_group="locomotion/run_01",
                fallbacks=("action_01",),
                dry_run=dry_run,
            )
        )
        generated.extend(
            _copy_upper_module(
                source_root,
                upper_root,
                canonical_action="walk_01",
                direction=direction,
                output_group="locomotion/walk_01",
                fallbacks=("action_01", "run_01"),
                dry_run=dry_run,
            )
        )
        generated.extend(
            _copy_upper_module(
                source_root,
                upper_root,
                canonical_action="idle_01",
                direction=direction,
                output_group="locomotion/idle_01",
                fallbacks=("action_01", "run_01"),
                dry_run=dry_run,
            )
        )

    return generated


def _copy_upper_module(
    source_root: Path,
    upper_root: Path,
    canonical_action: str,
    direction: str,
    output_group: str,
    fallbacks: tuple[str, ...],
    dry_run: bool,
) -> list[Path]:
    source_spec = _resolve_upper_source(source_root, canonical_action, direction, fallbacks)
    if source_spec is None:
        return []

    output_name = f"operator__modular_upper_body__unarmed__{canonical_action}__{direction}__{source_spec.frames}f__96.png"
    output_path = upper_root / output_group / output_name
    if dry_run:
        return [output_path]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    _write_or_copy_sheet(source_spec.path, output_path, source_spec.frames, target_frame_width=96, target_frame_height=96)
    return [output_path]


def _copy_lower_module(
    source_root: Path,
    lower_root: Path,
    canonical_action: str,
    direction: str,
    output_group: str,
    fallbacks: tuple[str, ...],
    dry_run: bool,
) -> list[Path]:
    source_spec = _resolve_lower_source(source_root, canonical_action, direction, fallbacks)
    if source_spec is None:
        return []

    output_name = f"operator__modular_lower_body__unarmed__{canonical_action}__{direction}__{source_spec.frames}f__96.png"
    output_path = lower_root / output_group / output_name
    if dry_run:
        return [output_path]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    _write_or_copy_sheet(source_spec.path, output_path, source_spec.frames, target_frame_width=96, target_frame_height=96)
    return [output_path]


def _resolve_lower_source(
    source_root: Path,
    action: str,
    direction: str,
    fallbacks: tuple[str, ...],
) -> SheetSpec | None:
    if action == "idle_01":
        idle_matches = sorted((source_root / "idle").glob(f"operator__modular_lower_body__idle__{direction}__*f__96.png"))
        if idle_matches:
            return _sheet_spec_from_path(idle_matches[0], direction)

    search_actions = (action, *fallbacks)
    search_dirs = (
        source_root / "lower",
        source_root / action.replace("_01", ""),
        source_root / "run",
        source_root / "walk",
        source_root / "fast_attack",
    )
    for search_action in search_actions:
        for directory in search_dirs:
            pattern = f"operator__modular_lower_body*__{search_action}__{direction}__*f__96.png"
            matches = sorted(directory.glob(pattern)) if directory.exists() else []
            if matches:
                return _sheet_spec_from_path(matches[0], direction)
    return None


def _resolve_upper_source(
    source_root: Path,
    action: str,
    direction: str,
    fallbacks: tuple[str, ...],
) -> SheetSpec | None:
    if action == "idle_01":
        for candidate_direction in _direction_fallbacks(direction):
            idle_matches = sorted(
                (source_root / "idle").glob(f"operator__modular_upper_body__idle__{candidate_direction}__*f__96.png")
            )
            if idle_matches:
                return _sheet_spec_from_path(idle_matches[0], direction)

    search_actions = (action, *fallbacks)
    search_dirs = (
        source_root / "upper",
        source_root / action.replace("_01", ""),
        source_root / "run",
        source_root / "walk",
        source_root / "idle",
        source_root / "png",
        source_root / "fast_attack",
    )
    for search_action in search_actions:
        for candidate_direction in _direction_fallbacks(direction):
            for directory in search_dirs:
                pattern = f"operator__modular_upper_body*__{search_action}__{candidate_direction}__*f__96.png"
                matches = sorted(directory.glob(pattern)) if directory.exists() else []
                if matches:
                    return _sheet_spec_from_path(matches[0], direction)
    return None


def _direction_fallbacks(direction: str) -> tuple[str, ...]:
    fallback_map = {
        "s": ("s", "se", "sw", "e", "w"),
        "se": ("se", "s", "e"),
        "e": ("e", "se", "s"),
        "ne": ("ne", "n", "e"),
        "n": ("n", "ne", "nw", "e", "w"),
        "nw": ("nw", "n", "w"),
        "w": ("w", "sw", "s"),
        "sw": ("sw", "s", "w"),
    }
    return fallback_map.get(direction, (direction,))


def _build_fast_attack_runtime(source_root: Path, action_root: Path, dry_run: bool) -> list[Path]:
    generated: list[Path] = []
    fast_root = source_root / "fast_attack"
    for direction in DIRECTIONS:
        upper = _find_part(fast_root, "upper_body", "fast_strike_01", direction)
        lower = _find_part(fast_root, "lower_body", "fast_strike_01", direction)
        if lower is None:
            lower = _find_part(fast_root, "lower_body", "fast_windup_01", direction)
        if upper is not None and lower is not None:
            output = action_root / "body" / f"operator__body__unarmed__fast_strike_01__{direction}__3f__96.png"
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _composite_horizontal_strips(lower, upper, output, frames=3, target_frame_width=96, target_frame_height=96)
            generated.append(output)

        windup_upper = _find_part(fast_root, "upper_body", "fast_windup_01", direction)
        windup_lower = _find_part(fast_root, "lower_body", "fast_windup_01", direction)
        if windup_upper is not None and windup_lower is not None:
            output = action_root / "body" / f"operator__body__unarmed__fast_windup_01__{direction}__3f__96.png"
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _composite_horizontal_strips(
                    windup_lower, windup_upper, output, frames=3, target_frame_width=96, target_frame_height=96
                )
            generated.append(output)

        fx = _find_part(fast_root, "upper_fx", "fast_strike_01", direction)
        if fx is not None:
            output = action_root / "overlay" / f"operator__fx__unarmed__fast_strike_01__{direction}__3f__96.png"
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _write_or_copy_sheet(fx, output, frames=3, target_frame_width=96, target_frame_height=96)
            generated.append(output)

        recovery_upper = _find_part(fast_root, "upper_body", "fast_recovery_01", direction)
        recovery_lower = _find_part(fast_root, "lower_body", "fast_recovery_01", direction)
        if recovery_upper is not None and recovery_lower is not None:
            output = action_root / "body" / f"operator__body__unarmed__fast_recovery_01__{direction}__3f__96.png"
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                _composite_horizontal_strips(
                    recovery_lower, recovery_upper, output, frames=3, target_frame_width=96, target_frame_height=96
                )
            generated.append(output)
    return generated


def _build_generic_action_modules(source_root: Path, module_root: Path, dry_run: bool) -> list[Path]:
    candidates: dict[tuple[str, str, str, str], tuple[int, SheetSpec]] = {}
    for source in sorted(source_root.rglob("operator__*.png")):
        parsed = _parse_generic_modular_source(source)
        if parsed is None:
            continue
        output_layer, loadout, action, spec, priority = parsed
        if _has_specialized_builder(loadout, action):
            continue
        semantic_key = (output_layer, loadout, action, spec.direction)
        current = candidates.get(semantic_key)
        if current is None or priority > current[0]:
            candidates[semantic_key] = (priority, spec)

    generated: list[Path] = []
    for (output_layer, loadout, action, _), (_, spec) in sorted(candidates.items()):
        output_name = (
            f"operator__modular_{output_layer}__{loadout}__{action}"
            f"__{spec.direction}__{spec.frames}f__96.png"
        )
        output = module_root / output_layer / "actions" / loadout / action / output_name
        if not dry_run:
            output.parent.mkdir(parents=True, exist_ok=True)
            _write_or_copy_sheet(spec.path, output, spec.frames, target_frame_width=96, target_frame_height=96)
        generated.append(output)
    return generated


def _parse_generic_modular_source(source: Path) -> tuple[str, str, str, SheetSpec, int] | None:
    parts = source.stem.split("__")
    if len(parts) < 6 or parts[0] != "operator":
        return None
    output_layer = MODULAR_LAYER_OUTPUTS.get(parts[1])
    if output_layer is None:
        return None
    try:
        direction = parts[-3]
        frames = int(parts[-2].removesuffix("f"))
        declared_size = int(parts[-1])
    except ValueError:
        return None
    if direction not in DIRECTIONS or frames <= 0 or declared_size <= 0:
        return None

    action_group = parts[2]
    variant = "__".join(parts[3:-3])
    if output_layer == "upper_body" and action_group == "weapon" and variant == "ranged_2h":
        output_layer = "ranged_weapon"
        loadout = "ranged_2h"
        action = "stance_01"
        priority = 1
        spec = _sheet_spec_from_path(source, direction)
        return output_layer, loadout, action, spec, priority
    if action_group in KNOWN_LOADOUTS and variant:
        loadout = action_group
        action = _canonical_action_name(variant)
        priority = 2
    elif variant in KNOWN_LOADOUTS:
        loadout = variant
        action = _canonical_action_name(action_group)
        priority = 1
    else:
        loadout = "unarmed"
        action = _canonical_action_name(variant or action_group)
        priority = 0

    spec = _sheet_spec_from_path(source, direction)
    return output_layer, loadout, action, spec, priority


def _canonical_action_name(action: str) -> str:
    return {
        "aim": "aim_01",
        "fire": "fire_01",
        "idle": "idle_01",
        "run": "run_01",
        "stance": "stance_01",
        "walk": "walk_01",
    }.get(action, action)


def _has_specialized_builder(loadout: str, action: str) -> bool:
    if loadout == "sidearm":
        return True
    if loadout == "ranged_2h" and action == "stance_01":
        return True
    if loadout != "unarmed":
        return False
    return action in {"idle_01", "run_01", "walk_01"} or action.startswith(("dodge", "fast_"))


def _remove_superseded_generated(generated: list[Path], dry_run: bool) -> None:
    generated_set = set(generated)
    identities = {
        (output.parent, identity)
        for output in generated
        if (identity := _canonical_output_identity(output.name)) is not None
    }
    for directory, identity in sorted(identities, key=lambda item: (str(item[0]), item[1])):
        if not directory.exists():
            continue
        for candidate in sorted(directory.glob("*.png")):
            if candidate in generated_set or _canonical_output_identity(candidate.name) != identity:
                continue
            try:
                display_path = candidate.relative_to(PROJECT_ROOT)
            except ValueError:
                display_path = candidate
            print(f"{'[dry-run] would remove' if dry_run else 'removed'} superseded generated {display_path}")
            if not dry_run:
                candidate.unlink()
                candidate.with_suffix(candidate.suffix + ".import").unlink(missing_ok=True)


def _canonical_output_identity(filename: str) -> tuple[str, ...] | None:
    if not filename.endswith(".png"):
        return None
    parts = filename.removesuffix(".png").split("__")
    if len(parts) < 5:
        return None
    if not parts[-2].endswith("f") or not parts[-2].removesuffix("f").isdigit():
        return None
    if not parts[-1].isdigit():
        return None
    return tuple(parts[:-2])


def _find_part(root: Path, part: str, action: str, direction: str) -> Path | None:
    matches = sorted(root.glob(f"operator__modular_{part}__unarmed__{action}__{direction}__*f__96.png"))
    return matches[0] if matches else None


def _sheet_spec_from_path(path: Path, direction: str) -> SheetSpec:
    match = re.search(r"__(\d+)f__(\d+)\.png$", path.name)
    if match is None:
        raise ValueError(f"cannot parse frame count from {path}")
    frames = int(match.group(1))
    with Image.open(path) as image:
        frame_width = image.width // frames
        frame_height = image.height
    return SheetSpec(path=path, frames=frames, direction=direction, frame_width=frame_width, frame_height=frame_height)


def _direction_from_path(path: Path) -> str:
    match = re.search(r"__([a-z]+)__\d+f__\d+\.png$", path.name)
    if match is None:
        raise ValueError(f"cannot parse direction from {path}")
    return match.group(1)


def _action_from_path(path: Path) -> str:
    parts = path.stem.split("__")
    if len(parts) < 7:
        raise ValueError(f"cannot parse action from {path}")
    return parts[3]


def _normalized_module_name(path: Path, frames: int, direction: str, output_layer: str) -> str:
    parts = path.stem.split("__")
    if len(parts) < 7:
        raise ValueError(f"cannot normalize module name from {path}")
    return "__".join((parts[0], output_layer, *parts[2:-3], direction, f"{frames}f", "96")) + ".png"


def _write_or_copy_sheet(
    source: Path,
    output: Path,
    frames: int,
    target_frame_width: int,
    target_frame_height: int,
) -> None:
    with Image.open(source) as image:
        image = image.convert("RGBA")
        source_frame_width = image.width // frames
        source_frame_height = image.height
        if source_frame_width == target_frame_width and source_frame_height == target_frame_height:
            copy2(source, output)
            return

        result = Image.new("RGBA", (target_frame_width * frames, target_frame_height), (0, 0, 0, 0))
        for frame_index in range(frames):
            frame = image.crop(
                (
                    frame_index * source_frame_width,
                    0,
                    (frame_index + 1) * source_frame_width,
                    source_frame_height,
                )
            )
            frame = _fit_frame_to_canvas(frame, target_frame_width, target_frame_height)
            result.alpha_composite(frame, (frame_index * target_frame_width, 0))
        result.save(output)


def _composite_horizontal_strips(
    lower: Path,
    upper: Path,
    output: Path,
    frames: int,
    target_frame_width: int,
    target_frame_height: int,
) -> None:
    with Image.open(lower) as lower_image, Image.open(upper) as upper_image:
        lower_image = lower_image.convert("RGBA")
        upper_image = upper_image.convert("RGBA")
        lower_frame_width = lower_image.width // frames
        upper_frame_width = upper_image.width // frames
        result = Image.new("RGBA", (target_frame_width * frames, target_frame_height), (0, 0, 0, 0))

        for frame_index in range(frames):
            lower_frame = lower_image.crop(
                (
                    frame_index * lower_frame_width,
                    0,
                    (frame_index + 1) * lower_frame_width,
                    lower_image.height,
                )
            )
            upper_frame = upper_image.crop(
                (
                    frame_index * upper_frame_width,
                    0,
                    (frame_index + 1) * upper_frame_width,
                    upper_image.height,
                )
            )
            composed = Image.new("RGBA", (target_frame_width, target_frame_height), (0, 0, 0, 0))
            composed.alpha_composite(_fit_frame_to_canvas(lower_frame, target_frame_width, target_frame_height))
            composed.alpha_composite(_fit_frame_to_canvas(upper_frame, target_frame_width, target_frame_height))
            result.alpha_composite(composed, (frame_index * target_frame_width, 0))

        result.save(output)


def _fit_frame_to_canvas(frame: Image.Image, target_width: int, target_height: int) -> Image.Image:
    frame = frame.convert("RGBA")
    if frame.width == target_width and frame.height == target_height:
        return frame

    bbox = frame.getbbox()
    if bbox is None:
        return Image.new("RGBA", (target_width, target_height), (0, 0, 0, 0))

    if frame.width > target_width or frame.height > target_height:
        left = max(0, min(frame.width - target_width, (bbox[0] + bbox[2] - target_width) // 2))
        top = max(0, min(frame.height - target_height, (bbox[1] + bbox[3] - target_height) // 2))
        frame = frame.crop((left, top, left + target_width, top + target_height))
    else:
        canvas = Image.new("RGBA", (target_width, target_height), (0, 0, 0, 0))
        canvas.alpha_composite(frame, ((target_width - frame.width) // 2, (target_height - frame.height) // 2))
        frame = canvas
    return frame


if __name__ == "__main__":
    raise SystemExit(main())
