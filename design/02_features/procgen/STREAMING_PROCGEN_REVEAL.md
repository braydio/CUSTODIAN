# Streaming Procgen Reveal

**Project:** CUSTODIAN  
**Status:** In Progress  
**Created:** 2026-03-26
**Last Updated:** 2026-10-01
**Content Canon Authority:** `design/03_world/GAME_PROTOCOLS_AND_WORLD_LORE.md`

## Goal

Make the procgen world appear to build itself around the player during play instead of fully appearing before the run starts.

This is a **deterministic chunk-streamed reveal layer** over the current contract map pipeline, not a replacement for the existing seeded procgen map generation.

The reveal should help the world feel operationally discovered, not magically conjured. Presentation and sequencing should support evidence-first world reading when possible.

## Runtime Model

- The full map is still generated deterministically from the contract seed.
- After generation, the visible tilemaps are cleared.
- Chunks are revealed back into the live tilemaps around the player.
- As the player moves, nearby chunks are revealed and far chunks may optionally unload.

The player-facing visual choreography is governed separately by
`STREAMING_REVEAL_PRESENTATION_V1.md` (**Archive Resolve**). That presentation
layer consumes tile request/commit/unload state but does not own chunk lifecycle,
PREPARE/COMMIT, collision, navigation, residency, or world semantics. Its locked
principle is: **chunks are logistics; they must never be choreography.**

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

## Runtime Lifecycle, Scheduling, and Pause (M2-M4)

- Derived rebuild publication (walkable boundary, shadows/presentation, navigation, collision, topology) batches through `ProcGenDerivedRebuildScheduler`: the first request in a scheduler batch schedules the real rebuild via a dirty-flag + `call_deferred` flush, and repeated requests within the same batch coalesce into that one flush/commit instead of one rebuild per caller. `_claim_isolated_world_overlook_pocket` is the sole exception requiring a synchronous, same-call `flush_now` postcondition.
- Tile-level reveal has explicit PREPARE/COMMIT phases owned by `ProcGenPauseAwareStreaming`. While the game is paused, already-queued tiles may be deterministically PREPAREd (a pure lookup into already-generated floor/wall data) without mutating any live TileMap/collision/navigation/foliage state and without accepting new player-driven discovery. COMMIT (the actual authoritative mutation) stays frozen while paused; on resume, prepared work drains first in original order, then any remaining queued tiles, under the same bounded per-frame budget as normal play.
- Per-chunk state is owned by `ProcGenChunkLifecycle`, a deterministic state machine: `UNSEEN -> QUEUED -> PREPARED -> REVEALING -> VISIBLE -> DORMANT -> UNLOADED`. A chunk is `QUEUED` once requested, `PREPARED` once every planned tile is prepared with none yet committed, `REVEALING` from its first authoritative tile commit, and `VISIBLE` once every planned tile has committed; a zero-content chunk becomes `VISIBLE` immediately. `VISIBLE` chunks that fall outside the current active interest radius become `DORMANT` (tracked for future interest/eviction decisions) and return to `VISIBLE` on re-entry without any duplicate queue/commit work -- M4 never removes a `DORMANT` chunk's presentation. `UNLOADED` exists in the contract and is reachable only through the already-disabled-by-default distant-unload path (`streaming_unload_distant_chunks`); production never reaches it by default, but the reload mechanism is already valid: a fresh request for an `UNLOADED` chunk restarts its lifecycle. M6 owns the production policy for when/why chunks are evicted and re-requested, not the existence of that mechanism.
- Exact per-tile visibility (used, for example, when a runtime mutation needs to know whether to paint its own result immediately) is answered by querying canonical painted-cell TileMap state directly, not chunk-level state -- a `REVEALING` chunk can have some committed tiles and some not, and only the TileMap itself knows which.
- `ProcGenChunkPayloadCache` (M5) is a lazy, generation-scoped, invalidatable derived cache behind `ProcGenTilemap`'s existing chunk-membership enumeration and tile PREPARE-record construction: repeated/re-reveal access to an unchanged chunk reuses its cached deterministic tile membership and prepared floor/wall records instead of rescanning `_generated_floor_cells`/`_generated_wall_cells` or re-reading source/atlas data every time. It is a plain-data `RefCounted` with no Node/TileMap/Resource/collision/foliage/gameplay-Callable state and never becomes semantic, queue, or lifecycle authority: `ProcGenTilemap` stays canonical semantic source, `ProcGenPauseAwareStreaming` stays the only tile queue/PREPARE-COMMIT owner, and `ProcGenChunkLifecycle` stays the only chunk-state owner. Live reveal priority (`_streaming_reveal_priority`) is never cached -- queued order is always recomputed from the current player `center_tile` and current region/wall semantics over the (possibly cache-reused) membership set. Every post-cache runtime semantic mutation (wall destruction/neighbor repaint, authored-scene/world-overlook floor or wall claims, and the shared terrain/floor/wall authority setters late-generation finalization also routes through) precisely invalidates its own tile's chunk; a full reset happens only at a true generation/streaming-reset boundary. A PREPARE record carries the generation/chunk-revision identity it was built under, so `_commit_tile_reveal_record()` can detect and rebuild a record that went stale after PREPARE but before COMMIT -- including one still sitting in M3's `_prepared` queue across a resume frame -- rather than ever painting stale data. COMMIT-time dynamic effects (road/surface decals, dressing/foliage decisions, runtime wall collision, overlays/shadows/navigation/macro visibility) are never cached and continue to execute live in committed reveal order. M5 implements no eviction/unload/hysteresis policy; `streaming_unload_distant_chunks` stays false and that production policy remains M6's.

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
