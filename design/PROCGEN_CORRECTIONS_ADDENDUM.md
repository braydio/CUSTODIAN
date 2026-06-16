# Addendum: Implementation Hazards, Confirmed Discoveries, and Hardened Corrections

This addendum is mandatory. It clarifies assumptions in the roadmap that are not guaranteed simply by reading the spec, and it records the actual discovery findings so Codex does not re-verify what is already known.

**Two-stage history:** The original addendum was written speculatively before the codebase was inspected. A separate amended document later recorded the discovery findings. This consolidated version merges both — replacing every "verify this" with the actual finding — so there is exactly one source of truth for implementation hazards.

---

## A. Implementation Discovery Results

The following assumptions from the original roadmap are now **confirmed or resolved** by actual runtime inspection:

| Issue | Finding | Action |
|---|---|---|
| `get_player_spawn()` | **Exists** in `proc_gen_tilemap.gd`. Already used many times. | Use it directly. Do not add a fallback. |
| `_ensure_world_progress_profile()` | **Exists** in `proc_gen_tilemap.gd`. `_fill_tilemaps()` already calls it. | Use it directly. Do not add a fallback. |
| Authored-scene reservation API | **Exists**: `claim_procgen_floor_rect_for_authored_scene_world(...)`, `claim_procgen_floor_rect_for_authored_scene_tiles(...)`, `_clear_procgen_wall_authority_at(...)`. | Phase 7 can call the shared API directly. No need to invent wall-clearing logic. |
| `_generated_floor_cells` value shape | **Dictionary entries**, not booleans. Existing code reads values as `Dictionary`. | Do not use `_generated_floor_cells[tile] = true`. Must preserve dictionary shape. |
| TerrainBuilder tile ID preload | Uses `TerrainTileIdsScript`, not bare `TerrainTileIds`. | Use `TerrainTileIdsScript.industrial("elevated_floor")` if an elevated-floor tile exists; otherwise use closest explicit tile ID. |
| Runtime height model | TerrainBuilder defines `HEIGHT_DROP = -1`, `HEIGHT_GROUND = 0`, `HEIGHT_ELEVATED = 1`. | Do not push `target_height = 9` into runtime elevation. Store long-range ascent pressure as `ascent_rank`; clamp runtime_height to 0..1. |
| `NavigationSystem` | AStar2D graph over floor/wall TileMaps; no elevation-cost integration. | Phase 8 is **query-only** unless Codex explicitly designs and validates AStar edge filtering. |
| `procgen_placeholder_roads_smoke.gd` | **Exists** on this branch. | Keep it in validation. Do not skip it. |

**Implementation discovery section** — record these in the task packet before editing:

```markdown
## Implementation Discovery

- `_fill_tilemaps()` location:
- terrain-builder call location:
- road/parking enforcement order:
- foliage/prop placement order:
- faction site placement order:
- story room placement order:
- `get_level_data()` export location:
- `get_player_spawn()` exists? yes/no; replacement:
- `_ensure_world_progress_profile()` exists? yes/no; replacement:
- `claim_procgen_floor_rect_for_authored_scene_tiles()` exists? yes/no; prerequisite:
- `_generated_floor_cells` value shape:
- TerrainTileIds preload name:
- ElevationMap traversal API names:
- available validation scripts:
```

---

## B. Preflight Inspection

Before implementing Phase 5, Phase 6, or Phase 8, verify the actual insertion points by running:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

grep -n "func _fill_tilemaps" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "func generate" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "func get_level_data" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "func _apply_terrain_builder" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "required_cells" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "_place_faction" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "_place_story" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "_apply.*road\|road.*enforcement\|_clear.*wall" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "claim_procgen_floor_rect" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "_ensure_world_progress_profile" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "get_player_spawn" custodian/game/world/procgen/proc_gen_tilemap.gd
grep -n "func build_terrain\|func build" custodian/game/world/procgen/terrain/terrain_builder.gd
grep -n "required_cells\|connectivity\|height_by_cell\|traversal_by_cell\|tile_by_cell" custodian/game/world/procgen/terrain/terrain_builder.gd
grep -n "can_traverse\|set_cell\|height" custodian/game/world/elevation/elevation_map.gd
```

---

## C. GDScript Syntax: use `null`, not `nil`

The roadmap contains a few `nil` examples that must be corrected before implementation. Godot 4 uses `null`, not `nil`.

Replace every instance of `nil` with `null`. Example corrections from the roadmap code:

```gdscript
var profile = context.get("world_progress_profile", null)       # not nil
assert(procgen != null)                                          # not nil
if _terrain_builder != null:                                     # not nil
```

Do not commit any new GDScript using `nil`.

---

## D. Confirmed Methods — Use Directly, No Fallback Needed

### `get_player_spawn()`

Exists in `proc_gen_tilemap.gd`. Use it directly in Phase 5:

```gdscript
var origin := get_player_spawn()
if origin == Vector2i.ZERO:
    origin = Vector2i(map_size.x / 2, map_size.y - 12)
```

Do **not** add a fallback helper. If a branch mismatch occurs where this method is missing, add a local helper:

```gdscript
func _get_worldgen_intent_origin_cell(map_size: Vector2i) -> Vector2i:
    if has_method("get_player_spawn"):
        var spawn = call("get_player_spawn")
        if spawn is Vector2i:
            return spawn
    if "_player_spawn_tile" in self:
        var stored_spawn = get("_player_spawn_tile")
        if stored_spawn is Vector2i:
            return stored_spawn
    if "_spawn_tile" in self:
        var spawn_tile = get("_spawn_tile")
        if spawn_tile is Vector2i:
            return spawn_tile
    return Vector2i(map_size.x / 2, map_size.y - 12)
```

### `_ensure_world_progress_profile()`

Exists in `proc_gen_tilemap.gd`. `_fill_tilemaps()` already calls it. Do **not** add a duplicate loader helper.

If a branch mismatch occurs where this method is missing, add a local helper:

```gdscript
func _ensure_worldgen_progress_profile_loaded() -> void:
    if _world_progress_profile != null:
        return
    if not world_progression_enabled:
        return
    if world_progress_profile_path == "":
        return
    if WORLD_PROGRESS_PROFILE_SCRIPT == null:
        push_warning("[ProcGenTilemap] Cannot load world progress profile: script preload missing.")
        return
    if WORLD_PROGRESS_PROFILE_SCRIPT.has_method("load_from_path"):
        _world_progress_profile = WORLD_PROGRESS_PROFILE_SCRIPT.load_from_path(world_progress_profile_path)
```

Then call:

```gdscript
if has_method("_ensure_world_progress_profile"):
    call("_ensure_world_progress_profile")
else:
    _ensure_worldgen_progress_profile_loaded()
```

---

## E. Runtime Data Shape: `_generated_floor_cells` stores dictionaries

The roadmap currently shows:

```gdscript
_generated_floor_cells[tile] = true
```

**This is wrong.** Current runtime reads `_generated_floor_cells[tile]` as a `Dictionary`. Use dictionary shape:

```gdscript
var source_id := _select_floor_source_id(tile)
var atlas := _select_floor_coord(tile)

_generated_floor_cells[tile] = {
    "source_id": source_id,
    "atlas": atlas,
    "alternative": 0,
    "authority": "worldgen_intent",
}
```

Verify with:

```bash
grep -n "_generated_floor_cells" custodian/game/world/procgen/proc_gen_tilemap.gd
```

If a future runtime change introduces a different shape, match whatever the existing code produces. Do not introduce mixed value types unless every reader is tolerant.

---

## F. Height Model: split `ascent_rank` from `runtime_height`

Current TerrainBuilder height constants are `HEIGHT_DROP = -1`, `HEIGHT_GROUND = 0`, `HEIGHT_ELEVATED = 1`. The roadmap's `target_height` value of `9` is **not safe** for runtime elevation.

Use this model in `WorldgenIntentNode`:

```gdscript
var runtime_height: int = 0
var ascent_rank: int = 0
```

Update `to_dictionary()`:

```gdscript
"runtime_height": runtime_height,
"ascent_rank": ascent_rank,
```

In `AscentSpineBuilder`, replace:

```gdscript
int(round(t * 9.0))
```

with:

```gdscript
var ascent_rank := int(round(t * 9.0))
var runtime_height := clampi(int(floor(float(ascent_rank) / 5.0)), 0, 1)
```

Then pass both into `_make_node(...)`.

For V1: ascent_rank = 0..9, runtime_height = clamp(ascent_rank / 4, 0, 1). Do not force height `9` into `ElevationMap` unless the elevation/traversal code is updated and validated to support it.

---

## G. TerrainTileIds: must use `TerrainTileIdsScript`

The roadmap uses:

```gdscript
TerrainTileIds.TILE_ELEVATED_FLOOR
```

**This is wrong.** The existing `terrain_builder.gd` preloads tile IDs as `TerrainTileIdsScript`. Use:

```gdscript
TerrainTileIdsScript.industrial("elevated_floor")
```

If no matching elevated-floor symbolic tile exists, choose the closest existing explicit elevated/platform tile ID and document the mapping in the task packet.

Verify with:

```bash
grep -n "TerrainTileIds" custodian/game/world/procgen/terrain/terrain_builder.gd
grep -n "TILE_ELEVATED" custodian/game/world/procgen/terrain/terrain_tile_ids.gd
```

---

## H. Phase 5 — Revised insertion order

Phase 5 requires modifying a real 1000+ line Godot class. The known anchors from discovery:

- `_fill_tilemaps()` is the main generation handoff.
- `_ensure_world_progress_profile()` is already called inside `_fill_tilemaps()`.
- `_apply_terrain_builder(map_size)` exists.
- `_place_faction_ambient_sites(map_size)` exists.
- `_place_story_rooms(map_size)` exists.
- `claim_procgen_floor_rect_for_authored_scene_tiles(...)` exists.
- `get_level_data()` exists.

**Do not paste snippets blindly.** Inspect the actual file, find the correct insertion point, and apply this pattern:

### Correct generation order

```
existing base procgen floor/wall generation
→ build intent graph
→ carve intent graph macro floor cells (using dictionary shape)
→ clear wall authority on intent cells (via _clear_procgen_wall_authority_at)
→ terrain builder with intent required cells
→ road/parking/compound connector enforcement
→ faction/story site placement
→ story/faction geometry reservation (via claim_procgen_floor_rect_for_authored_scene_tiles)
→ foliage/props/portals/ambient/encounters
→ streaming reveal / runtime wall collision / nav refresh
→ level-data export
```

### Implementation pattern — two hooks if needed

The roadmap specifies a single carve point. However, if later passes (roads, terrain, streaming) reintroduce wall/collision authority on reserved regions, add a **late cleanup hook** as well:

1. **Early macro carving hook** (after base generation, before terrain): creates route floor shape and clears wall authority.
2. **Late reservation cleanup hook** (after faction/story/road placement): re-clears wall/collision/elevation authority for story/faction/authored site footprints that later systems may have overwritten.

Do not let later road, wall, terrain, or streaming systems overwrite the carved intent regions.

### Safe helper for origin

Use `get_player_spawn()` directly (confirmed exists). Fallback:

```gdscript
var origin := get_player_spawn()
if origin == Vector2i.ZERO:
    origin = Vector2i(map_size.x / 2, map_size.y - 12)
```

---

## I. Phase 6 — TerrainBuilder connectivity

Phase 6 requires finding `_apply_terrain_builder()` and the existing `required_cells` logic inside `ProcGenTilemap`, then modifying TerrainBuilder without breaking connectivity validation.

### Required safety rules

- Add intent required cells to the existing required-cell set; do **not** replace it.
- Preserve existing spawn, road, compound ingress, portal, interior, and required anchor cells.
- Apply reserved region elevation **before** connectivity validation if the existing pipeline validates after feature application.
- If applying reserved elevation breaks connectivity, revert only the reserved-elevation change and report a warning.
- Do not remove existing mountain/platform fallback logic.
- Do not bypass existing TerrainBuilder connectivity checks.

### In `ProcGenTilemap` — add required cells from intent graph

Find wherever `required_cells` is built. Add:

```gdscript
if _worldgen_intent_graph != null:
    for cell in _worldgen_intent_graph.get_required_cells():
        required_cells[cell] = true
```

Add intent data to the terrain builder context:

```gdscript
    "worldgen_intent_graph": _worldgen_intent_graph,
    "worldgen_reserved_regions": _worldgen_reserved_regions,
    "worldgen_intent_floor_cells": _worldgen_intent_floor_cells,
```

### In `TerrainBuilder` — apply reserved region elevation

Add after baseline build, before the optional ascent route:

```gdscript
if context.has("worldgen_reserved_regions"):
    _apply_reserved_region_elevation(result, context.get("worldgen_reserved_regions", []))
```

### Snapshot and revert pattern

If connectivity fails, revert only the changes from this phase. Snapshot before applying:

```gdscript
var height_snapshot := result["height_by_cell"].duplicate(true)
var traversal_snapshot := result["traversal_by_cell"].duplicate(true)
var terrain_snapshot := result["terrain_type_by_cell"].duplicate(true)
var tile_snapshot := result["tile_by_cell"].duplicate(true)
var ramp_snapshot := result["ramp_dir_by_cell"].duplicate(true)
```

If connectivity fails:

```gdscript
result["height_by_cell"] = height_snapshot
result["traversal_by_cell"] = traversal_snapshot
result["terrain_type_by_cell"] = terrain_snapshot
result["tile_by_cell"] = tile_snapshot
result["ramp_dir_by_cell"] = ramp_snapshot
```

Then append a warning to the result/debug summary.

### Use current TerrainBuilder idioms

Replace any roadmap reference to `TerrainTileIds.TILE_ELEVATED_FLOOR` with:

```gdscript
TerrainTileIdsScript.industrial("elevated_floor")
```

Use existing height constants:

```gdscript
HEIGHT_GROUND
HEIGHT_ELEVATED
TRAVERSAL_WALKABLE
```

For reserved region elevation, the safer V1 behavior is:

```gdscript
var runtime_height := clampi(int(region.get("runtime_height", HEIGHT_GROUND)), HEIGHT_GROUND, HEIGHT_ELEVATED)
_set_result_cell(
    result,
    cell,
    runtime_height,
    TRAVERSAL_WALKABLE,
    TerrainType.INDUSTRIAL_PLATFORM if runtime_height > HEIGHT_GROUND else TerrainType.GROUND,
    TerrainTileIdsScript.industrial("elevated_floor") if runtime_height > HEIGHT_GROUND else NO_VISUAL_TILE
)
```

Do **not** use height `9`.

---

## J. Phase 7 — Authored-scene reservation API (confirmed viable)

Because the authored-scene reservation API already exists (all three methods confirmed), Phase 7 should **not** implement any duplicate wall-clearing logic.

The stampers should call the shared API directly:

```gdscript
claim_procgen_floor_rect_for_authored_scene_tiles(center, size, "story_room_floor", "story_room", 1)
```

That existing API already writes `_generated_floor_cells` as dictionaries and clears procgen wall authority. Required behavior for the shared API:

- claim a tile rect/footprint
- set floor visual/metadata
- clear wall TileMap cells
- clear `_generated_wall_cells`
- remove runtime wall bodies
- clear wall health
- clear foliage/large overhanging props where appropriate
- clear or reset blocking elevation metadata
- mark region metadata
- refresh runtime wall collision, overlays, shadows, and navigation

If the API does not cover all of these on the current branch, extend the API rather than duplicating partial wall-clearing logic in the stampers.

---

## K. Phase 8 — Elevation traversal (query-only)

The NavigationSystem is a simple AStar2D graph built from floor/wall tilemaps. There is no clean elevation-aware neighbor/cost abstraction in the current code.

**This pass implements query-only APIs.** Do not modify `NavigationSystem` unless a fully validated AStar edge/cost integration is implemented separately.

### Required result

```gdscript
func can_actor_move_between_tiles(from_tile: Vector2i, to_tile: Vector2i) -> bool:
    if elevation_map != null and elevation_map.has_method("can_traverse"):
        return bool(elevation_map.call("can_traverse", from_tile, to_tile))
    if _terrain_builder != nil and _terrain_builder.has_method("can_move_between"):
        return bool(_terrain_builder.call("can_move_between", from_tile, to_tile))
    return true


func get_actor_elevation_cost(from_tile: Vector2i, to_tile: Vector2i) -> float:
    if not can_actor_move_between_tiles(from_tile, to_tile):
        return INF
    var from_data := get_elevation_data_at_tile(from_tile)
    var to_data := get_elevation_data_at_tile(to_tile)
    var from_height := int(from_data.get("height", 0))
    var to_height := int(to_data.get("height", 0))
    var traversal := String(to_data.get("traversal_type", "walkable"))
    var cost := 1.0
    if to_height > from_height:
        cost += 0.35
    if traversal == "stair":
        cost += 0.2
    elif traversal == "ramp":
        cost += 0.15
    return cost
```

### Documentation requirement

Explicitly document in the task packet and CURRENT_STATE:

> Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.

Do **not** claim that elevation affects enemy navigation yet.

### If Option 2 is chosen despite this guidance

Only implement real navigation integration if `navigation_system.gd` has a clear neighbor-evaluation or path-cost function where elevation checks can be safely inserted. Required behavior:

- current map provider is resolved safely
- movement from tile A to tile B checks `can_actor_move_between_tiles`
- blocked elevation returns no neighbor / infinite cost
- stairs/ramps can add cost without making pathfinding unstable
- enemies and operator do not regress globally

---

## L. Validation

### Confirmed existing validation scripts

The following are confirmed to exist on the current branch:

- `tools/validation/procgen_intent_graph_smoke.gd`
- `tools/validation/procgen_worldgen_shape_smoke.gd`
- `tools/validation/procgen_placeholder_roads_smoke.gd`
- `tools/validation/terrain_builder_smoke.gd`
- `tools/validation/elevation_map_smoke.gd`

Additionally, these may exist if added during this pass or in prior work:

- `tools/validation/procgen_ascent_style_smoke.gd`
- `tools/validation/faction_story_sites_smoke.gd`
- `tools/validation/procgen_authored_scene_authority_smoke.gd`

### Run order

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian

godot --headless --script res://tools/validation/procgen_intent_graph_smoke.gd
godot --headless --script res://tools/validation/procgen_worldgen_shape_smoke.gd
godot --headless --script res://tools/validation/procgen_placeholder_roads_smoke.gd
godot --headless --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --script res://tools/validation/elevation_map_smoke.gd

# If additional validation scripts exist for this pass:
godot --headless --script res://tools/validation/procgen_ascent_style_smoke.gd
godot --headless --script res://tools/validation/faction_story_sites_smoke.gd
godot --headless --script res://tools/validation/procgen_authored_scene_authority_smoke.gd

godot --headless --path . --quit
```

---

## M. Working Tree Warning

The working tree is dirty on `main` before this task starts. Most current changes appear unrelated to procgen and involve operator/parry/block/inventory/fabrication assets/docs. **Do not overwrite, revert, or format unrelated files.**

Before implementing, create a branch:

```bash
git switch -c procgen-intent-graph-ascent-v1
```

Then limit edits to procgen/elevation/navigation/docs/validation files required by this task.

---

## N. Commit Plan

Implement in at least two commits to make failures easier to bisect.

### Commit 1 — Graph/export/validation only

Scope:

- intent node/edge/graph classes
- ascent spine builder
- region footprint reserver
- intent graph smoke validation
- level-data export if safe
- docs/task packet

Do not carve runtime maps yet unless the graph smoke passes.

### Commit 2 — Runtime carving/reservation integration

Scope:

- ProcGenTilemap integration
- worldgen intent floor carving (using dictionary shape)
- TerrainBuilder required-cell/reserved-region integration (using TerrainTileIdsScript)
- story/faction geometry reservation calls (using existing shared API)
- full procgen shape smoke
- docs updates

### Optional Commit 3 — Elevation traversal query/navigation

Scope:

- traversal query APIs (`can_actor_move_between_tiles`, `get_actor_elevation_cost`)
- query-only docs and CURRENT_STATE update
- validation for whichever path is chosen

---

## O. Acceptance Checklist Additions

Add these to the acceptance checklist in the roadmap:

- No new GDScript uses `nil`.
- `get_player_spawn()` is either confirmed to exist or replaced with a safe origin helper (confirmed: exists, use directly).
- `_ensure_world_progress_profile()` is either confirmed to exist or replaced with a safe profile-loading helper (confirmed: exists, use directly).
- `_generated_floor_cells` writes match the existing runtime value shape (confirmed: dictionaries).
- TerrainTileIds constant references match the actual preload/constant names (confirmed: `TerrainTileIdsScript`).
- Runtime `target_height` values respect the current ElevationMap height model (`HEIGHT_ELEVATED = 1`); `ascent_rank` is stored separately from `runtime_height`.
- Phase 7 only runs if the shared procgen authored-scene reservation API exists (confirmed: exists, use directly).
- Phase 8 is explicitly classified as query-only (this pass) — no real navigation integration claimed.
- Missing `procgen_placeholder_roads_smoke.gd` is handled gracefully (confirmed: exists, run it).
- Implementation discovery findings are recorded in the task packet.
- Working tree is clean or changes are isolated to the feature branch.
