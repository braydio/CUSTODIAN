#!/usr/bin/env python3
"""Verify the exact Carrow marble perimeter crop handoff; never modify input."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

MASTER_HASH = "132525dc9487b56b2b62d244bcf580786f654bb17c03832a1ec6cb6422c83c95"
CUTS = {
    "wall_marble_ew_straight_01": ((0, 505, 805, 1189), (0, 505), (805, 684),
        "af152f20218ee342c15ce8e51e28a95e936900d31271a82c7f4a31c565613368"),
    "wall_marble_ns_straight_01": ((820, 0, 1312, 505), (820, 0), (492, 505),
        "68e8d14f24baf0e46496df6fd2ea9e0ccb06b1d56d1551c66512c18db42d65c2"),
    "wall_marble_corner_ne_01": ((805, 505, 1312, 1189), (805, 505), (507, 684),
        "f9074c4b64baa5301c3d74261e1dafa078a55ba3ac78e1176200e8dd4c487032"),
}

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def verify(root: Path) -> None:
    manifest = json.loads((root / "MANIFEST.json").read_text())
    assert manifest["schema"] == "custodian.asset_handoff.v1"
    assert manifest["family_id"] == "carrow_yard_perimeter_walls_v1"
    assert set(row["state_id"] for row in manifest["assets"]) == set(CUTS)
    master = root / "reference/masters/image_20261021_031639_clean_ne_master.png"
    assert sha(master) == MASTER_HASH, "Original source master hash changed"
    original = Image.open(master).convert("RGBA")
    assert original.size == (1312, 1199)
    pixels = bytearray(original.tobytes())
    for i in range(0, len(pixels), 4):
        if pixels[i + 3] <= 3:
            pixels[i:i+4] = b"\0\0\0\0"
    cleaned = Image.frombytes("RGBA", original.size, bytes(pixels))
    rebuilt = Image.new("RGBA", original.size, (0, 0, 0, 0))
    by_state = {r["state_id"]: r for r in manifest["assets"]}
    for state, (rect, xy, size, digest) in CUTS.items():
        row = by_state[state]
        assert tuple(row["source_rect_xyxy"]) == rect
        assert tuple(row["placement_xy"]) == xy
        assert row["review_status"] == "SOURCE_READY_NEEDS_TUNE"
        assert row["install_inbox"] is False
        assert row["install_source"] is True
        source = root / row["package_source"]
        assert source.is_file() and sha(source) == digest, f"{state}: source SHA mismatch"
        assert source.stat().st_size == row["source_size_bytes"]
        layer = Image.open(source).convert("RGBA")
        assert layer.size == size
        assert layer.tobytes() == cleaned.crop(rect).tobytes(), f"{state}: wrong slice pixels"
        rebuilt.alpha_composite(layer, xy)
        print(f"PASS {state} {size[0]}x{size[1]} SHA-256 {digest}")
    assert rebuilt.tobytes() == cleaned.tobytes(), "Original L reconstructed incorrectly"
    print("PASS exact clean-master reconstruction; NO runtime tileability proven")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("package_root", type=Path)
    verify(ap.parse_args().package_root.resolve())
