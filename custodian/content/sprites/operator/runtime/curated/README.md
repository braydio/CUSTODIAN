# Operator Runtime Curated Set

This directory is the cleaned working set for the operator animation rebuild.

It is intentionally organized by gameplay role instead of by export history.
The old source folders remain intact for safety.

Runtime rule: if a sheet contains more than one animation or directional set, treat it as a source/master sheet and rebuild only the concrete runtime slices the game actually consumes.

## Updates - 3/24/26

These updates are for codex or other agent assistants to track newly updated or modified animations. Agents should update new or modified files to be named per directory conventions, in structured folders per below and wired into animation. Once done update this file to reflect the newly added animation in the following ## Structure section.

- `body/ranged_2h/equipped_run_right_body.png`
    - This file is the new 'equipped ranged weapon running right' animation. It is 2 rows of 4 frames each with the operator body in row 1 and the standard default ranged weapon sprite in row 2
- `operator/runtime/body/ranged_2h/operator__body__ranged_2h__run_01__e__5f__96.png`
    - This is the current canonical ranged 2H east/right run body strip, wired as `ranged_2h_run_right`.
- `operator/runtime/curated/weapon/ranged_2h/carbine_rifle_mk1/operator__weapon__ranged_2h__run_01__e__5f__96.png`
    - This is the current canonical ranged 2H east/right run weapon strip, wired as `equipped_run_right`.

- `body/melee_2h/heavy_anticipation_body.png`
- 2 rows of 5 frames each - operator body in row 1 and standard katana melee weapon row 2


- `body/melee_2h/fast_attack_{1,2}_right_body.png`
- `fast_attack_1` 3 rows of 6 frames `fast_attack_2` 3 rows of 5 frames - operator body row 1 standard katana melee row 2, effects row 3
- `fast_attack_1` is the initial fast attack that can be chained if subsequent input  frame 6 of `fast_attack_1` flows smoothly into frame 1 of `fast_attack_2`of which frame 5 flows smoothly into frame 1 of `fast_attack_1`
-

- `body/melee_2h/fast_recovery_body.png`
- 3 rows of 2 frames each as the non-chain conclusion of `fast_attack_1` body row 1, katana row 2, effects row 3

## Wiring Status - 2026-03-27

The following new curated sheets are wired into the active operator runtime resources:

- `body/ranged_2h/equipped_run_right_body.png`
  - body row wired to `run_right`
  - weapon row wired to `equipped_run_right`
- `operator/runtime/body/ranged_2h/operator__body__ranged_2h__run_01__e__5f__96.png`
  - wired to `ranged_2h_run_right`
- `operator/runtime/curated/weapon/ranged_2h/carbine_rifle_mk1/operator__weapon__ranged_2h__run_01__e__5f__96.png`
  - wired to `equipped_run_right`
- `body/melee_2h/heavy_anticipation_body.png`
  - body row wired to `melee_2h_heavy_anticipation`
  - weapon row wired to `melee_2h_heavy_anticipation_weapon`
- `body/melee_2h/fast_attack_1_right_body.png`
  - 3 rows of 6 frames confirmed from sheet dimensions
  - body row wired to `melee_2h_fast_1_right`
  - weapon row wired to `melee_2h_fast_1_weapon`
  - fx row wired to `melee_2h_fast_1_fx`
- `body/melee_2h/fast_attack_2_right_body.png`
  - 3 rows of 5 frames confirmed from sheet dimensions
  - body row wired to `melee_2h_fast_2_right`
  - weapon row wired to `melee_2h_fast_2_weapon`
  - fx row wired to `melee_2h_fast_2_fx`
- `body/melee_2h/fast_recovery_body.png`
  - body row wired to `melee_2h_fast_recovery`
  - weapon row wired to `melee_2h_fast_recovery_weapon`
  - fx row wired to `melee_2h_fast_recovery_fx`

## Structure

- `body/core`
  - shared front/idle body loops
- `body/default`
  - body-only movement with no equipped weapon assumption
- `body/default_locomotion`
  - legacy staging folder kept for safety during cleanup
- `body/ranged_2h`
  - body sheets for the equipped ranged stance/fire/reload set
- `body/melee_2h`
  - body sheets for stance, attacks, and block
- `overlay/melee_2h`
  - katana/effects overlays for melee states
- `weapon/ranged_2h/carbine_rifle_mk1`
  - current placeholder carbine overlay sheets

## Current Normalized Files

### Body Core

- `body/core/front_idle_loop.png`
  - from `operator_idle_main.png`
  - used by `idle_right`, `idle_down`, `idle_up`
- `body/core/front_idle_long_loop.png`
  - from `idle-long.png`
  - used by `idle_long`

### Default

- `body/default/run_right_body.png`
  - from `operator_body_default_run.png`
  - used by `run_right`
- `body/default/walk_right_body.png`
  - new curated right-walk body loop
  - used by `walk_right`
- `body/default/walk_down_body.png`
  - from `operator_body_default_walk_down.png`
  - used by `walk_down_default`
- `body/default/walk_up_body.png`
  - from `walk_up.png`
  - used by `walk_up`

### Ranged 2H

- `body/ranged_2h/equipped_walk_right_body_placeholder.png`
  - from `operator_body_ranged_2h_walk.png`
  - used by `walk_right`
- `body/ranged_2h/equipped_run_right_body.png`
  - legacy combined body/weapon source, superseded for active ranged 2H east run by the canonical body and weapon strips
- `../body/ranged_2h/operator__body__ranged_2h__run_01__e__5f__96.png`
  - used by `ranged_2h_run_right`
- `weapon/ranged_2h/carbine_rifle_mk1/operator__weapon__ranged_2h__run_01__e__5f__96.png`
  - used by `equipped_run_right`
- `body/ranged_2h/stance_body_placeholder.png`
  - from `operator_body_ranged_2h_stance.png`
  - used by `ranged_2h_stance`
- `body/ranged_2h/fire_body.png`
  - from `operator_body_ranged_2h_fire_loop-sheet.png`
  - used by `ranged_2h_fire`
- `body/ranged_2h/reload_body_4f.png`
  - from `operator_body_ranged_2h_reloading.png`
  - row 1 body
  - row 2 default rifle reload overlay/effects
  - registered as `ranged_2h_reload`

### Melee 2H

- `body/melee_2h/stance_front_body.png`
  - from `operator_body_melee_2h_stance.png`
  - used by `melee_2h_stance`
- `body/melee_2h/fast_attack_right_body_12f.png`
  - from `melee_fast_baked_operator_only.png`
  - used by `melee_2h_fast_right`
- `body/melee_2h/heavy_attack_right_3layer_7f.png`
  - from `operator_2h_heavy_3layer.png`
  - row 1 body, row 2 weapon, row 3 fx
  - used by `melee_2h_heavy_right`, `melee_2h_heavy_weapon`, `melee_2h_heavy_fx`
- `body/melee_2h/heavy_anticipation_body.png`
  - row 1 body, row 2 weapon
  - used by `melee_2h_heavy_anticipation`, `melee_2h_heavy_anticipation_weapon`
- `body/melee_2h/fast_attack_1_right_body.png`
  - row 1 body, row 2 weapon, row 3 fx
  - used by `melee_2h_fast_1_right`, `melee_2h_fast_1_weapon`, `melee_2h_fast_1_fx`
- `body/melee_2h/fast_attack_2_right_body.png`
  - row 1 body, row 2 weapon, row 3 fx
  - used by `melee_2h_fast_2_right`, `melee_2h_fast_2_weapon`, `melee_2h_fast_2_fx`
- `body/melee_2h/fast_recovery_body.png`
  - row 1 body, row 2 weapon, row 3 fx
  - used by `melee_2h_fast_recovery`, `melee_2h_fast_recovery_weapon`, `melee_2h_fast_recovery_fx`
- `body/melee_2h/block_enter_body_4f.png`
  - from `operator_body_melee_2h_block_enter.png`
  - used by `melee_2h_block_enter`
- `body/melee_2h/block_hold_body_1f.png`
  - from `operator_body_melee_2h_block_hold.png`
  - used by `melee_2h_block_hold`
- `body/melee_2h/block_exit_body_2f.png`
  - from `operator_body_melee_2h_block_exit.png`
  - used by `melee_2h_block_exit`

### Melee Overlays

- `overlay/melee_2h/fast_attack_weapon_12f.png`
  - used by `melee_2h_fast_weapon`
- `overlay/melee_2h/fast_attack_fx_12f.png`
  - used by `melee_2h_fast_fx`
- `overlay/melee_2h/block_enter_weapon_4f.png`
  - used by `melee_2h_block_enter_weapon`
- `overlay/melee_2h/block_hold_weapon_1f.png`
  - used by `melee_2h_block_hold_weapon`
- `overlay/melee_2h/block_exit_weapon_2f.png`
  - used by `melee_2h_block_exit_weapon`

### Ranged Weapon Overlay

- `weapon/ranged_2h/carbine_rifle_mk1/stance_and_fire_placeholder_3f.png`
  - current placeholder used by both `ranged_2h_stance` and `ranged_2h_fire`

## Notes

- This directory is for cleanup and rewiring work.
- It does not delete or replace the older export directories.
- Once the final set is approved, runtime resources can be pointed here directly.
