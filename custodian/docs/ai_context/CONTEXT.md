# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-05-02

## Purpose

Operational handoff summary for active Godot implementation work.
Use this directory as the current AI-facing context pack, not `python-sim/ai/`.
Use `custodian/AGENTS.md` as the first local stop before using this pack.

## One-Paragraph Summary

CUSTODIAN is a Godot-native tactical base-defense game with an embodied operator, deterministic runtime simulation, contract-driven deployment, and an in-world command terminal. The active game lives in `custodian/`, the active implementation specs live in `design/`, and the old Python simulation/terminal stack remains preserved only as migration and design history.

## Canonical Runtime Facts

- Engine: Godot 4.x
- Main scene: `res://scenes/game.tscn`
- Runtime authority: Godot only
- Active command shell: HUD terminal in `custodian/game/ui/hud/ui.gd`
- Contract/runtime coupling: contract planet generation feeds procgen world generation through a shared world profile
- Input prompts: interaction UI should derive from `InputMap`, not hardcoded keys
- Operator combat selection: Fists/unarmed is a first-class `OperatorWeaponDefinition` profile selected with `toggle_unarmed`; normal weapon cycling excludes Fists and only cycles armed profiles.
- Forest Shrumb cognitive drops now have a v1 foundation through `InventoryManager`, `CognitiveState`, `cognitive_pickup`, `shrumb_dropper`, and the live `ambient_shrumb.tscn` actor. Ambient spawning now uses this shrumb actor directly; the former scav droid scene path is removed.
- Procedural ruin prop variants have a v1 visual-only foundation under `custodian/content/props/ruins/`, using seeded layer assembly from authored sprites, overlays, rubble pieces, and a conservative palette shader. Collision remains authored and stable through `PropDefinition.collision_scene`.

## Active Architecture Snapshot

- Contract layer: contract map generation plus promoted runtime metadata
- World layer: procgen tilemap/runtime world systems
- Simulation layer: deterministic Godot runtime systems
- Cognitive layer: autoloaded inventory ledger and cognitive state values expose drop/combat modifier getters, with only pickup/drop feedback wired in v1
- UI layer: HUD + command terminal pages/widgets
- Actor layer: operator, enemies, structures, defenses, ambient entities

## Working Rules

- Treat `custodian/` and `design/` as the active implementation surface.
- Start all local work by reading `custodian/AGENTS.md`, then this context pack.
- Keep deterministic simulation separate from rendering/UI logic.
- When runtime behavior changes materially, update this directory alongside the relevant design/runtime docs.
- Do not silently shift authority back to Python-era systems or docs.

## Immediate Priorities

1. Validate Fists selection/combat in play and keep queued selection deterministic.
2. Move melee timing and active windows into explicit attack profile data.
3. Deepen terminal pages with richer live runtime data and interactions.
4. Preserve and extend planet-to-runtime world coupling as procgen evolves.
5. Wire true Forest Shrumbs into the intended spawning/procgen path and decide which cognitive readout belongs in HUD/debug.
6. Author ruin prop slices, overlay/rubble assets, and `PropDefinition` resources for the procedural prop system.

## Update Expectation

On significant architecture or behavior changes, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/CONTEXT.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/AGENTS.md` when local routing, migration flow, or operating rules change

Optionally also update legacy changelog/devlog material for historical continuity.
