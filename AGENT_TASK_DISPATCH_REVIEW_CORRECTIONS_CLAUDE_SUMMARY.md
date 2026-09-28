# Agent Task Dispatch Review Corrections Summary

## What changed

- Added a unique claimant commit and create-only push to `refs/heads/dispatch-claims/<workstream-id>`. Independent clones now race on different object IDs at the same absent remote ref; normal Git push semantics permit only one creation.
- After `workstream.py start`, dispatch fetches and confirms `origin/agent/<id>` before deleting the temporary claim. An interrupted temporary claim without its canonical branch blocks future claims and status shows explicit inspection/recovery instructions. A failed marker cleanup leaves the marker and the published workstream remains claimed.
- Added temporary-repository coverage for two independent clones, orphan claim recovery, branch-plus-marker status, cleanup failure, and dispatch from an attached non-main worktree. The latter proves packet discovery uses fetched `origin/main` and creates the sibling worktree through the persistent coordination checkout while preserving the existing task branch/files.
- Archived the completed correction packet and corrected lifecycle, validation recipe, file index, packet README, and automation backlog references.

## Validation and evidence

- `python3 custodian/tools/agent/test_dispatch.py` — 28 passed.
- `python3 -m unittest custodian.tools.agent.test_land_main custodian.tools.agent.test_workstream custodian.tools.agent.test_workstream_artifacts custodian.tools.agent.test_branch_hygiene` — 27 passed.
- `python3 custodian/tools/validation/agent_workflow_smoke.py` — passed, including prompt-contract self-test and agent workflow tests.
- `python3 -m py_compile custodian/tools/agent/dispatch.py custodian/tools/agent/test_dispatch.py` — passed.
- `git diff --check` — passed.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — passed 4/4 selected checks, zero failures/timeouts/infrastructure errors. Green report: `/tmp/agent-task-dispatch-review-corrections-validation.json`.
- The first focused test run correctly rejected four mocked `workstream.start` calls that did not publish a branch. Their mocks were updated to exercise the required publication contract; all focused tests then passed. A cleanup-failure test initially matched the claim-creation push too; the test condition was narrowed to the explicit delete refspec and passed.
- No unrelated lattice canon failure reproduced; `lattice_canon_docs` passed in the changed-file run.
- Moment Forge: not run — tooling and documentation only, with no runtime or presentation changes.

## Deferred

No age-based recovery, lease service, daemon, database, continuous worker, or review pipeline behavior was added. An operator must verify there is no live claimant before explicitly deleting an orphan remote claim ref.
