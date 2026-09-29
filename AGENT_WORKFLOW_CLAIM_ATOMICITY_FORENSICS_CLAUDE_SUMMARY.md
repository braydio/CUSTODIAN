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

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The summary used the packet title's `AND` token rather than the workstream-ID-derived canonical filename; finish reported the expected filename missing before completing.
- Root cause / contributing factors: The packet title and stable workstream slug differ, and the completion review checked the title-derived name instead of the lifecycle's slug-derived contract.
- Prevention / pipeline improvement: Derive the summary filename from the stable workstream ID and verify its exact path before invoking finish.
- Tooling / docs drift discovered: The finish path emitted a fatal-looking missing-file probe while continuing; the final artifact gate did not make this mismatch obvious.
- Follow-up: fixed-in-scope
- What worked: Shared remote claim CAS and common-dir locks serialize new starts; diagnostic traces remain outside task/main refs.
