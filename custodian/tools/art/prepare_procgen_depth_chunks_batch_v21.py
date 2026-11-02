#!/usr/bin/env python3
"""Normalize the second procgen depth-chunk batch into its V2.1 inbox."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[3]
SOURCE_DIR = REPO_ROOT / "custodian/asset_drop/source_work/procgen_depth_chunks"
INBOX_DIR = REPO_ROOT / "custodian/asset_drop/inbox/procgen_depth_chunks"
REPORT_PATH = (
    REPO_ROOT
    / "custodian/asset_drop/production_prep/procgen_depth_chunks/normalization_report.json"
)
ALPHA_CUTOFF = 16

ASSETS = {
    "depth_woodland_overgrown_works_v1.png": ("woodland_overgrown_works.png", (640, 448)),
    "depth_wetland_flooded_basin_v1.png": ("wetland_flooded_basin.png", (896, 576)),
    "depth_wetland_reed_channels_v1.png": ("wetland_reed_channels.png", (640, 448)),
    "depth_wetland_drowned_service_platform_v1.png": (
        "wetland_drowned_service_platform.png",
        (640, 448),
    ),
    "depth_rocky_upland_cliff_bowl_v1.png": ("rocky_upland_cliff_bowl.png", (896, 576)),
    "depth_rocky_upland_talus_ravine_v1.png": (
        "rocky_upland_talus_ravine.png",
        (896, 576),
    ),
    "depth_rocky_upland_exposed_ledge_v1.png": (
        "rocky_upland_exposed_ledge.png",
        (640, 448),
    ),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def normalize(source: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    source = source.convert("RGBA")
    scale = min(target_size[0] / source.width, target_size[1] / source.height)
    resized_size = (round(source.width * scale), round(source.height * scale))
    resized = source.resize(resized_size, Image.Resampling.LANCZOS)
    alpha = resized.getchannel("A")
    alpha = alpha.point([0 if value <= ALPHA_CUTOFF else value for value in range(256)])
    resized.putalpha(alpha)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    offset = ((target_size[0] - resized.width) // 2, (target_size[1] - resized.height) // 2)
    canvas.alpha_composite(resized, offset)
    return canvas


def alpha_metrics(image: Image.Image) -> dict[str, float | int]:
    histogram = image.getchannel("A").histogram()
    total = image.width * image.height
    return {
        "alpha_min": image.getchannel("A").getextrema()[0],
        "alpha_max": image.getchannel("A").getextrema()[1],
        "transparent_fraction": sum(histogram[:250]) / total,
        "partial_alpha_fraction": sum(histogram[17:255]) / total,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    missing = [name for name in ASSETS if not (SOURCE_DIR / name).is_file()]
    if missing:
        raise RuntimeError("Missing source masters:\n  " + "\n  ".join(missing))

    report = {
        "schema": "custodian.procgen_depth_chunks.normalization.v2",
        "source_root": str(SOURCE_DIR.relative_to(REPO_ROOT)),
        "inbox_root": str(INBOX_DIR.relative_to(REPO_ROOT)),
        "resampling": "Pillow LANCZOS exactly once from master to final size",
        "alpha_cutoff": ALPHA_CUTOFF,
        "outputs": [],
    }
    for source_name, (state_name, target_size) in ASSETS.items():
        source_path = SOURCE_DIR / source_name
        with Image.open(source_path) as opened:
            source = opened.convert("RGBA")
        source_metrics = alpha_metrics(source)
        if source_metrics["alpha_max"] != 255 or source_metrics["transparent_fraction"] <= 0.005:
            raise RuntimeError(f"{source_name}: missing usable true-alpha silhouette")
        output = normalize(source, target_size)
        output_metrics = alpha_metrics(output)
        if output.size != target_size or output_metrics["transparent_fraction"] <= 0.005:
            raise RuntimeError(f"{source_name}: invalid normalized output")
        output_path = INBOX_DIR / state_name
        if not args.dry_run:
            INBOX_DIR.mkdir(parents=True, exist_ok=True)
            output.save(output_path, compress_level=9)
        report["outputs"].append({
            "source": source_name,
            "source_sha256": sha256(source_path),
            "source_size": list(source.size),
            "state": state_name.removesuffix(".png"),
            "output": state_name,
            "output_size": list(output.size),
            "source_alpha": source_metrics,
            "output_alpha": output_metrics,
        })
        print(f"{source_name} -> {state_name} {target_size[0]}x{target_size[1]}")

    if not args.dry_run:
        REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
        REPORT_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote {REPORT_PATH.relative_to(REPO_ROOT)}")
    else:
        print("Dry run complete; no files written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
