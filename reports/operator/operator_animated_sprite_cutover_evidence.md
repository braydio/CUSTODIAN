# Operator `animated_sprite` cutover evidence

Scope is `animated_sprite` alone. The melee and weapon overlays remain
compatibility renderers and belong to their own later slices.

135 clips in the compatibility resource; 50 are reachable by a live consumer.

| disposition | all clips | live only |
|---|---|---|
| AUTHORING_DECISION | 13 | 13 |
| PROVEN_CANONICAL | 37 | 37 |
| RETIRED | 85 | 0 |

## Live clips

| clip | canonical identity | published | timing | disposition |
|---|---|---|---|---|
| `death` | `unarmed/reaction/legacy_death_disintigrate_base/omni/full_body` | NO | - | AUTHORING_DECISION |
| `idle_long` | `unarmed/cosmetic/legacy_front_idle_long_loop/omni/full_body` | NO | - | AUTHORING_DECISION |
| `idle_right` | `unarmed/cosmetic/legacy_front_idle_loop/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_fast_1_right` | `melee_1h_heavy/attack/legacy_fast_attack_1_right_body/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_fast_2_right` | `melee_1h_heavy/attack/legacy_fast_attack_2_right_body/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_fast_recovery` | `melee_1h_heavy/attack/legacy_fast_recovery_body/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_fast_right` | `melee_1h/attack/legacy_fast_attack_right_base/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_heavy` | `unarmed/attack/legacy_operator_2h_heavy_3layer/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_heavy_anticipation` | `melee_1h_heavy/attack/legacy_heavy_anticipation_body/omni/full_body` | NO | - | AUTHORING_DECISION |
| `melee_2h_heavy_right` | `unarmed/attack/legacy_operator_2h_heavy_3layer/omni/full_body` | NO | - | AUTHORING_DECISION |
| `ranged_2h_reload` | `ranged_2h/cosmetic/reload_01/omni/full_body` | NO | - | PROVEN_CANONICAL |
| `ranged_2h_run_left` | `ranged_2h/locomotion/run_01/w/full_body` | yes | preserved | PROVEN_CANONICAL |
| `run_right` | `unarmed/cosmetic/legacy_running_base/omni/full_body` | NO | - | AUTHORING_DECISION |
| `unarmed_attack_fast_recovery` | `unarmed/attack/fast_recovery_01/e/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_down` | `unarmed/attack/fast_recovery_01/s/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_down_left` | `unarmed/attack/fast_recovery_01/sw/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_down_right` | `unarmed/attack/fast_recovery_01/se/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_left` | `unarmed/attack/fast_recovery_01/w/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_right` | `unarmed/attack/fast_recovery_01/e/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_up` | `unarmed/attack/fast_recovery_01/n/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_up_left` | `unarmed/attack/fast_recovery_01/nw/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_recovery_up_right` | `unarmed/attack/fast_recovery_01/ne/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup` | `unarmed/attack/fast_windup_01/s/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_down` | `unarmed/attack/fast_windup_01/s/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_down_left` | `unarmed/attack/fast_windup_01/sw/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_down_right` | `unarmed/attack/fast_windup_01/se/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_left` | `unarmed/attack/fast_windup_01/w/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_right` | `unarmed/attack/fast_windup_01/e/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_up` | `unarmed/attack/fast_windup_01/n/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_up_left` | `unarmed/attack/fast_windup_01/nw/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_attack_fast_windup_up_right` | `unarmed/attack/fast_windup_01/ne/full_body` | yes | preserved | PROVEN_CANONICAL |
| `unarmed_run_down` | `unarmed/locomotion/run_01/s/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_down_left` | `unarmed/locomotion/run_01/sw/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_down_right` | `unarmed/locomotion/run_01/se/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_left` | `unarmed/locomotion/run_01/w/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_right` | `unarmed/locomotion/run_01/e/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_up` | `unarmed/locomotion/run_01/n/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_up_left` | `unarmed/locomotion/run_01/nw/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_run_up_right` | `unarmed/locomotion/idle_01/ne/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk` | `unarmed/locomotion/walk_01/s/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_down` | `unarmed/locomotion/walk_01/s/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_down_left` | `unarmed/locomotion/walk_01/sw/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_down_right` | `unarmed/locomotion/walk_01/se/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_left` | `unarmed/locomotion/walk_01/w/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_right` | `unarmed/locomotion/walk_01/e/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_up` | `unarmed/locomotion/walk_01/n/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_up_left` | `unarmed/locomotion/run_01/nw/lower_body` | yes | - | PROVEN_CANONICAL |
| `unarmed_walk_up_right` | `unarmed/locomotion/idle_01/ne/lower_body` | yes | - | PROVEN_CANONICAL |
| `walk_down_default` | `unarmed/cosmetic/legacy_walking_base/omni/full_body` | NO | - | AUTHORING_DECISION |
| `walk_right` | `unarmed/cosmetic/legacy_walking_base/omni/full_body` | NO | - | AUTHORING_DECISION |

## Authoring decisions

Each of these is a live clip drawing art published only under a legacy action
id. The reachability contract covers canonical entries only, so none of them
carry a recorded status; candidates are published full-body actions in the
same profile, listed across groups because the legacy strips were filed by
the old pipeline's grouping rather than their semantics.

| clip | legacy art | authored | candidates in profile |
|---|---|---|---|
| `death` | `legacy_death_disintigrate_base` | 9f @7.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `idle_long` | `legacy_front_idle_long_loop` | 10f @3.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `idle_right` | `legacy_front_idle_loop` | 3f @7.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `melee_2h_fast_1_right` | `legacy_fast_attack_1_right_body` | 6f @12.0 | `attack/fast_01`, `attack/fast_02`, `attack/fast_03`, `attack/fast_recovery_01`, `attack/heavy_01`, `attack/heavy_windup_01`, `defense/block_enter_01`, `defense/block_exit_01`, `defense/block_hold_01` |
| `melee_2h_fast_2_right` | `legacy_fast_attack_2_right_body` | 5f @12.0 | `attack/fast_01`, `attack/fast_02`, `attack/fast_03`, `attack/fast_recovery_01`, `attack/heavy_01`, `attack/heavy_windup_01`, `defense/block_enter_01`, `defense/block_exit_01`, `defense/block_hold_01` |
| `melee_2h_fast_recovery` | `legacy_fast_recovery_body` | 2f @10.0 | `attack/fast_01`, `attack/fast_02`, `attack/fast_03`, `attack/fast_recovery_01`, `attack/heavy_01`, `attack/heavy_windup_01`, `defense/block_enter_01`, `defense/block_exit_01`, `defense/block_hold_01` |
| `melee_2h_fast_right` | `legacy_fast_attack_right_base` | 12f @12.0 | `attack/fast_01`, `attack/fast_02`, `attack/fast_03`, `cosmetic/melee_1h` |
| `melee_2h_heavy` | `legacy_operator_2h_heavy_3layer` | 7f @11.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `melee_2h_heavy_anticipation` | `legacy_heavy_anticipation_body` | 5f @11.0 | `attack/fast_01`, `attack/fast_02`, `attack/fast_03`, `attack/fast_recovery_01`, `attack/heavy_01`, `attack/heavy_windup_01`, `defense/block_enter_01`, `defense/block_exit_01`, `defense/block_hold_01` |
| `melee_2h_heavy_right` | `legacy_operator_2h_heavy_3layer` | 7f @11.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `run_right` | `legacy_running_base` | 16f @14.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `walk_down_default` | `legacy_walking_base` | 8f @10.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |
| `walk_right` | `legacy_walking_base` | 8f @10.0 | `attack/dodge_fast_attack_01`, `attack/fast_01`, `attack/fast_recovery_01`, `attack/fast_strike_01`, `attack/fast_windup_01`, `attack/heavy_01`, `cosmetic/critical_execution_01`, `cosmetic/criticial_execution_01`, `cosmetic/falcon_reversal_01`, `defense/parry_miss_01`, `locomotion/idle_01`, `locomotion/run_01`, `locomotion/walk_01`, `posture/stance_01`, `reaction/bodyslam_knockdown_01`, `reaction/death_01`, `reaction/light_hitreact_01` |

## Data-driven bases

- `_get_weapon_animation_name(...unarmed_light_hitreact...)` — OperatorWeaponDefinition animation_map; the damage-reaction base is a weapon-definition field, not a literal in the actor
- `_get_authored_melee_body_stance_animation()` — melee posture resolver / weapon definition; the stance base is authored per weapon rather than named in the actor

## External name/frame consumers

- `instant_replay_recorder.gd` (observability) — captures `sprite.animation` and restores it on playback. In-memory only with no checked-in fixtures, so it round-trips whatever names are live; a replay captured before a cutover cannot be restored after one.
- `animation_state_machine.gd` (presentation) — `current_animation()` returns `sprite.animation` and `is_animation_playing(name)` compares it. The comparison helper has zero callers, so no gameplay state keys off the clip name today.
- `hit_recoil_state.gd` (gameplay-semantic) — detects reaction completion by comparing `sprite.animation` against the name it played. Survives renaming only because both sides move together; it must keep comparing the same string the state played.
- `operator_presentation_rig_2d.gd` (presentation) — mirrors `animated.animation = source_animated.animation` onto a preview rig, so the rig needs the same SpriteFrames the source renderer uses.
- `operator.gd::_apply_knight_test_skin_if_requested` (observability) — swaps `animated_sprite.sprite_frames` for a debug Knight skin built under legacy clip names, caching the production resource to restore. After canonicalization the skin's own names no longer match what consumers request, so the debug skin needs its own disposition.
