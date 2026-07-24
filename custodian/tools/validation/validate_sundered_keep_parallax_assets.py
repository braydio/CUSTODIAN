#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import sys

from PIL import Image, ImageDraw


PROJECT_ROOT = Path(__file__).resolve().parents[2]

ASSETS = {
    "far_cliff_islands": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/far_cliff_islands.png",
    "lower_cliff_depth": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/lower_cliff_depth.png",
    "causeway_far_arches": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/causeway_far_arches.png",
    "ocean_mist_left": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/ocean_mist_strip_left.png",
    "ocean_mist_right": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/ocean_mist_strip_right.png",
    "near_edge_mist_left": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/near_edge_mist_left.png",
    "near_edge_mist_right": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/near_edge_mist_right.png",
    "foreground_ruined_arch": PROJECT_ROOT
    / "content/backgrounds/sundered_keep/approach/parallax/foreground_ruined_arch.png",
}

FOG_ASSETS = {
    "ocean_mist_left",
    "ocean_mist_right",
    "near_edge_mist_left",
    "near_edge_mist_right",
}

KNOWN_REJECTED_DIGESTS = {
    "causeway_far_arches": (
        "ccbb192b573df98489300629aa8d4b19a1f3f07ebd137fcb8163f0133aa13ef0",
        "contains baked checkerboard inside the fog/architecture plate",
    ),
    "far_cliff_islands": (
        "042efae1f86ee8d75198cbf1e8be1773b97ded3ad38c791a55e44f33f22078de",
        "contains baked checkerboard inside the cloud and island plate",
    ),
    "lower_cliff_depth": (
        "adbc6bf211d67198277bfd0dd89957528b1e8a6bc9165682145b34e5fce4f87a",
        "contains a nearly opaque checkerboard across the full canvas",
    ),
    "ocean_mist_left": (
        "d763bc3e42d3e23c7b8ca160b926ea6f7411fc3cbd8aed4f519acd307d2d11f2",
        "contains baked checkerboard and lacks fog alpha gradation",
    ),
    "ocean_mist_right": (
        "062ca985f546c494d4e28dcd62372be219b51f92912ba773f199d673e87ecc39",
        "does not visually match the left mist plate and has hard landscape edges",
    ),
    "near_edge_mist_left": (
        "f889366002c1fa05fa7868d8bea5db38e155959e18cd7a4d7835329f4d61c8e1",
        "contains baked checkerboard inside the bright mist edge",
    ),
    "near_edge_mist_right": (
        "1150c7a62c22aae774c32f3e9b0eba03b8f5229f04d7073d8d98ec5307b2af1e",
        "contains baked checkerboard inside the bright mist edge",
    ),
}

REVIEW_BACKGROUNDS = {
    "red": (196, 24, 24, 255),
    "green": (24, 156, 64, 255),
    "black": (0, 0, 0, 255),
    "white": (255, 255, 255, 255),
}


def validate_asset(name: str, path: Path) -> list[str]:
    errors: list[str] = []

    if not path.is_file():
        return [f"{name}: missing file: {path}"]

    try:
        with Image.open(path) as source:
            if source.format != "PNG":
                errors.append(
                    f"{name}: expected PNG, detected {source.format or 'unknown'}"
                )
            if "A" not in source.getbands() and "transparency" not in source.info:
                errors.append(f"{name}: PNG has no alpha channel")
            image = source.convert("RGBA")
    except Exception as exc:
        return [f"{name}: could not open image: {exc}"]

    alpha = image.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    alpha_histogram = alpha.histogram()
    unique_alpha_count = sum(
        1 for pixel_count in alpha_histogram if pixel_count > 0
    )
    pixel_count = image.width * image.height
    transparent_fraction = sum(alpha_histogram[:6]) / pixel_count
    opaque_fraction = sum(alpha_histogram[250:]) / pixel_count
    digest = hashlib.sha256(path.read_bytes()).hexdigest()

    if alpha_min == 255 and alpha_max == 255:
        errors.append(
            f"{name}: alpha is fully opaque; likely no real transparency"
        )

    if alpha_min == 0 and alpha_max == 0:
        errors.append(f"{name}: image is fully transparent")

    if alpha_min >= 250:
        errors.append(
            f"{name}: no meaningful transparent region; alpha minimum={alpha_min}"
        )

    if transparent_fraction <= 0.001:
        errors.append(
            f"{name}: no usable fully transparent canvas "
            f"({transparent_fraction:.2%} alpha<=5)"
        )

    if name in FOG_ASSETS and unique_alpha_count < 8:
        errors.append(
            f"{name}: fog alpha lacks sufficient gradation "
            f"({unique_alpha_count} unique alpha values)"
        )

    rejected = KNOWN_REJECTED_DIGESTS.get(name)
    if rejected is not None and digest == rejected[0]:
        errors.append(f"{name}: rejected source revision: {rejected[1]}")

    print(
        f"[ParallaxAlpha] {name}: "
        f"{image.width}x{image.height}, "
        f"alpha={alpha_min}..{alpha_max}, "
        f"unique_alpha={unique_alpha_count}, "
        f"clear={transparent_fraction:.1%}, "
        f"opaque={opaque_fraction:.1%}, "
        f"sha256={digest[:12]}"
    )

    return errors


def write_review_sheet(name: str, path: Path, review_dir: Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGBA")

    panel_size = (640, 400)
    sheet = Image.new("RGBA", (panel_size[0] * 2, panel_size[1] * 2))
    for index, (label, color) in enumerate(REVIEW_BACKGROUNDS.items()):
        panel = Image.new("RGBA", panel_size, color)
        fitted = image.copy()
        fitted.thumbnail(
            (panel_size[0] - 24, panel_size[1] - 40),
            Image.Resampling.LANCZOS,
        )
        position = (
            (panel_size[0] - fitted.width) // 2,
            (panel_size[1] - fitted.height) // 2 + 12,
        )
        panel.alpha_composite(fitted, position)
        draw = ImageDraw.Draw(panel)
        draw.rectangle((0, 0, 180, 24), fill=(0, 0, 0, 180))
        draw.text((8, 5), f"{name} / {label}", fill="white")
        sheet.alpha_composite(
            panel,
            (
                (index % 2) * panel_size[0],
                (index // 2) * panel_size[1],
            ),
        )

    review_dir.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(
        review_dir / f"{name}_review.png",
        "PNG",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate Sundered Keep parallax alpha and review gates."
    )
    parser.add_argument(
        "--review-dir",
        type=Path,
        help="write four-background review sheets to this directory",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    failures: list[str] = []

    for name, path in ASSETS.items():
        failures.extend(validate_asset(name, path))
        if args.review_dir is not None and path.is_file():
            write_review_sheet(name, path, args.review_dir)

    if failures:
        for failure in failures:
            print(f"[ParallaxAlpha] ERROR: {failure}", file=sys.stderr)
        if args.review_dir is not None:
            print(f"[ParallaxAlpha] Review sheets: {args.review_dir}")
        return 1

    if args.review_dir is not None:
        print(f"[ParallaxAlpha] Review sheets: {args.review_dir}")
    print("[ParallaxAlpha] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
