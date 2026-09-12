#!/usr/bin/env python3
"""Characterize every legacy Operator animation-selection call site.

Migration tooling only. Gameplay must never consume this, and it deliberately
emits no runtime alias table: the point is to prove each old call site's
canonical identity from evidence the repo already records, not to build a
translation layer that would keep the old names alive.

Evidence sources, in order of authority:

1. `operator_animation_reachability.json` — records, per canonical action, the
   consumer that drives it. This is the repo's own statement of which legacy
   call site corresponds to which canonical identity.
2. `operator_runtime_manifest.generated.json` — the identities that actually
   exist in runtime, and their authored directional coverage.

A site whose canonical identity cannot be proven from those is reported
UNPROVEN rather than guessed, because inferring identity from a legacy clip
name is how a cutover silently changes what the player sees.

Usage:
    python3 operator_selection_cutover_inventory.py [--json out.json]
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[3]
OPERATOR_DIR = CUSTODIAN_ROOT / "game/actors/operator"
MANIFEST = CUSTODIAN_ROOT / "content/sprites/operator/runtime/operator_runtime_manifest.generated.json"
REACHABILITY = CUSTODIAN_ROOT / "content/data/operator/operator_animation_reachability.json"

PATTERNS = {
    "animation_resolver": re.compile(r"AnimationResolver\.resolve\s*\(\s*([^,]+),"),
    "directional_animation_fallback": re.compile(r"DirectionalAnimationFallback\.(\w+)\s*\("),
    "attack_fallback_animation": re.compile(r"\bfallback_animation\b"),
}


def enclosing_functions(lines: list[str]) -> list[tuple[int, str]]:
    return [(i, l.split("(")[0][5:]) for i, l in enumerate(lines) if l.startswith("func ")]


def enclosing(funcs, index: int) -> str:
    name = "<file scope>"
    for i, n in funcs:
        if i <= index:
            name = n
        else:
            break
    return name


def load_evidence() -> tuple[dict, dict]:
    """Canonical identities that exist, and the consumers the repo records."""
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    coverage: dict[tuple[str, str, str], dict[str, set]] = defaultdict(lambda: defaultdict(set))
    for entry in manifest["animations"].values():
        key = (entry["profile"], entry["group"], entry["action"])
        for layer in entry["layers"]:
            coverage[key][layer].add(entry["direction"])

    # Two indexes, because a call site is identified two different ways: by the
    # function the contract names, and by the legacy clip literal it passes.
    consumers: dict[str, list[dict]] = defaultdict(list)
    reach = json.loads(REACHABILITY.read_text(encoding="utf-8"))
    for entry in reach["entries"]:
        consumer = str(entry.get("consumer", ""))
        if not consumer:
            continue
        for token in re.findall(r"[A-Za-z_]\w*", consumer):
            consumers[token].append(entry)
    return coverage, consumers


def collect_sites() -> list[dict]:
    sites: list[dict] = []
    for path in sorted(OPERATOR_DIR.rglob("*.gd")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        lines = text.split("\n")
        funcs = enclosing_functions(lines)
        relative = path.relative_to(CUSTODIAN_ROOT).as_posix()
        for index, line in enumerate(lines):
            for key, pattern in PATTERNS.items():
                match = pattern.search(line)
                if not match:
                    continue
                sites.append({
                    "debt": key,
                    "file": relative,
                    "line": index + 1,
                    "function": enclosing(funcs, index),
                    "argument": match.group(1).strip() if match.groups() else "",
                    "source": line.strip(),
                })
    return sites


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", type=Path, help="write the full inventory as JSON")
    args = parser.parse_args(argv)

    coverage, consumers = load_evidence()
    sites = collect_sites()

    by_function: dict[str, list[dict]] = defaultdict(list)
    for site in sites:
        by_function[site["function"]].append(site)

    proven = 0
    for function, function_sites in sorted(by_function.items()):
        for site in function_sites:
            # Prefer the legacy clip literal the site passes: it is the most
            # specific join the contract offers. Fall back to the function name.
            literal = re.findall(r'"([A-Za-z_]\w*)"', site["argument"])
            evidence = []
            for token in literal:
                evidence.extend(consumers.get(token, []))
            if not evidence:
                evidence = consumers.get(function, [])
            site["evidence"] = [
                {
                    "profile": e["profile"], "group": e["group"], "action": e["action"],
                    "status": e.get("status"), "consumer": e.get("consumer"),
                    "layers": {l: sorted(d) for l, d in
                               sorted(coverage.get((e["profile"], e["group"], e["action"]), {}).items())},
                }
                for e in evidence
            ]
            site["proven"] = bool(evidence)
            site["matched_by"] = "clip_literal" if literal and evidence else (
                "function_name" if evidence else "")
            proven += 1 if evidence else 0

    counts: dict[str, int] = defaultdict(int)
    for site in sites:
        counts[site["debt"]] += 1

    print("Operator selection cutover inventory")
    print("=" * 72)
    for debt, count in sorted(counts.items()):
        print(f"  {debt:<34} {count}")
    print(f"  {'sites with recorded consumer evidence':<34} {proven}/{len(sites)}")
    print()
    for function, function_sites in sorted(by_function.items()):
        proven_here = sum(1 for s in function_sites if s.get("proven"))
        marker = "PROVEN  " if proven_here == len(function_sites) else (
            "PARTIAL " if proven_here else "UNPROVEN")
        print(f"{marker} {function}  ({proven_here}/{len(function_sites)} proven)")
        seen = set()
        for site in function_sites:
            for entry in site.get("evidence", [])[:3]:
                key = (entry["profile"], entry["group"], entry["action"])
                if key in seen:
                    continue
                seen.add(key)
                print("           %-28s -> %s/%s/%s %s" % (
                    site["argument"][:28], entry["profile"], entry["group"],
                    entry["action"], entry["layers"]))
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps({
            "schema": "custodian.operator_selection_cutover_inventory.v1",
            "counts": dict(counts), "sites": sites,
        }, indent=2) + "\n", encoding="utf-8")
        print(f"\nwrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
