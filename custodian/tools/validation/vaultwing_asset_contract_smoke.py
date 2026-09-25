#!/usr/bin/env python3
"""Validate the published Common Vaultwing 256px Asset V2 runtime family."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError as error:
    raise SystemExit(f"vaultwing_asset_contract_smoke: missing dependency ({error})") from error

CUSTODIAN = Path(__file__).resolve().parents[2]
RUNTIME = CUSTODIAN / "content/sprites/ambient_creatures/vaultwing_common/runtime"
FAMILY = CUSTODIAN / "content/metadata/assets/families/ambient_vaultwing_common.asset.json"
NAME = re.compile(r"^vaultwing_common__([a-z0-9_]+)__([a-z0-9_]+)__([a-z0-9_]+)__([nsew])__(\d+)f__256\.png$")
DIRECTIONS = {"n", "s", "e", "w"}


def main() -> int:
    failures: list[str] = []
    family = json.loads(FAMILY.read_text(encoding="utf-8"))
    if family.get("kind") != "ambient_creature":
        failures.append("family kind must be ambient_creature")
    runtime = family.get("runtime", {})
    if runtime.get("owner") != "vaultwing_common":
        failures.append("family runtime owner must be vaultwing_common")
    states = family.get("states", {})
    expected_actions = set(states)
    strips = sorted(RUNTIME.rglob("*.png"))
    identities: set[tuple[str, str, str]] = set()
    by_action_direction: set[tuple[str, str]] = set()
    for path in strips:
        match = NAME.match(path.name)
        if not match:
            failures.append(f"{path.name}: non-canonical Vaultwing runtime name")
            continue
        layer, group, action, direction, frames = match.groups()
        frames_i = int(frames)
        identity = (layer, action, direction)
        if identity in identities:
            failures.append(f"{path.name}: duplicate semantic identity {identity}")
        identities.add(identity)
        by_action_direction.add((action, direction))
        if action not in expected_actions:
            failures.append(f"{path.name}: action is absent from family contract")
            continue
        declared = int(states[action].get("frames", 0))
        if layer != states[action].get("layer") or group != states[action].get("action_group"):
            failures.append(f"{path.name}: layer/action_group do not match family metadata")
        if frames_i != declared:
            failures.append(f"{path.name}: filename {frames_i}f != family {declared}f")
        image = Image.open(path)
        if image.mode != "RGBA":
            failures.append(f"{path.name}: mode {image.mode} is not RGBA")
            image = image.convert("RGBA")
        if image.height != 256 or image.width != frames_i * 256:
            failures.append(f"{path.name}: geometry {image.width}x{image.height} != {frames_i * 256}x256")
            continue
        alpha = np.asarray(image.getchannel("A"))
        if alpha.min() > 0:
            failures.append(f"{path.name}: no transparent background pixels")
        for index in range(frames_i):
            cell = alpha[:, index * 256:(index + 1) * 256]
            if int((cell > 8).sum()) == 0:
                failures.append(f"{path.name}: frame {index} is empty")
            else:
                ys, xs = np.where(cell > 8)
                if xs.min() == 0 or ys.min() == 0 or xs.max() == 255 or ys.max() == 255:
                    failures.append(f"{path.name}: frame {index} touches cell edge; possible wrong-grid/clip")
    if len(strips) != 56:
        failures.append(f"expected 56 canonical strips, found {len(strips)}")
    for action in sorted(expected_actions):
        state = states[action]
        present_directions = {direction for candidate, direction in by_action_direction if candidate == action}
        # Recommended states may be registered before production art exists.
        # Once any strips are published, validate their declared coverage;
        # required states must always have full or explicitly declared coverage.
        if not state.get("required", False) and not present_directions:
            continue
        required_directions = set(state.get("required_directions", DIRECTIONS))
        for direction in sorted(required_directions):
            if (action, direction) not in by_action_direction:
                failures.append(f"missing {action}::{direction}")
    for path in [CUSTODIAN / "game/actors/ambient/vaultwing", CUSTODIAN / "game/systems/spawning/vaultwing_spawner.gd", CUSTODIAN / "scenes"]:
        for script in ([path] if path.is_file() else list(path.rglob("*.gd"))):
            text = script.read_text(encoding="utf-8")
            if "asset_drop/inbox" in text or "asset_drop/source_work" in text:
                failures.append(f"{script.relative_to(CUSTODIAN)}: runtime references source/inbox art")
    print(f"vaultwing_asset_contract_smoke: {len(strips)} strips, {len(by_action_direction)} action/direction pairs")
    result = {"schema": "custodian.headless_test.result.v1", "test": "vaultwing_asset_contract_smoke", "passed": not failures, "failure_count": len(failures), "failures": failures}
    print("CUSTODIAN_TEST_RESULT_JSON:" + json.dumps(result, sort_keys=True))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
