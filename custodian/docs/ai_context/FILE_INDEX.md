# FILE INDEX — CUSTODIAN

Last updated: 2026-05-15

## Local Entry And Workflow

- `custodian/AGENTS.md` — mandatory local primer for routing, context retrieval, docs-drift review, and migration execution
- `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md` — detailed migration and drift-remediation workflow
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` — template for non-trivial agent implementation, review, migration, validation, asset workflow, and multi-file docs work
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` — prioritized automation/script backlog for agent workflow validation and safety checks
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — canonical validation command selection guide for docs, Godot, asset pipeline, tile pipeline, and review work
- `custodian/docs/ai_context/prompts/README.md` — reusable agent prompt index and usage rules
- `custodian/docs/ai_context/task_packets/README.md` — task packet workflow and active packet index
- `REQUIRED_ASSETS.md` — project-level tracker for missing or partial production art, audio, animation, and content assets that implementation work depends on
- `custodian/docs/ai_context/task_packets/AGENT_WORKFLOW_AUTOMATION.md` — completed packet for task-packet next steps, ownership rules, and automation backlog
- `custodian/docs/ai_context/task_packets/VALIDATION_RECIPES.md` — completed packet for canonical validation recipes and prompt-template cleanup
- `custodian/docs/ai_context/task_packets/COMPOUND_ROOM_ASSEMBLY_CONTRACT.md` — completed packet for deterministic compound room graph, loader, and layout assembler contract hardening
- `custodian/docs/ai_context/task_packets/COMPOUND_ROOM_GRAPH_WALK_LAYOUT.md` — completed packet for the first graph-walk, door-aligned compound room layout pass
- `custodian/docs/ai_context/task_packets/PORTAL_COLLISION_DEBUG_TUNING.md` — completed packet for visualizing portal prop collision and correcting portal-ring side blocker positions
- `custodian/docs/ai_context/task_packets/ENEMY_VARIANT_SYSTEM.md` — completed packet for the first procedural wolf enemy variant runtime slice
- `custodian/docs/ai_context/task_packets/INDOOR_OUTDOOR_PROCGEN_REGIONS.md` — completed packet for the first region-aware indoor/outdoor procgen slice
- `custodian/docs/ai_context/task_packets/PROCGEN_WALL_PASSAGE_VISIBILITY.md` — completed packet for generated wall passage visibility on normal horizontal procgen wall runs
- `custodian/docs/ai_context/task_packets/PROCGEN_WALL_TOP_SOURCE_PREPROCESSING.md` — completed packet for wall-top preprocessing support in the atlas builder
- `custodian/docs/ai_context/task_packets/ASH_BELL_BELL_KNEELER.md` — packet for the first authored Ash-Bell / Bell-Kneeler event implementation slice and deferred production asset/procgen integration work

## Active Runtime Entry

- `custodian/project.godot` — Godot project config and input map
- `custodian/scenes/game.tscn` — active game scene and terminal layout; currently includes temporary `AshBellDevSpawner` for live Bell-Kneeler encounter review

## Active Runtime Systems

- `custodian/game/world/procgen/custodian_contract_map.gd` — contract generation and planet-linked world profile creation, including deterministic map size/room bands and ambient Shrumb trait profile fields
- `custodian/game/world/procgen/proc_gen_tilemap.gd` — runtime procgen world generation, planet world profile application, constructed interior region carving, semantic intent-zone metadata, intensity queries, foliage placement, decorative ruin prop placement, and paired portal-ring teleport endpoint wiring with portal-specific safe placement filtering
- `custodian/game/world/procgen/portal_teleporter.gd` — Area2D trigger component used by procgen portal-ring props to teleport the player to their linked endpoint with a physics-frame cooldown, one runtime-built `PortalStateSprite` for idle/activation/arrival playback, delayed destination arrival playback, and a 2.5D stair/platform impostor for top-only portal access plus mirrored north-side dual approach when enabled
- `custodian/game/world/compound/rooms/room_graph.gd` — deterministic compound room graph loader/validator with room count clamps, sorted type lookup, seeded template selection, and directional connection-rule checks
- `custodian/game/world/compound/rooms/room_loader.gd` — deterministic `.tmj` Tiled room-template loader with normalized door metadata, marker/stair extraction, template duplication, and door compatibility checks
- `custodian/game/world/compound/rooms/layout_assembler.gd` — deterministic compound room layout assembler with stable room IDs, graph-walk door-aligned placement, fixed-grid fallback, graph-rule-enforced compatible door connections, resolved endpoint tiles, intensity estimates, actual tile bounds, and placed-room state
- `custodian/game/world/compound/rooms/graphs/default_compound.json` — default compound room graph referencing command post, hangar, corridor, storage, and landing pad template names
- `custodian/game/world/compound/rooms/templates/` — Tiled `.tmj` compound room template directory; currently only `command_post.tmj` exists, with additional templates tracked in `REQUIRED_ASSETS.md`
- `custodian/game/world/events/ash_bell/bell_kneeler_site.tscn` — placeholder authored Ash-Bell special-room scene with Bell-Kneeler NPC, bell-frame/fountain/thread/clapper placeholders, triggers, and debug dialogue labels
- `custodian/game/world/events/ash_bell/bell_kneeler_site.gd` — Ash-Bell encounter controller for silence pressure, thread/fountain state, dialogue/item/knowledge signals, apparition/procession placeholders, and completion state
- `custodian/game/world/events/ash_bell/ash_bell_event_state.gd` — local Resource state model for Ash-Bell silence pressure, thread tension, fountain state, resolution, and knowledge flags
- `custodian/game/world/events/ash_bell/bell_kneeler_npc.gd` — Bell-Kneeler NPC controller with kneeling, hostile, dissolve, clapper swing, and thread-pull hooks
- `custodian/game/world/events/ash_bell/white_thread_hazard.gd` — soft thread hazard Area2D that increments thread tension and optionally applies player slow hooks
- `custodian/game/world/events/ash_bell/ash_bell_interactable.gd` — operator interaction bridge for kneeler, thread, clapper, fountain, and silence-ringing actions
- `custodian/game/world/events/ash_bell/ash_bell_trigger.gd` — Area2D trigger bridge for intro, fountain occupancy, exit, and procession-lane pressure
- `custodian/game/world/events/ash_bell/ash_bell_dev_spawner.gd` — temporary live-review spawner mounted in `scenes/game.tscn` that places the Ash-Bell site near the operator after contract world setup
- `custodian/game/systems/core/systems/ambient_critter_manager.gd` — ambient critter spawning, tint, pacing, scale, speed, naming, and trait metadata linked to world profile
- `custodian/game/systems/core/systems/inventory_manager.gd` — minimal stack-count ledger autoload for cognitive drops and future stackable resources
- `custodian/game/systems/cognitive/cognitive_state_system.gd` — `CognitiveState` autoload tracking Forest Shrumb recollection/instinct/bearing values, decay, dominant state, and v1 modifier getters
- `custodian/autoload/resource_ledger.gd` — fabrication resource accounting autoload for CUSTODIAN-flavored resource totals and payment checks
- `custodian/autoload/build_inventory.gd` — completed build-token inventory autoload used by fabrication outputs before placement exists
- `custodian/autoload/fab_pipeline.gd` — recipe loading, resource payment, queued fabrication jobs, and output completion autoload
- `custodian/game/fabrication/fab_job.gd` — lightweight queued fabrication job state with elapsed/duration/progress helpers
- `custodian/game/fabrication/fab_recipe_database.gd` — reusable JSON recipe database node for fabrication UI/world bridges
- `custodian/game/fabrication/fabricator_terminal.gd` — Area2D bridge for starting allowed fabrication recipes through `FabPipeline`
- `custodian/game/resources/resource_node.gd` — harvestable interactable resource node that depletes through operator interaction and deposits primary/secondary yields into `ResourceLedger`
- `custodian/game/resources/resource_node.tscn` — placeholder visual/collision scene for V1 hand-placed resource nodes
- `custodian/content/resources/resource_defs.json` — metadata for tier-0 CUSTODIAN-flavored fabrication resources
- `custodian/content/fabrication/fab_recipes.json` — starter fabrication recipes that output build tokens or unlocks
- `custodian/game/actors/enemies/ambient_shrumb.tscn` — live ambient Forest Shrumb actor path with shrumb slink animations, cognitive dropper, and no scrap material drops
- `custodian/game/actors/enemies/ambient_shrumb.gd` — ambient Forest Shrumb death hook that invokes the cognitive dropper before inherited enemy cleanup
- `custodian/game/actors/enemies/enemy.gd` — shared active enemy actor, now including `apply_variant(profile)` support for procedural wolf profiles and wolf sheet playback through `AnimatedSprite2D`
- `custodian/game/enemies/procgen/enemy_variant_profile.gd` — data-only procedural enemy profile resource generated from seed, biome, threat, family, tier, and affixes
- `custodian/game/enemies/procgen/enemy_variant_factory.gd` — deterministic procedural wolf profile composer with separate RNG streams, family/tier/affix rolls, palettes, safety clamps, and DPS normalization
- `custodian/game/enemies/procgen/wolf_animation_library.gd` — runtime `SpriteFrames` builder that slices the current wolf PNG sheets into idle/run/bite/death/howl animations
- `custodian/game/enemies/procgen/enemy_palette_tint.gdshader` — palette/glow/contrast shader used by procedural enemy visuals
- `custodian/game/systems/core/systems/enemy_factory.gd` — wave composition factory with deterministic local composition rolls and `"wolf"` type support
- `custodian/game/systems/core/systems/wave_manager.gd` — wave spawning system that applies procedural wolf variant profiles to spawned enemies when `"wolf"` entries are selected
- `custodian/game/actors/items/cognitive_pickup.tscn` — generic pickup scene for cognitive item drops
- `custodian/game/actors/items/cognitive_pickup.gd` — pickup flow that increments `InventoryManager`, applies `CognitiveState`, animates the 4-frame item sheet, and emits popup/log feedback
- `custodian/game/actors/items/shrumb_dropper.gd` — reusable Forest Shrumb cognitive drop table component
- `custodian/game/ui/hud/ui.gd` — active command terminal HUD integration, fabrication page rendering, page orchestration, and essentials-first HUD/debug visibility logic
- `custodian/game/ui/minimap/minimap_panel.tscn` — custom HUD tactical minimap panel instanced under `UI`
- `custodian/game/ui/minimap/minimap_controller.gd` — discovers runtime procgen/player/enemy/objective nodes and feeds minimap data to the view
- `custodian/game/ui/minimap/minimap_view.gd` — data-driven minimap renderer that caches procgen floor/wall terrain and draws tactical pips
- `custodian/game/ui/inventory/inventory_ui.tscn` — hidden HUD inventory overlay instanced under `UI` and toggled with `I`
- `custodian/game/ui/inventory/inventory_ui.gd` — inventory overlay open/close, sample item loading, and slot rendering
- `custodian/game/ui/terminal/terminal_command_router.gd` — command parsing, validation, refresh policy, and dispatch boundary for the HUD terminal
- `custodian/game/ui/terminal/terminal_snapshot.gd` — read-only terminal snapshot aggregation from runtime groups/autoloads/systems
- `custodian/game/ui/terminal/terminal_map_preview.gd` — terminal minimap preview state and click-to-world conversion boundary
- `custodian/game/ui/terminal/terminal_planet_preview.gd` — terminal globe viewport, rotation, zoom, and preview input handling
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
- `design/features/implementation/MINIMAP_SYSTEM.md` — custom data-driven tactical minimap implementation spec
- `design/features/implementation/MINIMAP_SYSTEM_CODE.md` — minimap runtime code plan and integration notes
- `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB_GAMEPLAY_CORE.md` — active Forest Shrumb cognitive drop runtime implementation notes
- `design/THE_TRAGEDY_OF_THE_FOREST_SHRUMB-IMPLEMENTATION_DELTA.md` — duplicate/current Forest Shrumb implementation delta reference used for v1 foundation

## Active Interaction/UI Files

- `custodian/game/actors/defense/turret.gd` — turret interaction prompt reads actual interact binding
- `custodian/game/actors/base/vehicle_base.gd` — vehicle exit prompt reads actual interact binding
- `custodian/game/actors/terminal/command_terminal.gd` — in-world `command_terminal` prop interaction and activation/deactivation animation, with fallback compatibility to the older `computer_terminal` sheets and the authored `builder_terminal` pickup/deploy sheet
- `custodian/game/systems/core/systems/terminal_deployment.gd` — deployable terminal pickup/redeploy runtime for the in-world command terminal prop
- `custodian/docs/TERMINAL_VIEW_LOCAL_MODE.md` — terminal-related runtime doc reference

## Active Asset Pipeline

- `custodian/tools/pipelines/ingest.py` — manifest-driven sprite ingest that writes into live runtime sprite domains and stages generated files through Git by default
- `custodian/tools/pipelines/generate_inbox_manifests.py` — deterministic inbox manifest generator that infers JSON sidecars from canonical filenames, image dimensions, flat item filenames, and harvesting-node filenames, then runs the ingest pipeline
- `custodian/tools/pipelines/reload_assets.py` — direct operator curated-resource rebuild entrypoint
- `custodian/tools/pipelines/update_operator_curated_resources.gd` — rebuilds operator runtime `SpriteFrames` from curated/source sheets
- `custodian/tools/art/build_reference_samplesheet.py` — Pillow-based utility that samples active runtime-facing tiles, walls, floors, ruin props, and environment prop sheets into a labeled design-reference PNG
- `custodian/content/reference/active_art_samplesheet.png` — generated design-reference sheet containing deterministic samples from active art directories; regenerate with `python3 custodian/tools/art/build_reference_samplesheet.py`
- `tools/tiles/extract_wall_parts.py` — offline wall module extractor that reads canonical wall source art, writes per-part PNGs, a packed source atlas, and JSON metadata
- `tools/tiles/compose_wall_variants.py` — offline deterministic wall-run composer that reads generated wall part metadata/atlas and writes composed wall variant sheets
- `tools/tiles/build_procgen_wall_atlas.py` — bridge builder that slices extracted wall modules into fixed `32x32` procgen TileMap cells and semantic coordinate buckets
- `custodian/tools/tiles/register_interior_floor_tiles.py` — convention-based registrar for `content/tiles/interiors/runtime/floor_*_32.png`, non-corner `wall_*_32.png`, and `wall_*corner*_32.png` TileSet sources plus procgen source arrays
- `tools/tiles/procgen_wall_semantics.json` — optional curated role override file for generated wall module semantics
- `custodian/content/tiles/walls/source/procgen_wall_modules_source.png` — canonical reviewed source sheet for generated procgen wall modules
- `custodian/content/tiles/walls/source/wall_passages/` — optional `32px`-tall wall passage strips sliced directly into procgen passage/hole buckets
- `custodian/content/tiles/walls/Wall_Tops.png` — wall-top source sheet that is alpha-split by the atlas builder with `--top-source`
- `custodian/content/tiles/tilesets/procgen_world_tileset.tres` — canonical active world/procgen TileSet used by procgen and test-map TileMapLayer scenes
- `custodian/content/tiles/interiors/runtime/` — runtime-ready `32x32` constructed-interior floor and military wall tiles registered into procgen source lists by naming convention
- `custodian/content/tiles/interiors/source/` — oversized/reference interior tile source art preserved for slicing or replacement
- `custodian/content/tiles/interiors/README.md` — interior tile folder layout, runtime/source split, and remaining art needs
- `custodian/assets/tiles/walls/generated/procgen_wall_source_parts.json` — stable intermediate metadata for extracted procgen wall source modules
- `custodian/assets/tiles/walls/generated/procgen_wall_source_atlas.png` — stable intermediate packed atlas for extracted procgen wall source modules
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png` — generated fixed-grid wall atlas used by procgen TileSet source ID `12`
- `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.mapping.json` — generated semantic bucket mapping used to populate procgen wall coordinate arrays
- `custodian/assets/tiles/walls/generated/README.md` — regeneration and Godot import notes for generated wall tile assets
- `design/features/implementation/WALL_TILE_PIPELINE.md` — implementation spec for the offline wall tile extraction and composition pipeline
- `design/features/implementation/PROCGEN_WALL_TILE_BRIDGE.md` — implementation spec for integrating generated wall tiles into the procgen TileMap runtime
- `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md` — first runtime slice for single-map indoor/outdoor region-aware procgen
- `custodian/content/sprites/_pipeline/README.md` — intake contract, canonical sprite naming, and manifest examples
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md` — project-wide runtime asset layout and canonical sprite filename convention
- `custodian/content/sprites/environment/props/portal_ring/runtime/fx/` — canonical portal-ring prop FX runtime strips used by `PortalTeleporter` for idle, activation, and arrival playback
- `custodian/content/sprites/effects/runtime/portal_ring/` — legacy compatibility copies of portal-ring teleport FX strips
- `custodian/content/items/shrumb_drops/shrumb_drops.json` — v1 cognitive item definitions for Faint Recollection, Residual Instinct, and Ancient Bearing
- `custodian/content/dialogue/ash_bell/bell_kneeler_dialogue.json` — Ash-Bell Bell-Kneeler dialogue data using Ninth Bell, Dry Fountain, white thread, black banners, and Unarrived Saint motifs without explicit alternate-continuity language
- `custodian/content/items/lore/ash_bell_items.json` — lore item definitions for Bell-Clapper Without a Bell, White Thread Knot, and Prayer to the Unarrived Saint
- `custodian/content/procgen/special_rooms/ash_bell_bell_kneeler_room.json` — metadata for future rare procgen insertion of the authored Ash-Bell Bell-Kneeler site
- `custodian/content/sprites/items/faint_recollection.png` — animated 4-frame pickup sheet for Faint Recollection
- `custodian/content/sprites/items/faded_instinct.png` — animated 4-frame pickup sheet currently used for `residual_instinct`
- `custodian/content/sprites/items/ancient_bearing.png` — animated 4-frame pickup sheet for Ancient Bearing
- `custodian/content/ui/terminal/README.md` — intended terminal PNG asset paths for frames, overlays, icons, pips, and button skins

## Active Prop Content

- `custodian/content/props/ruins/scenes/ProceduralProp.tscn` — reusable Node2D assembly scene for deterministic visual ruin prop variants
- `custodian/content/props/ruins/scripts/ProceduralProp.gd` — seeded visual variant generation, intensity modes, editor regeneration, palette material application, overlay/rubble placement, optional inline collision footprints, occlusion bounds, and player-relative depth sorting
- `custodian/content/props/ruins/scripts/PropDefinition.gd` — per-prop resource schema for base texture, anchor, palette bounds, overlay/rubble inputs, spawn regions, optional collision scene, optional collision footprint fields, optional occlusion bounds, and optional depth-sort settings
- `custodian/content/props/ruins/scripts/PropVariantLayer.gd` — structured overlay/rubble layer resource with type, spawn chance, spawn rect, alpha range, z-index, and flip rules
- `custodian/content/props/ruins/scripts/PropVariantGenerator.gd` — deterministic helper for deriving seeds from world cells or positions
- `custodian/content/props/ruins/scripts/WeightedPropEntry.gd` — weighted prop spawn entry resource
- `custodian/content/props/ruins/scripts/PropSpawnSet.gd` — weighted set of prop definitions used by scatterers/procgen
- `custodian/content/props/ruins/scripts/PropScatterer.gd` — reusable tile-based deterministic prop scatterer that records each spawned prop source tile for downstream systems such as portal pairing
- `custodian/content/props/ruins/shaders/prop_palette_variation.gdshader` — conservative HSV brightness/saturation/hue adjustment shader for prop sprites
- `custodian/content/props/ruins/data/ruin_prop_spawn_set.tres` — default weighted procgen spawn set for ruin props
- `custodian/content/props/ruins/data/prop_definitions/obelisk.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres` — starter test definition using available moss/crack overlays and rubble, including the raised platform impostor tuning, visual-frame `(80,60)` platform horizon/trigger anchor, mirrored north-side approach flag, and static-base hiding flag used by the animated portal state sprite
- `custodian/content/props/ruins/scenes/portal_ring_collision.tscn` — authored side-block collision scene used by `portal_ring_01`
- `custodian/content/props/ruins/data/prop_definitions/rotunda_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/data/prop_definitions/slab_01.tres` — starter test definition using available moss/crack overlays and rubble
- `custodian/content/props/ruins/README.md` — ruin prop folder layout, padding commands for cropped PNGs, import settings, and pixel-art transform constraints
- `design/02_features/props/PROCEDURAL_PROP_VARIANT_SYSTEM.md` — active implementation spec and runtime ownership note for the ruin prop variant system
- `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md` — merged system design for resource collection, ledger, and fabrication pipeline; Stage 1 ready for implementation
- `design/RESOURCE_FAB_PIPELINE_ADD.md` — build-token-first fabrication pipeline addendum used to scope the first runtime implementation
- `design/features/implementation/FAB_PIPELINE_SYSTEM.md` — implementation note for the first resource ledger, build inventory, and queued fab pipeline slice
- `design/04_research/resource_fabrication/RESOURCE_FABRICATION_PIPELINE.md` — source brainstorm: implementation-level pseudocode and script contracts
- `design/04_research/resource_fabrication/RESOURCE_COLLECTION_PLAN.md` — source brainstorm: strategic staging and spatial design for resource zones
- `design/04_research/resource_fabrication/RESOURCE_STARTER_TIER.md` — source brainstorm: resource identity, lore, and CUSTODIAN flavor framing

## Active Documentation

- `custodian/docs/ai_context/CURRENT_STATE.md` — current implementation state
- `custodian/docs/ai_context/CONTEXT.md` — project primer and working rules
- `custodian/docs/ai_context/FILE_INDEX.md` — this file
- `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` — reusable task packet template
- `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md` — recommended automation scripts and implementation order
- `custodian/docs/ai_context/VALIDATION_RECIPES.md` — validation command recipes and selection rules
- `custodian/docs/ai_context/prompts/` — reusable prompt templates for common agent tasks
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
