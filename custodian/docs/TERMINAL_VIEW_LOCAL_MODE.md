# Terminal View Local Mode

Last updated: 2026-03-11

## Runtime Behavior

The in-game command terminal now runs in **local snapshot mode** for gameplay wiring.

- World terminal art plays a short activation sequence before the shell opens.
- Closing the shell hides the UI immediately, then plays the terminal shutdown sequence after a short delay.
- World terminal activation art is sourced from `res://content/sprites/environment/props/terminal/runtime/body/command_terminal__body__interaction__activate__omni__4f__48.png` as a 2x2 sheet of 48x48 frames, with fallback to the older `computer_terminal` compatibility sheet while the rename lands.
- Once open, the shell enters ready state immediately.
- No HTTP server calls are required.
- Snapshot data is pulled directly from active runtime nodes.

## Snapshot Content

Terminal map pane now displays:

- Threat / assault context (from `EnemyDirector` when available)
- Wave status (`wave_number`, `in_progress`, `pending_spawns`)
- Enemy summary (total + drone/fast/heavy counts)
- Sector status list (`state` + HP%)
- Active contract snapshot (when `CustodianContractMap` is present and emitting):
  - `contract_seed`
  - `planet_key` + `planet_seed`
  - `map_seed`
  - `rooms` count + corridor spawn count
- Visual previews:
  - Planet preview (`SubViewport` render of contracted PixelPlanet scene)
  - Map preview (generated minimap texture from contract `level_data`)

## Local Commands

Available commands in terminal input:

- `HELP`
- `STATUS`
- `ENEMIES`
- `WAVE`
- `SECTORS`
- `CONTRACT`
- `PLANET`
- `MAP`
- `CLEAR`

## Sources

- `res://game/ui/hud/ui.gd`
- `res://game/systems/core/systems/wave_manager.gd`
- `res://game/world/procgen/custodian_contract_map.gd`
- `res://scenes/game.tscn` (`World/ContractMap`, terminal preview widgets)
