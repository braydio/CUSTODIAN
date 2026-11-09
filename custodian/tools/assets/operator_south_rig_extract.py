#!/usr/bin/env python3
"""Repository entry point for the pinned South Operator source-work extractor."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import sys

sys.dont_write_bytecode = True


ROOT = Path(__file__).resolve().parents[3]
SOURCE_SCRIPT = (
    ROOT
    / "custodian/asset_drop/source_work/operator/motion_foundry/"
    / "operator_south_visible_surface_v1/scripts/extract_operator_south_rig.py"
)


def _load_source_script():
    spec = importlib.util.spec_from_file_location("operator_south_rig_sourcework", SOURCE_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load pinned source-work extractor: {SOURCE_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_extractor = _load_source_script()
write_outputs = _extractor.write_outputs
sha = _extractor.sha


def main() -> int:
    return _extractor.main()


if __name__ == "__main__":
    raise SystemExit(main())
