#!/usr/bin/env python3
"""Prove LFS pointer detection protects project-wide Godot imports."""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/pipelines"))

from godot_import_preflight import POINTER_HEADER, preflight_detail, unmaterialized_lfs_paths


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="godot-import-preflight-") as temp:
        root = Path(temp)
        project = root / "project"
        project.mkdir()
        pointer = project / "pointer.png"
        image = project / "materialized.png"
        outside_project = root / "outside-pointer.png"
        pointer.write_bytes(POINTER_HEADER + b"\noid sha256:deadbeef\n")
        image.write_bytes(b"\x89PNG\r\n\x1a\nimage bytes")
        outside_project.write_bytes(POINTER_HEADER + b"\noid sha256:deadbeef\n")

        found = unmaterialized_lfs_paths(
            root,
            project,
            [
                "project/pointer.png",
                "project/materialized.png",
                "project/sparse-omitted.png",
                f"{outside_project.name}",
            ],
        )
        if found != [pointer]:
            print(f"FAIL: expected only the LFS pointer, found {found}")
            return 1
        if preflight_detail(project) is not None:
            print("FAIL: standalone project should not require a Git LFS check")
            return 1
        outside_project.unlink()

    print("godot_import_preflight_smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
