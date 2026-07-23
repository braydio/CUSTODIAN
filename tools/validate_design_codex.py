#!/usr/bin/env python3
"""
Validate CUSTODIAN Design Codex structure.

Checks:
- canonical card files under design/90_codex are indexed in 00_index.md
- index paths exist
- required card fields exist
- graduated/runtime-seed/implemented cards include an active target hint
- package residue folders are reported
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
CODEX_DIR = REPO_ROOT / "design" / "90_codex"
INDEX_FILE = CODEX_DIR / "00_index.md"

ROOT_DOCS = {
    "README.md",
    "00_index.md",
    "01_hall_of_great_ideas.md",
    "02_backlog.md",
    "03_graduated.md",
    "TRACKER.md",
}

IGNORED_DIR_PARTS = {
    "templates",
}

PACKAGE_RESIDUE_DIR_NAMES = {
    "Cards-Wave-3",
    "cards-wave-3",
    "wave",
    "bundle",
    "package",
}

REQUIRED_FIELDS = [
    "Status:",
    "Category:",
    "Priority:",
    "Maturity:",
    "Cost:",
]

GRADUATED_STATUSES = {
    "graduated",
    "runtime-seed",
    "implemented",
}

ACTIVE_TARGET_MARKERS = [
    "Graduated to:",
    "Runtime path:",
    "Active spec:",
    "Implementation spec:",
    "Task packet:",
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate design/90_codex structure.")
    parser.add_argument(
        "--changed-only",
        action="store_true",
        help="Accepted for hook compatibility. Currently validates the whole codex.",
    )
    parser.add_argument(
        "--warnings-as-errors",
        action="store_true",
        help="Treat warnings as errors.",
    )
    args = parser.parse_args()

    errors: list[str] = []
    warnings: list[str] = []

    if not CODEX_DIR.exists():
        errors.append(f"Missing codex directory: {rel(CODEX_DIR)}")
        return finish(errors, warnings, args.warnings_as_errors)

    if not INDEX_FILE.exists():
        errors.append(f"Missing codex index: {rel(INDEX_FILE)}")
        return finish(errors, warnings, args.warnings_as_errors)

    index_text = INDEX_FILE.read_text(encoding="utf-8")
    indexed_paths = extract_index_paths(index_text)

    canonical_cards = find_canonical_cards()
    canonical_rel_paths = {card.relative_to(CODEX_DIR).as_posix() for card in canonical_cards}

    check_index_paths_exist(indexed_paths, errors)
    check_cards_indexed(canonical_rel_paths, indexed_paths, errors)
    check_required_fields(canonical_cards, errors)
    check_graduated_targets(canonical_cards, errors)
    check_package_residue(warnings)
    check_empty_backlog(warnings)

    return finish(errors, warnings, args.warnings_as_errors)


# Path prefixes that point outside the codex directory.
# These appear as intentional cross-references (e.g. "Active-Spec Cross-Check")
# and should not be validated as codex-internal cards.
EXTERNAL_PREFIXES = (
    "design/01_",
    "design/02_",
    "design/03_",
    "design/04_",
    "design/05_",
    "design/06_",
    "design/07_",
    "design/08_",
    "design/09_",
    "design/10_",
    "design/11_",
    "design/12_",
    "design/20_",
    "custodian/",
    "custodian/",
)


def extract_index_paths(index_text: str) -> set[str]:
    paths: set[str] = set()

    # Markdown table cells and inline links can both contain card paths.
    for match in re.finditer(r"`?([A-Za-z0-9_./-]+\.md)`?", index_text):
        raw = match.group(1).strip()
        if raw.startswith("design/90_codex/"):
            raw = raw.removeprefix("design/90_codex/")
        if raw in ROOT_DOCS:
            continue
        if raw.startswith("templates/"):
            continue
        # Skip cross-references to files outside the codex.
        if any(raw.startswith(prefix) for prefix in EXTERNAL_PREFIXES):
            continue
        if "/" in raw:
            paths.add(raw)

    return paths


def find_canonical_cards() -> list[Path]:
    cards: list[Path] = []

    for path in CODEX_DIR.rglob("*.md"):
        rel_path = path.relative_to(CODEX_DIR)
        parts = set(rel_path.parts)

        if rel_path.as_posix() in ROOT_DOCS:
            continue
        if parts & IGNORED_DIR_PARTS:
            continue
        if parts & PACKAGE_RESIDUE_DIR_NAMES:
            # Reported separately as warning; not canonical by default.
            continue

        cards.append(path)

    return sorted(cards)


def check_index_paths_exist(indexed_paths: set[str], errors: list[str]) -> None:
    for indexed in sorted(indexed_paths):
        target = CODEX_DIR / indexed
        if not target.exists():
            errors.append(f"Index points to missing card: design/90_codex/{indexed}")


def check_cards_indexed(canonical_rel_paths: set[str], indexed_paths: set[str], errors: list[str]) -> None:
    missing = canonical_rel_paths - indexed_paths
    for path in sorted(missing):
        errors.append(f"Canonical card missing from 00_index.md: design/90_codex/{path}")


def check_required_fields(cards: list[Path], errors: list[str]) -> None:
    for card in cards:
        text = card.read_text(encoding="utf-8")
        for field in REQUIRED_FIELDS:
            if field not in text:
                errors.append(f"{rel(card)} missing required field `{field}`")


def check_graduated_targets(cards: list[Path], errors: list[str]) -> None:
    for card in cards:
        text = card.read_text(encoding="utf-8")
        status = extract_status(text)

        if status not in GRADUATED_STATUSES:
            continue

        if not any(marker in text for marker in ACTIVE_TARGET_MARKERS):
            errors.append(
                f"{rel(card)} has Status `{status}` but no active target marker "
                f"({', '.join(ACTIVE_TARGET_MARKERS)})"
            )


def extract_status(text: str) -> str:
    match = re.search(r"^Status:\s*([A-Za-z0-9_-]+)", text, flags=re.MULTILINE)
    if not match:
        return ""
    return match.group(1).strip().lower()


def check_package_residue(warnings: list[str]) -> None:
    for residue_name in sorted(PACKAGE_RESIDUE_DIR_NAMES):
        path = CODEX_DIR / residue_name
        if path.exists():
            warnings.append(
                f"Possible package residue directory exists: {rel(path)}. "
                "Move canonical cards into category folders or remove the package folder."
            )


def check_empty_backlog(warnings: list[str]) -> None:
    backlog = CODEX_DIR / "02_backlog.md"
    if not backlog.exists():
        warnings.append("Missing optional backlog file: design/90_codex/02_backlog.md")
        return

    text = backlog.read_text(encoding="utf-8").strip()
    if "Use this as the raw dump" in text and len(text.splitlines()) <= 8:
        warnings.append("Codex backlog appears to be only the template; consider adding raw ideas or noting intentionally empty.")


def rel(path: Path) -> str:
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def finish(errors: list[str], warnings: list[str], warnings_as_errors: bool) -> int:
    if warnings:
        print("Design Codex warnings:")
        for warning in warnings:
            print(f"  WARN: {warning}")
        print("")

    if warnings_as_errors:
        errors.extend(warnings)

    if errors:
        print("Design Codex validation failed:")
        for error in errors:
            print(f"  ERROR: {error}")
        return 1

    print("Design Codex validation passed.")
    if warnings:
        print(f"{len(warnings)} warning(s) reported.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
