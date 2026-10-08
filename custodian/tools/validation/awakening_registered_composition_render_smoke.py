#!/usr/bin/env python3
"""Run the registered-composition viewport smoke with a real X11 renderer."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = "res://tools/validation/awakening_registered_composition_render_smoke.gd"


def main() -> int:
    command = [
        "xvfb-run",
        "-a",
        "godot",
        "--path",
        str(ROOT),
        "--rendering-method",
        "gl_compatibility",
        "--audio-driver",
        "Dummy",
        "--script",
        SCRIPT,
    ]
    result = subprocess.run(command, cwd=ROOT, check=False)
    if result.returncode:
        print(
            f"registered composition renderer smoke failed with exit {result.returncode}",
            file=sys.stderr,
        )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
