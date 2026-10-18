#!/usr/bin/env python3
"""Read-only root-blocker frontier from CUSTODIAN dispatch.py audit --json.

Only consumes an existing JSON snapshot. It does not fetch refs, mutate claims,
change packet eligibility, or infer process death.
"""
from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path

LOCK_HOLDER_RE = re.compile(r"held by ([a-z0-9]+(?:-[a-z0-9]+)*)")


def analyze(audit: dict) -> dict:
    if not isinstance(audit, dict) or not isinstance(audit.get("packets"), list):
        raise ValueError("expected dispatch audit object with packets array")
    rows = audit["packets"]
    by_id = {p["workstream"]: p for p in rows
             if isinstance(p, dict) and isinstance(p.get("workstream"), str)
             and p["workstream"]}
    roots = collections.defaultdict(set)

    def frontier(workstream: str, visited: frozenset[str] = frozenset()):
        if workstream in visited:
            return {(workstream, "dependency or lock cycle; inspect")}
        row = by_id.get(workstream)
        if row is None:
            return {(workstream, "missing from active queue; inspect archive")}
        if row.get("claim_next_eligible"):
            return {(workstream, "eligible now; claim through dispatcher")}
        reasons = row.get("reasons") or []
        if not isinstance(reasons, list):
            reasons = []

        # Intrinsic corruption must not be obscured by an unrelated dependency.
        classification = row.get("actual_class", "unknown")
        if classification == "invalid_recovery":
            return {(workstream, "invalid record or interrupted claim; evidence triage")}

        rejected = [s.split("dependency review not accepted: ", 1)[1].split(" (", 1)[0]
                    for s in reasons if isinstance(s, str)
                    and s.startswith("dependency review not accepted: ")]
        roots_here = {(dep, "unaccepted review; genuine verdict required") for dep in rejected}
        missing = [s.split("dependency not archived complete: ", 1)[1].strip()
                   for s in reasons if isinstance(s, str)
                   and s.startswith("dependency not archived complete: ")]
        for dependency in missing:
            roots_here.update(frontier(dependency, visited | {workstream}))
        if roots_here:
            return roots_here

        if row.get("claimed") or classification == "claimed":
            return {(workstream, "claimed; original-owner recovery only")}

        for reason in reasons:
            if isinstance(reason, str) and reason.startswith("lock:"):
                match = LOCK_HOLDER_RE.search(reason)
                if match:
                    return frontier(match.group(1), visited | {workstream})
                return {(workstream, "lock conflict; inspect owner")}

        if classification == "parked_draft":
            return {(workstream, "draft; planning or human gate")}
        if classification == "dependency_lock_blocked":
            return {(workstream, "explicit block; inspect live audit reasons")}
        return {(workstream, str(classification))}

    for row in rows:
        if not isinstance(row, dict) or row.get("claim_next_eligible"):
            continue
        identity = row.get("workstream") or row.get("path") or "(unidentified)"
        for root in frontier(identity):
            roots[root].add(identity)

    ordered = sorted(roots.items(), key=lambda entry: (-len(entry[1]), entry[0]))
    return {
        "schema": "custodian.queue_frontier.v1",
        "source_audit_schema": audit.get("schema"),
        "packet_rows": len(rows),
        "claimable_auto": sum(bool(p.get("claim_next_eligible")) for p in rows
                              if isinstance(p, dict)),
        "source_claimable_auto": audit.get("claimable_auto_count"),
        "classes": audit.get("class_counts", {}),
        "interrupted_dispatch_claims": audit.get("interrupted_dispatch_claim_count"),
        "top_blocking_frontiers": [
            {"root": root, "cause": cause, "downstream_packet_count": len(affected),
             "examples": sorted(affected)[:4]}
            for (root, cause), affected in ordered
        ],
        "claimable_packet_ids": sorted(
            p["workstream"] for p in rows if isinstance(p, dict)
            and p.get("claim_next_eligible") and p.get("workstream")
        ),
        "warnings": [
            "Roots can overlap; downstream counts must not be summed.",
            "Historical audits are not current host liveness or claim authorization.",
            "This is analysis only, not a lock/review/dependency bypass.",
        ],
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("audit_json", type=Path)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--top", type=int, default=25)
    args = parser.parse_args(argv)
    if args.top < 1:
        parser.error("--top must be positive")
    try:
        report = analyze(json.loads(args.audit_json.read_text(encoding="utf-8")))
    except (ValueError, OSError, json.JSONDecodeError) as error:
        parser.error(str(error))
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
        return 0
    print(f"Packets: {report['packet_rows']} | auto-claimable: {report['claimable_auto']}"
          f" | interrupted claims: {report['interrupted_dispatch_claims']}")
    print("Classes:", ", ".join(
        f"{name}={count}" for name, count in sorted(report["classes"].items())))
    print("Claimable IDs:", ", ".join(report["claimable_packet_ids"]) or "(none)")
    print("Root blocker frontiers (overlapping downstream counts):")
    for item in report["top_blocking_frontiers"][:args.top]:
        print(f"  {item['downstream_packet_count']:4d}  {item['root']} ({item['cause']})")
        print("       e.g. " + ", ".join(item["examples"]))
    print("Evidence only: never treat a blocker ranking as permission to release claims.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
