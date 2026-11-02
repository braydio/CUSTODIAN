#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from PIL import Image, ImageDraw, ImageFont

PART_RE = re.compile(r"(^|[_/\.-])(upper|lower)(?=($|[_/\.-]))", re.IGNORECASE)
HASH_SHEET_RE = re.compile(r"__[0-9a-f]{8}__sheet$", re.IGNORECASE)
META_RE = re.compile(
    r"_(?P<frames>\d+)f(?:_(?P<frame_w>\d+))?(?:__[0-9a-f]{8})?__sheet\.png$",
    re.IGNORECASE,
)


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--out", type=Path, default=Path("./assets_review"))
    p.add_argument("--scale", type=int, default=4)
    p.add_argument("--duration-ms", type=int, default=120)
    p.add_argument("--open", action="store_true")
    p.add_argument("--upper-offset-x", type=int, default=0)
    p.add_argument("--upper-offset-y", type=int, default=0)
    p.add_argument("--lower-offset-x", type=int, default=0)
    p.add_argument("--lower-offset-y", type=int, default=0)
    return p.parse_args()


def part_for(path: Path) -> Optional[str]:
    m = PART_RE.search(path.name)
    return m.group(2).lower() if m else None


def pairing_key(path: Path) -> str:
    s = path.name.lower()
    s = re.sub(r"\.png$", "", s)
    s = HASH_SHEET_RE.sub("", s)
    s = re.sub(r"(^|[_/\.-])(upper|lower)(?=($|[_/\.-]))", r"\1part", s)
    return s


def base_id_from_lower(path: Path) -> str:
    s = path.name
    s = re.sub(r"\.png$", "", s, flags=re.IGNORECASE)
    s = HASH_SHEET_RE.sub("", s)
    s = re.sub(
        r"(^|[_/\.-])lower(?=($|[_/\.-]))", r"\1combined", s, flags=re.IGNORECASE
    )
    return s


def json_path_for_png(path: Path) -> Path:
    return path.with_suffix(".json")


def meta_from_json(path: Path) -> Optional[Tuple[int, int]]:
    jp = json_path_for_png(path)
    if not jp.exists():
        return None

    data = json.loads(jp.read_text(encoding="utf-8"))
    frames = data.get("frames", [])
    if not frames:
        return None

    first = frames[0]
    frame_box = first.get("frame", {})
    frame_w = int(frame_box.get("w", 0))
    frame_count = len(frames)

    if frame_w <= 0 or frame_count <= 0:
        return None

    return frame_count, frame_w


def sheet_meta(path: Path, img: Image.Image) -> Tuple[int, int, List[str]]:
    warnings: List[str] = []

    m = META_RE.search(path.name)
    if m:
        frame_count = int(m.group("frames"))
        frame_w_s = m.group("frame_w")
        if frame_w_s:
            frame_w = int(frame_w_s)
            return frame_count, frame_w, warnings

    json_meta = meta_from_json(path)
    if json_meta:
        return json_meta[0], json_meta[1], warnings

    if m:
        frame_count = int(m.group("frames"))
        if img.width % frame_count == 0:
            frame_w = img.width // frame_count
            warnings.append(
                f"{path.name}: inferred frame width {frame_w} from sheet width / frame count."
            )
            return frame_count, frame_w, warnings

    raise ValueError(f"Cannot infer frame metadata for {path.name}")


def checker(w: int, h: int, cell: int = 8) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            fill = (
                (40, 40, 45, 255)
                if ((x // cell + y // cell) % 2 == 0)
                else (72, 72, 80, 255)
            )
            d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=fill)
    return img


def on_checker(src: Image.Image, scale: int) -> Image.Image:
    scaled = src.resize(
        (src.width * scale, src.height * scale), Image.Resampling.NEAREST
    )
    bg = checker(scaled.width, scaled.height, max(4, scale * 2))
    bg.alpha_composite(scaled)
    return bg


def composite_pair(
    lower_path: Path, upper_path: Path, args
) -> Tuple[Image.Image, List[Image.Image], Dict]:
    lower = Image.open(lower_path).convert("RGBA")
    upper = Image.open(upper_path).convert("RGBA")

    lower_count, lower_fw, lw = sheet_meta(lower_path, lower)
    upper_count, upper_fw, uw = sheet_meta(upper_path, upper)

    warnings = lw + uw
    count = min(lower_count, upper_count)
    if lower_count != upper_count:
        warnings.append(
            f"Frame count mismatch: lower={lower_count}, upper={upper_count}; using {count}."
        )

    canvas_w = max(lower_fw, upper_fw)
    canvas_h = max(lower.height, upper.height)

    strip = Image.new("RGBA", (canvas_w * count, canvas_h), (0, 0, 0, 0))
    frames: List[Image.Image] = []

    for i in range(count):
        f = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

        lf = lower.crop((i * lower_fw, 0, (i + 1) * lower_fw, lower.height))
        uf = upper.crop((i * upper_fw, 0, (i + 1) * upper_fw, upper.height))

        lx = ((canvas_w - lower_fw) // 2) + args.lower_offset_x
        ux = ((canvas_w - upper_fw) // 2) + args.upper_offset_x

        f.alpha_composite(lf, (lx, args.lower_offset_y))
        f.alpha_composite(uf, (ux, args.upper_offset_y))

        strip.alpha_composite(f, (i * canvas_w, 0))
        frames.append(f)

    return (
        strip,
        frames,
        {
            "lower": str(lower_path),
            "upper": str(upper_path),
            "frame_count": count,
            "frame_width": canvas_w,
            "frame_height": canvas_h,
            "warnings": warnings,
        },
    )


def make_review(
    lower_path: Path, upper_path: Path, frames: List[Image.Image], args
) -> Image.Image:
    lower = Image.open(lower_path).convert("RGBA")
    upper = Image.open(upper_path).convert("RGBA")

    lower_count, lower_fw, _ = sheet_meta(lower_path, lower)
    upper_count, upper_fw, _ = sheet_meta(upper_path, upper)
    count = min(lower_count, upper_count, len(frames))

    scale = args.scale
    font = ImageFont.load_default()
    label_w = 92
    pad = 8
    gap = 6

    frame_w = frames[0].width
    frame_h = frames[0].height
    cell_w = frame_w * scale + gap
    row_h = frame_h * scale + gap

    out = Image.new(
        "RGBA",
        (label_w + pad + count * cell_w + pad, pad + 3 * row_h + pad),
        (18, 18, 22, 255),
    )
    d = ImageDraw.Draw(out)

    rows = [
        ("lower", lower, lower_fw),
        ("upper", upper, upper_fw),
        ("combined", None, frame_w),
    ]

    for row_i, (label, source, fw) in enumerate(rows):
        y = pad + row_i * row_h
        d.text((pad, y + 6), label, fill=(230, 230, 230, 255), font=font)

        for i in range(count):
            if label == "combined":
                frame = frames[i]
            else:
                frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
                crop = source.crop((i * fw, 0, (i + 1) * fw, source.height))
                frame.alpha_composite(crop, ((frame_w - fw) // 2, 0))

            preview = on_checker(frame, scale)
            x = label_w + pad + i * cell_w
            out.alpha_composite(preview, (x, y))
            d.rectangle(
                [x, y, x + preview.width - 1, y + preview.height - 1],
                outline=(150, 150, 150, 255),
            )
            d.text((x + 3, y + 3), str(i + 1), fill=(255, 255, 255, 255), font=font)

    return out


def make_gif(frames: List[Image.Image], path: Path, args) -> None:
    gif_frames = [
        on_checker(f, args.scale).convert("P", palette=Image.Palette.ADAPTIVE)
        for f in frames
    ]
    gif_frames[0].save(
        path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=args.duration_ms,
        loop=0,
        optimize=False,
        disposal=2,
    )


def write_html(path: Path, records: List[Dict]) -> None:
    cards = []
    for r in records:
        warning_html = ""
        if r["warnings"]:
            warning_html = (
                "<ul>"
                + "".join(f"<li>{html.escape(w)}</li>" for w in r["warnings"])
                + "</ul>"
            )

        cards.append(f"""
<section class="card">
  <h2>{html.escape(r["id"])}</h2>
  <p><b>lower:</b> {html.escape(r["lower_name"])}</p>
  <p><b>upper:</b> {html.escape(r["upper_name"])}</p>
  <p><b>frames:</b> {r["frame_count"]} | <b>frame:</b> {r["frame_width"]}x{r["frame_height"]}</p>
  {warning_html}
  <div class="grid">
    <div><h3>gif</h3><img src="{html.escape(r["gif_rel"])}"></div>
    <div><h3>review</h3><img src="{html.escape(r["review_rel"])}"></div>
  </div>
</section>
""")

    path.write_text(
        f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Modular PNG Pair Review</title>
<style>
body {{ background:#111216; color:#eee; font-family:system-ui,sans-serif; margin:24px; }}
.card {{ background:#1a1c22; border:1px solid #333844; border-radius:12px; padding:16px; margin-bottom:24px; }}
img {{ image-rendering:pixelated; max-width:100%; border:1px solid #444; }}
.grid {{ display:grid; grid-template-columns:minmax(180px,320px) 1fr; gap:18px; align-items:start; }}
li {{ color:#ffcf78; }}
</style>
</head>
<body>
<h1>Modular PNG Pair Review</h1>
{''.join(cards)}
</body>
</html>
""",
        encoding="utf-8",
    )


def main() -> int:
    args = parse_args()

    root = args.root.expanduser().resolve()
    out = args.out.expanduser().resolve()

    combined_dir = out / "combined"
    review_dir = out / "review"
    gif_dir = out / "gif"
    for d in [combined_dir, review_dir, gif_dir]:
        d.mkdir(parents=True, exist_ok=True)

    buckets: Dict[str, Dict[str, Path]] = {}

    for p in sorted(root.glob("*.png")):
        if not p.name.lower().endswith("__sheet.png"):
            continue

        part = part_for(p)
        if part not in {"upper", "lower"}:
            continue

        key = pairing_key(p)
        buckets.setdefault(key, {})[part] = p

    records: List[Dict] = []
    missing: List[Dict] = []

    for key, pair in sorted(buckets.items()):
        lower = pair.get("lower")
        upper = pair.get("upper")

        if not lower or not upper:
            missing.append(
                {
                    "key": key,
                    "lower": lower.name if lower else None,
                    "upper": upper.name if upper else None,
                }
            )
            continue

        rid = base_id_from_lower(lower)

        try:
            strip, frames, meta = composite_pair(lower, upper, args)
            review = make_review(lower, upper, frames, args)
        except Exception as e:
            print(f"ERROR: failed pair {key}: {e}")
            continue

        combined_path = combined_dir / f"{rid}.png"
        review_path = review_dir / f"{rid}_review.png"
        gif_path = gif_dir / f"{rid}.gif"

        strip.save(combined_path)
        review.save(review_path)
        make_gif(frames, gif_path, args)

        rec = {
            "id": rid,
            **meta,
            "lower_name": lower.name,
            "upper_name": upper.name,
            "combined_rel": str(combined_path.relative_to(out)),
            "review_rel": str(review_path.relative_to(out)),
            "gif_rel": str(gif_path.relative_to(out)),
        }
        records.append(rec)

    (out / "manifest.json").write_text(
        json.dumps(
            {
                "schema": "custodian.modular_flat_png_pair_review.v1",
                "root": str(root),
                "pair_count": len(records),
                "missing": missing,
                "records": records,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    write_html(out / "index.html", records)

    print(f"wrote {len(records)} pair reviews")
    print(f"index:    {out / 'index.html'}")
    print(f"manifest: {out / 'manifest.json'}")

    if missing:
        print()
        print("unpaired sheets:")
        for m in missing:
            print(f"  - key={m['key']} lower={m['lower']} upper={m['upper']}")

    if args.open:
        subprocess.run(["xdg-open", str(out / "index.html")], check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
