#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = Path(__file__).resolve().parent / "contracts/operator_animation_core.json"
DEFAULT_CATALOG = PROJECT_ROOT / "content/data/operator/generated/operator_animation_catalog.generated.json"


def expand(contract: dict) -> list[dict]:
    entries = []
    for group in contract.get("groups", []):
        for entry in group.get("entries", []):
            directions = entry.get("directions", contract["directions"])
            for direction in directions:
                entries.append({**entry, "direction": direction, "group_id": group["id"],
                                "required": entry.get("required", group.get("required", False))})
    return entries


def build_report(contract: dict, catalog: dict) -> dict:
    missing_required = []
    missing_optional = []
    present = []
    for expected in expand(contract):
        key = "/".join((expected["animation_profile"], expected["action_group"], expected["action"], expected["direction"]))
        layer = catalog.get("animations", {}).get(key, {}).get("layers", {}).get(expected["layer"])
        if layer:
            present.append({"key": key, "layer": expected["layer"], "path": layer["path"]})
        elif expected["required"]:
            missing_required.append({"key": key, "layer": expected["layer"]})
        else:
            missing_optional.append({"key": key, "layer": expected["layer"]})
    return {
        "schema": "custodian.operator_animation_contract_report.v2",
        "summary": {"expected": len(expand(contract)), "present": len(present),
                    "missing_required": len(missing_required), "missing_optional": len(missing_optional)},
        "present": present, "missing_required": missing_required, "missing_optional": missing_optional,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = build_report(json.loads(args.contract.read_text()), json.loads(args.catalog.read_text()))
    print(json.dumps(report, indent=2) if args.json else json.dumps(report["summary"], indent=2))
    return 1 if args.strict and report["summary"]["missing_required"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
