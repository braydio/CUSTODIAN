#!/usr/bin/env python3
"""Audit Operator runtime path references.

Retired runtime folder families are always a hard failure. Canonical `legacy_*`
actions are migration debt: reported every run, and a failure under ``--final``,
which is the objective end-state gate.

Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
FORBIDDEN = re.compile(
    r"content/sprites/operator/(?:new_operator|runtime/(?:animation_base|curated|modules/new_operator|actions|body|fx|overlay|overlays|full_body|weapon|live_review))(?:/|\b)"
)
LEGACY_ACTION = re.compile(r"\blegacy_[a-z0-9_]+|[a-z0-9]+_legacy_[a-z0-9]+")
# Only Operator animation identities are in scope; other systems have their own legacy.
OPERATOR_SCOPE = re.compile(r"content/sprites/(?:operator|weapons)/")
OPERATOR_OWNED_DIRS = ("game/actors/operator/", "game/systems/presentation/")

# Migration tooling is allowed to understand legacy names; that is its whole job.
MIGRATION_ONLY = {
    "operator_runtime_path_audit.py",
    "migrate_operator_assets_v2.py",
    "operator_legacy_asset_migration.py",
    "operator_legacy_animation_map.json",
    "materialize_operator_legacy_animations.gd",
    "operator_runtime_animation_authority_smoke.py",
    "operator_asset_schema.py",
    "operator_asset_schema_smoke.py",
    "sync_operator_runtime_assets.py",
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--final", action="store_true",
                        help="also fail on remaining legacy identities")
    args = parser.parse_args(argv)

    violations: list[str] = []
    legacy: list[str] = []
    for root in (PROJECT_ROOT / "game", PROJECT_ROOT / "tools"):
        for path in sorted(root.rglob("*")):
            if path.name in MIGRATION_ONLY:
                continue
            if path.suffix not in {".gd", ".tscn", ".tres", ".py", ".json"} or not path.is_file():
                continue
            relative = path.relative_to(PROJECT_ROOT).as_posix()
            operator_owned = relative.startswith(OPERATOR_OWNED_DIRS)
            for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                location = f"{relative}:{line_number}"
                if FORBIDDEN.search(line):
                    violations.append(f"{location}: {line.strip()}")
                if LEGACY_ACTION.search(line) and (operator_owned or OPERATOR_SCOPE.search(line)):
                    legacy.append(location)

    if violations:
        print("Retired Operator runtime paths remain:\n" + "\n".join(violations))
        return 1
    if legacy:
        label = "FAIL" if args.final else "TODO"
        print(f"{label} legacy Operator identities still referenced in {len(legacy)} lines")
        for location in legacy[:10]:
            print(f"  {location}")
        if len(legacy) > 10:
            print(f"  ... and {len(legacy) - 10} more")
        if args.final:
            return 1
    print("operator runtime path audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
