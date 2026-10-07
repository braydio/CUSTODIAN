#!/usr/bin/env python3
"""Prove Dropbox source identity, lossless connector publication, and Locker truth."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "asset_drop/source_work/awakening"
LEVELS = ROOT / "content/levels/awakening"
ASSETS = ROOT / "content/metadata/assets"
SCENE = ROOT / "scenes/awakening_first_return.tscn"
EXPECTED = {
    "dust": ("awakening_dust_lung_environment/underlay_source.png", "fa017e6daa218d9a0713be760f19acdb285ae0c5e01854c3fe43126ca547f111", (1216, 1216)),
    "connector": ("awakening_reliquary_dust_lung_connector/full_plate_underlay_source.png", "eb1dd930c6c084a3a9dce59ed57c5b0716730698daf88edbb197cceb08ffe721", (1374, 1076)),
    "locker": ("awakening_locker_reliquary_environment/underlay_source.png", "75e253f73f6570b72ed0b646648c2ba31902612c3241df82956b4d00ddd71a6c", (1200, 1211)),
}
RUNTIME = {
    "dust": LEVELS / "05_dust_lung/awakening_dust_lung_underlay_1216x1216.png",
    "connector": LEVELS / "04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1374x1076.png",
    "locker": LEVELS / "04_locker_reliquary/awakening_locker_reliquary_underlay_704x704.png",
}


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _normalized_locker(source_path: Path) -> tuple[Image.Image, float, tuple[int, int], tuple[int, int]]:
    source = Image.open(source_path).convert("RGBA")
    scale = min(704 / source.width, 704 / source.height)
    size = (round(source.width * scale), round(source.height * scale))
    resized = source.resize(size, Image.Resampling.LANCZOS)
    offset = ((704 - size[0]) // 2, (704 - size[1]) // 2)
    normalized = Image.new("RGBA", (704, 704), (0, 0, 0, 0))
    normalized.alpha_composite(resized, offset)
    return normalized, scale, size, offset


def main() -> int:
    failures: list[str] = []
    sources: dict[str, Path] = {}
    for key, (relative, digest, size) in EXPECTED.items():
        path = SOURCE / relative
        sources[key] = path
        if not path.is_file():
            failures.append(f"missing preserved source master: {path.relative_to(ROOT)}")
            continue
        if _sha256(path) != digest:
            failures.append(f"Dropbox SHA-256 mismatch for {key}")
        with Image.open(path) as image:
            if image.size != size:
                failures.append(f"{key} source size {image.size} != {size}")

    for key in ("dust", "connector"):
        if not sources[key].is_file() or not RUNTIME[key].is_file():
            failures.append(f"missing {key} source/runtime pair")
            continue
        if _sha256(sources[key]) != _sha256(RUNTIME[key]):
            failures.append(f"{key} runtime does not preserve exact Dropbox source bytes")
        with Image.open(sources[key]) as original, Image.open(RUNTIME[key]) as published:
            if original.convert("RGBA").size != published.convert("RGBA").size:
                failures.append(f"{key} runtime dimensions differ from source")

    locker_report: dict[str, object] = {}
    if sources["locker"].is_file() and RUNTIME["locker"].is_file():
        expected, scale, size, offset = _normalized_locker(sources["locker"])
        published = Image.open(RUNTIME["locker"]).convert("RGBA")
        if ImageChops.difference(expected, published).getbbox() is not None:
            failures.append("Locker runtime differs from uniform crop-free 704x704 normalization")
        source_bounds = Image.open(sources["locker"]).convert("RGBA").getchannel("A").getbbox()
        if source_bounds != (0, 0, 1200, 1211):
            failures.append(f"Locker source alpha bounds changed: {source_bounds}")

        foreground = Image.open(LEVELS / "04_locker_reliquary/awakening_locker_reliquary_foreground_704x704.png").convert("RGBA")
        underlay_alpha = published.getchannel("A")
        foreground_alpha = foreground.getchannel("A")
        alpha_pairs = [
            (underlay_alpha.getpixel((x, y)), foreground_alpha.getpixel((x, y)))
            for y in range(704)
            for x in range(704)
            if foreground_alpha.getpixel((x, y)) >= 128
        ]
        backed = sum(underlay >= 250 for underlay, _foreground in alpha_pairs)
        backing_ratio = backed / len(alpha_pairs) if alpha_pairs else 0.0
        if not alpha_pairs or backing_ratio >= 0.99:
            failures.append("Locker foreground parity test did not establish a material underlay mismatch")

        family = json.loads((ASSETS / "families/awakening_locker_reliquary_environment.asset.json").read_text())
        foreground_contract = family["states"]["foreground"]
        if foreground_contract.get("required") or foreground_contract.get("recommended"):
            failures.append("incompatible Locker foreground is still required/recommended by Asset V2")
        scene_text = SCENE.read_text()
        if "Zone04_LockerReliquary/Occlusion/Foreground" in scene_text or "awakening_locker_reliquary_foreground_704x704.png" in scene_text:
            failures.append("incompatible Locker foreground remains bound in the Awakening scene")
        requirements = json.loads((ASSETS / "required_assets.registry.json").read_text())
        deferred = next((item for item in requirements["requirements"] if item.get("id") == "p1-awakening-locker-foreground-parity"), None)
        if deferred is None or deferred.get("fulfillment", {}).get("status") != "deferred":
            failures.append("deferred Locker foreground is not recorded in Asset requirements")
        locker_report = {
            "source_size": [1200, 1211],
            "uniform_scale": scale,
            "resized_size": list(size),
            "transparent_padding_offset": list(offset),
            "opaque_foreground_backing_ratio": backing_ratio,
            "foreground_bound": False,
            "foreground_requirement": "deferred",
        }

    if failures:
        print(json.dumps({"test": "awakening_connector_asset_contract_smoke", "passed": False, "failures": failures}, indent=2))
        return 1
    print(json.dumps({
        "test": "awakening_connector_asset_contract_smoke",
        "passed": True,
        "source_sha256": {key: value[1] for key, value in EXPECTED.items()},
        "connector_silhouette": "full source preserved byte-for-byte",
        "locker_normalization": locker_report,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
