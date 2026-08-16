#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
FORBIDDEN = re.compile(
    r"content/sprites/operator/(?:new_operator|runtime/(?:animation_base|curated|modules/new_operator|actions|body|fx|overlay|overlays|full_body|weapon|live_review))(?:/|\b)"
)


def main() -> int:
    violations = []
    for root in (PROJECT_ROOT / "game", PROJECT_ROOT / "tools"):
        for path in sorted(root.rglob("*")):
            if path.name in {"operator_runtime_path_audit.py", "migrate_operator_assets_v2.py"}:
                continue
            if path.suffix not in {".gd", ".tscn", ".tres", ".py", ".json"} or not path.is_file():
                continue
            for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                if FORBIDDEN.search(line):
                    violations.append(f"{path.relative_to(PROJECT_ROOT)}:{line_number}: {line.strip()}")
    if violations:
        print("Legacy Operator runtime paths remain:\n" + "\n".join(violations))
        return 1
    print("operator runtime path audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
