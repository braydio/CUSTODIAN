# REVIEW ENEMY HEALTH BARS AND PURSUIT FRAME PRESENTATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-enemy-health-bars-and-pursuit-frame-presentation-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `enemy-health-bars-and-pursuit-frame-presentation-v1`
- Locks: `enemy-runtime, combat-feel`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `enemy-health-bars-and-pursuit-frame-presentation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/ENEMY_HEALTH_BARS_AND_PURSUIT_FRAME_PRESENTATION_V1.md`
- Reviewed main: `55105e4a90546453d2a537add5d859305289411d`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently prove that shared HP/power bar color bleed is eliminated and Pursuit Frame's actual existing behavior phases, E/W melee and death animations render correctly in spawned runtime actors.
- Reviewed implementation acceptance: `A1–A6` from exact archived `ENEMY_HEALTH_BARS_AND_PURSUIT_FRAME_PRESENTATION_V1.md`.
- Review evidence: Landed implementation SHA, real-scene bar style identities/colors, two opposite-facing target/attack traces with sprite names and pixel-orientation evidence, state/animation 16-row matrix, death/interrupt fixtures, focused test logs, and changed-file report.
- Correction threshold: Any shared mutable bar resource, missed existing actor bar, incorrect E/W pixels/actions, BSM animation never reached, premature action interruption, skipped Pursuit death, false bespoke-intercept claim, stale visual evidence, or loss of existing combat/death behavior is a blocking defect or material proof gap.
- Focused validation: Rerun real-scene two-enemy plus Sector bar-isolation tests, Pursuit Frame E/W/opposite-motion/melee/knockback/BSM/reaction/death fixtures, `custodian/tools/validation/pursuit_frame_animation_set_smoke.gd`, `custodian/tools/validation/standard_enemy_melee_smoke.gd` and `custodian/tools/validation/pursuit_frame_asset_family_smoke.py`; check SHA-pinned pixel hashes for LFS E/W if needed; required paired/doc/changed-file checks without repeating full visualization sweeps.
- Review focus: Falsify shared StyleBox ownership, the mistakenly placed `_setup_health_bar_style` exit code, Sector health/power contamination, committed attack facing versus movement facing, mirrored E/W asset semantics (one mirrored pair must not be double-flipped), Grunt-only behavior callback, Pursuit `reaction.death` bypass, flinch/stagger priorities, directional fallbacks, and all 16 registered states. Keep deferred intercept mechanic deferred.
- Acceptance: Findings-first independent review from fresh context. Record R0-NN findings with class, domain, affected A1–A6, evidence and disposition. Genuine blockers require bounded correction and fresh re-review; never mark a failed review passed. Preserve code-review independence and the coordinator's supported closeout contract.
- Non-goals: No runtime/asset edits in the review workstream, no new intercept ability, no unrelated combat-balance redesign, no packet/lock bypass.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the exact implementation packet is archived complete on fetched main.
2. Reconstruct the audit and acceptance from live code/art and durable implementation evidence in a new independent context. Do not adopt implementer's assumptions about west/east source pixels or state reachability.
3. Prove actual spawned-actor correctness, not only clip registration, animation names, or static assertions.
4. Use only the smallest targeted left/right ROI comparison when structural/pixel tests cannot establish visual facing; request a human baseline decision solely if a genuinely subjective issue persists.
5. Preserve findings and correction lineage; no invented PASS, no touching implementation from this workstream.

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Record exact passed receipt or bounded findings/correction handoff.
- Blockers or open questions: `Implementation dependency must finish; reviewer must prove real-run visual state/facing.`