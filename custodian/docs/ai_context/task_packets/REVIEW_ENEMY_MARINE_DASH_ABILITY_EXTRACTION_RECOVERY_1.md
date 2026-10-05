# REVIEW: ENEMY MARINE DASH ABILITY EXTRACTION RECOVERY 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-enemy-marine-dash-ability-extraction-recovery-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `enemy-marine-dash-ability-extraction-recovery-1`
- Locks: `enemy-runtime`
- Review: `none`
- Review target workstream: `enemy-marine-dash-ability-extraction-recovery-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ENEMY_MARINE_DASH_ABILITY_EXTRACTION.md`
- Reviewed main: `67eb2d3e13`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed recovery implementation represented by checkpoint `9af2adf5914ed799f4c7ee7606202b03ea5a95f1`: Marine Dash must preserve exact tactical behavior/tuning and current non-player architecture while avoiding stale-branch imports, duplicate ability authority, or validation exemptions.
- Reviewed implementation acceptance: Reuse the archived Marine extraction packet's full Acceptance contract and require current-main equivalence for quick/charged cadence, prediction lock, collision/contact, impact/recovery/reset, telemetry and Sundered Keep ambush integration.
- Review evidence: Archived recovery packet/summary; recovery checkpoint `9af2adf59`; Marine ability/config code and scene resource; exact 26-default + 26-scene-value parity evidence; focused Marine/spatial/production-ambush validation; changed-file closeout after the external baseline validation defect is repaired; non-player architecture ownership map.
- Correction threshold: Duplicate Marine phase state in `enemy.gd`, tuning drift, private external phase calls, changed combat outcomes/telemetry, stale branch architecture, or material proof gaps create correction work.
- Focused validation: Re-run the focused Marine smoke, spatial telemetry smoke, and production-map ambush smoke. Confirm the required changed-file closeout is green on the landed implementation. The pre-land `grunt_falcon_reversal` failure reproduced on clean main and is not a Marine finding by itself; however, this review must not pass until that baseline validation owner is repaired and the full selected closeout can complete normally.
- Review focus: one Marine Dash owner; exact 26-field default and Marine-scene tuning parity; `enemy.gd` net reduction remains approximately 343 lines from the measured 4,958-line baseline unless fresh-main reconciliation justifies a different count; Sundered Keep uses the public request seam; actor host only supplies shared services; no generic ability base invented; no Savage/Falcon scope bleed; current-main integration rather than stale branch wholesale merge.
- Acceptance: Findings-first fresh-context review with passed receipt or bounded correction packet. Do not patch reviewed implementation code.
- Non-goals: No Marine rebalance, new art/audio, Savage/Falcon rewrite, generic ability hierarchy or broad `enemy.gd` cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Auto-dispatch after `enemy-marine-dash-ability-extraction-recovery-1` completes and archives.
- Blockers or open questions: none.
## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Refresh instruction: If review finds a material ownership/tuning/caller difference from checkpoint `9af2adf59`, bring the review evidence back to this chat before changing the NPA-2 host-service contract or broader actor architecture.

## Review Progress

- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed landed main: `1ba0981e7859fa91ae86ea3bc638c0ce2474a1ad`
- Outcome: `pending`; no Marine blocking defect found. R0-01 is low-severity next-slice ownership prose drift. R0-02 is external changed-file coverage drift: all 23 selected tests pass, but `.agents/skills/custodian-next/agents/openai.yaml` is uncovered and makes the required report false (exit 6).
- Runtime evidence: Three required focused tests pass after fresh-worktree import; parity is exactly 26 defaults + 26 scene values; `enemy.gd` is exactly 343 lines smaller. Detailed receipt: `REVIEW_ENEMY_MARINE_DASH_ABILITY_EXTRACTION_RECOVERY_1_CLAUDE_SUMMARY.md`.
- Preserve this workstream until the external owner gate is repaired; do not edit reviewed implementation or exempt validation.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: Every selected closeout test passed, but the report failed coverage for unrelated current-main skill metadata; an initial focused invocation ran only its final repeated --test argument and encountered the fresh worktree's empty import cache.
- Root cause / contributing factors: Commit 48d0871bb added .agents/skills/custodian-next/agents/openai.yaml without a validation owner. The focused CLI accepts one --test value, and fresh worktrees need initial Godot import before tests that omit needs_import.
- Prevention / pipeline improvement: Repair the skill metadata's genuine validation ownership in a separate workstream; run individual focused IDs serially after import preflight/import.
- Tooling / docs drift discovered: task_packet_index.py cannot find its uninitialized managed Ready/Auto block; VALIDATION_RECIPES.md explicitly documents that migration as separately reviewable. Stale Marine ownership prose remains in CONTEXT.md:117 and CURRENT_STATE.md:1486.
- Follow-up: manual-follow-up
- What worked: Independent 26-default/26-scene parity, state/caller audit, focused runtime gates, and all 23 selected closeout checks passed.

## Next Handoff
- Next workstream: review-enemy-marine-dash-ability-extraction-recovery-1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search
- Refresh reason: Required closeout is not green until current-main skill metadata has a validation owner.
- Next action: Repair the unrelated coverage owner separately, then synchronize and resume this same review. After a passed review, refresh enemy-savage-pounce-ability-extraction in the authoring chat before implementation.
- Blockers or open questions: .agents/skills/custodian-next/agents/openai.yaml is the sole uncovered path in /tmp/npa1-review-closeout.json; no Marine blocking defect found.
