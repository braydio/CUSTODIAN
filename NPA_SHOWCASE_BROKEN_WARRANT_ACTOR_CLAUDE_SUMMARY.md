# NPA Showcase Broken Warrant Actor — Blocked Handoff

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Work completed

Implemented a dev-only Broken Warrant scene on the existing EnemyGrunt/Enemy authorities, with its own typed melee, reaction, parry-critical, lifecycle, and behavior configuration. Added the `spawn_broken_warrant` developer command, disabled Grunt Falcon Punch, labeled the donor art provisional, and kept the actor out of normal wave composition. Added an actor smoke that exercises real melee, parry/stagger, death, corpse loot, and the once-only ResourceLedger award. Updated the NPA program and current-state/index/arena documentation to record the implementation and missing original art family.

## Validation

The focused actor smoke and shared melee, reaction, parry-critical, corpse-loot, lifecycle, wave debug spawn gate, and DevConsole checks passed. Repository context, review-pairing, packet-index, and diff checks passed. The changed-file sweep selected 42 checks: 38 passed, three existing procgen checks timed out at 120 seconds (`command_terminal_tutorial`, `terminal_page_order_regression`, `terminal_sensors_layout`), and `awakening_late_seams_v1` was skipped downstream. Coverage was complete with no uncovered files. Raising those three timeout values did not resolve the issue; those unrelated manifest changes were reverted. This validation failure blocks completion and paired review.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: three existing procgen-backed checks exceeded 120 seconds in the changed-file sweep.
- Root cause / contributing factors: broad owner-linked validation includes slow procedural world generation under a shared constrained runtime.
- Prevention / pipeline improvement: rerun the same changed-file sweep when those checks can complete within their configured timeout; do not widen global timeouts without a task-scoped measured fix.
- Tooling / docs drift discovered: none
- Follow-up: npa-showcase-broken-warrant-actor
- What worked: the focused new actor and shared-authority tests were fast and green.

## Next Handoff
- Next workstream: general dispatcher claim-next stream (user-directed continuation)
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: checkpoint this preserved blocked workstream, then use `dispatch.py claim-next --agent codex` and continue within the user's finite 15-packet run.
- Blockers or open questions: three existing procgen checks exceeded the configured timeout; implementation completion and paired review remain pending.
