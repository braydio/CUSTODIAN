#!/usr/bin/env python3
"""Validate tracked/staged paths for Windows-compatible filenames.

Default mode checks staged paths for pre-commit use. Pass --all to scan every
tracked path, which is what CI uses.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import PurePosixPath


INVALID_CHARS = re.compile(r'[<>:"\\|?*\x00-\x1f]')
RESERVED_NAMES = {
    "CON",
    "PRN",
    "AUX",
    "NUL",
    *(f"COM{i}" for i in range(1, 10)),
    *(f"LPT{i}" for i in range(1, 10)),
}


def run_git(*args: str) -> bytes:
    result = subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        message = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(message or f"git {' '.join(args)} failed")
    return result.stdout


def decode_nul_paths(raw: bytes) -> list[str]:
    return [os.fsdecode(path) for path in raw.split(b"\0") if path]


def paths_to_check(check_all: bool) -> list[str]:
    if check_all:
        return decode_nul_paths(run_git("ls-files", "-z"))

    return decode_nul_paths(
        run_git(
            "diff",
            "--cached",
            "--name-only",
            "--diff-filter=ACMR",
            "-z",
        )
    )


def validate_component(component: str) -> list[str]:
    problems: list[str] = []

    invalid = sorted(set(INVALID_CHARS.findall(component)))
    if invalid:
        rendered = ", ".join(repr(char) for char in invalid)
        problems.append(f"contains Windows-invalid character(s): {rendered}")

    if component.endswith(" "):
        problems.append("ends with a space")

    if component.endswith("."):
        problems.append("ends with a period")

    stem = component.split(".", 1)[0].rstrip(" .").upper()
    if stem in RESERVED_NAMES:
        problems.append(f"uses Windows-reserved filename '{stem}'")

    return problems


def find_case_collisions(paths: list[str]) -> list[tuple[str, str]]:
    """Return tracked paths that differ only by case.

    Windows' default filesystem is case-insensitive, so both paths cannot be
    represented safely in the same checkout.
    """

    seen: dict[str, str] = {}
    collisions: list[tuple[str, str]] = []

    for path in paths:
        key = path.casefold()
        previous = seen.get(key)
        if previous is not None and previous != path:
            collisions.append((previous, path))
        else:
            seen[key] = path

    return collisions


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Reject repository paths that cannot be checked out safely on Windows."
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="check every tracked path instead of only staged paths",
    )
    args = parser.parse_args()

    try:
        paths = paths_to_check(args.all)
    except RuntimeError as exc:
        print(f"ERROR: could not enumerate Git paths: {exc}", file=sys.stderr)
        return 2

    failures: list[tuple[str, str]] = []
    for path in paths:
        for component in PurePosixPath(path).parts:
            for problem in validate_component(component):
                failures.append((path, problem))

    # In whole-repository mode, also catch case-only collisions among all
    # tracked files. Staged-only mode intentionally stays fast and focused.
    collisions = find_case_collisions(paths) if args.all else []

    if not failures and not collisions:
        scope = "tracked" if args.all else "staged"
        print(f"OK: all {scope} paths are Windows-compatible.")
        return 0

    print("ERROR: Windows-incompatible repository paths detected.", file=sys.stderr)
    print(file=sys.stderr)

    for path, problem in failures:
        print(f"  {path}", file=sys.stderr)
        print(f"    -> {problem}", file=sys.stderr)
        print(file=sys.stderr)

    for first, second in collisions:
        print("  Case-insensitive path collision:", file=sys.stderr)
        print(f"    {first}", file=sys.stderr)
        print(f"    {second}", file=sys.stderr)
        print(file=sys.stderr)

    print(
        "Rename these paths before committing/merging. "
        "Use portable names that work on Windows, macOS, and Linux.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
