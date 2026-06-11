#!/usr/bin/env python3
"""
Operator Combination Checker
============================
Composites the fast attack triplet (windup → strike → recovery) with FX overlay
into review PNG strips so you can eyeball how the modular animations look.

The body strips are already pre-composited (lower+upper) by
build_operator_modular_runtime.py. This script chains them into a single
continuous animation per direction with the FX overlaid on the strike frames.

Outputs:
  fast_attack_triplet_review.png  — 8 directions × 9 frames grid
  fast_attack_{s,se,e,ne,n,nw,w,sw}.png — one horizontal strip per direction

Usage:
  python3 tools/pipelines/operator_combination_checker.py

Outputs go to PROJECT_ROOT/animation_review/
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ACTION_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime/actions/unarmed/fast_attack"
OUTPUT_DIR = PROJECT_ROOT / "animation_review"

FRAME_SIZE = 96
TRIPLET_FRAMES = 9  # windup(3) + strike(3) + recovery(3)

DIRECTIONS = ("s", "se", "e", "ne", "n", "nw", "w", "sw")


def _strip_path(action_root: Path, kind: str, phase: str, direction: str) -> Path:
    """Build path like: body/operator__body__unarmed__fast_windup_01__s__3f__96.png"""
    phase_map = {
        "windup": "fast_windup_01",
        "strike": "fast_strike_01",
        "recovery": "fast_recovery_01",
    }
    phase_code = phase_map[phase]
    return action_root / kind / f"operator__{'body' if kind == 'body' else 'fx'}__unarmed__{phase_code}__{direction}__3f__96.png"


def _load_strip(path: Path) -> Image.Image:
    """Load a horizontal frame strip PNG. Returns RGBA."""
    img = Image.open(path)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    return img


def _extract_frame(strip: Image.Image, index: int) -> Image.Image:
    """Extract one 96×96 frame from a horizontal strip."""
    x = index * FRAME_SIZE
    return strip.crop((x, 0, x + FRAME_SIZE, FRAME_SIZE))


def _composite_frame(body_img: Image.Image, fx_img: Image.Image | None) -> Image.Image:
    """Composite body + optional FX overlay onto a transparent 96×96 canvas."""
    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    frame.paste(body_img, (0, 0), body_img)
    if fx_img is not None:
        frame.paste(fx_img, (0, 0), fx_img)
    return frame


def build_triplet_strip(
    action_root: Path,
    direction: str,
    include_fx: bool = True,
) -> Image.Image:
    """
    Build a single horizontal strip: windup(3) | strike(3) [with FX] | recovery(3).

    Returns a TRIPLET_FRAMES * FRAME_SIZE wide × FRAME_SIZE tall RGBA image.
    """
    width = TRIPLET_FRAMES * FRAME_SIZE
    canvas = Image.new("RGBA", (width, FRAME_SIZE), (0, 0, 0, 0))

    # Load strips
    windup_strip = _load_strip(_strip_path(action_root, "body", "windup", direction))
    strike_strip = _load_strip(_strip_path(action_root, "body", "strike", direction))
    recovery_strip = _load_strip(_strip_path(action_root, "body", "recovery", direction))

    fx_strip: Image.Image | None = None
    if include_fx:
        fx_path = _strip_path(action_root, "overlay", "strike", direction)
        if fx_path.exists():
            fx_strip = _load_strip(fx_path)

    x = 0

    # Windup (frames 0-2)
    for f in range(3):
        body = _extract_frame(windup_strip, f)
        frame = _composite_frame(body, None)
        canvas.paste(frame, (x, 0), frame)
        x += FRAME_SIZE

    # Strike (frames 3-5) with FX overlay
    for f in range(3):
        body = _extract_frame(strike_strip, f)
        fx = _extract_frame(fx_strip, f) if fx_strip else None
        frame = _composite_frame(body, fx)
        canvas.paste(frame, (x, 0), frame)
        x += FRAME_SIZE

    # Recovery (frames 6-8)
    for f in range(3):
        body = _extract_frame(recovery_strip, f)
        frame = _composite_frame(body, None)
        canvas.paste(frame, (x, 0), frame)
        x += FRAME_SIZE

    return canvas


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Chain fast attack triplet into review strips."
    )
    parser.add_argument(
        "--action-root",
        type=Path,
        default=ACTION_ROOT,
        help="Path to fast_attack action root (body/ + overlay/)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=OUTPUT_DIR,
        help="Where to save the review PNGs",
    )
    parser.add_argument(
        "--no-fx", action="store_true", help="Skip the FX overlay layer"
    )
    args = parser.parse_args()

    action_root = args.action_root.resolve()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    include_fx = not args.no_fx

    # ── Individual direction strips ──────────────────────────────────────
    for direction in DIRECTIONS:
        strip = build_triplet_strip(action_root, direction, include_fx)
        path = output_dir / f"fast_attack_{direction}.png"
        strip.save(path)
        print(f"  {path.name}  {strip.width}×{strip.height}")

    # ── Full grid: 8 directions × 9 frames ──────────────────────────────
    grid_width = TRIPLET_FRAMES * FRAME_SIZE
    grid_height = len(DIRECTIONS) * FRAME_SIZE
    grid = Image.new("RGBA", (grid_width, grid_height), (0, 0, 0, 0))

    for row_idx, direction in enumerate(DIRECTIONS):
        strip = build_triplet_strip(action_root, direction, include_fx)
        grid.paste(strip, (0, row_idx * FRAME_SIZE))

    grid_path = output_dir / "fast_attack_triplet_review.png"
    grid.save(grid_path)
    print(f"\n  {grid_path.name}  {grid.width}×{grid.height}")

    # ── Summary ──────────────────────────────────────────────────────────
    print(f"\nSaved {len(DIRECTIONS) + 1} review images to {output_dir}")
    print(f"Direction order (top→bottom): {', '.join(DIRECTIONS)}")
    print("Frame order (left→right): windup(0-2) | strike(3-5) | recovery(6-8)")
    return 0


if __name__ == "__main__":
    exit(main())
