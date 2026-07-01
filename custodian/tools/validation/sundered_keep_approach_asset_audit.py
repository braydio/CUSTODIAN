#!/usr/bin/env python3
"""Audit Sundered Keep Approach source PNG export contracts."""

from __future__ import annotations

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print(
        "[SunderedKeepApproachAssetAudit] ERROR: Pillow/PIL is required for PNG alpha inspection.",
        file=sys.stderr,
    )
    sys.exit(1)


ROOT = Path(__file__).resolve().parents[2]

EXPECTED_SIZES = {
    "content/backgrounds/sundered_keep/ocean_underlay.png": (2100, 1400),
    "content/backgrounds/sundered_keep/cliff_depth_underlay.png": (520, 540),
    "content/sprites/world/return_causeway/underlay/underlay_fog_band.png": (2100, 360),
    "content/backgrounds/sundered_keep/horizon_sky.png": (2100, 380),
    "content/backgrounds/sundered_keep/far_sea.png": (2100, 260),
    "content/backgrounds/sundered_keep/distant_sundered_keep.png": (540, 250),
    "content/backgrounds/sundered_keep/vista_fog_band.png": (2100, 160),
    "content/sprites/world/return_causeway/path/mainland_approach_path.png": (470, 400),
    "content/sprites/world/return_causeway/path/hill_climb_path.png": (400, 240),
    "content/sprites/world/return_causeway/path/overlook_ledge.png": (640, 200),
    "content/sprites/world/return_causeway/path/lateral_traverse_path.png": (520, 180),
    "content/sprites/world/return_causeway/path/fortress_wall_mass.png": (350, 380),
    "content/sprites/world/return_causeway/occlusion/cliff_occluder.png": (520, 540),
    "content/sprites/world/return_causeway/occlusion/wall_shadow_occluder.png": (2100, 130),
}

PLAYABLE_ALPHA_REQUIRED = {
    "content/sprites/world/return_causeway/path/mainland_approach_path.png",
    "content/sprites/world/return_causeway/path/hill_climb_path.png",
    "content/sprites/world/return_causeway/path/overlook_ledge.png",
    "content/sprites/world/return_causeway/path/lateral_traverse_path.png",
    "content/sprites/world/return_causeway/path/fortress_wall_mass.png",
}


def _alpha_extrema(image: Image.Image) -> tuple[int, int] | None:
    if "A" not in image.getbands():
        return None
    alpha = image.getchannel("A")
    return alpha.getextrema()


def main() -> int:
    errors: list[str] = []

    for rel_path, expected_size in EXPECTED_SIZES.items():
        path = ROOT / rel_path
        if not path.exists():
            errors.append(f"missing PNG: {rel_path}")
            continue

        with Image.open(path) as image:
            actual_size = image.size
            print(f"[SunderedKeepApproachAssetAudit] {rel_path}: {actual_size[0]}x{actual_size[1]} mode={image.mode}")
            if actual_size != expected_size:
                errors.append(f"{rel_path} expected {expected_size[0]}x{expected_size[1]}, got {actual_size[0]}x{actual_size[1]}")

            if rel_path in PLAYABLE_ALPHA_REQUIRED:
                extrema = _alpha_extrema(image)
                if extrema is None:
                    errors.append(f"{rel_path} has no alpha channel; re-export playable terrain with transparency outside the terrain shape")
                elif extrema[0] >= 255:
                    errors.append(f"{rel_path} is fully opaque; re-export playable terrain with transparent non-terrain pixels")

    if errors:
        for error in errors:
            print(f"[SunderedKeepApproachAssetAudit] ERROR: {error}", file=sys.stderr)
        print(f"[SunderedKeepApproachAssetAudit] FAIL ({len(errors)} issue(s))", file=sys.stderr)
        return 1

    print("[SunderedKeepApproachAssetAudit] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
