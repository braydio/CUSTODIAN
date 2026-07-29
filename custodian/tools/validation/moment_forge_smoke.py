#!/usr/bin/env python3
"""Compatibility entry point for the focused Moment Forge Python checks."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CHECKS = (
    "moment_forge_schema_smoke.py",
    "moment_forge_changed_router_smoke.py",
    "moment_forge_report_smoke.py",
)


def main() -> int:
    for check in CHECKS:
        completed = subprocess.run(
            [sys.executable, str(Path(__file__).with_name(check))],
            cwd=ROOT,
            check=False,
        )
        if completed.returncode:
            return completed.returncode
    print("Moment Forge Python smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
