Found the elevation authority: design/02_features/procgen/ELEVATION.md. It says elevation must be metadata-first: visual tile, height data, and traversal rule stay separate, with ElevationMap as the gameplay authority.   The current state also says Sundered Keep already has authored elevation regions, bridge elevation, fake-elevation visuals, and validation smokes.  

Send Codex this:

Codex task: improve Sundered Keep approach elevation, under-bridge shoreline traversal, and keep/indoor occlusion.

Read first:

1. AGENTS.md
2. custodian/AGENTS.md
3. design/02_features/procgen/ELEVATION.md
4. custodian/docs/ai_context/CURRENT_STATE.md
5. custodian/docs/ai_context/FILE_INDEX.md
6. custodian/docs/ai_context/VALIDATION_RECIPES.md
7. Relevant Sundered Keep files:
    * custodian/game/world/sundered_keep/sundered_keep_map.gd
    * custodian/game/world/sundered_keep/sundered_keep_tilemap_loader.gd
    * custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json
    * custodian/game/world/elevation/elevation_map.gd

Goal:
Rebuild the Sundered Keep entrance so the approach feels like a high, imposing bridge/causeway above a lower storm shore. The player must be able to walk on the elevated bridge and also walk below/around it on the lower shoreline where the bridge visually passes overhead. Then add exterior-to-interior keep readability: from outside, the keep should render as a full building with walls/roof mass; when the Custodian enters the keep interior, the ceiling/roof should cut away so the player can see inside.

Implementation requirements:

* Preserve metadata-first elevation. Do not let art tiles decide movement.
* Use ElevationMap as the authority for height, traversal type, ramps/stairs, blocked/drop cells, and same-height underpass movement.
* Create two traversable height bands:
    * height 1: elevated bridge / causeway deck
    * height 0: lower shore / under-bridge walkable path
* The bridge deck should be visually supported by cliffs, piers, retaining walls, arches, or shadowed supports.
* The lower shore should be walkable where intended, blocked by ocean/void/cliff where not intended.
* Under-bridge cells should remain height 0 and traversable if connected to the shoreline.
* Bridge deck cells should remain height 1 and only reachable by authored stairs/ramps.
* Do not allow accidental traversal between height 0 and height 1 except through explicit ramps/stairs.
* Add visual shadow/overpass treatment so the player understands they are walking below the bridge.
* Keep deterministic authored layout behavior.

Approach layout changes:

* Make the bridge narrower and taller-feeling, with parapets, large side drops, cliff-shadow strips, and vertical support props.
* Add lower shore routes to either side or beneath the bridge.
* Add at least one readable underpass segment where the bridge crosses above the lower shore.
* Add blockers around ocean/void boundaries.
* Improve imposing scale with:
    * larger gatehouse wall mass
    * thicker bridge parapets
    * pier/support columns
    * cliff-face tiles under the bridge edges
    * darker shadow tiles below elevated structure
    * broken lower-shore debris and wave-battered rubble

Indoor/outdoor keep rendering:

* Add a roof/ceiling occlusion system for the keep interior.
* Outside the keep, render full exterior building mass: roof, wall tops, parapets, upper facade, and doorway depth.
* When the Operator enters an authored interior region, hide/fade/cut away the roof/ceiling layer for that region only.
* Keep outer walls visible while hiding only the ceiling/roof plane needed to see the Custodian.
* Use region metadata or authored trigger rectangles rather than hard-coded player coordinates where possible.
* Operator-relative depth sorting should still work for doors, walls, props, and tall structures.
* The Great Hall doorway should continue using its existing open animation and blocker behavior.

Suggested implementation shape:

1. Add or extend authored region data in sundered_keep_front_gate_large.json:
    * elevation_regions
    * underpass_regions
    * shore_walk_regions

## Implementation Status

Implemented 2026-06-05 for the active Sundered Keep single-height-cell runtime model.

- `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json` now declares `underpass_regions`, `shore_walk_regions`, and `interior_occlusion_regions`.
- `custodian/game/world/sundered_keep/sundered_keep_map.gd` consumes those regions, renders visual underpass shadows/support dressing, preserves `ElevationMap` as traversal authority, and fades Great Hall roof occluders when the Operator enters authored interior rectangles.
- `custodian/tools/validation/sundered_keep_large_layout_smoke.gd` validates lower-shore/underpass metadata, height bands, same-height lower-lane traversal, visual underpass overlays/supports, and Great Hall roof cutaway/restoration.

Deferred: true same-coordinate stacked traversal, where a height-0 actor can occupy the same tile coordinate as a height-1 bridge deck, still requires an `ElevationMap` model change.
    
