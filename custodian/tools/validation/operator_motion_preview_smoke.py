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

# --- Continuous treadmill loop semantics ------------------------------------
# 10 frames @ 10 FPS -> a 1.0s animation cycle; 128px LINEAR travel per cycle.
# TREADMILL world travel must accumulate across cycles instead of resetting
# every time the sprite loops, while the sprite itself keeps looping cleanly.
tread = MotionConfig(identity, 10.0, 128.0, "linear", "e", mode="treadmill", frame_count=10)


def continuous_px(elapsed: float) -> float:
    return sample_motion(tread, elapsed, loop=True).continuous_position_px


assert abs(continuous_px(0.99) - 128.0) < 2.0
assert continuous_px(1.01) > 128.0
assert abs(continuous_px(1.50) - 192.0) < 1e-6
assert abs(continuous_px(2.00) - 256.0) < 1e-6

# Ground displacement must never jump toward zero across a cycle boundary.
boundary_before = sample_motion(tread, 0.999, loop=True)
boundary_after = sample_motion(tread, 1.001, loop=True)
assert boundary_after.continuous_position_px > boundary_before.continuous_position_px
assert boundary_after.cycle_index == boundary_before.cycle_index + 1

# The sprite still loops: the animation frame wraps from the final frame back
# to frame zero even though cumulative world travel keeps climbing. This
# proves sprite looping and world continuity are independent.
assert sample_motion(tread, 0.99, loop=True).frame_index == 9
assert sample_motion(tread, 1.0, loop=True).frame_index == 0
assert sample_motion(tread, 1.01, loop=True).frame_index == 0

with tempfile.TemporaryDirectory(prefix="operator_motion_treadmill_") as raw:
    root = Path(raw); sentinel = root / "runtime.png"
    Image.new("RGBA", (8, 8), (255, 0, 0, 255)).save(sentinel)
    tread_frames = tuple(Image.open(sentinel).convert("RGBA") for _ in range(10))
    renderer = MotionPreviewRenderer(root, tread_frames, "grid32")
    before_frame = renderer.render(tread, 0.999, loop=True)
    after_frame = renderer.render(tread, 1.001, loop=True)
    ground_before = -before_frame.sample.continuous_root_displacement[0]
    ground_after = -after_frame.sample.continuous_root_displacement[0]
    assert ground_after < ground_before, "ground scrolled backward across a cycle boundary"

with tempfile.TemporaryDirectory(prefix="operator_motion_readonly_") as raw:
    root = Path(raw); sentinel = root / "runtime.png"
    Image.new("RGBA", (8, 8), (255, 0, 0, 255)).save(sentinel)
    before = digest_tree(root)
    renderer = MotionPreviewRenderer(root, (Image.open(sentinel).convert("RGBA"),), "grid32")
    rendered = renderer.render(MotionConfig(identity, 10, 64, "attack_lunge", "e", frame_count=1), 0.05, loop=False)
    assert rendered.image.mode == "RGBA" and rendered.image.size == (768, 384)
    assert digest_tree(root) == before

print("operator_motion_preview_smoke ok")
