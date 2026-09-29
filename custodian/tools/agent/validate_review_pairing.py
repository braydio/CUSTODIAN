#!/usr/bin/env python3
"""Fail-fast consistency guard for the paired post-land review contract.

Every active task packet declaring `Review: auto` must have a matching active
review packet (`Kind: review`, `Review: none`, a dependency back on the
implementation workstream, and a matching target). Auto review packets also
need the exact bounded artifact override; ready packets' explicit validation
script paths must exist in the checked-out candidate tree.
Historical packets that omit review metadata are never required to pair; the
check only fires for packets that actively opt into `Review: auto`.

This is the one reusable validation authority for the pairing contract: it
wraps `dispatch.validate_review_pairing`, the same function `dispatch.py`
itself calls before making a packet eligible, so tooling and the live
dispatcher can never disagree about what a valid pairing looks like.
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
    repo = dispatch._coordination_repo(repo)
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
    for workstream, message in validation_errors.items():
        pairing_errors[workstream] = "; ".join(filter(None, (pairing_errors.get(workstream), message)))

    if not pairing_errors:
        reviewed = sum(1 for p in packets if p.review == "auto")
        print(f"validate_review_pairing: PASS ({reviewed} Review: auto packet(s) correctly paired)")
        return 0

    for workstream, message in sorted(pairing_errors.items()):
        print(f"FAIL: {workstream}: {message}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
