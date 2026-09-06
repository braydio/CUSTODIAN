#!/usr/bin/env python3
"""Validate the published Baby Opossum runtime strips against the pixel contract.

Reads only; never mutates assets. Runtime output must satisfy:

  * RGBA PNG with real transparent pixels (no matte, no checkerboard)
  * 96px frame height, width an exact multiple of 96
  * the ``<N>f`` filename token equal to the real frame count
  * one pose per cell (no strip sliced on the wrong frame grid)
  * a layer/action/direction identity that is unique across layers
  * every ``barrel_prop`` clip paired with a ``body`` clip of equal duration

Quality judgements about the art itself are deliberately out of scope.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
    from scipy import ndimage as ndi
except ImportError as error:  # pragma: no cover - environment guard
    sys.exit(f"baby_opossum_asset_contract_smoke: missing dependency ({error})")

CUSTODIAN = Path(__file__).resolve().parents[2]
RUNTIME = CUSTODIAN / "content/sprites/ambient_creatures/baby_opossum/runtime"
FAMILY = CUSTODIAN / "content/metadata/assets/families/ambient_baby_opossum.asset.json"
CELL = 96
ALPHA_FLOOR = 8
VALID_DIRECTIONS = {"omni", "n", "ne", "e", "se", "s", "sw", "w", "nw"}
# Same separation thresholds the staging tool uses; see
# tools/assets/stage_baby_opossum_source_work.py for the measurements behind them.
MAX_SECONDARY_BLOB_RATIO = 0.06
MAX_POSE_DRIFT_PX = 22.0


def parse_name(path: Path) -> dict[str, object] | None:
    parts = path.stem.split("__")
    if len(parts) != 7 or parts[0] != "baby_opossum":
        return None
    _, layer, group, variant, direction, frames_token, size_token = parts
    if direction not in VALID_DIRECTIONS or not frames_token.endswith("f"):
        return None
    return {
        "layer": layer,
        "action_group": group,
        "action": variant,
        "direction": direction,
        "frames": int(frames_token[:-1]),
        "size": size_token,
    }


def check_pixels(path: Path, declared_frames: int, failures: list[str]) -> None:
    image = Image.open(path)
    if image.mode != "RGBA":
        failures.append(f"{path.name}: mode {image.mode} is not RGBA")
        image = image.convert("RGBA")
    if image.height != CELL:
        failures.append(f"{path.name}: height {image.height} != {CELL}")
        return
    if image.width % CELL:
        failures.append(f"{path.name}: width {image.width} is not a multiple of {CELL}")
        return
    frames = image.width // CELL
    if frames != declared_frames:
        failures.append(f"{path.name}: filename declares {declared_frames}f but holds {frames} frames")
    alpha = np.asarray(image.getchannel("A"))
    if alpha.min() > ALPHA_FLOOR:
        failures.append(f"{path.name}: no transparent pixels (matte or opaque background)")
    content = alpha > ALPHA_FLOOR
    centres: list[float] = []
    for index in range(frames):
        cell = content[:, index * CELL:(index + 1) * CELL]
        labels, count = ndi.label(cell)
        if not count:
            failures.append(f"{path.name}: frame {index} is empty")
            continue
        areas = np.asarray(ndi.sum(cell, labels, range(1, count + 1)))
        order = np.argsort(areas)[::-1]
        xs = np.nonzero(labels == order[0] + 1)[1]
        centres.append((int(xs.min()) + int(xs.max())) / 2.0)
        if len(order) > 1:
            ratio = areas[order[1]] / areas[order[0]]
            if ratio >= MAX_SECONDARY_BLOB_RATIO:
                failures.append(
                    f"{path.name}: frame {index} holds a second pose fragment "
                    f"({ratio:.0%} of the main pose) — sliced on the wrong frame grid"
                )
    if len(centres) > 1:
        drift = max(centres) - min(centres)
        if drift >= MAX_POSE_DRIFT_PX:
            failures.append(f"{path.name}: pose drifts {drift:.0f}px across the strip")


def main() -> int:
    failures: list[str] = []
    if not RUNTIME.exists():
        print("baby_opossum_asset_contract_smoke: no runtime directory; nothing published yet")
        return 0

    family = json.loads(FAMILY.read_text(encoding="utf-8"))
    contract_fps = {
        (str(state.get("layer", "body")), str(state.get("variant", state_id))): state.get("fps")
        for state_id, state in family.get("states", {}).items()
    }

    clips: dict[tuple[str, str, str], dict[str, object]] = {}
    strips = sorted(RUNTIME.rglob("*.png"))
    for path in strips:
        parsed = parse_name(path)
        if parsed is None:
            failures.append(f"{path.name}: not a canonical Asset V2 filename")
            continue
        identity = (str(parsed["layer"]), str(parsed["action"]), str(parsed["direction"]))
        if identity in clips:
            failures.append(f"{path.name}: duplicate identity {identity}")
        clips[identity] = parsed
        if (str(parsed["layer"]), str(parsed["action"])) not in contract_fps:
            failures.append(
                f"{path.name}: layer/action {parsed['layer']}/{parsed['action']} "
                "has no matching family state"
            )
        if parsed["size"] != str(CELL):
            failures.append(f"{path.name}: cell size token {parsed['size']} != {CELL}")
        check_pixels(path, int(parsed["frames"]), failures)

    # A body and a prop clip may share a semantic action but never a runtime identity.
    for (layer, action, direction), parsed in clips.items():
        if layer == "body":
            continue
        body = clips.get(("body", action, direction)) or clips.get(("body", action, "s"))
        if body is None:
            failures.append(f"{action}/{direction}: {layer} clip has no body counterpart")
            continue
        body_fps = contract_fps.get(("body", action)) or 8
        prop_fps = contract_fps.get((layer, action)) or 8
        body_duration = int(body["frames"]) / float(body_fps)
        prop_duration = int(parsed["frames"]) / float(prop_fps)
        if abs(body_duration - prop_duration) > 0.01:
            failures.append(
                f"{action}: body runs {body_duration:.3f}s but {layer} runs {prop_duration:.3f}s"
            )

    layers: dict[str, int] = {}
    for layer, _, _ in clips:
        layers[layer] = layers.get(layer, 0) + 1
    print(
        "baby_opossum_asset_contract_smoke: %d strips, layers=%s"
        % (len(strips), ", ".join(f"{k}={v}" for k, v in sorted(layers.items())) or "none")
    )
    print("CUSTODIAN_TEST_RESULT_JSON:" + json.dumps({
        "schema": "custodian.headless_test.result.v1",
        "test": "baby_opossum_asset_contract_smoke",
        "passed": not failures,
        "failure_count": len(failures),
        "failures": failures,
    }, sort_keys=True))
    if failures:
        print(f"baby_opossum_asset_contract_smoke: FAIL ({len(failures)})")
        for message in failures:
            print(f"  - {message}")
        return 1
    print("baby_opossum_asset_contract_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
