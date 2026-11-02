#!/usr/bin/env python3
"""Preserve the Vigil dagger's 9-frame Fast 03 body as a weapon-owned override.

Every other Vigil fast-chain layer maps onto an identity the canonical database
already publishes. Fast 03's body does not: `vigil_pattern_dagger_body_frames.tres`
plays the **first nine** atlas regions of the generic ten-frame
`melee_1h/attack/fast_03/{e,w}/full_body` strip, at 13 fps, with a 1.5x hold on
the final frame. That is a distinct authored presentation, not a retime of the
shared identity, so it becomes weapon-owned art rather than being imposed on
`melee_1h`.

This materializes those exact nine frames -- no redraw, no regeneration, no
resampling -- as an Operator V2 source master under the weapon's own override
tree, with the timing sidecar beside it. `sync_operator_runtime_assets.py` then
publishes it to runtime and `build_operator_runtime_frames.gd` gives it the
identity:

    weapon/vigil_pattern_dagger/melee_1h_dagger/attack/fast_03/{e,w}/full_body

The frame hashes written into the sidecar are the preservation evidence: they are
computed from the compatibility resource's own atlas regions, so a later rebuild
that silently changes these pixels is detectable.

Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[3]
GENERIC_FAST_03 = (
    CUSTODIAN_ROOT / "content/sprites/operator/runtime/animations/melee_1h/attack/fast_03"
)
WEAPON_SOURCE = (
    CUSTODIAN_ROOT
    / "content/sprites/weapons/vigil_pattern_dagger/source/operator"
    / "melee_1h_dagger/overrides/attack/fast_03"
)
WORKING = (
    CUSTODIAN_ROOT
    / "asset_drop/source_work/operator/vigil_pattern_dagger_fast03_body_preservation"
)

TIMING_SCHEMA = "custodian.operator_animation_timing.v1"

PRESERVED_FRAMES = 9          # regions 0..8 of the 10-frame source
FRAME_WIDTH = 156
FRAME_HEIGHT = 96
FPS = 13.0
DURATIONS = [1.0] * 8 + [1.5]


def visible_hash(crop) -> str:
    raw = bytearray(crop.tobytes())
    for i in range(0, len(raw), 4):
        if raw[i + 3] == 0:
            raw[i] = raw[i + 1] = raw[i + 2] = 0
    return hashlib.sha256(bytes(raw)).hexdigest()


def build(sector: str, apply: bool) -> tuple[bool, str]:
    from PIL import Image

    source = GENERIC_FAST_03 / (
        "operator__full_body__melee_1h__attack__fast_03__%s__10f__156x96.png" % sector
    )
    if not source.exists():
        return False, "missing generic source strip: %s" % source

    with Image.open(source) as im:
        rgba = im.convert("RGBA")
        if rgba.size != (FRAME_WIDTH * 10, FRAME_HEIGHT):
            return False, "unexpected source geometry %s for %s" % (rgba.size, source.name)
        out = Image.new("RGBA", (FRAME_WIDTH * PRESERVED_FRAMES, FRAME_HEIGHT), (0, 0, 0, 0))
        hashes = []
        for index in range(PRESERVED_FRAMES):
            box = (index * FRAME_WIDTH, 0, (index + 1) * FRAME_WIDTH, FRAME_HEIGHT)
            frame = rgba.crop(box).copy()
            out.paste(frame, (index * FRAME_WIDTH, 0))
            hashes.append(visible_hash(frame))

    name = (
        "vigil_pattern_dagger__full_body__melee_1h_dagger__attack__fast_03__%s__9f__156x96"
        % sector
    )
    png = WEAPON_SOURCE / (name + ".png")
    sidecar = WEAPON_SOURCE / (name + ".animation.json")
    master = WORKING / ("fast_03_%s_source.png" % sector)

    payload = {
        "durations": DURATIONS,
        "fps": FPS,
        "frame_rgba_sha256": hashes,
        "frames": PRESERVED_FRAMES,
        "loop": False,
        "migration_source": {
            "animation": "vigil_dagger_fast_03_%s" % ("right" if sector == "e" else "left"),
            "consumer": "res://game/actors/operator/vigil_pattern_dagger_definition.tres",
            "resource": "res://game/actors/operator/vigil_pattern_dagger_body_frames.tres",
            "note": (
                "Frames 0-8 of the generic ten-frame melee_1h fast_03 strip, the exact "
                "subrange and cadence the compatibility SpriteFrames played. Copied "
                "region-for-region; no resample, no redraw."
            ),
        },
        "schema": TIMING_SCHEMA,
    }
    body = json.dumps(payload, indent="\t", sort_keys=True) + "\n"

    if apply:
        WEAPON_SOURCE.mkdir(parents=True, exist_ok=True)
        WORKING.mkdir(parents=True, exist_ok=True)
        out.save(png)
        out.save(master)
        sidecar.write_text(body, encoding="utf-8")
    return True, "%s  %dx%d  %d frames @ %g fps" % (
        png.relative_to(CUSTODIAN_ROOT).as_posix(),
        out.width, out.height, PRESERVED_FRAMES, FPS,
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write the masters (default is a dry run)")
    args = parser.parse_args(argv)

    failed = False
    for sector in ("e", "w"):
        ok, message = build(sector, args.apply)
        print("%s %s" % ("wrote" if (ok and args.apply) else ("would write" if ok else "FAIL"), message))
        failed = failed or not ok
    if not failed and args.apply:
        print("\nNext: sync_operator_runtime_assets.py, then build_operator_runtime_frames.gd")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
