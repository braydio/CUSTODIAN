# REVIEW: WORKSTREAM FINISH LANDED CLOSEOUT HARDENING

- Workstream: `review-workstream-finish-landed-closeout-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `workstream-finish-landed-closeout-hardening`
- Locks: `agent-workflow`
- Review: `none`
- Review target workstream: `workstream-finish-landed-closeout-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/WORKSTREAM_FINISH_LANDED_CLOSEOUT_HARDENING.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the corrected workstream finish lifecycle safely handles already-landed tasks without weakening artifact, validation, publication, or dirty-root protections.
- Review focus: already-landed short-circuit; durable closing-summary proof; no unnecessary history rewrite; correct published-ref guard; idempotent teardown; preservation of unlanded commits; dirty-root non-mutation; regression safety for ordinary landing and dispatch.
- Acceptance: Findings-first review either records a clean pass or queues a bounded correction through the live review pipeline. Reviewer must not patch the reviewed workflow code directly.
- Non-goals: Do not redesign dispatch, continuous workers, or branch hygiene generally.

## Required Checks

1. Reproduce the already-landed state in a temporary bare-remote fixture.
2. Prove summary/artifact validation still occurs when `origin/main...HEAD` is empty.
3. Prove an unlanded extra commit prevents false already-landed teardown.
4. Prove unrelated published refs still block rewrite while the canonical own task branch does not.
5. Prove dirty persistent main remains byte-for-byte/worktree-status unchanged.
6. Prove ordinary not-yet-landed finish remains green.
7. Inspect docs for agreement with actual behavior.
8. Record blocking findings and use the correction/re-review contract if needed.

## Handoff

- Next action: Auto-dispatch after the hardening implementation lands.
- Blockers or open questions: Blocked only by `workstream-finish-landed-closeout-hardening`.
