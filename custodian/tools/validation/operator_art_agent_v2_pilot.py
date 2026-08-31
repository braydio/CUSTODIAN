#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/operator"))

from art_agent.pilot import print_result, run_v2_pilot


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the real Operator Art Agent V2 semantic pilot")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--keep-artifacts", action="store_true")
    parser.add_argument("--allow-skip-aseprite", action="store_true")
    args = parser.parse_args()
    result = run_v2_pilot(
        keep_artifacts=args.keep_artifacts,
        allow_skip_aseprite=args.allow_skip_aseprite,
        repo_root=ROOT,
    )
    print_result(result, json_output=args.json)
    return 0 if result.get("engineering") in {"PASS", "SKIP"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
