#!/usr/bin/env python3
"""
Review modular upper/lower/fx operator animation pairs.

Generates composited previews of modular body parts (upper + lower)
and FX overlays (upper body + FX effects).

Supports two naming conventions:
  Legacy: operator__body__modular__lower__run_01__e__5f__96.png
          operator__body__modular__upper__run_01__e__5f__96.png
  Modern: operator__modular_upper_body__unarmed__fast_windup_01__e__3f__96.png
          operator__modular_lower_body__unarmed__fast_windup_01__e__3f__96.png
          operator__modular_upper_fx__unarmed__fast_strike_01__e__3f__96.png

Example:
  # Legacy runtime modular
  python tools/review_modular_body_pairs.py \
    --root custodian/content/sprites/operator/runtime/modular \
    --out .ai/modular_body_review \
    --open

  # Fast attack suite with FX
  python tools/review_modular_body_pairs.py \
    --root custodian/content/sprites/operator/new_operator/modular/fast_attack \
    --out .ai/fast_attack_fx_review \
    --open

  # Exclude FX pairing (body pairs only)
  python tools/review_modular_body_pairs.py \
    --root path/to/dir --out .ai/review --no-fx

  # Include alpha-bbox fit analysis in the manifest and HTML
  python tools/review_modular_body_pairs.py \
    --root path/to/dir --out .ai/review --fit-debug
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

# Matches modern naming: __modular_upper_body__, __modular_lower_body__, __modular_upper_fx__
# Also matches legacy naming: __upper__, __lower__
PART_RE = re.compile(
    r"__("
    r"modular_upper_body|modular_lower_body|modular_upper_fx|"
    r"upper|lower"
    r")__"
)
# Map raw part name -> simplified tag
PART_TAG = {
    "modular_upper_body": "upper",
    "modular_lower_body": "lower",
    "modular_upper_fx": "fx",
    "upper": "upper",
    "lower": "lower",
}
META_RE = re.compile(r"__(?P<frames>\d+)f(?:__?(?P<frame_w>\d+))?\.png$", re.IGNORECASE)


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
        help="Fallback frame width if filename lacks __Nf__W metadata.",
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
    p.add_argument("--fx-offset-x", type=int, default=0)
    p.add_argument("--fx-offset-y", type=int, default=0)
    p.add_argument(
        "--no-fx",
        action="store_true",
        help="Skip FX pair generation (body upper+lower only).",
    )
    p.add_argument(
        "--fit-debug",
        action="store_true",
        help="Analyze alpha bounding boxes for each composed frame and write fit data to manifest/HTML.",
    )
    p.add_argument(
        "--fit-verbose",
        action="store_true",
        help="Print per-frame fit-debug details for every generated pair.",
    )
    p.add_argument(
        "--fit-gap-threshold",
        type=int,
        default=3,
        help="Flag pairings with vertical gap magnitude >= this many pixels. Default: 3.",
    )
    return p.parse_args()


def rel(path: Path, base: Path) -> str:
    try:
        return str(path.relative_to(base))
    except ValueError:
        return str(path)


def part_for_name(path: Path) -> Optional[str]:
    m = PART_RE.search(path.name)
    if not m:
        return None
    raw = m.group(1)
    return PART_TAG.get(raw, raw)


def key_for_name(path: Path) -> str:
    """Normalize filename to a grouping key by replacing the body-part tag with __PART__."""
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
        frame_w_str = m.group("frame_w")
        if frame_w_str is not None:
            frame_w = int(frame_w_str)
        elif fallback_frame_w is not None:
            frame_w = fallback_frame_w
            warnings.append(
                f"{path.name}: has frame count but no width metadata; "
                f"using fallback frame width {frame_w}."
            )
        else:
            frame_w = img.width // frames
            warnings.append(
                f"{path.name}: no width metadata and no --frame-width; "
                f"inferred {frame_w}px per frame from {img.width}px / {frames} frames."
            )
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
    if img.width < expected_w:
        inferred = img.width // frame_w
        warnings.append(
            f"{path.name}: width {img.width} < {frames} * {frame_w} ({expected_w}); "
            f"using inferred frames={inferred}."
        )
        frames = inferred

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


def alpha_bbox(img: Image.Image) -> Optional[Tuple[int, int, int, int]]:
    alpha = img.convert("RGBA").getchannel("A")
    return alpha.getbbox()


def _nontransparent_pixels(alpha: Image.Image, bbox: Tuple[int, int, int, int]) -> int:
    l, t, r, b = bbox
    crop = alpha.crop((l, t, r, b))
    transparent_pixels = crop.histogram()[0]
    return crop.width * crop.height - transparent_pixels


def bbox_stats(img: Image.Image) -> Dict:
    alpha = img.convert("RGBA").getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return {
            "bbox": None,
            "nontransparent_width": 0,
            "nontransparent_height": 0,
            "nontransparent_pixels": 0,
        }

    l, t, r, b = bbox
    return {
        "bbox": [l, t, r, b],
        "nontransparent_width": r - l,
        "nontransparent_height": b - t,
        "nontransparent_pixels": _nontransparent_pixels(alpha, bbox),
    }


def row_alpha_ranges(img: Image.Image, rows: List[int]) -> List[Dict]:
    rgba = img.convert("RGBA")
    out: List[Dict] = []
    for y in rows:
        if y < 0 or y >= rgba.height:
            continue
        xs = [x for x in range(rgba.width) if rgba.getpixel((x, y))[3] > 0]
        if xs:
            out.append(
                {
                    "y": y,
                    "x_min": min(xs),
                    "x_max": max(xs),
                    "width": max(xs) - min(xs) + 1,
                }
            )
        else:
            out.append({"y": y, "x_min": None, "x_max": None, "width": 0})
    return out


def edge_contact_debug(lower_frame: Image.Image, upper_frame: Image.Image) -> Dict:
    """Analyze how two stacked transparent frames meet."""
    upper_bbox = alpha_bbox(upper_frame)
    lower_bbox = alpha_bbox(lower_frame)

    upper_rows: List[int] = []
    lower_rows: List[int] = []
    if upper_bbox:
        _, _, _, upper_bottom = upper_bbox
        upper_rows = [upper_bottom - 3, upper_bottom - 2, upper_bottom - 1]
    if lower_bbox:
        _, lower_top, _, _ = lower_bbox
        lower_rows = [lower_top, lower_top + 1, lower_top + 2]

    vertical_gap = (lower_bbox[1] - upper_bbox[3]) if upper_bbox and lower_bbox else None
    h_delta = (
        ((upper_bbox[0] + upper_bbox[2]) / 2)
        - ((lower_bbox[0] + lower_bbox[2]) / 2)
        if upper_bbox and lower_bbox
        else None
    )

    return {
        "upper_bbox": bbox_stats(upper_frame),
        "lower_bbox": bbox_stats(lower_frame),
        "upper_lowest_3_rows": row_alpha_ranges(upper_frame, upper_rows),
        "lower_top_3_rows": row_alpha_ranges(lower_frame, lower_rows),
        "vertical_gap_px": vertical_gap,
        "horizontal_center_delta_px": h_delta,
    }


def print_fit_debug(record_id: str, frame_debug: List[Dict]) -> None:
    print()
    print(f"fit debug: {record_id}")
    for item in frame_debug:
        print(f"  frame {item['frame']}:")
        print(f"    upper bbox: {item['upper_bbox']}")
        print(f"    lower bbox: {item['lower_bbox']}")
        print(f"    vertical_gap_px: {item['vertical_gap_px']}")
        print(f"    horizontal_center_delta_px: {item['horizontal_center_delta_px']}")


def fit_debug_summary(record: Dict, threshold: int) -> Tuple[int, int]:
    fit_debug = record.get("fit_debug") or []
    flagged = [
        item
        for item in fit_debug
        if item.get("vertical_gap_px") is not None
        and abs(item["vertical_gap_px"]) >= threshold
    ]
    return len(flagged), len(fit_debug)


def composite_pair(
    lower_path: Path,
    upper_path: Path,
    args: argparse.Namespace,
) -> Tuple[Image.Image, List[Image.Image], Dict]:
    """Composite lower + upper body into a combined character sheet."""
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
    fit_debug_frames: Optional[List[Dict]] = [] if args.fit_debug else None

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

        if fit_debug_frames is not None:
            fit_debug_frames.append(
                {
                    "frame": i,
                    **edge_contact_debug(lower_frame, upper_frame),
                }
            )

    meta = {
        "lower": str(lower_path),
        "upper": str(upper_path),
        "frame_count": frame_count,
        "frame_width": canvas_w,
        "frame_height": canvas_h,
        "lower_source_frame_width": lower_fw,
        "upper_source_frame_width": upper_fw,
        "pair_type": "body",
        "warnings": warnings,
    }
    if fit_debug_frames is not None:
        meta["fit_debug"] = fit_debug_frames

    return combined_strip, combined_frames, meta


def composite_fx_pair(
    body_path: Path,
    fx_path: Path,
    args: argparse.Namespace,
) -> Tuple[Image.Image, List[Image.Image], Dict]:
    """Composite upper body + upper FX effects into an FX overlay sheet."""
    warnings: List[str] = []

    body_img = Image.open(body_path).convert("RGBA")
    fx_img = Image.open(fx_path).convert("RGBA")

    body_frames, body_fw, w1 = parse_sheet_meta(body_path, body_img, args.frame_width)
    fx_frames, fx_fw, w2 = parse_sheet_meta(fx_path, fx_img, args.frame_width)
    warnings.extend(w1)
    warnings.extend(w2)

    frame_count = min(body_frames, fx_frames)
    if body_frames != fx_frames:
        warnings.append(
            f"Frame count mismatch: body={body_frames}, fx={fx_frames}; using {frame_count}."
        )

    canvas_w = max(body_fw, fx_fw)
    canvas_h = max(body_img.height, fx_img.height)

    combined_strip = Image.new("RGBA", (canvas_w * frame_count, canvas_h), (0, 0, 0, 0))
    combined_frames: List[Image.Image] = []
    fit_debug_frames: Optional[List[Dict]] = [] if args.fit_debug else None

    for i in range(frame_count):
        frame = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

        body_frame = body_img.crop(
            (i * body_fw, 0, (i + 1) * body_fw, body_img.height)
        )
        fx_frame = fx_img.crop((i * fx_fw, 0, (i + 1) * fx_fw, fx_img.height))

        bx = ((canvas_w - body_fw) // 2) + args.upper_offset_x
        by = args.upper_offset_y
        fx_x = ((canvas_w - fx_fw) // 2) + args.fx_offset_x
        fx_y = args.fx_offset_y

        frame.alpha_composite(body_frame, (bx, by))
        frame.alpha_composite(fx_frame, (fx_x, fx_y))

        combined_strip.alpha_composite(frame, (i * canvas_w, 0))
        combined_frames.append(frame)

        if fit_debug_frames is not None:
            fit_debug_frames.append(
                {
                    "frame": i,
                    **edge_contact_debug(body_frame, fx_frame),
                }
            )

    meta = {
        "body": str(body_path),
        "fx": str(fx_path),
        "frame_count": frame_count,
        "frame_width": canvas_w,
        "frame_height": canvas_h,
        "body_source_frame_width": body_fw,
        "fx_source_frame_width": fx_fw,
        "pair_type": "fx",
        "warnings": warnings,
    }
    if fit_debug_frames is not None:
        meta["fit_debug"] = fit_debug_frames

    return combined_strip, combined_frames, meta


def make_review_sheet(
    lower_path: Path,
    upper_path: Path,
    combined_frames: List[Image.Image],
    args: argparse.Namespace,
) -> Image.Image:
    """Build a review sheet showing lower row, upper row, combined row."""
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


def make_fx_review_sheet(
    body_path: Path,
    fx_path: Path,
    combined_frames: List[Image.Image],
    args: argparse.Namespace,
) -> Image.Image:
    """Build a review sheet showing upper body row, FX row, body+FX combined row."""
    body_img = Image.open(body_path).convert("RGBA")
    fx_img = Image.open(fx_path).convert("RGBA")

    body_frames, body_fw, _ = parse_sheet_meta(body_path, body_img, args.frame_width)
    fx_frames, fx_fw, _ = parse_sheet_meta(fx_path, fx_img, args.frame_width)
    frame_count = min(body_frames, fx_frames, len(combined_frames))

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
        ("body (upper)", body_img, body_fw),
        ("fx", fx_img, fx_fw),
        ("body+fx", None, frame_w),
    ]

    for row_i, (label, source, fw) in enumerate(rows):
        y = pad + row_i * row_h
        draw.text((pad, y + 6), label, fill=(230, 230, 230, 255), font=font)

        for i in range(frame_count):
            if label == "body+fx":
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
    has_fx = any(r.get("pair_type") == "fx" for r in records)
    has_body = any(r.get("pair_type") != "fx" for r in records)

    body_rows = []
    fx_rows = []
    for rec in records:
        warnings = rec.get("warnings") or []
        warning_html = ""
        if warnings:
            warning_html = (
                "<ul>"
                + "".join(f"<li>{html.escape(w)}</li>" for w in warnings)
                + "</ul>"
            )

        fit_html = ""
        if rec.get("fit_debug"):
            threshold = int(rec.get("fit_gap_threshold", 3))
            flagged_count, total_count = fit_debug_summary(rec, threshold)
            lines = []
            for item in rec["fit_debug"]:
                gap = item.get("vertical_gap_px")
                hdelta = item.get("horizontal_center_delta_px")
                flag = " *" if gap is not None and abs(gap) >= threshold else ""
                hdelta_text = f"{hdelta:+.0f}px" if hdelta is not None else "None"
                lines.append(
                    f"frame {item['frame']}: gap={gap}px h-center={hdelta_text} "
                    f"upper={item['upper_bbox']['nontransparent_width']}x{item['upper_bbox']['nontransparent_height']} "
                    f"lower={item['lower_bbox']['nontransparent_width']}x{item['lower_bbox']['nontransparent_height']}{flag}"
                )

            summary_style = " style=\"color:#ff8a8a\"" if flagged_count else ""
            fit_html = (
                "<div class=\"fit-debug\">"
                "<h3>Fit Analysis</h3>"
                f"<p{summary_style}>{flagged_count}/{total_count} frames exceed gap threshold "
                f"(+/-{threshold}px)</p>"
                "<pre>"
                + "\n".join(html.escape(line) for line in lines)
                + "</pre></div>"
            )

        is_fx = rec.get("pair_type") == "fx"
        if is_fx:
            sources = (
                f"<p><b>Body (upper):</b> {html.escape(rec.get('body', ''))}</p>\n"
                f"<p><b>FX:</b> {html.escape(rec.get('fx', ''))}</p>"
            )
        else:
            sources = (
                f"<p><b>Lower:</b> {html.escape(rec.get('lower', ''))}</p>\n"
                f"<p><b>Upper:</b> {html.escape(rec.get('upper', ''))}</p>"
            )

        card = f"""
        <section class="card{' fx-card' if is_fx else ''}">
          <h2>{'🎯 ' if is_fx else ''}{html.escape(rec["id"])}</h2>
          {sources}
          <p><b>Frames:</b> {rec["frame_count"]} &nbsp; <b>Frame:</b> {rec["frame_width"]}×{rec["frame_height"]}</p>
          {warning_html}
          {fit_html}
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
        """
        if is_fx:
            fx_rows.append(card)
        else:
            body_rows.append(card)

    sections = []
    if body_rows:
        sections.append(f"<h2>Body Pairs (upper+lower)</h2>\n{''.join(body_rows)}")
    if fx_rows:
        sections.append(f"<h2>FX Overlays (upper body + FX)</h2>\n{''.join(fx_rows)}")

    index_path.write_text(
        f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Modular body pair + FX review</title>
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
  .fx-card {{
    border-color: #6a4c9c;
    background: #1e1530;
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
  .fit-debug {{
    background: #101116;
    border: 1px solid #3a4050;
    border-radius: 8px;
    padding: 10px 12px;
    margin: 10px 0;
  }}
  .fit-debug h3 {{ font-size: 14px; margin-bottom: 6px; }}
  .fit-debug pre {{
    white-space: pre-wrap;
    font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    color: #d4d7e0;
    margin: 0;
  }}
</style>
</head>
<body>
<h1>Modular body pair + FX review</h1>
<p>Generated from: <code>{html.escape(str(root))}</code></p>
{''.join(sections)}
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
        # Skip known non-body files (wall tests, sheet compilations)
        if p.name.endswith("-sheet.png") or p.name.endswith("_ALTERNATE.png"):
            continue
        # Skip .uid metadata files that happen to match the glob
        if p.name.endswith(".uid"):
            continue
        part = part_for_name(p)
        if not part:
            continue
        key = key_for_name(p)
        buckets.setdefault(key, {"upper": [], "lower": [], "fx": []})[part].append(p)

    records: List[Dict] = []
    missing: List[str] = []
    used_pairs = set()

    # Phase 1: Body pair generation (upper + lower)
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

            base_name = lower_path.name
            for old, new in [("__modular_lower_body__", "__body_combined__"),
                              ("__lower__", "__combined__")]:
                base_name = base_name.replace(old, new)
            base_name = base_name.removesuffix(".png")
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
                "fit_gap_threshold": args.fit_gap_threshold,
            }
            if args.fit_verbose and rec.get("fit_debug"):
                print_fit_debug(rec["id"], rec["fit_debug"])
            records.append(rec)

    # Phase 2: FX overlay pairs (upper body + upper fx)
    if not args.no_fx:
        for key, parts in sorted(buckets.items()):
            uppers = parts.get("upper", [])
            fxs = parts.get("fx", [])

            if not uppers or not fxs:
                continue

            for fx_path in fxs:
                # Find the best-matching upper body by pair_score
                body_path = max(uppers, key=lambda u: pair_score(fx_path, u))
                fx_pair_key = (body_path, fx_path)
                if fx_pair_key in used_pairs:
                    continue
                used_pairs.add(fx_pair_key)

                base_name = fx_path.name
                for old, new in [("__modular_upper_fx__", "__body_plus_fx__"),
                                  ("__fx__", "__body_plus_fx__")]:
                    base_name = base_name.replace(old, new)
                base_name = base_name.removesuffix(".png")
                slug = safe_slug(base_name)
                if any(r["id"] == slug for r in records):
                    slug = f"{slug}_fx_{short_hash(str(fx_path))}"

                try:
                    combined_strip, combined_frames, meta = composite_fx_pair(
                        body_path, fx_path, args
                    )
                    review_sheet = make_fx_review_sheet(
                        body_path, fx_path, combined_frames, args
                    )
                except Exception as e:
                    print(
                        f"ERROR processing FX pair:\n  body={body_path}\n  fx={fx_path}\n  {e}",
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
                    "body": rel(body_path, root),
                    "fx": rel(fx_path, root),
                    "combined": rel(combined_path, out),
                    "review": rel(review_path, out),
                    "gif": rel(gif_path, out),
                    "review_rel": rel(review_path, out),
                    "gif_rel": rel(gif_path, out),
                    "fit_gap_threshold": args.fit_gap_threshold,
                }
                if args.fit_verbose and rec.get("fit_debug"):
                    print_fit_debug(rec["id"], rec["fit_debug"])
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
                "fit_debug": bool(args.fit_debug),
                "fit_gap_threshold": args.fit_gap_threshold,
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

    if args.fit_debug:
        bad_pairs = []
        for record in records:
            flagged_count, total_count = fit_debug_summary(
                record, args.fit_gap_threshold
            )
            if flagged_count:
                bad_pairs.append((record["id"], flagged_count, total_count))

        print()
        if bad_pairs:
            print(
                f"Fit-debug: {len(bad_pairs)}/{len(records)} pairings exceed "
                f"gap threshold (+/-{args.fit_gap_threshold}px):"
            )
            for record_id, flagged_count, total_count in sorted(bad_pairs)[:20]:
                print(f"  - {record_id}: {flagged_count}/{total_count} frames flagged")
            if len(bad_pairs) > 20:
                print(f"  ... and {len(bad_pairs) - 20} more")
        else:
            print(
                f"Fit-debug: all pairings within gap threshold "
                f"(+/-{args.fit_gap_threshold}px)"
            )

    if args.open:
        subprocess.run(["xdg-open", str(index_path)], check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
