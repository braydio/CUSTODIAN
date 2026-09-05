#!/usr/bin/env python3
"""Pure, non-mutating Motion Lab model regression coverage."""
from __future__ import annotations

import hashlib
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))
from animation_motion_preview import (MotionConfig, MotionPreviewRenderer, curve_progress,
                                      ground_phase, sample_motion, scrub_motion)
from animation_preview import SemanticIdentity


def digest_tree(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        digest.update(str(path.relative_to(root)).encode()); digest.update(path.read_bytes())
    return digest.hexdigest()


identity = SemanticIdentity("melee_1h", "attack", "lunge_01", "e")
linear = MotionConfig(identity, 10.0, 100.0, "linear", "e", frame_count=10)
half = sample_motion(linear, 0.5)
assert half.root_displacement == (50.0, 0.0)
assert half.ground_displacement == (-50.0, -0.0)
assert sample_motion(linear, 1.0).position_px == 100.0
west = sample_motion(MotionConfig(identity, 10, 100, "linear", "w", frame_count=10), 0.5)
assert west.root_displacement == (-half.root_displacement[0], -half.root_displacement[1])
assert sample_motion(linear, 1.0, loop=True).position_px == 0.0
assert scrub_motion(linear, 0.75) == sample_motion(linear, 0.75)
fast = MotionConfig(identity, 20, 100, "linear", "e", frame_count=10)
assert sample_motion(fast, 0).duration_sec == 0.5
assert sample_motion(fast, 0).average_speed == 200.0
assert sample_motion(fast, 0.5).position_px == 100.0
values = [curve_progress("attack_lunge", step / 100) for step in range(101)]
assert values[0] == 0.0 and values[-1] == 1.0
assert all(left <= right for left, right in zip(values, values[1:]))
assert ground_phase((-33.2, -65.0), (32, 32)) == (30, 31)

with tempfile.TemporaryDirectory(prefix="operator_motion_readonly_") as raw:
    root = Path(raw); sentinel = root / "runtime.png"
    Image.new("RGBA", (8, 8), (255, 0, 0, 255)).save(sentinel)
    before = digest_tree(root)
    renderer = MotionPreviewRenderer(root, (Image.open(sentinel).convert("RGBA"),), "grid32")
    rendered = renderer.render(MotionConfig(identity, 10, 64, "attack_lunge", "e", frame_count=1), 0.05, loop=False)
    assert rendered.image.mode == "RGBA" and rendered.image.size == (768, 384)
    assert digest_tree(root) == before

print("operator_motion_preview_smoke ok")
