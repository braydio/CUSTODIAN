#!/usr/bin/env python3
"""
Review modular upper/lower operator animation pairs.

Example:
  python tools/review_modular_body_pairs.py \
    --root custodian/content/sprites/operator/runtime/modular \
    --out .ai/modular_body_review \
    --open

Works with names like:
  operator__body__modular__lower__run_01__e__5f__96.png
  operator__body__modular__upper__run_01__e__5f__96.png
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from PIL import Image, ImageDraw, ImageFont

PART_RE = re.compile(r"__(upper|lower)__")
META_RE = re.compile(r"__(?P<frames>\d+)f__(?P<frame_w>\d+)\.png$", re.IGNORECASE)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--root", type=Path, required=True, help="Directory to scan recursively."
    )
    p.add_argument("--out", type=Path, default=Path(".ai/modular_body_review"))
    p.add_argument(
        "--scale", type=int, default=4, help="Preview scale for review sheets/GIFs."
    )
    p.add_argument("--duration-ms", type=int, default=120, help="GIF frame duration.")
    p.add_argument(
        "--frame-width",
        type=int,
        default=None,
        help="Fallback frame width if filename lacks __5f__96.",
    )
    p.add_argument(
        "--open", action="store_true", help="Open generated index.html with xdg-open."
    )
    p.add_argument(
        "--strict", action="store_true", help="Exit nonzero if missing pairs are found."
    )
    p.add_argument("--upper-offset-x", type=int, default=0)
    p.add_argument("--upper-offset-y", type=int, default=0)
    p.add_argument("--lower-offset-x", type=int, default=0)
    p.add_argument("--lower-offset-y", type=int, default=0)
    return p.parse_args()


def rel(path: Path, base: Path) -> str:
    try:
        return str(path.relative_to(base))
    except ValueError:
        return str(path)


def part_for_name(path: Path) -> Optional[str]:
    m = PART_RE.search(path.name)
    return m.group(1) if m else None


def key_for_name(path: Path) -> str:
    return PART_RE.sub("__PART__", path.name)


def short_hash(s: str) -> str:
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:8]


def safe_slug(s: str) -> str:
    s = re.sub(r"[^A-Za-z0-9_.-]+", "_", s)
    s = re.sub(r"_+", "_", s)
    return s.strip("_")


def parse_sheet_meta(
    path: Path, img: Image.Image, fallback_frame_w: Optional[int]
) -> Tuple[int, int, List[str]]:
    warnings: List[str] = []
    m = META_RE.search(path.name)

    if m:
        frames = int(m.group("frames"))
        frame_w = int(m.group("frame_w"))
    elif fallback_frame_w:
        frame_w = fallback_frame_w
        frames = img.width // frame_w
        warnings.append(
            f"{path.name}: no __Nf__W metadata; used fallback frame width {frame_w}."
        )
    else:
        raise ValueError(
            f"{path.name}: cannot infer frame count/frame width. Add --frame-width."
        )

    if frame_w <= 0 or frames <= 0:
        raise ValueError(
            f"{path.name}: invalid frame metadata frames={frames}, frame_w={frame_w}."
        )

    expected_w = frames * frame_w
    if img.width != expected_w:
        inferred = img.width // frame_w
        warnings.append(
            f"{path.name}: width {img.width} != {frames} * {frame_w} ({expected_w}); "
            f"using min declared/inferred frames."
        )
        frames = min(frames, inferred)

    return frames, frame_w, warnings


def pair_score(lower: Path, upper: Path) -> int:
    score = 0

    if lower.parent == upper.parent:
        score += 100

    lower_parts = list(lower.parts)
    upper_parts = list(upper.parts)

    if len(lower_parts) == len(upper_parts):
        diffs = sum(1 for a, b in zip(lower_parts, upper_parts) if a != b)
        score += max(0, 50 - diffs * 5)

    lower_parent_swapped = Path(
        *["upper" if p == "lower" else p for p in lower.parent.parts]
    )
    upper_parent_swapped = Path(
        *["lower" if p == "upper" else p for p in upper.parent.parts]
    )

    if lower_parent_swapped == upper.parent:
        score += 80
    if upper_parent_swapped == lower.parent:
        score += 80

    common = 0
    for a, b in zip(lower.parts, upper.parts):
        if a == b:
            common += 1
        else:
            break
    score += common

    return score


def build_checker(w: int, h: int, cell: int = 8) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    c1 = (38, 38, 42, 255)
    c2 = (70, 70, 76, 255)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            draw.rectangle(
                [x, y, x + cell - 1, y + cell - 1],
                fill=c1 if ((x // cell + y // cell) % 2 == 0) else c2,
            )
    return img


def alpha_on_checker(src: Image.Image, scale: int) -> Image.Image:
    src_scaled = src.resize(
        (src.width * scale, src.height * scale), Image.Resampling.NEAREST
    )
    bg = build_checker(src_scaled.width, src_scaled.height, max(4, scale * 2))
    bg.alpha_composite(src_scaled)
    return bg


def composite_pair(
    lower_path: Path,
    upper_path: Path,
    args: argparse.Namespace,
) -> Tuple[Image.Image, List[Image.Image], Dict]:
    warnings: List[str] = []

    lower = Image.open(lower_path).convert("RGBA")
    upper = Image.open(upper_path).convert("RGBA")

    lower_frames, lower_fw, w1 = parse_sheet_meta(lower_path, lower, args.frame_width)
    upper_frames, upper_fw, w2 = parse_sheet_meta(upper_path, upper, args.frame_width)
    warnings.extend(w1)
    warnings.extend(w2)

    frame_count = min(lower_frames, upper_frames)
    if lower_frames != upper_frames:
        warnings.append(
            f"Frame count mismatch: lower={lower_frames}, upper={upper_frames}; using {frame_count}."
        )

    canvas_w = max(lower_fw, upper_fw)
    canvas_h = max(lower.height, upper.height)

    combined_strip = Image.new("RGBA", (canvas_w * frame_count, canvas_h), (0, 0, 0, 0))
    combined_frames: List[Image.Image] = []

    for i in range(frame_count):
        frame = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

        lower_frame = lower.crop((i * lower_fw, 0, (i + 1) * lower_fw, lower.height))
        upper_frame = upper.crop((i * upper_fw, 0, (i + 1) * upper_fw, upper.height))

        lx = ((canvas_w - lower_fw) // 2) + args.lower_offset_x
        ly = args.lower_offset_y
        ux = ((canvas_w - upper_fw) // 2) + args.upper_offset_x
        uy = args.upper_offset_y

        frame.alpha_composite(lower_frame, (lx, ly))
        frame.alpha_composite(upper_frame, (ux, uy))

        combined_strip.alpha_composite(frame, (i * canvas_w, 0))
        combined_frames.append(frame)

    meta = {
        "lower": str(lower_path),
        "upper": str(upper_path),
        "frame_count": frame_count,
        "frame_width": canvas_w,
        "frame_height": canvas_h,
        "lower_source_frame_width": lower_fw,
        "upper_source_frame_width": upper_fw,
        "warnings": warnings,
    }

    return combined_strip, combined_frames, meta


def make_review_sheet(
    lower_path: Path,
    upper_path: Path,
    combined_frames: List[Image.Image],
    args: argparse.Namespace,
) -> Image.Image:
    lower = Image.open(lower_path).convert("RGBA")
    upper = Image.open(upper_path).convert("RGBA")

    lower_frames, lower_fw, _ = parse_sheet_meta(lower_path, lower, args.frame_width)
    upper_frames, upper_fw, _ = parse_sheet_meta(upper_path, upper, args.frame_width)
    frame_count = min(lower_frames, upper_frames, len(combined_frames))

    scale = args.scale
    label_w = 92
    pad = 8
    gap = 6
    frame_w = combined_frames[0].width
    frame_h = combined_frames[0].height

    cell_w = frame_w * scale + gap
    row_h = frame_h * scale + gap
    w = label_w + pad + frame_count * cell_w + pad
    h = pad + 3 * row_h + pad

    sheet = Image.new("RGBA", (w, h), (18, 18, 22, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    rows = [
        ("lower", lower, lower_fw),
        ("upper", upper, upper_fw),
        ("combined", None, frame_w),
    ]

    for row_i, (label, source, fw) in enumerate(rows):
        y = pad + row_i * row_h
        draw.text((pad, y + 6), label, fill=(230, 230, 230, 255), font=font)

        for i in range(frame_count):
            if label == "combined":
                frame = combined_frames[i]
            else:
                frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
                crop = source.crop((i * fw, 0, (i + 1) * fw, source.height))
                xoff = (frame_w - fw) // 2
                frame.alpha_composite(crop, (xoff, 0))

            preview = alpha_on_checker(frame, scale)
            x = label_w + pad + i * cell_w
            sheet.alpha_composite(preview, (x, y))
            draw.rectangle(
                [x, y, x + preview.width - 1, y + preview.height - 1],
                outline=(150, 150, 150, 255),
                width=1,
            )
            draw.text((x + 3, y + 3), str(i + 1), fill=(255, 255, 255, 255), font=font)

    return sheet


def make_gif(
    frames: List[Image.Image], out_path: Path, args: argparse.Namespace
) -> None:
    gif_frames = [
        alpha_on_checker(f, args.scale).convert("P", palette=Image.Palette.ADAPTIVE)
        for f in frames
    ]
    gif_frames[0].save(
        out_path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=args.duration_ms,
        loop=0,
        optimize=False,
        disposal=2,
    )


def write_html(index_path: Path, records: List[Dict], root: Path) -> None:
    rows = []
    for rec in records:
        warnings = rec.get("warnings") or []
        warning_html = ""
        if warnings:
            warning_html = (
                "<ul>"
                + "".join(f"<li>{html.escape(w)}</li>" for w in warnings)
                + "</ul>"
            )

        rows.append(f"""
        <section class="card">
          <h2>{html.escape(rec["id"])}</h2>
          <p><b>Lower:</b> {html.escape(rec["lower"])}</p>
          <p><b>Upper:</b> {html.escape(rec["upper"])}</p>
          <p><b>Frames:</b> {rec["frame_count"]} &nbsp; <b>Frame:</b> {rec["frame_width"]}×{rec["frame_height"]}</p>
          {warning_html}
          <div class="media">
            <div>
              <h3>Animated preview</h3>
              <img src="{html.escape(rec["gif_rel"])}" />
            </div>
            <div>
              <h3>Review sheet</h3>
              <img src="{html.escape(rec["review_rel"])}" />
            </div>
          </div>
        </section>
        """)

    index_path.write_text(
        f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Modular body pair review</title>
<style>
  body {{
    background: #111216;
    color: #e8e8e8;
    font-family: system-ui, sans-serif;
    margin: 24px;
  }}
  .card {{
    border: 1px solid #333844;
    border-radius: 12px;
    padding: 16px;
    margin-bottom: 24px;
    background: #1a1c22;
  }}
  img {{
    image-rendering: pixelated;
    max-width: 100%;
    border: 1px solid #444;
    background: #222;
  }}
  .media {{
    display: grid;
    grid-template-columns: minmax(180px, 320px) 1fr;
    gap: 18px;
    align-items: start;
  }}
  h1, h2, h3 {{ margin-top: 0; }}
  p {{ margin: 4px 0; }}
  li {{ color: #ffcf78; }}
</style>
</head>
<body>
<h1>Modular upper/lower body review</h1>
<p>Generated from: <code>{html.escape(str(root))}</code></p>
{''.join(rows)}
</body>
</html>
""",
        encoding="utf-8",
    )


def main() -> int:
    args = parse_args()

    root = args.root.expanduser().resolve()
    out = args.out.expanduser().resolve()

    if not root.exists():
        print(f"ERROR: root does not exist: {root}", file=sys.stderr)
        return 2

    combined_dir = out / "combined"
    review_dir = out / "review"
    gif_dir = out / "gif"
    for d in [combined_dir, review_dir, gif_dir]:
        d.mkdir(parents=True, exist_ok=True)

    buckets: Dict[str, Dict[str, List[Path]]] = {}

    for p in sorted(root.rglob("*.png")):
        if p.name.endswith(".import"):
            continue
        part = part_for_name(p)
        if not part:
            continue
        key = key_for_name(p)
        buckets.setdefault(key, {"upper": [], "lower": []})[part].append(p)

    records: List[Dict] = []
    missing: List[str] = []
    used_pairs = set()

    for key, parts in sorted(buckets.items()):
        lowers = parts.get("lower", [])
        uppers = parts.get("upper", [])

        if not lowers or not uppers:
            missing.append(f"{key}: lower={len(lowers)} upper={len(uppers)}")
            continue

        for lower_path in lowers:
            upper_path = max(uppers, key=lambda u: pair_score(lower_path, u))
            pair_key = (lower_path, upper_path)
            if pair_key in used_pairs:
                continue
            used_pairs.add(pair_key)

            base_name = lower_path.name.replace(
                "__lower__", "__combined__"
            ).removesuffix(".png")
            slug = safe_slug(base_name)
            if any(r["id"] == slug for r in records):
                slug = f"{slug}_{short_hash(str(lower_path))}"

            try:
                combined_strip, combined_frames, meta = composite_pair(
                    lower_path, upper_path, args
                )
                review_sheet = make_review_sheet(
                    lower_path, upper_path, combined_frames, args
                )
            except Exception as e:
                print(
                    f"ERROR processing pair:\n  lower={lower_path}\n  upper={upper_path}\n  {e}",
                    file=sys.stderr,
                )
                continue

            combined_path = combined_dir / f"{slug}.png"
            review_path = review_dir / f"{slug}_review.png"
            gif_path = gif_dir / f"{slug}.gif"

            combined_strip.save(combined_path)
            review_sheet.save(review_path)
            make_gif(combined_frames, gif_path, args)

            rec = {
                "id": slug,
                **meta,
                "lower": rel(lower_path, root),
                "upper": rel(upper_path, root),
                "combined": rel(combined_path, out),
                "review": rel(review_path, out),
                "gif": rel(gif_path, out),
                "review_rel": rel(review_path, out),
                "gif_rel": rel(gif_path, out),
            }
            records.append(rec)

    manifest_path = out / "manifest.json"
    index_path = out / "index.html"

    manifest_path.write_text(
        json.dumps(
            {
                "schema": "custodian.modular_body_review.v1",
                "root": str(root),
                "output": str(out),
                "pair_count": len(records),
                "missing_pairs": missing,
                "records": records,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    write_html(index_path, records, root)

    print(f"wrote {len(records)} pair reviews")
    print(f"index:    {index_path}")
    print(f"manifest: {manifest_path}")

    if missing:
        print("\nmissing/incomplete pairs:")
        for m in missing:
            print(f"  - {m}")
        if args.strict:
            return 1

    if args.open:
        subprocess.run(["xdg-open", str(index_path)], check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
