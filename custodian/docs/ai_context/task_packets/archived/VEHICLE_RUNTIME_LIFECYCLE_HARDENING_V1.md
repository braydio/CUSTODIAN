# VEHICLE RUNTIME LIFECYCLE HARDENING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-runtime-lifecycle-hardening-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `vehicle-runtime, player-control-vehicle-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-runtime-lifecycle-hardening-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial runtime lifecycle and authority correction`
- Reviewed main: `ad2868d66a`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Make the production pilotable-vehicle lifecycle fail-safe so entering, ordinary exit, disable, destruction, and teardown cannot strand the Operator or leave PlayerController and the vehicle with contradictory ownership.
- Completion boundary: Done when one production lifecycle authority releases/restores the pilot for every ownership-ending path, PlayerController has one canonical current-vehicle reference, duplicate nearby discovery is removed, zero-health/disabled behavior is coherent, obsolete VehicleBase behavior residue is removed or explicitly preserved with a proven consumer, and focused lifecycle regression coverage proves the transitions.
- Current measured state: `PilotableVehicle.enter_vehicle()` hides the pilot, clears pilot collision, and disables pilot process/input; `exit_vehicle()` restores those properties only when state is PILOTED. `disable_vehicle()` immediately changes state to DISABLED without releasing an occupied pilot, so later `exit_vehicle()` refuses. `PlayerController.on_vehicle_destroyed()` resets controller references/visibility but does not restore all pilot process/collision state, and production `PilotableVehicle` has no end-to-end damage/destruction notification path. PlayerController stores both `current_vehicle` and `controlled_vehicle`, and nearby discovery appends both `pilotable_vehicles` and `vehicle` groups without deduplication. Production LightBuggy uses `PilotableVehicle`; the old `VehicleBase` path is referenced only by legacy comments/docs and `game/actors/base/light_buggy.tscn.txt` in the reviewed tree.
- Evidence: `custodian/game/vehicles/pilotable_vehicle.gd`; `custodian/game/systems/core/player_controller.gd`; `custodian/game/actors/vehicles/light_buggy.tscn`; `custodian/game/actors/base/vehicle_base.gd`; `custodian/game/actors/base/vehicle_interaction.gd`; `custodian/game/actors/base/light_buggy.tscn.txt`; `custodian/tools/validation/vehicle_exit_clearance_smoke.gd`; `custodian/tools/validation/validate_vehicle_registry.gd`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Task-specific authority: `design/02_features/vehicles/VEHICLES.md`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`; production `PilotableVehicle` and PlayerController ownership behavior.
- Work surface: `custodian/game/vehicles/pilotable_vehicle.gd` is the primary lifecycle owner; `custodian/game/systems/core/player_controller.gd` owns input/camera routing; legacy base files may be deleted only after confirming zero live consumers; focused lifecycle validation and validation-manifest ownership are in scope.
- Change: Introduce one pilot-release/restore transition used by ordinary exit, disable/destruction, and teardown. Complete authoritative damage-to-zero behavior and an event/signal seam that lets PlayerController relinquish control without the vehicle reaching into controller internals. A blocked ordinary exit must continue to leave the pilot safely inside, but forced ownership-ending paths must not leave the Operator hidden or process/collision-disabled. Consolidate PlayerController to one canonical current vehicle reference and deduplicate nearby candidates. Remove unused legacy VehicleBase/VehicleInteraction/template residue when live search proves no runtime consumer; otherwise reduce it to an explicit compatibility adapter with a named exit condition. Correct stale comments/docs describing the old base as production authority.
- Preserve: Current registry ID/spawn behavior; safe-exit collision/navigation checks and emergency-entry fallback semantics; camera handoff on normal enter/exit; movement values; terrain multiplier behavior; interaction behavior; procgen/world placement ownership.
- Non-goals: No new vehicle class data, handling rebalance, new vehicle art, mounted weapons, scanner gameplay, procgen placement extraction, or new possession framework.
- Acceptance: Occupied disable or destruction restores a controllable/visible/collidable Operator and returns PlayerController/camera authority exactly once; blocked ordinary exit still fails closed without losing pilot ownership; zero-health vehicle is not enterable/drivable; nearby search yields each vehicle once despite compatibility groups; only one mutable PlayerController vehicle reference remains; live runtime has one vehicle lifecycle authority rather than parallel `VehicleBase` and `PilotableVehicle` implementations; observability is transition-level, not per-frame.
- Validation: Run `res://tools/validation/vehicle_exit_clearance_smoke.gd` and `res://tools/validation/validate_vehicle_registry.gd` first. Add a focused implementation-created lifecycle/destruction smoke covering occupied disable, occupied destruction, blocked ordinary exit, property restoration, camera/controller release, and duplicate-group discovery; record its exact path before closeout. Update `custodian/tools/validation/validation_manifest.json` so lifecycle edits select it. Then changed-file closeout.
- Task overrides: `none`
- Deferred: Field Scout class data/scene migration, durability profile data beyond the minimum lifecycle seam, Asset V2 family work, final vehicle art.

## Handoff

- Next workstream: `review-vehicle-runtime-lifecycle-hardening-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `n/a`
- Refresh reason: `none`
- Next action: Claim `review-vehicle-runtime-lifecycle-hardening-v1` after this implementation lands; perform the paired fresh-context review.
- Blockers or open questions: `none`

## Completion Truth

- Outcome: `complete`
- Landed behavior: `PilotableVehicle` owns entry/exit, damage-to-zero, disabled/destroyed release, and teardown release; a single snapshot restoration path restores actor visibility, collision, and processing state. Blocked ordinary exit retains occupancy. PlayerController owns one canonical typed vehicle reference, listens for release to restore camera/control once, and deduplicates overlapping groups.
- Legacy disposition: Removed unused `VehicleBase`, `VehicleInteraction`, their UID sidecars, and the unreferenced text LightBuggy template after live runtime search found no consumers. Updated current design/context references; historical specs are clearly marked as superseded/history.
- Focused coverage: `custodian/tools/validation/vehicle_runtime_lifecycle_smoke.gd`, registered as `vehicle_runtime_lifecycle`.
- Validation: `vehicle_runtime_lifecycle` PASS; `vehicle_exit_clearance` PASS; `validate_vehicle_registry.gd` PASS; changed-file closeout PASS (13 selected, 13 passed, complete coverage); `bash -n scripts/repomix-elevation.sh` PASS; `git diff --check` PASS.
- Known expected test output: The lifecycle and safe-exit smokes intentionally exercise blocked exits and therefore log `no valid exit position`; both then assert the expected safe state.
- Deferred: Field Scout taxonomy/presentation and Asset V2 work remain with their successor packets; no art or handling tuning changed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The first changed-file sweep correctly reported incomplete coverage for removed legacy files and doc/tool-only edits. Explicit coverage exclusions were added for those non-runtime inputs and the complete 13-test changed-file sweep then passed. The expected blocked-exit warning remains visible in test output.`
- Root cause / contributing factors: `The validator's default changed-file contract requires runtime owners; deleted compatibility files and a packaging-script path update have no runtime test owner.`
- Prevention / pipeline improvement: `Classify non-runtime/deleted paths explicitly in coverage_excludes when a task removes compatibility surfaces; retain runtime owners for behavior changes.`
- Tooling / docs drift discovered: `none`
- Follow-up: `none`
- What worked: `A focused production-script smoke exercised disable, lethal damage, blocked-exit recovery, teardown, state restoration, group de-duplication, and camera/controller signal handoff.`

## Next Handoff

- Next workstream: `review-vehicle-runtime-lifecycle-hardening-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `After landing, claim the paired review packet and independently verify the lifecycle and runtime evidence from a fresh context.`
- Blockers or open questions: `none`
