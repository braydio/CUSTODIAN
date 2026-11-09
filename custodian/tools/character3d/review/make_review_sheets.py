"""Compact review sheets for cleaned Pursuit Frame renders.

One sheet per action: rows are the 8 directions, columns are evenly spaced frames.
Cells are native 1:1 pixels, with labels in a margin outside the cells. Inputs are read only.

Usage:
  python3 -I scripts/make_review_sheets.py --src output/clean/c256_80 --action running --out output/review
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw

DIRS = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
COLUMNS = 6
MARGIN = 40
GAP = 4
BG = (40, 40, 40)
TEXT = (230, 230, 230)


def sheet(src_root: Path, action: str, out_dir: Path):
    action_root = src_root / action
    first = next((action_root / "S").glob("frame_*.png"))
    cell = Image.open(first).size[0]
    frame_count = len(list((action_root / "S").glob("frame_*.png")))
    picks = [round(i * (frame_count - 1) / (COLUMNS - 1)) for i in range(COLUMNS)]
    width = MARGIN + COLUMNS * (cell + GAP)
    height = 24 + len(DIRS) * (cell + GAP)
    img = Image.new("RGBA", (width, height), BG + (255,))
    draw = ImageDraw.Draw(img)
    for col, frame in enumerate(picks):
        x = MARGIN + col * (cell + GAP)
        draw.text((x + 2, 4), f"f{frame:03d}", fill=TEXT)
    for row, d in enumerate(DIRS):
        y = 24 + row * (cell + GAP)
        draw.text((6, y + cell // 2 - 6), d, fill=TEXT)
        for col, frame in enumerate(picks):
            x = MARGIN + col * (cell + GAP)
            tile = Image.open(action_root / d / f"frame_{frame:02d}.png").convert("RGBA")
            img.alpha_composite(tile, (x, y))
    out_dir.mkdir(parents=True, exist_ok=True)
    dst = out_dir / f"{action}_{src_root.name}_sheet.png"
    img.save(dst)
    return dst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--action", required=True, nargs="+")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    for action in args.action:
        print(sheet(Path(args.src), action, Path(args.out)))


if __name__ == "__main__":
    main()
