# Sector Damage System Implementation Notes (2026-03-07)

## Implemented Runtime Scope

### Shared damage state

- Added `res://core/systems/damageable.gd`
- Canonical states: `operational`, `damaged`, `critical`, `destroyed`
- Canonical APIs/signals: `take_damage`, `repair`, `heal` alias, `get_efficiency`, `is_dead`

### Sector integration

- `Sector` now extends `Damageable`
- Sector health visuals and bars now read from shared efficiency/state
- Sector destruction now leaves disabled structure state (no `queue_free`)

### Turret integration

- `DefenseTurret` now extends `Damageable`
- Turret fire output now scales by damage state:
  - operational `1.0`
  - damaged `0.6`
  - critical `0.3`
  - destroyed `0.0`

### Command post fail state

- Added `res://entities/sector/command_post.gd`
- Command post destruction emits `game_over` and triggers `GameState.trigger_game_over(...)`
- Runtime tree is paused on game over
- UI surfaces game-over reason in interaction label

### Power-node coupling

- Added `res://entities/sector/power_node.gd`
- Power node output scales by state:
  - operational `1.0`
  - damaged `0.6`
  - critical `0.3`
  - destroyed `0.0`
- `power.gd` now uses power-node generation (`get_power_output`) and non-power-sector consumption

### Scene wiring

- `game.tscn` now assigns:
  - `command_post.gd` to `World/Sectors/COMMAND`
  - `power_node.gd` to `World/Sectors/POWER`

## Remaining Non-Blocking Work

- Add dedicated game-over screen/modal and restart flow
- Balance `power_output`/`power_cost` values against wave pacing
- Add optional telemetry for state transition events

## Scale/Map Consistency Update (2026-03-07)

- Added world scale contract doc: `custodian/docs/WORLD_SCALE_CONTRACT.md`
- Normalized sector map placement to tile-grid-aligned coordinates in `custodian/scenes/game.tscn`
- Reduced command sector from `64x64` to `32x32` tiles to remove cross-sector overlap
- Set gameplay camera baseline zoom to `1.0`
- Aligned operator collision/visual footprint in `custodian/entities/operator/operator.tscn`
