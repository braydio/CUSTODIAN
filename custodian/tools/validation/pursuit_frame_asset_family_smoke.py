#!/usr/bin/env python3
"""Focused acceptance for the non-blocking Pursuit Frame animation intake."""
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

from PIL import Image

TOOLS = Path(__file__).resolve().parents[1] / "assets"
sys.path.insert(0, str(TOOLS))

from asset_contract import load_family  # noqa: E402
from asset_plan import generate_plan  # noqa: E402
from asset_status import get_family_status  # noqa: E402

REPO = Path(__file__).resolve().parents[3]
FAMILY_PATH = REPO / "custodian/content/metadata/assets/families/pursuit_frame.asset.json"

EXPECTED = {
    "idle_ready_01": ("posture", "s", 4),
    "patrol_walk_01": ("locomotion", "s", 8),
    "patrol_scan_01": ("activity", "s", 6),
    "checkpoint_halt_01": ("activity", "s", 4),
    "notice_01": ("combat", "s", 4),
    "pursuit_run_01": ("locomotion", "s", 8),
    "intercept_windup_01": ("combat", "e", 4),
    "intercept_burst_01": ("combat", "e", 4),
    "intercept_recover_01": ("combat", "e", 5),
    "melee_brace_01": ("combat", "e", 6),
}


def _strip(path: Path, frames: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGBA", (96 * frames, 96), (0, 0, 0, 0))
    for frame in range(frames):
        image.putpixel((frame * 96 + 12, 24), (40 + frame, 90, 130, 255))
    image.save(path)


def main() -> int:
    family = load_family(FAMILY_PATH)
    assert family.id == "pursuit_frame"
    assert family.kind == "enemy"
    assert family.auto_mirror
    assert (family.frame_width, family.frame_height) == (96, 96)
    assert set(family.states) == set(EXPECTED)

    for state_id, (group, direction, frames) in EXPECTED.items():
        state = family.states[state_id]
        assert not state.required and state.recommended
        assert state.action_group == group
        assert state.required_directions == (direction,)
        assert state.expected_frames == frames
        assert state.layout == "horizontal_strip"

    with tempfile.TemporaryDirectory(prefix="pursuit-frame-family-") as tmp:
        project = Path(tmp) / "custodian"
        inbox = project / "asset_drop/inbox/pursuit_frame"

        missing = generate_plan(family, inbox, project)
        assert missing.can_apply and not missing.assets and not missing.errors
        status = get_family_status(family, project)
        assert status.completeness == "0/0 required"
        assert len(status.recommended_states) == 10

        for state_id, (_, direction, frames) in EXPECTED.items():
            _strip(inbox / f"{state_id}__{direction}.png", frames)

        plan = generate_plan(family, inbox, project)
        assert plan.can_apply, plan.errors
        assert len(plan.assets) == 10
        assert len(plan.outputs) == 14  # Six south sheets plus four authored E/mirrored W pairs.
        for output in plan.outputs:
            path = output.target_relative_path.as_posix()
            assert path.startswith("content/sprites/enemies/pursuit_frame/runtime/body/")
            assert output.key.frame_width == 96 and output.key.frame_height == 96

        bad_state = "intercept_recover_01"
        _strip(inbox / f"{bad_state}__e.png", 4)
        bad = generate_plan(family, inbox, project)
        assert not bad.can_apply
        assert any("requires exactly 5 frames" in error for error in bad.errors)

    print("[PASS] Pursuit Frame Asset Pipeline V2 family")
    print("  missing animations: non-blocking")
    print("  authored inputs: 10")
    print("  planned outputs with E/W mirroring: 14")
    print("  exact frame contracts: enforced when supplied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
