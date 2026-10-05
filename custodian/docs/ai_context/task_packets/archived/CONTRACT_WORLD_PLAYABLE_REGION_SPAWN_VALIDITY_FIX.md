# CONTRACT WORLD PLAYABLE REGION SPAWN VALIDITY FIX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-playable-region-spawn-validity-fix`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `contract-world-loader, procgen-playability`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-contract-world-playable-region-spawn-validity-fix`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `4fab463d2c347327b48a7417a41e6eada3b63ee1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Summary backlink: Every durable implementation/review/recovery/correction/closeout summary for this packet must include `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7` exactly.
- Goal: Eliminate the current-main contract-world defect where the Operator can spawn on a tile that looks locally walkable to `ContractWorldLoader` but is outside the accepted/reachable playable region over exterior underlevel/void presentation.
- Completion boundary: Done when every final Operator spawn selected from compound or `player_spawn` fallback is validated against existing canonical procgen spawn/walkability authority **and** the accepted main reachable playable component before relocation; an invalid candidate fails over deterministically to a valid candidate or fails contract readiness without moving the Operator; and a focused regression reproduces a painted-floor-but-not-main-playable candidate and proves it can never become the runtime Operator position.
- Current measured state: The previous `contract-world-ingress-spawn-clearance-fix` correctly moved registered ingress claims before Operator placement and excludes `is_inside_world_ingress_dressing_clearance()`. A current-main playtest after that reviewed fix still spawned the Operator outside the playable region over the underlevel void. Live `ContractWorldLoader._is_safe_operator_spawn_tile()` currently checks only painted walkable floor plus ingress clearance; `_pick_compound_spawn_tile()` scans `compound_rect` through that local floor test. `ProcGenTilemap` already exposes stronger canonical seams including `is_valid_spawn_cell(tile)`, `is_runtime_navigation_walkable(tile)`, route-playability data/audit, and final RuntimeWalkableBoundary authority. Do not fix this by adding another private loader-only connectivity registry.
- Evidence: `custodian/game/systems/core/systems/contract_world_loader.gd::_position_operator/_is_safe_operator_spawn_tile/_pick_compound_spawn_tile`; `custodian/game/world/procgen/proc_gen_tilemap.gd::is_valid_spawn_cell/is_runtime_navigation_walkable/debug_get_route_playability`; `custodian/game/world/procgen/playability/route_playability_field.gd`; `runtime_walkable_boundary_chunk.gd`; reviewed ingress-spawn-clearance hotfix; user reproduction on current main in the recorded authoring chat.
- Task-specific authority: Procgen/playability remains owner of valid/reachable world cells. ContractWorldLoader may consume one narrow read-only validity query but must not duplicate connectivity/playability computation. RuntimeWalkableBoundary remains physical frontier; the loader owns only final placement orchestration.
- Work surface: Prefer a narrow reusable public query on the existing procgen/playability side if no current query exactly answers "valid final Operator spawn in the accepted main playable component", plus the minimum `contract_world_loader.gd` consumer change and focused validation. Reuse `route_playability_field.gd`, `ProcGenTilemap`, or an existing connectivity diagnostic/result rather than adding a loader flood-fill.
- Change: Harden `_is_safe_operator_spawn_tile()` so a candidate must pass canonical `ProcGenTilemap.is_valid_spawn_cell(tile)`, current runtime walkability, ingress clearance, and membership in the accepted/main reachable playable component. If the cleanest existing route-playability result lacks a public membership query, expose the smallest read-only query from its existing result rather than copying its data or algorithm into the loader.
- Change: Apply the same invariant to compound candidate enumeration and `player_spawn` fallback. A tile being painted in Floor is not sufficient.
- Change: Preserve deterministic selection order among safe candidates. If an ingress-adjacent preferred candidate is outside the accepted component, continue deterministic search among canonical safe compound candidates.
- Change: Fail closed when no safe accepted-component spawn exists: do not move the Operator, do not return control, and report a specific contract-generation failure reason/diagnostic.
- Change: Add a deterministic regression with at least two floor candidates: one locally painted/wall-free candidate deliberately outside the accepted reachable component and one valid candidate in it. Prove the old predicate would accept the bad tile, the new predicate rejects it, the Operator lands on the good tile, and repeated selection is identical.
- Change: Add an integration assertion that the final Operator world position maps back to a canonical valid spawn tile and the main reachable component after registered ingress placement and before camera snap/control readiness.
- Preserve: Existing ingress-before-Operator ordering; Ash Bell/Forlorn dressing-clearance exclusion; Sundered Keep frontage/ingress placement; generation topology and S1 fingerprint; RuntimeWalkableBoundary generation; navigation authority; Archive Resolve; camera snap after final valid placement.
- Non-goals: No procgen topology repair; no map-size tuning; no playable-area expansion; no AR3 presentation changes; no new spawn animation; no ingress relocation; no broad ContractWorldLoader extraction; no second connectivity/flood-fill authority in the loader.
- Acceptance: (1) final Operator spawn passes canonical spawn validity; (2) final spawn belongs to the accepted/main reachable playable component; (3) disconnected or exterior-presentational floor cannot be selected; (4) fallback obeys the same invariant; (5) no-safe-spawn fails closed before relocation/control; (6) deterministic selection is preserved; (7) ingress collision/clearance regression stays green; (8) camera snaps only after valid placement; (9) generation/Archive Resolve/S1 remain unchanged.
- Validation: Add/register a focused `contract_world_playable_region_spawn_validity` smoke. Run it first, then `contract_world_ingress_spawn_clearance`, relevant route-playability/walkable-boundary smoke, contract-world population/placement smoke, required Ritualant ingress sweep, and the smallest camera/runtime-map handoff regression selected by changed files. Run S1 quick only if procgen runtime code changes; require `1773840677` unless independently changed on main. Finish with `git diff --check`, packet/review pairing, and changed-file validation.
- Task overrides: `none`
- Deferred: Perceived playable-area scale is a separate design/tuning question after spawn correctness; do not increase map size in this hotfix merely because the user also wants to assess region scale.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `custodian/game/world/procgen/proc_gen_tilemap.gd::get_main_playable_component` (read-only, fresh per call, reuses `procgen_preterrain_diagnostics.gd::reachable_from`); `contract_world_loader.gd::_is_safe_operator_spawn_tile/_pick_compound_spawn_tile/_position_operator`; new registered `contract_world_playable_region_spawn_validity` smoke passes and FAILS when the loader predicate is reverted (mutation-checked); `contract_world_ingress_spawn_clearance`, `world_ingress_spawner`, `ash_bell_lift_ingress_presentation`, `procgen_walkable_boundary`, `startup_world_entry`, `world_contract_prewarm`, `persistent_compound_runtime`, `procgen_performance_baseline_quick` (S1 fingerprint unchanged) pass. NOT green but identical on the unmodified base: `vaultwing_world_spawn`/`vaultwing_bond` (missing sprite files), `procgen_ambient_enemy_real_world_spawn` (zero camp markers), `required_ritualant_ingress_contract_sweep` seed 0 (Threadway checks). `contract_world_population_placement_smoke` exits 0 with no PASS line.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The required Ritualant ingress sweep (100 seeds, ~15 s generation each) cannot finish in a closeout budget and fails seed 0 on the unmodified base; three other changed-file tests also fail on the base, so the changed-file run cannot be green.`
- Root cause / contributing factors: `Pre-existing: sweep couples placement checks to Threadway isolation; vaultwing sprites are absent from this checkout; ambient camp markers are not placed on the test map.`
- Prevention / pipeline improvement: `Give the sweep a registered quick profile that excludes Threadway checks; triage the three base-red tests so --changed can gate green.`
- Tooling / docs drift discovered: `None new; `contract_world_population_placement_smoke.gd` prints no PASS marker.`
- Follow-up: `review-contract-world-playable-region-spawn-validity-fix`

## Handoff

- Next workstream: `review-contract-world-playable-region-spawn-validity-fix`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none`
- Next action: Land the narrow validity fix, then run the fresh-context paired review before AR3 initial-spawn presentation can execute.
- Blockers or open questions: none.
