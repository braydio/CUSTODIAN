"""Sprite ingest adapter — wraps the existing sprite pipeline for animated assets."""

from __future__ import annotations

import hashlib
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parents[1]
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_plan import PlannedAsset


@dataclass
class BackendResult:
    ok: bool
    outputs: list[Path]
    errors: list[str]


def stage_asset(
    planned: PlannedAsset,
    project_dir: Path,
    *,
    dry_run: bool = False,
    replace: bool = False,
) -> BackendResult:
    """Stage an animated asset to its runtime target.

    For multi-frame assets, copies the source as-is to the canonical location.
    The existing sprite pipeline (generate_inbox_manifests -> ingest -> ingest_runtime)
    handles frame splitting when invoked separately.

    This adapter provides the V2 planning/orchestration layer and delegates
    the heavy lifting to existing backends for actual frame processing.
    """
    target = project_dir / planned.target_relative_path
    source = planned.source_path

    if target.exists() and not replace:
        h_src = _hash(source)
        h_tgt = _hash(target)
        if h_src == h_tgt:
            return BackendResult(ok=True, outputs=[target], errors=[])
        if not planned.replacement:
            return BackendResult(
                ok=False,
                outputs=[],
                errors=[f"target exists with different content: {target} (use --replace)"],
            )

    if dry_run:
        return BackendResult(ok=True, outputs=[target], errors=[])

    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)

    return BackendResult(ok=True, outputs=[target], errors=[])


def _hash(path: Path) -> str:
    import hashlib
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()
