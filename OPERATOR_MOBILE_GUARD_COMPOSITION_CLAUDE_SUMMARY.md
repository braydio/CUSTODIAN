# Operator Mobile Guard Composition — Summary

Workstream `operator-mobile-guard-composition`, branch `agent/operator-mobile-guard-composition` (worktree `.custodian-worktrees/operator-mobile-guard-composition-20261006T050451Z-c5768008f3aa`). Packet `Review: manual`.

## Reminder
This is a separate worktree. Switch back to your other in-progress work: `agent/operator-2-5d-canonical-visual-contract` (waiting on your root/scale/acceptance decisions; **do not merge**), the viability-audit branch, and the main checkout `/home/braydenchaffee/Projects/CUSTODIAN` (`main`).

## What changed
- `OperatorPresentationController` now owns the bounded movement-permissive composition decision: `decide_guard_composition(phase, moving, impact_locked)` (pure) and `compose_lower_upper(...)` (movement-owned lower + action-owned upper, independent identities, lower-progress preservation, explicit upper restart / reverse, optional overlay hook, no side effects when it cannot play).
- `operator.gd` routes unarmed guard presentation through it:
  - Moving enter / hold / non-break recoil / exit: lower = movement locomotion (movement direction, `block_move_multiplier` speed), upper = defensive action (aim direction). Stationary: authored paired lower+upper pose (unchanged).
  - Per-frame upkeep (`_sync_modular_block_movement_presentation`) keeps the lower following movement without restarting either layer; stopping mid-phase hands only the lower back to the paired pose.
  - Guard break / break recovery are impact-locked: always paired, never composed (recoil velocity is not movement intent).
  - Dedicated `block_light/heavy_recoil_01` and `block_exit_01` are preferred automatically only when published canonically (none are today, so recoil = `block_hit_01`, exit = reversed `block_enter_01`). Raw `source_work` is never used.
  - Missing lower/upper identity falls back to the complete paired pose (no half bodies).
- No gameplay change: movement lock set, `block_move_multiplier`, sprint suppression, guard/parry timers, damage and input are untouched.
- New focused smoke `operator_mobile_guard_composition` (registered in the validation manifest); docs: `COMBAT_FEEL_SYSTEM.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`.

## Validation
Pass: `operator_mobile_guard_composition` (new; mutation-checked — it fails when composition is disabled), `operator_modular_defense_ranged`, `operator_guard_flow`, `operator_parry_presentation`, `operator_body_pair_canonical`, `operator_modular_layers`, `operator_modular_idle_hitreact`, `operator_fixed_tick_spine`, `operator_input_frame`, `operator_input_aim_source`, `operator_armed_melee_body_visibility`, `operator_primary_ranged_modular_fire`, `operator_modular_fast_attack`, `operator_dodge_presentation`.
- **Pre-existing failures, not caused by this work** (verified with changes stashed): `operator_ranged_ready_input` ("queued parry counter should start the strike after guard release"), `operator_unarmed_fast_chain`, `operator_vigil_dagger`.
- Closeout sweep `run_validation.py --changed --json` (58 tests): 3 failures, all **pre-existing** — each fails identically with my changes stashed: `operator_ranged_ready_input`, `operator_unarmed_fast_chain` ("needs a live carry to interrupt"), `operator_vigil_dagger` (camera impact probe). 4 tests skipped by the runner (`dev_observatory_audit`, `operator_visual_ownership`, `vaultwing_bond`, `ranged_ballistic_alignment`). Everything else passed.
- The worktree needed a one-time `godot --import` before Godot tests could run (no `.godot` cache).

## Moment Forge: not run — harness gap
I built a guard-strafe scenario, but probes proved the Operator never became unarmed inside Moment Forge (`using_unarmed` stayed false through tick 200, also in the existing `combat/unarmed_four_link_confirmed` scenario; the same toggle works in a direct headless run), so the scenario would not have exercised this path. I removed it rather than ship a misleading one. Follow-up: find why `toggle_unarmed` does not take effect under the Moment runner (or allowlist a safe unarmed setup), then add `combat/unarmed_mobile_guard_strafe`.

## Left for you
- Not yet landed: this is `Review: manual`; I have not run `workstream.py finish` (it merges to main and needs the packet archived + completion-truth receipt). Say the word and I will finish it.
- Visual confirmation of the strafe at runtime scale is still outstanding (the lifecycle is proven by deterministic smoke, not captured frames).
