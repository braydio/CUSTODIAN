#!/usr/bin/env python3
"""Audit Sundered Keep Approach route-master PNG contracts."""

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
    "content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png": (4813, 3066),
    "content/backgrounds/sundered_keep/approach/approach_ocean_void_underlay.png": (1586, 992),
    "content/backgrounds/sundered_keep/approach/approach_cliff_spires_underlay.png": (2560, 1600),
    "content/backgrounds/sundered_keep/approach/approach_route_contact_shadow.png": (1536, 1024),
    "content/backgrounds/sundered_keep/approach/approach_edge_mist_wrap.png": (1536, 1024),
    "content/backgrounds/sundered_keep/approach/approach_first_vista_horizon.png": (2560, 1440),
    "content/backgrounds/sundered_keep/approach/approach_first_vista_fog_veil.png": (2560, 1440),
    "content/backgrounds/sundered_keep/approach/approach_final_gate_shadow_veil.png": (2560, 900),
    "content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_01.png": (1024, 512),
    "content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_02.png": (1024, 512),
    "content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_03.png": (1024, 512),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_panorama.png": (1672, 941),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_fog_overlay.png": (1672, 941),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_parapet.png": (1672, 941),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_shadow_vignette.png": (1672, 941),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_ocean_spray_overlay.png": (1672, 941),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_horizon_seam_fog.png": (3546, 443),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_path_contact_shadow.png": (3546, 443),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_edge_mask.png": (1672, 941),
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_edge_spray_wrap.png": (1656, 925),
}

ALPHA_REQUIRED = {
    "content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png",
    "content/backgrounds/sundered_keep/approach/approach_route_contact_shadow.png",
    "content/backgrounds/sundered_keep/approach/approach_edge_mist_wrap.png",
    "content/backgrounds/sundered_keep/approach/approach_first_vista_horizon.png",
    "content/backgrounds/sundered_keep/approach/approach_first_vista_fog_veil.png",
    "content/backgrounds/sundered_keep/approach/approach_final_gate_shadow_veil.png",
    "content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_01.png",
    "content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_02.png",
    "content/backgrounds/sundered_keep/approach/fog/approach_fog_strip_03.png",
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_parapet.png",
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_ocean_spray_overlay.png",
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_horizon_seam_fog.png",
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_path_contact_shadow.png",
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_foreground_edge_mask.png",
    "content/backgrounds/sundered_keep/grand_vista/grand_vista_edge_spray_wrap.png",
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

            if rel_path in ALPHA_REQUIRED:
                extrema = _alpha_extrema(image)
                if extrema is None:
                    errors.append(f"{rel_path} has no alpha channel; export with real transparency")
                elif extrema[0] >= 255:
                    errors.append(f"{rel_path} is fully opaque; remove baked checkerboard/matte and preserve real alpha")
                elif extrema[1] <= 0:
                    errors.append(f"{rel_path} is fully transparent; overlay needs visible nontransparent pixels")

    legacy_fog_paths = sorted((ROOT / "content/backgrounds/sundered_keep/approach").glob("approach_fog_strip_*.png"))
    for path in legacy_fog_paths:
        errors.append(f"fog strip should live under approach/fog/: {path.relative_to(ROOT)}")

    if errors:
        for error in errors:
            print(f"[SunderedKeepApproachAssetAudit] ERROR: {error}", file=sys.stderr)
        print(f"[SunderedKeepApproachAssetAudit] FAIL ({len(errors)} issue(s))", file=sys.stderr)
        return 1

    print("[SunderedKeepApproachAssetAudit] PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
