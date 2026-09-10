"""Godot import adapter — triggers Godot's import pipeline for new assets."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

# A cold full-project import routinely runs past two minutes, so the default has
# to leave room for one. This is the single authority for the import timeout;
# `asset ingest --godot-import-timeout` overrides it per run.
DEFAULT_GODOT_IMPORT_TIMEOUT_SEC = 300


@dataclass
class ImportResult:
    ok: bool
    detail: str


def run_godot_import(
    project_dir: Path,
    timeout_sec: float = DEFAULT_GODOT_IMPORT_TIMEOUT_SEC,
) -> ImportResult:
    """Run `godot --headless --import` to process newly placed assets."""
    godot_bin = _find_godot()
    if godot_bin is None:
        return ImportResult(ok=False, detail="godot binary not found on PATH")

    try:
        result = subprocess.run(
            [godot_bin, "--headless", "--path", str(project_dir), "--import", "--quit"],
            capture_output=True,
            text=True,
            timeout=timeout_sec,
        )
        if result.returncode == 0:
            return ImportResult(ok=True, detail="godot import succeeded")
        return ImportResult(
            ok=False,
            detail=f"godot exited {result.returncode}: {result.stderr[:500]}",
        )
    except subprocess.TimeoutExpired:
        return ImportResult(
            ok=False,
            detail=f"godot import timed out ({_format_timeout(timeout_sec)}s)",
        )
    except FileNotFoundError:
        return ImportResult(ok=False, detail="godot binary not found")


def _format_timeout(timeout_sec: float) -> str:
    """Render whole seconds without a trailing .0 so messages read naturally."""
    return str(int(timeout_sec)) if float(timeout_sec).is_integer() else str(timeout_sec)


def _find_godot() -> str | None:
    import shutil
    return shutil.which("godot")
