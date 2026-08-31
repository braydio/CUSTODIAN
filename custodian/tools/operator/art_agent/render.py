from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops


def split_strip(
    strip_path: Path,
    *,
    frame_width: int,
    frame_height: int,
    frame_count: int,
    output_dir: Path,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    with Image.open(strip_path) as source_image:
        source = source_image.convert("RGBA")
        expected = (frame_width * frame_count, frame_height)
        if source.size != expected:
            raise ValueError(f"rendered strip size {source.size} != {expected}")
        for index in range(frame_count):
            frame = source.crop(
                (
                    index * frame_width,
                    0,
                    (index + 1) * frame_width,
                    frame_height,
                )
            )
            path = output_dir / f"{index + 1:03d}.png"
            frame.save(path)
            paths.append(path)
    return paths


def make_contact_sheet(
    frame_paths: list[Path],
    output: Path,
    *,
    columns: int = 3,
    padding: int = 8,
) -> None:
    if not frame_paths:
        raise ValueError("contact sheet requires at least one frame")
    images = [Image.open(path).convert("RGBA") for path in frame_paths]
    try:
        frame_width, frame_height = images[0].size
        if any(image.size != (frame_width, frame_height) for image in images):
            raise ValueError("contact sheet frames have different dimensions")
        rows = (len(images) + columns - 1) // columns
        canvas = Image.new(
            "RGBA",
            (
                columns * frame_width + (columns + 1) * padding,
                rows * frame_height + (rows + 1) * padding,
            ),
            (0, 0, 0, 0),
        )
        for index, image in enumerate(images):
            column = index % columns
            row = index // columns
            canvas.alpha_composite(
                image,
                (padding + column * (frame_width + padding),
                 padding + row * (frame_height + padding)),
            )
        output.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output)
    finally:
        for image in images:
            image.close()


def make_diff(before_path: Path, after_path: Path, output_path: Path) -> None:
    with Image.open(before_path) as before_image, Image.open(after_path) as after_image:
        before = before_image.convert("RGBA")
        after = after_image.convert("RGBA")
        if before.size != after.size:
            raise ValueError("diff images have different dimensions")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        ImageChops.difference(before, after).save(output_path)


def make_before_after(before_path: Path, after_path: Path, output_path: Path) -> None:
    with Image.open(before_path) as before_image, Image.open(after_path) as after_image:
        before = before_image.convert("RGBA")
        after = after_image.convert("RGBA")
        if before.size != after.size:
            raise ValueError("before/after images have different dimensions")
        canvas = Image.new("RGBA", (before.width, before.height * 2), (0, 0, 0, 0))
        canvas.alpha_composite(before, (0, 0))
        canvas.alpha_composite(after, (0, before.height))
        output_path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output_path)
