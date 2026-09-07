#!/usr/bin/env python3
"""Canonical semantic identity for Operator Pipeline V2 animation artwork."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

DIRECTIONS = ("s", "se", "e", "ne", "n", "nw", "w", "sw", "omni")
LAYERS = ("lower_body", "upper_body", "full_body", "head", "cape", "fx", "weapon")
PROFILES = (
    "shared",
    "unarmed",
    "melee_1h",
    "melee_1h_dagger",
    "melee_1h_heavy",
    "sidearm",
    "ranged_2h",
)
ACTION_GROUPS = (
    "locomotion",
    "posture",
    "attack",
    "defense",
    "reaction",
    "interaction",
    "transition",
    "cosmetic",
    "presentation",
)


@dataclass(frozen=True)
class OperatorAssetKey:
    owner: str
    layer: str
    animation_profile: str
    action_group: str
    action: str
    direction: str
    frames: int
    frame_width: int
    frame_height: int


def _size(token: str) -> tuple[int, int]:
    match = re.fullmatch(r"(\d+)(?:x(\d+))?", token)
    if not match:
        raise ValueError(f"invalid frame size token: {token}")
    width = int(match.group(1))
    return width, int(match.group(2) or width)


def parse_filename(
    path_or_name: str | Path, *, allow_legacy_action: bool = False
) -> OperatorAssetKey:
    name = Path(path_or_name).name
    if not name.endswith(".png"):
        raise ValueError(f"Operator animation asset must be PNG: {name}")
    parts = Path(name).stem.split("__")
    if len(parts) != 8:
        raise ValueError(f"expected 8 V2 fields, got {len(parts)}: {name}")
    owner, layer, profile, group, action, direction, frame_token, size_token = parts
    if not re.fullmatch(r"[a-z0-9_]+", owner):
        raise ValueError(f"invalid owner: {owner}")
    if not frame_token.endswith("f") or not frame_token[:-1].isdigit():
        raise ValueError(f"invalid frame-count token: {frame_token}")
    width, height = _size(size_token)
    key = OperatorAssetKey(
        owner,
        layer,
        profile,
        group,
        action,
        direction,
        int(frame_token[:-1]),
        width,
        height,
    )
    validate_key(key, allow_legacy_action=allow_legacy_action)
    return key


def is_legacy_action(action: str) -> bool:
    return action.startswith("legacy_") or "_legacy_" in action


def validate_key(key: OperatorAssetKey, *, allow_legacy_action: bool = False) -> None:
    if not allow_legacy_action and is_legacy_action(key.action):
        raise ValueError(f"legacy action is not valid canonical content: {key.action}")
    if key.layer not in LAYERS:
        raise ValueError(f"invalid Operator layer: {key.layer}")
    if key.animation_profile not in PROFILES:
        raise ValueError(f"invalid animation profile: {key.animation_profile}")
    if key.action_group not in ACTION_GROUPS:
        raise ValueError(f"invalid action group: {key.action_group}")
    if key.direction not in DIRECTIONS:
        raise ValueError(f"invalid direction: {key.direction}")
    if key.frames < 1 or key.frame_width < 1 or key.frame_height < 1:
        raise ValueError("frames and canvas dimensions must be positive")


def canonical_filename(
    key: OperatorAssetKey, *, allow_legacy_action: bool = False
) -> str:
    validate_key(key, allow_legacy_action=allow_legacy_action)
    size = (
        str(key.frame_width)
        if key.frame_width == key.frame_height
        else f"{key.frame_width}x{key.frame_height}"
    )
    return (
        "__".join(
            (
                key.owner,
                key.layer,
                key.animation_profile,
                key.action_group,
                key.action,
                key.direction,
                f"{key.frames}f",
                size,
            )
        )
        + ".png"
    )


def semantic_identity(key: OperatorAssetKey) -> tuple[str, str, str, str, str, str]:
    """Identity deliberately ignores replacement frame count/canvas."""
    return (
        key.owner,
        key.layer,
        key.animation_profile,
        key.action_group,
        key.action,
        key.direction,
    )


def _weapon_relative_path(key: OperatorAssetKey, filename: str) -> Path:
    """Weapon art stays weapon-owned; only the source/runtime prefix differs."""
    return (
        Path(key.animation_profile)
        / (
            Path("held")
            if key.action_group == "presentation" and key.action == "held_01"
            else Path("overrides") / key.action_group / key.action
        )
        / filename
    )


def canonical_source_path(
    key: OperatorAssetKey, *, allow_legacy_action: bool = False
) -> Path:
    filename = canonical_filename(key, allow_legacy_action=allow_legacy_action)
    if key.owner == "operator":
        return (
            Path("content/sprites/operator/source/animations")
            / key.animation_profile
            / key.action_group
            / key.action
            / filename
        )
    return (
        Path("content/sprites/weapons")
        / key.owner
        / "source/operator"
        / _weapon_relative_path(key, filename)
    )


def canonical_runtime_path(
    key: OperatorAssetKey, *, allow_legacy_action: bool = False
) -> Path:
    filename = canonical_filename(key, allow_legacy_action=allow_legacy_action)
    if key.owner == "operator":
        return (
            Path("content/sprites/operator/runtime/animations")
            / key.animation_profile
            / key.action_group
            / key.action
            / filename
        )
    return (
        Path("content/sprites/weapons")
        / key.owner
        / "runtime/operator"
        / _weapon_relative_path(key, filename)
    )


def infer_action_group(action: str) -> str:
    if action.startswith(
        ("draw", "sheathe", "stance", "ready_", "relax_")
    ) or action.startswith(("idle_ready", "idle_relaxed")):
        return "posture"

    if action.startswith(("idle", "walk", "run")):
        return "locomotion"

    if any(
        token in action
        for token in ("attack", "fast", "heavy", "strike", "windup", "recovery")
    ):
        return "attack"

    if any(token in action for token in ("block", "parry")):
        return "defense"

    if any(token in action for token in ("hitreact", "stagger", "death", "knockdown")):
        return "reaction"

    if any(token in action for token in ("arrival", "teleport", "dodge")):
        return "transition"

    if any(token in action for token in ("patch", "interact", "success")):
        return "interaction"

    return "cosmetic"
