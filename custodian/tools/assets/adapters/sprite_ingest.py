"""Animated sprite adapter delegating manifests to the mature Godot ingest backend."""
from __future__ import annotations
import json
import shutil
import subprocess
import sys
from pathlib import Path

ASSETS_DIR = Path(__file__).resolve().parents[1]
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_plan import AssetOperation, PlannedAsset
from adapters.backend_result import BackendResult


def build_manifest(planned: PlannedAsset, staged_source: Path) -> dict:
    output = planned.target_relative_path.relative_to("content/sprites").as_posix()
    manifest = {
        "source": staged_source.name,
        "mode": "strip" if planned.inspection.layout.value == "horizontal_strip" else "grid",
        "frame_size": [planned.inspection.frame_width, planned.inspection.frame_height],
        "outputs": [{"path": output, "layout": "horizontal_strip"}],
        "auto_mirror": False,
    }
    if planned.inspection.layout.value == "grid":
        manifest.update(columns=planned.inspection.columns, rows=planned.inspection.rows)
    return manifest


def stage_asset(planned: PlannedAsset, project_dir: Path, *, dry_run: bool = False,
                replace: bool = False, work_dir: Path | None = None) -> BackendResult:
    target = project_dir / planned.target_relative_path
    if planned.operation == AssetOperation.CONFLICT:
        return BackendResult(False, planned.operation, [], [f"unsafe target conflict: {target}"])
    if planned.operation == AssetOperation.REPLACE and not replace:
        return BackendResult(False, planned.operation, [], [f"replacement requires --replace: {target}"])
    if planned.operation == AssetOperation.DUPLICATE:
        return BackendResult(True, planned.operation, [target], [])
    if dry_run:
        return BackendResult(True, planned.operation, [target], [])
    if work_dir is None:
        return BackendResult(False, planned.operation, [], ["sprite backend requires transaction staging"])
    staged_source = work_dir / planned.canonical_filename
    manifest_path = staged_source.with_suffix(".json")
    shutil.copy2(planned.source_path, staged_source)
    manifest_path.write_text(json.dumps(build_manifest(planned, staged_source), indent=2) + "\n", encoding="utf-8")
    command = [sys.executable, str(project_dir / "tools/pipelines/ingest.py"), "--manifest", str(manifest_path), "--no-mirror"]
    result = subprocess.run(command, cwd=project_dir.parent, capture_output=True, text=True, check=False)
    if result.returncode != 0 or not target.exists():
        detail = (result.stderr or result.stdout or "sprite ingest produced no output").strip()
        return BackendResult(False, planned.operation, [], [detail[-1000:]])
    return BackendResult(True, planned.operation, [target], [])
