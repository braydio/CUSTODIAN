#!/usr/bin/env python3
"""Build a compact visual reference sheet from active CUSTODIAN art.

The default scan intentionally skips source/archive/pipeline folders and samples
runtime-facing tiles, walls, floors, and prop sheets from `custodian/content/`.
"""

from __future__ import annotations

import argparse
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


DEFAULT_ROOTS = (
    "content/tiles",
    "content/props/ruins",
    "content/sprites/environment/props",
)
DEFAULT_OUTPUT = "content/reference/active_art_samplesheet.png"
IMAGE_EXTENSIONS = {".png", ".webp"}
SKIP_PARTS = {
    ".godot",
    "_aseprite",
    "_pipeline",
    "__pycache__",
    "archive",
    "logs",
    "modulate",
    "normalized",
    "scenes",
    "scripts",
    "shaders",
    "source",
	"temp",
}
SKIP_NAME_FRAGMENTS = (
    ".mapping",
    "_preview",
    "preview_",
    ".preview",
    "output",
)
DEFAULT_TILE_SIZE = 32

@dataclass(frozen=True)
class Sample:
    source_path: Path
    label: str
    image: Image.Image


def _repo_content_root(script_path: Path) -> Path:
    return script_path.resolve().parents[2]


def _load_font(size: int) -> ImageFont.ImageFont:
    candidates = (
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf",
    )
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def _natural_sort_key(path: Path) -> list[object]:
    text = path.as_posix().lower()
    return [int(part) if part.isdigit() else part for part in re.split(r"(\d+)", text)]


def _path_is_active(path: Path) -> bool:
    lowered_name = path.name.lower()
    if any(fragment in lowered_name for fragment in SKIP_NAME_FRAGMENTS):
        return False
    return not any(part in SKIP_PARTS for part in path.parts)


def _iter_images(content_root: Path, roots: Iterable[str]) -> list[Path]:
    images: list[Path] = []
    for root_arg in roots:
        root = (content_root / root_arg).resolve()
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in IMAGE_EXTENSIONS:
                continue
            try:
                relative = path.relative_to(content_root)
            except ValueError:
                continue
            if _path_is_active(relative):
                images.append(path)
    return sorted(set(images), key=_natural_sort_key)


def _infer_cell_size(path: Path, image: Image.Image, fallback_tile_size: int) -> tuple[int, int]:
    name = path.stem.lower()

    frame_match = re.search(r"__(\d+)f__(\d+)(?:x(\d+))?$", name)
    if frame_match:
        frame_size = int(frame_match.group(2))
        frame_height = int(frame_match.group(3) or frame_size)
        if frame_size > 0 and image.width % frame_size == 0:
            return frame_size, min(frame_height, image.height)

    size_match = re.search(r"_(\d+)x(\d+)$", name)
    if size_match:
        return int(size_match.group(1)), int(size_match.group(2))

    square_match = re.search(r"_(\d+)$", name)
    if square_match:
        size = int(square_match.group(1))
        if size in {8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 128, 161}:
            return size, size

    if "portal_ring" in name and image.width % 161 == 0:
        return 161, min(98, image.height)

    if fallback_tile_size > 0 and image.width >= fallback_tile_size and image.height >= fallback_tile_size:
        return fallback_tile_size, fallback_tile_size

    return image.width, image.height


def _crop_has_pixels(crop: Image.Image) -> bool:
	if crop.mode != "RGBA":
		crop = crop.convert("RGBA")
	alpha = crop.getchannel("A")
	return alpha.getbbox() is not None


def _candidate_crops(path: Path, image: Image.Image, fallback_tile_size: int) -> list[Image.Image]:
    cell_w, cell_h = _infer_cell_size(path, image, fallback_tile_size)
    cell_w = max(1, min(cell_w, image.width))
    cell_h = max(1, min(cell_h, image.height))

    crops: list[Image.Image] = []
    columns = max(1, image.width // cell_w)
    rows = max(1, image.height // cell_h)

    for row in range(rows):
        for column in range(columns):
            left = column * cell_w
            top = row * cell_h
            crop = image.crop((left, top, min(left + cell_w, image.width), min(top + cell_h, image.height)))
            if _crop_has_pixels(crop):
                crops.append(crop)

    if crops:
        return crops

    return [image.copy()]


def _pick_samples(crops: list[Image.Image], count: int) -> list[Image.Image]:
    if len(crops) <= count:
        return crops

    if count <= 1:
        return [crops[len(crops) // 2]]

    selected: list[Image.Image] = []
    for index in range(count):
        source_index = round(index * (len(crops) - 1) / (count - 1))
        selected.append(crops[source_index])
    return selected


def _fit_sample(image: Image.Image, max_size: int) -> Image.Image:
    sample = image.convert("RGBA")
    sample.thumbnail((max_size, max_size), Image.Resampling.NEAREST)
    return sample


def _wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split("/")
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if current == "" else current + "/" + word
        if draw.textbbox((0, 0), candidate, font=font)[2] <= max_width:
            current = candidate
            continue
        if current:
            lines.append(current)
        current = word
    if current:
        lines.append(current)
    return lines[-3:] if len(lines) > 3 else lines


def _make_card(sample: Sample, card_size: tuple[int, int], swatch_size: int, font: ImageFont.ImageFont) -> Image.Image:
    card_w, card_h = card_size
    card = Image.new("RGBA", card_size, (22, 24, 23, 255))
    draw = ImageDraw.Draw(card)
    draw.rectangle((0, 0, card_w - 1, card_h - 1), outline=(72, 82, 72, 255))

    swatch = _fit_sample(sample.image, swatch_size)
    checker = _checkerboard((swatch_size, swatch_size))
    swatch_x = (card_w - swatch_size) // 2
    swatch_y = 8
    card.alpha_composite(checker, (swatch_x, swatch_y))
    card.alpha_composite(swatch, (swatch_x + (swatch_size - swatch.width) // 2, swatch_y + (swatch_size - swatch.height) // 2))

    lines = _wrap_text(draw, sample.label, font, card_w - 10)
    text_y = swatch_y + swatch_size + 6
    for line in lines:
        draw.text((5, text_y), line, fill=(214, 221, 202, 255), font=font)
        text_y += 11

    return card


def _checkerboard(size: tuple[int, int], cell: int = 8) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    colors = ((44, 47, 45, 255), (58, 63, 59, 255))
    for y in range(0, height, cell):
        for x in range(0, width, cell):
            color = colors[((x // cell) + (y // cell)) % 2]
            draw.rectangle((x, y, min(x + cell - 1, width - 1), min(y + cell - 1, height - 1)), fill=color)
    return image


def _build_samples(content_root: Path, image_paths: list[Path], samples_per_image: int, fallback_tile_size: int) -> list[Sample]:
    samples: list[Sample] = []
    for path in image_paths:
        try:
            with Image.open(path) as opened:
                image = opened.convert("RGBA")
        except OSError as exc:
            print(f"[skip] Could not open {path}: {exc}")
            continue

        crops = _candidate_crops(path, image, fallback_tile_size)
        selected = _pick_samples(crops, samples_per_image)
        relative = path.relative_to(content_root)
        for index, crop in enumerate(selected, start=1):
            label = relative.as_posix()
            if len(selected) > 1:
                label = f"{label} #{index}"
            samples.append(Sample(path, label, crop))
    return samples


def _compose_sheet(samples: list[Sample], output_path: Path, columns: int, card_width: int, card_height: int, swatch_size: int) -> None:
    font = _load_font(9)
    title_font = _load_font(14)
    columns = max(1, columns)
    rows = max(1, math.ceil(len(samples) / columns))
    gutter = 8
    margin = 12
    title_height = 34
    width = margin * 2 + columns * card_width + (columns - 1) * gutter
    height = margin * 2 + title_height + rows * card_height + (rows - 1) * gutter

    sheet = Image.new("RGBA", (width, height), (13, 15, 14, 255))
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, margin), f"CUSTODIAN active art samples ({len(samples)} samples)", fill=(235, 238, 218, 255), font=title_font)

    for index, sample in enumerate(samples):
        row = index // columns
        column = index % columns
        x = margin + column * (card_width + gutter)
        y = margin + title_height + row * (card_height + gutter)
        sheet.alpha_composite(_make_card(sample, (card_width, card_height), swatch_size, font), (x, y))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGBA").save(output_path)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", action="append", dest="roots", help="Content-relative root to scan. Can be repeated.")
    parser.add_argument("--output", default=DEFAULT_OUTPUT, help="Content-relative or absolute PNG output path.")
    parser.add_argument("--samples-per-image", type=int, default=2, help="Number of samples to take from each image.")
    parser.add_argument("--tile-size", type=int, default=DEFAULT_TILE_SIZE, help="Fallback cell size for sheet sampling.")
    parser.add_argument("--columns", type=int, default=6, help="Number of sample cards per row.")
    parser.add_argument("--card-width", type=int, default=170, help="Sample card width in pixels.")
    parser.add_argument("--card-height", type=int, default=132, help="Sample card height in pixels.")
    parser.add_argument("--swatch-size", type=int, default=72, help="Maximum displayed swatch size in each card.")
    parser.add_argument("--list-only", action="store_true", help="Only print images that would be sampled.")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    content_root = _repo_content_root(Path(__file__))
    roots = tuple(args.roots or DEFAULT_ROOTS)
    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = content_root / output_path

    image_paths = _iter_images(content_root, roots)
    if args.list_only:
        for path in image_paths:
            print(path.relative_to(content_root).as_posix())
        print(f"Found {len(image_paths)} image(s).")
        return 0

    samples = _build_samples(
        content_root=content_root,
        image_paths=image_paths,
        samples_per_image=max(1, args.samples_per_image),
        fallback_tile_size=max(1, args.tile_size),
    )
    if not samples:
        print("No samples found.")
        return 1

    _compose_sheet(
        samples=samples,
        output_path=output_path,
        columns=args.columns,
        card_width=args.card_width,
        card_height=args.card_height,
        swatch_size=args.swatch_size,
    )
    print(f"Wrote {len(samples)} samples from {len(image_paths)} image(s) to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
