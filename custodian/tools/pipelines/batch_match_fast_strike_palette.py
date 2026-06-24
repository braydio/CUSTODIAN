#!/usr/bin/env python3
"""Batch-palette-match all fast_strike_01 strips to their fast_windup_01 counterparts.

For each layer (upper_body, lower_body, upper_fx) and direction (e,n,ne,nw,s,se,sw,w):
  - Reference: operator__modular_{layer}__unarmed__fast_windup_01__{dir}__3f__96.png
  - Target:    operator__modular_{layer}__unarmed__fast_strike_01__{dir}__3f__96.png
  - Output:    (overwrites target in place)

Also matches the ALTERNATE fx strip.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

TOOL = Path(__file__).resolve().parent / "match_sprite_palette.py"
SOURCE_DIR = Path(__file__).resolve().parents[2] / "content/sprites/operator/new_operator/modular/fast_attack"
DIRECTIONS = ("e", "n", "ne", "nw", "s", "se", "sw", "w")
LAYERS = ("upper_body", "lower_body", "upper_fx")
STRENGTH = 0.9
MAX_COLORS = 64


def main() -> int:
    failures = 0
    matches = 0

    for layer in LAYERS:
        for direction in DIRECTIONS:
            ref = SOURCE_DIR / f"operator__modular_{layer}__unarmed__fast_windup_01__{direction}__3f__96.png"
            target = SOURCE_DIR / f"operator__modular_{layer}__unarmed__fast_strike_01__{direction}__3f__96.png"

            if not ref.exists():
                print(f"SKIP (no ref): {ref.name}")
                continue
            if not target.exists():
                print(f"SKIP (no target): {target.name}")
                continue

            # Output overwrites target in-place
            cmd = [
                sys.executable, str(TOOL),
                "--reference", str(ref),
                "--target", str(target),
                "--output", str(target),
                "--strength", str(STRENGTH),
                "--max-colors", str(MAX_COLORS),
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"FAIL: {target.name}")
                print(result.stderr)
                failures += 1
            else:
                print(f"OK:   {target.name}")
                matches += 1

    # Also match the ALTERNATE fx strip if it exists
    alt_target = SOURCE_DIR / "operator__modular_upper_fx__unarmed__fast_strike_01__e__3f__96__ALTERNATE.png"
    alt_ref_e = SOURCE_DIR / "operator__modular_upper_fx__unarmed__fast_windup_01__e__3f__96.png"
    if alt_target.exists() and alt_ref_e.exists():
        cmd = [
            sys.executable, str(TOOL),
            "--reference", str(alt_ref_e),
            "--target", str(alt_target),
            "--output", str(alt_target),
            "--strength", str(STRENGTH),
            "--max-colors", str(MAX_COLORS),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"FAIL: {alt_target.name}")
            print(result.stderr)
            failures += 1
        else:
            print(f"OK:   {alt_target.name}")
            matches += 1

    print(f"\nDone. {matches} matched, {failures} failed.")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
