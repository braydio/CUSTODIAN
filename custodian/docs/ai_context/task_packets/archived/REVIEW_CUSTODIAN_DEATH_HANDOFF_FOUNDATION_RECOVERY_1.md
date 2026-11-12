# REVIEW: CUSTODIAN DEATH HANDOFF FOUNDATION RECOVERY 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-custodian-death-handoff-foundation-recovery-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `custodian-death-handoff-foundation-recovery-1`
- Locks: `custodian-death-flow, operator-runtime`
- Review: `none`
- Review target workstream: `custodian-death-handoff-foundation-recovery-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/CUSTODIAN_DEATH_HANDOFF_FOUNDATION.md`
- Reviewed main: `5a82486a46f30ad8753625133e1c6cee7eddd958`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the recovered R1 death handoff lands the intended campaign-level exactly-once death consequence on current main without importing stale branch architecture or regressing the Operator/runtime decomposition.
- Reviewed implementation acceptance: Reuse the archived R1 packet's full Acceptance contract, with special attention to exactly-once campaign resolution, fallback ordering, no direct Operator life decrement, unchanged facility/siege terminal failures, and no recovery/armament scope creep.
- Review evidence: Archived refreshed R1 packet and closing summary; diff against the stranded donor checkpoint; focused death-handoff/campaign outcome/game-over validation; current Operator architecture debt/audit; changed-file closeout.
- Correction threshold: Any duplicate campaign outcome, actor-owned life decrement, fallback-before-campaign ordering, stale branch architecture reintroduced into current main, or material proof gap is correction-worthy. Cosmetic/docs-only nits are non-blocking.
- Focused validation: Re-run the implementation-created death-handoff smoke plus `game_over_flow_smoke.gd`, `campaign_outcome_exactly_once_smoke.gd`, the narrow live world-simulation/binding regression selected by the landed diff, architecture debt audit for unexpected new debt, and one changed-file closeout.
- Review focus: (1) current-main integration rather than stale-branch wholesale merge; (2) one structured lethal event -> one campaign failure; (3) compatibility Game Over only after recognized campaign failure when a campaign exists; (4) safe legacy fallback when no campaign can accept the handoff; (5) Operator death presentation/telemetry preserved; (6) no additional Operator domain ownership moved into the actor.
- Acceptance: Produce a findings-first independent review on live main with stable IDs and a passed receipt or bounded correction packet. Do not patch reviewed implementation code.
- Recovery planning chat: https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search. If this review is clean/non-blocking, R2 remains dependency-gated on reviewed H6; if this review changes R2's required seam, the closing summary must cite this exact URL and mark R2 refresh-required.
- Non-goals: No Post recovery, Crèche recovery, armament registration, inventory persistence, death-site persistence, or unrelated Operator decomplexification.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Run the independent R1 review. On clean/non-blocking completion, preserve R2 as dependency-gated on reviewed H6 and surface https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search in the closing summary because R2 requires architecture-sensitive refresh after both reviews.
- Blockers or open questions: none for R1 review; R2 cannot become ready until `review-hub-campaign-return` is complete.
