# CURRENT STATE — CUSTODIAN

Last updated: 2026-04-08

## Runtime Status

- Active runtime: Godot 4.x project in `custodian/`.
- Active main scene: `res://scenes/game.tscn`.
- Authority model: Godot-authoritative runtime with no external gameplay authority.
- Timing model: fixed-step deterministic simulation.
- State root: `GameState` autoload plus world/system nodes under `GameRoot`.
- Active UI shell: in-game command terminal embedded in the Godot HUD.

## Current Implemented Slice

- Contract generation is live and produces a contracted planet plus a linked tactical runtime world.
- Contract planet data now feeds runtime procgen through a shared world profile so the player is actually deployed onto a world shaped by the contracted planet.
- Procgen runtime consumes planet-linked variation for layout openness, compound footprint, foliage density, fruit chance, and world tinting.
- Ambient critter behavior also reads the same world profile so non-combat ambience matches the contracted planet.
- The command terminal has a multi-page shell with nav rail, action rail, center content pane, transcript, and command line input.
- Terminal pages are widget-backed for `OVERVIEW`, `STATUS`, `SECTORS`, `POWER`, `DEFENSE`, `SENSORS`, `INCIDENTS`, `ARCHIVE`, `RECON`, `CONTRACTS`, `HISTORY`, and `SETTINGS`.
- Terminal usability includes keyboard page/action navigation, transcript link jumps, command echo fallback, auto-following text panes, and a scrollable center content column.
- Interaction prompts for turret pickup and vehicle exit now reflect the actual `interact` input binding instead of stale hardcoded keys.

## Current Runtime Focus

- Godot-native contract loop, procgen runtime world, and command terminal are active implementation areas.
- Terminal page coverage is largely complete; remaining work is richer live data, tighter layout polish, and code modularization.
- Planet/runtime coupling is active and should be preserved when adjusting procgen or contract generation.

## Legacy Scope

- `python-sim/game/` and `python-sim/custodian-terminal/` remain preserved legacy reference only.
- Legacy Python terminal contracts are not runtime authority.
- Legacy AI tracker files under `python-sim/ai/` are historical reference, not the active update target.

## Active Gaps

- Some terminal pages still use placeholder or lightly-derived summaries instead of full live runtime controls/data.
- Terminal rendering still lives largely inside `custodian/game/ui/hud/ui.gd` and should eventually be split into dedicated page/controller scripts.
- The project still exits headless validation with existing object/resource leak warnings that have not yet been cleaned up.
- Broader infrastructure depth, save/load, and full long-horizon base systems are still incomplete relative to full doctrine scope.

## Documentation Status

- Active AI context directory: `custodian/docs/ai_context/`.
- Active runtime docs: `custodian/docs/*`.
- Godot implementation specs: `design/`.
- Locked doctrine: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`.
- Use `python-sim/design/DOC_STATUS.md` to resolve active-vs-legacy conflicts in older docs.
