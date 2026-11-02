# REVIEW: NPA-6 ENEMY DEATH, CORPSE AND LOOT LIFECYCLE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-6-enemy-death-corpse-loot-extraction`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-6-enemy-death-corpse-loot-extraction`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `npa-6-enemy-death-corpse-loot-extraction`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_6_ENEMY_DEATH_CORPSE_LOOT_EXTRACTION.md`
- Reviewed main: `dd17a65e7`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that NPA-6 moved Enemy health and death/corpse lifecycle state behind one focused owner while preserving public combat, loot, reification and host-integration behavior.
- Reviewed implementation acceptance: Use the archived NPA-6 packet's complete Acceptance contract. Require one mutable lifecycle authority, stable Enemy façade APIs without shadow state, exact damage-result/death semantics, single payload transfer and reward, authored config parity, correct corpse cleanup, intact NPA-5 paired-execution host boundary, and validation ownership.
- Review evidence: Archived NPA-6 packet and implementation summary; lifecycle/config source; Enemy façade/callback diff; scene config bindings; corpse loot/carrier components; reification and loot consumers; focused lifecycle, death, paired-execution and changed-file validation reports.
- Correction threshold: Duplicate health/death/corpse state on Enemy; broken damage-result fields/order or lethal paths; repeated death/payload/reward; table-fallback or authored-config drift; invalid collector/reward behavior; cleanup threshold/camera geometry drift; reification API break; NPA-5 damage callback or token regression; lifecycle authority absorbing presentation, BSM or global reward policy; private mutation remaining in tests/callers; or material validation gaps creates bounded correction work.
- Focused validation: Re-run the NPA-6 lifecycle smoke, `lootable_corpse_beacon`, `authored_vault_grunt_loot_marine`, world-simulation actor reification handoff, NPA-5 reaction/parry-critical and paired-execution lethal controls; run changed-file validation and `git diff --check`.
- Review focus: one coherent health/death/corpse owner; facade delegation with no second mutable source; host callbacks and ordering; existing collector/carrier boundaries; typed authored config parity; death observability and paired execution; reification restoration; minimum/offscreen/hard corpse cleanup; no health-system or universal NPC superclass.
- Acceptance: Findings-first fresh-context review with zero blocking defects/material evidence gaps for pass. Record stable cycle-scoped finding IDs and evidence. Correction-worthy findings use normal bounded correction/re-review lineage. Do not patch reviewed implementation.
- Non-goals: No loot economy or balance changes; no corpse art/VFX/audio redesign; no general actor health abstraction; no persistence schema, spawn/wave, Operator death/campaign, or cross-family changes.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Independent Review

- Review schema: `custodian.independent_review.v1`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed implementation SHA: `4fda2ffa1`
- Verdict: `pass`
- Findings: `none`
- Evidence: Fresh focused checks passed for lifecycle/corpse behavior, authored vault/loot behavior, lifecycle config parity, world-simulation reification, NPA-5 reaction posture, parry-critical, and standard Enemy melee after initializing the fresh Godot import cache. The blocked review's changed-file and whitespace checks were infrastructure failures caused by writes to shared `.git` LFS/FETCH_HEAD storage. The recovery artifact `VALIDATION_EVIDENCE.md` identifies the implementation workstream's post-sync changed-file report at target main `c5d4c19fe99be2a2164a878609413391f250d213`: 42/42 selected passed, no failures/timeouts/skips/infrastructure errors, complete coverage, and `review_pairing_contract` passed; it was supplied to that target's finish. `FILTER_SAFE_DIFF_CHECK.txt` records successful `git -c filter.lfs.process= -c filter.lfs.clean=cat diff --check 4fda2ffa1^ 4fda2ffa1` with no whitespace errors. These match the reviewed implementation commit `4fda2ffa1` and close the material evidence gap without repeating prohibited shared-metadata commands. Source review found one `EnemyLifecycle` mutable owner for health/death/payload/corpse clocks; Enemy preserves the damage/death/reification façade and effectful host callback ordering; `EnemyCorpseLoot` and `EnemyLootCarrier` retain their reward and captured-resource boundaries; typed scene configs and architecture ownership match the packet. No blocking or material non-blocking defect remains. `RV0-01` is resolved.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: `The initial review's changed-file and diff commands attempted writes under shared .git LFS/FETCH_HEAD paths; these checks were initially treated as an unresolved evidence gap.`
- Root cause / contributing factors: `The review worktree shares Git metadata outside the writable roots; the target implementation finish retained equivalent post-sync validation and LFS-safe diff evidence in its recovery artifact.`
- Prevention / pipeline improvement: `Accept matching implementation-finish validation evidence for the exact landed target when review-worktree Git metadata is read-only; do not retry changed-file discovery in that environment.`
- Tooling / docs drift discovered: `Review validation instructions do not identify the shared-Git-metadata write constraint in restricted review worktrees.`
- Follow-up: fixed-in-scope
- What worked: `Focused checks plus durable implementation-finish evidence satisfied the review contract without retrying a known read-only shared-metadata operation.`

## Handoff

- Next workstream: `npa-7-commanded-ally-contracts-planning`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `NPA-7 has only a roadmap outcome; remeasure reviewed standard-agent lifecycle APIs and real commanded-ally consumers before defining shared contracts.`
- Next action: `After this review passes, stop and refresh NPA-7 planning in the Authoring chat from reviewed live runtime.`
- Blockers or open questions: `NPA-7 implementation boundary remains intentionally unauthored.`
