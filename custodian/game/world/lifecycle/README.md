# World Lifecycle

- Belongs here: world transitions, active world registry, spawn/rebind/cleanup contracts, world context payloads.
- Does not belong here: procgen terrain carving, authored map interaction state, HUD rendering.
- Current migration status: scaffold only; placement and rebinding still live in existing loader/scene scripts.
- Current source of truth: `game/systems/core/systems/contract_world_loader.gd`, Sundered Keep approach/map transition scripts.
