# FILE INDEX — CUSTODIAN

Last updated: 2026-05-03

## Local Entry And Workflow

- `custodian/AGENTS.md` — mandatory local primer for routing, context retrieval, docs-drift review, and migration execution
- `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md` — detailed migration and drift-remediation workflow
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` — template for non-trivial agent implementation, review, migration, validation, asset workflow, and multi-file docs work
- `custodian/docs/ai_context/task_packets/README.md` — task packet workflow and active packet index
- `custodian/docs/ai_context/task_packets/VALIDATION_RECIPES.md` — active packet for implementing canonical validation recipes

## Active Runtime Entry

- `custodian/project.godot` — Godot project config and input map
- `custodian/scenes/game.tscn` — active game scene and terminal layout

## Active Runtime Systems

- `custodian/game/world/procgen/custodian_contract_map.gd` — contract generation and planet-linked world profile creation, including deterministic map size/room bands and ambient Shrumb trait profile fields
- `custodian/game/world/procgen/proc_gen_tilemap.gd` — runtime procgen world generation, planet world profile application, foliage placement, and decorative ruin prop placement
- `custodian/game/systems/core/systems/ambient_critter_manager.gd` — ambient critter spawning, tint, pacing, scale, speed, naming, and trait metadata linked to world profile
- `custodian/game/systems/core/systems/inventory_manager.gd` — minimal stack-count ledger autoload for cognitive drops and future stackable resources
- `custodian/game/systems/cognitive/cognitive_state_system.gd` — `CognitiveState` autoload tracking Forest Shrumb recollection/instinct/bearing values, decay, dominant state, and v1 modifier getters
- `custodian/game/actors/enemies/ambient_shrumb.tscn` — live ambient Forest Shrumb actor path with shrumb slink animations, cognitive dropper, and no scrap material drops
- `custodian/game/actors/enemies/ambient_shrumb.gd` — ambient Forest Shrumb death hook that invokes the cognitive dropper before inherited enemy cleanup
- `custodian/game/actors/items/cognitive_pickup.tscn` — generic pickup scene for cognitive item drops
- `custodian/game/actors/items/cognitive_pickup.gd` — pickup flow that increments `InventoryManager`, applies `CognitiveState`, animates the 4-frame item sheet, and emits popup/log feedback
- `custodian/game/actors/items/shrumb_dropper.gd` — reusable Forest Shrumb cognitive drop table component
- `custodian/game/ui/hud/ui.gd` — active command terminal and essentials-first HUD/debug visibility logic
- `custodian/game/actors/operator/operator.gd` — operator movement, queued armed/Fists profile selection, ranged fire, block, and light/fast/heavy melee attack runtime logic
- `custodian/game/actors/operator/operator_weapon_definition.gd` — weapon/combat profile resource schema, including intent and movement/combat multipliers
- `custodian/game/actors/operator/unarmed_definition.tres` — Fists/unarmed combat profile used by `toggle_unarmed`
- `custodian/project.godot` — canonical runtime input bindings, including `attack_primary`, `attack_secondary`, `toggle_unarmed`, armed cycling, and `build`
- `custodian/game/actors/operator/animations/animation_state_machine.gd` — deterministic operator animation state transition manager with priorities, elapsed time, and same-state re-entry support
- `custodian/game/actors/operator/animations/states/attack_light_state.gd` — default unmodified melee attack animation state
- `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md` — active combat feel doctrine, including animation-driven attack loop and `attack_light` tuning priority
- `design/02_features/combat_feel/COMBAT_FEEL_UPGRADE.md` — ordered combat feel implementation lane after sprite pipeline cleanup
- `design/features/implementation/UNARMED_TOGGLE.md` — unarmed/Fists selection behavior, state rules, and acceptance tests
- `design/features/implementation/UNARMED_TOGGLE_CODE.md` — implementation notes for the unarmed/Fists profile selection system
- `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB_GAMEPLAY_CORE.md` — active Forest Shrumb cognitive drop runtime implementation notes
- `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB-IMPLEMENTATION_DELTA.md` — duplicate/current Forest Shrumb implementation delta reference used for v1 foundation

## Active Interaction/UI Files

- `custodian/game/actors/defense/turret.gd` — turret interaction prompt reads actual interact binding
- `custodian/game/actors/base/vehicle_base.gd` — vehicle exit prompt reads actual interact binding
- `custodian/game/actors/terminal/command_terminal.gd` — in-world command terminal interaction and activation/deactivation prop animation
- `custodian/docs/TERMINAL_VIEW_LOCAL_MODE.md` — terminal-related runtime doc reference

## Active Asset Pipeline

- `custodian/tools/pipelines/ingest.py` — manifest-driven sprite ingest that writes into live runtime sprite domains and stages generated files through Git by default
- `custodian/tools/pipelines/reload_assets.py` — direct operator curated-resource rebuild entrypoint
- `custodian/tools/pipelines/update_operator_curated_resources.gd` — rebuilds operator runtime `SpriteFrames` from curated/source sheets
- `tools/tiles/extract_wall_parts.py` — offline wall module extractor that reads canonical wall source art, writes per-part PNGs, a packed source atlas, and JSON metadata
- `tools/tiles/compose_wall_variants.py` — offline deterministic wall-run composer that reads generated wall part metadata/atlas and writes composed wall variant sheets
- `tools/tiles/build_procgen_wall_atlas.py` — bridge builder that slices extracted wall modules into fixed `32x32` procgen TileMap cells and semantic coordinate buckets
- `tools/tiles/procgen_wall_semantics.json` — optional curated role override file for generated wall module semantics
- `custodian/content/tiles/walls/source/procgen_wall_modules_source.png` — canonical reviewed source sheet for generated procgen wall modules
- `custodian/content/tiles/walls/source/wall_passages/` — optional `32px`-tall wall passage strips sliced directly into procgen passage/hole buckets
- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json` — stable intermediate metadata for extracted procgen wall source modules
- `custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png` — stable intermediate packed atlas for extracted procgen wall source modules
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png` — generated fixed-grid wall atlas used by procgen TileSet source ID `12`
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.mapping.json` — generated semantic bucket mapping used to populate procgen wall coordinate arrays
- `custodian/assets/tiles/walls/generated/README.md` — regeneration and Godot import notes for generated wall tile assets
- `design/features/implementation/WALL_TILE_PIPELINE.md` — implementation spec for the offline wall tile extraction and composition pipeline
- `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md` — implementation spec for integrating generated wall tiles into the procgen TileMap runtime
- `custodian/content/sprites/_pipeline/README.md` — intake contract, canonical sprite naming, and manifest examples
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md` — project-wide runtime asset layout and canonical sprite filename convention
- `custodian/content/items/shrumb_drops/shrumb_drops.json` — v1 cognitive item definitions for Faint Recollection, Residual Instinct, and Ancient Bearing
- `custodian/content/sprites/items/faint_recollection.png` — animated 4-frame pickup sheet for Faint Recollection
- `custodian/content/sprites/items/faded_instinct.png` — animated 4-frame pickup sheet currently used for `residual_instinct`
- `custodian/content/sprites/items/ancient_bearing.png` — animated 4-frame pickup sheet for Ancient Bearing

## Active Prop Content

- `custodian/content/props/ruins/scenes/ProceduralProp.tscn` — reusable Node2D assembly scene for deterministic visual ruin prop variants
- `custodian/content/props/ruins/scripts/ProceduralProp.gd` — seeded visual variant generation, intensity modes, editor regeneration, palette material application, overlay/rubble placement, and stable collision scene instancing
- `custodian/content/props/ruins/scripts/PropDefinition.gd` — per-prop resource schema for base texture, anchor, palette bounds, overlay/rubble inputs, spawn regions, and optional collision scene
- `custodian/content/props/ruins/scripts/PropVariantLayer.gd` — structured overlay/rubble layer resource with type, spawn chance, spawn rect, alpha range, z-index, and flip rules
- `custodian/content/props/ruins/scripts/PropVariantGenerator.gd` — deterministic helper for deriving seeds from world cells or positions
- `custodian/content/props/ruins/scripts/WeightedPropEntry.gd` — weighted prop spawn entry resource
- `custodian/content/props/ruins/scripts/PropSpawnSet.gd` — weighted set of prop definitions used by scatterers/procgen
- `custodian/content/props/ruins/scripts/PropScatterer.gd` — reusable tile-based deterministic prop scatterer
- `custodian/content/props/ruins/shaders/prop_palette_variation.gdshader` — conservative HSV brightness/saturation/hue adjustment shader for prop sprites
- `custodian/content/props/ruins/data/ruin_prop_spawn_set.tres` — default weighted procgen spawn set for ruin props
- `custodian/content/props/ruins/data/prop_definitions/obelisk.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/rotunda_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/slab_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/README.md` — ruin prop folder layout, padding commands for cropped PNGs, import settings, and pixel-art transform constraints
- `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md` — active implementation spec and runtime ownership note for the ruin prop variant system

## Active Documentation

- `custodian/docs/ai_context/CURRENT_STATE.md` — current implementation state
- `custodian/docs/ai_context/CONTEXT.md` — project primer and working rules
- `custodian/docs/ai_context/FILE_INDEX.md` — this file
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` — reusable task packet template
- `custodian/docs/ai_context/task_packets/` — active and completed task-scoped agent packets
- `custodian/AGENTS.md` — first-stop local operating guide for all work under `custodian/`
- `custodian/docs/ARCHITECTURE.md` — runtime architecture reference
- `custodian/docs/SCENE_HIERARCHY.md` — scene organization reference
- `custodian/docs/GDSCRIPT_STANDARDS.md` — scripting standards
- `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md` — migration and docs-drift cleanup procedure
- `design/` — active Godot feature/system implementation specs
- `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md` — canonical lore, faction, and game-protocol authority
- `design/03_content/PROCEDURAL_LORE_GENERATION.md` — procedural lore payload, inspect, machine-language, and faction mapping target

## Legacy Reference Only

- `python-sim/game/` — legacy simulation
- `python-sim/custodian-terminal/` — legacy terminal UI
- `python-sim/ai/` — historical AI context pack, superseded by `custodian/docs/ai_context/`
- `python-sim/design/archive/` — historical design/archive material
