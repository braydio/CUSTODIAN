"""Deterministic topology profile selection for procgen Phase 1."""

from __future__ import annotations


MIN_MOD = 0.75
MAX_MOD = 1.25
MIN_INTERCEPT_MOD = 0.85
MAX_INTERCEPT_MOD = 1.15

_PROFILE_FAMILIES = [
    {
        "family": "TP_BALANCED_BASELINE",
        "variants": [
            {
                "variant": "A",
                "transit_bias": {"T_NORTH": 1.0, "T_SOUTH": 1.0},
                "ingress_bias": {"INGRESS_N": 1.0, "INGRESS_S": 1.0},
                "intercept_modifier": {"T_NORTH": 1.0, "T_SOUTH": 1.0},
                "fortify_effectiveness_modifier": {"T_NORTH": 1.0, "T_SOUTH": 1.0},
                "summary": "Balanced baseline. North Transit and South Transit remain even.",
            }
        ],
    },
    {
        "family": "TP_NORTH_PRESSURE",
        "variants": [
            {
                "variant": "A",
                "transit_bias": {"T_NORTH": 1.2, "T_SOUTH": 0.85},
                "ingress_bias": {"INGRESS_N": 1.2, "INGRESS_S": 0.85},
                "intercept_modifier": {"T_NORTH": 0.92, "T_SOUTH": 1.08},
                "fortify_effectiveness_modifier": {"T_NORTH": 0.92, "T_SOUTH": 1.08},
                "summary": "North ingress pressure elevated. South Transit interception is more favorable.",
            }
        ],
    },
    {
        "family": "TP_SOUTH_PRESSURE",
        "variants": [
            {
                "variant": "A",
                "transit_bias": {"T_NORTH": 0.85, "T_SOUTH": 1.2},
                "ingress_bias": {"INGRESS_N": 0.85, "INGRESS_S": 1.2},
                "intercept_modifier": {"T_NORTH": 1.08, "T_SOUTH": 0.92},
                "fortify_effectiveness_modifier": {"T_NORTH": 1.08, "T_SOUTH": 0.92},
                "summary": "South ingress pressure elevated. North Transit interception is more favorable.",
            }
        ],
    },
    {
        "family": "TP_SPLIT_INGRESS",
        "variants": [
            {
                "variant": "A",
                "transit_bias": {"T_NORTH": 1.15, "T_SOUTH": 0.9},
                "ingress_bias": {"INGRESS_N": 1.15, "INGRESS_S": 0.9},
                "intercept_modifier": {"T_NORTH": 0.95, "T_SOUTH": 1.05},
                "fortify_effectiveness_modifier": {"T_NORTH": 1.05, "T_SOUTH": 0.95},
                "summary": "North Transit sees higher pressure, but fortification leverage is improved there.",
            }
        ],
    },
    {
        "family": "TP_TRANSIT_CONTESTED",
        "variants": [
            {
                "variant": "A",
                "transit_bias": {"T_NORTH": 1.1, "T_SOUTH": 1.1},
                "ingress_bias": {"INGRESS_N": 1.0, "INGRESS_S": 1.0},
                "intercept_modifier": {"T_NORTH": 0.9, "T_SOUTH": 0.9},
                "fortify_effectiveness_modifier": {"T_NORTH": 1.1, "T_SOUTH": 1.1},
                "summary": "Both transit lanes are contested. Early fortification has stronger returns.",
            }
        ],
    },
    {
        "family": "TP_ARCHIVE_EXPOSED",
        "variants": [
            {
                "variant": "A",
                "transit_bias": {"T_NORTH": 1.2, "T_SOUTH": 0.85},
                "ingress_bias": {"INGRESS_N": 1.2, "INGRESS_S": 0.85},
                "intercept_modifier": {"T_NORTH": 0.9, "T_SOUTH": 1.1},
                "fortify_effectiveness_modifier": {"T_NORTH": 0.9, "T_SOUTH": 1.1},
                "summary": "Archive-side routes are more exposed. South Transit remains the steadier lane.",
            }
        ],
    },
]


def _validate_profile(profile: dict) -> None:
    for key in ("transit_bias", "ingress_bias"):
        for value in profile[key].values():
            if value < MIN_MOD or value > MAX_MOD:
                raise ValueError(f"{key} out of bounds: {value}")
    for key in ("intercept_modifier", "fortify_effectiveness_modifier"):
        for value in profile[key].values():
            if value < MIN_INTERCEPT_MOD or value > MAX_INTERCEPT_MOD:
                raise ValueError(f"{key} out of bounds: {value}")


def select_topology_profile(seed: int) -> dict:
    seed_value = int(seed)
    family_idx = seed_value % len(_PROFILE_FAMILIES)
    family = _PROFILE_FAMILIES[family_idx]
    variants = family["variants"]
    variant_idx = (seed_value // len(_PROFILE_FAMILIES)) % len(variants)
    variant = variants[variant_idx]
    profile = {
        "schema_version": 1,
        "profile_id": f"{family['family']}_{variant['variant']}",
        "transit_bias": dict(variant["transit_bias"]),
        "ingress_bias": dict(variant["ingress_bias"]),
        "intercept_modifier": dict(variant["intercept_modifier"]),
        "fortify_effectiveness_modifier": dict(variant["fortify_effectiveness_modifier"]),
        "summary": str(variant["summary"]),
    }
    _validate_profile(profile)
    return profile
