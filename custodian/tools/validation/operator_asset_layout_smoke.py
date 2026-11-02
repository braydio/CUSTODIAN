#!/usr/bin/env python3
from __future__ import annotations

import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "tools/pipelines"))
from operator_asset_schema import parse_filename, semantic_identity
import operator_runtime_path_audit


def main() -> int:
    errors = []
    runtime = PROJECT_ROOT / "content/sprites/operator/runtime"
    if {path.name for path in runtime.iterdir() if path.is_dir()} != {"animations"}:
        errors.append("Operator runtime must contain only animations/")
    seen = defaultdict(list)
    synchronized = defaultdict(dict)
    for path in sorted((runtime / "animations").rglob("*.png")):
        try:
            key = parse_filename(path)
            with Image.open(path) as image:
                if image.size != (key.frames * key.frame_width, key.frame_height):
                    errors.append(f"dimension mismatch: {path}")
            seen[semantic_identity(key)].append(path)
            synchronized[(key.animation_profile, key.action_group, key.action, key.direction)][key.layer] = key
        except Exception as exc:
            errors.append(f"{path}: {exc}")
    for identity, paths in seen.items():
        if len(paths) > 1:
            errors.append(f"superseded semantic siblings {identity}: {paths}")
    for identity, layers in synchronized.items():
        if "lower_body" in layers and "upper_body" in layers and layers["lower_body"].frames != layers["upper_body"].frames:
            errors.append(f"synchronized frame mismatch {identity}")
    if operator_runtime_path_audit.main() != 0:
        errors.append("runtime path audit failed")
    if errors:
        print("\n".join(errors))
        return 1
    print(f"operator asset layout smoke passed ({sum(len(paths) for paths in seen.values())} runtime sheets)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
