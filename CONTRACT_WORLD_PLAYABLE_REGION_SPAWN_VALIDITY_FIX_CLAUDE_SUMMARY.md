# CONTRACT_WORLD_PLAYABLE_REGION_SPAWN_VALIDITY_FIX summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7

## What changed
- `ContractWorldLoader._is_safe_operator_spawn_tile()` now also requires, on a `ProcGenTilemap`, `is_valid_spawn_cell()`, `is_runtime_navigation_walkable()` and membership in the main playable component. Compound candidate enumeration (`_pick_compound_spawn_tile`) and the `player_spawn` fallback both use it. Selection order is unchanged.
- New read-only `ProcGenTilemap.get_main_playable_component()`: valid walkable cells 4-connected to `get_player_spawn()`, computed fresh per call so wall destruction or prop blockers can't leave it stale. It reuses the pre-terrain diagnostics' flood fill through a new public `reachable_from()`; the loader has no connectivity code. If the origin itself isn't walkable the set is empty and spawn fails closed.
- No safe tile: `_position_operator` returns false before moving the Operator, and contract activation fails with the existing `no_safe_operator_spawn_after_world_ingress_placement` reason plus a `detail` string. Camera snap already follows placement.
- New registered smoke `contract_world_playable_region_spawn_validity`: an exterior painted tile and a severed island (canonically valid, painted, but disconnected) are accepted by the old predicate and rejected by the new one; bad-only rects and bad `player_spawn` fail closed with the Operator unmoved; a mixed rect lands on the good tile deterministically; the landed tile is valid and in the component.
- Docs: CURRENT_STATE, FILE_INDEX, task-packet README.

## Evidence
- New smoke passes, and fails with seven errors when the loader predicate is reverted.
- Passed: `contract_world_ingress_spawn_clearance`, `world_ingress_spawner_smoke`, `ash_bell_lift_ingress_presentation_smoke`, and from the changed-file run `procgen_walkable_boundary`, `startup_world_entry`, `world_contract_prewarm`, `persistent_compound_runtime`, `procgen_performance_baseline_quick`, and the procgen streaming/lifecycle/region-frame set.
- Not green, identical on the unmodified base (checked by stashing my changes): `vaultwing_world_spawn` and `vaultwing_bond` (sprite PNGs fail to load), `procgen_ambient_enemy_real_world_spawn` (no camp markers placed), and `required_ritualant_ingress_contract_sweep` at seed 0 (Threadway checks). The sweep also can't finish 10 seeds in 500 s; I ran 1 and 3.
- `contract_world_population_placement_smoke` exits 0 but prints no PASS marker, so I count it as "no error", not as a pass.
- Caveat: the changed-file report therefore has `passed: false` because of those base failures.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The required ingress sweep is unusable at closeout and base-red; three changed-file tests are red on the base.
- Root cause / contributing factors: Pre-existing sweep/Threadway coupling, missing vaultwing sprites in the checkout, ambient markers absent on the test map.
- Prevention / pipeline improvement: A quick registered ingress profile without Threadway; triage the base-red tests.
- Tooling / docs drift discovered: `contract_world_population_placement_smoke.gd` has no PASS marker.
- Follow-up: review-contract-world-playable-region-spawn-validity-fix
- What worked: Isolating the island case by walling a tile's four neighbours tested the component rule without a separate fixture map.

## Next Handoff
- Next workstream: `review-contract-world-playable-region-spawn-validity-fix`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7
- Refresh reason: none
- Next action: Fresh-context paired review claims next; AR3 (`procgen-archive-resolve-semantic-echo`) waits on it.
- Blockers or open questions: none.

## Reminder
Ran on `agent/contract-world-playable-region-spawn-validity-fix` in a separate worktree. Your root checkout should stay on `main`; switch back if you left it.
