#!/usr/bin/env python3
"""Materialize authored directional coverage from an explicit authoring decision.

Migration tooling. Gameplay never consumes this, and it is NOT a fallback: it
freezes a human authoring decision into exact canonical identities so that
`OperatorAnimationSelector` keeps seeing an exact identity and its contract stays

    exact -> temporary same-identity SOUTH -> error

Some Operator actions are authored in fewer facings than the eight runtime
sectors. The old `DirectionalAnimationFallback` papered over that with a
nearest-available-sector search whose visible outcomes were an artifact of tie
ordering rather than a rule. Rather than keep an opaque search alive forever, the
authoring decision is recorded here and expanded into real runtime identities.

Every expanded strip is a byte-identical copy of the authored strip it reuses,
and each carries a sidecar recording that it is a deliberate reuse rather than
unique art, so a future agent does not mistake it for authored coverage.

Usage:
    expand_operator_directional_coverage.py [--apply] [--map PATH]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = CUSTODIAN_ROOT / "content/sprites/operator/source/animations"
DEFAULT_MAP = Path(__file__).with_name("operator_directional_expansion_map.json")

PROVENANCE_SCHEMA = "custodian.operator_directional_expansion.v1"


def load_map(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("schema") != PROVENANCE_SCHEMA:
        raise ValueError(f"{path}: unexpected schema {payload.get('schema')!r}")
    return payload


def plan_expansions(payload: dict) -> list[dict]:
    plans: list[dict] = []
    for rule in payload["expansions"]:
        profile, group, action = rule["profile"], rule["group"], rule["action"]
        layer, frames, cell = rule["layer"], rule["frames"], rule["cell"]
        directory = SOURCE_ROOT / profile / group / action
        for target, authored in rule["directions"].items():
            if target == authored:
                continue  # the authored facing itself
            name = "operator__%s__%s__%s__%s__%s__%df__%s.png" % (
                layer, profile, group, action, "%s", frames, cell)
            source = directory / (name % authored)
            destination = directory / (name % target)
            if not source.is_file():
                raise FileNotFoundError(f"authored strip missing: {source}")
            plans.append({
                "source": source, "destination": destination,
                "identity": f"{profile}/{group}/{action}/{target}/{layer}",
                "authored_direction": authored, "target_direction": target,
                "reason": rule.get("reason", ""),
            })
    return plans


def sidecar_for(destination: Path) -> Path:
    return destination.with_suffix("").with_suffix(".expansion.json")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--map", type=Path, default=DEFAULT_MAP)
    args = parser.parse_args(argv)

    try:
        payload = load_map(args.map)
        plans = plan_expansions(payload)
    except (OSError, ValueError, KeyError, FileNotFoundError) as error:
        print(error, file=sys.stderr)
        return 1

    written = 0
    for plan in plans:
        source: Path = plan["source"]
        destination: Path = plan["destination"]
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        if destination.exists():
            # Never overwrite authored art with a reuse copy.
            existing = hashlib.sha256(destination.read_bytes()).hexdigest()
            if existing != digest:
                print(
                    f"refusing to overwrite differing art: {destination}",
                    file=sys.stderr,
                )
                return 1
        status = "present" if destination.exists() else (
            "expanded" if args.apply else "dry-run")
        if args.apply and not destination.exists():
            shutil.copy2(source, destination)
            written += 1
        if args.apply:
            sidecar_for(destination).write_text(json.dumps({
                "schema": PROVENANCE_SCHEMA,
                "identity": plan["identity"],
                "authored_direction": plan["authored_direction"],
                "target_direction": plan["target_direction"],
                "reuses_authored_pixels": True,
                "source_sha256": digest,
                "reason": plan["reason"],
            }, indent=2) + "\n", encoding="utf-8")
        print("%-9s %s  <- authored %s" % (
            status, plan["identity"], plan["authored_direction"]))
    print("\n%d expansion(s); %d newly written" % (len(plans), written))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
