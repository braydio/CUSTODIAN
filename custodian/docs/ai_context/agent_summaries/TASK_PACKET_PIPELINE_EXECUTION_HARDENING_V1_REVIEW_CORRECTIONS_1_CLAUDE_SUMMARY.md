# Task Packet Pipeline Execution Hardening V1 Review Corrections 1

## What changed

- Added public `header_field()` as the shared interface to the existing continuation-folding parser, then changed the Ready/Auto index renderer to use it. Its local Goal fallback and 160-character truncation remain unchanged.
- Added a focused monkeypatch test proving Goal rendering uses the shared parser result.
- Added the user's temporary task-routing note to `custodian/AGENTS.md`: through 2026-10-01 00:00 America/New_York, agents other than Claude skip procgen-family packets; Claude is explicitly allowed to claim and work them. Extended the existing scheduled cleanup to remove the note and self-delete at that expiry.
- Added workflow smoke assertions for the date, UTC expiry, skip rule, Claude exception, and cleanup markers.
- Marked the correction packet complete, archived it, and removed it from the active packet index.

## Validation and evidence

- `python3 custodian/tools/agent/test_task_packet_index.py`: passed, 11 tests (10 existing assertions/tests unchanged plus the new shared-helper test).
- `python3 custodian/tools/agent/test_task_packet_contract.py`: passed, 18 tests.
- `python3 -m py_compile custodian/tools/agent/task_packet_contract.py custodian/tools/agent/task_packet_index.py custodian/tools/validation/agent_workflow_smoke.py`: passed.
- `python3 custodian/tools/validation/agent_workflow_smoke.py`: passed all workflow contract checks (prompt contracts, landing, dispatch, review, and temporary routing expiry).
- `git diff --check`: passed.
- `python3 custodian/tools/agent/check_ai_context.py`: reports three existing README-index findings unrelated to this change: `ASH_BELL_FORLORN_RITUALANT.md` is complete but listed In Progress; `BLACK_RELIQUARY_LIVE_MINIMAP.md` is listed In Progress without Status; `OPERATOR_FAST_CHAIN_INBOX_RECONCILIATION.md` is archived but listed Ready/Auto. No finding concerns this task packet or the touched workflow contract. These were left outside scope.
- No output artifacts from validation were retained; no generated or source assets were changed.

## Negative controls and deferred work

- The helper test supplies a deliberately different shared-parser value and asserts the renderer returns it, so a reintroduced local folding implementation would fail the test.
- No procgen content or runtime code was changed. Other packet families remain eligible under the normal dispatcher rules.
- The expiry workflow uses its existing fixed cutoff at 2026-10-01 04:00 UTC. Scheduled workflow dispatch can be delayed by GitHub; the cleanup itself only runs after the fixed cutoff and is also manually dispatchable.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: The requested timed tasking note extended beyond the correction packet's original parser scope.
- Root cause / contributing factors: The repository already had a self-removing temporary-instruction workflow that could safely own the note's expiry.
- Prevention / pipeline improvement: Added smoke coverage for the temporary instruction's end time and explicit Claude exception.
- Tooling / docs drift discovered: The cleanup cron was set for 00:17 America/New_York; aligned it with midnight.
- Follow-up: fixed-in-scope
- What worked: Existing marked-block cleanup allowed a narrowly scoped expiry extension.
