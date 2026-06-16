# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-06-16

## Purpose

Operational handoff summary for active Godot implementation work.
Use this directory as the current AI-facing context pack, not `python-sim/ai/`.
Use `custodian/AGENTS.md` as the first local stop before using this pack.

## One-Paragraph Summary

CUSTODIAN is a Godot-native tactical base-defense game with an embodied operator, deterministic runtime simulation, contract-driven deployment, and an in-world command terminal. The active game lives in `custodian/`, the active implementation specs live in `design/`, and the old Python simulation/terminal stack remains preserved only as migration and design history.

## Current Lore Canon

The Great Severance is no longer framed as a collapse caused by lost shared context. The internal root cause is The Unarrival: a supernatural/cosmic provenance wound that damaged reality's ability to maintain shared cause, memory, witness, and origin. Shared-context collapse, contradictory archives, and fragmented histories are symptoms. Knowledge recovery should be treated as provenance stabilization across object, origin, witness, time, use, and meaning.

## Canonical Runtime Facts

- Engine: Godot 4.x
- Main scene: `res://scenes/game.tscn`
- Beginning/Home scene: `res://scenes/home_custodian_begin.tscn` implements Objective 01, tracing the Custodian-band frequency to a damaged Field Terminal and establishing witness contact; it is a dedicated scene and not yet the application main scene.
- Runtime authority: Godot only
- Active command shell: HUD terminal in `custodian/game/ui/hud/ui.gd`, with terminal helper modules under `custodian/game/ui/terminal/`
- Current gameplay HUD style: compact Black Reliquary gothic/brass UI. Assets live in `custodian/content/ui/black_reliquary/`; reusable theme/components/HUD scenes live under `custodian/game/ui/`. Prompt text must be real Godot labels, not baked into images, the minimap frame should embed the shared live tactical minimap renderer rather than static marker art, authored-map-specific HUD content must only show inside its owning map, debug diagnostics should live in the dedicated F12/`debug_hud` debug screen instead of normal HUD labels, and terminal focus must mask gameplay overlays without re-showing inactive map-local HUDs.
- Contract/runtime coupling: contract planet generation feeds procgen world generation through a shared world profile
- Input prompts: interaction UI should derive from `InputMap`, not hardcoded keys
- Operator combat selection: Fists/unarmed is a first-class `OperatorWeaponDefinition` profile selected with `toggle_unarmed`; normal weapon cycling excludes Fists and only cycles armed profiles. Melee attack physics resolve through `MeleeAttackProfile` resources referenced by each weapon definition, with legacy operator melee exports kept only as fallbacks. The offhand secondary button (`aim_hold` / `attack_secondary`, right mouse or LT) is context-sensitive: selected ranged primary holds primary ranged-ready, melee/unarmed plus equipped P-9 holds sidearm-ready, and melee/unarmed with empty or guard-focused offhand starts tap parry / held guard. Primary fires the active ranged weapon while ranged-ready or sidearm-ready is active and can quick panic-shot along current facing from a ranged loadout when aim is not held. `Shift+primary` remains the melee/unarmed heavy chord. Operator movement now supports WASD/left stick movement, mouse/right-stick aim, and movement-first dodge with idle aiming backstep.
- Forest Shrumb cognitive drops now have a v1 foundation through `InventoryManager`, `CognitiveState`, `cognitive_pickup`, `shrumb_dropper`, and the live `ambient_shrumb.tscn` actor. Ambient spawning now uses this shrumb actor directly; the former scav droid scene path is removed.
- Procedural ruin prop variants have a v1 visual-only foundation under `custodian/content/props/ruins/`, using seeded layer assembly from authored sprites, overlays, rubble pieces, and a conservative palette shader. Collision remains authored and stable through `PropDefinition.collision_scene`.
- Procgen terrain construction now has a dedicated metadata-first `TerrainBuilder` pass under `game/world/procgen/terrain/`; elevation/cliff visuals remain separate from `ElevationMap` height/traversal rules and resolve through registered terrain sources in `procgen_world_tileset.tres`.
- Procgen world progression now has a route-first Intent Graph / Ascent V1 layer. `ProcGenTilemap.world_shape_mode` defaults to `ASCENT_FIELD`, which does not use the old BSP/corridor/cellular cave mask as the base world substrate. It builds a deterministic ascent spine, broad exterior route, terraces, branch pockets, sparse cliff/ruin blockers, and story/faction reservations from the world profile, then exports the graph/summary/reserved regions in level data. `LEGACY_CAVE` keeps the old generator path available. TerrainBuilder consumes intent required cells and reserved regions for guarded height/traversal metadata. Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.
- Sundered Keep is a live authored connected-map destination under `game/world/sundered_keep/`. Its active front-gate level is now built from `content/levels/sundered_keep/sundered_keep_front_gate_large.json` through `sundered_keep_tilemap_loader.gd`, giving the map `112x80` tile bounds, a southern broken-causeway spawn, outer landing, pre-gate Return Mooring/key alcoves, gatehouse, locked portcullis, vestibule, courtyard, rampart/service branches, and Great Hall front. Interaction state remains in `sundered_keep_map.gd`: real game32 Return Mooring assets provide diegetic return travel, the Main Gate starts closed with a four-tile/two-row collision blocker and requires local/inventory item `sundered_gate_key`, the Great Hall entry has its own openable double-door blocker, and the map exports live minimap floor/wall data plus tile/world conversion methods for the compact HUD minimap. Temporary review mode is active in `ContractWorldLoader`: `debug_start_near_sundered_keep_entrance` starts the Operator next to the main-map Sundered Keep travel gate.
- Enemy marine dash is now a documented heavy commitment attack, not just forced sprite playback: windup/telegraph locks direction, dash travel owns the only active hit window, impact/recovery enforce a punish window, and feel comes from hitstop, knockback, camera shake, and Operator impact-lock feedback. Current runtime uses the east body/FX strip as fallback while directional dash body/FX sheets and the dash audio stack are tracked in `REQUIRED_ASSETS.md`.

## Active Architecture Snapshot

- Contract layer: contract map generation plus promoted runtime metadata
- World layer: procgen tilemap/runtime world systems
- Simulation layer: deterministic Godot runtime systems
- Cognitive layer: autoloaded inventory ledger and cognitive state values expose drop/combat modifier getters, with only pickup/drop feedback wired in v1
- UI layer: HUD + command terminal pages/widgets; terminal command, snapshot, map preview, and planet preview helpers live under `game/ui/terminal/`
- Black Reliquary UI layer: `game/ui/theme/` centralizes palette/styles/assets, `game/ui/components/` owns reusable compact panels/prompts/minimap/icon labels, and `game/ui/hud/custodian_hud.tscn` is the first local gameplay HUD shell used by Sundered Keep and Home. The Black Reliquary minimap component wraps `game/ui/minimap/minimap_panel.tscn` so it stays live while using gothic/brass chrome.
- Debug UI layer: `game/ui/hud/debug_screen.tscn` owns F12/`debug_hud` diagnostics as a read-only tabbed overlay fed by `game/ui/hud/ui.gd`.
- Terminal overlay policy: `game/ui/hud/ui.gd` owns terminal-open suppression for legacy HUD labels, minimap/crosshair, `gameplay_overlay` HUD scenes, and the debug screen; context-aware overlays such as the Sundered Keep HUD preserve their map-local active state when terminal suppression is removed.
- Home beginning layer: `game/world/home/` owns the first Field Terminal witness-contact slice, using the Road of Witnesses prototype map and Black Reliquary HUD as the current presentation shell.
- Actor layer: operator, enemies, structures, defenses, ambient entities
- Enemy dash layer: `enemy_marine.tscn` enables the shared enemy phased dash values; `enemy.gd` owns the generic marine dash phases and impact feedback; `operator.gd` exposes `apply_enemy_dash_impact(...)`; Sundered Keep's local hallway ambush mirrors the same heavy dash tuning.

## Working Rules

- Treat `custodian/` and `design/` as the active implementation surface.
- Start all local work by reading `custodian/AGENTS.md`, then this context pack.
- Use task packets as optional risk-control and handoff records: skip narrow low-risk work, use the compact template when durable scope or acceptance helps, and expand it only for high-risk or multi-session work.
- When a task packet exists, keep it current as scope, blockers, acceptance, or deferred work materially changes.
- Use `custodian/docs/ai_context/VALIDATION_RECIPES.md` for validation command selection.
- Use `custodian/docs/ai_context/prompts/` for reusable task prompts, and confirm prompt paths before acting.
- Keep deterministic simulation separate from rendering/UI logic.
- When runtime behavior changes materially, update this directory alongside the relevant design/runtime docs.
- Do not silently shift authority back to Python-era systems or docs.

## Immediate Priorities

1. Create or ingest the enemy marine heavy dash directional body sheets, FX overlay sheets, and five-part audio stack now tracked in `REQUIRED_ASSETS.md`.
2. Validate profile-backed Fists/melee combat in play and keep queued selection deterministic.
3. Clean remaining animation-state documentation/assets around deprecated `attack_light` compatibility.
4. Deepen terminal pages with richer live runtime data and interactions.
5. Preserve and extend planet-to-runtime world coupling as procgen evolves.
6. Continue Sundered Keep follow-up with encounter composition, save/load persistence for gate/key state, and eventual TileSet/TileMapLayer authoring if the JSON-driven Sprite2D authored map becomes hard to maintain.
7. Keep Sundered Keep/Home prompts and normal-play status surfaces on the compact Black Reliquary HUD API; route diagnostics to the dedicated debug screen instead of reintroducing giant panels or debug labels during normal gameplay.
8. Decide when the Home beginning scene should become the boot/default entry, then wire it into the world-transition/campaign-flow spine without regressing the current contract/procgen sandbox.
9. Wire true Forest Shrumbs into the intended spawning/procgen path and decide which cognitive readout belongs in HUD/debug.
10. Author ruin prop slices, overlay/rubble assets, and `PropDefinition` resources for the procedural prop system.

## Update Expectation

On significant architecture or behavior changes, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/CONTEXT.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- relevant files under `custodian/docs/ai_context/task_packets/`
- relevant files under `custodian/docs/ai_context/prompts/`
- `custodian/AGENTS.md` when local routing, migration flow, or operating rules change

Optionally also update legacy changelog/devlog material for historical continuity.
