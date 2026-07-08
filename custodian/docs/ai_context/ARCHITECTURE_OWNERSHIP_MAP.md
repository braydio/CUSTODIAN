# Architecture Ownership Map

Compact agent-facing map for current and target ownership. Use this with `custodian/docs/ARCHITECTURE.md` and `custodian/docs/ai_context/FILE_INDEX.md`.

## Core Ownership

- Persistent state: currently `GameState`, `InventoryManager`, `CognitiveState`; target is `game/state/persistent/*` behind compatibility facades.
- Transient campaign/run state: currently `GameState`, `GameStats`, and contract generation records; target is `game/state/run/campaign_session.gd`, `campaign_outcome.gd`, and `run_phase.gd`.
- Active world binding: currently `contract_world_loader.gd`, scene-local transition code, camera/navigation rebinding; target is `game/world/lifecycle/*`.
- Procgen construction: `proc_gen_tilemap.gd` is the façade/state host; terrain, intent, foliage, and pre-terrain required-cell/diagnostic/repair algorithms already live in focused helpers. Further generation services should continue moving under `game/world/procgen/{generation,diagnostics,foliage,roads,authored_claims}`.
- Authored maps: currently `game/world/sundered_keep/`, `game/world/home/`, and gothic compound runtime files; target is `game/world/authored/<map>/` after explicit path migration.
- Combat simulation: currently `game/systems/combat/*`, operator combat profiles, enemy combat hooks, `NoiseEventBus`; target remains domain-owned under `game/systems/combat/` plus actor-local ability modules.
- Actor-local behavior: currently `operator.gd`, `enemy.gd`, allied/vehicle actors; target extracts enemy abilities/archetypes while preserving actor-owned movement and health contracts.
- HUD/terminal presentation: currently `game/ui/hud/ui.gd`, `game/ui/terminal/*`, `game/ui/components/*`, `game/ui/minimap/*`; target keeps UI as read-only presentation plus explicit command requests.
- Debug/observability: currently `custodian/debug/*`, `DevObservatory`, `WorldHistory`, `SectorHeatmap`, validation scripts; target routes observability services under `game/systems/observability/` without becoming player UI.

## Overburdened Coordinator Files

- `custodian/game/world/procgen/proc_gen_tilemap.gd`: procgen facade, construction policy, roads, terrain integration, foliage, portals, authored claims, export helpers.
- `custodian/game/world/procgen/custodian_contract_map.gd`: contract seed/profile creation, candidate selection, acceptance metrics, final visual promotion.
- `custodian/game/systems/core/systems/contract_world_loader.gd`: runtime handoff, anchor rebinding, vehicles, relays, resources, ingress, authored destinations.
- `custodian/game/actors/enemies/enemy.gd`: base enemy actor, variants, marine dash, parry handshake, loot, animation fallback, behavior hooks.
- `custodian/game/systems/core/state/game_state.gd`: run failure, modal pause, compatibility state, and future persistent/run/world state pressure.

## Extraction Status

- Phase 0 documentation/scaffold: active in `ARCHITECTURE_ORGANIZATION_PASS.md`.
- Iteration 1 foliage generation owner: `custodian/game/world/procgen/foliage/procgen_foliage_spawner.gd`.
- Foliage compatibility facade: `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Foliage forbidden ownership: terrain connectivity, road authority, elevation traversal, contract candidate scoring, authored-scene claims.
