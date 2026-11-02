"""Read-only .blend inspection routed through Blender and shared rig signatures."""
from __future__ import annotations

import json
import pathlib
import subprocess

from .glb import ModelToSpriteError, _regular_file, sha256_file
from .pipeline import BLENDER_RENDER_SCRIPT, _blender_path, _blender_version, REPO_ROOT


INSPECT_SCRIPT = pathlib.Path(__file__).resolve().parent / "inspect_blend.py"


def inspect_blend(input_path: str | pathlib.Path, *, blender_executable: str | None = None) -> dict:
    source = _regular_file(pathlib.Path(input_path))
    if source.suffix.lower() != ".blend":
        raise ModelToSpriteError("INPUT_FORMAT_INVALID", "blend inspection requires a .blend file")
    blender = _blender_path(blender_executable)
    try:
        version = _blender_version(blender)
    except ModelToSpriteError:
        raise
    import tempfile

    with tempfile.TemporaryDirectory(prefix="custodian-blend-inspect-") as temp:
        output = pathlib.Path(temp) / "inspection.json"
        command = [blender, "-b", "--python", str(INSPECT_SCRIPT), "--", str(source), str(output)]
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=600, check=False)
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise ModelToSpriteError("BLEND_INSPECTION_FAILED", "Blender could not inspect the master") from exc
        lines = [line.partition(":")[2] for line in result.stdout.splitlines()
                 if line.startswith("MODEL_TO_SPRITE_BLEND_INSPECTION_JSON:")]
        failures = [line.partition(":")[2] for line in result.stdout.splitlines()
                    if line.startswith("MODEL_TO_SPRITE_BLEND_ERROR:")]
        if result.returncode or not lines or not output.is_file():
            raise ModelToSpriteError("BLEND_INSPECTION_FAILED", failures[-1] if failures else (result.stderr + result.stdout).strip()[-1000:])
        try:
            report = json.loads(output.read_text(encoding="utf-8"))
            # Confirm the Blender process that performed the read matches the queried binary.
            report["blender_binary"] = version
            report["source"]["sha256"] = sha256_file(source)
            return report
        except (OSError, json.JSONDecodeError) as exc:
            raise ModelToSpriteError("BLEND_INSPECTION_FAILED", "Blender inspection report was invalid") from exc
