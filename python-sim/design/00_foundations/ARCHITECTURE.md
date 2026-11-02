# ARCHITECTURE — CUSTODIAN (v2.0)

Status: Active (Godot-native)
Last updated: 2026-03-04

## Authority and Runtime

- Runtime authority is Godot 4.x.
- There is no external simulation server in the active game runtime.
- Legacy Python simulation remains preserved under `python-sim/game/` for reference and parity testing.

## Active Runtime Layers

1. State layer
- `res://core/state/game_state.gd` (autoload singleton).
- Holds canonical simulation state for the active run.

2. Systems layer
- `res://core/systems/*.gd`.
- Fixed-step deterministic logic mutates GameState.

3. Entity layer
- `res://entities/*`.
- Operator/enemy scripts consume state and input.

4. Scene/UI layer
- `res://scenes/*.tscn` and `res://ui/*`.
- Presentation, camera, and overlays read state; they do not own rules.

## Timing Model

- Simulation is fixed-step (target: 60Hz).
- `_process(delta)` accumulates and runs deterministic `simulation_step(FIXED_DT)` loops.
- Tactical pause is a hard freeze (`get_tree().paused`).
- Time scaling (1x/2x/4x) is permitted only if fixed-step determinism is preserved.

## Input Model

- Primary: embodied operator control (`move_up`, `move_down`, `move_left`, `move_right`, `pause`).
- Secondary: terminal/debug interface is legacy and non-authoritative for the active game.

## Legacy Reference Scope

The following are deprecated for active gameplay authority:

- `python-sim/custodian-terminal/`
- `python-sim/game/simulations/world_state/terminal/`
- HTTP `/command` and `/snapshot` runtime contract as primary control path

These remain preserved for reference, migration history, and debugging support.
