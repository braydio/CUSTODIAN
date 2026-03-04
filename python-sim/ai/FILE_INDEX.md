# FILE INDEX — CUSTODIAN

Last updated: 2026-03-04

## Active Runtime (Godot)

### Project Entry

- `custodian/project.godot` — Godot project config and input map
- `custodian/scenes/game.tscn` — active main scene

### Core Runtime

- `custodian/core/state/game_state.gd` — GameState autoload singleton
- `custodian/core/systems/simulation.gd` — fixed-step simulation loop + pause toggle

### Entities

- `custodian/entities/operator/operator.gd` — embodied operator movement controller
- `custodian/entities/operator/operator.tscn` — operator scene

### Active Runtime Docs

- `custodian/docs/ARCHITECTURE.md`
- `custodian/docs/GDSCRIPT_STANDARDS.md`
- `custodian/docs/SCENE_HIERARCHY.md`

## Canonical Design Docs

- `python-sim/design/MASTER_DESIGN_DOCTRINE.md` — locked master doctrine
- `python-sim/design/DOC_STATUS.md` — active vs legacy documentation authority map
- `python-sim/design/00_foundations/` — architecture/timing/identity foundations
- `python-sim/design/30_playable_game/` — control/runtime-play model docs

## Legacy Reference (Deprecated)

- `python-sim/game/` — terminal-era Python simulation
- `python-sim/custodian-terminal/` — terminal UI
- `python-sim/design/archive/terminal-deprecated/` — archived command-contract docs
