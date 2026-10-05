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
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
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