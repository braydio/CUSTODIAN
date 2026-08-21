# Architecture Ownership Map

Compact agent-facing map for current and target ownership. Use this with `custodian/docs/ARCHITECTURE.md` and `custodian/docs/ai_context/FILE_INDEX.md`.

## Core Ownership

- Persistent state: currently `GameState`, `InventoryManager`, `CognitiveState`; target is `game/state/persistent/*` behind compatibility facades.
- Transient campaign/run state: currently `GameState`, `GameStats`, and contract generation records; target is `game/state/run/campaign_session.gd`, `campaign_outcome.gd`, and `run_phase.gd`.
- Active world binding: currently `contract_world_loader.gd`, scene-local transition code, camera/navigation rebinding; target is `game/world/lifecycle/*`.
- Procgen construction: `proc_gen_tilemap.gd` is the façade/state host; terrain, intent, playability, foliage, encounter cadence, and pre-terrain required-cell/diagnostic/repair algorithms live in focused helpers. `encounters/encounter_cadence_planner.gd` owns data-only combat-pocket cadence; it never spawns actors or mutates geometry.
- Authored maps: currently `game/world/sundered_keep/`, `game/world/home/`, and gothic compound runtime files; target is `game/world/authored/<map>/` after explicit path migration.
- Combat simulation: shared contracts remain under `game/systems/combat/*`; actor-local controllers/abilities own bounded phase machines. `OperatorGuardController` owns guard/parry/posture/break state while `operator.gd` supplies health, stamina, damage, movement, input, and presentation services. Enemy special abilities follow the same actor-hosted boundary.
- Enemy behavior: `EnemyBehaviorStateMachine` owns strategic state and movement goals; perception owns detection; objective sensor scores candidates; blackboard stores working memory; profiles tune behavior. `EnemyAnimationSet` plus `EnemyPresentationController` own semantic animation mapping/playback only. Actor-local ability modules own extracted special-decision/execution seams. `enemy.gd` remains the shared combat/locomotion host, reaction authority, compatibility surface, and disabled-BSM legacy fallback.
- Navigation/elevation: `NavigationSystem` owns path selection; `ProcGenTilemap` plus `ElevationMap` own movement legality. Ambient spawning remains exclusively `AmbientEnemySpawner` plus `AmbientEnemyCamp`, with loader markers adapting encounter-plan data.
- HUD/terminal presentation: currently `game/ui/hud/ui.gd`, `game/ui/terminal/*`, `game/ui/components/*`, `game/ui/minimap/*`; target keeps UI as read-only presentation plus explicit command requests.
- Debug/observability: currently `custodian/debug/*`, `DevObservatory`, `WorldHistory`, `SectorHeatmap`, validation scripts; target routes observability services under `game/systems/observability/` without becoming player UI.

## Overburdened Coordinator Files

- `custodian/game/world/procgen/proc_gen_tilemap.gd`: procgen facade, construction policy, roads, terrain integration, foliage, portals, authored claims, export helpers.
- `custodian/game/world/procgen/custodian_contract_map.gd`: contract seed/profile creation, candidate selection, acceptance metrics, final visual promotion.
- `custodian/game/systems/core/systems/contract_world_loader.gd`: runtime handoff, anchor rebinding, vehicles, relays, resources, ingress, authored destinations.
- `custodian/game/actors/enemies/enemy.gd`: base enemy actor, remaining Marine/Savage special phase hosts, shared ability combat services, parry handshake, loot, animation fallback, behavior hooks.
- `custodian/game/actors/enemies/presentation/`: semantic animation-set and playback authority; presentation never owns hit timing or behavior state.
- `custodian/game/actors/enemies/abilities/`: actor-local special ability modules; Falcon Punch is the first complete extraction, owning typed tuning, cadence, target capture, phases, movement/contact, reversal state, and telemetry.
- `custodian/game/actors/operator/operator.gd`: shared Operator combat/movement/presentation host and compatibility surface; guard/parry state has moved to `combat/operator_guard_controller.gd` with typed `OperatorGuardConfig` tuning.
- `custodian/game/systems/core/state/game_state.gd`: run failure, modal pause, compatibility state, and future persistent/run/world state pressure.

## Extraction Status

- Phase 0 documentation/scaffold: active in `ARCHITECTURE_ORGANIZATION_PASS.md`.
- Iteration 1 foliage generation owner: `custodian/game/world/procgen/foliage/procgen_foliage_spawner.gd`.
- Foliage compatibility facade: `custodian/game/world/procgen/proc_gen_tilemap.gd`.
- Foliage forbidden ownership: terrain connectivity, road authority, elevation traversal, contract candidate scoring, authored-scene claims.
