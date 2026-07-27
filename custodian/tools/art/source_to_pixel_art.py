#!/usr/bin/env python3
"""Create and interactively choose among three pixel-art conversions.

Updated behavior:
- Auto-trims transparent border from the source
- Auto-fits the art into a recommended 768x768 source canvas by default
- Preserves aspect ratio and centers the art
- Removes partial alpha by converting alpha to binary (0 or 255 only)
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageEnhance, ImageFont
except ImportError as exc:
    raise SystemExit(
        "Missing dependency: Pillow. Install it with: python3 -m pip install Pillow"
    ) from exc


METHODS = {
    "1": ("crisp", "Nearest-neighbor reduction; best for enlarged pixel art."),
    "2": ("balanced", "Box/area reduction plus a controlled palette."),
    "3": (
        "clustered",
        "Area reduction, stronger values, fewer colors, and noise cleanup.",
    ),
}
METHOD_ALIASES = {
    "1": "1",
    "crisp": "1",
    "nearest": "1",
    "2": "2",
    "balanced": "2",
    "area": "2",
    "3": "3",
    "clustered": "3",
    "bold": "3",
}


def parse_size(value: str) -> tuple[int, int]:
    normalized = value.lower().replace("×", "x")
    parts = normalized.split("x", 1)
    try:
        width = int(parts[0])
        height = int(parts[1]) if len(parts) == 2 else width
    except (TypeError, ValueError) as exc:
        raise argparse.ArgumentTypeError("size must be N or WIDTHxHEIGHT") from exc
    if width < 1 or height < 1:
        raise argparse.ArgumentTypeError("size dimensions must be positive")
    return width, height


def clamp_alpha_binary(image: Image.Image, cutoff: int = 16) -> Image.Image:
    """Force alpha to binary transparency only: 0 or 255."""
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda value: 255 if value >= cutoff else 0)
    rgba.putalpha(alpha)
    return rgba


def trim_transparent_border(image: Image.Image, cutoff: int = 16) -> Image.Image:
    """Crop away empty transparent border based on alpha cutoff."""
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda value: 255 if value >= cutoff else 0)
    bbox = alpha.getbbox()
    if bbox is None:
        return rgba.copy()
    return rgba.crop(bbox)


def contain_fit_on_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
    margin: int = 32,
    alpha_cutoff: int = 16,
) -> Image.Image:
    """Fit image proportionally inside a transparent canvas."""
    image = trim_transparent_border(image, cutoff=alpha_cutoff)

    canvas_w, canvas_h = canvas_size
    usable_w = max(1, canvas_w - margin * 2)
    usable_h = max(1, canvas_h - margin * 2)

    scale = min(usable_w / image.width, usable_h / image.height)
    new_w = max(1, int(round(image.width * scale)))
    new_h = max(1, int(round(image.height * scale)))

    resized = image.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    offset_x = (canvas_w - new_w) // 2
    offset_y = (canvas_h - new_h) // 2
    canvas.alpha_composite(resized, (offset_x, offset_y))

    return clamp_alpha_binary(canvas, cutoff=alpha_cutoff)


def quantize_rgba(image: Image.Image, colors: int, alpha_cutoff: int) -> Image.Image:
    """Quantize RGB without dithering while preserving binary alpha."""
    rgba = clamp_alpha_binary(image.convert("RGBA"), cutoff=alpha_cutoff)
    alpha = rgba.getchannel("A")

    rgb = Image.new("RGB", rgba.size, (0, 0, 0))
    rgb.paste(rgba.convert("RGB"), mask=alpha)

    quantized = rgb.quantize(
        colors=max(2, min(colors, 256)),
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")

    result = quantized.convert("RGBA")
    result.putalpha(alpha)
    return clamp_alpha_binary(result, cutoff=alpha_cutoff)


def clean_isolated_colors(image: Image.Image) -> Image.Image:
    """Replace only strong 3x3 color outliers, preserving edges and alpha."""
    source = image.convert("RGBA")
    pixels = source.load()
    output = source.copy()
    out_pixels = output.load()
    width, height = source.size

    for y in range(height):
        for x in range(width):
            center = pixels[x, y]
            if center[3] == 0:
                continue

            counts: dict[tuple[int, int, int, int], int] = {}
            for neighbor_y in range(max(0, y - 1), min(height, y + 2)):
                for neighbor_x in range(max(0, x - 1), min(width, x + 2)):
                    color = pixels[neighbor_x, neighbor_y]
                    if color[3] == 0:
                        continue
                    counts[color] = counts.get(color, 0) + 1

            replacement, count = max(counts.items(), key=lambda item: item[1])
            if counts.get(center, 0) == 1 and count >= 4:
                out_pixels[x, y] = replacement

    return output


def make_candidates(
    source: Image.Image,
    target_size: tuple[int, int],
    colors: int,
    alpha_cutoff: int,
) -> dict[str, Image.Image]:
    rgba = source.convert("RGBA")

    crisp = rgba.resize(target_size, Image.Resampling.NEAREST)
    crisp = clamp_alpha_binary(crisp, cutoff=alpha_cutoff)

    balanced_reduced = rgba.resize(target_size, Image.Resampling.BOX)
    balanced = quantize_rgba(balanced_reduced, colors, alpha_cutoff=alpha_cutoff)

    clustered_reduced = rgba.resize(target_size, Image.Resampling.BOX)
    clustered_reduced = ImageEnhance.Contrast(clustered_reduced).enhance(1.12)
    clustered_reduced = ImageEnhance.Color(clustered_reduced).enhance(1.08)
    clustered = quantize_rgba(
        clustered_reduced,
        max(8, colors * 2 // 3),
        alpha_cutoff=alpha_cutoff,
    )
    clustered = clean_isolated_colors(clustered)
    clustered = clamp_alpha_binary(clustered, cutoff=alpha_cutoff)

    return {"1": crisp, "2": balanced, "3": clustered}


def checkerboard(size: tuple[int, int], cell: int = 12) -> Image.Image:
    board = Image.new("RGBA", size, (56, 58, 64, 255))
    draw = ImageDraw.Draw(board)
    light = (78, 81, 89, 255)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=light)
    return board


def build_comparison(candidates: dict[str, Image.Image], destination: Path) -> None:
    preview_scale = max(1, min(8, 512 // max(candidates["1"].size)))
    preview_size = tuple(
        dimension * preview_scale for dimension in candidates["1"].size
    )
    gap = 24
    label_height = 54
    panel_width = preview_size[0]
    canvas = Image.new(
        "RGBA",
        (gap * 4 + panel_width * 3, gap * 2 + label_height + preview_size[1]),
        (28, 30, 35, 255),
    )
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()

    for index, key in enumerate(("1", "2", "3")):
        name, description = METHODS[key]
        x = gap + index * (panel_width + gap)
        draw.text((x, gap), f"{key}. {name.upper()}", fill=(245, 246, 250), font=font)
        draw.text(
            (x, gap + 20), description.split(";")[0], fill=(184, 188, 198), font=font
        )
        preview = candidates[key].resize(preview_size, Image.Resampling.NEAREST)
        background = checkerboard(preview_size)
        background.alpha_composite(preview)
        canvas.alpha_composite(background, (x, gap + label_height))

    canvas.convert("RGB").save(destination)


def show_comparison(path: Path) -> str:
    if sys.stdout.isatty() and shutil.which("chafa"):
        subprocess.run(
            ["chafa", "--format=symbols", "--size=120x40", str(path)],
            check=False,
        )
        return "terminal preview"
    if os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"):
        if shutil.which("xdg-open"):
            subprocess.Popen(
                ["xdg-open", str(path)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return "desktop viewer"
    return "file only"


def choose_interactively() -> str:
    print("\nChoose the output:")
    for key, (name, description) in METHODS.items():
        print(f"  {key}) {name:<9} {description}")
    while True:
        try:
            answer = input("Selection [1-3, q to cancel]: ").strip().lower()
        except EOFError as exc:
            raise SystemExit(
                "Interactive selection needs a terminal; pass --choose 1, 2, or 3."
            ) from exc
        if answer in METHOD_ALIASES:
            return METHOD_ALIASES[answer]
        if answer in {"q", "quit", "cancel"}:
            raise SystemExit("Cancelled; no output was written.")
        print("Enter 1, 2, or 3.")


def default_output(source: Path, size: tuple[int, int]) -> Path:
    return source.with_name(f"{source.stem}_pixel_{size[0]}x{size[1]}.png")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Generate crisp, balanced, and clustered pixel-art candidates, "
            "auto-fit the source into a recommended canvas, preview them, "
            "and choose the final PNG."
        )
    )
    parser.add_argument(
        "source", type=Path, help="Source PNG or other Pillow-readable image"
    )
    parser.add_argument("output", type=Path, nargs="?", help="Final PNG path")
    parser.add_argument(
        "--size",
        type=parse_size,
        default=(96, 96),
        metavar="N|WxH",
        help="Final dimensions (default: 96x96)",
    )
    parser.add_argument(
        "--source-canvas",
        type=parse_size,
        default=(768, 768),
        metavar="N|WxH",
        help="Prepared source canvas before downscaling (default: 768x768)",
    )
    parser.add_argument(
        "--margin",
        type=int,
        default=32,
        help="Transparent padding inside the prepared source canvas (default: 32)",
    )
    parser.add_argument(
        "--colors",
        type=int,
        default=24,
        help="Balanced-method palette size (default: 24)",
    )
    parser.add_argument(
        "--alpha-cutoff",
        type=int,
        default=16,
        help="Alpha threshold. Pixels below become transparent; at/above become opaque (default: 16)",
    )
    parser.add_argument(
        "--choose",
        choices=sorted(METHOD_ALIASES),
        help="Skip the prompt and select a method by number or name",
    )
    parser.add_argument(
        "--keep-candidates",
        type=Path,
        metavar="DIR",
        help="Keep all three PNGs, comparison.png, and prepared_source.png in this directory",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace an existing output file",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    source_path = args.source.expanduser().resolve()
    if not source_path.is_file():
        raise SystemExit(f"Source image not found: {source_path}")
    if not 2 <= args.colors <= 256:
        raise SystemExit("--colors must be between 2 and 256")
    if not 0 <= args.alpha_cutoff <= 255:
        raise SystemExit("--alpha-cutoff must be between 0 and 255")
    if args.margin < 0:
        raise SystemExit("--margin must be 0 or greater")

    output_path = (
        args.output.expanduser().resolve()
        if args.output
        else default_output(source_path, args.size)
    )
    if output_path.exists() and not args.force:
        raise SystemExit(
            f"Output already exists: {output_path}\nPass --force to replace it."
        )
    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        with Image.open(source_path) as opened:
            source = opened.convert("RGBA")
    except (OSError, ValueError) as exc:
        raise SystemExit(f"Could not read source image: {exc}") from exc

    prepared_source = contain_fit_on_canvas(
        source,
        canvas_size=args.source_canvas,
        margin=args.margin,
        alpha_cutoff=args.alpha_cutoff,
    )

    candidates = make_candidates(
        prepared_source,
        target_size=args.size,
        colors=args.colors,
        alpha_cutoff=args.alpha_cutoff,
    )

    temporary = None
    if args.keep_candidates:
        candidate_dir = args.keep_candidates.expanduser().resolve()
        candidate_dir.mkdir(parents=True, exist_ok=True)
    else:
        temporary = tempfile.TemporaryDirectory(prefix="custodian-pixelart-")
        candidate_dir = Path(temporary.name)

    prepared_source.save(candidate_dir / "prepared_source.png")
    for key, image in candidates.items():
        name = METHODS[key][0]
        image.save(candidate_dir / f"{key}_{name}.png")
    comparison_path = candidate_dir / "comparison.png"
    build_comparison(candidates, comparison_path)

    chosen = METHOD_ALIASES[args.choose] if args.choose else None
    if chosen is None:
        if not sys.stdin.isatty():
            raise SystemExit(
                "Interactive selection needs a terminal; pass --choose 1, 2, or 3."
            )
        display_mode = show_comparison(comparison_path)
        print(f"Prepared source: {candidate_dir / 'prepared_source.png'}")
        print(f"Comparison: {comparison_path} ({display_mode})")
        chosen = choose_interactively()

    selected_name = METHODS[chosen][0]
    candidates[chosen].save(output_path, format="PNG")
    print(f"Wrote {selected_name} conversion: {output_path}")
    if args.keep_candidates:
        print(f"Kept candidates: {candidate_dir}")

    if temporary is not None:
        temporary.cleanup()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
