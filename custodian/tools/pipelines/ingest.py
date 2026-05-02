#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent


def main() -> int:
    forwarded_args: list[str] = []
    index = 0
    raw_args = sys.argv[1:]
    while index < len(raw_args):
        arg = raw_args[index]
        forwarded_args.append(arg)
        if arg == "--manifest" and index + 1 < len(raw_args):
            index += 1
            forwarded_args.append(_normalize_manifest_arg(raw_args[index]))
        index += 1

    args = [
        "godot",
        "--headless",
        "--path",
        str(PROJECT_DIR),
        "--script",
        "res://tools/pipelines/ingest_runtime.gd",
        "--",
        *forwarded_args,
    ]
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    return result.returncode


def _normalize_manifest_arg(value: str) -> str:
    if value.startswith("res://"):
        return value

    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = (Path.cwd() / candidate).resolve()
    else:
        candidate = candidate.resolve()

    try:
        relative = candidate.relative_to(PROJECT_DIR)
    except ValueError:
        return str(candidate)

    return "res://" + relative.as_posix()


if __name__ == "__main__":
    raise SystemExit(main())
