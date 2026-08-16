#!/usr/bin/env python3
"""Canonical semantic identity for Operator Pipeline V2 animation artwork."""

from __future__ import annotations

import re
from dataclasses import dataclass, replace
from pathlib import Path


DIRECTIONS = ("s", "se", "e", "ne", "n", "nw", "w", "sw", "omni")
LAYERS = ("lower_body", "upper_body", "full_body", "head", "cape", "fx", "weapon")
PROFILES = ("shared", "unarmed", "melee_1h", "melee_1h_dagger", "melee_1h_heavy", "sidearm", "ranged_2h")
ACTION_GROUPS = ("locomotion", "posture", "attack", "defense", "reaction", "interaction", "transition", "cosmetic", "presentation")

LAYER_ALIASES = {
    "modular_body_lower": "lower_body", "modular_lower_body": "lower_body",
    "modular_body_upper": "upper_body", "modular_upper_body": "upper_body",
    "modular_combined_body": "full_body", "combined_body": "full_body", "body": "full_body",
    "modular_head": "head", "modular_wardrobe_cape": "cape", "wardrobe_cape": "cape",
    "cape": "cape", "modular_upper_fx": "fx", "upper_fx": "fx", "combat_fx": "fx", "fx": "fx",
    "modular_sidearm": "weapon", "modular_ranged_weapon": "weapon", "weapon": "weapon",
}
PROFILE_ALIASES = {"full": "shared", "hooded": "shared", "melee_2h": "melee_1h_heavy"}
ACTION_ALIASES = {
    "chain_01": "fast_01", "chain_02": "fast_02", "chain_03": "fast_03",
    "enter_block_01": "block_enter_01", "block_loop_01": "block_hold_01",
    "blocking_hitreact_01": "block_hit_01",
}


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


def parse_filename(path_or_name: str | Path) -> OperatorAssetKey:
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
    key = OperatorAssetKey(owner, layer, profile, group, action, direction, int(frame_token[:-1]), width, height)
    validate_key(key)
    return key

def validate_key(key: OperatorAssetKey) -> None:
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


def canonical_filename(key: OperatorAssetKey) -> str:
    validate_key(key)
    size = str(key.frame_width) if key.frame_width == key.frame_height else f"{key.frame_width}x{key.frame_height}"
    return "__".join((key.owner, key.layer, key.animation_profile, key.action_group, key.action,
                     key.direction, f"{key.frames}f", size)) + ".png"


def semantic_identity(key: OperatorAssetKey) -> tuple[str, str, str, str, str, str]:
    """Identity deliberately ignores replacement frame count/canvas."""
    return (key.owner, key.layer, key.animation_profile, key.action_group, key.action, key.direction)


def canonical_source_path(key: OperatorAssetKey) -> Path:
    if key.owner == "operator":
        return Path("content/sprites/operator/source/animations") / key.animation_profile / key.action_group / key.action / canonical_filename(key)
    return Path("content/sprites/weapons") / key.owner / "operator" / key.animation_profile / (
        Path("held") if key.action_group == "presentation" and key.action == "held_01"
        else Path("overrides") / key.action_group / key.action
    ) / canonical_filename(key)


def canonical_runtime_path(key: OperatorAssetKey) -> Path:
    if key.owner == "operator":
        return Path("content/sprites/operator/runtime/animations") / key.animation_profile / key.action_group / key.action / canonical_filename(key)
    return canonical_source_path(key)


def infer_action_group(action: str) -> str:
    if action.startswith(("idle", "walk", "run")):
        return "locomotion"
    if action.startswith(("draw", "sheathe", "stance", "relaxed")) or "ready" in action:
        return "posture"
    if any(token in action for token in ("attack", "fast", "heavy", "strike", "windup", "recovery")):
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


def normalize_legacy_filename(path_or_name: str | Path, *, explicit_action_map: dict[str, str] | None = None) -> OperatorAssetKey:
    """Normalize a parseable legacy strip; ambiguous names raise instead of guessing."""
    name = Path(path_or_name).name
    parts = Path(name).stem.split("__")
    if len(parts) == 8:
        return parse_filename(name)
    if len(parts) < 6 or parts[0] != "operator":
        raise ValueError(f"unrecognized legacy Operator filename: {name}")
    direction, frame_token, size_token = parts[-3:]
    if direction not in DIRECTIONS or not frame_token.endswith("f") or not frame_token[:-1].isdigit():
        raise ValueError(f"unparseable legacy animation tail: {name}")
    width, height = _size(size_token)
    raw_layer = parts[1]
    layer = LAYER_ALIASES.get(raw_layer)
    if layer is None:
        if raw_layer.startswith("modular_weapon_"):
            layer = "weapon"
        elif raw_layer == "full_body_combat":
            layer = "full_body"
        else:
            raise ValueError(f"unknown legacy Operator layer: {raw_layer}")
    middle = parts[2:-3]
    profile = middle[0] if middle else "unarmed"
    action = "__".join(middle[1:]) if len(middle) > 1 else profile
    if profile in {"locomotion", "ranged", "stance"}:
        action, profile = (action if action != profile else profile), "unarmed"
    profile = PROFILE_ALIASES.get(profile, profile)
    if raw_layer == "modular_head":
        profile = "shared"
    if raw_layer in {"modular_sidearm"}:
        profile = "sidearm"
    if raw_layer in {"modular_ranged_weapon"}:
        profile = "ranged_2h"
    if raw_layer.startswith("modular_weapon_vigil"):
        profile = "melee_1h_dagger"
    elif raw_layer.startswith("modular_weapon_cleaver"):
        profile = "melee_1h_heavy"
    if profile not in PROFILES:
        raise ValueError(f"ambiguous legacy animation profile {profile}: {name}")
    mapping = {**ACTION_ALIASES, **(explicit_action_map or {})}
    action = mapping.get(action, action)
    key = OperatorAssetKey("operator", layer, profile, infer_action_group(action), action, direction,
                           int(frame_token[:-1]), width, height)
    validate_key(key)
    return key
