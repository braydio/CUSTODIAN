# Vehicle Runtime Lifecycle Hardening V1 — Closing Summary

## What changed

- `PilotableVehicle` now captures and restores the pilot's original visibility, collision, and process/input state through one release transition shared by ordinary exit, disable, destruction, and tree teardown.
- Blocked ordinary exit continues to fail closed while leaving pilot occupancy, controller ownership, and camera follow intact. Forced disable/destruction/teardown releases even when local exit search fails, using the recorded entry position or a directional fallback.
- Added clamped health damage, health/lifecycle signals, and authoritative lethal damage-to-destruction behavior. Disabled or zero-health vehicles reject entry and routed driving.
- `PlayerController` now has one typed `current_vehicle` reference, listens to `pilot_released` for the single controller/camera handoff, and de-duplicates the overlapping vehicle groups.
- Removed the unreferenced `VehicleBase` and `VehicleInteraction` implementations, sidecars, and text LightBuggy template after searching the live runtime for consumers. Updated current vehicle authority, index, recipes, roadmap, sprite pipeline notes, and historical-plan notices.
- Added `custodian/tools/validation/vehicle_runtime_lifecycle_smoke.gd` and registered `vehicle_runtime_lifecycle`.

## Evidence

- `vehicle_runtime_lifecycle`: PASS. Covers occupied disable, damage/destruction, ordinary exit obstruction and recovery, pilot property restoration, controller/camera release count, de-duplicated group discovery, and vehicle teardown.
- `vehicle_exit_clearance`: PASS.
- `validate_vehicle_registry.gd`: PASS.
- Changed-file closeout: PASS, 13 selected / 13 passed, coverage complete.
- `bash -n scripts/repomix-elevation.sh`: PASS.
- `git diff --check`: PASS.
- The blocked-exit cases intentionally emit `no valid exit position`; the smoke verifies retained ownership and then recovery after the obstruction clears.

## What went wrong / deferred

The first changed-file sweep failed its coverage completeness check because removed compatibility paths and docs/tooling-only changes had no runtime test owner. I explicitly classified those paths in `coverage_excludes` and reran the complete 13-test sweep successfully. No runtime acceptance item remains open. Field Scout taxonomy/presentation and Asset V2 work remain deferred to their successor packets; no art or handling values changed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial changed-file coverage was incomplete until non-runtime/deleted paths were explicitly classified; expected blocked-exit warning remains visible in logs.
- Root cause / contributing factors: Coverage defaults assume changed runtime files have runtime test owners, including when compatibility scripts are deleted.
- Prevention / pipeline improvement: Classify removed legacy and docs/tooling-only paths explicitly during closeout while retaining runtime coverage for behavior changes.
- Tooling / docs drift discovered: The code-review graph was empty in the claimed worktree; graph initialization did not complete, so final impact review used the targeted source diff and changed-file test coverage.
- Follow-up: none
- What worked: Focused production-script lifecycle coverage combined with safe-exit and registry checks.

## Next Handoff

- Next workstream: review-vehicle-runtime-lifecycle-hardening-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: After landing, claim the paired review packet and independently verify lifecycle closure from a fresh context.
- Blockers or open questions: none
