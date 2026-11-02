#!/usr/bin/env python3
from PIL import Image
import argparse
import os
import sys


def ring_coords(w: int, h: int, inset: int):
    """
    Return coordinates for a 1px-thick rectangular perimeter ring,
    ordered clockwise starting at top-left corner of that ring.
    """
    left = inset
    top = inset
    right = w - 1 - inset
    bottom = h - 1 - inset

    if left > right or top > bottom:
        return []

    coords = []

    # Top edge: left -> right
    for x in range(left, right + 1):
        coords.append((x, top))

    # Right edge: top+1 -> bottom-1
    for y in range(top + 1, bottom):
        coords.append((right, y))

    # Bottom edge: right -> left (if different row)
    if bottom > top:
        for x in range(right, left - 1, -1):
            coords.append((x, bottom))

    # Left edge: bottom-1 -> top+1 (if different col)
    if right > left:
        for y in range(bottom - 1, top, -1):
            coords.append((left, y))

    return coords


def map_dest_layer_to_src_inset(layer: int, out_thickness: int, inner_start: int, inner_end: int):
    """
    Map dest border layer -> source inset layer by nearest-ish scaling.
    Example:
      inner band 5..7 => source layers [5,6]
      out thickness 3 => dest layers [0,1,2] map to [5,5,6]
    """
    band_thickness = inner_end - inner_start
    if band_thickness <= 0:
        raise ValueError("inner_end must be greater than inner_start")
    src_layer_offset = int(layer * band_thickness / out_thickness)
    if src_layer_offset >= band_thickness:
        src_layer_offset = band_thickness - 1
    return inner_start + src_layer_offset


def rotate_list_clockwise(values, shift):
    if not values:
        return values
    n = len(values)
    shift %= n
    if shift == 0:
        return values[:]
    # Positive shift means content moves clockwise along our clockwise-ordered ring
    return values[-shift:] + values[:-shift]


def process_image(infile, outfile, inner_start, inner_end, out_thickness, shift):
    img = Image.open(infile).convert("RGBA")
    out = img.copy()

    w, h = img.size

    # Basic sanity
    if w <= (inner_end * 2) or h <= (inner_end * 2):
        raise ValueError(
            f"Image too small for requested inner band. "
            f"Image is {w}x{h}, inner_end={inner_end}."
        )
    if out_thickness <= 0:
        raise ValueError("out_thickness must be > 0")

    for dest_layer in range(out_thickness):
        src_inset = map_dest_layer_to_src_inset(
            dest_layer, out_thickness, inner_start, inner_end
        )

        src_coords = ring_coords(w, h, src_inset)
        dest_coords = ring_coords(w, h, dest_layer)

        if not src_coords or not dest_coords:
            continue

        # Resample source ring to match destination ring length if needed
        src_pixels = [img.getpixel(c) for c in src_coords]

        if len(src_pixels) != len(dest_coords):
            # Nearest-neighbor resampling around the ring
            resampled = []
            src_len = len(src_pixels)
            dst_len = len(dest_coords)
            for i in range(dst_len):
                src_idx = int(i * src_len / dst_len)
                if src_idx >= src_len:
                    src_idx = src_len - 1
                resampled.append(src_pixels[src_idx])
            src_pixels = resampled

        rotated = rotate_list_clockwise(src_pixels, shift)

        for coord, px in zip(dest_coords, rotated):
            out.putpixel(coord, px)

    out.save(outfile)


def main():
    parser = argparse.ArgumentParser(
        description="Copy an inner edge ring to the outer border and rotate it clockwise."
    )
    parser.add_argument("input", help="Input PNG")
    parser.add_argument("output", help="Output PNG")
    parser.add_argument("--inner-start", type=int, default=5,
                        help="Start of sampled inner band in pixels from edge (default: 5)")
    parser.add_argument("--inner-end", type=int, default=7,
                        help="End of sampled inner band in pixels from edge, exclusive (default: 7)")
    parser.add_argument("--out-thickness", type=int, default=3,
                        help="Thickness of outer border to overwrite (default: 3)")
    parser.add_argument("--shift", type=int, default=7,
                        help="Clockwise perimeter shift in pixels (default: 7)")

    args = parser.parse_args()

    process_image(
        infile=args.input,
        outfile=args.output,
        inner_start=args.inner_start,
        inner_end=args.inner_end,
        out_thickness=args.out_thickness,
        shift=args.shift,
    )


if __name__ == "__main__":
    main()
