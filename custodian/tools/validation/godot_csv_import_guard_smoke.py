#!/usr/bin/env python3
"""Guard against Godot's default CSV translation importer crashing project import.

Godot imports every ``.csv`` it can see as a translation. Under Godot 4.7.2 a
fresh import (new checkout, new worktree, cleared ``.godot``) segfaults on the
asset-index CSVs, whose columns (``x``, ``y``, ``pixels`` ...) are not locales.
Data CSVs that Godot can see must opt out with ``importer="keep"``; CSVs under a
``.gdignore`` directory are invisible to Godot and need nothing.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
PROJECT = REPO_ROOT / "custodian"
KEEP_RE = re.compile(r'^importer="keep"\s*$', re.MULTILINE)


def hidden_from_godot(path: Path) -> bool:
    directory = path.parent
    while directory != PROJECT.parent:
        if (directory / ".gdignore").exists():
            return True
        directory = directory.parent
    return False


def project_csvs() -> list[Path]:
    listing = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", "custodian/*.csv"],
        cwd=REPO_ROOT, capture_output=True, check=True,
    ).stdout.decode("utf-8")
    return sorted(REPO_ROOT / item for item in listing.split("\0") if item)


def main() -> int:
    failures: list[str] = []
    checked = 0
    for csv in project_csvs():
        if hidden_from_godot(csv):
            continue
        checked += 1
        sidecar = Path(f"{csv}.import")
        relative = csv.relative_to(REPO_ROOT)
        if not sidecar.is_file():
            failures.append(f"{relative}: no .import sidecar; Godot will create a csv_translation import")
        elif not KEEP_RE.search(sidecar.read_text(encoding="utf-8")):
            failures.append(f"{relative}: .import must set importer=\"keep\"")
    if failures:
        print("FAIL: Godot-visible CSV files would use the translation importer")
        for failure in failures:
            print(f"  {failure}")
        print('  fix: write "[remap]\\n\\nimporter=\\"keep\\"\\n" to <file>.csv.import, or place the CSV under a .gdignore directory')
        return 1
    print(f"godot_csv_import_guard_smoke: PASS ({checked} Godot-visible CSV files opt out of translation import)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
