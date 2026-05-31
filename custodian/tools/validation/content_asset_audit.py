#!/usr/bin/env python3
"""Report unstable content paths and exact duplicate asset files.

This audit is intentionally read-only. It does not decide that a duplicate is
safe to delete; it only groups byte-identical assets so a migration can update
Godot references and imports deliberately.
"""

from __future__ import annotations

import argparse
import hashlib
from collections import defaultdict
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
CONTENT_ROOT = REPO_ROOT / "custodian" / "content"

HASH_EXTENSIONS = {
    ".ase",
    ".aseprite",
    ".gd",
    ".gif",
    ".json",
    ".png",
    ".tres",
    ".webp",
    ".xcf",
}

ROOT_ALLOWLIST = {
    ".tree-map.txt",
    "README.md",
    "gothic_manifest.game32.json",
    "sundered_keep_manifest.game32.json",
}

INTENTIONAL_DUPLICATE_MARKERS = (
    "/_aseprite/",
    "/_pipeline/archive/",
    "/_pipeline/normalized/",
    "/archive/",
    "/legacy/",
    "/masters/",
    "/reference/",
    "/source/",
)

LOOSE_DOMAIN_DIRS = {
    "sprites",
    "tiles",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit custodian/content for loose files and exact duplicates."
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=30,
        help="Maximum duplicate groups to print. Use 0 for all groups.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit non-zero when unstable loose paths are found.",
    )
    return parser.parse_args()


def rel(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def content_rel(path: Path) -> str:
    return path.relative_to(CONTENT_ROOT).as_posix()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def iter_hashable_files() -> list[Path]:
    files: list[Path] = []
    for path in CONTENT_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() == ".import":
            continue
        if path.suffix.lower() in HASH_EXTENSIONS:
            files.append(path)
    return sorted(files)


def find_root_loose_files() -> list[Path]:
    loose: list[Path] = []
    for path in CONTENT_ROOT.iterdir():
        if not path.is_file():
            continue
        if path.name in ROOT_ALLOWLIST or path.suffix == ".import":
            continue
        loose.append(path)
    return sorted(loose)


def find_loose_domain_files() -> list[Path]:
    loose: list[Path] = []
    for dirname in LOOSE_DOMAIN_DIRS:
        domain = CONTENT_ROOT / dirname
        if not domain.exists():
            continue
        for path in domain.iterdir():
            if path.is_file() and path.name != "README.md" and path.suffix != ".import":
                loose.append(path)
    return sorted(loose)


def duplicate_intent(paths: list[Path]) -> str:
    rel_paths = ["/" + content_rel(path) for path in paths]
    marked = [
        path
        for path in rel_paths
        if any(marker in path for marker in INTENTIONAL_DUPLICATE_MARKERS)
    ]
    if len(marked) == len(rel_paths):
        return "documented-history"
    if marked:
        return "mixed-runtime-history"
    return "needs-review"


def choose_canonical_candidate(paths: list[Path]) -> Path:
    def score(path: Path) -> tuple[int, int, str]:
        path_text = "/" + content_rel(path)
        penalty = 0
        for marker in INTENTIONAL_DUPLICATE_MARKERS:
            if marker in path_text:
                penalty += 10
        if "/runtime/" in path_text:
            penalty -= 3
        if "/sprites/" in path_text or "/tiles/" in path_text or "/props/" in path_text:
            penalty -= 1
        return (penalty, len(path.parts), rel(path))

    return sorted(paths, key=score)[0]


def main() -> int:
    args = parse_args()
    if not CONTENT_ROOT.exists():
        raise SystemExit(f"Missing content root: {CONTENT_ROOT}")

    hashable_files = iter_hashable_files()
    by_hash: dict[str, list[Path]] = defaultdict(list)
    for path in hashable_files:
        by_hash[sha256_file(path)].append(path)

    duplicate_groups = [
        sorted(paths)
        for paths in by_hash.values()
        if len(paths) > 1
    ]
    duplicate_groups.sort(key=lambda group: (-len(group), rel(group[0])))

    root_loose = find_root_loose_files()
    loose_domain = find_loose_domain_files()
    unregistered_files = sorted(
        path
        for path in (CONTENT_ROOT / "unregistered").rglob("*")
        if path.is_file() and path.suffix != ".import"
    )

    duplicate_file_count = sum(len(group) for group in duplicate_groups)
    review_groups = [
        group for group in duplicate_groups if duplicate_intent(group) != "documented-history"
    ]

    print("Content asset audit")
    print(f"content_root: {rel(CONTENT_ROOT)}")
    print(f"hashable_files: {len(hashable_files)}")
    print(f"duplicate_groups: {len(duplicate_groups)}")
    print(f"duplicate_files: {duplicate_file_count}")
    print(f"duplicate_groups_needing_review: {len(review_groups)}")
    print(f"root_loose_files: {len(root_loose)}")
    print(f"loose_sprites_or_tiles_files: {len(loose_domain)}")
    print(f"unregistered_files: {len(unregistered_files)}")

    if root_loose:
        print("\nRoot loose files")
        for path in root_loose:
            print(f"- {rel(path)}")

    if loose_domain:
        print("\nLoose sprite/tile domain files")
        for path in loose_domain:
            print(f"- {rel(path)}")

    if unregistered_files:
        print("\nUnregistered quarantine files")
        for path in unregistered_files:
            print(f"- {rel(path)}")

    if duplicate_groups:
        groups_to_print = duplicate_groups if args.limit == 0 else duplicate_groups[: args.limit]
        print("\nDuplicate groups")
        for index, group in enumerate(groups_to_print, start=1):
            intent = duplicate_intent(group)
            candidate = choose_canonical_candidate(group)
            print(f"\n[{index}] files={len(group)} intent={intent}")
            print(f"canonical_candidate: {rel(candidate)}")
            for path in group:
                print(f"- {rel(path)}")

    unstable_count = len(root_loose) + len(loose_domain)
    if args.strict and unstable_count > 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
