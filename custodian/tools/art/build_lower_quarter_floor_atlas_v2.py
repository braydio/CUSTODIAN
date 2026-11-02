#!/usr/bin/env python3
"""Build the Lower Quarter Gothic-scifi floor runtime atlas from its master.

See custodian/docs/ai_context/task_packets/ASH_BELL_LOWER_QUARTER_FLOOR_PASS_V2.md
for the contract this enforces: a 1024x1024, 16x16-cell, 64px/cell source
master downconverted per-cell at exactly 0.5x into a 512x512, 16x16-cell,
32px/cell runtime atlas. Source [x,y] maps directly to runtime [x,y].

Each cell is cropped from the master before resizing, so no cell can bleed
into a neighbor's seam.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

GRID = 16
SRC_CELL = 64
DST_CELL = 32
SRC_SIZE = GRID * SRC_CELL
DST_SIZE = GRID * DST_CELL

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_SOURCE = (
    REPO_ROOT
    / "custodian/asset_drop/source_work/lower_quarter_region"
    / "lower_quarter_gothic_scifi_floor__master__1024x1024.png"
)
DEFAULT_OUTPUT = (
    REPO_ROOT
    / "custodian/content/tiles/ash_bell/lower_quarter"
    / "lower_quarter_gothic_scifi_floor_atlas_512.png"
)


def build_atlas(source: Path, output: Path) -> None:
    with Image.open(source) as master:
        master = master.convert("RGBA")
        if master.size != (SRC_SIZE, SRC_SIZE):
            raise ValueError(
                f"expected {SRC_SIZE}x{SRC_SIZE} source master, got "
                f"{master.size[0]}x{master.size[1]} ({source})"
            )

        atlas = Image.new("RGBA", (DST_SIZE, DST_SIZE))
        for cell_y in range(GRID):
            for cell_x in range(GRID):
                left = cell_x * SRC_CELL
                top = cell_y * SRC_CELL
                cell = master.crop((left, top, left + SRC_CELL, top + SRC_CELL))
                cell = cell.resize((DST_CELL, DST_CELL), Image.Resampling.BOX)
                atlas.paste(cell, (cell_x * DST_CELL, cell_y * DST_CELL))

    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)
    print(f"wrote {output} ({atlas.size[0]}x{atlas.size[1]})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    if not args.source.exists():
        raise SystemExit(
            f"source master not found: {args.source}\n"
            "Drop the authored 1024x1024 master there first — see "
            "ASH_BELL_LOWER_QUARTER_FLOOR_PASS_V2.md."
        )

    build_atlas(args.source, args.output)


if __name__ == "__main__":
    main()
