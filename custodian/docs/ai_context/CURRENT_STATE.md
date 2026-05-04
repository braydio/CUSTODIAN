# CURRENT STATE — CUSTODIAN

Last updated: 2026-05-04

## Runtime Status

- Active runtime: Godot 4.x project in `custodian/`.
- Active main scene: `res://scenes/game.tscn`.
- Authority model: Godot-authoritative runtime with no external gameplay authority.
- Timing model: fixed-step deterministic simulation.
- State root: `GameState` autoload plus world/system nodes under `GameRoot`.
- Active UI shell: in-game command terminal embedded in the Godot HUD.
- Mandatory local agent/developer entrypoint: `custodian/AGENTS.md`.

## Current Implemented Slice

- Contract generation is live and produces a contracted planet plus a linked tactical runtime world.
- Contract planet data now feeds runtime procgen through a shared world profile so the player is actually deployed onto a world shaped by the contracted planet.
- Procgen runtime consumes planet-linked variation for map size, room count bands, layout openness, compound footprint, foliage density, fruit chance, and world tinting. The generated tactical world now uses larger deterministic profile ranges, currently spanning about `144x144` to `240x240` tiles instead of the old `100x100` default.
- Procgen wall presentation is tile-only again: wall visuals come from the active TileSet wall atlas, runtime overlay/endcap passes are disabled, and per-tile runtime collision now matches the visible wall tile footprint.
- Ambient critter behavior also reads the same world profile so non-combat ambience matches the contracted planet.
- The command terminal has a multi-page shell with nav rail, action rail, center content pane, transcript, and command line input.
- The command terminal decursification pass has started: HUD rendering still lives in `game/ui/hud/ui.gd`, while command parsing/dispatch boundary, snapshot aggregation, map preview state/conversion, and planet preview state now have dedicated scripts under `game/ui/terminal/`.
- Terminal pages are widget-backed for `OVERVIEW`, `STATUS`, `SECTORS`, `POWER`, `DEFENSE`, `SENSORS`, `INCIDENTS`, `ARCHIVE`, `RECON`, `CONTRACTS`, `HISTORY`, and `SETTINGS`.
- Terminal usability includes keyboard page/action navigation, transcript link jumps, command echo fallback, auto-following text panes, and a scrollable center content column.
- The in-world command terminal prop plays open/close visual sequences from `res://content/sprites/environment/props/terminal/runtime/body/computer_terminal__body__interaction__activate__omni__4f__48.png`.
- Interaction prompts for turret pickup and vehicle exit now reflect the actual `interact` input binding instead of stale hardcoded keys.
- A first drivable vehicle slice is now wired into the live scene: `PlayerController` is mounted in `game.tscn`, a `LightBuggy` test vehicle is placed near spawn, and the buggy uses cleaned runtime sheets for both hover idle and horizontal movement.
- Ambient shrumbs now participate in runtime world interaction: the buggy can launch or squish passive critters on collision depending on speed, and active enemies can attack nearby shrumbs as fallback targets.
- Ambient Shrumb populations now inherit deterministic world-profile traits, including tint, count/pacing, name prefix, trait tags, size multiplier, and speed multiplier, so ambient critter procgen starts from the same planet settings as map generation.
- Ambient critter north/south slink playback uses cleaned `64x85` strip sources instead of the large `1536x1024` north/south master sheet to avoid frame-origin jitter.
- Ambient shrumb readability was increased: the live shrumb scene uses larger custom slink/knockout sprite scales, and ambient variant scale modifiers no longer shrink variants below readable size.
- Forest Shrumb lore/gameplay implementation has a v1 runtime foundation: `InventoryManager` and `CognitiveState` autoloads, stackable cognitive item definitions, a generic cognitive pickup, a reusable shrumb dropper, placeholder item sprites, and the live `ambient_shrumb.tscn` actor. The former scav droid scene path has been removed from ambient spawning.
- Shrumb cognitive pickups now render item-specific animated 4-frame horizontal sheets from `res://content/sprites/items/` with a lightweight procedural bob/pulse instead of the earlier colored placeholder square. `residual_instinct` currently maps to the authored `faded_instinct.png` sheet.
- A first authored hub-space prototype now exists at `res://scenes/hub_road_of_witnesses_prototype.tscn`, using the Road of Witnesses PNG as a playable background with rough collision and foreground occlusion masks.
- A Godot-native procedural ruin prop variant foundation now exists at `res://content/props/ruins/`: `ProceduralProp.tscn`, `PropDefinition`, `PropVariantLayer`, `PropVariantGenerator`, and a conservative palette shader assemble deterministic visual variants from authored base sprites, overlays, and rubble while keeping collision stable through authored collision scenes.
- Starter ruin prop definitions now exist for `obelisk`, `portal_ring_01`, `rotunda_01`, and `slab_01`, using the available moss/crack overlays and padded rubble/base sprites for immediate editor testing.
- Procgen now has a decorative ruin prop placement slice: `ProcGenTilemap` spawns weighted `ProceduralProp` instances under `NavigationRegion2D/PropLayer` from `ruin_prop_spawn_set.tres`, using floor-cell filtering, wall/player/compound clearance, spacing checks, and deterministic tile seeds.
- Ruin prop art prep is documented in `res://content/props/ruins/README.md`, including transparent ImageMagick padding commands for cropped PNGs and the bottom-center anchor convention needed after padding.
- Sprite ingest is now routed through a manifest-driven intake pipeline at `res://content/sprites/_pipeline/`, which writes into the existing `operator/`, `weapons/`, `enemies/`, `effects/`, `vehicles/`, and `turrets/` runtime domains instead of a separate synthetic asset tree.
- New sprite sheets should use the canonical `<owner>__<layer>__<action_group>__<variant>__<direction>__<frames>f__<frame_size>.png` naming convention, with manifests writing compatibility copies where legacy runtime paths still exist.
- Successful non-dry-run sprite ingests automatically stage generated outputs, existing `.import` metadata, normalized previews, logs, and archived intake files with `git add`; pass `--no-git-add` when deliberately inspecting without staging.
- An offline wall tile extraction/composition pipeline now exists under `tools/tiles/`, using canonical source `custodian/content/tiles/walls/source/procgen_wall_modules_source.png` to generate procgen wall source modules, a packed source atlas, metadata, and composed previews under `custodian/assets/tiles/walls/generated/`.
- Procgen walls now use a generated fixed-grid wall bridge atlas: `tools/tiles/build_procgen_wall_atlas.py` converts extracted wall modules plus optional `32px`-tall passage strips from `custodian/content/tiles/walls/source/wall_passages/` and optional wall-top preprocessing from `custodian/content/tiles/walls/Wall_Tops.png` into `custodian/content/tiles/walls/generated/procgen_wall_tiles_32.png` plus semantic mapping JSON, and `proc_gen_map.tscn` points wall rendering at TileSet source ID `12`. Passage-strip art is exported through `reference_passage_wall_coords` and can appear as deterministic visual variants on ordinary horizontal wall runs; this does not carve walkable openings or change wall collision.
- Operator melee now has a distinct `attack_light` animation state, while active attack intent resolves through the current `OperatorWeaponDefinition` combat profile.
- Unarmed/Fists is now a first-class selectable combat profile at `res://game/actors/operator/unarmed_definition.tres`; it is selected with `F`, excluded from normal weapon cycling, toggles back to the last armed weapon, and owns canonical `unarmed_fast` / `unarmed_heavy` primary/secondary intents.
- Input bindings are intentionally split to avoid combat/build ambiguity: `M1` is `attack_primary`, `Shift+M1` is `attack_secondary`, `Q/E` cycle armed profiles only, `F` toggles Fists, and `B` is build. Runtime prompts should derive from `InputMap` instead of hardcoded keys.
- Operator selection state is simulation-owned (`using_unarmed`, `armed_weapon_index`, `last_armed_weapon_index`, `pending_weapon_selection`) and queued selection only applies from safe idle/walk/sprint states.
- The default HUD is now essentials-only; camera/aim/time/director/supply/button diagnostics are hidden unless `UI.show_debug_hud` is enabled.
- Operator animation state management is now deterministic enough for the combat baseline: the state machine tracks transition sequence and per-state elapsed time, attack states can explicitly re-enter, and attack completion is read from operator combat state instead of sprite playback.
- Operator light damage reaction now enters `hit_recoil` for a short `0.22s` stun window; while Fists are active, it resolves through the `unarmed_light_hitreact` profile animation.
- Unarmed idle is wired for all four cardinal directions: south/down `8f`, east/right `6f`, north/up `10f`, and west/left `6f`. The north inbox source had a noncanonical missing-variant filename but was ingested into canonical runtime output `operator__body__unarmed__idle_01__n__10f__96.png`.
- Unarmed south fast attack is wired as `unarmed_attack_fast_down` from canonical `operator__body__unarmed__fast_01__s__6f__96.png`; this replaces the earlier temporary fallback to the clean melee-light body sheet.
- Unarmed east run is wired as `unarmed_run_right` from canonical `operator__body__unarmed__run_01__e__5f__96.png`; sprint animation selection now resolves profile-specific unarmed run before falling back to default body run.
- Unarmed north run is wired as `unarmed_run_up` from canonical `operator__body__unarmed__run_01__n__6f__96.png`.
- Unarmed south run is wired as `unarmed_run_down` from canonical `operator__body__unarmed__run_01__s__7f__96.png`.
- Unarmed west run is wired as `unarmed_run_left` from canonical `operator__body__unarmed__run_01__w__5f__96.png`.
- Unarmed south fast recovery is wired as `unarmed_attack_fast_recovery_down` from canonical `operator__body__unarmed__fast_recovery_01__s__2f__96.png`.
- Unarmed north fast recovery is wired as `unarmed_attack_fast_recovery_up` plus `unarmed_attack_fast_recovery_fx_up`; east fast recovery was refreshed from a 3-frame source and now plays at `15 FPS` to keep the same short recovery timing.
- Unarmed east and west fast recoveries are wired from canonical 3-frame sheets; west uses dedicated `unarmed_attack_fast_recovery_left` playback instead of mirroring the east recovery.
- Unarmed east walk is wired as `unarmed_walk_right` from canonical `operator__body__unarmed__walk_01__e__5f__96.png`.
- Unarmed south walk is wired as `unarmed_walk` / `unarmed_walk_down` from canonical `operator__body__unarmed__walk_01__s__6f__96.png`; Fists-specific walk selection now runs before the default `walk_down_default` fallback so the placeholder walk cannot override unarmed walking.
- Unarmed north walk is wired as `unarmed_walk_up` from canonical `operator__body__unarmed__walk_01__n__7f__96.png`.
- Unarmed west walk is wired as `unarmed_walk_left` from canonical `operator__body__unarmed__walk_01__w__5f__96.png`.
- Unarmed west stance is wired as `unarmed_stance_left` from canonical `operator__body__unarmed__stance_01__w__6f__96.png`.
- Operator ranged east stance is refreshed as `ranged_2h_stance` from canonical `operator__body__ranged__stance_01__e__12f__96.png`.
- Operator idle facing now preserves the last movement direction after stopping; mouse motion or keyboard aim updates the visual idle facing explicitly, while attacks still resolve from combat aim.
- Unarmed heavy attacks are wired for all four cardinal directions: east/right body+FX, west/left body+FX, north/up body+FX, and south/down body+FX. North uses canonical 8-frame sheets at `11.5 FPS`; east, west, and south use canonical 7-frame sheets at `10 FPS`.
- Unarmed death is wired as `unarmed_death` from canonical `operator__body__unarmed__death_01__omni__6f__96.png`; the operator death handler uses it only while Fists are active and falls back to generic `death` otherwise.
- `AnimationResolver` now resolves authored `_left` clips before mirrored right fallbacks when facing west, and operator playback disables horizontal flip for authored-left melee animations.
- Sprite runtime directories should retain only the currently mapped sheet for a given owner/layer/action/variant/direction once the replacement has been ingested, imported, and verified; `_pipeline/archive/` keeps the older source/intake history.
- Melee target readability now prefers enemies inside the current melee/Fists strike range and facing arc, and the target ring switches to a thicker green pulse when the selected enemy is actually hittable by the current preview strike profile.
- Current `attack_light` starting tune uses frame 4 as the only active hit frame with `0.46s` duration, `0.34s` cancel start, `16` damage, `68px` range, `88deg` arc, `0.035s` light hit stop, and `1.4` camera shake.
- Melee impact sparks resolve their contact point before enemy knockback and set world position after parenting, so hit feedback should land at the struck contact point instead of drifting with post-hit movement or parent transforms.
- Projectile impact sparks now follow the same rule: bullets, tracers, energy shots, and missiles snapshot the contact point before damage/knockback and assign FX world position after parenting.
- Combat feel direction is locked around `INPUT -> ATTACK STATE -> FRAME WINDOW -> ARC/RANGE HIT RESOLUTION -> RECOVERY -> CONTROL RETURN`; `attack_light` is the next tuning baseline after sprite pipeline loose ends are closed.

## Active Agent Workflow

- Agent task packets are now the required planning/handoff artifact for non-trivial implementation, review, migration, validation, asset workflow, and multi-file docs work.
- Task packet template: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Active packet directory: `custodian/docs/ai_context/task_packets/`.
- Validation recipes now live at `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Reusable prompt templates now live under `custodian/docs/ai_context/prompts/`.
- Agent workflow automation candidates are prioritized in `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`.
- First workflow packet: `custodian/docs/ai_context/task_packets/VALIDATION_RECIPES.md`, covering validation recipes and prompt-template cleanup.

## Current Runtime Focus

- Godot-native contract loop, procgen runtime world, and command terminal are active implementation areas.
- Forest Shrumb v1 is now wired into ambient spawning through `AmbientCritterManager`; next work is deciding whether cognitive values should surface in HUD beyond pickup popups/logs.
- Immediate task focus: validate Fists selection/combat in play, then move melee timing into explicit attack profile data.
- Terminal page coverage is largely complete; remaining work is richer live data, tighter layout polish, and code modularization.
- Planet/runtime coupling is active and should be preserved when adjusting procgen or contract generation.
- Procgen runtime handoff wiring now explicitly snaps the world camera to the operator spawn, rebinds navigation to promoted procgen tilemaps, and treats procgen bounds as the only camera clamp authority.
- Operator mouse aim now resolves through the active world camera path first, reducing procgen handoff desync risk.
- Procgen streaming now batches navigation rebuilds around reveal completion instead of rebuilding navigation every reveal frame during world bring-up.
- Vehicle enter/exit prompt authority now routes through `PlayerController` first so the HUD can surface vehicle interaction prompts without depending on the operator node alone.

## Legacy Scope

- `python-sim/game/` and `python-sim/custodian-terminal/` remain preserved legacy reference only.
- Legacy Python terminal contracts are not runtime authority.
- Legacy AI tracker files under `python-sim/ai/` are historical reference, not the active update target.

## Active Gaps

- Some terminal pages still use placeholder or lightly-derived summaries instead of full live runtime controls/data.
- Forest Shrumb cognitive modifiers are exposed as getters only; player movement, combat feel, enemy accuracy/tracking, instinct actions, and full inventory UI are intentionally not integrated in v1.
- Terminal page rendering still lives largely inside `custodian/game/ui/hud/ui.gd`; command routing, snapshot aggregation, and preview boundaries have been split, but page renderers/theme resources still need follow-up extraction.
- The project still exits headless validation with existing object/resource leak warnings that have not yet been cleaned up.
- Broader infrastructure depth, save/load, and full long-horizon base systems are still incomplete relative to full doctrine scope.
- The remaining procgen handoff gap is live runtime verification: camera bounds, cursor aim, reachable anchors, and enemy navigation still need an end-to-end boot test in Godot.
- Vehicle content is still art-incomplete: the hover buggy idle and horizontal movement loops are runtime-ready, while firing, damage, and destruction animations still need final source assets.
- Additional ruin prop definitions and production chip/dirt/vine/highlight overlays still need to be authored under `custodian/content/props/ruins/data/prop_definitions/`, `extracted/`, and `overlays/`; the first moss/crack-driven test definitions and procgen placement are available.
- The sprite pipeline only has one automated post-process hook today: operator curated outputs can rebuild live `SpriteFrames`, while most other runtime consumers still rely on direct path updates plus Godot import.
- Melee combat still needs profile-data consolidation: light/fast/heavy timing, active frames, movement lock, movement resume, recovery, range, arc, damage, knockback, hit stop, and camera impulse are not yet centralized.
- Unarmed runtime body animation slices are still art-incomplete. Missing production sheets should be supplied under `custodian/content/sprites/_pipeline/inbox/` using canonical names such as `operator__body__unarmed__idle_01__s__?f__96.png`, `operator__body__unarmed__walk_01__s__?f__96.png`, `operator__body__unarmed__fast_01__s__?f__96.png`, and `operator__body__unarmed__heavy_01__s__?f__96.png`.

## Documentation Status

- Active AI context directory: `custodian/docs/ai_context/`.
- Mandatory local routing primer: `custodian/AGENTS.md`.
- Agent task packet template: `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Agent task packet directory: `custodian/docs/ai_context/task_packets/`.
- Validation recipes: `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Reusable prompt templates: `custodian/docs/ai_context/prompts/`.
- Agent automation backlog: `custodian/docs/ai_context/AGENT_AUTOMATION_BACKLOG.md`.
- Active runtime docs: `custodian/docs/*`.
- Godot implementation specs: `design/`.
- Locked doctrine: `python-sim/design/MASTER_DESIGN_DOCTRINE.md`.
- Use `python-sim/design/DOC_STATUS.md` to resolve active-vs-legacy conflicts in older docs.
- Active migration/drift workflow: `custodian/docs/AGENT_MIGRATION_PLAYBOOK.md`.
