# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-04-08

## Purpose

Operational handoff summary for active Godot implementation work.
Use this directory as the current AI-facing context pack, not `python-sim/ai/`.

## One-Paragraph Summary

CUSTODIAN is a Godot-native tactical base-defense game with an embodied operator, deterministic runtime simulation, contract-driven deployment, and an in-world command terminal. The active game lives in `custodian/`, the active implementation specs live in `design/`, and the old Python simulation/terminal stack remains preserved only as migration and design history.

## Canonical Runtime Facts

- Engine: Godot 4.x
- Main scene: `res://scenes/game.tscn`
- Runtime authority: Godot only
- Active command shell: HUD terminal in `custodian/game/ui/hud/ui.gd`
- Contract/runtime coupling: contract planet generation feeds procgen world generation through a shared world profile
- Input prompts: interaction UI should derive from `InputMap`, not hardcoded keys

## Active Architecture Snapshot

- Contract layer: contract map generation plus promoted runtime metadata
- World layer: procgen tilemap/runtime world systems
- Simulation layer: deterministic Godot runtime systems
- UI layer: HUD + command terminal pages/widgets
- Actor layer: operator, enemies, structures, defenses, ambient entities

## Working Rules

- Treat `custodian/` and `design/` as the active implementation surface.
- Keep deterministic simulation separate from rendering/UI logic.
- When runtime behavior changes materially, update this directory alongside the relevant design/runtime docs.
- Do not silently shift authority back to Python-era systems or docs.

## Immediate Priorities

1. Deepen terminal pages with richer live runtime data and interactions.
2. Continue modularizing terminal code out of `ui.gd`.
3. Preserve and extend planet-to-runtime world coupling as procgen evolves.
4. Resolve known leak/resource warnings during headless exit when that work becomes active.

## Update Expectation

On significant architecture or behavior changes, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/CONTEXT.md`
- `custodian/docs/ai_context/FILE_INDEX.md`

Optionally also update legacy changelog/devlog material for historical continuity.
