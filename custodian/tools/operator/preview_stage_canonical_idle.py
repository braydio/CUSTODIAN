#!/usr/bin/env python3
"""Copy the accepted canonical Operator idle sheet into one dev-preview boundary.

This is a byte-preserving preview copier. It is not an Asset Pipeline V2 intake,
runtime publisher, approval step, or replacement for the canonical source.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil
import sys

from PIL import Image

SOURCE_REL = Path(
    "asset_drop/source_work/operator/operator_2_5d_first_animation/"
    "unarmed_posture_idle_relaxed_01_full_body_v1_source.png"
)
DEST_REL = Path(
    "game/world/levels/authored/dev/sepulcher_material_operator_v2/preview/"
    "operator_2_5d_idle_relaxed_8dir_15f_128.png"
)
EXPECTED_SHA256 = "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3"
EXPECTED_SIZE = (1920, 1024)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_png(path: Path) -> None:
    with Image.open(path) as image:
        if image.format != "PNG" or image.mode != "RGBA" or image.size != EXPECTED_SIZE:
            raise ValueError(
                f"expected RGBA {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]} PNG; "
                f"received {image.format} {image.mode} {image.size}"
            )
        image.verify()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--custodian", type=Path, required=True, help="checkout custodian/ directory")
    parser.add_argument("--source", type=Path, help="pinned accepted source; defaults to source_work path")
    parser.add_argument("--install", action="store_true", help="install verified dev-only copy (default: dry run)")
    args = parser.parse_args()

    custodian = args.custodian.expanduser().resolve(strict=True)
    if not (custodian / "project.godot").is_file():
        raise ValueError(f"not a CUSTODIAN Godot project: {custodian}")
    source = (args.source or (custodian / SOURCE_REL)).expanduser().resolve(strict=True)
    target = custodian / DEST_REL
    if source == target or not source.is_file():
        raise ValueError("source must be the pinned source-work PNG, not the preview destination")
    if target.is_symlink():
        raise ValueError("refusing symlinked preview destination")
    validate_png(source)
    source_hash = sha256(source)
    if source_hash != EXPECTED_SHA256:
        raise ValueError(f"source SHA-256 mismatch: {source_hash}")

    if target.exists():
        if not target.is_file() or sha256(target) != EXPECTED_SHA256:
            raise ValueError("existing preview conflicts with the pinned source; refusing overwrite")
        validate_png(target)
        print(f"PASS: byte-identical dev preview already staged: {target}")
        return 0
    if not args.install:
        print(f"DRY RUN: verified accepted preview source {source} => {target}")
        return 0

    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.parent.resolve().is_relative_to(custodian / "game/world/levels/authored/dev/sepulcher_material_operator_v2"):
        raise ValueError("preview destination escaped its declared development scene")
    created = False
    try:
        with source.open("rb") as input_stream:
            with target.open("xb") as output_stream:
                created = True
                shutil.copyfileobj(input_stream, output_stream)
        if sha256(target) != EXPECTED_SHA256:
            raise ValueError("installed preview does not match pinned source SHA-256")
        validate_png(target)
    except BaseException:
        if created:
            target.unlink(missing_ok=True)
        raise
    print(f"STAGED DEV-ONLY canonical idle preview: {target}")
    print("NO runtime SpriteFrames, Asset V2 family, source approval, or animation timing was changed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"BLOCKED: {error}", file=sys.stderr)
        raise SystemExit(2)
