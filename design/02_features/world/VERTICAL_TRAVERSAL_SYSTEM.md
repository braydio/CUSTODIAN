# CUSTODIAN Vertical Traversal System

**Status:** active design lock  
**Date:** 2026-10-15  
**Audited runtime:** `main@350ee94e4b3b80010c0970903f3418966df3b851`  
**Refresh planning chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

## Product intent

CUSTODIAN should support real multi-elevation traversal while remaining a 2D top-down Godot game. The first generated production target is an Alpine route where the Operator approaches from a lower terrace, wraps around a cliff shoulder on a broad shelf/ascent, reaches a real upper playable terrace, and can stand at the crest looking back toward the route below.

Verticality is gameplay truth. Cliff, ramp, stair, rubble and lift art explain that truth; they never create it.

The program also hardens local mechanical vertical transit. Awakening's Dust Lung service lift is the first production consumer, but its current scene-specific implementation is a compatibility owner, not the reusable end-state.

## Human quality lock

The existing 32 px elevation/cliff/ramp/stair artwork is technically registered but is **not production-acceptable vertical traversal art**. Its existence must never satisfy a future art gate.

Production vertical traversal must instead provide:
- a broad multi-cell route readable at normal gameplay zoom;
- a clearly lower landing and clearly upper landing;
- a shelf/shoulder turn or equivalent spatial continuation so traversal reads as terrain, not an icon;
- upper playable ground visibly occluding enough of the cliff crown to establish the upper plane;
- talus/rubble aligned to the lower/route plane rather than floating as an ambiguous rock mass;
- no hard sprite crop wall, black matte, baked UI cue, or saturated "climb here" paint.

Ordinary Alpine cliffs continue to use the AP2 cliff/fascia/contact presentation. Traversal-specific art supplements that vocabulary only where gameplay has an explicit connector.

## Live runtime truth

| Concern | Live authority | Audited behavior |
| --- | --- | --- |
| Height/traversal | `game/world/elevation/elevation_map.gd` | integer height; walkable/blocked/ledge/ramp/stair/drop; cardinal edge legality; max step/drop 1 |
| Terrain realization | `game/world/procgen/terrain/terrain_builder.gd` | emits height/traversal/ramp-direction metadata with guarded rollback/connectivity |
| Procgen facade | `game/world/procgen/proc_gen_tilemap.gd` | exposes `can_actor_move_between_tiles()`, elevation cost/data, spawn validity and tile/world seams |
| Navigation | `game/systems/core/systems/navigation_system.gd` | directional AStar edges call `can_actor_move_between_tiles()`; navigation-driven enemies already consume this graph |
| Operator | `game/actors/operator/operator.gd` | owns final movement chassis and sole normal `move_and_slide()`; local displacement does not yet query elevation |
| Alpine presentation | Region Frame/AP2 cliff authorities | presentation-only ordinary cliff geology/contact/fog; no traversal authority |
| Local same-map transit | `game/world/traversal/local_transit_lift_2d.gd` + `local_transit_station_2d.gd` | reusable stable-ID station/cycle authority; token-guarded timers, cancellation, and exactly-once actor lock cleanup |
| Awakening lift | `game/world/awakening/awakening_transit_lift.gd` | thin Dust Lung adapter preserving LOWER/UPPER compatibility, prompt, production sprite, and legacy signals |

This corrects stale documentation: enemy navigation is not wholly elevation-blind anymore. The remaining enforcement gaps are Operator local displacement, vehicles, and enemy movement paths that intentionally bypass NavigationSystem.

## Elevation traversal V1

V1 reuses existing `ramp` and `stair` semantics. It does not add a second height graph or hand-over-hand Z simulation.

The first connector grammar is:

```text
lower terrace
  -> lower landing
  -> shelf / shoulder turn
  -> multi-cell ramp or stair ascent, logical height 0 -> 1
  -> upper lip / landing
  -> upper terrace / overlook
```

Ordinary cliff edges remain blocked/ledge/drop according to ElevationMap. Visual cliff art can never make an unregistered edge traversable.

A future explicit mantle, ladder, hand-over-hand climb, jump-down capability or actor-specific climbing profile is deferred until this continuous V1 is proven.

## Operator movement ownership

`operator.gd` remains the final `move_and_slide()` authority. A focused traversal controller may filter proposed movement, but it must not sample raw input, move the actor, mutate terrain, create collision, or duplicate ramp-direction policy.

The Operator guard must:
- resolve/cache the active traversal provider at the composition boundary, never scan the tree every physics frame;
- preserve authored levels that have no procgen provider;
- inspect every tile edge crossed by a proposed movement step, including Dodge/attack-drive displacement;
- use `can_actor_move_between_tiles()` as the sole terrain-edge truth;
- preserve movement along a legal axis when the other axis is blocked;
- leave explicit route/lift/portal relocations outside ordinary local-motion filtering.

## Generated Alpine connector topology

`ASCENT_FIELD` remains upstream world-shape authority. A focused connector planner may reserve one bounded `shelf_wrap` module when a valid lower/upper terrace relationship exists.

Initial design envelope, subject to A2 refresh against landed A1:
- one logical height step;
- lower and upper safe landings target at least 5x4 cells;
- ascent corridor target at least 3 cells wide and 4 cells long;
- one visible shelf/shoulder turn before or after the ascent;
- total connector reservation target no larger than 14x14 cells;
- no overlap with authored/story/faction/compound claims;
- no props, foliage, ordinary cliff fascia/contact or incompatible macro stamp inside the reserved route footprint.

The connector exports its geometry and presentation anchors as semantic level data. Assets consume that data. Assets never reconstruct topology from alpha.

## Reusable local lift

The reusable same-map local transit authority lives under `game/world/traversal/`; Awakening consumes it through a thin compatibility adapter. Do not merge campaign/level route-transition lifts merely because they use the word "lift".

Required mechanics:
- stable StringName station IDs and 2+ station support;
- deterministic idle/busy/origin/destination/cycle state;
- exactly-once actor lock/unlock and cancellation cleanup;
- current station changes only after successful arrival;
- stale callbacks from a cancelled cycle cannot mutate a later cycle;
- invalid actor, reset and tree exit cannot strand player control;
- presentation observes lifecycle phase/progress/signals but does not own eligibility;
- Awakening preserves its lower/upper positions, prompt, one gameplay owner, two physical station affordances and public compatibility expected by progression/debug tooling.

`AshBellLiftIngressSite`, Forlorn Ritualant departure and other LevelLoader/route-transition lifts remain separate until a later audit proves identical semantics.

## Lift presentation target

Current screen dim plus short sprite movement is a compatibility presentation, not the quality bar. After the reusable mechanics land, refresh the existing `awakening-interactible-locker-lift-presentation-v1` packet instead of creating another polish workstream.

Desired Dust Lung result:
- lower and upper stations visibly belong to one machine;
- cage/platform, rails, cables/counterweights and station stops establish vertical travel before interaction;
- the existing Operator `lift_braced` presentation is evaluated as a consumer where appropriate;
- camera/audio/motion support ascent without owning lifecycle;
- cancellation/reset cannot leave stale visuals;
- Dust Lung V2 environment plates remain a separate source-art/runtime cutover gate.

## Asset Pipeline V2 direction

Do not "fix" the rejected tiny ramps into another single-cell family. After connector topology lands, create:

```text
family: procgen_alpine_vertical_traversal
source_work: custodian/asset_drop/source_work/procgen/procgen_alpine_vertical_traversal/
inbox:       custodian/asset_drop/inbox/procgen_alpine_vertical_traversal/
runtime:     custodian/content/tiles/procgen_macro/runtime/alpine_vertical_traversal/
```

Planned 14 static RGBA states:
- `north/south/east/west_ascent_01`
- `north/south/east/west_ascent_broken_01`
- `north/south/east/west_upper_lip_01`
- `scree_talus_01`, `scree_talus_02`

Exact runtime canvases are deliberately **not locked yet**. A3 must derive whole-32-pixel-multiple canvases and registration anchors from the reviewed A2 connector footprint. Each state is one frame with true alpha outside authored geometry.

## Validation doctrine

Objective proof precedes renderer review:
1. ElevationMap/Navigation regressions plus a real Operator traversal fixture.
2. Generic local-lift lifecycle smoke including forward/reverse, 3-station configuration, busy/cancel/reset/invalid-actor negatives.
3. Fixed-seed connector topology determinism, reservations and connectivity.
4. Asset V2 source provenance, dimensions, alpha, registration, status and doctor.
5. Final native-scale traversal evidence showing lower approach, shelf/ascent, crest, upper stance and look-back.

Subjective questions remain human-owned: is the route clearly traversable before entry, do upper/lower levels read immediately, does the crest read as standing above the prior route, and does the module look geological rather than tiled/pasted?

## Explicit non-goals

- no true 3D heightfield or 3D collision conversion;
- no camera-pitch rewrite;
- no vehicle elevation enforcement in V1;
- no universal enemy-special-movement rewrite;
- no mandatory mantle/hand-over-hand animation for V1;
- no reopening ordinary AP2 cliff ownership;
- no unification of same-map local transit with campaign/level route transitions.
