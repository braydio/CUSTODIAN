# FILE INDEX — CUSTODIAN

Last updated: 2026-04-08

## Active Runtime Entry

- `custodian/project.godot` — Godot project config and input map
- `custodian/scenes/game.tscn` — active game scene and terminal layout

## Active Runtime Systems

- `custodian/game/world/procgen/custodian_contract_map.gd` — contract generation and planet-linked world profile creation
- `custodian/game/world/procgen/proc_gen_tilemap.gd` — runtime procgen world generation and application of planet world profile
- `custodian/game/systems/core/systems/ambient_critter_manager.gd` — ambient critter spawning/color behavior linked to world profile
- `custodian/game/ui/hud/ui.gd` — active command terminal and HUD logic

## Active Interaction/UI Files

- `custodian/game/actors/defense/turret.gd` — turret interaction prompt reads actual interact binding
- `custodian/game/actors/base/vehicle_base.gd` — vehicle exit prompt reads actual interact binding
- `custodian/docs/TERMINAL_VIEW_LOCAL_MODE.md` — terminal-related runtime doc reference

## Active Documentation

- `custodian/docs/ai_context/CURRENT_STATE.md` — current implementation state
- `custodian/docs/ai_context/CONTEXT.md` — project primer and working rules
- `custodian/docs/ai_context/FILE_INDEX.md` — this file
- `custodian/docs/ARCHITECTURE.md` — runtime architecture reference
- `custodian/docs/SCENE_HIERARCHY.md` — scene organization reference
- `custodian/docs/GDSCRIPT_STANDARDS.md` — scripting standards
- `design/` — active Godot feature/system implementation specs

## Legacy Reference Only

- `python-sim/game/` — legacy simulation
- `python-sim/custodian-terminal/` — legacy terminal UI
- `python-sim/ai/` — historical AI context pack, superseded by `custodian/docs/ai_context/`
- `python-sim/design/archive/` — historical design/archive material
