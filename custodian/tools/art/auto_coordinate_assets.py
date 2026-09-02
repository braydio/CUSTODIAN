#!/usr/bin/env python3
"""Automatic true-alpha atlas coordinate extractor for CUSTODIAN source sheets.

Finds alpha-connected assets, emits deterministic source-space rectangles,
a numbered overlay, optional crops, and JSON. This is SOURCE authoring only;
it does not resize or publish runtime assets.
"""
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def args():
    p = argparse.ArgumentParser()
    p.add_argument("source", type=Path)
    p.add_argument("--out", type=Path, default=None)
    p.add_argument("--kind", choices=("wall", "prop", "asset"), default="asset")
    p.add_argument("--alpha", type=int, default=10)
    p.add_argument("--min-area", type=int, default=100)
    p.add_argument("--padding", type=int, default=0)
    p.add_argument("--row-band", type=int, default=90,
                   help="Visual reading-order Y quantization in source pixels")
    p.add_argument("--crops", action="store_true")
    return p.parse_args()


def font(size=14):
    for f in (
        "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
        "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    ):
        if Path(f).exists():
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def components(img: Image.Image, alpha_threshold: int, min_area: int):
    a = img.getchannel("A")
    w, h = img.size
    pix = a.load()
    visited = bytearray(w * h)
    out = []
    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if visited[idx]:
                continue
            visited[idx] = 1
            if pix[x, y] <= alpha_threshold:
                continue
            q = deque([(x, y)])
            area = 0
            x0 = x1 = x
            y0 = y1 = y
            while q:
                px, py = q.popleft()
                area += 1
                x0 = min(x0, px); x1 = max(x1, px)
                y0 = min(y0, py); y1 = max(y1, py)
                for dx, dy in ((-1,0),(1,0),(0,-1),(0,1)):
                    nx, ny = px + dx, py + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    nidx = ny * w + nx
                    if visited[nidx]:
                        continue
                    visited[nidx] = 1
                    if pix[nx, ny] > alpha_threshold:
                        q.append((nx, ny))
            if area >= min_area:
                out.append((x0, y0, x1 + 1, y1 + 1, area))
    return out


def main():
    a = args()
    src = a.source.resolve()
    out = (a.out or src.parent / (src.stem + "__coords")).resolve()
    out.mkdir(parents=True, exist_ok=True)
    img = Image.open(src).convert("RGBA")
    w, h = img.size

    raw = components(img, a.alpha, a.min_area)
    records = []
    for x0, y0, x1, y1, area in raw:
        x0 = max(0, x0 - a.padding); y0 = max(0, y0 - a.padding)
        x1 = min(w, x1 + a.padding); y1 = min(h, y1 + a.padding)
        records.append({
            "x": x0, "y": y0, "w": x1-x0, "h": y1-y0,
            "area": area, "cx": (x0+x1)/2, "cy": (y0+y1)/2,
        })

    # Stable human reading order: broad Y row first, then X.
    records.sort(key=lambda r: (round(r["cy"] / a.row_band), r["cx"], r["cy"]))
    for i, r in enumerate(records, 1):
        r["index"] = i
        r["id"] = f"{a.kind}_asset_{i:03d}"

    payload = {
        "schema": "custodian.auto_source_coordinates.v1",
        "source": {"path": str(src), "filename": src.name, "size": [w, h]},
        "detector": {
            "alpha_threshold": a.alpha,
            "connectivity": 4,
            "min_area": a.min_area,
            "padding_px": a.padding,
            "row_band_px": a.row_band,
            "resizing": "none",
        },
        "asset_count": len(records),
        "regions": [
            {
                "index": r["index"],
                "id": r["id"],
                "category": "unclassified",
                "rect_px": [r["x"], r["y"], r["w"], r["h"]],
                "opaque_component_area": r["area"],
            }
            for r in records
        ],
    }

    json_path = out / f"{src.stem}__coords.json"
    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    overlay = img.copy()
    d = ImageDraw.Draw(overlay)
    fnt = font()
    for r in records:
        x, y, ww, hh = r["x"], r["y"], r["w"], r["h"]
        d.rectangle((x, y, x+ww-1, y+hh-1), outline=(255,255,0,255), width=2)
        label = str(r["index"])
        box = d.textbbox((0,0), label, font=fnt)
        tw, th = box[2]-box[0], box[3]-box[1]
        d.rectangle((x, y, x+tw+6, y+th+5), fill=(0,0,0,220))
        d.text((x+2, y+1), label, fill=(255,255,0,255), font=fnt)
    overlay_path = out / f"{src.stem}__coords_overlay.png"
    overlay.save(overlay_path)

    if a.crops:
        crop_dir = out / "crops"
        crop_dir.mkdir(exist_ok=True)
        for r in records:
            x, y, ww, hh = r["x"], r["y"], r["w"], r["h"]
            img.crop((x,y,x+ww,y+hh)).save(crop_dir / f"{r['id']}__{ww}x{hh}.png")

    print(f"assets={len(records)}")
    print(json_path)
    print(overlay_path)


if __name__ == "__main__":
    main()
