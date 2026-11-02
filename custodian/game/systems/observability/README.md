# Observability Systems

- Belongs here: telemetry services, bounded history, sector heatmaps, interest classification, developer observability state.
- Does not belong here: player HUD, direct simulation mutation, debug UI layout.
- Current migration status: scaffold only; observability is split between `game/systems/debug`, `game/systems/world`, and `game/systems/simulation`.
- Current source of truth: `game/systems/debug/dev_observatory.gd`, `game/systems/world/world_history.gd`, `game/systems/world/sector_heatmap.gd`, `game/systems/simulation/simulation_interest_manager.gd`.
