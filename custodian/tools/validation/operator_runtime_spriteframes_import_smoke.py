#!/usr/bin/env python3
"""Guard canonical Operator SpriteFrames against invalid texture import sidecars."""

from __future__ import annotations

import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
RESOURCE = REPO_ROOT / "custodian/content/sprites/operator/runtime/operator_runtime_frames.tres"
EXT_RESOURCE_RE = re.compile(r'^\[ext_resource type="Texture2D" path="res://([^\"]+)"', re.MULTILINE)


def main() -> int:
    if not RESOURCE.is_file():
        print(f"FAIL: canonical Operator SpriteFrames resource is missing: {RESOURCE}")
        return 1

    paths = EXT_RESOURCE_RE.findall(RESOURCE.read_text(encoding="utf-8"))
    failures: list[str] = []
    if not paths:
        failures.append("canonical SpriteFrames resource has no external textures")

    for relative in paths:
        # `relative` starts at the project root (content/...), not custodian/.
        source = REPO_ROOT / "custodian" / relative
        sidecar = Path(f"{source}.import")
        if not source.is_file():
            failures.append(f"missing texture source: res://{relative}")
            continue
        if not sidecar.is_file():
            failures.append(f"missing import sidecar: {sidecar.relative_to(REPO_ROOT)}")
            continue
        metadata = sidecar.read_text(encoding="utf-8")
        if re.search(r"^valid=false\s*$", metadata, re.MULTILINE):
            failures.append(f"invalid texture import sidecar: {sidecar.relative_to(REPO_ROOT)}")
        elif not re.search(r"^path=\"res://\.godot/imported/", metadata, re.MULTILINE):
            failures.append(f"sidecar has no imported texture path: {sidecar.relative_to(REPO_ROOT)}")

    if failures:
        print("FAIL: canonical Operator SpriteFrames has invalid texture imports")
        for failure in failures:
            print(f"  {failure}")
        return 1

    print(f"operator_runtime_spriteframes_import_smoke: PASS ({len(paths)} texture imports)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
