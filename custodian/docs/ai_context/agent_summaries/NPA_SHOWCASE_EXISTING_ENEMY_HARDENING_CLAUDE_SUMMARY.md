# NPA Showcase Existing Enemy Hardening — Implementation Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Result

Added actor-aware directional contact validation for Marine Dash and Savage Pounce. Their prior center-to-center checks did not account for the fact that enabled body collision shapes stop the actors before their centers reach the configured contact distance. The new helper projects each actor's root collision-shape support along the attack axis and extends the allowed forward center distance by the sum, only when both actors have enabled root collision shapes. Existing `directional_lane` callers retain their current behavior.

Added `npa_showcase_existing_enemy_smoke.gd` and its manifest entry. The fixture instantiates the actual Grunt, Marine, Savage and Operator scenes, uses public ability requests, and checks Grunt melee and reactions/parry-critical eligibility, Marine Dash hit/impact/recovery, Savage Pounce and two-hit chain, and lethal Grunt corpse loot with once-only collection. It explicitly reproduces the Marine and Savage live contact cases that failed before the collision-support change.

## Evidence

- Focused checks passed: `enemy_reaction_posture`, `standard_enemy_melee`, `grunt_parry_critical`, `lootable_corpse_beacon`, `enemy_lifecycle_config`, `enemy_savage_pounce`, `savage_runtime`, `authored_vault_grunt_loot_marine`, `enemy_hit_spatial_telemetry`, and `npa_showcase_existing_enemy`.
- Final changed-file sweep `/tmp/npa-existing-enemy-changed-final.json`: 33 selected, 33 passed, 0 failed, 0 timed out, complete changed-file coverage.
- Task-packet authoring preflight, task-packet index validation and `git diff --check` passed.

## Measurements and awkward parts

- The initial real-actor fixture failed for both Marine Dash at its valid launch band and Savage Pounce at its launchable distance: physical body collision stopped movement with centers outside configured contact reach. Both paths passed once the lane accounted for the projected collision support.
- The fixture manually ticks public ability lifecycle methods in fixed 1/60-second steps to keep the test deterministic; it does not mutate private timers or replace actor scenes.
- The first changed-file sweep exposed broad formatting churn in neighboring manifest records. Those unrelated changes were removed, leaving only the new manifest record.
- Some existing actor validations report known navigation/ObjectDB/resource-exit warnings; all selected checks exited successfully and the sweep classified no failures.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Marine Dash and Savage Pounce could begin valid authored attacks but miss the live Operator because body collision stopped their centers farther apart than configured reach.
- Root cause / contributing factors: Directional hit validation compared center-to-center distance without accounting for the physical collision boundaries.
- Prevention / pipeline improvement: Keep the actor-aware projected-support calculation and real-scene contact cases in focused validation.
- Tooling / docs drift discovered: The manifest formatter rewrote unrelated entries during initial editing; those changes were removed before closeout.
- Follow-up: review-npa-showcase-existing-enemy-hardening
- What worked: Real-actor validation made the contact defect reproducible and verified the narrow correction.

## Next Handoff
- Next workstream: review-npa-showcase-existing-enemy-hardening
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: After implementation lands and the packet archives complete, run the paired fresh-context reviewer for the named review workstream.
- Blockers or open questions: none
