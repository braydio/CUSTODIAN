#!/usr/bin/env python3
"""Audit Operator runtime path references.

Retired runtime folder families are always a hard failure. Canonical `legacy_*`
actions are migration debt: reported every run, and a failure under ``--final``,
which is the objective end-state gate. Direct gameplay references to individual
Operator animation art are blocked against an exact temporary debt baseline.

Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
FORBIDDEN = re.compile(
    r"content/sprites/operator/(?:new_operator|runtime/(?:animation_base|curated|modules/new_operator|actions|body|fx|overlay|overlays|full_body|weapon|live_review))(?:/|\b)"
)
LEGACY_ACTION = re.compile(r"\blegacy_[a-z0-9_]+|[a-z0-9]+_legacy_[a-z0-9]+")
# Only Operator animation identities are in scope; other systems have their own legacy.
OPERATOR_SCOPE = re.compile(r"content/sprites/(?:operator|weapons)/")
OPERATOR_OWNED_DIRS = ("game/actors/operator/", "game/systems/presentation/")
RAW_GAMEPLAY_OPERATOR_ART = re.compile(
    r"res://content/sprites/operator/(?:runtime/animations|source)/[^\"'\s)]+"
    r"|res://content/sprites/weapons/[^\"'\s)]*/source/operator/[^\"'\s)]+"
)

# Exact migration debt, keyed by consumer and referenced asset. New entries fail
# ordinary validation; removed entries also fail until this ledger is shrunk.
KNOWN_LEGACY_RAW_OPERATOR_PATHS = frozenset({
    ("game/actors/operator/operator.gd", path)
    for path in (
        "res://content/sprites/operator/runtime/animations/unarmed/defense/parry_miss_01/operator__full_body__unarmed__defense__parry_miss_01__e__8f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/defense/parry_miss_01/operator__full_body__unarmed__defense__parry_miss_01__w__8f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/legacy_operator_fx_critical_hitspark_01_e_8f_156x96/operator__fx__unarmed__cosmetic__legacy_operator_fx_critical_hitspark_01_e_8f_156x96__omni__1f__1248x96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/legacy_operator_fx_critical_hitspark_01_w_8f_156x96/operator__fx__unarmed__cosmetic__legacy_operator_fx_critical_hitspark_01_w_8f_156x96__omni__1f__1248x96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/critical_execution_01/operator__full_body__unarmed__cosmetic__critical_execution_01__s__8f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/critical_execution_01/operator__full_body__unarmed__cosmetic__critical_execution_01__e__12f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/critical_execution_01/operator__full_body__unarmed__cosmetic__critical_execution_01__w__12f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/critical_execution_01/operator__fx__unarmed__cosmetic__critical_execution_01__s__8f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/critical_execution_01/operator__fx__unarmed__cosmetic__critical_execution_01__e__12f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/critical_execution_01/operator__fx__unarmed__cosmetic__critical_execution_01__w__12f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__full_body__unarmed__cosmetic__falcon_reversal_01__e__8f__156.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__full_body__unarmed__cosmetic__falcon_reversal_01__w__8f__156.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__fx__unarmed__cosmetic__falcon_reversal_01__e__8f__156.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/falcon_reversal_01/operator__fx__unarmed__cosmetic__falcon_reversal_01__w__8f__156.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/legacy_operator_body_melee_fast_01_e_7f_156x96/operator__full_body__melee_1h__attack__legacy_operator_body_melee_fast_01_e_7f_156x96__omni__1f__1092x96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/legacy_operator_body_melee_fast_02_e_7f_156x96/operator__full_body__melee_1h__attack__legacy_operator_body_melee_fast_02_e_7f_156x96__omni__1f__1092x96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/legacy_operator_body_melee_fast_03_e_8f_156x96/operator__full_body__melee_1h__attack__legacy_operator_body_melee_fast_03_e_8f_156x96__omni__1f__1248x96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/fast_01_legacy_7f7c22c3/operator__fx__melee_1h__attack__fast_01_legacy_7f7c22c3__e__10f__96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/fast_01_legacy_3865ae8b/operator__fx__melee_1h__attack__fast_01_legacy_3865ae8b__w__10f__96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/fast_02_legacy_c1da49f3/operator__fx__melee_1h__attack__fast_02_legacy_c1da49f3__e__8f__96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/fast_02_legacy_04ab0f51/operator__fx__melee_1h__attack__fast_02_legacy_04ab0f51__w__8f__96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/fast_03_legacy_7010c688/operator__fx__melee_1h__attack__fast_03_legacy_7010c688__e__8f__96.png",
        "res://content/sprites/operator/runtime/animations/melee_1h/attack/fast_03_legacy_99791341/operator__fx__melee_1h__attack__fast_03_legacy_99791341__w__8f__96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/cosmetic/legacy_front_idle_loop/operator__full_body__unarmed__cosmetic__legacy_front_idle_loop__omni__1f__480x96.png",
        "res://content/sprites/operator/runtime/animations/unarmed/posture/stance_01/operator__full_body__unarmed__posture__stance_01__e__12f__96.png",
        "res://content/sprites/operator/runtime/animations/ranged_2h/cosmetic/legacy_operator_body_ranged_2h_aim_raise/operator__full_body__ranged_2h__cosmetic__legacy_operator_body_ranged_2h_aim_raise__omni__1f__288x96.png",
        "res://content/sprites/operator/runtime/animations/ranged_2h/cosmetic/legacy_firing_slow_walk/operator__full_body__ranged_2h__cosmetic__legacy_firing_slow_walk__omni__1f__672x96.png",
        "res://content/sprites/operator/runtime/animations/shared/transition/dodge_01/operator__full_body__shared__transition__dodge_01__n__9f__96.png",
        "res://content/sprites/operator/runtime/animations/shared/transition/dodge_01/operator__full_body__shared__transition__dodge_01__s__9f__96.png",
        "res://content/sprites/operator/runtime/animations/shared/transition/dodge_01/operator__fx__shared__transition__dodge_01__n__9f__96.png",
        "res://content/sprites/operator/runtime/animations/shared/transition/dodge_01/operator__fx__shared__transition__dodge_01__s__9f__96.png",
    )
})

# Migration tooling is allowed to understand legacy names; that is its whole job.
MIGRATION_ONLY = {
    "operator_runtime_path_audit.py",
    "migrate_operator_assets_v2.py",
    "operator_legacy_asset_migration.py",
    "operator_legacy_animation_map.json",
    "materialize_operator_legacy_animations.gd",
    "operator_runtime_animation_authority_smoke.py",
    "operator_asset_schema.py",
    "operator_asset_schema_smoke.py",
    "sync_operator_runtime_assets.py",
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true",
                        help="also fail on remaining legacy identities")
    args = parser.parse_args(argv)

    violations: list[str] = []
    legacy: list[str] = []
    raw_gameplay_paths: set[tuple[str, str]] = set()
    for root in (PROJECT_ROOT / "game", PROJECT_ROOT / "tools"):
        for path in sorted(root.rglob("*")):
            if path.name in MIGRATION_ONLY:
                continue
            if path.suffix not in {".gd", ".tscn", ".tres", ".py", ".json"} or not path.is_file():
                continue
            relative = path.relative_to(PROJECT_ROOT).as_posix()
            operator_owned = relative.startswith(OPERATOR_OWNED_DIRS)
            for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                location = f"{relative}:{line_number}"
                if FORBIDDEN.search(line):
                    violations.append(f"{location}: {line.strip()}")
                if LEGACY_ACTION.search(line) and (operator_owned or OPERATOR_SCOPE.search(line)):
                    legacy.append(location)
                if root == PROJECT_ROOT / "game" and path.suffix == ".gd":
                    raw_gameplay_paths.update(
                        (relative, match.group(0))
                        for match in RAW_GAMEPLAY_OPERATOR_ART.finditer(line)
                    )

    if violations:
        print("Retired Operator runtime paths remain:\n" + "\n".join(violations))
        return 1
    new_raw_paths = raw_gameplay_paths - KNOWN_LEGACY_RAW_OPERATOR_PATHS
    stale_baseline = KNOWN_LEGACY_RAW_OPERATOR_PATHS - raw_gameplay_paths
    if new_raw_paths:
        print("New direct gameplay Operator animation art references are forbidden:")
        for relative, asset_path in sorted(new_raw_paths):
            print(f"  {relative}: {asset_path}")
        return 1
    if stale_baseline:
        print("Operator raw-path debt was removed; shrink KNOWN_LEGACY_RAW_OPERATOR_PATHS:")
        for relative, asset_path in sorted(stale_baseline):
            print(f"  {relative}: {asset_path}")
        return 1
    if legacy:
        label = "FAIL" if args.final else "TODO"
        print(f"{label} legacy Operator identities still referenced in {len(legacy)} lines")
        for location in legacy[:10]:
            print(f"  {location}")
        if len(legacy) > 10:
            print(f"  ... and {len(legacy) - 10} more")
        if args.final:
            return 1
    print("operator runtime path audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
