"""Animated sprite adapter delegating manifests to the mature Godot ingest backend."""
from __future__ import annotations
import json
import shutil
import subprocess
import sys
from pathlib import Path
from PIL import Image

ASSETS_DIR = Path(__file__).resolve().parents[1]
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_plan import AssetOperation, PlannedAsset
from adapters.backend_result import BackendResult


def build_manifest(planned: PlannedAsset, staged_source: Path) -> dict:
    authored = next(output for output in planned.outputs if output.provenance == "authored")
    output = authored.target_relative_path.relative_to("content/sprites").as_posix()
    mode = "grid" if planned.inspection.layout.value == "grid" else ("copy" if planned.inspection.frame_count == 1 else "strip")
    manifest = {
        "source": staged_source.name,
        "mode": mode,
        "frame_size": [planned.inspection.frame_width, planned.inspection.frame_height],
        "outputs": [{"path": output, "layout": "horizontal_strip"}],
        "auto_mirror": any(item.provenance == "mirrored" for item in planned.outputs),
        "post_process": list(planned.post_process),
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
    if planned.operation == AssetOperation.DUPLICATE and all(
        output.operation == AssetOperation.DUPLICATE for output in planned.outputs
    ):
        return BackendResult(True, planned.operation, [project_dir / output.target_relative_path for output in planned.outputs], [])
    if dry_run:
        return BackendResult(True, planned.operation, [target], [])
    if work_dir is None:
        return BackendResult(False, planned.operation, [], ["sprite backend requires transaction staging"])
    # The mature backend normally retains archive/preview/log compatibility
    # artifacts. V2 owns its source archive and receipt, so use a job-unique
    # basename and remove those bounded backend artifacts after delegation.
    staged_source = work_dir / f"{work_dir.name}__{planned.canonical_filename}"
    manifest_path = staged_source.with_suffix(".json")
    if planned.inspection.layout.value == "vertical_strip":
        _normalize_vertical(planned, staged_source)
    else:
        shutil.copy2(planned.source_path, staged_source)
    manifest_path.write_text(json.dumps(build_manifest(planned, staged_source), indent=2) + "\n", encoding="utf-8")
    command = [sys.executable, str(project_dir / "tools/pipelines/ingest.py"), "--manifest", str(manifest_path)]
    if not any(item.provenance == "mirrored" for item in planned.outputs): command.append("--no-mirror")
    try:
        result = subprocess.run(command, cwd=project_dir.parent, capture_output=True, text=True, check=False)
    finally:
        _cleanup_backend_compatibility_outputs(project_dir, staged_source.stem)
    expected=[project_dir/output.target_relative_path for output in planned.outputs]
    if result.returncode != 0 or any(not output.exists() for output in expected):
        detail = (result.stderr or result.stdout or "sprite ingest produced no output").strip()
        return BackendResult(False, planned.operation, [], [detail[-1000:]])
    return BackendResult(True, planned.operation, expected, [])


def _cleanup_backend_compatibility_outputs(project_dir: Path, basename: str) -> None:
    pipeline = project_dir / "content/sprites/_pipeline"
    for path in (
        pipeline / "archive" / f"{basename}.png",
        pipeline / "archive" / f"{basename}.json",
        pipeline / "normalized" / f"{basename}.png",
        pipeline / "logs" / f"{basename}.log.json",
    ):
        if path.is_file():
            path.unlink()


def _normalize_vertical(planned: PlannedAsset, destination: Path) -> None:
    fw,fh=planned.inspection.frame_width,planned.inspection.frame_height
    with Image.open(planned.source_path) as source:
        source=source.convert("RGBA")
        output=Image.new("RGBA",(fw*planned.inspection.frame_count,fh))
        for index in range(planned.inspection.frame_count):
            output.paste(source.crop((0,index*fh,fw,(index+1)*fh)),(index*fw,0))
        output.save(destination)
