#!/usr/bin/env python3
"""Install repository-owned Codex custom prompts into CODEX_HOME/prompts.

Codex currently discovers custom slash prompts from the user-level prompt
directory, not from a project-local .codex/prompts directory. Keep the prompt
source versioned in this repository and install symlinks so updates follow main.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path


def prompt_source_dir() -> Path:
    return Path(__file__).resolve().parent / "prompts"


def codex_prompt_dir() -> Path:
    codex_home = Path(os.environ.get("CODEX_HOME", "~/.codex")).expanduser()
    return codex_home / "prompts"


def desired_links() -> list[tuple[Path, Path]]:
    source = prompt_source_dir()
    destination = codex_prompt_dir()
    return [(item.resolve(), destination / item.name) for item in sorted(source.glob("*.md"))]


def _same_link(destination: Path, source: Path) -> bool:
    if not destination.is_symlink():
        return False
    try:
        return destination.resolve(strict=False) == source
    except OSError:
        return False


def install(*, check: bool, force: bool) -> int:
    links = desired_links()
    if not links:
        print(f"NO PROMPTS: {prompt_source_dir()}")
        return 1

    destination_root = codex_prompt_dir()
    failures: list[str] = []

    if not check:
        destination_root.mkdir(parents=True, exist_ok=True)

    for source, destination in links:
        if _same_link(destination, source):
            print(f"OK {destination} -> {source}")
            continue

        if destination.exists() or destination.is_symlink():
            if check:
                failures.append(f"{destination}: not linked to {source}")
                continue
            if not force:
                failures.append(
                    f"{destination}: existing file/link differs; rerun with --force only if it is safe to replace"
                )
                continue
            destination.unlink()

        if check:
            failures.append(f"{destination}: missing")
            continue

        destination.symlink_to(source)
        print(f"INSTALLED {destination} -> {source}")

    if failures:
        for failure in failures:
            print(f"BLOCKED {failure}")
        return 2

    if check:
        print("codex prompt links: PASS")
    else:
        print("Restart Codex, then use /prompts:custodian-next")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify links without modifying anything")
    parser.add_argument(
        "--force",
        action="store_true",
        help="replace an existing conflicting prompt file/symlink",
    )
    args = parser.parse_args()
    return install(check=args.check, force=args.force)


if __name__ == "__main__":
    raise SystemExit(main())
