#!/usr/bin/env python3
"""Refuse project-wide Godot imports while checked-out LFS pointers remain."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


POINTER_HEADER = b"version https://git-lfs.github.com/spec/v1"
SIDECAR_ISSUES = {
    "invalid": "valid=false",
    "path": "missing remap path",
    "dest_files": "missing remap destination",
}


def _section(text: str, name: str) -> str:
    match = re.search(rf"(?ms)^\[{re.escape(name)}\]\s*\n(.*?)(?=^\[|\Z)", text)
    return match.group(1) if match else ""


def _sidecar_metadata(sidecar: Path) -> tuple[str | None, str | None, list[str], list[str]]:
    """Read the source, UID and generated remap destinations from a PNG sidecar."""
    try:
        text = sidecar.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return None, None, [], ["unreadable sidecar"]
    remap = _section(text, "remap")
    deps = _section(text, "deps")
    source_match = re.search(r'^source_file\s*=\s*"res://([^"\n]+)"\s*$', deps, re.M)
    uid_match = re.search(r'^uid\s*=\s*"([^"]+)"\s*$', remap, re.M)
    path_match = re.search(r'^path\s*=\s*"(res://[^"\n]+)"\s*$', remap, re.M)
    dest_match = re.search(r"(?ms)^dest_files\s*=\s*\[(.*?)\]\s*$", deps)
    destinations = re.findall(r'"(res://[^"\n]+)"', dest_match.group(1)) if dest_match else []
    issues: list[str] = []
    if re.search(r"^valid\s*=\s*false\s*$", remap, re.M):
        issues.append(SIDECAR_ISSUES["invalid"])
    if not path_match:
        issues.append(SIDECAR_ISSUES["path"])
    if not destinations:
        issues.append(SIDECAR_ISSUES["dest_files"])
    return source_match.group(1) if source_match else None, uid_match.group(1) if uid_match else None, destinations, issues


def _tracked_project_paths(repository_root: Path, project_dir: Path) -> tuple[list[str], str | None]:
    try:
        project_rel = project_dir.resolve().relative_to(repository_root.resolve()).as_posix()
    except ValueError:
        return [], "Godot project is outside the Git repository"
    result = subprocess.run(
        ["git", "-C", str(repository_root), "ls-files", "--", project_rel],
        capture_output=True, text=True, check=False,
    )
    if result.returncode:
        return [], result.stderr.strip() or "git ls-files failed"
    return [line for line in result.stdout.splitlines() if line.endswith(".png.import")], None


def _referenced_sidecars(repository_root: Path, project_dir: Path, malformed: dict[str, tuple[str | None, str | None]]) -> set[str]:
    """Keep only malformed tracked sidecars referenced by a tracked project text file."""
    needles: dict[str, str] = {}
    for sidecar, (source, uid) in malformed.items():
        if source:
            needles[f"res://{source}"] = sidecar
        if uid:
            needles[uid] = sidecar
    if not needles:
        return set()
    try:
        project_rel = project_dir.resolve().relative_to(repository_root.resolve()).as_posix()
    except ValueError:
        return set()
    command = ["git", "-C", str(repository_root), "grep", "-I", "-n", "-F"]
    for needle in needles:
        command.extend(("-e", needle))
    command.extend(("--", project_rel))
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip() or "git grep failed while checking PNG import references")
    referenced: set[str] = set()
    for line in result.stdout.splitlines():
        # A .png.import's own source_file/UID is metadata, not a project consumer.
        file_path, _, remainder = line.partition(":")
        _line_number, _, content = remainder.partition(":")
        if file_path.endswith(".png.import"):
            continue
        for needle, sidecar in needles.items():
            if needle in content:
                referenced.add(sidecar)
    return referenced


def invalid_referenced_png_sidecars(repository_root: Path, project_dir: Path, tracked_paths: list[str]) -> list[tuple[Path, list[str]]]:
    malformed: dict[str, tuple[str | None, str | None]] = {}
    details: dict[str, list[str]] = {}
    for relative in tracked_paths:
        if not relative.endswith(".png.import"):
            continue
        source, uid, _destinations, issues = _sidecar_metadata(repository_root / relative)
        if issues:
            malformed[relative] = (source, uid)
            details[relative] = issues
    referenced = _referenced_sidecars(repository_root, project_dir, malformed)
    return [
        (repository_root / relative, details[relative])
        for relative in sorted(referenced)
    ]


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
    if repository_root is not None:
        tracked_paths, tracked_error = _tracked_project_paths(repository_root, project_dir)
        if tracked_error:
            return f"cannot inspect tracked PNG import sidecars: {tracked_error}"
        try:
            invalid = invalid_referenced_png_sidecars(repository_root, project_dir, tracked_paths)
        except (OSError, RuntimeError) as error:
            return f"cannot inspect tracked PNG import sidecars: {error}"
        if invalid:
            listed = [f"  {path.relative_to(repository_root)} ({', '.join(issues)})" for path, issues in invalid[:30]]
            if len(invalid) > 30:
                listed.append(f"  ... and {len(invalid) - 30} more")
            return "refusing project import; referenced tracked PNG sidecars have invalid remap metadata:\n" + "\n".join(listed)
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
