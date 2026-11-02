# COMMAND PRESSURE SCENARIO V1

- Status: `complete`
- Authority: `design/02_features/terminal/COMMAND_PRESSURE_SCENARIO_V1.md`
- Goal: Prove the terminal-centered physical gameplay loop through one authored, deterministic scenario using existing live Godot systems.
- Constraints: no procgen dependency; no parallel combat/economy/HP/power state; scenario launch only; normal launch unchanged; no production art; no push.
- Acceptance: focused setup and physical-loop smokes pass; changed-file validation and archive-boundary validation pass; docs describe live ownership.
- Completed: design authority; inert scenario launch/isolation; exact authored layout/resources/repair ports; live Power/Sector/ResourceLedger/WaveManager/Enemy/terminal integration; derived after-action observation; Observatory events; focused validation; active documentation drift repair.
- Deferred: developer-owned interactive runs for turret, capacitor/load-shedding, and repair/direct-combat balance; human Moment Forge/visual review.

## Ownership And Timing

- Owner: Codex implementation session
- Created: 2026-08-30
- Last updated: 2026-08-30

## Work Surface

- Read: repository primers, doctrine, terminal/assault/authored-level specs, current state/index/ownership/validation, graph relationships, and live runtime seams.
- Change: scenario bootstrap/root/director; WaveManager authored ingress; physical repair; terminal action/read-model seams; focused validation; active docs/indexes.
- Out of scope: strategic simulation, procgen, campaign persistence, new content families, broad terminal refactor, balance evaluation.

## Plan

1. Establish durable authority and scenario isolation contract.
2. Add inert argument-driven bootstrap and authored physical setup.
3. Add public authored-wave ingress and observation state.
4. Add live world actions and reusable physical repair interaction.
5. Surface scenario state through existing terminal snapshots/view model.
6. Add focused automated smokes and run repository validation.
7. Repair documentation drift, review authority boundaries, and commit.

## Drift Review

- Primary authority: new active scenario spec; terminal and assault specs require updates.
- `CURRENT_STATE.md`: add implemented scenario and validation state at completion.
- `CONTEXT.md`: no new global architectural rule beyond existing physical-authority doctrine unless implementation reveals one.
- `FILE_INDEX.md`: index scenario entrypoints, world action service, repair component, and smokes.
- Local routing/readmes: no new routing file required.

## Evaluation Handoff

The user explicitly owns hands-on evaluation. After automated acceptance:

1. Run turret preparation route.
2. Run capacitor plus load-shedding route.
3. Run repair/direct-combat route without major construction.
4. Review a 6–8 second north-ingress/first-contact Moment Forge capture if desired.

Record balance observations here without silently changing recipe costs.

## Handoff

- Next action: developer-owned interactive balance/playability evaluation only.
- Best starting files: scenario director, `wave_manager.gd`, `game.tscn`, terminal snapshot/view model.
- Validation to run: both scenario smokes, changed-file runner, historical archive boundary validator, headless project load.
- Blockers or open questions: none; interactive balance remains intentionally developer-owned.

## Validation Record

- `command_pressure_scenario_setup_smoke.gd`: PASS.
- `command_pressure_physical_loop_smoke.gd`: PASS.
- scenario-mode headless boot: PASS; no contract generation began during the observed startup window.
- Godot import/script registration: PASS; only repository-known import UID and exit-leak warnings.
- historical archive boundary validator: PASS.
- changed-file runner: 13/14 selected checks passed. The sole failure was `terminal_page_order_regression`, which printed its own PASS and was classified failed because the ordinary procgen fixture emitted the pre-existing `ProcGenTilemap._is_inside_combat_readability_spawn_clearance` freed-instance error during teardown/streaming. The scenario smokes and other selected terminal, Sensors, construction, WaveManager, prewarm, and validation-runner checks passed.
- Moment Forge and manual three-route playtests: not run by explicit user direction; developer-owned evaluation.
