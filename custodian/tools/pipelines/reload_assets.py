#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent


def main() -> int:
    compatibility = subprocess.run(
        [sys.executable, str(SCRIPT_DIR / "update_operator_compatibility_resources.py")],
        capture_output=True,
        text=True,
        check=False,
    )
    if compatibility.stdout:
        print(compatibility.stdout, end="")
    if compatibility.stderr:
        print(compatibility.stderr, file=sys.stderr, end="")
    if compatibility.returncode != 0:
        return compatibility.returncode
    command = [
        "godot",
        "--headless",
        "--path",
        str(PROJECT_DIR),
        "--script",
        "res://tools/pipelines/build_operator_animation_resources.gd",
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
