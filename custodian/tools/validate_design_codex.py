#!/usr/bin/env python3
"""Validate the governance contract for design/90_codex/.

Checks index coverage, required card metadata, index/card agreement,
graduation and runtime links, and packaging-directory residue.

Usage:
    python tools/validate_design_codex.py
    python tools/validate_design_codex.py --codex-root design/90_codex
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT_NON_CARD_FILES = {
    "README.md",
    "00_index.md",
    "01_hall_of_great_ideas.md",
    "02_backlog.md",
    "03_graduated.md",
}
NON_CARD_DIRS = {"templates"}
REQUIRED_FIELDS = ("status", "category", "priority", "maturity", "cost")
INDEX_TABLE_ROW = re.compile(
    r"^\|\s*`([^`]+\.md)`\s*\|"
    r"\s*([^|]*)\s*\|"  # status
    r"\s*([^|]*)\s*\|"  # priority
    r"\s*([^|]*)\s*\|"  # maturity
    r"\s*([^|]*)\s*\|"  # runtime status
)
METADATA_LINE = re.compile(r"^([A-Za-z][A-Za-z ]*):\s*(.*?)\s*$")
PACKAGING_DIR = re.compile(r"^cards-wave(?:-\d+)?$", re.IGNORECASE)
BACKTICK_PATH = re.compile(r"`([^`]+)`")


def discover_card_files(codex_root: Path) -> set[str]:
    """Return card paths relative to the Codex root."""
    cards: set[str] = set()
    for md_file in sorted(codex_root.rglob("*.md")):
        rel = md_file.relative_to(codex_root)
        if rel.parent == Path(".") and rel.name in ROOT_NON_CARD_FILES:
            continue
        if any(part in NON_CARD_DIRS for part in rel.parts[:-1]):
            continue
        cards.add(rel.as_posix())
    return cards


def parse_index(index_path: Path) -> tuple[dict[str, dict[str, str]], list[str]]:
    """Extract indexed card metadata and report duplicate rows."""
    entries: dict[str, dict[str, str]] = {}
    errors: list[str] = []
    for line_number, line in enumerate(index_path.read_text(encoding="utf-8").splitlines(), 1):
        match = INDEX_TABLE_ROW.match(line)
        if match is None:
            continue
        card_path = match.group(1)
        if card_path in entries:
            errors.append(f"Duplicate index entry for {card_path} on line {line_number}")
            continue
        entries[card_path] = {
            "status": match.group(2).strip(),
            "priority": match.group(3).strip(),
            "maturity": match.group(4).strip(),
            "runtime status": match.group(5).strip(),
        }
    return entries, errors


def parse_card_metadata(card_path: Path) -> dict[str, str]:
    """Read top-level ``Field: value`` metadata from a card."""
    metadata: dict[str, str] = {}
    for line in card_path.read_text(encoding="utf-8").splitlines():
        match = METADATA_LINE.match(line)
        if match is not None:
            metadata[match.group(1).strip().lower()] = match.group(2).strip()
    return metadata


def referenced_path(value: str) -> str:
    """Return a backtick-wrapped path, or a plain metadata value."""
    match = BACKTICK_PATH.search(value)
    return match.group(1).strip() if match is not None else value.strip()


def validate_reference(repo_root: Path, card_rel: str, field: str, value: str) -> str | None:
    path_text = referenced_path(value)
    if not path_text:
        return None
    if path_text.startswith("res://"):
        target = repo_root / "custodian" / path_text.removeprefix("res://")
    else:
        target = repo_root / path_text
    if not target.exists():
        return f"Card {card_rel} has missing {field} target: {path_text}"
    return None


def find_packaging_directories(codex_root: Path) -> list[str]:
    return sorted(
        path.relative_to(codex_root).as_posix()
        for path in codex_root.rglob("*")
        if path.is_dir() and PACKAGING_DIR.match(path.name)
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--codex-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "design" / "90_codex",
    )
    args = parser.parse_args()

    codex_root = args.codex_root.resolve()
    repo_root = codex_root.parent.parent
    index_path = codex_root / "00_index.md"
    if not index_path.exists():
        print(f"ERROR: index not found at {index_path}", file=sys.stderr)
        return 1

    card_files = discover_card_files(codex_root)
    index_entries, errors = parse_index(index_path)
    index_keys = set(index_entries)

    for directory in find_packaging_directories(codex_root):
        errors.append(f"Packaging directory must be removed or relocated: {directory}")

    for card in sorted(card_files - index_keys):
        errors.append(f"Card file has no index entry: {card}")
    for entry in sorted(index_keys - card_files):
        errors.append(f"Index entry has no card file: {entry}")

    for card_rel in sorted(card_files):
        card_path = codex_root / card_rel
        metadata = parse_card_metadata(card_path)

        for field in REQUIRED_FIELDS:
            if not metadata.get(field):
                errors.append(f"Card {card_rel} is missing required metadata: {field.title()}")

        index_metadata = index_entries.get(card_rel)
        if index_metadata is not None:
            for field in ("status", "priority", "maturity", "runtime status"):
                card_value = metadata.get(field, "")
                index_value = index_metadata[field]
                if card_value.casefold() != index_value.casefold():
                    errors.append(
                        f"Card {card_rel} has {field.title()}: '{card_value}' "
                        f"but index says '{index_value}'"
                    )

        status = metadata.get("status", "").casefold()
        runtime_status = metadata.get("runtime status", "").casefold()
        runtime_path = metadata.get("runtime path", "")
        graduated_to = metadata.get("graduated to", "")

        if status == "graduated" and not (graduated_to or runtime_path):
            errors.append(
                f"Graduated card {card_rel} needs Graduated to: or Runtime path: metadata"
            )
        if runtime_status == "live" and not runtime_path:
            errors.append(f"Live card {card_rel} needs Runtime path: metadata")

        for field, value in (("Graduated to", graduated_to), ("Runtime path", runtime_path)):
            if value:
                error = validate_reference(repo_root, card_rel, field, value)
                if error is not None:
                    errors.append(error)

    if errors:
        print("Codex drift detected:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(
        f"Codex governance OK — {len(card_files)} cards, "
        f"{len(index_entries)} index entries, no drift."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
