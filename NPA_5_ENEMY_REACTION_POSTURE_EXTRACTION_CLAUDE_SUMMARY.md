# NPA-5 Enemy Reaction and Posture Extraction

Implemented `npa-5-enemy-reaction-posture-extraction` in its existing claimed worktree. The extraction puts ordinary reaction/posture state in `EnemyReactionController` and critical-open/paired-execution victim state in `EnemyParryCritical`, preserving the stable Enemy façade and the existing host/presentation/health boundaries.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

## Delivered

- Added separate typed config resources and runtime owners for posture accumulation/recovery, light-flinch policy, recoil, stagger, ordinary critical-hit recovery, critical-open phases, reservation owner/token, execution root/direction/kind, and once-only damage consumption.
- Preserved `stagger_damage_threshold` in shared hit classification; actual health/death/corpse/loot, BSM behavior, special abilities, Operator choreography, and presentation playback remain outside the extracted owners. Execution-body position restoration moved to `EnemyPresentationController`.
- Kept Grunt/Marine/Savage tuning and Vigil Dagger reaction durations exact. `enemy.gd` is 3,946 lines versus 4,201 at the worktree base, a net reduction of 255 lines.
- Refactored validation/debug callers to semantic APIs and added `enemy_reaction_posture_smoke.gd` with manifest ownership.
- Diagnosed the startup-grunt gate failure on a clean detached checkout of `origin/main@2dffdffbd026b0788702eaa5f0aae4edfe4d5355`. Runtime behavior passed before the test failed at a source-text assertion requiring an explicit serialized false default. Replaced that assertion with a load/instantiate/effective-property check. The production scene and spawn behavior were untouched.
- Reconciled `CURRENT_STATE.md`, `FILE_INDEX.md`, and the NPA runtime architecture roadmap with the extracted ownership and validation evidence.

## Validation

- Focused combat/runtime regressions: 15/15 passed, including reaction/posture, paired-execution lethal controls, StandardEnemyMelee, Marine ambush/Dash, Falcon, Savage, guard, spatial telemetry, and commitment checks.
- Source-change sweep before packet lifecycle closeout: 31/31 passed, complete manifest ownership, zero failures, zero timeouts. The final changed sweep selected the unrelated `review_pairing_contract` check and failed on the known F14-C1 pair mismatch; later tiers were skipped. F14 was left untouched.
- `git diff --check`: passed.
- The first run after changing the gate exposed the script's need for an explicit Boolean type; corrected in-scope. One existing spawn-position assertion intermittently exceeded its 4px tolerance once, then passed on rerun and in the 31-test sweep.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: A pre-existing validation gate blocked the initial batch because it tested scene serialization instead of effective runtime configuration. The initial correction needed an explicit type annotation; one debug-spawn position assertion also varied slightly across runs.
- Root cause / contributing factors: The safety contract was encoded as a serialization detail, the existing fixture has small physics-frame position variance, and the final queue validator detected the known F14-C1 pair inconsistency.
- Prevention / pipeline improvement: Check instantiated effective properties for runtime safety gates. Reproduce shared validation failures on clean main before attributing them to a feature workstream; leave F14 correction with its owner.
- Tooling / docs drift discovered: `wave_manager_debug_grunt_spawn_gate_smoke.gd` treated omission of a script-default value from the scene file as unsafe. Fixed in-scope without changing gameplay or production scene data. The final changed sweep also surfaced the known F14-C1 queue-contract defect.
- Follow-up: manual-follow-up
- What worked: Clean-main baseline reproduction isolated the validation defect; semantic APIs and the focused reaction smoke provided clear ownership and regression evidence.

## Next Handoff

- Next workstream: review-npa-5-enemy-reaction-posture-extraction
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: After implementation lands and archives, claim the paired review through `paired_review_runner.py` in a fresh reviewer context. After that review passes, stop at the NPA-6 planning refresh gate.
- Blockers or open questions: none
