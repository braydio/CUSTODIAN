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

## Environmental storytelling continuation (design only, 2026-10-27)

The V1 story-room placer exports deterministic metadata and the live StoryRoomGeometryStamper can claim an existing reserved rectangle of floor. That is **partial site geometry**, not full environmental storytelling: no causal prop tableau, physical inspect circuit, production art or canon-conditioned evidence composition is thereby realized. Do not reissue the previous "any room geometry" task as if the existing stamper were absent.

The user-endorsed three-scene proposal is [Procedural Environmental Storytelling V1](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md): Refused Passage, Borrowed Hearth, False Seam. The [integration roadmap](PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md) holds geometry acceptance, faction migration, art and implementation pending the next explicit design review. In particular, legacy iconoclast/cult_mechanist/scavenger identifiers here are prototype runtime compatibility data, not canonical polity definitions.

### Next Agent Slice (planning, not implementation)

- **Goal:** audit one safe F02 site claim/realization seam, current room/intent/accepted export, and F15-B2 read-only site identity; evaluate proposed footprints against real nav and camera.
- **Files:** custodian/game/world/procgen/story/, intent/, roads/, generation/accepted_world_export.gd, relevant inspect and Asset V2 consumers.
- **Constraints:** no second story/terrain authority, no auto-dispatched packets or art, preserve routes/mission ingress and seven-polity canon.
- **Acceptance:** source-grounded option and first Refused Passage pilot plan approved before any coding packet is authored.

## Local biome orthogonality

Local ecological biome is orthogonal to distance/style progression. Distance band does not directly choose biome; accepted terrain, seeded moisture/exposure, and climate bias do.
