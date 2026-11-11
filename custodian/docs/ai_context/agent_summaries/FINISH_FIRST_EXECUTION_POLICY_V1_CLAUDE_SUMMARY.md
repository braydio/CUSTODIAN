# Finish-First Execution Policy Summary

Workstream: `finish-first-execution-policy-v1`

## Result

Updated the CUSTODIAN agent rules, CUSTODIAN Next skill, and lifecycle guide to
keep an explicitly selected unfinished workstream current until its acceptance
is complete or a genuine blocker is recorded. The guidance distinguishes
readiness, claim, implementation, landing, validation, and closure; requires
acceptance evidence before reporting completion; preserves claims and review
evidence; favors focused validation for bounded reversible work; and directs
agents to fix workflow defects in their existing owners.

Corrected the task-packet template's `Publication inputs` example and guidance
to match the live parser: individually backticked paths separated by
semicolons, or exactly `none`. Added a regression test that reads the template
field and validates it through the parser.

## Validation

- `python3 -m unittest test_task_packet_contract`: PASS (32 tests).
- `python3 -m unittest test_next_execution_boundary`: PASS (18 tests; existing
  routing behavior retained).
- `python3 custodian/tools/agent/check_ai_context.py --json`: PASS, zero findings.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`:
  PASS, 8/8 selected checks and complete changed-file coverage.
- `git diff --check`: PASS.

## Protected follow-up

The existing `next_execution_boundary.py` behavior and test demonstrate that an
explicit global-next request can fall through from a `blocked` phase to
`claim_general_next` when a general candidate is eligible. The intended
finish-first correction changes dispatch-boundary enforcement, which is
protected by repository review policy. This workstream leaves that helper and
its tests unchanged. Next action: open/claim the focused protected
workflow-correction workstream with a fresh independent review, then add a
regression asserting a blocked selected workstream cannot be replaced by a
general candidate and implement the same-workstream blocker handoff contract.

## Handoff

The Memorial Slab installation is complete on `origin/main` at
`695179d2ba6c9233147984f427ba5476e3f47475`. This policy change is separate and
must not reopen or modify that art workstream. No authoring-chat URL was
recorded for this policy-only workstream.
