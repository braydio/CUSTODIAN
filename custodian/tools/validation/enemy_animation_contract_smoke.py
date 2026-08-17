#!/usr/bin/env python3
from __future__ import annotations

import json

from enemy_animation_contract_report import (
    DEFAULT_CONTRACT,
    DEFAULT_ENEMY_ROOT,
    build_report,
)


def main() -> int:
    contract = json.loads(DEFAULT_CONTRACT.read_text())
    enemy_ids = list(contract.get("default_enforced_enemies", []))
    if not enemy_ids:
        print("enemy animation contract has no default_enforced_enemies")
        return 1

    report = build_report(contract, enemy_ids, DEFAULT_ENEMY_ROOT)
    print(json.dumps(report["summary"], indent=2))

    if report["summary"]["invalid_names"]:
        print("warning: legacy/malformed enemy runtime animation names remain; run enemy_animation_contract_report.py --json for details")

    return 1 if report["summary"]["missing_required_capabilities"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
