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
- Reviewed main: `5a82486a46f30ad8753625133e1c6cee7eddd958`
- Review modes: `code, architecture, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the recovered Marine Dash extraction preserves exact tactical behavior/tuning and current non-player architecture while avoiding stale-branch imports or duplicate ability authority.
- Reviewed implementation acceptance: Reuse the archived Marine extraction packet's full Acceptance contract and require current-main equivalence for quick/charged cadence, prediction lock, collision/contact, impact/recovery/reset, telemetry and Sundered Keep ambush integration.
- Review evidence: Archived recovery packet/summary; diff against the stranded donor branch; Marine ability/config code and scene resource; focused Marine/spatial/ambush validation; non-player architecture ownership map.
- Correction threshold: Duplicate Marine phase state in `enemy.gd`, tuning drift, private external phase calls, changed combat outcomes/telemetry, stale branch architecture, or material proof gaps create correction work.
- Focused validation: Re-run the focused Marine smoke, spatial telemetry smoke, production-map ambush smoke, directly selected enemy regressions, changed-file closeout and `git diff --check`.
- Review focus: one Marine Dash owner; exact tuning parity; actor host only supplies shared services; no generic ability base invented; no Savage/Falcon scope bleed; current-main integration rather than stale branch wholesale merge.
- Acceptance: Findings-first fresh-context review with passed receipt or bounded correction packet. Do not patch reviewed implementation code.
- Non-goals: No Marine rebalance, new art/audio, Savage/Falcon rewrite, generic ability hierarchy or broad `enemy.gd` cleanup.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next action: Auto-dispatch after `enemy-marine-dash-ability-extraction-recovery-1` completes and archives.
- Blockers or open questions: none.
