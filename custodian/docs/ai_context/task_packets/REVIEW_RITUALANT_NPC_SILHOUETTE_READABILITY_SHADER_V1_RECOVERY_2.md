# REVIEW: RITUALANT — NPC SILHOUETTE READABILITY SHADER V1 RECOVERY 2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-ritualant-npc-silhouette-readability-shader-v1-recovery-2`
- Category: `assets-art`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `ritualant-npc-silhouette-readability-shader-v1-recovery-2`
- Locks: `ritualant-npc-presentation`
- Review: `none`
- Review target workstream: `ritualant-npc-silhouette-readability-shader-v1-recovery-2`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2.md`
- Reviewed main: `ecd4ac324d42e7bc8183fcd7ea0d05732c75ec46`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the actor-local readability treatment against the exact production scene and the authored visual acceptance, without silently broadening it into an encounter, room-FX, or sprite replacement.
- Reviewed implementation acceptance: Check all numbered Change clauses and Acceptance from the archived implementation packet; verify the recorded October 17 approval of candidate 03678c0af88caf911166040a06fba460bcf4d2e0 from the durable receipt; do not request that same sign-off again.
- Review evidence: Archived packet, implementation closeout summary with the exact authoring URL, actual `forlorn_ritualant_site.tscn` and production `AnimatedSprite2D` material, shader/material resources, pixel/alpha tests, completion and underground smoke receipts, compact human-reviewed Dropbox artifact manifest/decision.
- Correction threshold: Missing material on the real animated character, false lighting/canon, opaque-alpha leaks, atlas/frame bleed, lost dissolve/death alpha, shadow persisting after disappearance, altered gameplay/animation authority, missing subjective approval, or materially unproven runtime integration.
- Focused validation: Reuse implementation's focused shader/sprite alpha and `res://tools/validation/forlorn_ritualant_completion_smoke.gd` tests; check authored underground integration and original-vs-landed node/geometry/animation/phase invariants. Do not recapture the same visual frames if durable evidence and decision remain current.
- Review focus: Original production AnimatedSprite2D rather than legacy hidden Visual; no illicit global screen FX; correct physically grounded ash/continuity edge treatment; no more than small subjective visual intervention; no nearby north route, White Thread, scene geometry, combat or audio mutation.
- Acceptance: Findings-first independent review with stable R0 IDs, exact failing evidence if any, and clear status of human visual approval. No edits to reviewed implementation.
- Non-goals: No rewrite of shaders under review, replacement character art, broader scene restyling, nor repeat visual capture without evidence deficiency.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Summary backlink: Include this exact Authoring chat URL in all durable review/correction handoffs. Original visual-decision conversation: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20.
- Refresh reason: `none`
- Next action: Return the review outcome and accepted Ritualant visual evidence to this conversation; then resume the Forlorn Ritualant soundtrack at Track 07/08.
- Blockers or open questions: `none` unless an objective defect or missing human visual decision is found.


## Supersession and review boundary

This review covers only the exact landed recovery-2 implementation and its durable validation/evidence. The user-owned subjective visual decision for the unchanged approved shader treatment is already satisfied by the 2026-10-17 decision receipt (`custodian/docs/ai_context/reports/ritualant_npc_silhouette_readability_shader_v1_human_visual_decision.md`, candidate `03678c0af88caf911166040a06fba460bcf4d2e0`, ROI SHA-256 `dffb67e0369b018c4fd5deb2410bf1634207bac62622f4695f20af3ef42931df`). `Visual review: conditional` means no new human approval is pending before independent technical review; the reviewer must still check actual landed visual/alpha/phase integration, and may escalate a genuinely new subjective or materially changed visual decision as `human_required` rather than assuming acceptance. Recovery-1 is superseded, blocked/manual, not complete and not accepted because its historical d06bde080 post-sync validation cannot pass against the repaired import metadata now on main at ecd4ac324d42e7bc8183fcd7ea0d05732c75ec46. Do not treat recovery-1 or its unfinished review as a predecessor, implementation acceptance, or review evidence. Recovery-2 has no dependency on recovery-1's review. Verify the existing October 17 human visual decision from `custodian/docs/ai_context/reports/ritualant_npc_silhouette_readability_shader_v1_human_visual_decision.md` and https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20, while independently checking objective alpha, atlas, production scene binding, phase and runtime requirements against the exact landed source.
