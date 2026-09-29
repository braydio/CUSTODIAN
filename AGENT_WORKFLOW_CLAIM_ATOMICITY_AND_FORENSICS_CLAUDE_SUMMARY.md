# Agent Workflow Claim Atomicity and Forensics

## What changed

- Added `workflow_control.py` as the shared source for common-dir mutexes, unique remote claim acquisition/release, secret redaction, and append-only structured run traces.
- `dispatch.py` now uses the shared remote claim primitive and per-workstream mutex while preserving the existing assignment receipt and `last-claim` behavior.
- `workstream.py start` claims before creating a worktree, verifies the published branch before releasing its claim, and refuses existing remote/local/attached state. `workstream.py resume` is the explicit path for inspected clean attached or published workstreams; dirty and local-only unique-commit worktrees remain untouched.
- Added `run_trace.py list` and `export`, automatic trace events through start, claim, checkpoint, validation, main sync, landing, and teardown, and best-effort diagnostic snapshots under `agent-diagnostics/<workstream>/<run-id>`.
- Landing rejects diagnostic refs; branch hygiene classifies them as `DIAGNOSTIC_PRESERVE` and refuses retirement. Updated lifecycle/validation docs and archived the completed packet.

## Evidence and validation

- Same-common-dir direct-start race: exactly one start wins; the loser leaves the winner's checkout intact.
- Independent-clone direct-start race: exactly one remote CAS succeeds and publishes the canonical agent branch.
- Injected worktree-creation failure preserves the remote claim; a retry through ordinary `start` fails closed.
- Trace test verified secret redaction and diagnostics-only ref publication. Existing dispatcher race/receipt tests remain green.
- `python3 -m py_compile` passed for the changed agent tooling.
- Focused workflow suite: 113 tests passed across `test_workflow_control`, `test_workstream`, `test_dispatch`, `test_workstream_artifacts`, `test_land_main`, `test_branch_hygiene`, and `test_review_contract`.
- `python3 custodian/tools/validation/agent_workflow_smoke.py` passed, including prompt-contract validation.

## Friction and deferred work

- Existing tests assumed `start` could silently resume remote branches. Those recovery cases now call `resume`; this makes ownership intent visible and testable.
- A create failure leaves a durable remote claim and any partial checkout for explicit recovery. There is no TTL or automatic stale-claim deletion, by design.
- Diagnostics are best-effort and remain outside task history. Cross-host liveness, retention policy, and tracing arbitrary shell/model activity remain deferred.

## Execution Feedback

- Outcome: Direct creation now shares dispatch's ownership primitive, local races serialize before checkout mutation, and operators can reconstruct the lifecycle from exported structured traces.
- Friction: A local-only attached checkout can be recoverable but cannot prove assignment ownership; dispatch therefore leaves it untouched and blocks instead of adopting it.
- Prevention: Concurrency, interrupted-create, redaction, and ref-isolation checks cover those failure boundaries.
- Validation: 113 focused agent workflow tests and the agent workflow contract smoke passed.
- Deferred: Explicit operator resolution remains necessary for stale claims; no lease expiry or automated diagnostics cleanup was added.
