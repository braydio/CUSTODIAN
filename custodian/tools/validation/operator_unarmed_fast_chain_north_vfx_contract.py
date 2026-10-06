#!/usr/bin/env python3
"""Verify the North fast-chain FX source, pipeline, and runtime image contract."""
from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
ASSET_ROOT = ROOT / "custodian"


def main() -> int:
    for action, frames in (("fast_01", 6), ("fast_02", 6), ("fast_03", 7), ("fast_04", 8)):
        name = f"operator__fx__unarmed__attack__{action}__n__{frames}f__96.png"
        paths = {
            "source_work": ROOT / "custodian/asset_drop/source_work/operator/unarmed/attack" / action / "north" / f"operator_unarmed_{action}_n_vfx_generated_master.png",
            "inbox": ASSET_ROOT / "content/sprites/_pipeline/inbox" / name,
            "normalized": ASSET_ROOT / "content/sprites/_pipeline/normalized" / name,
            "source": ASSET_ROOT / "content/sprites/operator/source/animations/unarmed/attack" / action / name,
            "runtime": ASSET_ROOT / "content/sprites/operator/runtime/animations/unarmed/attack" / action / name,
        }
        for label, path in paths.items():
            assert path.is_file(), f"{action}: missing {label} asset: {path}"

        assert paths["source"].read_bytes() == paths["runtime"].read_bytes(), f"{action}: source/runtime bytes differ"
        reference_pixels = None
        for label in ("inbox", "normalized", "source", "runtime"):
            with Image.open(paths[label]) as source_image:
                image = source_image.convert("RGBA")
            assert image.size == (frames * 96, 96), f"{action}: {label} dimensions {image.size}"
            alpha = image.getchannel("A")
            assert alpha.getextrema() == (0, 255), f"{action}: {label} lacks real transparency"
            for frame in range(frames):
                cell = alpha.crop((frame * 96, 0, (frame + 1) * 96, 96))
                assert cell.getbbox() is not None, f"{action}: {label} frame {frame + 1} is empty"
            pixels = image.tobytes()
            if reference_pixels is None:
                reference_pixels = pixels
            else:
                assert pixels == reference_pixels, f"{action}: {label} pixels differ from inbox"
    print("PASS operator_unarmed_fast_chain_north_vfx_contract: dimensions, alpha, cells, and pipeline parity")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
