"""Godot import adapter — triggers Godot's import pipeline for new assets."""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path


@dataclass
class ImportResult:
    ok: bool
    detail: str


def run_godot_import(project_dir: Path) -> ImportResult:
    """Run `godot --headless --import` to process newly placed assets."""
    godot_bin = _find_godot()
    if godot_bin is None:
        return ImportResult(ok=False, detail="godot binary not found on PATH")

    try:
        result = subprocess.run(
            [godot_bin, "--headless", "--path", str(project_dir), "--quit"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode == 0:
            return ImportResult(ok=True, detail="godot import succeeded")
        return ImportResult(
            ok=False,
            detail=f"godot exited {result.returncode}: {result.stderr[:500]}",
        )
    except subprocess.TimeoutExpired:
        return ImportResult(ok=False, detail="godot import timed out (120s)")
    except FileNotFoundError:
        return ImportResult(ok=False, detail="godot binary not found")


def _find_godot() -> str | None:
    import shutil
    return shutil.which("godot")
