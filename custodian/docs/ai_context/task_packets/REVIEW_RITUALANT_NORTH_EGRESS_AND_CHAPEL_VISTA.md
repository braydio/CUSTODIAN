# REVIEW: RITUALANT — NORTH EGRESS + DISTANT CHAPEL PRESENTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-ritualant-north-egress-and-chapel-vista`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `ritualant-north-egress-and-chapel-vista`
- Locks: `ritualant-underground-route, ritualant-camera-presentation`
- Review: `none`
- Review target workstream: `ritualant-north-egress-and-chapel-vista`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/RITUALANT_NORTH_EGRESS_AND_CHAPEL_VISTA.md`
- Reviewed main: `435c422d6cb5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the real camera-zone chapel reveal and post-resolution north route.
- Reviewed implementation acceptance: Verify real arrival-driven chapel visibility, correct retirement point, pre-resolution north block, post-resolution Highlands transition, safe reverse traversal and no encounter replay.
- Review evidence: Archived implementation packet/summary; live route/scene/camera code; focused Ritualant route/presentation evidence.
- Correction threshold: Confirmed acceptance defect or material proof gap only; subjective composition questions may become human_required.
- Focused validation: Re-run the landed Ritualant north-egress/camera proof, `res://tools/validation/forlorn_ritualant_completion_smoke.gd`, and BF1/BF2 lifecycle tests referenced by the archived packet.
- Review focus: Test-only profile handler shortcuts, seal visual opening without collision opening, pre-resolution escape, wrong Highlands spawn, reverse-travel loops, one-shot replay, camera authority not released.
- Acceptance: Findings-first fresh review with stable IDs; do not patch reviewed runtime.
- Non-goals: No bridge topology or Lower Quarter work.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next workstream: `bridged-falls-procgen-topology`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: BF4/BF5 should consume the reviewed route identity and Highlands geometry rather than draft assumptions.
- Next action: Bring review evidence back to the authoring chat and refresh BF4/BF5.
- Blockers or open questions: none unless review creates correction work.
