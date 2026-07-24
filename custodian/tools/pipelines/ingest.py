#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
OPERATOR_RUNTIME_BUILDER = SCRIPT_DIR / "build_operator_modular_runtime.py"
USAGE = """\
Usage: python custodian/tools/pipelines/ingest.py [options]

Options:
  --manifest PATH             Process one manifest (repeatable).
  --dry-run                   Preview ingest and requested builds without writing.
  --skip-post                 Skip manifest post-process hooks.
  --no-mirror                 Do not generate horizontal direction counterparts.
  --remove-superseded         Remove older canonical sibling outputs.
  --build-operator-runtime    Rebuild Operator modular runtime after successful ingest.
  -h, --help                  Show this help.
"""


def main() -> int:
    forwarded_args: list[str] = []
    build_operator_runtime = False
    index = 0
    raw_args = sys.argv[1:]
    while index < len(raw_args):
        arg = raw_args[index]
        if arg in ("-h", "--help"):
            print(USAGE)
            return 0
        if arg == "--build-operator-runtime":
            build_operator_runtime = True
            index += 1
            continue
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
        "--log-file",
        str(PROJECT_DIR / ".godot" / "sprite_pipeline_ingest.log"),
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
    if result.returncode != 0 or not build_operator_runtime:
        return result.returncode

    builder_args = [sys.executable, str(OPERATOR_RUNTIME_BUILDER)]
    if "--dry-run" in forwarded_args:
        builder_args.append("--dry-run")
    if "--remove-superseded" in forwarded_args:
        builder_args.append("--remove-superseded")
    return subprocess.run(builder_args, cwd=PROJECT_DIR, check=False).returncode


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
