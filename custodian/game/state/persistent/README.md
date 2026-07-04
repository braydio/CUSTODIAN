# Persistent State

- Belongs here: Hub state, durable unlocks, knowledge state, campaign history, save/load-facing meta progression.
- Does not belong here: active world nodes, transient run timers, TileMap construction, HUD widgets.
- Current migration status: scaffold only; compatibility state remains in existing autoloads.
- Current source of truth: `game/systems/core/state/game_state.gd`, `game/systems/core/systems/inventory_manager.gd`, `game/systems/cognitive/cognitive_state_system.gd`.
