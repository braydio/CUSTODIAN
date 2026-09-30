#!/usr/bin/env python3
"""Refuse project-wide Godot imports while checked-out LFS pointers remain."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


POINTER_HEADER = b"version https://git-lfs.github.com/spec/v1"


def unmaterialized_lfs_paths(
    repository_root: Path, project_dir: Path, listed_paths: list[str]
) -> list[Path]:
    """Return present Git LFS paths that still contain pointer text."""
    result: list[Path] = []
    project_dir = project_dir.resolve()
    for relative in listed_paths:
        source = repository_root / relative
        try:
            source.resolve().relative_to(project_dir)
        except ValueError:
            continue  # LFS assets outside this Godot project cannot be imported here.
        if not source.is_file():
            continue  # Sparse-omitted assets are not inputs to this checkout.
        try:
            with source.open("rb") as stream:
                header = stream.read(len(POINTER_HEADER))
        except OSError:
            continue
        if header == POINTER_HEADER:
            result.append(source)
    return result


def inspect_project(project_dir: Path) -> tuple[Path | None, list[Path], str | None]:
    project_dir = project_dir.resolve()
    if not any((parent / ".git").exists() for parent in (project_dir, *project_dir.parents)):
        return None, [], None  # Standalone Godot projects have no Git LFS index.

    root_result = subprocess.run(
        ["git", "-C", str(project_dir), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if root_result.returncode != 0:
        return None, [], root_result.stderr.strip() or "git rev-parse failed"

    repository_root = Path(root_result.stdout.strip()).resolve()
    lfs_result = subprocess.run(
        ["git", "-C", str(repository_root), "lfs", "ls-files", "--name-only"],
        capture_output=True,
        text=True,
        check=False,
    )
    if lfs_result.returncode != 0:
        detail = lfs_result.stderr.strip() or "git lfs ls-files failed"
        return repository_root, [], detail

    paths = [line for line in lfs_result.stdout.splitlines() if line]
    return repository_root, unmaterialized_lfs_paths(repository_root, project_dir, paths), None


def preflight_detail(project_dir: Path) -> str | None:
    """Return a blocking explanation, or None when project-wide import is safe."""
    repository_root, pointers, error = inspect_project(project_dir)
    if error:
        return f"cannot inspect Git LFS files: {error}"
    if pointers and repository_root is not None:
        listed = [f"  {path.relative_to(repository_root)}" for path in pointers[:30]]
        if len(pointers) > 30:
            listed.append(f"  ... and {len(pointers) - 30} more")
        return "materialize checked-out Git LFS files before importing:\n" + "\n".join(listed)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--project-dir",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Godot project directory (defaults to custodian/)",
    )
    args = parser.parse_args()

    if not any(
        (parent / ".git").exists()
        for parent in (args.project_dir.resolve(), *args.project_dir.resolve().parents)
    ):
        print("godot_import_preflight: no Git repository; LFS check skipped")
        return 0
    detail = preflight_detail(args.project_dir.resolve())
    if detail:
        error = detail.startswith("cannot inspect Git LFS files:")
        print(
            "godot_import_preflight: "
            + (detail if error else f"refusing project import; {detail} (for example, git lfs checkout)"),
            file=sys.stderr,
        )
        return 2 if error else 1

    print("godot_import_preflight: PASS (no checked-out LFS pointers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
