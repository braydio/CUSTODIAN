#!/usr/bin/env python3
"""Publish authored timing sidecars for the shared melee_1h fast-chain art.

The Vigil-Pattern Dagger's compatibility `SpriteFrames` played the generic
`melee_1h/attack/fast_0N` strips at 18/14/13 fps. The canonical identities built
from the same strips carry no timing sidecar, so they publish at the pipeline
default of 12 fps. Canonicalizing armed melee without closing that gap would
retune the dagger by accident.

The evidence that 18/14/13 is the *semantic* timing of these identities rather
than a dagger-local preference is that the weapon layer already says so: the
published `weapon/vigil_pattern_dagger/melee_1h_dagger/attack/fast_0N/*/weapon`
identities already carry exactly 18, 14 and 13 fps with the 1.5 final-frame hold
on fast_03. The body and FX layers of the same actions were simply never given
sidecars. This repairs that.

No runtime consumer reads `melee_1h/attack/fast_0N` semantically today -- the only
`melee_1h` identities the actor selects are `transition` and `defense` actions --
so retiming these creates no conflict with another clock.

Sidecars are authored source data. Run the Operator runtime sync afterwards to
republish; do not hand-edit generated runtime files.

Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = CUSTODIAN_ROOT / "content/sprites/operator/source/animations"
TIMING_SCHEMA = "custodian.operator_animation_timing.v1"

MIGRATION_SOURCE = {
    "consumer": "res://game/actors/operator/vigil_pattern_dagger_definition.tres",
    "resource": "res://game/actors/operator/vigil_pattern_dagger_body_frames.tres",
    "note": (
        "Cadence recovered from the pre-C2b compatibility SpriteFrames the Vigil "
        "dagger installed at equip time; matches the already-published weapon-layer "
        "sidecars for the same actions."
    ),
}

# action -> {layers to retime: (frames, fps, durations)}
# fast_03's 10-frame body layers are deliberately absent: the dagger plays a
# 9-frame subrange of that art, which is published as a weapon-owned override
# instead of being imposed on the shared identity.
PLAN = {
    "fast_01": {
        "layers": ["full_body", "fx", "lower_body", "upper_body"],
        "frames": 10,
        "fps": 18.0,
        "durations": [1.0] * 10,
    },
    "fast_02": {
        "layers": ["full_body", "fx", "lower_body", "upper_body"],
        "frames": 8,
        "fps": 14.0,
        "durations": [1.0] * 8,
    },
    "fast_03": {
        "layers": ["fx"],
        "frames": 8,
        "fps": 13.0,
        "durations": [1.0] * 7 + [1.5],
    },
}

SECTORS = ["e", "w"]


def frame_hashes(png: Path, frames: int) -> list[str]:
    from PIL import Image

    with Image.open(png) as im:
        rgba = im.convert("RGBA")
        width = rgba.width // frames
        out = []
        for i in range(frames):
            crop = rgba.crop((i * width, 0, (i + 1) * width, rgba.height)).copy()
            raw = bytearray(crop.tobytes())
            for k in range(0, len(raw), 4):
                if raw[k + 3] == 0:
                    raw[k] = raw[k + 1] = raw[k + 2] = 0
            out.append(hashlib.sha256(bytes(raw)).hexdigest())
        return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write the sidecars (default is a dry run)")
    args = parser.parse_args(argv)

    written, skipped, missing = 0, 0, []
    for action, spec in PLAN.items():
        directory = SOURCE_ROOT / "melee_1h/attack" / action
        for layer in spec["layers"]:
            for sector in SECTORS:
                # The frame-size suffix is per-file, not per-layer: melee_1h
                # fast_02 publishes its lower/upper body at 156x96 while fast_01
                # publishes them at 96. Discover it instead of assuming.
                stem = "operator__%s__melee_1h__attack__%s__%s__%df__" % (
                    layer, action, sector, spec["frames"]
                )
                candidates = sorted(directory.glob(stem + "*.png"))
                if len(candidates) != 1:
                    missing.append("%s (%d matches for %s*)" % (
                        directory.relative_to(CUSTODIAN_ROOT).as_posix(), len(candidates), stem))
                    continue
                png = candidates[0]
                sidecar = png.with_suffix("").with_suffix(".animation.json")
                payload = {
                    "durations": spec["durations"],
                    "fps": spec["fps"],
                    "frame_rgba_sha256": frame_hashes(png, spec["frames"]),
                    "frames": spec["frames"],
                    "loop": False,
                    "migration_source": MIGRATION_SOURCE,
                    "schema": TIMING_SCHEMA,
                }
                body = json.dumps(payload, indent="\t", sort_keys=True) + "\n"
                if sidecar.exists() and sidecar.read_text(encoding="utf-8") == body:
                    skipped += 1
                    continue
                action_word = "write" if args.apply else "would write"
                print("%s %s  (%df @ %g fps)" % (
                    action_word, sidecar.relative_to(CUSTODIAN_ROOT).as_posix(),
                    spec["frames"], spec["fps"]))
                if args.apply:
                    sidecar.write_text(body, encoding="utf-8")
                written += 1

    if missing:
        print("\nMISSING source PNGs (nothing written for these):")
        for m in missing:
            print("  " + m)
    print("\n%d sidecar(s) %s, %d already current" % (
        written, "written" if args.apply else "pending", skipped))
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
