# CONTRACT WORLD ENCOUNTER PLACEMENT EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-encounter-placement-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `contract-world-placement-foundation`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `7913903704aee8fdd2c645891df441fa31fb6cca`
- Goal: Move ambient enemy/encounter marker placement policy from ContractWorldLoader into one focused placement service without moving enemy spawning or AI authority.
- Completion boundary: Done when encounter-plan markers, legacy ambient markers, candidate tile scoring, Vaultwing marker placement, and related placement telemetry are service-owned; loader delegates and spawner/director remain simulation owners.
- Current measured state: `custodian/game/systems/core/systems/contract_world_loader.gd` still owns `_place_ambient_enemy_camps`, `_place_encounter_plan_markers`, `_place_legacy_ambient_enemy_markers`, `_place_vaultwing_markers` / candidate variants, `_build_ambient_enemy_candidate_tiles`, `_ambient_enemy_tile_score`, generated-marker cleanup, and spawner refresh orchestration. Encounter planning itself already has a focused owner at `custodian/game/world/procgen/encounters/encounter_cadence_planner.gd`; actual ambient spawning remains in `custodian/game/systems/spawning/ambient_enemy_spawner.gd` / `ambient_enemy_camp.gd`, and Vaultwing actor spawning remains under `custodian/game/systems/spawning/vaultwing_spawner.gd`.
- Evidence: live loader placement functions; `custodian/game/world/procgen/encounters/encounter_cadence_planner.gd`; `custodian/game/systems/spawning/ambient_enemy_spawner.gd`; `custodian/game/systems/spawning/vaultwing_spawner.gd`; `custodian/tools/validation/procgen_encounter_cadence_smoke.gd`; `custodian/tools/validation/procgen_ambient_enemy_real_world_spawn_smoke.gd`; `custodian/tools/validation/vaultwing_world_spawn_smoke.gd`; P1 placement context.
- Task-specific authority: world placement README; current enemy placement/spawner ownership; placement context.
- Work surface: `custodian/game/world/placement/encounter_placement_service.gd` (or clearly equivalent placement-package file), loader adapter only, existing `custodian/game/world/procgen/encounters/encounter_cadence_planner.gd` preserved as encounter-plan authority, existing ambient/Vaultwing spawners preserved as actor-spawn authorities, placement README/index, and focused placement regressions.
- Change: Extract marker/candidate placement only. Preserve current distinction between planned markers, legacy fallback, Vaultwing candidates, and actual actor-spawner refresh. Keep enemy creation/AI/director outside the service.
- Preserve: Fixed-seed marker positions/counts, walkability/clearances, population role telemetry, ambient spawner refresh behavior.
- Non-goals: No encounter tuning, enemy AI/combat changes, director redesign, or actor pooling.
- Acceptance: Fixed-seed marker snapshots and real-world spawn smoke remain identical; loader no longer owns encounter candidate/scoring policy.
- Validation: `res://tools/validation/procgen_encounter_cadence_smoke.gd`, `res://tools/validation/procgen_ambient_enemy_real_world_spawn_smoke.gd`, `res://tools/validation/vaultwing_world_spawn_smoke.gd`, `res://tools/validation/world_contract_prewarm_smoke.gd`, plus an implementation-created marker snapshot if needed; then changed-file closeout.
- Task overrides: `none`
- Deferred: Other placement domains and loader contraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; loader contraction waits for all placement-domain dependents.
- Best starting files: ambient/Vaultwing helpers in ContractWorldLoader; relevant spawn smokes; placement context.
- Blockers or open questions: None known at authoring time.
