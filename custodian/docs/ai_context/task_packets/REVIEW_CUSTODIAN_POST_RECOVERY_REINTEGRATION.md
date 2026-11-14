# REVIEW: CUSTODIAN POST RECOVERY REINTEGRATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-custodian-post-recovery-reintegration`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `custodian-post-recovery-reintegration`
- Locks: `custodian-death-flow, hub-runtime, world-lifecycle, operator-runtime`
- Review: `none`
- Review target workstream: `custodian-post-recovery-reintegration`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CUSTODIAN_POST_RECOVERY_REINTEGRATION.md`
- Reviewed main: `d5ae87bff7a7`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that R2 removes the R1 Game Over fallback only for a genuinely accepted death return, layers recovery on the reviewed H6 authority without duplicating it, and restores/re-arms the persistent Operator safely for a later death.
- Reviewed implementation acceptance: Reuse every Acceptance claim from the archived R2 packet, with special attention to exact death-outcome correlation, H6 single ownership, fallback safety, reintegration-before-rearm ordering, and two sequential lives.
- Review evidence: Archived R2 packet/summary; archived reviewed H6 evidence; live R1 binding and Operator recovery/reset code; implementation-created focused reintegration evidence; existing death-handoff and campaign-outcome regressions.
- Correction threshold: Duplicate outcome/Hub mutation/return ownership; Game Over suppression before a return is accepted; classifying unrelated FAILURE outcomes as death; a permanently latched or prematurely re-armed death binding; Operator control restored before Hub/world bindings are valid; or material proof gaps are correction-worthy. Cosmetic recovery wording or future armament ideas are next-slice/deferred.
- Focused validation: Re-run the implementation-created R2 death-return/reintegration smoke, `custodian/tools/validation/operator_death_campaign_handoff_smoke.gd`, `custodian/tools/validation/campaign_outcome_exactly_once_smoke.gd`, and the reviewed H6 focused return regression from live main; then the smallest control/binding regression needed to prove playable reintegration and one changed-file closeout.
- Review focus: (1) no second Campaign->Hub authority; (2) exact outcome identity, not generic failure classification; (3) fallback remains fail-safe only; (4) one persistent Operator; (5) death context survives until recovery completes; (6) binding re-arms only after successful reintegration; (7) second later death works exactly once.
- Acceptance: Produce a findings-first independent review on live main with stable IDs and a passed receipt or bounded correction packet. Do not patch reviewed implementation code.
- Non-goals: No local Crèche, armament persistence/registration, death-site weapon semantics, fabricated recovery infrastructure, or metaphysical explanation.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: After a clean/non-blocking review, R3 remains planning-chat refresh-gated.
- Blockers or open questions: implementation dependency only; R3 refresh uses https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search.
