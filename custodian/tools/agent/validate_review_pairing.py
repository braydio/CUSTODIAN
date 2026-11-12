#!/usr/bin/env python3
"""Advisory diagnostic for the retired paired post-land review contract.

Paired review was retired 2026-11-12 by owner decision. This script still
reports, for any packet that still declares `Review: auto` with a paired
review, whether that pair matches — but a pairing mismatch is advisory only
and never fails the check, CI, or a claim. Only missing explicit validation
script paths (a real broken reference) still fail. New packets should use
`Review: none`; do not author new paired reviews.
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

SCRIPT = Path(__file__).with_name("dispatch.py")
SPEC = importlib.util.spec_from_file_location("custodian_dispatch_validator", SCRIPT)
dispatch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = dispatch
SPEC.loader.exec_module(dispatch)


def main() -> int:
    repo = Path(dispatch.git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
    dispatch._fetch(repo)
    # Validate the checked-out candidate tree so the closeout gate tests packet
    # changes on a task branch before those changes land. Dispatch itself still
    # validates fetched origin/main before any real claim.
    packets = dispatch._packets(repo, "HEAD")

    # Scope is the review-pairing contract only: many active packets predate the
    # `Workstream:`-header dispatcher convention entirely and already carry
    # unrelated parse errors (missing Status, non-kebab Workstream, and so on).
    # Those are historical documents, not this guard's concern; flagging them
    # here would make this check fail on unrelated pre-existing drift.
    pairing_errors = dispatch.validate_review_pairing(packets)
    claimed = dispatch._claimed(repo)
    validation_errors = dispatch.validate_packet_validation_references(
        repo, packets, tree="HEAD", exclude_workstreams=claimed,
    )
    if pairing_errors:
        for workstream, message in sorted(pairing_errors.items()):
            print(f"ADVISORY (retired paired review, non-blocking): {workstream}: {message}")
    if not validation_errors:
        reviewed = sum(1 for p in packets if p.review == "auto")
        print(f"validate_review_pairing: PASS ({reviewed} Review: auto packet(s) declared; pairing is advisory only)")
        return 0

    for workstream, message in sorted(validation_errors.items()):
        print(f"FAIL: {workstream}: {message}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
