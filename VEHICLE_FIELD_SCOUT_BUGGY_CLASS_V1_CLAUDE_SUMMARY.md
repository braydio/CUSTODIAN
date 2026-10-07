# Vehicle Field Scout Buggy Class V1 — Codex Summary

## Delivered

- Preserved registry ID `custodian_ground_buggy_scout_light` and changed its display identity to **Custodian Field Scout Buggy Mk I**.
- Added semantic production scene `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`, migrated `game.tscn` and the world-origin contract, and removed the now-unreferenced `light_buggy.tscn`.
- Added durability profile `light_scout_utility` (100 max health). `PilotableVehicle` loads it into its existing `max_health` field and clamps the existing `current_health`; no second health state was added.
- Preserved all `ground_wheeled_light` values (175 speed, 420 acceleration, 520 deceleration, 10 turn response, 0.45 reverse, 0.78 off-road, road multiplier enabled), one driver/zero passengers, 64 px entry radius, 2x1 bottom-center footprint, hardpoints, and `none` loadout.
- Removed the unbound constant HealthBar. Renamed the temporary hover visual kit to `custodian_field_scout_buggy_mk1_compat_hover`; it remains explicitly temporary until the Asset V2 vehicle-family task.
- Added `vehicle_field_scout_class_smoke.gd` and registered it in `validation_manifest.json`.

## Evidence

- `validate_vehicle_registry.gd`: PASS.
- `vehicle_exit_clearance_smoke.gd`: PASS (the intentional total-blockage case emits its expected warning).
- `vehicle_runtime_lifecycle_smoke.gd`: PASS (the intentional blocked-exit case emits its expected warning).
- `vehicle_field_scout_class_smoke.gd`: PASS; covers identity, durability consumption without health reset, seat/footprint/hardpoint/collision composition, absent HealthBar, and game scene binding.
- `run_moment.py --changed`: no matching scenario selected; no vehicle class scenario currently exists.
- Final `run_validation.py --changed --json` report: `/tmp/vehicle-field-scout-changed-validation-final.json`; 27 selected, 22 passed, 3 failed, 2 timed out, coverage complete. All three vehicle checks (`vehicle_exit_clearance`, `vehicle_field_scout_class`, `vehicle_runtime_lifecycle`) and the world-origin contract passed.
- Two unrelated failures were confirmed against the exact `origin/main` game scene: `vaultwing_world_spawn` expects a production VaultwingSpawner that is absent on baseline; `wave_manager_debug_grunt_spawn_gate` fails the startup debug-grunt assertion on baseline. `terminal_sensors_layout` failed with unrelated ContractWorldLoader deferred-call errors and missing Vaultwing art; it was not baseline-verified. `command_terminal_tutorial` and `terminal_page_order_regression` timed out in the changed-file sweep.
- `check_ai_context.py --json` reports nine existing findings in unrelated task packets; `task_packet_index.py` and the 23-test task-packet contract suite pass.
- Fresh worktree required one Godot editor import to populate ignored class/import caches. Existing focused smoke scripts also emit their expected blocked-exit warnings and resource cleanup warnings at process exit.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: fresh checkout import was required, and changed-file closeout exposed unrelated baseline failures/timeouts after all vehicle-focused tests passed.
- Root cause / contributing factors: checkout-local generated Godot cache plus broad scene ownership selecting unrelated consumers; a world-origin smoke contract had drifted.
- Prevention / pipeline improvement: import before direct scripts; keep structural scene contracts aligned with the current scene; investigate baseline suite defects separately.
- Tooling / docs drift discovered: world_origin_branch_contract_smoke omitted WorldEnvironmentDirector and Ambient; nine unrelated packet grammar findings remain.
- Follow-up: manual-follow-up
- What worked: focused class smoke joins registry, data, scene, and live-scene identity in one deterministic assertion path.

## Next Handoff
- Next workstream: review-vehicle-field-scout-buggy-class-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: resolve or disposition changed-file validation failures/timeouts, then finish/land and claim paired review.
- Blockers or open questions: changed-file report is not green (22/27 passed, 3 failed, 2 timed out); two failures reproduce on baseline, one remains unverified against baseline.
