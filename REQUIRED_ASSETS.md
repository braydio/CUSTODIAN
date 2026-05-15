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
> ### Dual Copy Sync
>
> This file exists in **two locations that must be kept identical**:
> 1. `REQUIRED_ASSETS.md` — project root (user visibility)
> 2. `design/00_meta/REQUIRED_ASSETS.md` — design directory (agent reference)
>
> **Any update to one copy must be mirrored to the other immediately.** Do not let them drift.

## Practice

## Ash-Bell / Bell-Kneeler Encounter

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
| needed | Bell-Kneeler NPC runtime sprites | `custodian/content/sprites/npcs/ash_bell/bell_kneeler_idle_48x64.png`, `custodian/content/sprites/npcs/ash_bell/bell_kneeler_rise_48x64.png`, `custodian/content/sprites/npcs/ash_bell/bell_kneeler_hostile_idle_48x64.png`, `custodian/content/sprites/npcs/ash_bell/bell_kneeler_clapper_swing_48x64.png` | Replace placeholder Bell-Kneeler geometry with readable kneeling/rising/hostile/attack animation. | Runtime scene uses ColorRect placeholders until these are supplied and wired into `AnimatedSprite2D`. |
| needed | Bell-Kneeler death/dissolve sprite | `custodian/content/sprites/npcs/ash_bell/bell_kneeler_death_unthreading_48x64.png` | Let nonlethal dissolve and violent defeat resolve with authored ritual animation. | Current NPC queues free after a timed placeholder dissolve. |
| needed | Unarrived Saint apparition sprite | `custodian/content/sprites/npcs/ash_bell/unarrived_saint_apparition_64x96.png` | Show the late-arriving apparition when thread snaps, silence is rung, or the site is defiled. | Placeholder vertical ColorRect exists in `bell_kneeler_site.tscn`. |
| needed | Unarrived procession silhouettes | `custodian/content/sprites/npcs/ash_bell/unarrived_procession_ghosts_32x48.png` | Replace the placeholder procession band with subtle civic silhouettes. | Needed before Ninth Answer/procession lane reads correctly. |
| needed | Ash-Bell ritual prop sprites | `custodian/content/props/ash_bell/empty_bell_frame_96x96.png`, `custodian/content/props/ash_bell/bell_clapper_without_bell_32x32.png`, `custodian/content/props/ash_bell/white_thread_floor_a_32.png`, `custodian/content/props/ash_bell/white_thread_floor_b_32.png`, `custodian/content/props/ash_bell/white_thread_hanging_32x64.png`, `custodian/content/props/ash_bell/white_thread_knot_16x16.png` | Replace placeholder bell frame, clapper, and white-thread zones in the authored encounter. | The runtime module is wired but intentionally not pretending production art exists. |
| needed | Ash-Bell chamber dressing props/decals | `custodian/content/props/ash_bell/black_banner_hanging_32x64.png`, `custodian/content/props/ash_bell/black_banner_torn_32x48.png`, `custodian/content/props/ash_bell/black_banner_floor_32x32.png`, `custodian/content/decals/ash_bell/ash_child_handprints_32.png`, `custodian/content/props/ash_bell/west_gate_seal_marker_32x64.png`, `custodian/content/decals/ash_bell/sealed_gate_scratches_32.png` | Make the room communicate black banners, sealed west gate, child handprints, and Ash-Bell ritual context. | Placeholder banners exist; decals/seal markers are not yet represented. |
| needed | Dry Fountain apparition states | `custodian/content/props/ash_bell/dry_fountain_ghost_96x96.png`, `custodian/content/props/ash_bell/dry_fountain_black_water_96x96.png`, `custodian/content/props/ash_bell/dry_fountain_cracked_96x96.png` | Support ABSENT/GHOST/BLACK_WATER/CRACKED_ANCHORED fountain states. | Current scene fades placeholder ColorRects. |
| needed | Ash-Bell audio cues | `custodian/content/audio/sfx/ash_bell/thread_strain_*.wav`, `custodian/content/audio/sfx/ash_bell/reverse_chime_*.wav`, `custodian/content/audio/ambience/ash_bell_room_bed_*.wav`, `custodian/content/audio/sfx/ash_bell/silence_pulse_*.wav` | Provide thread strain, reversed chime, room bed, and silence-pulse feedback for the encounter mechanics. | Runtime has state hooks but no audio assets or mixer mute implementation yet. |

## Procgen Gameplay Feel

| Status | Asset | Target Path | Purpose | Notes |
|---|---|---|---|---|
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
| partial | Operator unarmed arrival | `custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__arrival_01__s__9f__96.png` | Portal arrival body animation. | Ingested and wired for south/down only. Directional variants not supplied. |
| needed | Operator non-unarmed hit reactions | `custodian/content/sprites/operator/runtime/body/{melee_2h,ranged_2h}/operator__body__*__light_hitreact_01__*__?f__96.png` | Avoid using unarmed hitreact fallback for armed profiles. | Runtime currently falls back to unarmed hitreact. |
| needed | Remaining directional ranged run sheets | `custodian/content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged_2h__run_01__{n,s,w}__?f__96.png` and matching weapon overlays | Dedicated ranged sprint/run in all directions. | East is wired and mirrored for horizontal left. |

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
