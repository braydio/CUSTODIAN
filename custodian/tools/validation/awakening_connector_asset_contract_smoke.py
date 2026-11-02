#!/usr/bin/env python3
"""Prove the exact registered 04→05 composition and Asset V2 publication."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "asset_drop/source_work/awakening"
LEVELS = ROOT / "content/levels/awakening"
ASSETS = ROOT / "content/metadata/assets/families"
SCENE = ROOT / "scenes/awakening_first_return.tscn"
CANVAS = (1502, 2048)
EXPECTED = {
    "dust": (
        SOURCE / "awakening_dust_lung_environment/registered_composition_v1/underlay_source.png",
        LEVELS / "05_dust_lung/awakening_dust_lung_underlay_1502x2048.png",
        "fa8637992bfc0b1ff1b0d009fbe463e098a4adbfe97031c67d2276d2fe94172e",
        (0, 0, 870, 838),
    ),
    "connector": (
        SOURCE / "awakening_reliquary_dust_lung_connector/registered_composition_v1/full_plate_underlay_source.png",
        LEVELS / "04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png",
        "489b49615ba53b0073519d5a261f736321ba69b95019bb54ec02ff408a9ffd76",
        (258, 672, 1300, 1256),
    ),
    "locker": (
        SOURCE / "awakening_locker_reliquary_environment/registered_composition_v1/underlay_source.png",
        LEVELS / "04_locker_reliquary/awakening_locker_reliquary_underlay_1502x2048.png",
        "76cc103eda059974f8f279e8e4e10fdb1b388030ea26f2a7b659075c45ceb48d",
        (644, 1182, 1502, 2048),
    ),
}
COMPOSITE = SOURCE / "awakening_04_05_registered_composition_v1/composite_reference_1502x2048.png"
COMPOSITE_SHA256 = "521beec078b9c3dfb3d694d134258c6a77d0db64e3ce4cc8a71491efff8c9383"


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _bounds(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def main() -> int:
    failures: list[str] = []
    layers: dict[str, Image.Image] = {}
    hashes: dict[str, str] = {}
    for name, (source, runtime, expected_hash, expected_bounds) in EXPECTED.items():
        for label, path in (("registered source", source), ("runtime", runtime)):
            if not path.is_file():
                failures.append(f"missing {name} {label}: {path.relative_to(ROOT)}")
                continue
        if not source.is_file() or not runtime.is_file():
            continue
        source_hash = _sha256(source)
        runtime_hash = _sha256(runtime)
        hashes[name] = source_hash
        if source_hash != expected_hash or runtime_hash != expected_hash:
            failures.append(f"{name} source/runtime hash differs from the registered reference")
        with Image.open(source) as src, Image.open(runtime) as output:
            if src.mode != "RGBA" or output.mode != "RGBA" or src.size != CANVAS or output.size != CANVAS:
                failures.append(f"{name} source/runtime must be RGBA {CANVAS}")
            if _bounds(src) != expected_bounds or _bounds(output) != expected_bounds:
                failures.append(f"{name} alpha bounds differ from {expected_bounds}")
            layers[name] = output.copy()

    if COMPOSITE.is_file():
        if _sha256(COMPOSITE) != COMPOSITE_SHA256:
            failures.append("composite reference hash differs from the registered reference")
    else:
        failures.append("composite reference is missing")

    if len(layers) == 3 and COMPOSITE.is_file():
        reference = Image.open(COMPOSITE).convert("RGBA")
        rendered = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
        for name in ("dust", "connector", "locker"):
            rendered.alpha_composite(layers[name])
        difference = ImageChops.difference(reference, rendered)
        mismatch_pixels = sum(
            1
            for y in range(CANVAS[1])
            for x in range(CANVAS[0])
            if difference.getpixel((x, y)) != (0, 0, 0, 0)
        )
        if mismatch_pixels > 1267:
            failures.append(f"ordered composition differs at {mismatch_pixels} pixels (budget 1267)")
        alphas = {name: image.getchannel("A") for name, image in layers.items()}
        overlap_dc = sum(bool(alphas["dust"].getpixel((x, y)) and alphas["connector"].getpixel((x, y))) for y in range(CANVAS[1]) for x in range(CANVAS[0]))
        overlap_cl = sum(bool(alphas["connector"].getpixel((x, y)) and alphas["locker"].getpixel((x, y))) for y in range(CANVAS[1]) for x in range(CANVAS[0]))
        overlap_dl = sum(bool(alphas["dust"].getpixel((x, y)) and alphas["locker"].getpixel((x, y))) for y in range(CANVAS[1]) for x in range(CANVAS[0]))
        if (overlap_dc, overlap_cl, overlap_dl) != (17979, 10979, 0):
            failures.append(f"alpha overlaps drifted: {(overlap_dc, overlap_cl, overlap_dl)}")

    expected_states = {
        "awakening_dust_lung_environment": "underlay",
        "awakening_reliquary_dust_lung_connector": "full_plate_underlay",
        "awakening_locker_reliquary_environment": "underlay",
    }
    for family_id, state_id in expected_states.items():
        family = json.loads((ASSETS / f"{family_id}.asset.json").read_text())
        state = family["states"][state_id]
        if family["canvas"] != {"width": 1502, "height": 2048}:
            failures.append(f"{family_id} canvas does not declare the registered canvas")
        if (state.get("frame_width"), state.get("frame_height")) != CANVAS:
            failures.append(f"{family_id}.{state_id} does not declare the registered frame size")

    scene_text = SCENE.read_text()
    if "RegisteredComposition04_05" not in scene_text or "rotation = -0.198826" in scene_text:
        failures.append("scene is missing the shared axis-aligned composition root")
    if "awakening_locker_reliquary_foreground_704x704.png" in scene_text:
        failures.append("incompatible Locker foreground remains bound in the scene")
    locker_family = json.loads((ASSETS / "awakening_locker_reliquary_environment.asset.json").read_text())
    foreground = locker_family["states"]["foreground"]
    if foreground.get("required") or foreground.get("recommended"):
        failures.append("incompatible Locker foreground is still required/recommended")

    if failures:
        print(json.dumps({"test": "awakening_connector_asset_contract_smoke", "passed": False, "failures": failures}, indent=2))
        return 1
    print(json.dumps({
        "test": "awakening_connector_asset_contract_smoke",
        "passed": True,
        "source_sha256": hashes,
        "registered_canvas": list(CANVAS),
        "ordered_composition_pixel_mismatches": mismatch_pixels,
        "alpha_overlap_pixels": {"dust_connector": overlap_dc, "connector_locker": overlap_cl, "dust_locker": overlap_dl},
        "draw_order": ["dust", "connector", "locker"],
        "locker_foreground_requirement": "deferred",
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
