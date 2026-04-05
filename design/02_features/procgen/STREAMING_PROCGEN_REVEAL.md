# Streaming Procgen Reveal

**Project:** CUSTODIAN  
**Status:** In Progress  
**Created:** 2026-03-26

## Goal

Make the procgen world appear to build itself around the player during play instead of fully appearing before the run starts.

This is a **deterministic chunk-streamed reveal layer** over the current contract map pipeline, not a replacement for the existing seeded procgen map generation.

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

## Collision + Navigation

- Revealed wall tiles also reveal their runtime collision bodies.
- Navigation is rebuilt after chunk reveal batches so enemies can path through the visible world shell.
- This system is compatible with destructible procgen walls.

## Foliage Lifecycle + Depth Rules

- Foliage participates in the same reveal/unload lifecycle as streamed floor and wall tiles.
- Foliage is spawned deterministically from generated floor/wall state, not from ad hoc runtime randomness.
- Foliage should render between floor and walls by default.
- Foliage in front of the operator should render above the operator body while still remaining below wall layers.
- Foliage behind the operator should remain behind, but a small local occlusion bubble around the operator may soften the covered region to preserve readability.
- The translucency rule is a local readability zone, not a whole-sprite fade; distant foliage should remain fully opaque.
- Tree foliage may carry a small trunk-only collision shape at the ground contact point so the canopy remains visual while the base behaves like a readable world obstacle.

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
