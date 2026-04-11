# CURRENT STATE — CUSTODIAN

Last updated: 2026-04-10

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
- Procgen now also builds ruined horizontal wall overlay strips from the new 4x3 96x96 wall sheet for top-exposed horizontal wall runs, including interior/corridor runs, using repeated middle segments and taller exposed-row collision.
- Exposed horizontal wall runs can also receive ruined endcap overlays from the matching 96x96 endcap sheet with light vertical staggering.
- Exposed vertical wall faces can now reuse the same ruined wall sheet through rotated repeated segments so interior corridors and corners read closer to the exterior ruin massing.
- Procgen runtime wall collision now also expands upward and sideways on exposed ruined-wall faces so collision reads closer to the visible wall bulk.
- Procgen runtime can now also show a debug collision overlay for those generated wall blockers while tuning overblocking.
- The active procgen map scene can now hide the original wall tilemap visuals so ruined overlays and collision debug can be inspected in isolation.
- The active procgen map scene can also restrict runtime collision to only tiles currently using the ruined overlay treatment for cleaner collision debugging.
- Ambient critter behavior also reads the same world profile so non-combat ambience matches the contracted planet.
- The command terminal has a multi-page shell with nav rail, action rail, center content pane, transcript, and command line input.
- Terminal pages are widget-backed for `OVERVIEW`, `STATUS`, `SECTORS`, `POWER`, `DEFENSE`, `SENSORS`, `INCIDENTS`, `ARCHIVE`, `RECON`, `CONTRACTS`, `HISTORY`, and `SETTINGS`.
- Terminal usability includes keyboard page/action navigation, transcript link jumps, command echo fallback, auto-following text panes, and a scrollable center content column.
- Interaction prompts for turret pickup and vehicle exit now reflect the actual `interact` input binding instead of stale hardcoded keys.

## Current Runtime Focus

- Godot-native contract loop, procgen runtime world, and command terminal are active implementation areas.
- Terminal page coverage is largely complete; remaining work is richer live data, tighter layout polish, and code modularization.
- Planet/runtime coupling is active and should be preserved when adjusting procgen or contract generation.
- Procgen runtime handoff wiring now explicitly snaps the world camera to the operator spawn, rebinds navigation to promoted procgen tilemaps, and treats procgen bounds as the only camera clamp authority.
- Operator mouse aim now resolves through the active world camera path first, reducing procgen handoff desync risk.
- Procgen streaming now batches navigation rebuilds around reveal completion instead of rebuilding navigation every reveal frame during world bring-up.

## Legacy Scope

- `python-sim/game/` and `python-sim/custodian-terminal/` remain preserved legacy reference only.
- Legacy Python terminal contracts are not runtime authority.
- Legacy AI tracker files under `python-sim/ai/` are historical reference, not the active update target.

## Active Gaps

- Some terminal pages still use placeholder or lightly-derived summaries instead of full live runtime controls/data.
- Terminal rendering still lives largely inside `custodian/game/ui/hud/ui.gd` and should eventually be split into dedicated page/controller scripts.
- The project still exits headless validation with existing object/resource leak warnings that have not yet been cleaned up.
- Broader infrastructure depth, save/load, and full long-horizon base systems are still incomplete relative to full doctrine scope.
- The remaining procgen handoff gap is live runtime verification: camera bounds, cursor aim, reachable anchors, and enemy navigation still need an end-to-end boot test in Godot.

## Documentation Status

- Active AI context directory: `custodian/docs/ai_context/`.
- Active runtime docs: `custodian/docs/*`.
- Godot implementation specs: `design/`.
- Locked doctrine: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`.
- Use `python-sim/design/DOC_STATUS.md` to resolve active-vs-legacy conflicts in older docs.
