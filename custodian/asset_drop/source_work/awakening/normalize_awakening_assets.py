#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
PREVIEW_ROOT = ROOT / "_normalized_ready"
BACKUP_ROOT = ROOT / "_normalize_backup"

ALPHA_CONTENT_THRESHOLD = 4
ALPHA_STRUCTURE_THRESHOLD = 128

# Small transparent safety border inside each final runtime canvas.
PADDING_FRACTION = 0.02

STATIC_ASSETS = [
    {
        "name": "Crèche recovery alcove / idle",
        "src": Path("creche_recovery_alcove.png"),
        "dst": Path("creche_recovery_alcove/idle.png"),
        "size": (192, 256),
        "anchor": "bottom",
    },
    {
        "name": "Dust Lung lift / idle",
        "src": Path("dust_lung_lift/idle.png"),
        "dst": Path("dust_lung_lift/idle.png"),
        "size": (192, 256),
        "anchor": "bottom",
    },
    {
        "name": "Gate of Dust / body idle sealed",
        "src": Path("gate_of_dust/body_idle_sealed.png"),
        "dst": Path("gate_of_dust/body_idle_sealed.png"),
        "size": (768, 512),
        "anchor": "center",
    },
    {
        "name": "Gate of Dust / west pylon",
        "src": Path("gate_of_dust/west_pylon.png"),
        "dst": Path("gate_of_dust/west_pylon.png"),
        "size": (256, 512),
        "anchor": "bottom",
    },
    {
        "name": "Gate of Dust / east pylon",
        "src": Path("gate_of_dust/east_pylon.png"),
        "dst": Path("gate_of_dust/east_pylon.png"),
        "size": (256, 512),
        "anchor": "bottom",
    },
    {
        "name": "Gate of Dust / sealed aperture",
        "src": Path("gate_of_dust/sealed_aperture.png"),
        "dst": Path("gate_of_dust/sealed_aperture.png"),
        "size": (512, 512),
        "anchor": "center",
    },
    {
        "name": "Gate of Dust / rest threshold",
        "src": Path("gate_of_dust/rest_threshold.png"),
        "dst": Path("gate_of_dust/rest_threshold.png"),
        "size": (128, 160),
        "anchor": "bottom",
    },
]

WAKE_SRC = Path("creche_recovery_alcove/wake.png")
WAKE_DST = Path("creche_recovery_alcove/wake.png")
WAKE_FRAMES = 8
WAKE_FRAME_SIZE = (192, 256)


def alpha_bbox(img: Image.Image, threshold: int) -> tuple[int, int, int, int] | None:
    alpha = img.getchannel("A")
    mask = alpha.point(lambda a: 255 if a >= threshold else 0)
    return mask.getbbox()


def validate_real_alpha(img: Image.Image, path: Path) -> None:
    if img.mode != "RGBA":
        raise RuntimeError(f"{path}: expected RGBA, got {img.mode}")

    lo, hi = img.getchannel("A").getextrema()

    if lo == 255:
        raise RuntimeError(
            f"{path}: RGBA file has no transparent pixels. "
            "Refusing to normalize an opaque/matted asset."
        )

    if hi == 0:
        raise RuntimeError(f"{path}: image is completely transparent.")


def load_rgba(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)

    img = Image.open(path).convert("RGBA")
    validate_real_alpha(img, path)
    return img


def premultiplied_lanczos(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    """
    Resize in premultiplied-alpha space.

    This prevents transparent RGB garbage around the edge of generated PNGs
    from bleeding dark/light fringes into the visible sprite.
    """
    if img.size == size:
        return img.copy()

    premul = img.convert("RGBa")

    out = premul.resize(
        size,
        Image.Resampling.LANCZOS,
        reducing_gap=3.0,
    )

    return out.convert("RGBA")


def calculate_padding(target: tuple[int, int]) -> int:
    return max(2, round(min(target) * PADDING_FRACTION))


def normalize_object(
    source: Image.Image,
    target: tuple[int, int],
    anchor: str,
) -> Image.Image:
    """
    Transparent-trim -> aspect-preserving scale -> deterministic placement.

    Never stretches the source.
    """
    bbox = alpha_bbox(source, ALPHA_CONTENT_THRESHOLD)
    if bbox is None:
        raise RuntimeError("No visible pixels found")

    cropped = source.crop(bbox)

    tw, th = target
    padding = calculate_padding(target)

    available_w = tw - padding * 2
    available_h = th - padding * 2

    scale = min(
        available_w / cropped.width,
        available_h / cropped.height,
    )

    nw = max(1, round(cropped.width * scale))
    nh = max(1, round(cropped.height * scale))

    resized = premultiplied_lanczos(cropped, (nw, nh))

    result = Image.new("RGBA", target, (0, 0, 0, 0))

    x = (tw - nw) // 2

    if anchor == "bottom":
        y = th - padding - nh
    elif anchor == "center":
        y = (th - nh) // 2
    else:
        raise ValueError(f"Unknown anchor: {anchor}")

    result.alpha_composite(resized, (x, y))
    return result


def split_requested_horizontal_frames(
    source: Image.Image, count: int
) -> list[Image.Image]:
    """
    The image generator produced an 8-frame left-to-right composition on a
    non-divisible 2172px-wide canvas.

    Do NOT assume equal integer source cells and do NOT reinterpret it as 4x2.

    We divide the source into eight deterministic fractional slots, then
    alpha-trim each slot independently.
    """
    w, h = source.size
    frames = []

    boundaries = [round(i * w / count) for i in range(count + 1)]

    for i in range(count):
        x0 = boundaries[i]
        x1 = boundaries[i + 1]

        slot = source.crop((x0, 0, x1, h))

        bbox = alpha_bbox(slot, ALPHA_CONTENT_THRESHOLD)
        if bbox is None:
            raise RuntimeError(
                f"Wake frame {i + 1}: no visible pixels in source slot " f"{x0}:{x1}"
            )

        frames.append(slot)

    return frames


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    # Fixed parameters for repeatable PNG output.
    img.save(
        path,
        format="PNG",
        optimize=False,
        compress_level=9,
    )


def checkerboard(size: tuple[int, int], cell: int = 12) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, (50, 50, 50))
    draw = ImageDraw.Draw(img)

    c1 = (58, 58, 58)
    c2 = (82, 82, 82)

    for y in range(0, h, cell):
        for x in range(0, w, cell):
            color = c1 if ((x // cell) + (y // cell)) % 2 == 0 else c2
            draw.rectangle(
                (x, y, min(x + cell - 1, w), min(y + cell - 1, h)),
                fill=color,
            )

    return img


def make_card(name: str, image: Image.Image, card_size=(280, 340)) -> Image.Image:
    cw, ch = card_size

    card = Image.new("RGB", card_size, (22, 22, 22))
    draw = ImageDraw.Draw(card)
    font = ImageFont.load_default()

    preview_box = (cw - 24, ch - 58)

    bg = checkerboard(preview_box, 10)

    display = image.copy()

    display.thumbnail(
        (preview_box[0] - 20, preview_box[1] - 20),
        Image.Resampling.LANCZOS,
    )

    px = (bg.width - display.width) // 2
    py = (bg.height - display.height) // 2

    bg_rgba = bg.convert("RGBA")
    bg_rgba.alpha_composite(display, (px, py))

    card.paste(bg_rgba.convert("RGB"), (12, 12))

    draw.text(
        (12, ch - 38),
        name,
        fill=(235, 235, 235),
        font=font,
    )

    draw.text(
        (12, ch - 22),
        f"{image.width}x{image.height}",
        fill=(165, 165, 165),
        font=font,
    )

    return card


def split_wake_grid(source: Image.Image) -> list[Image.Image]:
    expected_size = (2172, 724)

    if source.size != expected_size:
        raise RuntimeError(
            f"Unexpected wake source size {source.size}; "
            f"expected {expected_size}. Refusing to guess."
        )

    cols = 4
    rows = 2
    cell_w = 543
    cell_h = 362

    frames = []

    for row in range(rows):
        for col in range(cols):
            x0 = col * cell_w
            y0 = row * cell_h

            frames.append(
                source.crop(
                    (
                        x0,
                        y0,
                        x0 + cell_w,
                        y0 + cell_h,
                    )
                )
            )

    return frames


def normalize_wake_strip(
    source: Image.Image,
) -> tuple[Image.Image, list[Image.Image]]:

    source_frames = split_wake_grid(source)

    descriptors = [describe_frame(frame) for frame in source_frames]

    fw, fh = WAKE_FRAME_SIZE
    padding = calculate_padding(WAKE_FRAME_SIZE)

    # ONE scale across every frame.
    # Never allow animation frames to resize independently.
    max_w = max(d["content_size"][0] for d in descriptors)

    max_h = max(d["content_size"][1] for d in descriptors)

    common_scale = min(
        (fw - padding * 2) / max_w,
        (fh - padding * 2) / max_h,
    )

    baseline = fh - padding

    normalized_frames = []

    for index, desc in enumerate(descriptors):
        crop = desc["crop"]

        nw = max(
            1,
            round(crop.width * common_scale),
        )

        nh = max(
            1,
            round(crop.height * common_scale),
        )

        resized = premultiplied_lanczos(
            crop,
            (nw, nh),
        )

        # Opaque mechanical structure is the registration authority.
        structure_center_x = desc["structure_center_x"] * common_scale

        structure_bottom = desc["structure_bottom"] * common_scale

        x = round((fw / 2.0) - structure_center_x)

        y = round(baseline - structure_bottom)

        # Safety only. If this clamps heavily, we want to know.
        unclamped_x = x
        unclamped_y = y

        x = max(
            0,
            min(x, fw - nw),
        )

        y = max(
            0,
            min(y, fh - nh),
        )

        if (x, y) != (unclamped_x, unclamped_y):
            print(
                f"WARNING: wake frame {index + 1} "
                f"required bounds clamp: "
                f"{(unclamped_x, unclamped_y)} -> {(x, y)}"
            )

        cell = Image.new(
            "RGBA",
            WAKE_FRAME_SIZE,
            (0, 0, 0, 0),
        )

        cell.alpha_composite(
            resized,
            (x, y),
        )

        normalized_frames.append(cell)

    strip = Image.new(
        "RGBA",
        (
            fw * len(normalized_frames),
            fh,
        ),
        (0, 0, 0, 0),
    )

    for index, frame in enumerate(normalized_frames):
        strip.alpha_composite(
            frame,
            (index * fw, 0),
        )

    if strip.size != (1536, 256):
        raise RuntimeError(
            f"Wake output ended at {strip.size}; " "expected exactly 1536x256."
        )

    return strip, normalized_frames


def create_contact_sheet(
    static_outputs: list[tuple[str, Image.Image]],
    wake_frames: list[Image.Image],
) -> Path:
    cards = []

    for name, img in static_outputs:
        cards.append(make_card(name, img))

    for i, frame in enumerate(wake_frames, 1):
        cards.append(
            make_card(
                f"Crèche wake frame {i:02d}",
                frame,
            )
        )

    cols = 4
    card_w = 280
    card_h = 340

    rows = (len(cards) + cols - 1) // cols

    sheet = Image.new(
        "RGB",
        (cols * card_w, rows * card_h),
        (10, 10, 10),
    )

    for i, card in enumerate(cards):
        x = (i % cols) * card_w
        y = (i // cols) * card_h
        sheet.paste(card, (x, y))

    out = PREVIEW_ROOT / "awakening_normalized_contact_sheet.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, compress_level=9)

    return out


def backup_file(path: Path) -> None:
    if not path.exists():
        return

    rel = path.relative_to(ROOT)
    backup = BACKUP_ROOT / rel

    if backup.exists():
        return

    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)


def apply_output(preview_path: Path, actual_path: Path) -> None:
    backup_file(actual_path)

    actual_path.parent.mkdir(parents=True, exist_ok=True)

    temp_path = actual_path.with_suffix(actual_path.suffix + ".normalize_tmp")
    shutil.copy2(preview_path, temp_path)
    temp_path.replace(actual_path)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Deterministically normalize CUSTODIAN Awakening source art."
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="After preview generation, back up and replace working source files.",
    )

    parser.add_argument(
        "--no-open",
        action="store_true",
        help="Do not open the generated contact sheet.",
    )

    args = parser.parse_args()

    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)

    report = {
        "static": [],
        "wake": {},
    }

    preview_static = []

    print()
    print("CUSTODIAN Awakening Asset Normalizer")
    print("=" * 46)
    print()

    for spec in STATIC_ASSETS:
        src = ROOT / spec["src"]
        dst_preview = PREVIEW_ROOT / spec["dst"]

        source = load_rgba(src)

        normalized = normalize_object(
            source,
            spec["size"],
            spec["anchor"],
        )

        save_png(normalized, dst_preview)

        preview_static.append((spec["name"], normalized))

        report["static"].append(
            {
                "name": spec["name"],
                "source": str(spec["src"]),
                "source_size": list(source.size),
                "output": str(spec["dst"]),
                "output_size": list(normalized.size),
                "anchor": spec["anchor"],
            }
        )

        print(
            f"✓ {spec['name']:<38} "
            f"{source.width}x{source.height} -> "
            f"{normalized.width}x{normalized.height}"
        )

    wake_source_path = ROOT / WAKE_SRC
    wake_source = load_rgba(wake_source_path)

    wake_strip, wake_frames = normalize_wake_strip(wake_source)

    wake_preview_path = PREVIEW_ROOT / WAKE_DST
    save_png(wake_strip, wake_preview_path)

    report["wake"] = {
        "source": str(WAKE_SRC),
        "source_size": list(wake_source.size),
        "output": str(WAKE_DST),
        "output_size": list(wake_strip.size),
        "frames": WAKE_FRAMES,
        "frame_size": list(WAKE_FRAME_SIZE),
        "frame_order": "left_to_right",
    }

    print(
        f"✓ {'Crèche recovery alcove / wake':<38} "
        f"{wake_source.width}x{wake_source.height} -> "
        f"{wake_strip.width}x{wake_strip.height} "
        f"({WAKE_FRAMES}x {WAKE_FRAME_SIZE[0]}x{WAKE_FRAME_SIZE[1]})"
    )

    report_path = PREVIEW_ROOT / "normalization_report.json"
    report_path.write_text(
        json.dumps(report, indent=2) + "\n",
        encoding="utf-8",
    )

    sheet = create_contact_sheet(preview_static, wake_frames)

    print()
    print(f"Preview assets: {PREVIEW_ROOT}")
    print(f"Contact sheet:  {sheet}")
    print(f"Report:         {report_path}")

    if args.apply:
        print()
        print("Applying normalized assets...")

        for spec in STATIC_ASSETS:
            preview_path = PREVIEW_ROOT / spec["dst"]
            actual_path = ROOT / spec["dst"]

            apply_output(preview_path, actual_path)
            print(f"  ✓ {spec['dst']}")

        apply_output(
            PREVIEW_ROOT / WAKE_DST,
            ROOT / WAKE_DST,
        )

        print(f"  ✓ {WAKE_DST}")

        print()
        print(f"Original backups: {BACKUP_ROOT}")
        print("APPLY COMPLETE")
    else:
        print()
        print("Nothing in source_work was modified.")
        print("Review the contact sheet, then run:")
        print()
        print("    python3 normalize_awakening_assets.py --apply")
        print()

    if not args.no_open:
        try:
            subprocess.Popen(
                ["xdg-open", str(sheet)],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, OSError):
            pass

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
