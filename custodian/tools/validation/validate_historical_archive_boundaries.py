#!/usr/bin/env python3
"""Reject active Godot-era references to the retired Python archive."""

from __future__ import annotations

from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
TARGETS = (
    REPO / "design",
    REPO / "custodian" / "game",
    REPO / "custodian" / "tools",
    REPO / "custodian" / "scenes",
    REPO / "custodian" / "content",
    REPO / "custodian" / "docs" / "ai_context",
)
EXCLUDED_PREFIXES = (
    REPO / "custodian" / "docs" / "ai_context" / "task_packets" / "archived",
)
EXPLICIT_HISTORY_ALLOWLIST = {
    REPO / "custodian" / "README.md",
    REPO / "custodian" / "AGENTS.md",
}
HISTORY_MARKERS = ("historical artifact", "historical archive", "pre-godot", "retired")


def is_excluded(path: Path) -> bool:
    return path == Path(__file__).resolve() or any(
        path.is_relative_to(prefix) for prefix in EXCLUDED_PREFIXES
    )


def scan_file(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return []
    if "python-sim" not in text:
        return []
    if path in EXPLICIT_HISTORY_ALLOWLIST and any(marker in text.lower() for marker in HISTORY_MARKERS):
        return []
    return [
        f"{path.relative_to(REPO)}:{line_number}: active archive reference"
        for line_number, line in enumerate(text.splitlines(), start=1)
        if "python-sim" in line
    ]


def main() -> int:
    failures: list[str] = []
    for target in TARGETS:
        if not target.exists():
            continue
        for path in target.rglob("*"):
            if path.is_file() and not is_excluded(path):
                failures.extend(scan_file(path))
    for path in EXPLICIT_HISTORY_ALLOWLIST:
        if path.exists():
            failures.extend(scan_file(path))
    if failures:
        print("Historical archive boundary violations:")
        print("\n".join(failures))
        return 1
    print("historical archive boundary validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
