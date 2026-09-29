#!/usr/bin/env python3
"""Prove operator_ingest.sh forwards --profile/--strict to sync_operator_runtime_assets.py.

Runs the wrapper in its default dry-run mode (no writes) with `--skip-inbox` so only
the sync step executes, once with `--profile unarmed --strict` and once with neither.
Checks, from the bash trace, that the sync invocation's arguments differ exactly by
those two flags, and, from the sync tool's own reported count, that scoping to one
profile actually narrows the synchronized set rather than merely accepting the flags.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
INGEST_SH = "custodian/tools/operator/operator_ingest.sh"

SYNC_TRACE_RE = re.compile(
    r"sync_operator_runtime_assets\.py[^\n]*"
)
SYNCHRONIZED_COUNT_RE = re.compile(
    r"synchronized (\d+) Operator runtime sheets"
)


def _run_ingest(*extra_args: str) -> str:
    # The wrapper does `exec > >(tee ...) 2>&1` internally, which remaps its own
    # stderr (including our -x xtrace) into the same stream as its stdout. Capture
    # both together rather than relying on a stderr/stdout split.
    result = subprocess.run(
        ["bash", "-x", str(ROOT / INGEST_SH), "--dry-run", "--skip-inbox", *extra_args],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=60,
    )
    return result.stdout


def _last_sync_trace_line(trace: str) -> str | None:
    matches = SYNC_TRACE_RE.findall(trace)
    return matches[-1] if matches else None


def main() -> int:
    errors: list[str] = []

    scoped_output = _run_ingest("--profile", "unarmed", "--strict")
    plain_output = _run_ingest()

    scoped_line = _last_sync_trace_line(scoped_output)
    plain_line = _last_sync_trace_line(plain_output)

    if scoped_line is None:
        errors.append("could not find a sync_operator_runtime_assets.py trace line for the scoped run")
    elif "--profile unarmed" not in scoped_line or "--strict" not in scoped_line:
        errors.append(f"scoped run did not forward --profile unarmed --strict: {scoped_line!r}")

    if plain_line is None:
        errors.append("could not find a sync_operator_runtime_assets.py trace line for the plain run")
    elif "--profile" in plain_line or "--strict" in plain_line:
        errors.append(f"plain run unexpectedly forwarded --profile/--strict: {plain_line!r}")

    scoped_count_match = SYNCHRONIZED_COUNT_RE.search(scoped_output)
    plain_count_match = SYNCHRONIZED_COUNT_RE.search(plain_output)
    if scoped_count_match is None:
        errors.append("scoped run produced no 'synchronized N Operator runtime sheets' line")
    if plain_count_match is None:
        errors.append("plain run produced no 'synchronized N Operator runtime sheets' line")
    if scoped_count_match and plain_count_match:
        scoped_count = int(scoped_count_match.group(1))
        plain_count = int(plain_count_match.group(1))
        if not (0 < scoped_count < plain_count):
            errors.append(
                f"--profile unarmed did not narrow the synchronized set: scoped={scoped_count} "
                f"plain={plain_count} (expected 0 < scoped < plain)"
            )

    if errors:
        for error in errors:
            print(f"FAIL: {error}")
        return 1

    print(
        "operator_ingest_wrapper_smoke: PASS "
        f"scoped={scoped_count_match.group(1)} plain={plain_count_match.group(1)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
