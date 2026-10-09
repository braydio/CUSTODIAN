# NPA-4 Standard Enemy Melee Extraction

Implemented `npa-4-standard-enemy-melee-extraction` in the claimed workstream, preserving the ordinary combat transaction while extracting its mutable authority into `StandardEnemyMelee` and typed `StandardEnemyMeleeConfig` resources.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Delivered

- Moved first-strong consumption, windup/tracking lock, committed contact context, attack ID, hit/whiff/cancel resolution, recovery/redecision, debug state, and observability into the actor-local melee authority.
- Kept damage, target selection, shared hit handling, engagement coordination, reactions, presentation, and special abilities at their existing host/ability seams. `damage_timer` and `damage_interval` remain outside the module.
- Added typed defaults plus exact Grunt, Marine, Savage, and Pursuit Frame resources. Updated `SavageChain` to query the first-hit windup through the module's public host seam.
- Replaced direct transaction state access in active callers and tests with semantic APIs. `enemy.gd` is 4,201 lines versus 4,467 at the main baseline, a net reduction of 266 lines.
- Added validation ownership and a focused `standard_enemy_melee` smoke, including result-mode, current-target-at-resolution, tracking/lock, no-target, contact source, recovery, and variant-cooldown checks.

## Validation

- Focused `standard_enemy_melee`: pass.
- `enemy_grunt_notice_and_attack_cadence`, `enemy_hit_spatial_telemetry`, `combat_exchange_commitment`, `operator_guard_flow`, `grunt_falcon_punch`, `grunt_falcon_reversal`, `authored_vault_grunt_loot_marine`, `sundered_keep_marine_ambush`, `enemy_savage_pounce`, `savage_runtime`, `enemy_grunt_behavior_presentation`, `enemy_grunt_presentation`, and `dev_observatory_audit`: pass.
- Changed-file sweep: 31/31 pass, complete ownership coverage, zero timeouts; report: `/tmp/npa4-changed-validation-final.json`.
- `git diff --check`: pass.

The first broad sweep showed incomplete ownership for two changed files; the manifest was corrected. When the ambient Shrumb scene was temporarily assigned to a full procgen spawn integration test, that test hit its 180-second timeout. The focused smoke now directly loads the scene and validates its inherited melee config, and the final changed sweep passes.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Initial validation caught an empty shared engagement-token release seam, a malformed conditional, a nonexistent facing callback, and a regression fixture that lacked a physics RID. A first changed-file sweep found missing manifest ownership for two changed callers; all were corrected. The unrelated procgen spawn test timed out when used for the small ambient scene edit, so focused scene-load coverage now owns that change.
- Root cause / contributing factors: Shared host service removal during extraction, incomplete fixture physics behavior, and missing changed-path ownership metadata.
- Prevention / pipeline improvement: Preserve shared host services explicitly, use physics-body validation fixtures for perception callers, and register changed files with narrow smoke owners before broad validation. Fixed in scope.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Focused semantic coverage isolated the transaction from reaction and special-ability ownership.

## Next Handoff
- Next workstream: review-npa-4-standard-enemy-melee-extraction
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Start the paired post-land review in a fresh reviewer context.
- Blockers or open questions: none
