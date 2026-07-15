# Streaming Procgen Reveal

**Project:** CUSTODIAN  
**Status:** In Progress  
**Created:** 2026-03-26
**Last Updated:** 2026-04-08
**Content Canon Authority:** `design/03_content/GAME_PROTOCOLS_AND_WORLD_LORE.md`

## Goal

Make the procgen world appear to build itself around the player during play instead of fully appearing before the run starts.

This is a **deterministic chunk-streamed reveal layer** over the current contract map pipeline, not a replacement for the existing seeded procgen map generation.

The reveal should help the world feel operationally discovered, not magically conjured. Presentation and sequencing should support evidence-first world reading when possible.

## Runtime Model

- The full map is still generated deterministically from the contract seed.
- After generation, the visible tilemaps are cleared.
- Chunks are revealed back into the live tilemaps around the player.
- As the player moves, nearby chunks are revealed and far chunks may optionally unload.

This preserves:

- deterministic contract seeds
- current spawn placement
- current sector/terminal alignment
- current contract payload structure

## Chunk Rules

- Chunk grid is tile-based.
- Default chunk size: `16x16` tiles.
- Default active radius: `2` chunks around the player.
- Default immediate reveal radius at spawn: `1` chunk.

## Reveal Behavior

- The chunk containing the spawn/player and its closest neighbors are revealed immediately.
- Outer chunks are queued and revealed over subsequent frames.
- Reveal order is distance-biased so tiles appear to build outward from the player.
- As content systems deepen, reveal order may also prioritize structurally or fictionally important signals (ingress, terminal zones, relay anchors, obvious machine warnings) as long as determinism is preserved.

## Collision + Navigation

- Revealed wall tiles also reveal their runtime collision bodies.
- Navigation is rebuilt after chunk reveal batches so enemies can path through the visible world shell.
- This system is compatible with destructible procgen walls.

## Foliage Lifecycle + Depth Rules

- Foliage participates in the same reveal/unload lifecycle as streamed floor and wall tiles.
- Foliage is spawned deterministically from generated floor/wall state, not from ad hoc runtime randomness.
- When streaming reveal is enabled, foliage should not be pre-spawned during map capture; it should be restored on tile reveal and removed on chunk unload.
- Foliage should render between floor and walls by default.
- Foliage density inside the compound footprint should be reduced so build pads, traversal lanes, and named structures remain readable.
- Building pads and the immediate player spawn zone should maintain foliage clearance rather than filling with trees and shrubs.
- Foliage in front of the operator should render above the operator body while still remaining below wall layers.
- Foliage behind the operator should remain behind, but a small local occlusion bubble around the operator may soften the covered region to preserve readability.
- Combat-active foliage readability uses the same local occlusion model with a stronger temporary profile: when a live enemy/mob is near the player, nearby canopies use a wider, softer, lower-alpha bubble for a short hold window. This remains presentation-only and must not become movement, target, or combat authority.
- Core combat/readability pockets such as spawn clearings, faction sites, story rooms, portal plazas, compound ingress, and connector lanes should maintain large-foliage and bulky-prop clearance while allowing perimeter cover.
- The translucency rule is a local readability zone, not a whole-sprite fade; distant foliage should remain fully opaque.
- Tree foliage may carry a small trunk-only collision shape at the ground contact point so the canopy remains visual while the base behaves like a readable world obstacle.
- Tree trunk collision must be attached to the spawned foliage node itself so streamed reveal/unload and foliage cleanup do not leave orphan collision bodies behind.
- Floor and wall TileMaps remain base structural authority, but every spawned tree trunk or ruin prop with collision must register its occupied cells in the `ProcGenTilemap` runtime blocker overlay. Navigation and local escape validation consume that overlay; visual-only canopy cells never register.
- Blocking foliage and ruin props must remain at least three tiles from required routes and structure thresholds, with four-tile combat/readability clearance. Canopies may overlap those lanes visually when their trunk collision is suppressed.
- After prop placement and completed reveal batches, deterministic local escape validation checks cardinal exits around blocker-adjacent floor cells. Collision-created pockets with fewer than two exits are remediated by disabling the implicated decorative collision and rebuilding navigation; remediation is logged loudly and mirrored to Developer Observatory.
- Debug builds may rescue an Operator who holds movement for `0.35` seconds with less than `3 px` displacement and near-zero velocity. Rescue searches four tiles for runtime-walkable floor with at least two exits and always prints the source/destination tiles; this is a playtest failsafe, not generation authority.

## Scope

Included now:

- seeded full-map generation
- chunked tile reveal
- player-driven reveal updates
- optional distant chunk unload hooks

Not included yet:

- true endless infinite-world generation
- per-chunk enemy spawn lifecycle
- streaming authored room stitching
- streaming save/load persistence
