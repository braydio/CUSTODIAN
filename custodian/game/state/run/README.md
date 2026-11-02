# Run State

- Belongs here: current campaign session, run phase, objectives, outcome aggregation, transient fail/success state.
- Does not belong here: persistent Hub history, low-level procgen generation, actor sprite logic.
- Current migration status: scaffold only; `GameState` and `GameStats` remain compatibility owners.
- Current source of truth: `game/systems/core/state/game_state.gd`, `game/systems/core/state/game_stats.gd`, `game/world/procgen/custodian_contract_map.gd`.
