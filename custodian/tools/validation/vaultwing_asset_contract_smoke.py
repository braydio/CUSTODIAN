#!/usr/bin/env python3
"""Validate the published Common Vaultwing 256px Asset V2 runtime family."""
from __future__ import annotations

import json
import re
import sys
import tempfile
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


def validate_family(
    family: dict,
    runtime_root: Path,
    custodian_root: Path | None = None,
) -> tuple[list[str], dict[str, str]]:
    failures: list[str] = []
    if family.get("kind") != "ambient_creature":
        failures.append("family kind must be ambient_creature")
    runtime = family.get("runtime", {})
    owner = str(runtime.get("owner", ""))
    if owner != "vaultwing_common":
        failures.append("family runtime owner must be vaultwing_common")
    states = family.get("states", {})
    directions = {"n", "s", "e", "w", "omni"}
    strips = sorted(runtime_root.rglob("*.png"))
    identities: set[tuple[str, str, str]] = set()
    by_action_direction: dict[str, set[str]] = {action: set() for action in states}
    for path in strips:
        match = NAME.match(path.name)
        if not match:
            failures.append(f"{path.name}: non-canonical Vaultwing runtime name")
            continue
        layer, group, action, direction, frames = match.groups()
        if direction not in directions:
            failures.append(f"{path.name}: unknown direction {direction}")
            continue
        frames_i = int(frames)
        identity = (layer, action, direction)
        if identity in identities:
            failures.append(f"{path.name}: duplicate semantic identity {identity}")
        identities.add(identity)
        if action not in states:
            failures.append(f"{path.name}: action is absent from family contract")
            continue
        state = states[action]
        by_action_direction[action].add(direction)
        declared = int(state.get("frames", 0))
        if layer != state.get("layer") or group != state.get("action_group"):
            failures.append(f"{path.name}: layer/action_group do not match family metadata")
        if action != state.get("variant", action):
            failures.append(f"{path.name}: variant does not match family metadata")
        if frames_i != declared:
            failures.append(f"{path.name}: filename {frames_i}f != family {declared}f")
        image = Image.open(path)
        if image.mode != "RGBA":
            failures.append(f"{path.name}: mode {image.mode} is not RGBA")
            continue
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
    coverage: dict[str, str] = {}
    for action, state in sorted(states.items()):
        present = by_action_direction[action]
        declared = set(state.get("required_directions", DIRECTIONS))
        if state.get("required", False):
            required_directions = declared
        else:
            # Recommended coverage is advisory; the Asset V2 status command owns
            # READY/PARTIAL/MISSING reporting. Every strip present was validated
            # above, but later directions must not fail this validator.
            required_directions = set()
            coverage[action] = "missing" if not present else (
                "ready" if declared.issubset(present) else "partial"
            )
        if state.get("required", False):
            coverage[action] = "ready" if declared.issubset(present) else "partial"
        for direction in sorted(required_directions):
            if direction not in present:
                failures.append(f"missing {action}::{direction}")
    if custodian_root is not None:
        for path in [custodian_root / "game/actors/ambient/vaultwing", custodian_root / "game/systems/spawning/vaultwing_spawner.gd", custodian_root / "scenes"]:
            for script in ([path] if path.is_file() else list(path.rglob("*.gd"))):
                text = script.read_text(encoding="utf-8")
                if "asset_drop/inbox" in text or "asset_drop/source_work" in text:
                    failures.append(f"{script.relative_to(custodian_root)}: runtime references source/inbox art")
    return failures, coverage


def _write_strip(path: Path, action: str, direction: str, frames: int, malformed: str = "") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    width = frames * 256
    height = 256
    mode = "RGBA"
    if malformed == "size":
        width -= 1
    image = Image.new(mode, (width, height), (0, 0, 0, 0))
    for index in range(frames):
        x0 = index * 256 + 32
        image.alpha_composite(Image.new("RGBA", (36, 60), (120, 80, 40, 255)), (x0, 120))
    if malformed == "opaque":
        image = Image.new("RGBA", image.size, (40, 30, 20, 255))
    group = "bonding" if action in {"feed_accept", "notice_bait", "guarded_approach", "inspect_bait", "watch_player", "bond_greet"} else "locomotion"
    image.save(path.parent / f"vaultwing_common__body__{group}__{action}__{direction}__{frames}f__256.png")


def run_regressions() -> list[str]:
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="vaultwing_asset_contract_") as temporary:
        root = Path(temporary)
        family = {
            "kind": "ambient_creature",
            "runtime": {"owner": "vaultwing_common"},
            "states": {
                "required_idle": {
                    "required": True, "layer": "body", "action_group": "locomotion",
                    "variant": "required_idle", "frames": 1, "required_directions": ["e", "n", "s"],
                },
                "feed_accept": {
                    "recommended": True, "layer": "body", "action_group": "bonding",
                    "variant": "feed_accept", "frames": 2, "required_directions": ["e", "n", "s"],
                },
            },
        }
        partial_root = root / "partial"
        _write_strip(partial_root / "unused.png", "required_idle", "e", 1)
        _write_strip(partial_root / "unused.png", "required_idle", "n", 1)
        _write_strip(partial_root / "unused.png", "required_idle", "s", 1)
        _write_strip(partial_root / "unused.png", "feed_accept", "e", 2)
        _write_strip(partial_root / "unused.png", "feed_accept", "w", 2)
        errors, coverage = validate_family(family, partial_root)
        if errors:
            failures.append(f"partial recommended coverage rejected: {errors}")
        if coverage.get("feed_accept") != "partial":
            failures.append(f"partial recommended art not reported partial: {coverage}")

        malformed_root = root / "malformed"
        _write_strip(malformed_root / "unused.png", "required_idle", "e", 1)
        _write_strip(malformed_root / "unused.png", "required_idle", "n", 1)
        _write_strip(malformed_root / "unused.png", "required_idle", "s", 1)
        _write_strip(malformed_root / "unused.png", "feed_accept", "e", 2, malformed="size")
        malformed_errors, _ = validate_family(family, malformed_root)
        if not any("geometry" in error for error in malformed_errors):
            failures.append("malformed present recommended strip was not rejected")

        lost_required_root = root / "lost_required"
        _write_strip(lost_required_root / "unused.png", "required_idle", "e", 1)
        _write_strip(lost_required_root / "unused.png", "feed_accept", "e", 2)
        lost_errors, _ = validate_family(family, lost_required_root)
        missing_required = {f"missing required_idle::{direction}" for direction in ("n", "s")}
        if not missing_required.issubset(set(lost_errors)):
            failures.append(f"required direction loss was not rejected: {lost_errors}")

        unknown_root = root / "unknown"
        _write_strip(unknown_root / "unused.png", "required_idle", "e", 1)
        _write_strip(unknown_root / "unused.png", "required_idle", "n", 1)
        _write_strip(unknown_root / "unused.png", "required_idle", "s", 1)
        unknown_path = unknown_root / "body" / "vaultwing_common__body__locomotion__required_idle__q__1f__256.png"
        unknown_path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", (256, 256), (0, 0, 0, 0)).save(unknown_path)
        unknown_errors, _ = validate_family(family, unknown_root)
        if not any("non-canonical" in error for error in unknown_errors):
            failures.append("unknown direction was not rejected")

        unknown_action_root = root / "unknown_action"
        _write_strip(unknown_action_root / "unused.png", "required_idle", "e", 1)
        _write_strip(unknown_action_root / "unused.png", "required_idle", "n", 1)
        _write_strip(unknown_action_root / "unused.png", "required_idle", "s", 1)
        unknown_action_path = unknown_action_root / "body" / "vaultwing_common__body__bonding__unknown_action__e__2f__256.png"
        unknown_action_path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGBA", (512, 256), (0, 0, 0, 0)).save(unknown_action_path)
        unknown_action_errors, _ = validate_family(family, unknown_action_root)
        if not any("absent from family contract" in error for error in unknown_action_errors):
            failures.append("unknown action was not rejected")
    return failures


def main() -> int:
    family = json.loads(FAMILY.read_text(encoding="utf-8"))
    failures, coverage = validate_family(family, RUNTIME, CUSTODIAN)
    failures.extend(run_regressions())
    strips = sorted(RUNTIME.rglob("*.png"))
    action_direction_count = len({
        (match.group(3), match.group(4))
        for path in strips
        if (match := NAME.match(path.name))
    })
    print(f"vaultwing_asset_contract_smoke: {len(strips)} strips, {action_direction_count} action/direction pairs")
    print("vaultwing_asset_contract_smoke coverage: " + json.dumps(coverage, sort_keys=True))
    print("vaultwing_asset_contract_smoke regressions: partial recommended, malformed present, required-direction loss, unknown direction")
    result = {"schema": "custodian.headless_test.result.v1", "test": "vaultwing_asset_contract_smoke", "passed": not failures, "failure_count": len(failures), "failures": failures}
    print("CUSTODIAN_TEST_RESULT_JSON:" + json.dumps(result, sort_keys=True))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
