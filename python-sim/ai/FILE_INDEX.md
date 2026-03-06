# FILE INDEX — CUSTODIAN

Last updated: 2026-03-06

## Active Runtime (Godot)

### Project Entry

- `custodian/project.godot` — Godot project config and input map
- `custodian/scenes/game.tscn` — active main scene

### Core Runtime

- `custodian/core/state/game_state.gd` — GameState autoload singleton
- `custodian/core/systems/simulation.gd` — fixed-step simulation loop + pause toggle
- `custodian/core/systems/wave_manager.gd` — timed enemy wave orchestration + difficulty scaling
- `custodian/core/systems/spawn_node.gd` — lane-tagged enemy ingress points
- `custodian/core/systems/power.gd` — sector power distribution model

### Entities

- `custodian/entities/operator/operator.gd` — embodied operator movement controller
- `custodian/entities/operator/operator.tscn` — operator scene
- `custodian/entities/enemies/enemy.gd` — enemy controller + structure-priority objective targeting
- `custodian/entities/projectiles/bullet.gd` — shared projectile logic (player + defense teams)
- `custodian/entities/sector/turret.gd` — automated defense turret runtime + damage-state efficiency
- `custodian/entities/sector/turret.tscn` — base turret scene
- `custodian/entities/sector/turret_gunner.tscn` — balanced turret variant
- `custodian/entities/sector/turret_blaster.tscn` — high-damage turret variant
- `custodian/entities/sector/turret_repeater.tscn` — rapid-fire turret variant
- `custodian/entities/sector/turret_sniper.tscn` — long-range turret variant

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
