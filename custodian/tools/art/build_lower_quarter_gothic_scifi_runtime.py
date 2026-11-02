#!/usr/bin/env python3
"""Build Lower Quarter Gothic-Sci-Fi native runtime art from reviewed source coordinates.

This is an OFFLINE authoring builder. It never touches collision/navigation and
never auto-fits individual assets. Both source sheets use one global 0.5 scale.

Expected repo inputs:
  custodian/asset_drop/source_work/lower_quarter_region/
    lower_quarter_gothic_scifi_walls__master__1448x1086.png
    lower_quarter_gothic_scifi_props__master__1448x1086.png
    lower_quarter_gothic_scifi_walls__coords.json
    lower_quarter_gothic_scifi_props__coords.json

  custodian/content/metadata/assets/
    lower_quarter_gothic_scifi_walls.source_review.json
    lower_quarter_gothic_scifi_props.source_review.json

Outputs:
  content/sprites/environment/structure/ash_bell/lower_quarter/gothic_scifi_native/
  content/sprites/environment/props/ash_bell/lower_quarter/gothic_scifi_native/
  content/metadata/assets/lower_quarter_gothic_scifi_walls_native.semantic.json
  content/metadata/assets/lower_quarter_gothic_scifi_props_native.semantic.json
"""
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
PROJECT = ROOT / "custodian"

SOURCE_ROOT = PROJECT / "asset_drop/source_work/lower_quarter_region"
META_ROOT = PROJECT / "content/metadata/assets"

WALL_SOURCE = SOURCE_ROOT / "lower_quarter_gothic_scifi_walls__master__1448x1086.png"
PROP_SOURCE = SOURCE_ROOT / "lower_quarter_gothic_scifi_props__master__1448x1086.png"

WALL_REVIEW = META_ROOT / "lower_quarter_gothic_scifi_walls.source_review.json"
PROP_REVIEW = META_ROOT / "lower_quarter_gothic_scifi_props.source_review.json"

WALL_RUNTIME = PROJECT / "content/sprites/environment/structure/ash_bell/lower_quarter/gothic_scifi_native"
PROP_RUNTIME = PROJECT / "content/sprites/environment/props/ash_bell/lower_quarter/gothic_scifi_native"

WALL_MANIFEST = META_ROOT / "lower_quarter_gothic_scifi_walls_native.semantic.json"
PROP_MANIFEST = META_ROOT / "lower_quarter_gothic_scifi_props_native.semantic.json"

RUNTIME_SCALE = 0.5
ALPHA_CUTOFF = 16
PALETTE_COLORS = 48


def load_json(path: Path) -> dict:
    if not path.is_file():
        raise RuntimeError(f"missing required input: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def build_palette(source: Image.Image) -> Image.Image:
    """Build one shared palette per source sheet from opaque pixels."""
    rgba = source.convert("RGBA")
    pixels = []
    stride = max(1, (rgba.width * rgba.height) // 65536)
    flat = list(rgba.getdata())
    for i in range(0, len(flat), stride):
        r, g, b, a = flat[i]
        if a > ALPHA_CUTOFF:
            pixels.append((r, g, b))
    if not pixels:
        raise RuntimeError("source has no opaque pixels")
    side = 256
    rows = (len(pixels) + side - 1) // side
    sample = Image.new("RGB", (side, rows), (0, 0, 0))
    sample.putdata(pixels + [(0, 0, 0)] * (side * rows - len(pixels)))
    return sample.quantize(colors=PALETTE_COLORS, method=Image.Quantize.MEDIANCUT)


def binary_alpha(image: Image.Image) -> Image.Image:
    out = image.convert("RGBA")
    a = out.getchannel("A").point(lambda v: 255 if v > ALPHA_CUTOFF else 0)
    out.putalpha(a)
    return out


def convert_crop(crop: Image.Image, palette: Image.Image) -> Image.Image:
    w = max(1, round(crop.width * RUNTIME_SCALE))
    h = max(1, round(crop.height * RUNTIME_SCALE))
    reduced = crop.convert("RGBA").resize((w, h), Image.Resampling.BOX)
    alpha = reduced.getchannel("A")
    rgb = reduced.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB")
    out = Image.merge("RGBA", (*rgb.split(), alpha))
    return binary_alpha(out)


def floor_contact_anchor(image: Image.Image) -> tuple[float, float]:
    a = image.getchannel("A")
    bbox = a.getbbox()
    if bbox is None:
        return (image.width / 2.0, float(image.height))
    x0, y0, x1, y1 = bbox
    band = max(2, round((y1 - y0) * 0.08))
    points = []
    px = a.load()
    for y in range(max(y0, y1 - band), y1):
        for x in range(x0, x1):
            if px[x, y] > 0:
                points.append(x)
    anchor_x = (min(points) + max(points)) / 2.0 if points else (x0 + x1) / 2.0
    return (anchor_x, float(y1))


def anchor_for(image: Image.Image, mode: str) -> tuple[float, float]:
    if mode in ("floor_contact", "wall_bottom_center"):
        if mode == "floor_contact":
            return floor_contact_anchor(image)
        return (image.width / 2.0, float(image.height))
    if mode == "floor_center":
        return (image.width / 2.0, image.height / 2.0)
    if mode == "wall_top_center":
        return (image.width / 2.0, 0.0)
    raise RuntimeError(f"unsupported anchor mode: {mode}")


def build(source_path: Path, review_path: Path, runtime_root: Path, manifest_path: Path, kind: str) -> None:
    source = Image.open(source_path).convert("RGBA")
    review = load_json(review_path)

    expected = review.get("source", {}).get("size")
    if expected and list(source.size) != list(expected):
        raise RuntimeError(f"{kind} source size mismatch: got={source.size} expected={expected}")

    if float(review.get("runtime_scale", -1)) != RUNTIME_SCALE:
        raise RuntimeError(f"{kind} review scale must be exactly {RUNTIME_SCALE}")

    palette = build_palette(source)
    entries = []

    for entry in review["entries"]:
        if entry["production_status"] == "detail_only":
            continue

        x, y, w, h = map(int, entry["rect_px"])
        crop = source.crop((x, y, x + w, y + h))
        converted = convert_crop(crop, palette)

        family = str(entry["runtime_family"])
        variant = str(entry["variant_key"])
        dst = runtime_root / family / f"{variant}.png"
        dst.parent.mkdir(parents=True, exist_ok=True)
        converted.save(dst, optimize=True)

        ax, ay = anchor_for(converted, str(entry["anchor_mode"]))
        sprite_position = [
            converted.width / 2.0 - ax,
            converted.height / 2.0 - ay,
        ]

        item = dict(entry)
        item.update({
            "texture_path": "res://" + dst.relative_to(PROJECT).as_posix(),
            "native_size": [converted.width, converted.height],
            "canvas_size": [converted.width, converted.height],
            "sprite_position": sprite_position,
            "native_scale": 1.0,
            "source_runtime_scale": RUNTIME_SCALE,
            "collision_profile": "none",
            "collision_is_authoritative": False,
            "y_sort": entry["role"] != "floor_overlay",
        })
        entries.append(item)

    doc = {
        "schema": "custodian.semantic_native_visual_manifest.v1",
        "family_id": f"lower_quarter_gothic_scifi_{kind}",
        "source_master": {
            "path": "res://" + source_path.relative_to(PROJECT).as_posix(),
            "size": list(source.size),
        },
        "runtime_contract": {
            "global_source_scale": RUNTIME_SCALE,
            "individual_autofit": False,
            "alpha": "binary 0/255 after cutoff 16",
            "shared_palette_colors": PALETTE_COLORS,
            "collision": "visual-only; existing authored topology remains authority",
        },
        "entries": entries,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"{kind}: built {len(entries)} runtime entries -> {manifest_path}")


def main() -> None:
    build(WALL_SOURCE, WALL_REVIEW, WALL_RUNTIME, WALL_MANIFEST, "walls")
    build(PROP_SOURCE, PROP_REVIEW, PROP_RUNTIME, PROP_MANIFEST, "props")


if __name__ == "__main__":
    main()
