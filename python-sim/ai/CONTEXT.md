# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-03-06

## Purpose

Operational handoff summary for active implementation work.
Use this to quickly identify active runtime authority, current implementation depth, and migration boundaries.

## One-Paragraph Summary

CUSTODIAN is now a Godot-native 2.5D isometric tactical base-defense game with an embodied operator. The active runtime lives in `custodian/` and follows a fixed-step deterministic simulation model with tactical hard pause. The prior Python terminal stack remains preserved in `python-sim/` as legacy reference and migration history.

## Canonical Runtime Facts

- Engine: Godot 4.x
- Active scene root: `res://scenes/game.tscn`
- Authority: Godot runtime only
- Fixed-step loop: `core/systems/simulation.gd`
- State singleton: `core/state/game_state.gd`
- Input map includes `move_up/down/left/right` and `pause`
- Enemy wave system: `core/systems/wave_manager.gd` + spawn nodes grouped as `enemy_spawn`
- Turret system: `entities/sector/turret.gd` + preplaced defense turrets in `World/Sectors/DEFENSE`
- Enemy objective selection uses structure-priority groups (`command_post`, `power_node`, `turret`, `player`)

## Active Architecture Snapshot

- State layer: GameState singleton (tick + pause baseline)
- Systems layer: fixed-step simulation controller
- Entity layer: operator movement controller
- Scene layer: world root + camera + UI placeholder

## Legacy Boundaries

Treat these as deprecated for active runtime authority:

- `python-sim/game/simulations/world_state/`
- `python-sim/custodian-terminal/`
- `/command` HTTP contract as gameplay control path

These remain useful for:

- deterministic reference behavior
- migration reasoning
- historical design continuity

## Immediate Work Priorities

1. Sector/base damage + repair gameplay loop completion
2. Infrastructure systems depth (power/logistics/fabrication/relay)
3. Turret placement/build costs + upgrade loops
4. Save/load determinism pipeline

## Guardrails

- Keep simulation logic separated from rendering concerns.
- Preserve deterministic fixed-step mutation.
- Keep active-vs-legacy documentation labels explicit.
- Use `python-sim/design/DOC_STATUS.md` to resolve doc authority conflicts.
- Update `design/CHANGELOG.md`, `design/DEVLOG.md`, and `ai/CURRENT_STATE.md` on material architecture changes.
