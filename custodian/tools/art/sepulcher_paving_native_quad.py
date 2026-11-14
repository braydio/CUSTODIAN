#!/usr/bin/env python3
"""Produce exactly four native 512px Sepulcher paving preview crops, no resampling.

Original source is unapproved, and generated images are DEV-ONLY.
"""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import sys
from PIL import Image, ImageChops

EXPECTED = "62341f6850cd526b5b03187d9c9035318453c2b7cf2d6e213f19f1597af967bf"
SOURCE = Path("asset_drop/source_work/hub/first_set/hub_first_set_sepulcher_gardens_floor_materials/paving_base_source.png")
OUT = Path("game/world/levels/authored/dev/sepulcher_modular_material_pilot/preview/generated")
RECTS = {
    "nw": ((128, 128, 640, 640), (0, 0)),
    "ne": ((640, 128, 1152, 640), (512, 0)),
    "sw": ((128, 640, 640, 1152), (0, 512)),
    "se": ((640, 640, 1152, 1152), (512, 512)),
}

def make_pieces(source: Image.Image):
    assert source.size == (1254, 1254) and source.mode == "RGB", "Wrong master image dimensions or color mode"
    full = Image.new("RGB", (1024, 1024))
    pieces = {}
    for name, (rect, offset) in RECTS.items():
        part = source.crop(rect)
        assert part.size == (512, 512)
        full.paste(part, offset)
        pieces[name] = part
    expected = source.crop((128, 128, 1152, 1152))
    assert ImageChops.difference(full, expected).getbbox() is None, "Original pixels not reconstructed"
    return pieces, full

def self_test():
    test = Image.new("RGB", (1254, 1254), (15, 26, 37))
    test.putpixel((128, 128), (200, 60, 80))
    test.putpixel((639, 639), (4, 5, 6))
    test.putpixel((640, 640), (11, 22, 33))
    test.putpixel((1151, 1151), (120, 121, 122))
    parts, full = make_pieces(test)
    assert len(parts) == 4 and all(v.size == (512, 512) for v in parts.values())
    assert full.getpixel((0, 0)) == (200, 60, 80)
    assert full.getpixel((511, 511)) == (4, 5, 6)
    assert full.getpixel((512, 512)) == (11, 22, 33)
    assert full.getpixel((1023, 1023)) == (120, 121, 122)
    print("PASS: fixed rectangles, native pixels, 1024x1024 reconstruction")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--custodian", type=Path, help="path to checkout's custodian/ directory")
    parser.add_argument("--out", type=Path, help="optional dev-only output location")
    parser.add_argument("--self-test", action="store_true", help="verify deterministic crop geometry without master")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if not args.custodian:
        parser.error("--custodian is required without --self-test")
    root = args.custodian.expanduser().resolve(strict=True)
    assert (root / "project.godot").is_file(), "Not a custodian Godot project"
    source = root / SOURCE
    assert source.is_file(), "Pinned raw master not staged in source_work"
    assert hashlib.sha256(source.read_bytes()).hexdigest() == EXPECTED, "Pinned source SHA mismatch"
    with Image.open(source) as image:
        pieces, full = make_pieces(image)
    destination = args.out.expanduser().resolve() if args.out else root / OUT
    destination.mkdir(parents=True, exist_ok=True)
    for name, part in pieces.items():
        target = destination / f"native_paving_{name}.png"
        if target.exists():
            with Image.open(target) as old:
                assert old.mode == "RGB" and old.size == part.size and ImageChops.difference(old, part).getbbox() is None, f"Conflicting output: {target}"
        else:
            part.save(target, "PNG")
    ref = destination / "native_quad_reference_1024.png"
    if ref.exists():
        with Image.open(ref) as existing:
            assert existing.mode == "RGB" and existing.size == full.size and ImageChops.difference(existing, full).getbbox() is None, f"Conflicting reference: {ref}"
    else:
        full.save(ref, "PNG")
    print("PASS: four 512x512 native RGB preview pieces, original 1024px region reconstructs exactly:", destination)
    print("DEV-ONLY, OUTER EDGES NOT SEAMLESS, NO ASSET V2 APPROVAL")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError) as exc:
        print("BLOCKED:", exc, file=sys.stderr)
        raise SystemExit(2)
