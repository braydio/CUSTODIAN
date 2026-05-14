
## 1. Overview

The ProcGen Gameplay Feel System adds semantic intent zones, authored-feeling traversal paths, landmark staging, room identity, tactical foliage tags, destroyed-wall terrain states, and reveal-priority rules to `proc_gen_tilemap.gd`.

This document is an instructional reference for developers working on the procgen runtime. It describes system behavior, data contracts, exported controls, helper functions, and generation order. Patch details belong in `CODEX_IMPLEMENT.md`.

---

## 2. Intent Zone Registry

Intent zones are stored through `_set_region_tile(tile, region_type, zone)` and queried through `get_region_type_at_tile(tile)` and `get_region_data_at_tile(tile)`.

| Region Type | Zone / Tag | Created By | Purpose |
|---|---|---|---|
| `spawn_clearing` | `safe` | `_stamp_spawn_clearing()` | Creates a readable low-threat starting area around player spawn. |
| `soft_path` | `travel` | `_carve_soft_path()`, `_carve_generated_soft_path()` | Creates subtle traversal lanes between spawn, compound ingress, interiors, and portals. |
| `compound_approach` | `compound_ingress` | `_decorate_compound_ingress()` | Marks cleared approach tiles outside compound entrances. |
| `cover_anchor` | `compound_ingress` | `_decorate_compound_ingress()` | Marks potential cover placement positions near compound ingress points. |
| `interior_wall` | `military_complex` | `_apply_constructed_interior_region()` | Marks constructed interior wall tiles. |
| `interior_floor` | room zone name | `_carve_interior_floor_rect()` | Marks constructed interior floor tiles with room identity. |
| `interior_threshold` | `doorway` | `_carve_constructed_interior_threshold()` | Marks interior doorway and threshold tiles. |
| `exterior_threshold` | `doorway` | `_carve_constructed_interior_threshold()` | Marks exterior access tiles leading into constructed interiors. |
| `portal_plaza` | `portal` | `_stamp_portal_plaza()` | Marks authored-feeling open floor around portal landmarks. |
| `destroyed_wall_floor` | `debris` | `_set_destroyed_wall_floor_tile()` | Marks tiles where destructible walls were destroyed. |
| `foliage_cover` | `tree` / `shrub` | `_place_foliage()` | Marks foliage as tactical terrain / concealment. |

---

## 3. System Behaviors

### 3.1 Spawn Clearing

Spawn clearing creates a readable starting zone around the player spawn.

**Timing**

Runs after compound and interior generation, before wall visual application and tile-state capture.

**Pipeline slot**

```gdscript
if intent_spawn_clearing_enabled:
	_stamp_spawn_clearing(map_size)
````

**Exports consumed**

| Export                                     |       Type |          Default | Purpose                                          |
| ------------------------------------------ | ---------: | ---------------: | ------------------------------------------------ |
| `intent_spawn_clearing_enabled`            |     `bool` |           `true` | Enables spawn clearing stamp.                    |
| `intent_spawn_clearing_half_extents_tiles` | `Vector2i` | `Vector2i(5, 4)` | Controls rectangular clearing size around spawn. |

**Behavior**

* Gets spawn tile from `get_player_spawn()`.
* Converts all tiles inside the configured half-extents to floor.
* Tags stamped tiles as `spawn_clearing / safe`.
* Prevents immediate procedural clutter at player start.

**Reference**

```gdscript
_stamp_spawn_clearing(map_size)
```

---

### 3.2 Soft Paths

Soft paths create subtle travel lanes between major points of interest.

**Timing**

Runs after spawn clearing, before wall visuals and tile-state capture.

**Pipeline slot**

```gdscript
if intent_soft_paths_enabled:
	_carve_interest_paths(map_size)
```

**Exports consumed**

| Export                      |   Type | Default | Purpose                                |
| --------------------------- | -----: | ------: | -------------------------------------- |
| `intent_soft_paths_enabled` | `bool` |  `true` | Enables soft path carving.             |
| `intent_soft_path_width`    |  `int` |     `1` | Brush radius used while carving paths. |

**Path sources**

Soft paths are carved from player spawn to:

* compound ingress tiles
* constructed interior threshold tiles
* portal plaza tiles after portal placement

**Behavior**

* Uses Manhattan-style carving.
* Ignores indoor tiles.
* Avoids replacing active wall cells in the normal generation path.
* Tags carved tiles as `soft_path / travel`.

**References**

```gdscript
_carve_interest_paths(map_size)
_carve_soft_path(from_tile, to_tile, width, map_size)
_carve_path_brush(center, width, map_size)
_carve_generated_soft_path(from_tile, to_tile, width, map_size)
_carve_generated_path_brush(center, width, map_size)
```

---

### 3.3 Portal Plazas

Portal plazas make portal endpoints feel authored and visible.

**Timing**

Runs inside `_configure_portal_pair()` after each portal endpoint tile is resolved.

**Exports consumed**

| Export                                   |       Type |          Default | Purpose                                 |
| ---------------------------------------- | ---------: | ---------------: | --------------------------------------- |
| `intent_portal_plazas_enabled`           |     `bool` |           `true` | Enables portal plaza stamping.          |
| `intent_portal_plaza_half_extents_tiles` | `Vector2i` | `Vector2i(3, 2)` | Controls portal plaza floor stamp size. |

**Behavior**

* Stamps floor around each resolved portal tile.
* Tags stamped tiles as `portal_plaza / portal`.
* Removes foliage from plaza tiles.
* Updates `_generated_floor_cells` and `_generated_wall_cells` so streaming reveal remains consistent.

**Reference**

```gdscript
_stamp_portal_plaza(center, map_size)
_set_floor_tile_and_generated_state(pos, "portal_plaza", "portal")
```

---

### 3.4 Portal Commitment and Arrival

Portal teleporters should feel intentional, not accidental.

**Recommended defaults**

| Export                                   | Recommended Value | Purpose                                               |
| ---------------------------------------- | ----------------: | ----------------------------------------------------- |
| `portal_teleport_cooldown_frames`        |              `60` | Prevents immediate bounce-back.                       |
| `portal_trigger_radius`                  |            `12.0` | Requires closer commitment to portal center.          |
| `portal_arrival_animation_delay_seconds` |            `0.50` | Keeps arrival responsive while preserving FX staging. |
| `portal_arrival_offset`                  |  `Vector2(0, 54)` | Places player outside destination trigger.            |

**Platform portal behavior**

When `portal_definition.portal_platform_enabled` is true:

* Teleporter is positioned at `portal_platform_trigger_offset`.
* Ramp bottom is derived from `portal_platform_bottom_offset - portal_platform_trigger_offset`.
* `arrival_offset` is set to the ramp bottom offset, not `Vector2.ZERO`.
* Teleport requires ramp elevation.
* Body must still be in the trigger at teleport frame.
* Body velocity is stopped on arrival.

**Required property mapping**

```gdscript
teleporter.set("ramp_side_block_extra_height", portal_definition.portal_platform_side_block_height)
```

Do not use:

```gdscript
teleporter.set("ramp_side_block_height", portal_definition.portal_platform_side_block_height)
```

unless `PortalTeleporter.gd` keeps that property as a compatibility alias.

**Reference**

```gdscript
_attach_portal_teleporter(prop)
```

---

### 3.5 Interior Room Zones

Interior rooms receive semantic identity tags for downstream prop, enemy, loot, and ambience systems.

**Room zone roster**

```txt
storage
security
maintenance
archive
generator
barracks
lab
warehouse_bay
hallway
```

**Timing**

Assigned during constructed interior generation.

**Behavior**

* `_pick_room_zone(room, room_index)` assigns a deterministic room zone using `_tile_noise_hash()`.
* `_carve_interior_floor_rect(room, zone)` stamps room floors using the selected zone.
* Interior prop nodes receive `region_zone` metadata from the tile’s region data.

**References**

```gdscript
_pick_room_zone(room, room_index)
_carve_interior_floor_rect(rect, zone)
get_region_data_at_tile(tile)
```

**Interior prop metadata**

Interior props should store:

```gdscript
sprite.set_meta("source_tile", pos)
sprite.set_meta("region_zone", String(get_region_data_at_tile(pos).get("zone", "room")))
```

---

### 3.6 Compound Ingress Decoration

Compound ingress points should feel like threshold encounter spaces.

**Timing**

Runs inside `_apply_compound_layout()` immediately after `_carve_compound_ingress()`.

**Export consumed**

| Export                             |   Type | Default | Purpose                                            |
| ---------------------------------- | -----: | ------: | -------------------------------------------------- |
| `intent_decorate_compound_ingress` | `bool` |  `true` | Enables ingress approach and cover-anchor tagging. |

**Behavior**

For each ingress:

* Clears several tiles outside the wall.
* Tags outside approach tiles as `compound_approach / compound_ingress`.
* Tags side anchor tiles as `cover_anchor / compound_ingress`.

**Reference**

```gdscript
_decorate_compound_ingress(ingress, rect)
```

---

### 3.7 Foliage as Tactical Cover

Foliage can act as tactical terrain instead of only decoration.

**Export consumed**

| Export                      |   Type | Default | Purpose                         |
| --------------------------- | -----: | ------: | ------------------------------- |
| `intent_mark_foliage_cover` | `bool` |  `true` | Enables foliage region tagging. |

**Behavior**

When foliage is placed on an exterior tile:

* Tile is tagged as `foliage_cover`.
* Zone is set to the foliage kind: `tree` or `shrub`.
* Removing foliage clears the `foliage_cover` region tag.

**References**

```gdscript
_place_foliage(pos)
_remove_foliage(pos)
_classify_foliage(foliage_size)
```

---

### 3.8 Destroyed Wall Floor

Destroyed walls become semantic terrain instead of generic floor.

**Timing**

Runs inside `damage_wall_tile()` when wall health reaches zero.

**Behavior**

* Removes wall from `_generated_wall_cells`.
* Adds floor state to `_generated_floor_cells`.
* Sets visible floor tile.
* Erases wall tile.
* Tags tile as `destroyed_wall_floor / debris`.
* Emits minimap update using `destroyed_wall_floor`.

**Reference**

```gdscript
_set_destroyed_wall_floor_tile(pos)
```

**Signal terrain kind**

```gdscript
minimap_tile_changed.emit(pos, "destroyed_wall_floor")
```

---

### 3.9 Interest-Biased Streaming Reveal

Streaming reveal prioritizes semantically important tiles.

**Timing**

Runs when chunks are queued for reveal.

**Behavior**

`_queue_chunk_for_reveal()` sorts chunk tiles using `_streaming_reveal_priority(tile, center_tile)`.

Lower score reveals earlier.

**Priority modifiers**

| Region Type            | Score Delta | Effect                                                           |
| ---------------------- | ----------: | ---------------------------------------------------------------- |
| `spawn_clearing`       |      `-240` | Reveals safe start fastest.                                      |
| `portal_plaza`         |      `-220` | Reveals portal landmarks early.                                  |
| `compound_approach`    |      `-180` | Reveals compound approaches early.                               |
| `compound_ingress`     |      `-160` | Reveals ingress points early.                                    |
| `interior_threshold`   |      `-140` | Reveals doorways early.                                          |
| `soft_path`            |      `-120` | Reveals travel lanes early.                                      |
| `interior_floor`       |       `-80` | Reveals interior floor moderately early.                         |
| `destroyed_wall_floor` |       `-60` | Reveals changed terrain slightly early.                          |
| `foliage_cover`        |       `+30` | Reveals foliage cover slightly later.                            |
| generated wall cell    |       `+12` | Slightly delays wall reveal compared to critical floor features. |

**References**

```gdscript
_queue_chunk_for_reveal(chunk_pos, center_tile)
_streaming_reveal_priority(tile, center_tile)
```

---

### 3.10 Encounter Intensity API

`get_intensity_at_tile(tile)` provides a normalized intensity value for downstream systems.

**Consumers**

* enemy spawners
* loot placement
* hazard placement
* ambient audio
* minimap effects
* lighting profile systems
* combat director systems

**Formula**

Base intensity is distance from player spawn divided by map diagonal length.

Region modifiers then adjust the value.

**Region modifiers**

| Region Type            | Modifier |
| ---------------------- | -------: |
| `spawn_clearing`       |  `-0.35` |
| `soft_path`            |  `-0.10` |
| `compound_approach`    |  `+0.08` |
| `cover_anchor`         |  `+0.10` |
| `interior_threshold`   |  `+0.15` |
| `interior_floor`       |  `+0.22` |
| `portal_plaza`         |  `+0.30` |
| `destroyed_wall_floor` |  `+0.12` |
| `foliage_cover`        |  `+0.05` |

Additional modifiers:

| Condition                 | Modifier |
| ------------------------- | -------: |
| Tile inside compound rect |  `+0.08` |
| Tile inside interior rect |  `+0.12` |

**Reference**

```gdscript
get_intensity_at_tile(tile)
```

---

## 4. Exports Reference

These exports belong under:

```gdscript
@export_group("Gameplay Feel / Intent Zones", "intent")
```

| Export                                     |       Type |          Default | Description                                                 |
| ------------------------------------------ | ---------: | ---------------: | ----------------------------------------------------------- |
| `intent_spawn_clearing_enabled`            |     `bool` |           `true` | Enables spawn clearing around player start.                 |
| `intent_spawn_clearing_half_extents_tiles` | `Vector2i` | `Vector2i(5, 4)` | Half-size of spawn clearing rectangle.                      |
| `intent_soft_paths_enabled`                |     `bool` |           `true` | Enables path carving between major interest points.         |
| `intent_soft_path_width`                   |      `int` |              `1` | Brush radius for soft paths.                                |
| `intent_portal_plazas_enabled`             |     `bool` |           `true` | Enables portal plaza stamping.                              |
| `intent_portal_plaza_half_extents_tiles`   | `Vector2i` | `Vector2i(3, 2)` | Half-size of portal plaza rectangle.                        |
| `intent_mark_foliage_cover`                |     `bool` |           `true` | Enables foliage tactical cover tags.                        |
| `intent_decorate_compound_ingress`         |     `bool` |           `true` | Enables compound ingress approach and cover-anchor tagging. |

---

## 5. Helper Function Index

| Function                                                          | Purpose                                                                     |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `_is_tile_inside_map(tile, map_size, margin)`                     | Bounds-checks a tile against map dimensions.                                |
| `_stamp_spawn_clearing(map_size)`                                 | Converts spawn-adjacent tiles to safe floor.                                |
| `_carve_interest_paths(map_size)`                                 | Carves soft paths from spawn to compound ingress and interior thresholds.   |
| `_carve_soft_path(from_tile, to_tile, width, map_size)`           | Carves a Manhattan path through current tilemap state.                      |
| `_carve_path_brush(center, width, map_size)`                      | Applies floor/region tags for normal soft path carving.                     |
| `_decorate_compound_ingress(ingress, rect)`                       | Clears and tags approach/cover-anchor tiles around ingress.                 |
| `_pick_room_zone(room, room_index)`                               | Assigns deterministic room identity.                                        |
| `_is_tile_currently_visible(tile)`                                | Checks whether a tile is currently revealed under streaming mode.           |
| `_set_floor_tile_and_generated_state(pos, region_type, zone)`     | Updates generated floor state and visible floor tile if currently revealed. |
| `_stamp_portal_plaza(center, map_size)`                           | Stamps portal plaza floor and removes foliage.                              |
| `_carve_generated_soft_path(from_tile, to_tile, width, map_size)` | Carves paths after generated tile state has already been captured.          |
| `_carve_generated_path_brush(center, width, map_size)`            | Updates generated floor state for late-stage path carving.                  |
| `_set_destroyed_wall_floor_tile(pos)`                             | Converts destroyed wall tile into semantic debris floor.                    |
| `_streaming_reveal_priority(tile, center_tile)`                   | Scores streaming reveal priority for chunk tile sorting.                    |
| `get_intensity_at_tile(tile)`                                     | Returns normalized encounter intensity for downstream systems.              |

---

## 6. Fixes and Cleanup

The implementation patch set also performs these cleanup fixes.

### 6.1 Tile center alignment

`_tile_to_world_position()` returns the TileMap cell center from `map_to_local()` directly.

Do not add `tile_size * 0.5`.

Correct behavior:

```gdscript
return floor_tilemap.to_global(floor_tilemap.map_to_local(pos))
```

---

### 6.2 Foliage occlusion bubble activation

`_apply_foliage_occlusion_material()` must set:

```gdscript
bubble_enabled = bubble_count > 0
```

Do not permanently set `bubble_enabled` to `false`.

---

### 6.3 Runtime wall collision cleanup

When regenerating the map with `clear_first`, also call:

```gdscript
_clear_runtime_wall_collision()
_rebuild_runtime_wall_collision_debug()
```

This prevents stale invisible wall collision after regeneration.

---

### 6.4 Interior loop indentation

Interior wall and floor carving loops use normal one-tab indentation inside nested loops.

Target structure:

```gdscript
for x in range(...):
	for y in range(...):
		var tile := Vector2i(x, y)
		...
```

---

### 6.5 Wall neighbor refresh state preservation

`_refresh_wall_neighbors()` updates both:

* visible wall tilemap cell
* `_generated_wall_cells` backing state

This prevents streaming reloads from restoring stale neighbor visuals.

---

### 6.6 Navigation rebuild fallback

`_flush_navigation_rebuild()` first tries nodes in group `"navigation"` with a `rebuild()` method.

If no rebuild method is called, it falls back to:

```gdscript
nav_region.bake_navigation_polygon(false)
```

---

## 7. Generation Pipeline Order

Generation order for the gameplay feel system:

1. Base procgen fills wall/floor grid.
2. Compound layout applies.
3. Compound ingress is carved.
4. Compound ingress decoration runs.
5. Constructed interior region applies.
6. Interior room zones are assigned.
7. Spawn clearing stamp runs.
8. Soft path carving runs.
9. Wall visuals apply.
10. Generated tile state is captured.
11. Streaming reveal is prepared, or runtime wall collision is built.
12. Ruin props spawn.
13. Portal props are resolved.
14. Portal plazas are stamped.
15. Portal paths are carved into generated state.
16. Portal teleporters are attached and linked.
17. Interior props spawn.
18. Foliage spawns or streams in.
19. Foliage cover tags are assigned.
20. Navigation and shadows refresh.

---

## 8. Cross-System Contract

### 8.1 Minimap

`minimap_tile_changed` may emit new terrain kinds.

Known new terrain kind:

```txt
destroyed_wall_floor
```

Future minimap systems may also query region data directly.

---

### 8.2 Navigation

Wall destruction and streaming reveal call navigation refresh helpers.

Navigation consumers should expect deferred rebuild behavior.

Fallback path:

```gdscript
nav_region.bake_navigation_polygon(false)
```

---

### 8.3 Enemy Spawning

Enemy spawners should use:

```gdscript
get_intensity_at_tile(tile)
get_region_type_at_tile(tile)
get_region_data_at_tile(tile)
```

Recommended interpretation:

| Intensity Range | Meaning                                   |
| --------------: | ----------------------------------------- |
|     `0.00–0.25` | Safe / low pressure                       |
|     `0.25–0.50` | Light encounter space                     |
|     `0.50–0.75` | Standard combat space                     |
|     `0.75–1.00` | High-pressure landmark or objective space |

---

### 8.4 Loot and Resource Placement

Loot systems should prefer:

* `interior_floor` zones with room identities
* `portal_plaza` for rare landmark rewards
* `destroyed_wall_floor` for break-through rewards
* `compound_approach` for low-tier combat pickups
* `spawn_clearing` only for tutorial or starter resources

---

### 8.5 Hazards

Hazard systems should avoid:

* `spawn_clearing`
* immediate `soft_path` tiles near spawn

Hazard systems may prefer:

* `interior_threshold`
* `interior_floor`
* `portal_plaza`
* high-intensity tiles

---

### 8.6 Audio and Ambience

Audio systems may use region types for ambience switching.

Examples:

| Region Type         | Audio Use                              |
| ------------------- | -------------------------------------- |
| `spawn_clearing`    | Low tension ambient bed                |
| `soft_path`         | Exploration bed                        |
| `compound_approach` | Distant mechanical / military ambience |
| `interior_floor`    | Interior room tone                     |
| `portal_plaza`      | Portal hum / anomaly tone              |
| `foliage_cover`     | Leaf rustle / muffled movement         |

---

### 8.7 AI Context Docs

After implementation, update:

```txt
custodian/docs/ai_context/CURRENT_STATE.md
```

Required note:

```txt
Procgen now emits semantic intent zones for gameplay feel:
spawn_clearing, soft_path, compound_approach, cover_anchor, portal_plaza,
foliage_cover, destroyed_wall_floor, and interior room zones. Downstream
systems should consume get_region_type_at_tile(), get_region_data_at_tile(),
and get_intensity_at_tile() instead of inferring gameplay meaning from raw
floor/wall state alone.
```

---

## 9. Non-Goals

This instruction reference does not contain full patch blocks.

Full implementation diffs belong in:

```txt
CODEX_IMPLEMENT.md
```

This file should remain a quick reference for:

* system behavior
* function purpose
* exports
* region contracts
* generation order
* cross-system integration rules

```
