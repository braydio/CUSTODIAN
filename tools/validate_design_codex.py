#!/usr/bin/env python3
"""Validate design/90_codex/ card index consistency.

Checks that every card file under design/90_codex/ appears in 00_index.md
and that every index entry has a corresponding file. Also verifies that
the Runtime column in the index matches the Runtime field in card files.
Exits non-zero on drift.

Usage:
    python tools/validate_design_codex.py
    python tools/validate_design_codex.py --codex-root design/90_codex
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Files and directories to skip when scanning for card .md files.
SKIP_NAMES = {"README.md", "00_index.md", "01_hall_of_great_ideas.md",
              "02_backlog.md", "03_graduated.md"}
SKIP_DIRS = {"templates", "Cards-Wave-3"}

INDEX_TABLE_ROW = re.compile(
    r"^\|\s*`([^`]+\.md)`\s*\|"  # card path
    r"\s*([^|]*)\s*\|"            # status
    r"\s*([^|]*)\s*\|"            # priority
    r"\s*([^|]*)\s*\|"            # maturity
    r"\s*([^|]*)\s*\|"            # runtime (may be empty)
)
CARD_RUNTIME_RE = re.compile(r"^Runtime:\s*(.+)", re.MULTILINE | re.IGNORECASE)


def discover_card_files(codex_root: Path) -> set[str]:
    """Return relative card paths (from codex root) for all .md card files."""
    cards: set[str] = set()
    for md_file in sorted(codex_root.rglob("*.md")):
        rel = md_file.relative_to(codex_root)
        if rel.name in SKIP_NAMES:
            continue
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        cards.add(str(rel))
    return cards


def parse_index(index_path: Path) -> dict[str, str]:
    """Extract card paths and their Runtime column from the index table."""
    entries: dict[str, str] = {}
    for line in index_path.read_text().splitlines():
        m = INDEX_TABLE_ROW.match(line)
        if m:
            card_path = m.group(1)
            runtime_col = m.group(5).strip()
            entries[card_path] = runtime_col
    return entries


def card_has_runtime(card_path: Path) -> bool:
    """Check if a card file declares Runtime: live."""
    text = card_path.read_text()
    m = CARD_RUNTIME_RE.search(text)
    return m is not None and "live" in m.group(1).lower()


def main() -> int:
    codex_root = Path(__file__).resolve().parent.parent / "design" / "90_codex"
    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == "--codex-root" and i < len(sys.argv) - 1:
            codex_root = Path(sys.argv[i + 1]).resolve()

    index_path = codex_root / "00_index.md"
    if not index_path.exists():
        print(f"ERROR: index not found at {index_path}", file=sys.stderr)
        return 1

    card_files = discover_card_files(codex_root)
    index_entries = parse_index(index_path)
    index_keys = set(index_entries.keys())

    errors: list[str] = []

    # Cards on disk but missing from index.
    missing_from_index = sorted(card_files - index_keys)
    for card in missing_from_index:
        errors.append(f"Card file has no index entry: {card}")

    # Index entries with no corresponding file.
    missing_from_disk = sorted(index_keys - card_files)
    for entry in missing_from_disk:
        errors.append(f"Index entry has no card file: {entry}")

    # Runtime column consistency: if card declares Runtime: live, index should say live.
    for card_rel, runtime_col in index_entries.items():
        card_file = codex_root / card_rel
        if not card_file.exists():
            continue
        has_live = card_has_runtime(card_file)
        index_says_live = "live" in runtime_col.lower()
        if has_live and not index_says_live:
            errors.append(f"Card {card_rel} has Runtime: live but index says '{runtime_col}'")
        elif not has_live and index_says_live:
            errors.append(f"Index says {card_rel} is live but card has no Runtime: live field")

    if errors:
        print("Codex drift detected:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"Codex index OK — {len(card_files)} cards, {len(index_entries)} index entries, no drift.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
