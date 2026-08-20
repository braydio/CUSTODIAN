"""Runtime-ready adapter delegating execution to the mature backend."""
from __future__ import annotations
import sys
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parents[1]
PIPELINES_DIR = ASSETS_DIR.parent / "pipelines"
for directory in (ASSETS_DIR, PIPELINES_DIR):
    if str(directory) not in sys.path:
        sys.path.insert(0, str(directory))

from asset_plan import AssetOperation, PlannedAsset
from adapters.backend_result import BackendResult
from runtime_ready_assets import route_asset


def stage_asset(planned: PlannedAsset, project_dir: Path, *, dry_run: bool = False,
                replace: bool = False, work_dir: Path | None = None) -> BackendResult:
    target = project_dir / planned.target_relative_path
    if planned.operation == AssetOperation.CONFLICT:
        return BackendResult(False, planned.operation, [], [f"unsafe target conflict: {target}"])
    if planned.operation == AssetOperation.REPLACE and not replace:
        return BackendResult(False, planned.operation, [], [f"replacement requires --replace: {target}"])
    if planned.operation == AssetOperation.DUPLICATE:
        return BackendResult(True, planned.operation, [target], [])
    result = route_asset(planned.source_path, target, apply=not dry_run, replace=replace)
    if result.status == "rejected":
        return BackendResult(False, planned.operation, [], [result.detail])
    return BackendResult(True, planned.operation, [target], [])
