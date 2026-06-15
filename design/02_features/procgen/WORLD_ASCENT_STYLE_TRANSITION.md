# World Ascent Style Transition

**Implementation status:** implemented V1

## Goal

Generated contract worlds gradually transition from low labyrinth spaces into broken foothills, uphill routes, faction-marked ridges, and environmental storytelling sites.

## Primary Runtime Files

- `custodian/game/world/procgen/proc_gen_tilemap.gd`
- `custodian/game/world/procgen/terrain/terrain_builder.gd`
- `custodian/game/world/procgen/terrain/terrain_region.gd`
- `custodian/game/world/elevation/elevation_map.gd`
- `custodian/game/actors/enemies/enemy_behavior_state_machine.gd`
- `custodian/game/actors/enemies/components/enemy_blackboard.gd`
- `custodian/game/actors/enemies/components/enemy_behavior_profile.gd`

## Design Rule

World progression is not a hard biome swap. It is a deterministic blend of distance band, elevation pressure, terrain grammar, faction ambient presence, and story-room insertion.

## V1 Scope

- Load a data-driven distance-band world progression profile.
- Sample style, elevation, faction, and story-room metadata deterministically.
- Stamp one connectivity-validated uphill route across existing generated floor cells.
- Place deterministic faction ambient activity anchors and story-room markers.
- Allow behavior-driven enemies to claim and perform non-combat ambient routines.
- Export all progression/site metadata through procgen level data.

Full story-room geometry, production art, stacked traversal, and actor elevation path costs remain follow-up work.

## Next Agent Slice

- **Goal:** Convert story-room metadata into reserved/carved authored geometry.
- **Files:** procgen story modules, `proc_gen_tilemap.gd`, authored room templates.
- **Constraints:** preserve deterministic generation and required-route connectivity.
- **Acceptance:** story footprints reserve space, carve safely, place props/anchors, and export minimap metadata.
