#!/usr/bin/env python3
"""Validate the pinned South Operator source-work bundle without publishing art."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[3]
BUNDLE = ROOT / "custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1"
TEST_SCRIPT = BUNDLE / "scripts/test_extract_operator_south_rig.py"
SOURCE = BUNDLE / "source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite"
ENTRY = ROOT / "custodian/tools/assets/operator_south_rig_extract.py"
EXPECTED_ZIP_SHA256 = "ea039bbbf945da4172c61d43a61beea793bf92a0f807c73d363cd7877673bf94"
EXPECTED_SOURCE_SHA256 = "61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3"


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    inventory_path = BUNDLE / "bundle_inventory.json"
    inventory = json.loads(inventory_path.read_text())
    expected = inventory["files"]
    actual = {
        path.relative_to(BUNDLE).as_posix(): file_sha(path)
        for path in BUNDLE.rglob("*")
        if path.is_file() and path != inventory_path and "__pycache__" not in path.parts
    }
    if actual != expected:
        raise SystemExit("source-work bundle does not match bundle_inventory.json")
    if len(actual) != 40 or file_sha(SOURCE) != EXPECTED_SOURCE_SHA256:
        raise SystemExit("source-work bundle or original source identity is unexpected")
    if not (BUNDLE / "asset_handoff_manifest.json").is_file():
        raise SystemExit("source-work provenance manifest is missing")

    result = subprocess.run(
        [sys.executable, str(TEST_SCRIPT)],
        cwd=BUNDLE,
        check=False,
        text=True,
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
    )
    if result.returncode:
        return result.returncode

    with tempfile.TemporaryDirectory(prefix="operator_south_rig_smoke_") as temp:
        out = Path(temp) / "extracted"
        subprocess.run(
            [
                sys.executable,
                str(ENTRY),
                "--source",
                str(SOURCE),
                "--out",
                str(out),
            ],
            cwd=ROOT,
            check=True,
        )
        report = json.loads((out / "segmentation_manifest.json").read_text())
        if report["visible_pixel_count"] != 2440:
            raise SystemExit("unexpected visible-pixel count")
        if report["original_pixel_reassembly_exact"] is not True:
            raise SystemExit("original RGBA reassembly is not exact")
        if report["aseprite_layered_file_roundtrip_exact"] is not True:
            raise SystemExit("layered Aseprite roundtrip is not exact")
        if report["hidden_geometry_reconstructed"] is not False:
            raise SystemExit("source-work output claims reconstructed hidden geometry")

    print(
        json.dumps(
            {
                "status": "ok",
                "bundle_files": len(actual) + 1,
                "source_sha256": EXPECTED_SOURCE_SHA256,
                "pinned_external_zip_sha256": EXPECTED_ZIP_SHA256,
                "source_work_only": True,
                "runtime_or_inbox_changed": False,
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
