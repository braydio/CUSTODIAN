#!/usr/bin/env python3
"""Enforce Operator runtime animation authority and report remaining migration debt.

Two tiers:

* Invariants always fail the run. They protect the properties the migration has
  already established: gameplay only ever loads runtime art, and no legacy
  identity reaches runtime.
* Completion gates are the objective definition of "migration finished". They
  are reported every run and only fail under ``--final``, so the remaining debt
  stays visible and countable instead of silently accumulating.

Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[2]
PROJECT_ROOT = CUSTODIAN_ROOT.parent
sys.path.insert(0, str(CUSTODIAN_ROOT / "tools/pipelines"))

from operator_asset_schema import is_legacy_action, parse_filename  # noqa: E402

RUNTIME_PACKAGE = CUSTODIAN_ROOT / "content/sprites/operator/runtime"
RUNTIME_MANIFEST = RUNTIME_PACKAGE / "operator_runtime_manifest.generated.json"
RUNTIME_FRAMES = RUNTIME_PACKAGE / "operator_runtime_frames.tres"
OPERATOR_RUNTIME_ANIMATIONS = RUNTIME_PACKAGE / "animations"
WEAPONS_ROOT = CUSTODIAN_ROOT / "content/sprites/weapons"
GAME_ROOT = CUSTODIAN_ROOT / "game"
OPERATOR_GD = GAME_ROOT / "actors/operator/operator.gd"

MANIFEST_SCHEMA = "custodian.operator_runtime_manifest.v1"

COMPATIBILITY_RESOURCES = [
    "operator_runtime_frames.tres",
    "operator_weapon_frames.tres",
    "operator_melee_overlay_frames.tres",
    "operator_ranged_fx_frames.tres",
    "operator_modular_lower_body_frames.tres",
    "operator_modular_upper_body_frames.tres",
    "operator_modular_sidearm_frames.tres",
    "operator_modular_upper_fx_frames.tres",
    "operator_modular_cape_frames.tres",
    "operator_modular_head_frames.tres",
    "operator_animation_catalog_frames.tres",
]

RETIRED_SELECTION_SYMBOLS = (
    "AnimationResolver",
    "DirectionalAnimationFallback",
    "OperatorAnimationCatalog",
    "fallback_animation",
)


def manifest_layer_specs(manifest: dict) -> list[tuple[str, dict]]:
    specs: list[tuple[str, dict]] = []
    for identity, entry in manifest.get("animations", {}).items():
        for layer, spec in entry.get("layers", {}).items():
            specs.append((f"{identity}/{layer}", spec))
    for weapon_id, weapon in manifest.get("weapons", {}).items():
        for direction, spec in weapon.get("held", {}).items():
            specs.append((f"weapon/{weapon_id}/held/{direction}", spec))
        for slot, layers in weapon.get("overrides", {}).items():
            for layer, spec in layers.items():
                specs.append((f"weapon/{weapon_id}/{slot}/{layer}", spec))
    return specs


def check_invariants() -> list[str]:
    failures: list[str] = []

    if not RUNTIME_MANIFEST.exists():
        return [f"missing runtime manifest: {RUNTIME_MANIFEST}"]
    manifest = json.loads(RUNTIME_MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("schema") != MANIFEST_SCHEMA:
        failures.append(f"manifest schema is {manifest.get('schema')!r}, expected {MANIFEST_SCHEMA!r}")

    specs = manifest_layer_specs(manifest)
    if not specs:
        failures.append("runtime manifest describes no animations")
    for name, spec in specs:
        path = str(spec.get("path", ""))
        if "/runtime/" not in path:
            failures.append(f"manifest layer {name} is not runtime art: {path}")
        if not (CUSTODIAN_ROOT / path.removeprefix("res://")).exists():
            failures.append(f"manifest layer {name} points at a missing file: {path}")
        try:
            if is_legacy_action(parse_filename(path, allow_legacy_action=True).action):
                failures.append(f"legacy identity entered runtime manifest: {name}")
        except ValueError as exc:
            failures.append(f"manifest layer {name} is not a canonical filename: {exc}")

    if not RUNTIME_FRAMES.exists():
        failures.append(f"missing generated runtime SpriteFrames: {RUNTIME_FRAMES}")
    else:
        frames_text = RUNTIME_FRAMES.read_text(encoding="utf-8", errors="ignore")
        for referenced in re.findall(r'path="(res://[^"]+\.png)"', frames_text):
            if "/runtime/" not in referenced:
                failures.append(f"runtime SpriteFrames references non-runtime art: {referenced}")
        if re.search(r'name=&"[^"]*legacy_', frames_text):
            failures.append("runtime SpriteFrames contains a legacy animation identity")

    # Gameplay may never read Operator animation art from authoring authority.
    for path in sorted(GAME_ROOT.rglob("*")):
        if path.suffix not in {".gd", ".tscn", ".tres"} or not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "content/sprites/operator/source/" in text:
            failures.append(f"gameplay reads Operator source art: {path.relative_to(PROJECT_ROOT)}")
        if re.search(r"content/sprites/weapons/[a-z0-9_]+/source/", text):
            failures.append(f"gameplay reads weapon source art: {path.relative_to(PROJECT_ROOT)}")
    return failures


def check_completion_gates() -> list[str]:
    gates: list[str] = []

    residue = []
    for root in [OPERATOR_RUNTIME_ANIMATIONS, *WEAPONS_ROOT.glob("*/runtime")]:
        if not root.exists():
            continue
        for png in root.rglob("*.png"):
            try:
                if is_legacy_action(parse_filename(png, allow_legacy_action=True).action):
                    residue.append(png)
            except ValueError:
                continue
    if residue:
        gates.append(f"legacy runtime residue: {len(residue)} files still under runtime/")

    present = [name for name in COMPATIBILITY_RESOURCES
               if (GAME_ROOT / "actors/operator" / name).exists()]
    if present:
        gates.append(f"compatibility SpriteFrames still present: {len(present)} ({', '.join(sorted(present)[:3])}...)")

    if OPERATOR_GD.exists():
        actor = OPERATOR_GD.read_text(encoding="utf-8", errors="ignore")
        raw = actor.count("content/sprites/operator/runtime/animations")
        if raw:
            gates.append(f"operator.gd still names {raw} raw runtime PNG paths")

    live_symbols: dict[str, int] = {}
    for path in sorted(GAME_ROOT.rglob("*.gd")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for symbol in RETIRED_SELECTION_SYMBOLS:
            if symbol in text:
                live_symbols[symbol] = live_symbols.get(symbol, 0) + 1
    if live_symbols:
        detail = ", ".join(f"{k} in {v} files" for k, v in sorted(live_symbols.items()))
        gates.append(f"retired selection symbols still live: {detail}")
    return gates


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true",
                        help="also fail on completion gates; the migration is done when this passes")
    args = parser.parse_args(argv)

    failures = check_invariants()
    gates = check_completion_gates()

    for failure in failures:
        print(f"FAIL {failure}", file=sys.stderr)
    for gate in gates:
        print(f"{'FAIL' if args.final else 'TODO'} {gate}", file=sys.stderr if args.final else sys.stdout)

    if failures or (args.final and gates):
        return 1
    print(
        "operator runtime animation authority smoke passed"
        + (f" ({len(gates)} migration gates remaining)" if gates else " (migration complete)")
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
