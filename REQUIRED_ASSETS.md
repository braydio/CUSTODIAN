# REQUIRED ASSETS

Canonical tracker for production art, audio, animation, and content assets that runtime or design work has identified but not fully supplied.

> ## Agent Instructions — Asset Lifecycle Automation
>
> **When you create an asset** that matches a `needed` entry in this file:
> - **Automatically remove that entry** — no user approval needed.
> - The asset is now done; it does not belong on the required list.
>
> **When you discover a missing production asset** during implementation:
> - **Automatically add it** to the appropriate section with status `needed`.
> - Use exact target paths when known.
> - **Inform the user** what was added and why.
>
> **When you change an asset's status** (e.g., `needed` → `partial` or `done`), update the entry accordingly.
>
> ### Canonical Location
>
> This root file is the sole canonical required-assets tracker. `design/00_meta/REQUIRED_ASSETS.md` is a deprecated
> forwarding notice only; never copy tracker entries there.

## Practice

## Sundered Keep

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Sundered Keep reveal fog veil sheet | `custodian/content/sprites/vista/sundered_keep/reveal/sundered_keep_reveal_fog_veil_01.png` and `custodian/content/sprites/vista/sundered_keep/source/sundered_keep_reveal_fog_veil_01.aseprite` | Replace the runtime near-fog peel scaffold with a center-opening authored veil. | 512×256 frames, 8 frames, 4096×256 transparent sheet. |
| needed | Sundered Keep reveal fog ribbons sheet | `custodian/content/sprites/vista/sundered_keep/reveal/sundered_keep_reveal_fog_ribbons_01.png` and `custodian/content/sprites/vista/sundered_keep/source/sundered_keep_reveal_fog_ribbons_01.aseprite` | Add soft trailing breakup behind the fast near-fog peel. | 384×192 frames, 6 frames, 2304×192 transparent sheet. |
| needed | Sundered Keep reveal moonlight sweep sheet | `custodian/content/sprites/vista/sundered_keep/reveal/sundered_keep_reveal_light_sweep_01.png` and `custodian/content/sprites/vista/sundered_keep/source/sundered_keep_reveal_light_sweep_01.aseprite` | Replace the procedural radial light cue with an authored cool facade-edge sweep. | 640×360 frames, 5 frames, 3200×360 transparent sheet. |
| needed | Sundered Keep far silhouette plate | `custodian/content/sprites/vista/sundered_keep/background/sundered_keep_far_silhouette_01.png` and `custodian/content/sprites/vista/sundered_keep/source/sundered_keep_far_silhouette_01.aseprite` | Replace reused horizon-matte distance scaffolds with a dedicated large keep mass. | Single 2048×1024 transparent/background plate. |
| needed | Sundered Keep labyrinth wall kit | `custodian/content/tiles/sundered_keep/walls/labyrinth_keep/{wall_straight_s_01,wall_pier_01,wall_corner_01,wall_broken_end_01}.png` plus `.game32.json` sidecars | Replace `PLACEHOLDER_sundered_keep_labyrinth_wall_*` sprites with production walls that make courtyard partitions, gatehouse side blockers, west service-yard boundaries, and keep maze turns read as actual architecture. | The registered cheat-sheet relayout placeholders are `PLACEHOLDER_sundered_keep_labyrinth_wall_straight_s`, `_wall_pier`, and `_wall_corner`; all remain production-art TODOs. |
| needed | Sundered Keep void/cliff boundary kit | `custodian/content/tiles/sundered_keep/walls/labyrinth_keep/{void_edge_w_01,void_edge_e_01,collapsed_sea_cut_01,cliff_guard_rail_01}.png` plus `.game32.json` sidecars | Replace `PLACEHOLDER_sundered_keep_labyrinth_void_edge.png` where ocean/void collision boundaries need to read as cliffs, broken masonry, or collapsed keep edges instead of invisible walls. | The registered `_void_edge` placeholder remains in the cheat-sheet relayout around lower-route boundaries and the Great Hall collapsed sea cut. |
| needed | Sundered Keep wall dressing overlays | `custodian/content/tiles/sundered_keep/walls/labyrinth_keep/overlays/{moss_drip_*.png,crack_*.png,iron_sconce_*.png,white_thread_marker_*.png}` | Add variation and landmarks to the labyrinth walls so the keep is readable as a designed place instead of repeated wall tiles. | Recommended before replacing the placeholder walls broadly; not required for collision semantics. |
| needed | Sundered Keep Custodian sidearm field-retention locker | `custodian/content/runtime/sundered_keep/props/prop_storage/prop_custodian_sidearm_locker_01.png` plus `.game32.json` sidecar | Replace the temporary wet-crate stand-in for the P-9 Field Sidearm unlock with a sealed Custodian service-imprint locker/chest. | Runtime uses `prop_crate_stack_wet_01` as a temporary visual at `SidearmLockerInteraction`. |

## Inventory UI

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | CUSTODIAN inventory frame and panel kit | `custodian/content/ui/inventory/runtime/panels/{inventory_frame_9slice,inventory_panel_deep_9slice}.png` plus `.game32.json` sidecars | Replace Black Reliquary fallback panels with bespoke professional inventory frame art. | Runtime resolves these paths automatically through `inventory_ui_asset_manifest.json`. |
| needed | CUSTODIAN inventory slot kit | `custodian/content/ui/inventory/runtime/slots/{inventory_slot_empty,inventory_slot_hover,inventory_slot_selected}.png` plus `.game32.json` sidecars | Provide production empty/hover/selected carried-object slot visuals. | Current UI falls back to legacy inventory slot PNGs. |
| needed | CUSTODIAN inventory ornaments | `custodian/content/ui/inventory/runtime/ornaments/inventory_ornament_{nw,ne,sw,se}.png` | Replace fallback Black Reliquary corner ornaments with inventory-specific framing accents. | Text remains live in Godot labels. |
| needed | CUSTODIAN item icon suite | `custodian/content/ui/inventory/runtime/icons/icon_{item_id}.png` and `icon_unknown.png` | Provide production icons for carried items such as Shrumb drops, Sundered Gate Key, Ash-Bell relics, and future ledger objects. | Any matching `icon_{item_id}.png` is picked up automatically by the runtime catalog. |

## Home Beginning / Custodian Field Terminal

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Custodian Field Terminal production prop suite | `custodian/content/sprites/environment/props/field_terminal/runtime/body/field_terminal__body__interaction__{idle,activate,damaged_active}__omni__?f__96.png` | Replace the Home beginning placeholder command-terminal compatibility art with the half-buried armored Field Terminal / Archive Anchor described by the first objective. | `home_custodian_begin.tscn` currently uses existing command terminal fallback art through `FieldTerminalInteractable`. |
| needed | Custodian-band signal visual FX | `custodian/content/sprites/effects/runtime/custodian_frequency/custodian_band_pulse_01__omni__?f__?.png`, `custodian/content/sprites/effects/runtime/custodian_frequency/provenance_static_01__omni__?f__?.png` | Make the opening signal gradient, pulse, and provenance distortion readable without relying only on HUD text. | V1 uses a small procedural `Line2D` signal needle and HUD status fragments. |
| needed | Custodian-band signal audio cues | `custodian/content/audio/sfx/custodian_frequency/signal_pulse_*.wav`, `custodian/content/audio/sfx/custodian_frequency/provenance_static_*.wav`, `custodian/content/audio/ambience/home_beginning_signal_bed_*.wav` | Provide directional/static/near-terminal audio feedback for tracing the degraded provenance carrier. | No audio hooks are wired yet; assets are needed before the signal-tracking pass can be made diegetic. |
| needed | Field Terminal chamber dressing props | `custodian/content/props/home/field_terminal/{burned_generator_*.png,dead_maintenance_drone_*.png,field_tag_offerings_*.png,white_thread_tie_*.png,floor_map_mismatch_*.png}` | Communicate that the terminal was found before, misunderstood, and treated as an Oath Box / Iron Witness. | V1 uses the Road of Witnesses map without bespoke terminal-chamber environmental storytelling props. |

## Ash-Bell / Forlorn-Ritualant Encounter

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Forlorn-Ritualant NPC runtime sprites | `custodian/content/sprites/npcs/ash_bell/forlorn_ritualant_idle_48x64.png`, `custodian/content/sprites/npcs/ash_bell/forlorn_ritualant_rise_48x64.png`, `custodian/content/sprites/npcs/ash_bell/forlorn_ritualant_hostile_idle_48x64.png`, `custodian/content/sprites/npcs/ash_bell/forlorn_ritualant_clapper_swing_48x64.png` | Replace placeholder Forlorn-Ritualant geometry with readable kneeling/rising/hostile/attack animation. | Runtime scene uses ColorRect placeholders until these are supplied and wired into `AnimatedSprite2D`. |
| needed | Forlorn-Ritualant death/dissolve sprite | `custodian/content/sprites/npcs/ash_bell/forlorn_ritualant_death_unthreading_48x64.png` | Let nonlethal dissolve and violent defeat resolve with authored ritual animation. | Current NPC queues free after a timed placeholder dissolve. |
| needed | Unarrived Saint apparition sprite | `custodian/content/sprites/npcs/ash_bell/unarrived_saint_apparition_64x96.png` | Show the late-arriving apparition when thread snaps, silence is rung, or the site is defiled. | Placeholder vertical ColorRect exists in `forlorn_ritualant_site.tscn`. |
| needed | Unarrived procession silhouettes | `custodian/content/sprites/npcs/ash_bell/unarrived_procession_ghosts_32x48.png` | Replace the placeholder procession band with subtle civic silhouettes. | Needed before Ninth Answer/procession lane reads correctly. |
| needed | Ash-Bell ritual prop sprites | `custodian/content/props/ash_bell/empty_bell_frame_96x96.png`, `custodian/content/props/ash_bell/stilling_pin_32x32.png`, `custodian/content/props/ash_bell/white_thread_floor_a_32.png`, `custodian/content/props/ash_bell/white_thread_floor_b_32.png`, `custodian/content/props/ash_bell/white_thread_hanging_32x64.png`, `custodian/content/props/ash_bell/white_thread_knot_16x16.png` | Replace placeholder bell frame, stilling pin, and white-thread zones in the authored encounter. | The runtime module is wired but intentionally not pretending production art exists. |
| needed | Ash-Bell chamber dressing props/decals | `custodian/content/props/ash_bell/black_banner_hanging_32x64.png`, `custodian/content/props/ash_bell/black_banner_torn_32x48.png`, `custodian/content/props/ash_bell/black_banner_floor_32x32.png`, `custodian/content/decals/ash_bell/ash_child_handprints_32.png`, `custodian/content/props/ash_bell/west_gate_seal_marker_32x64.png`, `custodian/content/decals/ash_bell/sealed_gate_scratches_32.png` | Make the room communicate black banners, sealed west gate, child handprints, and Ash-Bell ritual context. | Placeholder banners exist; decals/seal markers are not yet represented. |
| needed | Dry Fountain apparition states | `custodian/content/props/ash_bell/dry_fountain_ghost_96x96.png`, `custodian/content/props/ash_bell/dry_fountain_black_water_96x96.png`, `custodian/content/props/ash_bell/dry_fountain_cracked_96x96.png` | Support ABSENT/GHOST/BLACK_WATER/CRACKED_ANCHORED fountain states. | Current scene fades placeholder ColorRects. |
| needed | Ash-Bell audio cues | `custodian/content/audio/sfx/ash_bell/thread_strain_*.wav`, `custodian/content/audio/sfx/ash_bell/reverse_chime_*.wav`, `custodian/content/audio/ambience/ash_bell_room_bed_*.wav`, `custodian/content/audio/sfx/ash_bell/silence_pulse_*.wav` | Provide thread strain, reversed chime, room bed, and silence-pulse feedback for the encounter mechanics. | Runtime has state hooks but no audio assets or mixer mute implementation yet. |

## Last Routekeeper Event

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Last Routekeeper residual projection animations | `custodian/content/sprites/events/last_routekeeper/{last_routekeeper_residual_idle_south_96x96_6f,last_routekeeper_residual_mark_south_96x96_6f,last_routekeeper_residual_fade_south_96x96_8f}.png` | Replace placeholder Polygon2D residual figure used by `LastRoutekeeperEvent`. | One-time Sundered Keep random event: route authority trace of B. Chaffee. |
| needed | Last Routekeeper route beacon and route-mark props | `custodian/content/tiles/sundered_keep/events/last_routekeeper/{routekeeper_survey_beacon_01,routekeeper_chalk_marks_01,routekeeper_route_hint_marker_01,routekeeper_hologram_pulse_01}.png` plus `.game32.json` sidecars | Replace placeholder beacon/marker visuals used by `LastRoutekeeperEvent` and Sundered Keep hint reveal. | Lower causeway / underpass traversal readability reward. |

## Procgen Gameplay Feel

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Production procgen road/path decal pack | `custodian/content/tiles/roads_paths/runtime/roads/{standard,gothic}/pieces/road_lane_{center,left_1,left_2,right_1,right_2}.png`, `custodian/content/tiles/roads_paths/runtime/paths/pieces/*.png`, and matching manifests | Replace the active road lane-role placeholders and `PLACEHOLDER_paths_mask_*` runtime decals once the generated road layout is approved. | Procgen road overlays now use the 32x32 lane-role contract `center`, `left_1`, `left_2`, `right_1`, and `right_2`; current road role entries alias existing `PLACEHOLDER_roads_mask_*` art until production lane tiles are supplied. |
| partial | Terrain gameplay pack direction/corner semantic review | `reports/terrain_pack_ingest/terrain_direction_review.md` plus runtime art under `custodian/content/tiles/terrain/runtime/{connector,ascent,chasm_bridge}/` | Confirm connector inner/outer corners, ascent ramp/stair directions, chasm edge/corner directions, and bridge start directions before gameplay placement. | Connector, Ascent, and Chasm+Bridge packs are ingested and registered as TileSet atlas sources, but runtime placement and actual TileSet terrain/autotile terrain sets are deferred. |
| needed | Power Components harvesting node strips | `custodian/content/sprites/props/harvesting_nodes/power_node/power_node__node__idle__5f__96.png`, `custodian/content/sprites/props/harvesting_nodes/power_node/power_node__node__depleted__1f__96.png` | Complete local `power_components` source-node implementation with the same 96px idle/depleted strip contract used by other `ResourceNode` presets. | Existing flat `power_components_*` PNGs are concept/source material, not compatible harvest-state node strips. |
| needed | Fiber Moss harvesting node strips | `custodian/content/sprites/props/harvesting_nodes/moss_patch/moss_patch__node__idle__5f__96.png`, `custodian/content/sprites/props/harvesting_nodes/moss_patch/moss_patch__node__depleted__1f__96.png` | Complete local `fiber_moss` source-node implementation for gatherable moss patches. | Existing design references `moss_patch`; runtime currently gets `fiber_moss` only as a secondary yield from fungal resin pods. |
| needed | Destroyed wall debris floor variants | `custodian/content/tiles/walls/runtime/destroyed_wall_floor_*.png` or registered TileSet source | Make destroyed walls read as debris terrain instead of generic floor. | Runtime now tags `destroyed_wall_floor / debris`; visual art is still generic floor until supplied and wired. |
| needed | Wall destruction dust puff FX | `custodian/content/sprites/effects/runtime/wall_destruction/wall_dust_puff_01__omni__?f__?.png` | Reinforce destructible wall impact and traversal affordance. | No runtime FX hook yet; asset needed before wiring. |
| needed | Wall destruction audio cues | `custodian/content/audio/sfx/world/wall_destroy_*.wav` | Feedback for wall break events. | Pair with future dust FX hook. |
| needed | Portal plaza dressing props | `custodian/content/props/ruins/data/prop_definitions/portal_plaza_*.tres` plus sprites under `custodian/content/props/ruins/` | Make portal endpoints feel authored and landmark-like. | Runtime now stamps `portal_plaza`; decorative ring clutter is not yet authored. |
| needed | Compound ingress cover props | `custodian/content/props/ruins/data/prop_definitions/compound_cover_*.tres` | Fill `cover_anchor / compound_ingress` points with barricades, crates, lamps, or ruin cover. | Runtime tags anchors only; no prop consumer yet. |
| needed | Compound ingress hazard/light markers | `custodian/content/sprites/environment/props/compound/ingress_marker_*.png` | Make compound thresholds read as defended encounter spaces. | Optional but recommended by procgen feel notes. |
| needed | Room-identity interior prop sets | `custodian/content/tiles/interiors/runtime/props_storage_*.png`, `props_security_*.png`, `props_maintenance_*.png`, `props_archive_*.png`, `props_generator_*.png`, `props_barracks_*.png`, `props_lab_*.png` | Let room zones influence interior dressing. | Runtime now tags prop `region_zone`; current prop pool is generic. |
| needed | Foliage tactical cover variants | `custodian/content/sprites/environment/foliage/cover_shrub_*.png`, `tree_los_blocker_*.png` | Make `foliage_cover` terrain visually distinguish concealment/blocker roles. | Runtime now tags foliage as `foliage_cover / tree|shrub`. |

## Compound Room Templates

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Hangar room templates | `custodian/game/world/compound/rooms/templates/hangar_large.tmj`, `custodian/game/world/compound/rooms/templates/hangar_small.tmj` | Supply combat/vehicle-scale room candidates referenced by `default_compound.json`. | Only `command_post.tmj` exists today; layout generation skips missing templates. |
| needed | Corridor room templates | `custodian/game/world/compound/rooms/templates/corridor_h.tmj`, `custodian/game/world/compound/rooms/templates/corridor_v.tmj` | Supply graph connectivity rooms with authored north/south/east/west door metadata. | Required before deterministic graph-walk assembly can be meaningfully smoke-tested. |
| needed | Storage room template | `custodian/game/world/compound/rooms/templates/storage.tmj` | Supply loot/storage candidate referenced by `default_compound.json`. | Should include door properties and optional loot/prop markers per room template README. |
| needed | Landing pad room template | `custodian/game/world/compound/rooms/templates/landing_pad.tmj` | Supply extract/arrival room candidate referenced by `default_compound.json`. | Should include door properties plus extract/arrival markers when that runtime consumer exists. |

## Vault Storage / Enemy Raiding

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Per-resource vault storage state sprites | `custodian/content/sprites/environment/props/vault_storage/runtime/{ruin_scrap,structural_alloy,power_components,resin_clot,capacitor_dust,signal_filament,memory_glass_fragment}__storage__{empty,stored,damaged}__1f__160x128.png` | Make stored resources visibly occupy the vault instead of using one generic chest for every resource. | Runtime now has a permanent vault-storage sprite home and uses the generic chest states there until resource-specific props exist. |
| needed | Enemy grunt sabotage animation suite | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__objective__sabotage_01__{n,ne,e,se,s,sw,w,nw}__6f__96.png` | Make storage vandalism/opening readable during the timed sabotage action. | Runtime sabotage behavior is implemented but currently reuses existing stop/idle presentation. |
| needed | Enemy grunt loot/carry/escape animation suite | `custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__objective__{loot_start_01,carry_run_01,escape_01}__{n,ne,e,se,s,sw,w,nw}__?f__96.png` | Show thieves taking a bundle and fleeing with weight/urgency. | Current loot carrier state is functional and minimap-visible but not visually distinct on the enemy body. |
| needed | Vault raid audio cues | `custodian/content/audio/sfx/vault/{storage_open_*.wav,storage_sabotage_*.wav,storage_destroyed_*.wav,loot_stolen_*.wav}` | Feedback for enemy storage opening, sabotage damage, destruction, and successful theft. | Runtime emits manager signals that can drive these cues once supplied. |

## Enemy Marine

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Enemy marine movement and combat runtime suite | `custodian/content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__{run_01,melee_01,stagger_01,death_01}__{n,ne,e,se,s,sw,w,nw}__?f__96.png`, optional FX under `custodian/content/sprites/enemies/enemy_marine/runtime/fx/` | Promote `enemy_marine` beyond idle fallback into a readable active wave enemy. | The full 8-direction idle suite is wired, and an east dash attack body/FX strip is wired for the Sundered Keep Great Hall ambush. Full directional run, regular melee, stagger, death, and non-east dash coverage are still needed. |
| needed | Enemy marine heavy dash directional body suite | `custodian/content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_01__{n,ne,e,se,s,sw,w,nw}__8f__156.png` | Replace the current east-only dash fallback with readable directional heavy-charge body animation. | Design target is slow compressed windup, violent launch smear, impact frame, and skid/recovery. Minimum useful coverage is E/W/NE/NW/SE/SW; E exists and W may flip temporarily. |
| needed | Enemy marine heavy dash FX overlay suite | `custodian/content/sprites/enemies/enemy_marine/runtime/fx/enemy_marine__fx__unarmed__dash_attack_01__{n,ne,e,se,s,sw,w,nw}__8f__156.png` | Add separate telegraph, launch, travel, impact, skid, and settling dust/spark overlays for the heavy dash. | Keep FX dirty/metallic: shoulder glow, boot scrape, floor chips, orange sparks, short shock crescent, skid dust. E exists but should be revised to the hardened design if needed. |
| needed | Enemy marine heavy dash audio stack | `custodian/content/audio/sfx/enemies/enemy_marine/dash_{windup,launch,travel,impact,recover}_*.wav` | Sell mass and impact with servo whine, armor creak, boot slam, dirty whoosh, metal body hit, bass thud, stone scrape, and recovery grind. | Do not use sword-swish audio; this should sound like armored mass crossing space violently. |

## Enemy Savage

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Enemy Savage rushdown animation suite | `custodian/content/sprites/enemies/enemy_savage/runtime/body/enemy_savage__body__{run,melee_chain_01,pounce,flinch,stagger,death}__{n,ne,e,se,s,sw,w,nw}__?f__96.png`, optional FX under `runtime/fx/` | Replace idle substitution with readable movement, two-hit pressure, pounce commitment, reactions, and death. | Gameplay is live with E/N/S/SE/SW/W idle strips, NE/NW falling back to N. Minimum broad wiring target is S/E/W/N; each sheet needs explicit frame metadata if its canvas is not 96px. |

## Portal / Ruin Props

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| partial | Portal-ring FX strips | `custodian/content/sprites/environment/props/portal_ring/runtime/fx/` | Idle, activation, and arrival portal playback. | Runtime strips exist; in-editor timing polish may still need revised frames. |
| partial | Portal-ring collision/occlusion reference | `custodian/content/props/ruins/scenes/portal_ring_collision.tscn` | Precise side blockers and platform occlusion. | Authored scene exists; keep tracker open until final visual QA locks it. |
| needed | Additional ruin prop overlays | `custodian/content/props/ruins/overlays/` | Dirt, chips, vines, highlights, moss/crack variety for procedural prop variants. | Current starter definitions use limited moss/crack overlays. |
| needed | Additional ruin prop definitions | `custodian/content/props/ruins/data/prop_definitions/*.tres` | Expand procgen ruin landmark and clutter variety. | Starter obelisk, portal, rotunda, slab exist. |

## Operator / Combat

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Posture-break flash editable source | `custodian/content/sprites/effects/combat/critical/source/posture_break_flash_01.aseprite` | Preserve the editable source for the live seven-frame critical-open posture-break strip. | Runtime PNG, SpriteFrames, scene, and playback are implemented; only the source file named by the design contract is absent. |
| needed | Critical-window expiry editable source | `custodian/content/sprites/effects/combat/critical/source/critical_window_expire_01.aseprite` | Preserve the editable source for the live eight-frame unconsumed-opportunity closure strip. | Runtime PNG, SpriteFrames, scene, and playback are implemented; only the source file named by the design contract is absent. |
| partial | Operator unarmed arrival | `custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__arrival_01__s__9f__96.png` | Portal arrival body animation. | Ingested and wired for south/down only. Directional variants not supplied. |
| needed | Operator modular fast windup FX south sheet | `custodian/content/sprites/operator/new_operator/modular/fast_attack/operator__modular_upper_fx__unarmed__fast_windup_01__s__3f__96.png` | Complete optional fast windup FX coverage if windup FX is promoted into runtime playback later. | Fast windup lower/upper body sheets are live for all 8 directions. Existing non-south windup FX source sheets remain unwired because fast windup FX is not part of the current runtime phase contract. |
| partial | Operator modular ranged-ready/fire suite | `custodian/content/sprites/operator/new_operator/modular/ranged/` plus runtime copies under `custodian/content/sprites/operator/runtime/modules/new_operator/` | Complete the true layered two-handed ranged rig where body, weapon, muzzle flash, and smoke act independently. | E/N/W lower-body, upper-body, and weapon stance layers are live for idle carbine-ready. Still needed: south/diagonals plus modular movement, fire, recover, reload, muzzle flash, and smoke. |
| needed | Complete Operator modular sidearm recovery/reload/cardinal suite | `custodian/content/sprites/operator/new_operator/modular/sidearm/` with matching upper/lower/sidearm/FX layers for `{n,e,s,w}` draw/fire plus diagonal/cardinal recover/reload | Complete the modular pistol set so cardinal aim, recovery, and reload do not require nearest-diagonal or legacy placeholder fallbacks. | Draw/fire lower, upper, pistol, and FX layers are live for NE/NW/SE/SW. Draw's final frame is the held ready pose. |
| partial | Operator unarmed parry body and FX suite | `custodian/content/sprites/operator/new_operator/modular/parry/operator__modular_{lower_body,upper_body,upper_fx}__unarmed__parry_{start,success,recovery,fx}_01__{n,ne,e,se,s,sw,w,nw}__?f__96.png` plus generated runtime modules | Complete authored primary-from-guard parry, perfect-parry success, parry recovery, and impact FX coverage. | Baseline `parry_01` lower/upper N body and N/E upper-FX sheets are generated, curated at 12 FPS, and live for guard-triggered parry/success. Successful parry currently uses clearly labeled `PLACEHOLDER_unarmed_parry_success_fx*` animations sourced from the normal parry FX strip until a dedicated success burst lands. Still needed: dedicated recovery, stronger success/impact variants, S/W and diagonal body/FX coverage, and final audio. |
| needed | Operator parry miss world VFX | `custodian/content/sprites/effects/combat/parry/combat_fx__parry_miss_01__6f__128.png` | Show a missed active parry as a dry empty-air whiff when no hit is caught. | Runtime spawns `res://game/vfx/combat/parry_miss_vfx.tscn` only when the active parry window expires into recovery without a successful parry. The scene disables itself with a warning until this 6-frame 128px horizontal strip exists. |
| needed | Operator modular lower-body fallback action | `custodian/content/sprites/operator/new_operator/modular/lower/operator__modular_lower_body__action_01__{n,ne,e,se,s,sw,w,nw}__5f__96.png` | Shared lower-body fallback for modular movement/action defaults. | Runtime builder supports `action_01` as a fallback, but no source sheets exist yet; current generated idle/walk fall back to available authored sheets or `run_01`. |
| needed | Operator modular lower-body directional idle gaps | `custodian/content/sprites/operator/new_operator/modular/idle/operator__modular_lower_body__idle__{ne,nw}__5f__96.png` | Complete true modular lower-body idle defaults for all directions. | Runtime builder now uses authored lower idle for N/E/SE/S/SW/W; NE/NW still fall back through `action_01` then `run_01`. |
| needed | Operator modular lower-body directional walk | `custodian/content/sprites/operator/new_operator/modular/walk/operator__modular_lower_body__walk_01__{n,ne,s,se,sw,nw}__5f__96.png` | True modular lower-body walk defaults beyond east/west. | East/west walk sources exist; other directions fall back through `action_01` then `run_01`. |
| needed | Operator modular upper-body fallback action | `custodian/content/sprites/operator/new_operator/modular/upper/operator__modular_upper_body__unarmed__action_01__{n,ne,e,se,s,sw,w,nw}__5f__96.png` | Shared upper-body fallback for modular movement/action defaults. | Runtime builder supports upper `action_01`, but no source sheets exist yet; idle/walk currently fall back to available upper `run_01`. |
| needed | Operator modular upper-body directional idle | `custodian/content/sprites/operator/new_operator/modular/idle/operator__modular_upper_body__unarmed__idle_01__{n,ne,e,se,s,sw,w,nw}__5f__96.png` | True upper-body idle layer for the modular operator rig. | Current upper idle runtime sheets are generated fallbacks from upper `run_01`/nearest-direction sources. |
| needed | Operator modular upper-body directional walk | `custodian/content/sprites/operator/new_operator/modular/walk/operator__modular_upper_body__unarmed__walk_01__{n,ne,e,se,s,sw,w,nw}__5f__96.png` | True upper-body walk layer for the modular operator rig. | Current upper walk runtime sheets are generated fallbacks from upper `run_01`/nearest-direction sources. |
| needed | Operator modular upper-body run diagonal gaps | `custodian/content/sprites/operator/new_operator/modular/run/operator__modular_upper_body__unarmed__run_01__{ne,nw}__5f__96.png` | Complete authored upper-body run coverage for all 8 directions. | Upper run has N/E/SE/S/SW/W; NE/NW currently use nearest-direction fallbacks. |
| partial | Operator full directional dodge body/FX suite | Current full strips: `custodian/content/sprites/operator/new_operator/modular/dodge/operator__{body,fx}__full__dodge_01__{n,s}__9f__96.png`; remaining directions under the same folder. Optional split/backstep tracks remain supported under `custodian/content/sprites/operator/runtime/body/locomotion/`. | Complete authored dodge direction coverage while preserving deterministic impulse/recovery timing. | N/S 9-frame full body and FX strips are live; upward uses N and horizontal/downward uses S with horizontal mirroring. Still needed: dedicated E/W/diagonals and optional authored aim-backstep variants. |
| needed | Operator non-unarmed hit reactions | `custodian/content/sprites/operator/runtime/body/{melee_2h,ranged_2h}/operator__body__*__light_hitreact_01__*__?f__96.png` | Avoid using unarmed hitreact fallback for armed profiles. | Runtime currently falls back to unarmed hitreact. |
| needed | Remaining directional ranged run sheets | `custodian/content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged_2h__run_01__{n,s,w}__?f__96.png` and matching weapon overlays | Dedicated ranged sprint/run in all directions. | East is wired and mirrored for horizontal left. |

## Combat Resource Feedback (Milestone A)

The V1 common dry-fire and carbine reload/heat/vent WAVs are supplied, format-verified, and wired. The P-9 reuses those cues until bespoke replacements arrive.

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Overheat vent FX strip | `custodian/content/sprites/effects/runtime/weapon_pressure/weapon_pressure__fx__ranged__overheat_vent_01__omni__6f__32.png` | Compact white-grey pressure discharge with faint amber first frame, spawned at weapon barrel during overheat. | 32×32 per frame, 6 frames, 12 fps, non-looping. Optional for V1 — a procedural particle scene (`weapon_overheat_vent_vfx.tscn`) can stand in. |
| needed | Source Aseprite for vent FX | `custodian/content/_aseprite/sprites/effects/source/weapon_pressure/weapon_pressure__fx__ranged__overheat_vent_01__omni__6f__32.aseprite` | Editable source for the overheat vent strip. | Required by the Aseprite source file convention. |
| needed | HUD icon: heat hot | `custodian/content/ui/black_reliquary/icons/weapon_pressure/heat_hot.png` | Optional state icon for the pressure row when heat is above warning threshold. | 16×16, transparent background. Optional — initial implementation uses the text label and Black Reliquary palette. |
| needed | HUD icon: heat critical | `custodian/content/ui/black_reliquary/icons/weapon_pressure/heat_critical.png` | Optional state icon for the pressure row when 1–2 shots remain before overheat. | 16×16, transparent background. Optional. |
| needed | HUD icon: overheated | `custodian/content/ui/black_reliquary/icons/weapon_pressure/overheated.png` | Optional state icon for the pressure row during overheat lockout. | 16×16, transparent background. Optional. |
| needed | HUD icon: reloading | `custodian/content/ui/black_reliquary/icons/weapon_pressure/reloading.png` | Optional state icon for the pressure row during magazine reload. | 16×16, transparent background. Optional. |
| needed | HUD icon: dry | `custodian/content/ui/black_reliquary/icons/weapon_pressure/dry.png` | Optional state icon for the pressure row when magazine and reserve are empty. | 16×16, transparent background. Optional. |

## Vehicles

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Hover buggy firing animation | `custodian/content/sprites/vehicles/light_buggy/runtime/` | Vehicle combat feedback. | Idle and horizontal movement are runtime-ready. |
| needed | Hover buggy damage animation | `custodian/content/sprites/vehicles/light_buggy/runtime/` | Vehicle damage readability. | Needed before broader vehicle combat polish. |
| needed | Hover buggy destruction animation | `custodian/content/sprites/vehicles/light_buggy/runtime/` | Vehicle failure/death readability. | Needed before vehicle durability feels complete. |

## UI / Terminal

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Command terminal renamed production sheets | `custodian/content/sprites/environment/props/terminal/runtime/body/command_terminal__*.png` | Replace compatibility fallback to older terminal naming. | Some compatibility copies exist; final canonical art pass remains open. |
| needed | Terminal UI frames, overlays, icons, pips, button skins | See `custodian/content/ui/terminal/README.md` | Replace placeholder/lightly-derived terminal styling. | Keep UI asset asks synchronized with that README. |
