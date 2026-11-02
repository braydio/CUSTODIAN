#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


IMAGE_EXT = ".png"
OUTPUT_PREFIX = "png_animation_audit_"


# =============================================================================
# Time
# =============================================================================

def now_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


# =============================================================================
# Sorting / file discovery
# =============================================================================

def natural_key(path: Path) -> list[Any]:
    return [
        int(part) if part.isdigit() else part.lower()
        for part in re.split(r"(\d+)", path.name)
    ]


def get_pngs(
    cwd: Path,
    pattern: str,
    recursive: bool,
) -> list[Path]:
    iterator = cwd.rglob(pattern) if recursive else cwd.glob(pattern)

    files = [
        path
        for path in iterator
        if (
            path.is_file()
            and path.suffix.lower() == IMAGE_EXT
            and not path.name.startswith(OUTPUT_PREFIX)
        )
    ]

    return sorted(files, key=natural_key)


# =============================================================================
# Fonts
# =============================================================================

def load_font(
    size: int = 14,
    bold: bool = False,
) -> ImageFont.ImageFont:

    candidates: list[str] = []

    if bold:
        candidates += [
            "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
        ]

    candidates += [
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
    ]

    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)

    return ImageFont.load_default()


def font_line_height(
    draw: ImageDraw.ImageDraw,
    font: ImageFont.ImageFont,
) -> int:

    bbox = draw.textbbox(
        (0, 0),
        "Ag",
        font=font,
    )

    return max(1, bbox[3] - bbox[1])


def text_width(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.ImageFont,
) -> int:

    bbox = draw.textbbox(
        (0, 0),
        text,
        font=font,
    )

    return bbox[2] - bbox[0]


# =============================================================================
# Checkerboard
# =============================================================================

def checkerboard(
    size: tuple[int, int],
    block: int = 8,
) -> Image.Image:

    width, height = size

    image = Image.new(
        "RGBA",
        size,
        (232, 232, 232, 255),
    )

    draw = ImageDraw.Draw(image)

    for y in range(0, height, block):
        for x in range(0, width, block):

            if ((x // block) + (y // block)) % 2 == 0:
                draw.rectangle(
                    (
                        x,
                        y,
                        min(x + block - 1, width - 1),
                        min(y + block - 1, height - 1),
                    ),
                    fill=(207, 207, 207, 255),
                )

    return image


# =============================================================================
# Pixel scaling
# =============================================================================

def integer_scaled_image(
    image: Image.Image,
    zoom: int,
) -> Image.Image:

    if zoom <= 1:
        return image.copy()

    return image.resize(
        (
            image.width * zoom,
            image.height * zoom,
        ),
        Image.Resampling.NEAREST,
    )


# =============================================================================
# Filename parsing
# =============================================================================

def parse_sprite_filename(
    path: Path,
) -> dict[str, Any]:
    """
    Parse canonical names like:

        enemy_grunt__body__melee__stagger_01__e__8f__96.png

    or:

        operator__modular_upper_body__melee_1h__chain_02__e__8f__156x96.png
    """

    stem = path.stem
    parts = stem.split("__")

    result: dict[str, Any] = {
        "owner": None,
        "layer": None,
        "group": None,
        "action": None,
        "direction": None,
        "frames": None,
        "frame_width": None,
        "frame_height": None,
    }

    if len(parts) >= 1:
        result["owner"] = parts[0]

    if len(parts) >= 2:
        result["layer"] = parts[1]

    if len(parts) >= 3:
        result["group"] = parts[2]

    # Canonical tail:
    #
    #   __direction__8f__96
    #
    # or:
    #
    #   __direction__8f__156x96
    #
    if len(parts) >= 6:

        direction = parts[-3]
        frames_token = parts[-2]
        size_token = parts[-1]

        result["direction"] = direction

        action_parts = parts[3:-3]

        if action_parts:
            result["action"] = "__".join(action_parts)

        frame_match = re.fullmatch(
            r"(\d+)f",
            frames_token,
        )

        if frame_match:
            result["frames"] = int(frame_match.group(1))

        size_match = re.fullmatch(
            r"(\d+)(?:x(\d+))?",
            size_token,
            flags=re.IGNORECASE,
        )

        if size_match:

            width = int(size_match.group(1))

            height = (
                int(size_match.group(2))
                if size_match.group(2)
                else width
            )

            result["frame_width"] = width
            result["frame_height"] = height

    return result


# =============================================================================
# Metadata
# =============================================================================

def format_bytes(size: int) -> str:

    if size < 1024:
        return f"{size} B"

    if size < 1024 * 1024:
        return f"{size / 1024:.1f} KiB"

    return f"{size / (1024 * 1024):.1f} MiB"


def get_validation(
    path: Path,
    image: Image.Image,
) -> tuple[bool, str]:

    parsed = parse_sprite_filename(path)

    frames = parsed["frames"]
    frame_width = parsed["frame_width"]
    frame_height = parsed["frame_height"]

    if (
        frames is None
        or frame_width is None
        or frame_height is None
    ):
        return True, "filename metadata not parseable"

    expected_width = frames * frame_width
    expected_height = frame_height

    if (
        image.width == expected_width
        and image.height == expected_height
    ):
        return True, "dimensions match filename"

    return (
        False,
        (
            f"DECLARATION MISMATCH: "
            f"expected {expected_width}×{expected_height}px, "
            f"actual {image.width}×{image.height}px"
        ),
    )


def build_metadata_line(
    path: Path,
    image: Image.Image,
) -> str:

    parsed = parse_sprite_filename(path)

    bits: list[str] = []

    frames = parsed["frames"]
    fw = parsed["frame_width"]
    fh = parsed["frame_height"]
    direction = parsed["direction"]

    if frames is not None:
        bits.append(f"{frames} frames")

    if fw is not None and fh is not None:

        if fw == fh:
            bits.append(f"{fw}px/frame")
        else:
            bits.append(f"{fw}×{fh}px/frame")

    if direction:
        bits.append(f"dir: {direction}")

    bits.append(
        f"sheet: {image.width}×{image.height}px"
    )

    try:
        bits.append(
            format_bytes(path.stat().st_size)
        )
    except OSError:
        pass

    return "  •  ".join(bits)


def image_metadata(
    path: Path,
    cwd: Path,
) -> dict[str, Any]:

    with Image.open(path) as raw:

        image = raw.convert("RGBA")

        alpha = image.getchannel("A")
        alpha_bbox = alpha.getbbox()

        nontransparent = (
            sum(
                1
                for pixel in alpha.getdata()
                if pixel > 0
            )
            if alpha_bbox
            else 0
        )

        valid, validation_message = get_validation(
            path,
            image,
        )

        return {
            "filename": path.name,
            "relative_path": path.relative_to(cwd).as_posix(),
            "size_px": list(image.size),
            "has_alpha": True,
            "nontransparent_pixel_count": nontransparent,
            "alpha_bbox_px": (
                list(alpha_bbox)
                if alpha_bbox
                else None
            ),
            "filename_dimensions_valid": valid,
            "validation": validation_message,
            "file_size_bytes": path.stat().st_size,
            "modified_at_utc": datetime.fromtimestamp(
                path.stat().st_mtime,
                timezone.utc,
            ).isoformat(timespec="seconds"),
        }


# =============================================================================
# Filename wrapping
# =============================================================================

def wrap_filename(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.ImageFont,
    max_width: int,
) -> list[str]:

    if text_width(draw, text, font) <= max_width:
        return [text]

    # Canonical asset names have useful "__" boundaries.
    parts = text.split("__")

    lines: list[str] = []
    current = ""

    for index, part in enumerate(parts):

        token = part

        if index < len(parts) - 1:
            token += "__"

        candidate = current + token

        if (
            current
            and text_width(
                draw,
                candidate,
                font,
            ) > max_width
        ):
            lines.append(current)
            current = token

        else:
            current = candidate

    if current:
        lines.append(current)

    # Hard wrap pathological individual chunks.
    final: list[str] = []

    for line in lines:

        if text_width(draw, line, font) <= max_width:
            final.append(line)
            continue

        chunk = ""

        for char in line:

            candidate = chunk + char

            if (
                chunk
                and text_width(
                    draw,
                    candidate,
                    font,
                ) > max_width
            ):
                final.append(chunk)
                chunk = char

            else:
                chunk = candidate

        if chunk:
            final.append(chunk)

    return final


# =============================================================================
# Color helpers
# =============================================================================

def page_colors(
    background: str,
) -> dict[str, tuple[int, int, int, int]]:

    if background == "light":
        return {
            "page": (238, 240, 243, 255),
            "row": (250, 250, 250, 255),
            "row_alt": (244, 246, 248, 255),
            "text": (18, 20, 24, 255),
            "meta": (76, 82, 90, 255),
            "border": (160, 165, 172, 255),
            "good": (45, 110, 65, 255),
            "bad": (180, 45, 45, 255),
        }

    if background == "transparent":
        return {
            "page": (0, 0, 0, 0),
            "row": (20, 22, 26, 235),
            "row_alt": (25, 28, 33, 235),
            "text": (245, 247, 249, 255),
            "meta": (177, 184, 194, 255),
            "border": (80, 86, 94, 230),
            "good": (110, 215, 135, 255),
            "bad": (255, 105, 105, 255),
        }

    # dark
    return {
        "page": (14, 16, 20, 255),
        "row": (22, 25, 30, 255),
        "row_alt": (27, 30, 36, 255),
        "text": (242, 245, 248, 255),
        "meta": (168, 177, 188, 255),
        "border": (72, 78, 87, 255),
        "good": (110, 215, 135, 255),
        "bad": (255, 105, 105, 255),
    }


# =============================================================================
# Build audit sheet
# =============================================================================

def build_animation_audit_sheet(
    files: list[Path],
    cwd: Path,
    zoom: int,
    label_width: int,
    row_padding: int,
    outer_padding: int,
    column_gap: int,
    page_bg: str,
    sprite_bg: str,
    sort_mode: str,
    show_validation: bool,
) -> Image.Image:

    if not files:
        raise SystemExit("No PNG files found.")

    records: list[dict[str, Any]] = []

    for path in files:

        with Image.open(path) as raw:
            image = raw.convert("RGBA")

        valid, validation_message = get_validation(
            path,
            image,
        )

        records.append(
            {
                "path": path,
                "image": image,
                "w": image.width,
                "h": image.height,
                "area": image.width * image.height,
                "valid": valid,
                "validation": validation_message,
            }
        )

    # -------------------------------------------------------------------------
    # Sorting
    # -------------------------------------------------------------------------

    if sort_mode == "size":

        records.sort(
            key=lambda record: (
                record["h"],
                record["w"],
                natural_key(record["path"]),
            )
        )

    elif sort_mode == "area":

        records.sort(
            key=lambda record: (
                record["area"],
                record["h"],
                record["w"],
                natural_key(record["path"]),
            )
        )

    else:

        records.sort(
            key=lambda record: natural_key(
                record["path"]
            )
        )

    # -------------------------------------------------------------------------
    # Fonts
    # -------------------------------------------------------------------------

    title_font = load_font(
        max(15, 14 * zoom),
        bold=True,
    )

    meta_font = load_font(
        max(12, 11 * zoom),
        bold=False,
    )

    validation_font = load_font(
        max(11, 10 * zoom),
        bold=True,
    )

    measure_image = Image.new(
        "RGBA",
        (1, 1),
        (0, 0, 0, 0),
    )

    measure_draw = ImageDraw.Draw(
        measure_image
    )

    title_line_h = (
        font_line_height(
            measure_draw,
            title_font,
        )
        + max(3, zoom)
    )

    meta_line_h = (
        font_line_height(
            measure_draw,
            meta_font,
        )
        + max(3, zoom)
    )

    validation_line_h = (
        font_line_height(
            measure_draw,
            validation_font,
        )
        + max(3, zoom)
    )

    # -------------------------------------------------------------------------
    # Determine sprite column width
    # -------------------------------------------------------------------------

    max_sprite_width = max(
        record["w"] * zoom
        for record in records
    )

    # -------------------------------------------------------------------------
    # Calculate variable row heights
    # -------------------------------------------------------------------------

    label_inner_width = label_width - 20

    for record in records:

        filename_lines = wrap_filename(
            measure_draw,
            record["path"].name,
            title_font,
            label_inner_width,
        )

        label_height = (
            len(filename_lines) * title_line_h
            + 8
            + meta_line_h
        )

        if (
            show_validation
            and not record["valid"]
        ):
            label_height += (
                6
                + validation_line_h
            )

        artwork_height = (
            record["h"] * zoom
        )

        record["filename_lines"] = filename_lines

        record["content_height"] = max(
            label_height,
            artwork_height,
        )

        record["row_height"] = (
            record["content_height"]
            + row_padding * 2
        )

    # -------------------------------------------------------------------------
    # Canvas dimensions
    # -------------------------------------------------------------------------

    sheet_width = (
        outer_padding
        + label_width
        + column_gap
        + max_sprite_width
        + outer_padding
    )

    sheet_height = (
        outer_padding * 2
        + sum(
            record["row_height"]
            for record in records
        )
        + max(
            0,
            len(records) - 1,
        )
    )

    colors = page_colors(
        page_bg
    )

    sheet = Image.new(
        "RGBA",
        (
            sheet_width,
            sheet_height,
        ),
        colors["page"],
    )

    draw = ImageDraw.Draw(
        sheet
    )

    # -------------------------------------------------------------------------
    # Draw
    # -------------------------------------------------------------------------

    y = outer_padding

    sprite_x = (
        outer_padding
        + label_width
        + column_gap
    )

    for index, record in enumerate(records):

        row_height = record["row_height"]

        row_fill = (
            colors["row"]
            if index % 2 == 0
            else colors["row_alt"]
        )

        draw.rectangle(
            (
                outer_padding,
                y,
                sheet_width - outer_padding - 1,
                y + row_height - 1,
            ),
            fill=row_fill,
        )

        # ---------------------------------------------------------------------
        # Filename panel
        # ---------------------------------------------------------------------

        text_x = outer_padding + 10
        text_y = y + row_padding

        for line in record["filename_lines"]:

            draw.text(
                (
                    text_x,
                    text_y,
                ),
                line,
                font=title_font,
                fill=colors["text"],
            )

            text_y += title_line_h

        text_y += 5

        metadata = build_metadata_line(
            record["path"],
            record["image"],
        )

        draw.text(
            (
                text_x,
                text_y,
            ),
            metadata,
            font=meta_font,
            fill=colors["meta"],
        )

        text_y += meta_line_h + 4

        if show_validation:

            if record["valid"]:

                validation_text = "✓ dimensions valid"
                validation_color = colors["good"]

            else:

                validation_text = (
                    "⚠ "
                    + record["validation"]
                )

                validation_color = colors["bad"]

            draw.text(
                (
                    text_x,
                    text_y,
                ),
                validation_text,
                font=validation_font,
                fill=validation_color,
            )

        # ---------------------------------------------------------------------
        # Sprite strip
        # ---------------------------------------------------------------------

        scaled = integer_scaled_image(
            record["image"],
            zoom,
        )

        art_y = (
            y
            + (
                row_height
                - scaled.height
            ) // 2
        )

        # Checkerboard is ONLY behind this actual sprite-sheet rectangle.
        if sprite_bg == "checker":

            check = checkerboard(
                (
                    scaled.width,
                    scaled.height,
                ),
                block=max(
                    4,
                    8 * zoom,
                ),
            )

            sheet.alpha_composite(
                check,
                (
                    sprite_x,
                    art_y,
                ),
            )

        elif sprite_bg == "dark":

            draw.rectangle(
                (
                    sprite_x,
                    art_y,
                    sprite_x
                    + scaled.width
                    - 1,
                    art_y
                    + scaled.height
                    - 1,
                ),
                fill=(
                    12,
                    14,
                    17,
                    255,
                ),
            )

        # If sprite_bg == transparent, nothing is painted here.

        sheet.alpha_composite(
            scaled,
            (
                sprite_x,
                art_y,
            ),
        )

        draw.rectangle(
            (
                sprite_x,
                art_y,
                sprite_x
                + scaled.width
                - 1,
                art_y
                + scaled.height
                - 1,
            ),
            outline=colors["border"],
            width=max(
                1,
                zoom,
            ),
        )

        # Row separator.
        y += row_height

        if index < len(records) - 1:

            draw.line(
                (
                    outer_padding,
                    y,
                    sheet_width - outer_padding,
                    y,
                ),
                fill=colors["border"],
                width=1,
            )

            y += 1

    return sheet


# =============================================================================
# Clipboard
# =============================================================================

def copy_image_to_clipboard(
    path: Path,
) -> bool:

    wl_copy = shutil.which(
        "wl-copy"
    )

    if wl_copy:

        with path.open("rb") as file:

            subprocess.run(
                [
                    wl_copy,
                    "--type",
                    "image/png",
                ],
                stdin=file,
                check=True,
            )

        return True

    xclip = shutil.which(
        "xclip"
    )

    if xclip:

        subprocess.run(
            [
                xclip,
                "-selection",
                "clipboard",
                "-target",
                "image/png",
                "-i",
                str(path),
            ],
            check=True,
        )

        return True

    return False


# =============================================================================
# JSON index snapshot
# =============================================================================

def write_index_snapshot(
    files: list[Path],
    cwd: Path,
    out_dir: Path,
) -> Path:

    data = {
        "schema": "png_animation_audit.index_snapshot.v1",
        "generated_at_utc": now_iso(),
        "cwd": str(cwd),
        "file_count": len(files),
        "files": [
            image_metadata(
                path,
                cwd,
            )
            for path in files
        ],
    }

    output = (
        out_dir
        / f"png_animation_index_{now_stamp()}.json"
    )

    output.write_text(
        json.dumps(
            data,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    return output


# =============================================================================
# CLI
# =============================================================================

def parse_args() -> argparse.Namespace:

    parser = argparse.ArgumentParser(
        description=(
            "Create a vertical pixel-art animation audit sheet. "
            "Each PNG gets one readable row with its filename and full strip."
        )
    )

    parser.add_argument(
        "--pattern",
        default="*.png",
        help="PNG glob pattern. Default: *.png",
    )

    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="Search directories recursively.",
    )

    parser.add_argument(
        "--zoom",
        type=int,
        choices=[
            1,
            2,
            3,
            4,
            5,
            6,
            8,
        ],
        default=1,
        help=(
            "Integer nearest-neighbor artwork zoom. "
            "Default: 1."
        ),
    )

    parser.add_argument(
        "--label-width",
        type=int,
        default=620,
        help=(
            "Width of filename/metadata column in pixels. "
            "Default: 620."
        ),
    )

    parser.add_argument(
        "--row-padding",
        type=int,
        default=14,
        help=(
            "Vertical padding inside each row. "
            "Default: 14."
        ),
    )

    parser.add_argument(
        "--outer-padding",
        type=int,
        default=16,
        help=(
            "Padding around the whole sheet. "
            "Default: 16."
        ),
    )

    parser.add_argument(
        "--column-gap",
        type=int,
        default=20,
        help=(
            "Gap between filename and artwork columns. "
            "Default: 20."
        ),
    )

    parser.add_argument(
        "--page-bg",
        choices=[
            "dark",
            "light",
            "transparent",
        ],
        default="dark",
        help=(
            "Background for the overall audit sheet. "
            "Default: dark."
        ),
    )

    parser.add_argument(
        "--sprite-bg",
        choices=[
            "checker",
            "transparent",
            "dark",
        ],
        default="checker",
        help=(
            "Background directly behind each sprite strip. "
            "Default: checker."
        ),
    )

    parser.add_argument(
        "--sort",
        choices=[
            "natural",
            "size",
            "area",
        ],
        default="natural",
        help=(
            "Sort order. Default: natural."
        ),
    )

    parser.add_argument(
        "--no-validation",
        action="store_true",
        help=(
            "Do not display filename-vs-sheet dimension validation."
        ),
    )

    parser.add_argument(
        "--no-clipboard",
        action="store_true",
        help=(
            "Do not copy the finished sheet to the clipboard."
        ),
    )

    parser.add_argument(
        "--save",
        nargs="?",
        const=".",
        default=None,
        help=(
            "Save to a directory. "
            "If supplied without a path, saves in the current directory."
        ),
    )

    parser.add_argument(
        "--out",
        default=None,
        help=(
            "Exact output PNG path. Overrides --save."
        ),
    )

    parser.add_argument(
        "--index-snapshot",
        action="store_true",
        help=(
            "Also generate a JSON metadata/index file."
        ),
    )

    return parser.parse_args()


# =============================================================================
# Main
# =============================================================================

def main() -> None:

    args = parse_args()

    cwd = Path.cwd()

    files = get_pngs(
        cwd,
        args.pattern,
        args.recursive,
    )

    if not files:

        raise SystemExit(
            f"No PNG files found in {cwd} "
            f"matching {args.pattern!r}"
        )

    artifact = build_animation_audit_sheet(
        files=files,
        cwd=cwd,
        zoom=args.zoom,
        label_width=args.label_width,
        row_padding=args.row_padding,
        outer_padding=args.outer_padding,
        column_gap=args.column_gap,
        page_bg=args.page_bg,
        sprite_bg=args.sprite_bg,
        sort_mode=args.sort,
        show_validation=not args.no_validation,
    )

    # -------------------------------------------------------------------------
    # Output path
    # -------------------------------------------------------------------------

    if args.out:

        artifact_path = Path(
            args.out
        ).expanduser()

        if not artifact_path.is_absolute():

            artifact_path = (
                cwd
                / artifact_path
            )

        artifact_path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

    elif args.save is not None:

        save_dir = Path(
            args.save
        ).expanduser()

        if not save_dir.is_absolute():

            save_dir = (
                cwd
                / save_dir
            )

        save_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        artifact_path = (
            save_dir
            / f"{OUTPUT_PREFIX}{now_stamp()}.png"
        )

    else:

        temp_dir = Path(
            tempfile.mkdtemp(
                prefix="png_animation_audit_"
            )
        )

        artifact_path = (
            temp_dir
            / f"{OUTPUT_PREFIX}{now_stamp()}.png"
        )

    artifact.save(
        artifact_path
    )

    # -------------------------------------------------------------------------
    # Console summary
    # -------------------------------------------------------------------------

    print()
    print("Animation Audit")
    print("===============")
    print(f"files:            {len(files)}")
    print(f"artifact:         {artifact_path}")
    print(f"zoom:             {args.zoom}x")
    print("resampling:       NEAREST ONLY")
    print(f"page background:  {args.page_bg}")
    print(f"sprite background:{args.sprite_bg}")

    # -------------------------------------------------------------------------
    # Validation summary
    # -------------------------------------------------------------------------

    mismatch_count = 0

    for path in files:

        with Image.open(path) as raw:
            image = raw.convert("RGBA")

        valid, message = get_validation(
            path,
            image,
        )

        if not valid:
            mismatch_count += 1
            print(
                f"WARNING: {path.name}: {message}"
            )

    print(
        f"dimension issues: {mismatch_count}"
    )

    # -------------------------------------------------------------------------
    # Clipboard
    # -------------------------------------------------------------------------

    if not args.no_clipboard:

        try:

            copied = copy_image_to_clipboard(
                artifact_path
            )

        except Exception as exc:

            copied = False

            print(
                f"clipboard: failed: {exc}"
            )

        else:

            if copied:

                print(
                    "clipboard: copied image"
                )

            else:

                print(
                    "clipboard: no supported image clipboard utility "
                    "(install wl-clipboard or xclip)"
                )

    # -------------------------------------------------------------------------
    # Index
    # -------------------------------------------------------------------------

    if args.index_snapshot:

        snapshot = write_index_snapshot(
            files,
            cwd,
            artifact_path.parent,
        )

        print(
            f"index snapshot:   {snapshot}"
        )


if __name__ == "__main__":
    main()
