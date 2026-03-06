# CURRENT STATE — CUSTODIAN

Last updated: 2026-03-05

## Runtime Status

- Active runtime: Godot 4.x project in `custodian/`.
- Active main scene: `res://scenes/game.tscn`.
- Authority model: Godot-authoritative (no external runtime process).
- Timing model: fixed-step simulation in `core/systems/simulation.gd` (`FIXED_DT = 1/60`).
- Pause model: hard pause toggled via `pause` input action (`Space`), sets `get_tree().paused`.
- State root: autoload `GameState` (`core/state/game_state.gd`).
- Embodied operator: `CharacterBody2D` with WASD movement in `entities/operator/operator.gd`.

## Current Implemented Godot Slice

- Project boot and run pipeline is live (`project.godot` + `scenes/game.tscn`).
- Operator movement is functional with normalized vector and configurable speed.
- Simulation tick accumulator loop is implemented and advances `GameState.tick` when unpaused.
- Scene includes world root, operator instance, camera, simulation node, and UI layer placeholders.
- Wave spawning is live via `core/systems/wave_manager.gd`, using lane-based spawn nodes under `World/SpawnNodes`.
- Enemy pressure now comes from timed wave spawns into `World/Enemies` instead of static preplaced drones.

## Legacy Scope (Preserved)

- `python-sim/game/` and `python-sim/custodian-terminal/` are legacy terminal-era systems.
- Legacy command parser/processor and `/command` transport are not active runtime authority.
- Legacy docs are retained for migration context and parity reference.

## Active Gaps

- Enemy objective targeting and structure damage/repair loops are not yet implemented in Godot runtime.
- Sector system and base layout rules need full scene/system integration.
- Infrastructure systems (power/logistics/fabrication/ARRN) need Godot-native runtime implementations.
- Save/load pipeline not yet implemented.

## Documentation Status

- Master doctrine remains locked at `python-sim/design/MASTER_DESIGN_DOCTRINE.md`.
- Foundation/playable docs have been updated to Godot-native assumptions.
- Active-vs-legacy design authority map is maintained in `python-sim/design/DOC_STATUS.md`.
- Terminal contract docs are archived under `python-sim/design/archive/terminal-deprecated/`.
