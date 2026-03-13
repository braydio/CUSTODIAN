# Enemy Behavior Director Implementation Notes (2026-03-08)

## Implemented Runtime Slice

### New systems

- Added `res://core/systems/enemy_director.gd`.
- Added `res://core/systems/threat_model.gd`.
- Added `res://core/systems/assault_lane.gd`.
- Added `res://core/systems/enemy_factory.gd`.

### Scene integration

- Added `EnemyDirector` node to `res://scenes/game.tscn`.
- `EnemyDirector` auto-resolves `WaveManager` and instantiates child `ThreatModel` and `EnemyFactory` if not explicitly wired.

### Wave integration contract

- `WaveManager` now supports:
  - `set_external_wave_plan(composition: Array[String], lane: String, objective: String)`
- When a plan is present, `WaveManager` uses the provided composition queue instead of its internal chooser.
- Forced lane limits spawn-node selection to that lane (fallback to any active node if lane has no active nodes).
- Forced objective is passed to enemies through `attack_objective`.

### Enemy compatibility

- `Enemy` now has `attack_objective` export (default `breach_command`).
- Target group scan order changes by objective:
  - `harass_player`
  - `destroy_power`
  - `destroy_turrets`
  - `breach_command`

### Threat model behavior

- Threat computed as:
  - `base_threat + wave*threat_per_wave + destroyed*threat_per_destroyed_structure + elapsed_minutes*threat_per_minute`
- Threat is converted to wave budget by rounded integer (`max(1, round(threat))`).

## Remaining Non-Blocking Work

- Add lane-specific success metrics beyond destroyed-structure delta.
- Add dedicated `siege` enemy scene and hook to factory export in main scene.
- Tune objective weights and threat coefficients through playtesting.

## Update (2026-03-10)

- Added explicit objective/threat telemetry to UI and terminal map output fallback.
- Added lane-level outcomes in runtime (`total_attacks`, `successful_attacks`, `success_ratio`).
