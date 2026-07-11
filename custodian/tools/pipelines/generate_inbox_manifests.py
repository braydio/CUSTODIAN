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

OPERATOR_MODULAR_LAYERS = {
    "modular_body_lower",
    "modular_body_upper",
    "modular_combined_body",
    "modular_lower_body",
    "modular_sidearm",
    "modular_upper_body",
    "modular_upper_fx",
    "modular_wardrobe_cape",
}

SUPPORTED_OPERATOR_MODULAR_LOADOUTS = {"unarmed", "sidearm", "ranged_2h"}
FUTURE_OPERATOR_MODULAR_LOADOUTS = {"melee", "melee_1h", "melee_2h"}


@dataclass(frozen=True)
class SheetInfo:
    basename: str
    owner: str
    layer: str
    action_group: str
    variant: str
    direction: str
    frame_count: int
    frame_width: int
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
        "--remove-superseded",
        action="store_true",
        help="Remove older canonical sibling outputs with the same semantic animation identity.",
    )
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
            if args.dry_run and args.remove_superseded:
                existing_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
                for superseded in _find_superseded_outputs(existing_manifest):
                    print(f"[dry-run] would remove superseded {superseded.relative_to(PROJECT_DIR)}")
            continue

        manifest = _build_manifest(png_path, remove_superseded=args.remove_superseded)
        generated += 1
        if args.dry_run:
            print(f"[dry-run] would write {manifest_path.relative_to(PROJECT_DIR)}")
            if args.remove_superseded:
                for superseded in _find_superseded_outputs(manifest):
                    print(f"[dry-run] would remove superseded {superseded.relative_to(PROJECT_DIR)}")
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
    if args.remove_superseded:
        ingest_args.append("--remove-superseded")

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


def _build_manifest(png_path: Path, *, remove_superseded: bool = False) -> dict:
    info = _inspect_sheet(png_path)
    manifest: dict = {
        "source": png_path.name,
        "mode": "copy" if info.source_kind == "copy" else "strip",
        "outputs": _build_outputs(info),
    }
    if info.source_kind != "copy":
        manifest["frame_size"] = [info.frame_width, info.frame_size]
    if remove_superseded:
        manifest["remove_superseded"] = True
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
        if _is_allied_actor_owner(parts[0]):
            return _inspect_simple_actor_sheet(png_path, parts)
        if len(parts) < 2:
            raise RuntimeError(
                f"{basename}: expected canonical sprite name or item filename"
            )
        return _inspect_item_sheet(png_path, parts)
    owner = parts[0]
    layer = parts[1]
    action_group = parts[2]

    # Variant and direction may contain underscores; work backwards from the end.
    # Expected tail: <direction>__<frames>f__<size>
    # The frames token is always the second-to-last segment.
    if len(parts) < 5:
        raise RuntimeError(f"{basename}: canonical sprite names need at least owner__layer__action__direction__Nf__size")
    direction = parts[-3]
    frames_token = parts[-2]
    size_token = parts[-1]
    # Variant is everything between action_group (parts[2]) and direction (parts[-3]).
    variant = "__".join(parts[3:-3])

    frame_count = _parse_token_count(frames_token, "f", basename)
    frame_width, frame_size = _parse_frame_dimensions(size_token, basename)
    source_kind = "copy" if "4dir" in direction or frame_count == 1 else "strip"

    with Image.open(png_path) as image:
        width, height = image.size
    if source_kind == "strip" and height != frame_size:
        raise RuntimeError(
            f"{basename}: strip height {height} does not match declared frame size {frame_size}"
        )
    if source_kind == "strip" and width % frame_width != 0:
        raise RuntimeError(
            f"{basename}: strip width {width} is not divisible by declared frame width {frame_width}"
        )
    if source_kind == "strip" and width // frame_width != frame_count:
        raise RuntimeError(
            f"{basename}: declared {frame_count} frames at {frame_width}px wide expects "
            f"a {frame_count * frame_width}px strip, got {width}px"
        )

    return SheetInfo(
        basename=basename,
        owner=owner,
        layer=layer,
        action_group=action_group,
        variant=variant,
        direction=direction,
        frame_count=frame_count,
        frame_width=frame_width,
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
        raise RuntimeError(f"{basename}: item strip height {height} must equal declared frame size {frame_size} — fix the filename suffix")
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
        frame_width=frame_size,
        frame_size=frame_size,
        source_kind="strip",
    )


def _inspect_simple_actor_sheet(png_path: Path, parts: list[str]) -> SheetInfo:
    basename = png_path.name
    if len(parts) not in {3, 5}:
        raise RuntimeError(
            f"{basename}: simple actor filenames should follow <actor>__<animation>__<direction>.png"
            " or <actor>__<animation>__<direction>__<frames>f__<size>.png"
        )

    owner = parts[0]
    animation = parts[1]
    direction = parts[2]
    with Image.open(png_path) as image:
        width, height = image.size

    if len(parts) == 5:
        frame_count = _parse_token_count(parts[3], "f", basename)
        frame_size = _parse_token_count(parts[4], "", basename)
    else:
        frame_size = height
        if frame_size <= 0 or width % frame_size != 0:
            raise RuntimeError(
                f"{basename}: simple actor sheet width {width} must be divisible by inferred frame size {frame_size}"
            )
        frame_count = width // frame_size

    if height != frame_size:
        raise RuntimeError(
            f"{basename}: simple actor strip height {height} must equal frame size {frame_size}"
        )
    if width % frame_size != 0:
        raise RuntimeError(
            f"{basename}: simple actor strip width {width} must be divisible by frame size {frame_size}"
        )
    if width // frame_size != frame_count:
        frame_count = width // frame_size

    layer = "fx" if animation.startswith("fx_") else "body"
    variant = animation.removeprefix("fx_")
    action_group = _simple_actor_action_group(variant, layer)
    source_kind = "copy" if frame_count == 1 else "strip"
    return SheetInfo(
        basename=basename,
        owner=owner,
        layer=layer,
        action_group=action_group,
        variant=variant,
        direction=direction,
        frame_count=frame_count,
        frame_width=frame_size,
        frame_size=frame_size,
        source_kind=source_kind,
    )


def _simple_actor_action_group(animation: str, layer: str) -> str:
    if layer == "fx":
        return "fx"
    if animation in {"idle", "walk", "run", "turn"}:
        return "locomotion"
    if animation in {"aim", "fire", "reload"}:
        return "ranged"
    if animation in {"windup", "active", "strike", "recover", "guard", "parry"}:
        return "combat"
    if animation in {"hit", "stagger", "death", "disabled", "wake", "sleep"}:
        return "state"
    return "misc"


def _inspect_harvesting_node_sheet(png_path: Path, parts: list[str]) -> SheetInfo:
    basename = png_path.name
    if len(parts) < 6:
        raise RuntimeError(
            f"{basename}: harvesting node filenames should follow props__harvesting_nodes__<node_type>__node__<state>__<frames>f__<size>.png"
            " or props__harvesting_nodes__<node_type>__fx__<state>__<frames>f__<size>.png"
        )
    node_type = parts[2]
    # State is everything between the type prefix and the metadata tail (__Nf__size).
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
        frame_width=frame_size,
        frame_size=frame_size,
        source_kind="strip",
    )


def _parse_token_count(token: str, suffix: str, basename: str) -> int:
    # Strip a trailing suffix (e.g. "-sheet" from "96-sheet") before parsing.
    for extra in ("-sheet", "-tile", "-strip"):
        if token.endswith(extra):
            token = token[: -len(extra)]
    if suffix and not token.endswith(suffix):
        raise RuntimeError(f"{basename}: expected token ending in {suffix!r}, got {token!r}")
    raw = token[: -len(suffix)] if suffix else token
    if not raw.isdigit():
        raise RuntimeError(f"{basename}: expected numeric token, got {token!r}")
    return int(raw)


def _parse_frame_dimensions(token: str, basename: str) -> tuple[int, int]:
    if "x" not in token.lower():
        size = _parse_token_count(token, "", basename)
        return size, size

    parts = token.lower().split("x")
    if len(parts) != 2 or not all(part.isdigit() for part in parts):
        raise RuntimeError(
            f"{basename}: expected frame size token <size> or <width>x<height>, got {token!r}"
        )
    width, height = (int(part) for part in parts)
    if width <= 0 or height <= 0:
        raise RuntimeError(f"{basename}: frame dimensions must be positive")
    return width, height


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
        if _is_operator_modular_sidearm_weapon(info):
            return f"operator/new_operator/modular/sidearm/{info.basename}"
        if _is_operator_modular_sheet(info):
            return f"operator/new_operator/modular/{_operator_modular_source_bucket(info)}/{info.basename}"
        if info.layer == "body":
            return f"operator/runtime/body/{info.action_group}/{info.basename}"
        if info.layer == "weapon":
            return f"operator/runtime/weapon/{info.action_group}/{info.basename}"
        if info.layer == "fx":
            return f"operator/runtime/overlays/{info.action_group}/{info.basename}"
    if info.owner == "enemy" or info.owner.startswith("enemy_") or info.owner == "drone":
        return f"enemies/{info.owner}/runtime/{info.layer}/{info.basename}"
    if _is_allied_actor_owner(info.owner):
        return f"allies/{info.owner}/runtime/{info.layer}/{info.basename}"
    if info.owner in {"fallen_star_katana", "carbine_rifle", "carbine_rifle_mk1"}:
        return f"weapons/{info.owner}/animations/{info.basename}"
    if info.owner in {"command_terminal", "fabricator_terminal", "computer_terminal", "builder_terminal"}:
        return f"environment/props/terminal/runtime/body/{info.basename}"
    if info.owner in {"portal_ring", "hit_spark", "muzzle_flash", "block_spark"} or info.owner.endswith("_spark") or info.owner.endswith("_ring"):
        return f"effects/runtime/{info.basename}"
    if _is_vehicle_owner(info.owner):
        return f"vehicles/{info.owner}/runtime/{info.basename}"
    if info.owner in {"turret", "gunner", "repeater", "sniper"} or info.layer == "turret":
        return f"turrets/{info.owner}/{info.basename}"
    if info.owner == "props" and info.layer == "harvesting_nodes":
        if info.variant.startswith("fx") or info.variant.startswith("fx_strike"):
            return f"effects/harvesting_nodes/{info.action_group}/{info.basename}"
        return f"props/harvesting_nodes/{info.action_group}/{info.action_group}__node__{info.variant}__{info.frame_count}f__{info.frame_size}.png"
    if info.owner == "items" or info.layer == "item" or info.action_group == "item":
        return _items_runtime_path(info)
    return f"{info.owner}/runtime/{info.layer}/{info.basename}"


def _compatibility_outputs(info: SheetInfo) -> list[dict]:
	outputs: list[dict] = []
	if info.owner.startswith("enemy_") or info.owner == "drone":
		output: dict = {
			"path": f"enemies/{info.owner}/{info.basename}",
			"layout": "copy" if info.source_kind == "copy" else "horizontal_strip",
		}
		if info.source_kind != "copy":
			output["select"] = {"type": "range", "start": 0, "count": info.frame_count}
		outputs.append(output)
	return outputs


def _operator_modular_source_bucket(info: SheetInfo) -> str:
    loadout, action = _operator_modular_loadout_action(info)
    if action.startswith("dodge"):
        return "dodge"
    if action.startswith("idle"):
        return "idle"
    if action.startswith("walk"):
        return "walk"
    if action.startswith("run") or action.startswith("action"):
        return "run"
    if action.startswith("fast_"):
        return "fast_attack"
    if loadout == "sidearm":
        return "sidearm"
    if loadout == "ranged_2h":
        return "ranged"
    if action.startswith(("block", "blocking_", "enter_block", "exit_block")):
        return "block"
    if action.startswith(("hit", "stagger", "knockdown", "recover")):
        return "reaction"
    return action


def _operator_modular_loadout_action(info: SheetInfo) -> tuple[str, str]:
    known_loadouts = SUPPORTED_OPERATOR_MODULAR_LOADOUTS
    if info.owner == "operator" and info.layer in OPERATOR_MODULAR_LAYERS:
        detected_loadout = ""
        if info.action_group in FUTURE_OPERATOR_MODULAR_LOADOUTS:
            detected_loadout = info.action_group
        elif info.variant in FUTURE_OPERATOR_MODULAR_LOADOUTS:
            detected_loadout = info.variant
        if detected_loadout:
            print(
                "[WARN] Operator modular loadout '%s' seen in %s. "
                "Update pipeline supported loadouts before ingesting weapon-specific block/hitreact assets."
                % (detected_loadout, info.basename),
                file=sys.stderr,
            )
    if info.action_group in known_loadouts and info.variant:
        return info.action_group, info.variant
    if info.variant in known_loadouts:
        return info.variant, info.action_group
    return "unarmed", info.variant or info.action_group


def _items_runtime_path(info: SheetInfo) -> str:
    return f"items/{info.layer}/{info.variant}.png"


def _is_vehicle_owner(owner: str) -> bool:
    return owner in {"hover_buggy", "light_buggy", "vehicle", "buggy"} or owner.startswith("vehicle_") or owner.endswith("_buggy")


def _is_operator_modular_sidearm_weapon(info: SheetInfo) -> bool:
    return info.owner == "operator" and info.layer == "weapon" and info.action_group == "sidearm_pistol"


def _is_operator_modular_sheet(info: SheetInfo) -> bool:
    return info.owner == "operator" and info.layer in OPERATOR_MODULAR_LAYERS


def _build_post_process(info: SheetInfo) -> list[str]:
    post_process: list[str] = []
    if info.owner == "operator" and info.layer == "body":
        post_process.append("operator_curated_resources")
    if _is_operator_modular_sheet(info) or _is_operator_modular_sidearm_weapon(info):
        post_process.append("operator_modular_runtime")
    if info.owner.startswith("enemy_") or info.owner == "drone":
        post_process.append("enemy_runtime_import")
    if _is_allied_actor_owner(info.owner):
        post_process.append(f"actor_spriteframes:allies:{info.owner}")
    if _is_vehicle_owner(info.owner):
        post_process.append("vehicle_runtime_import")
    return post_process


def _is_allied_actor_owner(owner: str) -> bool:
    return (
        owner.startswith("allied_")
        or owner
        in {
            "combat_droid",
            "routebreaker_frame",
            "field_turret",
            "repair_drone",
        }
    )


def _find_superseded_outputs(manifest: dict) -> list[Path]:
    superseded: list[Path] = []
    sprites_root = PROJECT_DIR / "content/sprites"
    for output in manifest.get("outputs", []):
        target = sprites_root / str(output.get("path", ""))
        identity = _canonical_output_identity(target.name)
        if identity is None or not target.parent.exists():
            continue
        for candidate in sorted(target.parent.glob("*.png")):
            if candidate.name != target.name and _canonical_output_identity(candidate.name) == identity:
                superseded.append(candidate)
    return superseded


def _canonical_output_identity(filename: str) -> tuple[str, ...] | None:
    if not filename.endswith(".png"):
        return None
    parts = filename.removesuffix(".png").split("__")
    if len(parts) < 5:
        return None
    if not parts[-2].endswith("f") or not parts[-2].removesuffix("f").isdigit():
        return None
    size_parts = parts[-1].lower().split("x")
    if len(size_parts) not in {1, 2} or not all(part.isdigit() and int(part) > 0 for part in size_parts):
        return None
    return tuple(parts[:-2])


if __name__ == "__main__":
    raise SystemExit(main())
