#!/usr/bin/env python3
"""Legacy Operator filename understanding, isolated from the canonical V2 schema.

Only migration and ingest tooling may import this. The everyday runtime schema in
``operator_asset_schema`` stays strict and knows nothing about historical names.
"""

from __future__ import annotations

from pathlib import Path

from operator_asset_schema import (
    DIRECTIONS,
    PROFILES,
    OperatorAssetKey,
    _size,
    canonical_filename,
    canonical_runtime_path,
    canonical_source_path,
    infer_action_group,
    parse_filename,
    validate_key,
)


def legacy_canonical_filename(key: OperatorAssetKey) -> str:
    return canonical_filename(key, allow_legacy_action=True)


def legacy_canonical_source_path(key: OperatorAssetKey) -> Path:
    return canonical_source_path(key, allow_legacy_action=True)


def legacy_canonical_runtime_path(key: OperatorAssetKey) -> Path:
    return canonical_runtime_path(key, allow_legacy_action=True)

LAYER_ALIASES = {
    "modular_body_lower": "lower_body",
    "modular_lower_body": "lower_body",
    "modular_body_upper": "upper_body",
    "modular_upper_body": "upper_body",
    "modular_combined_body": "full_body",
    "combined_body": "full_body",
    "body": "full_body",
    "modular_head": "head",
    "modular_wardrobe_cape": "cape",
    "wardrobe_cape": "cape",
    "cape": "cape",
    "modular_upper_fx": "fx",
    "upper_fx": "fx",
    "combat_fx": "fx",
    "fx": "fx",
    "modular_sidearm": "weapon",
    "modular_ranged_weapon": "weapon",
    "weapon": "weapon",
}
PROFILE_ALIASES = {"full": "shared", "hooded": "shared", "melee_2h": "melee_1h_heavy"}
ACTION_ALIASES = {
    "chain_01": "fast_01",
    "chain_02": "fast_02",
    "chain_03": "fast_03",
    "enter_block_01": "block_enter_01",
    "block_loop_01": "block_hold_01",
    "blocking_hitreact_01": "block_hit_01",
}


def normalize_legacy_filename(
    path_or_name: str | Path, *, explicit_action_map: dict[str, str] | None = None
) -> OperatorAssetKey:
    """Normalize a parseable legacy strip; ambiguous names raise instead of guessing."""
    name = Path(path_or_name).name
    parts = Path(name).stem.split("__")
    if len(parts) == 8:
        return parse_filename(name, allow_legacy_action=True)
    if len(parts) < 6 or parts[0] != "operator":
        raise ValueError(f"unrecognized legacy Operator filename: {name}")
    direction, frame_token, size_token = parts[-3:]
    if (
        direction not in DIRECTIONS
        or not frame_token.endswith("f")
        or not frame_token[:-1].isdigit()
    ):
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
    key = OperatorAssetKey(
        "operator",
        layer,
        profile,
        infer_action_group(action),
        action,
        direction,
        int(frame_token[:-1]),
        width,
        height,
    )
    # Legacy normalization may legitimately produce a legacy-named action; only the
    # canonical schema forbids it, and migration output is checked at its own gates.
    validate_key(key, allow_legacy_action=True)
    return key
