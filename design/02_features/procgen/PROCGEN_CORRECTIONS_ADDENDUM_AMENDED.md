# THIS IS THE FINAL PROCGEN ROADMAP CORRECTIONS FILE.

Got it. This hardening pack actually resolves several of the earlier unknowns. The roadmap is now safer, and some of the addendum warnings can be converted from “verify this” to “confirmed; implement like this.”

## Key findings from the attached discovery output

The important uncertainties are now mostly resolved:

| Issue                              | Actual finding                                                                                                                                                | Roadmap impact                                                                                                        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `get_player_spawn()`               | **Exists** in `proc_gen_tilemap.gd` at line `5348`; it is already used many times.                                                                            | Do **not** add a fallback helper unless Codex finds a branch mismatch. Use existing `get_player_spawn()`.             |
| `_ensure_world_progress_profile()` | **Exists** at line `2502`; `_fill_tilemaps()` already calls it around line `571`.                                                                             | Do **not** add a duplicate loader helper. Use existing method.                                                        |
| Authored-scene reservation API     | **Exists**: `claim_procgen_floor_rect_for_authored_scene_world`, `claim_procgen_floor_rect_for_authored_scene_tiles`, and `_clear_procgen_wall_authority_at`. | Phase 7 can use the shared reservation API directly. No need to invent it.                                            |
| `_generated_floor_cells` shape     | Confirmed as **Dictionary entries**, not booleans. Existing code reads values as `Dictionary` at line `4782`.                                                 | Roadmap must not use `_generated_floor_cells[tile] = true`. It must preserve dictionary shape.                        |
| Road smoke file                    | `procgen_placeholder_roads_smoke.gd` **exists**.                                                                                                              | Keep it in validation. Do not skip it.                                                                                |
| TerrainBuilder tile IDs            | Uses `TerrainTileIdsScript`, not `TerrainTileIds`.                                                                                                            | Use `TerrainTileIdsScript.industrial("elevated_floor")`, not `TerrainTileIds.TILE_ELEVATED_FLOOR`.                    |
| Runtime height model               | TerrainBuilder currently defines `HEIGHT_DROP = -1`, `HEIGHT_GROUND = 0`, `HEIGHT_ELEVATED = 1`.                                                              | Do not push `target_height = 9` into runtime elevation. Store ascent rank separately or clamp to `0..1`.              |
| Navigation system                  | AStar2D graph over floor/wall TileMaps; no obvious elevation-cost integration currently.                                                                      | Phase 8 should be **query-only** unless Codex explicitly designs and validates AStar edge filtering/cost integration. |

These findings are directly visible in the discovery output: `get_player_spawn()`, `_ensure_world_progress_profile()`, the authored-scene claim API, terrain-builder integration points, and `get_level_data()` are all present in `proc_gen_tilemap.gd`; TerrainBuilder uses `TerrainTileIdsScript`, `HEIGHT_DROP/GROUND/ELEVATED`, and connectivity validation; `procgen_placeholder_roads_smoke.gd` exists.

Also note: your working tree is dirty on `main`, mostly because of operator/parry/block/inventory/fabrication-related work, plus a new `design/02_features/procgen/PROCGEN_CORRECTIONS.md`. That means Codex should branch before touching worldgen.

---

# Hardened corrections to apply to the roadmap

## 1. Add this before Phase 0

```markdown id="tzw37z"
## Implementation Discovery Results

The hardening context confirms several previously ambiguous assumptions:

- `ProcGenTilemap.get_player_spawn()` exists and should be used directly.
- `ProcGenTilemap._ensure_world_progress_profile()` exists and should be used directly.
- The authored-scene reservation API already exists:
  - `claim_procgen_floor_rect_for_authored_scene_world(...)`
  - `claim_procgen_floor_rect_for_authored_scene_tiles(...)`
  - `_clear_procgen_wall_authority_at(...)`
- `_generated_floor_cells` stores dictionary values. Do not write booleans into it.
- `procgen_placeholder_roads_smoke.gd` exists and must remain part of validation.
- `TerrainBuilder` uses `TerrainTileIdsScript`, not a bare `TerrainTileIds` symbol.
- Runtime terrain height currently supports `HEIGHT_DROP = -1`, `HEIGHT_GROUND = 0`, and `HEIGHT_ELEVATED = 1`. Store long-range ascent pressure as `ascent_rank`; do not write height `9` into runtime terrain/elevation.
- `NavigationSystem` is currently AStar2D over floor/wall tilemaps. Phase 8 is query-only unless a real AStar edge/cost integration is implemented and validated.
```

## 2. Replace the roadmap’s `target_height` model

Use this in `WorldgenIntentNode`:

```gdscript id="f84mh9"
var runtime_height: int = 0
var ascent_rank: int = 0
```

And update `to_dictionary()`:

```gdscript id="4gr3pb"
"runtime_height": runtime_height,
"ascent_rank": ascent_rank,
```

In `AscentSpineBuilder`, replace:

```gdscript id="hix3qm"
int(round(t * 9.0))
```

with:

```gdscript id="7erskv"
var ascent_rank := int(round(t * 9.0))
var runtime_height := clampi(int(floor(float(ascent_rank) / 5.0)), 0, 1)
```

Then pass both into `_make_node(...)`.

Reason: current TerrainBuilder runtime height model is basically `-1/0/1`, with elevated platform using `HEIGHT_ELEVATED = 1`; height `9` is not runtime-safe.

## 3. Replace `_generated_floor_cells[tile] = true`

Use dictionary shape:

```gdscript id="7sp9pm"
var source_id := _select_floor_source_id(tile)
var atlas := _select_floor_coord(tile)

_generated_floor_cells[tile] = {
	"source_id": source_id,
	"atlas": atlas,
	"alternative": 0,
	"authority": "worldgen_intent",
}
```

Reason: existing code reads `_generated_floor_cells[tile]` as `Dictionary`, so booleans would be unsafe.

## 4. Phase 5 insertion should target the real order

Discovery shows `_fill_tilemaps()` is the main hook, with `_ensure_world_progress_profile()` already called early. It also shows faction/story placement happens around `_place_faction_ambient_sites(map_size)` and `_place_story_rooms(map_size)`, while `_apply_terrain_builder(map_size)` exists separately.

So replace the roadmap’s vague insertion instruction with this:

```markdown id="536ijl"
### Phase 5 revised insertion order

Patch `custodian/game/world/procgen/proc_gen_tilemap.gd`.

Known anchors from discovery:

- `_fill_tilemaps()` exists.
- `_ensure_world_progress_profile()` already exists and is called inside `_fill_tilemaps()`.
- `_apply_terrain_builder(map_size)` exists.
- `_place_faction_ambient_sites(map_size)` exists.
- `_place_story_rooms(map_size)` exists.
- `claim_procgen_floor_rect_for_authored_scene_tiles(...)` exists.
- `get_level_data()` exists.

Insert the intent-graph build after base floor/wall generation has populated `_generated_floor_cells` / `_generated_wall_cells`, but before terrain/faction/story/props depend on the generated shape.

Do not move existing `_ensure_world_progress_profile()`; reuse it.

Required integration pattern:

1. Base procgen populates `_generated_floor_cells` and `_generated_wall_cells`.
2. Build `WorldgenIntentGraph`.
3. Apply intent floor reservations using existing floor-cell dictionary shape.
4. Clear procgen wall authority using `_clear_procgen_wall_authority_at(...)`.
5. Run terrain builder with intent required cells.
6. Run roads/compound connector enforcement.
7. Run faction/story site placement.
8. Run story/faction reservation stampers through `claim_procgen_floor_rect_for_authored_scene_tiles(...)`.
9. Refresh runtime wall collision/overlays/navigation after final authority changes.

If later systems reintroduce wall authority, add a late cleanup pass for intent/faction/story reserved regions.
```

## 5. Phase 6 should use current TerrainBuilder idioms

Replace any direct `TerrainTileIds.TILE_ELEVATED_FLOOR` reference with:

```gdscript id="7l9en5"
TerrainTileIdsScript.industrial("elevated_floor")
```

Use existing height constants:

```gdscript id="z9d5kk"
HEIGHT_GROUND
HEIGHT_ELEVATED
TRAVERSAL_WALKABLE
```

For reserved region elevation, the safer V1 behavior is:

```gdscript id="fy8krl"
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

## 6. Phase 7 is now confirmed viable

Because the authored-scene reservation API already exists, Phase 7 should not implement any duplicate wall-clearing logic. It should just call:

```gdscript id="0x59n1"
claim_procgen_floor_rect_for_authored_scene_tiles(...)
```

That existing API already appears to write `_generated_floor_cells` as dictionaries and clear procgen wall authority.

## 7. Phase 8 should be query-only for now

The NavigationSystem is currently a simple AStar2D graph built from floor/wall tilemaps with `_walkable_tiles`; discovery does not show a clean elevation-aware neighbor/cost abstraction.

So harden Phase 8 to this:

```markdown id="zehudl"
## Phase 8 revised scope — query-only

Implement map-level elevation traversal query APIs only.

Do not modify `NavigationSystem` in this pass unless Codex adds a fully validated AStar edge/cost integration.

Required result:

- `ProcGenTilemap.can_actor_move_between_tiles(from_tile, to_tile) -> bool`
- `ProcGenTilemap.get_actor_elevation_cost(from_tile, to_tile) -> float`

Explicitly document:

> Elevation traversal query API is live; actor/enemy pathfinding enforcement is deferred.

Do not claim that elevation affects enemy navigation yet.
```

## 8. Validation list can now include roads smoke

Since `procgen_placeholder_roads_smoke.gd` exists, keep it:

```bash id="z01njd"
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian

godot --headless --script res://tools/validation/procgen_intent_graph_smoke.gd
godot --headless --script res://tools/validation/procgen_worldgen_shape_smoke.gd
godot --headless --script res://tools/validation/procgen_placeholder_roads_smoke.gd
godot --headless --script res://tools/validation/procgen_ascent_style_smoke.gd
godot --headless --script res://tools/validation/faction_story_sites_smoke.gd
godot --headless --script res://tools/validation/procgen_authored_scene_authority_smoke.gd
godot --headless --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --script res://tools/validation/elevation_map_smoke.gd
godot --headless --path . --quit
```

## 9. Add this warning to Codex because your tree is dirty

````markdown id="ohrw6y"
## Working Tree Warning

The working tree is dirty on `main` before this task starts. Most current changes appear unrelated to procgen and involve operator/parry/block/inventory/fabrication assets/docs. Do not overwrite, revert, or format unrelated files.

Before implementing, create a branch:

```bash
git switch -c procgen-intent-graph-ascent-v1
```
````

Then limit edits to procgen/elevation/navigation/docs/validation files required by this task.

```

---

## My conclusion

This pack mostly **confirms the roadmap is viable**, but the correct hardened version should be less speculative:

- no fake fallback needed for `get_player_spawn()`
- no fake fallback needed for `_ensure_world_progress_profile()`
- no `nil`
- no boolean `_generated_floor_cells`
- no `TerrainTileIds.TILE_ELEVATED_FLOOR`
- no height `9` in runtime elevation
- no NavigationSystem integration claim unless actually implemented
- keep road smoke validation because it exists

The next thing I would send Codex is the roadmap plus this hardening section.
```
