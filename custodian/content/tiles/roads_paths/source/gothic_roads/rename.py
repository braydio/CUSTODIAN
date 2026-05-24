#!/usr/bin/env python3
"""
Fix overlay slice names using explicit source-index remapping.

This is for cases where the export script guessed the wrong semantic role:
  085_overlay_hardware_plate_01.png  -> overlay_hanging_banner_01.png

Default behavior copies files into a corrected output folder.
Use --in-place only after reviewing the dry run.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

NAME_RE = re.compile(
    r"^(?P<source_index>\d{3})_overlay_(?P<old_role>[a-z0-9_]+)_(?P<old_role_index>\d{2})\.png$"
)

# Explicit source-index truth table.
# Edit this after visually inspecting the contact sheet.
ROLE_BY_SOURCE_INDEX: dict[int, str] = {
    # Top / cracks
    1: "rubble_debris",
    7: "crack",
    8: "crack",
    9: "crack",
    10: "crack",
    # Rune circles
    11: "rune_circle",
    12: "rune_circle",
    13: "rune_circle",
    16: "rune_circle",
    17: "rune_circle",
    18: "rune_circle",
    19: "rune_circle",
    # Rune marks
    20: "rune_mark",
    23: "rune_mark",
    24: "rune_mark",
    25: "rune_mark",
    26: "rune_mark",
    # Gothic trims
    27: "gothic_corner_trim",
    28: "gothic_corner_trim",
    29: "gothic_corner_trim",
    30: "gothic_corner_trim",
    31: "gothic_corner_trim",
    32: "gothic_corner_trim",
    33: "gothic_corner_trim",
    34: "gothic_corner_trim",
    35: "gothic_corner_trim",
    36: "gothic_corner_trim",
    37: "gothic_corner_trim",
    38: "gothic_corner_trim",
    # Relic symbols
    39: "relic_symbol",
    40: "relic_symbol",
    41: "relic_symbol",
    42: "relic_symbol",
    43: "relic_symbol",
    44: "relic_symbol",
    45: "relic_symbol",
    46: "relic_symbol",
    47: "relic_symbol",
    # Rubble
    49: "rubble_debris",
    50: "rubble_debris",
    51: "rubble_debris",
    52: "rubble_debris",
    53: "rubble_debris",
    # Barriers / shrines / stains
    54: "barrier_chain",
    55: "barrier_chain",
    56: "candle_shrine",
    57: "candle_shrine",
    58: "candle_shrine",
    59: "candle_shrine",
    60: "candle_shrine",
    61: "candle_shrine",
    62: "candle_shrine",
    63: "candle_shrine",
    64: "candle_shrine",
    65: "candle_shrine",
    68: "blood_splatter",
    69: "blood_splatter",
    70: "blood_splatter",
    71: "blood_splatter",
    72: "blood_splatter",
    73: "puddle_stain",
    74: "puddle_stain",
    75: "puddle_stain",
    # Corrected lower rows.
    # You specifically called out that these are actually banners.
    85: "hanging_banner",
    86: "hanging_banner",
    87: "hanging_banner",
    88: "hanging_banner",
    # Inspect these four. If they are not hardware/trim, change this block.
    89: "hardware_plate",
    90: "hardware_plate",
    91: "hardware_plate",
    92: "hardware_plate",
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--dir", required=True, help="Directory containing overlay PNGs.")
    p.add_argument(
        "--out-dir",
        default=None,
        help="Corrected output folder. Default: <dir>/../overlays_corrected",
    )
    p.add_argument("--apply", action="store_true", help="Actually copy/rename files.")
    p.add_argument(
        "--in-place",
        action="store_true",
        help="Rename files in place instead of copying to out-dir. Not recommended until reviewed.",
    )
    p.add_argument(
        "--delete-imports",
        action="store_true",
        help="Delete old .png.import files when using --in-place.",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    src_dir = Path(args.dir).expanduser().resolve()

    if not src_dir.is_dir():
        raise SystemExit(f"Not a directory: {src_dir}")

    if args.in_place:
        out_dir = src_dir
    else:
        out_dir = (
            Path(args.out_dir).expanduser().resolve()
            if args.out_dir
            else src_dir.parent / "overlays_corrected"
        )

    files = []
    skipped = []

    for path in sorted(src_dir.glob("*.png")):
        m = NAME_RE.match(path.name)
        if not m:
            skipped.append(path.name)
            continue

        source_index = int(m.group("source_index"))
        old_role = m.group("old_role")
        old_role_index = int(m.group("old_role_index"))

        corrected_role = ROLE_BY_SOURCE_INDEX.get(source_index)
        if not corrected_role:
            skipped.append(path.name)
            continue

        files.append(
            {
                "path": path,
                "source_index": source_index,
                "old_name": path.name,
                "old_role": old_role,
                "old_role_index": old_role_index,
                "corrected_role": corrected_role,
            }
        )

    # Preserve visual/source order while numbering per corrected role.
    files.sort(key=lambda x: x["source_index"])

    role_counts: dict[str, int] = defaultdict(int)
    plan = []

    for item in files:
        role = item["corrected_role"]
        role_counts[role] += 1

        new_name = f"overlay_{role}_{role_counts[role]:02d}.png"
        new_path = out_dir / new_name

        plan.append(
            {
                **item,
                "new_name": new_name,
                "new_path": new_path,
                "new_role_index": role_counts[role],
            }
        )

    print(f"Source: {src_dir}")
    print(f"Output: {out_dir}")
    print(f"Matched/remapped: {len(plan)}")
    print(f"Skipped: {len(skipped)}")
    print()

    for item in plan:
        marker = "OK"
        if item["old_role"] != item["corrected_role"]:
            marker = "FIX"

        print(f"[{marker}] {item['old_name']} -> {item['new_name']}")

    if skipped:
        print("\nSkipped:")
        for name in skipped:
            print(f"  {name}")

    if not args.apply:
        print("\nDRY RUN. Re-run with --apply after reviewing.")
        return

    out_dir.mkdir(parents=True, exist_ok=True)

    # Collision check.
    for item in plan:
        if item["new_path"].exists() and item["new_path"].name != item["old_name"]:
            raise SystemExit(f"Refusing to overwrite existing file: {item['new_path']}")

    if args.in_place:
        # Two-pass rename to avoid name collisions.
        temp_items = []
        for i, item in enumerate(plan, start=1):
            old_path = item["path"]
            temp_path = old_path.with_name(f".__tmp_overlay_fix_{i:04d}.png")
            old_path.rename(temp_path)
            temp_items.append((item, temp_path))

            old_import = old_path.with_name(old_path.name + ".import")
            if old_import.exists():
                if args.delete_imports:
                    old_import.unlink()
                else:
                    temp_import = old_path.with_name(
                        f".__tmp_overlay_fix_{i:04d}.png.import"
                    )
                    old_import.rename(temp_import)
                    item["temp_import"] = temp_import

        for item, temp_path in temp_items:
            final_path = out_dir / item["new_name"]
            temp_path.rename(final_path)

            temp_import = item.get("temp_import")
            if temp_import:
                final_import = final_path.with_name(final_path.name + ".import")
                temp_import.rename(final_import)
    else:
        for item in plan:
            shutil.copy2(item["path"], item["new_path"])

    manifest = {
        "asset": "CUSTODIAN corrected overlay naming manifest",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_dir": str(src_dir),
        "output_dir": str(out_dir),
        "in_place": bool(args.in_place),
        "remapped_count": len(plan),
        "skipped": skipped,
        "renames": [
            {
                "source_index": item["source_index"],
                "old_name": item["old_name"],
                "old_role": item["old_role"],
                "corrected_role": item["corrected_role"],
                "new_name": item["new_name"],
            }
            for item in plan
        ],
    }

    manifest_path = out_dir / "overlay_corrected_name_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print()
    print(f"Done. Wrote manifest: {manifest_path}")


if __name__ == "__main__":
    main()
