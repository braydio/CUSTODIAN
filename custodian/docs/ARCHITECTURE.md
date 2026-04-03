# CUSTODIAN Godot Architecture

Last updated: 2026-03-12

## Runtime Authority

Godot is the only authoritative runtime for active gameplay.

- State mutation source: simulation systems and runtime world loaders
- Presentation source: scene tree, tilemaps, UI, animation
- Input source: Godot input actions

## Layer Boundaries

1. State
- `res://game/systems/core/state/game_state.gd`
- Holds canonical run-state fields.

2. Systems
- `res://game/systems/core/systems/*.gd`
- Fixed-step or runtime orchestration systems.
- Key active systems:
  - `wave_manager.gd`
  - `enemy_director.gd`
  - `power.gd`
  - `supply_drop_manager.gd`
  - `contract_world_loader.gd`

3. Procgen / Contract Runtime
- `res://game/world/procgen/custodian_contract_map.gd`
- `res://game/world/procgen/proc_gen_tilemap.gd`
- `res://game/world/procgen/procgen.gd`
- Responsibilities:
  - contract planet selection
  - map seed derivation
  - procgen map instancing
  - live world handoff through `ContractWorldLoader`

4. Entities
- `res://game/actors/*`
- Operator, enemies, turrets, sectors, interactables, projectiles.
- Current runtime is hybrid:
  - legacy/static sectors still provide some systems compatibility
  - procgen runtime map now owns visible traversal space

5. Scenes / UI
- `res://scenes/*.tscn`
- `UI` owns HUD and in-game command terminal presentation.
- Terminal is now local-runtime driven rather than HTTP-backed.

## Runtime World Model

`res://scenes/game.tscn` boots with:

- `World/ContractMap`
- `ContractWorldLoader`
- `World/ProcGenRuntime` (created at runtime)

Flow:

1. `CustodianContractMap` generates contract payload
2. `ContractWorldLoader` reparents the generated `ProcGenMap` into active world
3. Static sector visuals and collisions are disabled when procgen runtime takes over
4. **Operator and spawn nodes are repositioned from procgen `level_data`**
5. **Camera still follows legacy sector bounds** - needs procgen-aware rebinding
6. **Other anchors (terminal, ammo caches) remain in legacy coords**

## Known Issues - Procgen Handoff is PARTIAL

| Priority | Issue | Impact |
|----------|-------|--------|
| HIGH | Camera bounds rebuilt from `World/Sectors` which are hidden | Camera feels "linked elsewhere" |
| HIGH | Mouse-to-world conversion wrong due to stale camera | Bullets fire toward wrong position |
| MEDIUM | Only Operator + SpawnNodes moved to procgen space | Terminal, ammo caches stay in legacy coords |
| MEDIUM | No camera rebind on contract completion | Camera never snaps to procgen player |
| LOW | Camera not in "camera" group | Game feel shake is no-op |

**The procgen handoff is PARTIAL until camera and non-player anchors are also migrated.**

## Determinism Rules

- Keep gameplay-affecting random choices derived from explicit seeds.
- Contract world generation is deterministic from a single contract seed.
- Avoid frame-dependent mutation paths for combat/system logic.

## Command Terminal Integration

- World terminal prop: `res://game/actors/terminal/command_terminal.tscn`
- Interaction contract:
  - group `interactable`
  - operator proximity query
  - `interact` action (`G`)
- Terminal runtime:
  - implemented in `res://game/ui/hud/ui.gd`
  - local snapshot mode only
  - no HTTP service dependency
  - renders contract metadata, wave/enemy/sector snapshot, planet preview, map preview

## Legacy Boundary

- `python-sim/` remains legacy reference only.
- Static sector scene content in `game.tscn` is no longer the primary traversed map when contract procgen is active.
- Legacy systems remain temporarily for compatibility until procgen compound structures become fully authoritative entities.
