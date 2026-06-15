Below is a **paste-ready Codex instructional**. It is written as an implementation task, not just a design brainstorm.

The plan assumes the current repo state from your packed context: active runtime is Godot under `custodian/`, active procgen/elevation files include `proc_gen_tilemap.gd`, `terrain_builder.gd`, `terrain_region.gd`, and `elevation_map.gd`; terrain/elevation is already metadata-first; and enemy behavior already has an opt-in finite state machine with blackboard/perception/objective components. fileciteturn2file0

```text
Task: Implement distance-based procgen world-style transition, uphill ascent terrain, faction ambient activity metadata, and first-pass environmental storytelling room placement.

You are working in the CUSTODIAN repo.

Goal:
The generated world should gradually transition after distance from the spawn/origin:
1. from cave-like labyrinth rooms/corridors
2. into broken foothills
3. into an increasingly uphill mountain slog
4. into faction-marked ridges, camps, worksites, and environmental storytelling rooms.

This is not a tileset swap. Implement this as metadata-first world progression:
- distance band
- elevation bias
- ascent route metadata
- terrain style metadata
- faction presence metadata
- ambient activity anchors
- story room placement metadata

Use existing visual assets/placeholders where possible. Do not block on production art.
Do not rewrite the whole procgen generator.
Do not rewrite pathfinding.
Keep deterministic behavior.
Keep simulation metadata separate from rendering.

Important current architecture:
- `ProcGenTilemap` owns procgen world handoff, terrain builder integration, level-data export, elevation-map ownership, region metadata, props, roads, interiors, foliage, minimap data, and streaming reveal.
- `TerrainBuilder` is already the metadata-first terrain/elevation pass.
- `ElevationMap` already stores height/traversal metadata.
- `TerrainRegion` currently only models baseline/mountain/chasm/industrial platform and needs expansion.
- Enemy behavior already has `EnemyBehaviorStateMachine`, `EnemyBlackboard`, `EnemyBehaviorProfile`, perception, objective sensor, and loot carrier components.
- Current elevation does not yet enforce full operator/vehicle/enemy path traversal. Keep that deferred unless explicitly trivial.
```

---

# 0. Start with repo status and context

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

git status --short

sed -n '1,220p' AGENTS.md
sed -n '1,240p' custodian/AGENTS.md
sed -n '1,220p' custodian/docs/ai_context/CONTEXT.md
sed -n '1,260p' custodian/docs/ai_context/CURRENT_STATE.md
sed -n '1,220p' custodian/docs/ai_context/FILE_INDEX.md
```

Create the task packet first:

```text
custodian/docs/ai_context/task_packets/PROCGEN_ASCENT_STYLE_FACTION_STORY_V1.md
```

Use status `active`.

Also create the design spec first:

```text
design/02_features/procgen/WORLD_ASCENT_STYLE_TRANSITION.md
```

The spec must say:

```text
Implementation status: planned / active
Primary runtime files:
- custodian/game/world/procgen/proc_gen_tilemap.gd
- custodian/game/world/procgen/terrain/terrain_builder.gd
- custodian/game/world/procgen/terrain/terrain_region.gd
- custodian/game/world/elevation/elevation_map.gd
- custodian/game/actors/enemies/enemy_behavior_state_machine.gd
- custodian/game/actors/enemies/components/enemy_blackboard.gd
- custodian/game/actors/enemies/components/enemy_behavior_profile.gd

Design rule:
World progression is not a hard biome swap. It is a deterministic blend of distance band, elevation pressure, terrain grammar, faction ambient presence, and story-room insertion.
```

---

# 1. Add world progression profile data

Create:

```text
custodian/content/procgen/world_profiles/sundered_keep_ascent.json
```

```json
{
  "id": "sundered_keep_ascent",
  "origin_cell": [0, 0],
  "blend_width_tiles": 32,
  "bands": [
    {
      "id": "labyrinth_lowlands",
      "distance_min": 0,
      "distance_max": 120,
      "height_bias": 0,
      "ascent_gain": 0,
      "style_weights": {
        "cave_corridor": 0.65,
        "ruined_room": 0.25,
        "shore_cut": 0.1
      },
      "faction_presence": {
        "iconoclast": 0.05,
        "cult_mechanist": 0.08,
        "scavenger": 0.12
      },
      "story_room_chance": 0.04
    },
    {
      "id": "broken_foothills",
      "distance_min": 120,
      "distance_max": 240,
      "height_bias": 2,
      "ascent_gain": 3,
      "style_weights": {
        "cave_corridor": 0.25,
        "ravine_path": 0.25,
        "switchback": 0.25,
        "ruined_terrace": 0.25
      },
      "faction_presence": {
        "iconoclast": 0.15,
        "cult_mechanist": 0.2,
        "scavenger": 0.25
      },
      "story_room_chance": 0.1
    },
    {
      "id": "slog_ascent",
      "distance_min": 240,
      "distance_max": 480,
      "height_bias": 5,
      "ascent_gain": 6,
      "style_weights": {
        "switchback": 0.35,
        "ridge_trail": 0.3,
        "collapsed_keep_exterior": 0.2,
        "faction_worksite": 0.15
      },
      "faction_presence": {
        "iconoclast": 0.3,
        "cult_mechanist": 0.35,
        "scavenger": 0.25
      },
      "story_room_chance": 0.18
    },
    {
      "id": "upper_exhaustion",
      "distance_min": 480,
      "distance_max": 99999,
      "height_bias": 9,
      "ascent_gain": 9,
      "style_weights": {
        "ridge_trail": 0.3,
        "wind_cut_stair": 0.25,
        "ruined_observatory": 0.2,
        "faction_encampment": 0.25
      },
      "faction_presence": {
        "iconoclast": 0.35,
        "cult_mechanist": 0.45,
        "scavenger": 0.2
      },
      "story_room_chance": 0.24
    }
  ]
}
```

---

# 2. Add world style profile scripts

Create:

```text
custodian/game/world/procgen/progression/world_style_band.gd
```

```gdscript
extends RefCounted
class_name WorldStyleBand

var id: String = "baseline"
var distance_min: int = 0
var distance_max: int = 999999
var height_bias: int = 0
var ascent_gain: int = 0
var style_weights: Dictionary = {}
var faction_presence: Dictionary = {}
var story_room_chance: float = 0.0


static func from_dictionary(data: Dictionary) -> WorldStyleBand:
	var band := WorldStyleBand.new()
	band.id = String(data.get("id", band.id))
	band.distance_min = int(data.get("distance_min", band.distance_min))
	band.distance_max = int(data.get("distance_max", band.distance_max))
	band.height_bias = int(data.get("height_bias", band.height_bias))
	band.ascent_gain = int(data.get("ascent_gain", band.ascent_gain))
	band.style_weights = (data.get("style_weights", {}) as Dictionary).duplicate(true)
	band.faction_presence = (data.get("faction_presence", {}) as Dictionary).duplicate(true)
	band.story_room_chance = float(data.get("story_room_chance", band.story_room_chance))
	return band


func contains_distance(distance_tiles: float) -> bool:
	return distance_tiles >= float(distance_min) and distance_tiles < float(distance_max)


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"distance_min": distance_min,
		"distance_max": distance_max,
		"height_bias": height_bias,
		"ascent_gain": ascent_gain,
		"style_weights": style_weights.duplicate(true),
		"faction_presence": faction_presence.duplicate(true),
		"story_room_chance": story_room_chance,
	}
```

Create:

```text
custodian/game/world/procgen/progression/world_progress_profile.gd
```

```gdscript
extends RefCounted
class_name WorldProgressProfile

const WorldStyleBandScript := preload("res://game/world/procgen/progression/world_style_band.gd")

var profile_id: String = "default"
var origin_cell: Vector2i = Vector2i.ZERO
var blend_width_tiles: int = 32
var bands: Array[WorldStyleBand] = []


static func load_from_path(path: String) -> WorldProgressProfile:
	var profile := WorldProgressProfile.new()
	if not FileAccess.file_exists(path):
		push_warning("WorldProgressProfile: missing profile at %s; using fallback." % path)
		profile.bands.append(WorldStyleBandScript.new())
		return profile

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("WorldProgressProfile: could not open profile at %s; using fallback." % path)
		profile.bands.append(WorldStyleBandScript.new())
		return profile

	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("WorldProgressProfile: invalid JSON at %s; using fallback." % path)
		profile.bands.append(WorldStyleBandScript.new())
		return profile

	var data := parsed as Dictionary
	profile.profile_id = String(data.get("id", profile.profile_id))
	var origin_value = data.get("origin_cell", [0, 0])
	if origin_value is Array and origin_value.size() >= 2:
		profile.origin_cell = Vector2i(int(origin_value[0]), int(origin_value[1]))
	profile.blend_width_tiles = int(data.get("blend_width_tiles", profile.blend_width_tiles))

	var raw_bands: Array = data.get("bands", [])
	for raw_band in raw_bands:
		if raw_band is Dictionary:
			profile.bands.append(WorldStyleBandScript.from_dictionary(raw_band))
	if profile.bands.is_empty():
		profile.bands.append(WorldStyleBandScript.new())
	return profile


func get_distance_tiles(cell: Vector2i) -> float:
	return float(cell.distance_to(origin_cell))


func get_band_for_distance(distance_tiles: float) -> WorldStyleBand:
	for band in bands:
		if band.contains_distance(distance_tiles):
			return band
	return bands.back()


func get_cell_progress(cell: Vector2i, seed: int = 0) -> Dictionary:
	var distance_tiles := get_distance_tiles(cell)
	var band := get_band_for_distance(distance_tiles)
	return {
		"profile_id": profile_id,
		"origin_cell": origin_cell,
		"distance_tiles": distance_tiles,
		"band_id": band.id,
		"height_bias": band.height_bias,
		"ascent_gain": band.ascent_gain,
		"dominant_style": choose_weighted_key(band.style_weights, cell, seed, "style", "baseline"),
		"dominant_faction": choose_weighted_key(band.faction_presence, cell, seed, "faction", "none"),
		"style_weights": band.style_weights.duplicate(true),
		"faction_presence": band.faction_presence.duplicate(true),
		"story_room_chance": band.story_room_chance,
	}


func choose_weighted_key(weights: Dictionary, cell: Vector2i, seed: int, salt: String, fallback: String) -> String:
	if weights.is_empty():
		return fallback
	var total := 0.0
	for key in weights.keys():
		total += maxf(0.0, float(weights[key]))
	if total <= 0.0:
		return fallback

	var basis := "%s:%s:%d:%d:%d" % [profile_id, salt, seed, cell.x, cell.y]
	var roll := float((basis.hash() & 0x7fffffff) % 100000) / 100000.0 * total
	var running := 0.0
	var sorted_keys := weights.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		running += maxf(0.0, float(weights[key]))
		if roll <= running:
			return String(key)
	return String(sorted_keys.back())
```

---

# 3. Add ascent route planner

Create:

```text
custodian/game/world/procgen/progression/ascent_route_planner.gd
```

```gdscript
extends RefCounted
class_name AscentRoutePlanner

const TRAVERSAL_WALKABLE := "walkable"
const TRAVERSAL_BLOCKED := "blocked"
const TRAVERSAL_LEDGE := "ledge"
const TRAVERSAL_RAMP := "ramp"
const TRAVERSAL_STAIR := "stair"
const TRAVERSAL_DROP := "drop"

const TERRAIN_GROUND := 0
const TERRAIN_ROCK_PLATEAU := 6
const TERRAIN_INDUSTRIAL_STAIR := 4

const TILE_ELEVATED_FLOOR := "rock_plateau_raised_32"
const TILE_STAIR := "stair_metal_32"


func apply_ascent_route(map_rect: Rect2i, result: Dictionary, context: Dictionary, profile: WorldProgressProfile) -> Dictionary:
	if profile == null:
		return {}

	var start_cell: Vector2i = context.get("start_cell", Vector2i.ZERO)
	if not _has_cell(result, start_cell):
		return {}

	var terrain_seed := int(context.get("seed", 0))
	var required_cells: Array[Vector2i] = _normalize_cell_array(context.get("required_cells", []))
	var target_cell := _select_target_cell(result, start_cell, required_cells, profile)
	if target_cell == start_cell:
		return {}

	var path := _find_path(result, start_cell, target_cell)
	if path.size() < 2:
		return {}

	var target_progress := profile.get_cell_progress(target_cell, terrain_seed)
	var total_gain := clampi(int(target_progress.get("ascent_gain", 0)), 0, 12)
	if total_gain <= 0:
		return {
			"kind": "ascent_route",
			"route_cells": path,
			"target_cell": target_cell,
			"target_height": 0,
			"applied": false,
			"reason": "band has no ascent gain"
		}

	var last_height := 0
	for index in range(path.size()):
		var cell := path[index]
		var t := float(index) / maxf(1.0, float(path.size() - 1))
		var height := int(floor(t * float(total_gain)))
		height = clampi(height, 0, total_gain)

		var traversal := TRAVERSAL_WALKABLE
		var tile_id := TILE_ELEVATED_FLOOR if height > 0 else ""

		if index > 0:
			var prev_cell := path[index - 1]
			var prev_height := int(result["height_by_cell"].get(prev_cell, 0))
			if abs(height - prev_height) == 1:
				traversal = TRAVERSAL_STAIR
				tile_id = TILE_STAIR
		if index < path.size() - 1:
			var next_t := float(index + 1) / maxf(1.0, float(path.size() - 1))
			var next_height := int(floor(next_t * float(total_gain)))
			if abs(next_height - height) == 1:
				traversal = TRAVERSAL_STAIR
				tile_id = TILE_STAIR

		result["height_by_cell"][cell] = height
		result["traversal_by_cell"][cell] = traversal
		result["terrain_type_by_cell"][cell] = TERRAIN_INDUSTRIAL_STAIR if traversal == TRAVERSAL_STAIR else TERRAIN_ROCK_PLATEAU
		result["tile_by_cell"][cell] = tile_id
		if traversal == TRAVERSAL_STAIR:
			result["ramp_dir_by_cell"][cell] = "none"
		else:
			result["ramp_dir_by_cell"].erase(cell)

		last_height = height

	return {
		"kind": "ascent_route",
		"route_cells": path,
		"target_cell": target_cell,
		"target_height": last_height,
		"applied": true,
		"band_id": String(target_progress.get("band_id", "unknown")),
		"dominant_style": String(target_progress.get("dominant_style", "unknown")),
	}


func _select_target_cell(result: Dictionary, start_cell: Vector2i, required_cells: Array[Vector2i], profile: WorldProgressProfile) -> Vector2i:
	var best_cell := start_cell
	var best_score := -INF

	for cell in required_cells:
		if not _has_cell(result, cell):
			continue
		if _is_blocked(result, cell):
			continue
		var score := start_cell.distance_squared_to(cell) + profile.get_distance_tiles(cell) * 8.0
		if score > best_score:
			best_score = score
			best_cell = cell

	if best_cell != start_cell:
		return best_cell

	for cell_variant in (result.get("height_by_cell", {}) as Dictionary).keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if _is_blocked(result, cell):
			continue
		var score := start_cell.distance_squared_to(cell) + profile.get_distance_tiles(cell) * 8.0
		if score > best_score:
			best_score = score
			best_cell = cell

	return best_cell


func _find_path(result: Dictionary, start_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var came_from := {}
	var open: Array[Vector2i] = [start_cell]
	came_from[start_cell] = start_cell

	while not open.is_empty():
		var current := open.pop_front() as Vector2i
		if current == target_cell:
			break
		for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next := current + dir
			if came_from.has(next):
				continue
			if not _has_cell(result, next):
				continue
			if _is_blocked(result, next):
				continue
			came_from[next] = current
			open.append(next)

	if not came_from.has(target_cell):
		return []

	var path: Array[Vector2i] = []
	var cursor := target_cell
	while cursor != start_cell:
		path.push_front(cursor)
		cursor = came_from[cursor]
	path.push_front(start_cell)
	return path


func _has_cell(result: Dictionary, cell: Vector2i) -> bool:
	return (result.get("height_by_cell", {}) as Dictionary).has(cell)


func _is_blocked(result: Dictionary, cell: Vector2i) -> bool:
	var traversal := String((result.get("traversal_by_cell", {}) as Dictionary).get(cell, TRAVERSAL_BLOCKED))
	return traversal == TRAVERSAL_BLOCKED or traversal == TRAVERSAL_LEDGE or traversal == TRAVERSAL_DROP


func _normalize_cell_array(value: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if key is Vector2i:
				cells.append(key)
	elif value is Array:
		for item in value:
			if item is Vector2i:
				cells.append(item)
	return cells
```

---

# 4. Expand terrain region kinds

Modify:

```text
custodian/game/world/procgen/terrain/terrain_region.gd
```

Replace the enum with:

```gdscript
enum RegionKind {
	BASELINE,
	LABYRINTH_ROOM,
	LABYRINTH_CORRIDOR,
	MOUNTAIN_WALL,
	CHASM,
	INDUSTRIAL_PLATFORM,
	RAVINE_PATH,
	SWITCHBACK_TRAIL,
	RIDGE_TRAIL,
	RUINED_TERRACE,
	COLLAPSED_STAIR,
	CLIFF_FACE,
	ASCENT_ROUTE,
	FACTION_WORKSITE,
	FACTION_CAMP,
	STORY_ROOM,
	VISTA,
}
```

Replace `kind_to_string` with:

```gdscript
static func kind_to_string(value: RegionKind) -> String:
	match value:
		RegionKind.LABYRINTH_ROOM:
			return "labyrinth_room"
		RegionKind.LABYRINTH_CORRIDOR:
			return "labyrinth_corridor"
		RegionKind.MOUNTAIN_WALL:
			return "mountain_wall"
		RegionKind.CHASM:
			return "chasm"
		RegionKind.INDUSTRIAL_PLATFORM:
			return "industrial_platform"
		RegionKind.RAVINE_PATH:
			return "ravine_path"
		RegionKind.SWITCHBACK_TRAIL:
			return "switchback_trail"
		RegionKind.RIDGE_TRAIL:
			return "ridge_trail"
		RegionKind.RUINED_TERRACE:
			return "ruined_terrace"
		RegionKind.COLLAPSED_STAIR:
			return "collapsed_stair"
		RegionKind.CLIFF_FACE:
			return "cliff_face"
		RegionKind.ASCENT_ROUTE:
			return "ascent_route"
		RegionKind.FACTION_WORKSITE:
			return "faction_worksite"
		RegionKind.FACTION_CAMP:
			return "faction_camp"
		RegionKind.STORY_ROOM:
			return "story_room"
		RegionKind.VISTA:
			return "vista"
		_:
			return "baseline"
```

---

# 5. Patch TerrainBuilder

Modify:

```text
custodian/game/world/procgen/terrain/terrain_builder.gd
```

Add preloads near the top:

```gdscript
const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const AscentRoutePlannerScript := preload("res://game/world/procgen/progression/ascent_route_planner.gd")
```

Add a member:

```gdscript
var _ascent_route_planner: RefCounted = null
```

Inside `build_terrain`, after `required_cells` and `start_cell` are resolved, add:

```gdscript
	var world_progress_profile: WorldProgressProfile = null
	if context.has("world_progress_profile") and context["world_progress_profile"] is WorldProgressProfile:
		world_progress_profile = context["world_progress_profile"] as WorldProgressProfile
	elif context.has("world_progress_profile_path"):
		world_progress_profile = WorldProgressProfileScript.load_from_path(String(context["world_progress_profile_path"]))

	if _ascent_route_planner == null:
		_ascent_route_planner = AscentRoutePlannerScript.new()
```

After the existing industrial platform block and before final connectivity validation, insert:

```gdscript
	if bool(context.get("enable_ascent_route", false)) and world_progress_profile != null:
		var ascent_snapshot := result.duplicate(true)
		var ascent_region: Dictionary = _ascent_route_planner.call("apply_ascent_route", map_rect, result, context, world_progress_profile)
		if not ascent_region.is_empty():
			if _validate_connectivity(result, start_cell, required_cells).get("ok", false):
				debug_regions.append(ascent_region)
			else:
				result = ascent_snapshot
				warnings.append("WARNING: TerrainBuilder discarded ascent route because connectivity validation failed.")
```

In `_build_debug_summary`, add counts:

```gdscript
	var max_height := 0
	var ascent_route_count := 0
	for cell in height_by_cell.keys():
		max_height = maxi(max_height, int(height_by_cell.get(cell, HEIGHT_GROUND)))
```

Then add to the returned dictionary:

```gdscript
		"max_height": max_height,
```

Keep existing keys.

---

# 6. Patch ProcGenTilemap for profile loading and metadata export

Modify:

```text
custodian/game/world/procgen/proc_gen_tilemap.gd
```

Add preloads near the current terrain/elevation preloads:

```gdscript
const WORLD_PROGRESS_PROFILE_SCRIPT := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const FACTION_SITE_PLACER_SCRIPT := preload("res://game/world/procgen/factions/faction_site_placer.gd")
const STORY_ROOM_PLACER_SCRIPT := preload("res://game/world/procgen/story/story_room_placer.gd")
```

Add exports near the existing elevation exports:

```gdscript
@export_group("World Progression", "world_progress")
@export var world_progression_enabled: bool = true
@export_file("*.json") var world_progress_profile_path: String = "res://content/procgen/world_profiles/sundered_keep_ascent.json"
@export var world_progress_debug_logging: bool = true
@export var ascent_route_enabled: bool = true
@export_group("", "")

@export_group("Faction Ambient Sites", "faction_ambient")
@export var faction_ambient_sites_enabled: bool = true
@export_range(0, 64, 1) var faction_ambient_site_count: int = 18
@export_group("", "")

@export_group("Story Rooms", "story_room")
@export var story_rooms_enabled: bool = true
@export_range(0, 32, 1) var story_room_count: int = 8
@export_group("", "")
```

Add members near `_planet_world_profile`:

```gdscript
var _world_progress_profile: WorldProgressProfile = null
var _world_progress_samples: Dictionary = {}
var _faction_activity_sites: Array[Dictionary] = []
var _story_room_sites: Array[Dictionary] = []
var _faction_site_placer: RefCounted = null
var _story_room_placer: RefCounted = null
```

Add helper functions:

```gdscript
func _ensure_world_progress_profile() -> void:
	if not world_progression_enabled:
		_world_progress_profile = null
		return
	if _world_progress_profile != null:
		return
	_world_progress_profile = WORLD_PROGRESS_PROFILE_SCRIPT.load_from_path(world_progress_profile_path)
	var spawn := get_player_spawn()
	if spawn != Vector2i.ZERO:
		_world_progress_profile.origin_cell = spawn


func _ensure_site_placers() -> void:
	if _faction_site_placer == null:
		_faction_site_placer = FACTION_SITE_PLACER_SCRIPT.new()
	if _story_room_placer == null:
		_story_room_placer = STORY_ROOM_PLACER_SCRIPT.new()


func _build_world_progress_samples(map_size: Vector2i) -> void:
	_world_progress_samples.clear()
	if _world_progress_profile == null:
		return
	var sample_step := 16
	for x in range(0, map_size.x, sample_step):
		for y in range(0, map_size.y, sample_step):
			var cell := Vector2i(x, y)
			_world_progress_samples[cell] = _world_progress_profile.get_cell_progress(cell, procgen_node.seed)


func get_world_progress_at_tile(tile: Vector2i) -> Dictionary:
	_ensure_world_progress_profile()
	if _world_progress_profile == null:
		return {}
	return _world_progress_profile.get_cell_progress(tile, procgen_node.seed)
```

Patch `_fill_tilemaps`.

Find:

```gdscript
	var map_size = procgen_node.map_size
	var open_layout_active := _is_open_layout_active()
```

Add after it:

```gdscript
	_ensure_world_progress_profile()
	_ensure_site_placers()
```

Find the existing terrain builder context in `_apply_terrain_builder`:

```gdscript
	var context := {
		"seed": terrain_seed,
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"blocked_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"start_cell": get_player_spawn(),
		"required_cells": required_cells,
		"enable_industrial_platform": elevation_platform_stamps_enabled,
		"enable_mountain_boundary": terrain_builder_mountain_boundary_enabled,
	}
```

Replace with:

```gdscript
	var context := {
		"seed": terrain_seed,
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"blocked_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"start_cell": get_player_spawn(),
		"required_cells": required_cells,
		"enable_industrial_platform": elevation_platform_stamps_enabled,
		"enable_mountain_boundary": terrain_builder_mountain_boundary_enabled,
		"enable_ascent_route": ascent_route_enabled and world_progression_enabled,
		"world_progress_profile": _world_progress_profile,
		"world_progress_profile_path": world_progress_profile_path,
	}
```

After this existing terrain section:

```gdscript
		_refresh_road_path_visuals()
		_capture_generated_tile_state(map_size)
```

Add:

```gdscript
	if world_progression_enabled:
		_build_world_progress_samples(map_size)
	if faction_ambient_sites_enabled:
		_place_faction_ambient_sites(map_size)
	if story_rooms_enabled:
		_place_story_rooms(map_size)
```

Add these functions:

```gdscript
func _place_faction_ambient_sites(map_size: Vector2i) -> void:
	_faction_activity_sites.clear()
	if _world_progress_profile == null or _faction_site_placer == null:
		return
	var floor_cells := _dict_keys_as_vector2i_array(_generated_floor_cells)
	var blocked_cells := _dict_keys_as_vector2i_array(_generated_wall_cells)
	var context := {
		"seed": _tile_noise_hash(Vector2i(661, 911)),
		"map_size": map_size,
		"floor_cells": floor_cells,
		"blocked_cells": blocked_cells,
		"required_cells": _collect_terrain_required_cells(map_size),
		"count": faction_ambient_site_count,
		"world_progress_profile": _world_progress_profile,
		"elevation_cells": elevation_map.get_cells() if elevation_map != null and elevation_map.has_method("get_cells") else {},
	}
	_faction_activity_sites = _faction_site_placer.call("place_sites", context)
	for site in _faction_activity_sites:
		var cell: Vector2i = site.get("cell", Vector2i.ZERO)
		if _is_tile_inside_map(cell, map_size):
			_set_region_tile(cell, "faction_%s_%s" % [String(site.get("faction_id", "none")), String(site.get("activity_id", "ambient"))], "faction_activity")


func _place_story_rooms(map_size: Vector2i) -> void:
	_story_room_sites.clear()
	if _world_progress_profile == null or _story_room_placer == null:
		return
	var context := {
		"seed": _tile_noise_hash(Vector2i(1201, 1709)),
		"map_size": map_size,
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"blocked_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"required_cells": _collect_terrain_required_cells(map_size),
		"count": story_room_count,
		"world_progress_profile": _world_progress_profile,
		"faction_sites": _faction_activity_sites,
		"elevation_cells": elevation_map.get_cells() if elevation_map != null and elevation_map.has_method("get_cells") else {},
	}
	_story_room_sites = _story_room_placer.call("place_story_rooms", context)
	for room in _story_room_sites:
		var cell: Vector2i = room.get("cell", Vector2i.ZERO)
		if _is_tile_inside_map(cell, map_size):
			_set_region_tile(cell, "story_room_%s" % String(room.get("story_id", "unknown")), "story_room")
```

Patch `get_level_data()`.

Add these keys:

```gdscript
		"world_progression_enabled": world_progression_enabled,
		"world_progress_profile_id": _world_progress_profile.profile_id if _world_progress_profile != null else "",
		"world_progress_samples": _world_progress_samples.duplicate(true),
		"faction_activity_sites": _faction_activity_sites.duplicate(true),
		"story_room_sites": _story_room_sites.duplicate(true),
```

---

# 7. Add faction ambient site placer

Create:

```text
custodian/game/world/procgen/factions/faction_activity_site.gd
```

```gdscript
extends RefCounted
class_name FactionActivitySite

var site_id: String = ""
var faction_id: String = "none"
var activity_id: String = "ambient"
var cell: Vector2i = Vector2i.ZERO
var radius_tiles: int = 4
var band_id: String = ""
var style_id: String = ""
var escalation_radius_tiles: int = 6
var noncombat_first: bool = true


func to_dictionary() -> Dictionary:
	return {
		"site_id": site_id,
		"faction_id": faction_id,
		"activity_id": activity_id,
		"cell": cell,
		"radius_tiles": radius_tiles,
		"band_id": band_id,
		"style_id": style_id,
		"escalation_radius_tiles": escalation_radius_tiles,
		"noncombat_first": noncombat_first,
	}
```

Create:

```text
custodian/game/world/procgen/factions/faction_site_placer.gd
```

```gdscript
extends RefCounted
class_name FactionSitePlacer

const FactionActivitySiteScript := preload("res://game/world/procgen/factions/faction_activity_site.gd")

const ACTIVITIES := {
	"iconoclast": [
		"scrape_inscription",
		"index_relic",
		"stand_watch",
		"burn_archive",
		"mark_false_history"
	],
	"cult_mechanist": [
		"pray_to_machine",
		"carry_cable",
		"repair_wrong",
		"polish_relic",
		"chant_into_broken_comm"
	],
	"scavenger": [
		"haul_crate",
		"sleep_camp",
		"argue_over_salvage",
		"cook_near_scrap_fire",
		"set_winch"
	]
}


func place_sites(context: Dictionary) -> Array[Dictionary]:
	var profile: WorldProgressProfile = context.get("world_progress_profile", null)
	if profile == null:
		return []

	var seed := int(context.get("seed", 0))
	var count := int(context.get("count", 12))
	var floor_cells: Array[Vector2i] = _normalize_cell_array(context.get("floor_cells", []))
	var blocked_lookup := _lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var required_lookup := _lookup(_normalize_cell_array(context.get("required_cells", [])))

	var candidates: Array[Vector2i] = []
	for cell in floor_cells:
		if blocked_lookup.has(cell):
			continue
		if required_lookup.has(cell):
			continue
		var progress := profile.get_cell_progress(cell, seed)
		if String(progress.get("dominant_faction", "none")) == "none":
			continue
		if float(progress.get("distance_tiles", 0.0)) < 96.0:
			continue
		candidates.append(cell)

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ah := ("%d:%d:%d" % [seed, a.x, a.y]).hash()
		var bh := ("%d:%d:%d" % [seed, b.x, b.y]).hash()
		return ah < bh
	)

	var sites: Array[Dictionary] = []
	var occupied: Array[Vector2i] = []
	for cell in candidates:
		if sites.size() >= count:
			break
		if not _far_enough(cell, occupied, 14):
			continue
		var progress := profile.get_cell_progress(cell, seed)
		var faction := String(progress.get("dominant_faction", "none"))
		var activity := _pick_activity(faction, cell, seed)
		var site := FactionActivitySiteScript.new()
		site.site_id = "%s_%s_%d_%d" % [faction, activity, cell.x, cell.y]
		site.faction_id = faction
		site.activity_id = activity
		site.cell = cell
		site.band_id = String(progress.get("band_id", "unknown"))
		site.style_id = String(progress.get("dominant_style", "unknown"))
		site.radius_tiles = 4 + int(abs(("%s:%d:%d" % [faction, cell.x, cell.y]).hash()) % 3)
		sites.append(site.to_dictionary())
		occupied.append(cell)

	return sites


func _pick_activity(faction: String, cell: Vector2i, seed: int) -> String:
	var list: Array = ACTIVITIES.get(faction, ["ambient"])
	if list.is_empty():
		return "ambient"
	var index := int(abs(("%s:%d:%d:%d" % [faction, seed, cell.x, cell.y]).hash()) % list.size())
	return String(list[index])


func _far_enough(cell: Vector2i, occupied: Array[Vector2i], min_distance_tiles: int) -> bool:
	var min_distance_sq := min_distance_tiles * min_distance_tiles
	for other in occupied:
		if cell.distance_squared_to(other) < min_distance_sq:
			return false
	return true


func _lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


func _normalize_cell_array(value: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if key is Vector2i:
				cells.append(key)
	elif value is Array:
		for item in value:
			if item is Vector2i:
				cells.append(item)
	return cells
```

---

# 8. Add story room placement

Create:

```text
custodian/game/world/procgen/story/story_room_template.gd
```

```gdscript
extends RefCounted
class_name StoryRoomTemplate

var story_id: String = "unknown"
var allowed_bands: Array[String] = []
var required_faction: String = ""
var footprint_tiles: Vector2i = Vector2i(10, 8)
var activity_tags: Array[String] = []


static func make(id: String, bands: Array[String], faction: String, footprint: Vector2i, tags: Array[String]) -> StoryRoomTemplate:
	var template := StoryRoomTemplate.new()
	template.story_id = id
	template.allowed_bands = bands.duplicate()
	template.required_faction = faction
	template.footprint_tiles = footprint
	template.activity_tags = tags.duplicate()
	return template


func accepts(progress: Dictionary, faction_id: String) -> bool:
	var band_id := String(progress.get("band_id", ""))
	if not allowed_bands.is_empty() and not allowed_bands.has(band_id):
		return false
	if not required_faction.is_empty() and required_faction != faction_id:
		return false
	return true


func to_dictionary() -> Dictionary:
	return {
		"story_id": story_id,
		"allowed_bands": allowed_bands.duplicate(),
		"required_faction": required_faction,
		"footprint_tiles": footprint_tiles,
		"activity_tags": activity_tags.duplicate(),
	}
```

Create:

```text
custodian/game/world/procgen/story/story_room_placer.gd
```

```gdscript
extends RefCounted
class_name StoryRoomPlacer

const StoryRoomTemplateScript := preload("res://game/world/procgen/story/story_room_template.gd")


func _default_templates() -> Array[StoryRoomTemplate]:
	return [
		StoryRoomTemplateScript.make("first_switchback_camp", ["broken_foothills", "slog_ascent"], "scavenger", Vector2i(12, 9), ["set_winch", "haul_crate", "sleep_camp"]),
		StoryRoomTemplateScript.make("erased_archive_wall", ["broken_foothills", "slog_ascent", "upper_exhaustion"], "iconoclast", Vector2i(11, 8), ["scrape_inscription", "index_relic"]),
		StoryRoomTemplateScript.make("machine_pilgrim_rest", ["slog_ascent", "upper_exhaustion"], "cult_mechanist", Vector2i(10, 10), ["pray_to_machine", "repair_wrong"]),
		StoryRoomTemplateScript.make("collapsed_stair_underpass", ["broken_foothills", "slog_ascent"], "", Vector2i(14, 8), ["collapsed_stair", "vista"]),
		StoryRoomTemplateScript.make("dead_patrol_overlook", ["slog_ascent", "upper_exhaustion"], "", Vector2i(10, 7), ["stand_watch", "dead_patrol"]),
	]


func place_story_rooms(context: Dictionary) -> Array[Dictionary]:
	var profile: WorldProgressProfile = context.get("world_progress_profile", null)
	if profile == null:
		return []

	var seed := int(context.get("seed", 0))
	var count := int(context.get("count", 6))
	var floor_cells := _normalize_cell_array(context.get("floor_cells", []))
	var blocked_lookup := _lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var required_lookup := _lookup(_normalize_cell_array(context.get("required_cells", [])))
	var faction_sites: Array = context.get("faction_sites", [])

	var candidates: Array[Vector2i] = []
	for cell in floor_cells:
		if blocked_lookup.has(cell) or required_lookup.has(cell):
			continue
		var progress := profile.get_cell_progress(cell, seed)
		if float(progress.get("distance_tiles", 0.0)) < 128.0:
			continue
		var chance := float(progress.get("story_room_chance", 0.0))
		var roll := float(abs(("%d:%d:%d:story" % [seed, cell.x, cell.y]).hash()) % 100000) / 100000.0
		if roll <= chance:
			candidates.append(cell)

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return profile.get_distance_tiles(a) > profile.get_distance_tiles(b)
	)

	var templates := _default_templates()
	var rooms: Array[Dictionary] = []
	var occupied: Array[Vector2i] = []

	for cell in candidates:
		if rooms.size() >= count:
			break
		if not _far_enough(cell, occupied, 20):
			continue

		var progress := profile.get_cell_progress(cell, seed)
		var faction_id := _nearest_faction_site(cell, faction_sites)
		var template := _pick_template(templates, progress, faction_id, cell, seed)
		if template == null:
			continue

		rooms.append({
			"story_id": template.story_id,
			"cell": cell,
			"band_id": String(progress.get("band_id", "")),
			"dominant_style": String(progress.get("dominant_style", "")),
			"faction_id": faction_id,
			"footprint_tiles": template.footprint_tiles,
			"activity_tags": template.activity_tags.duplicate(),
			"metadata_only_v1": true
		})
		occupied.append(cell)

	return rooms


func _pick_template(templates: Array[StoryRoomTemplate], progress: Dictionary, faction_id: String, cell: Vector2i, seed: int) -> StoryRoomTemplate:
	var valid: Array[StoryRoomTemplate] = []
	for template in templates:
		if template.accepts(progress, faction_id):
			valid.append(template)
	if valid.is_empty():
		return null
	var index := int(abs(("%d:%d:%d:%s" % [seed, cell.x, cell.y, faction_id]).hash()) % valid.size())
	return valid[index]


func _nearest_faction_site(cell: Vector2i, faction_sites: Array) -> String:
	var best_faction := ""
	var best_dist := INF
	for site in faction_sites:
		if not site is Dictionary:
			continue
		var site_cell: Vector2i = site.get("cell", Vector2i.ZERO)
		var dist := cell.distance_squared_to(site_cell)
		if dist < best_dist:
			best_dist = dist
			best_faction = String(site.get("faction_id", ""))
	return best_faction


func _far_enough(cell: Vector2i, occupied: Array[Vector2i], min_distance_tiles: int) -> bool:
	var min_distance_sq := min_distance_tiles * min_distance_tiles
	for other in occupied:
		if cell.distance_squared_to(other) < min_distance_sq:
			return false
	return true


func _lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


func _normalize_cell_array(value: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if key is Vector2i:
				cells.append(key)
	elif value is Array:
		for item in value:
			if item is Vector2i:
				cells.append(item)
	return cells
```

---

# 9. Add ambient activity anchors for future actor routines

Create:

```text
custodian/game/actors/enemies/ambient/ambient_activity_anchor.gd
```

```gdscript
extends Area2D
class_name AmbientActivityAnchor

@export var faction_id: String = "none"
@export var activity_id: String = "ambient"
@export var radius_px: float = 28.0
@export var claim_duration_sec: float = 4.0
@export var escalation_radius_px: float = 160.0
@export var noncombat_first: bool = true

var claimed_by: Node = null


func can_claim(actor: Node) -> bool:
	if claimed_by == null:
		return true
	if not is_instance_valid(claimed_by):
		claimed_by = null
		return true
	return claimed_by == actor


func claim(actor: Node) -> bool:
	if not can_claim(actor):
		return false
	claimed_by = actor
	return true


func release(actor: Node) -> void:
	if claimed_by == actor:
		claimed_by = null


func get_anchor_position() -> Vector2:
	return global_position


func get_activity_snapshot() -> Dictionary:
	return {
		"faction_id": faction_id,
		"activity_id": activity_id,
		"claimed": claimed_by != null and is_instance_valid(claimed_by),
		"position": global_position,
		"noncombat_first": noncombat_first,
	}
```

Patch:

```text
custodian/game/actors/enemies/components/enemy_blackboard.gd
```

Add fields:

```gdscript
var ambient_anchor: Node = null
var ambient_activity_id: StringName = &"none"
var ambient_activity_timer: float = 0.0
var ambient_noncombat_first: bool = true
```

In `reset_alerts()`, add:

```gdscript
	ambient_activity_id = &"none"
	ambient_activity_timer = 0.0
```

In `get_debug_snapshot()`, add:

```gdscript
		"ambient_activity": String(ambient_activity_id),
		"ambient_anchor": ambient_anchor.name if ambient_anchor != null and is_instance_valid(ambient_anchor) else "",
```

Patch:

```text
custodian/game/actors/enemies/components/enemy_behavior_profile.gd
```

Add exports:

```gdscript
@export_category("Ambient Routine")
@export var ambient_activity_weight: float = 0.35
@export var ambient_activity_duration_sec: float = 4.0
@export var ambient_anchor_search_radius_px: float = 220.0
@export var noncombat_warning_seconds: float = 0.8
```

Patch factory defaults in `create_profile`, where profile IDs are assigned. Add these differences if the profile switch exists:

```gdscript
	&"iconoclast_looter":
		profile.ambient_activity_weight = 0.55
		profile.noncombat_warning_seconds = 1.1
	&"zealot_wanderer":
		profile.ambient_activity_weight = 0.7
		profile.noncombat_warning_seconds = 0.5
	&"raider_grunt":
		profile.ambient_activity_weight = 0.25
		profile.noncombat_warning_seconds = 0.4
```

Patch:

```text
custodian/game/actors/enemies/enemy_behavior_state_machine.gd
```

Add constant:

```gdscript
const AMBIENT_ACTIVITY := &"ambient_activity"
```

Add export:

```gdscript
@export var ambient_anchor_group: StringName = &"ambient_activity_anchor"
```

In `physics_update` match block, add before `INVESTIGATE` or after `PATROL`:

```gdscript
		AMBIENT_ACTIVITY:
			_update_ambient_activity(enemy, delta)
```

Add function:

```gdscript
func force_ambient(anchor: Node) -> void:
	if blackboard == null or anchor == null:
		return
	blackboard.ambient_anchor = anchor
	if "activity_id" in anchor:
		blackboard.ambient_activity_id = StringName(str(anchor.get("activity_id")))
	if "noncombat_first" in anchor:
		blackboard.ambient_noncombat_first = bool(anchor.get("noncombat_first"))
	if anchor.has_method("claim") and not bool(anchor.call("claim", get_parent())):
		return
	change_state(AMBIENT_ACTIVITY)
```

At the top of `_update_idle`, after `_evaluate_interrupts(enemy)`:

```gdscript
	if _try_claim_nearby_ambient_anchor(enemy):
		return
```

Add functions:

```gdscript
func _try_claim_nearby_ambient_anchor(enemy: Node2D) -> bool:
	if profile == null or blackboard == null:
		return false
	var roll_basis := "%s:%d:%d" % [enemy.name, int(state_time * 10.0), int(profile.ambient_activity_weight * 100.0)]
	var roll := float((roll_basis.hash() & 0x7fffffff) % 1000) / 1000.0
	if roll > profile.ambient_activity_weight:
		return false

	var best_anchor: Node = null
	var best_dist := INF
	for anchor in enemy.get_tree().get_nodes_in_group(ambient_anchor_group):
		if not (anchor is Node2D):
			continue
		if anchor.has_method("can_claim") and not bool(anchor.call("can_claim", enemy)):
			continue
		var dist := enemy.global_position.distance_to((anchor as Node2D).global_position)
		if dist > profile.ambient_anchor_search_radius_px:
			continue
		if dist < best_dist:
			best_dist = dist
			best_anchor = anchor

	if best_anchor == null:
		return false

	blackboard.ambient_anchor = best_anchor
	if "activity_id" in best_anchor:
		blackboard.ambient_activity_id = StringName(str(best_anchor.get("activity_id")))
	else:
		blackboard.ambient_activity_id = &"ambient"
	if "noncombat_first" in best_anchor:
		blackboard.ambient_noncombat_first = bool(best_anchor.get("noncombat_first"))
	if best_anchor.has_method("claim") and not bool(best_anchor.call("claim", enemy)):
		return false
	change_state(AMBIENT_ACTIVITY)
	return true


func _update_ambient_activity(enemy: Node2D, delta: float) -> void:
	if blackboard.is_alerted and blackboard.operator_ref != null:
		_release_ambient_anchor(enemy)
		change_state(NOTICE)
		return

	var anchor := blackboard.ambient_anchor as Node2D
	if anchor == null or not is_instance_valid(anchor):
		change_state(PATROL)
		return

	var anchor_pos := anchor.global_position
	if anchor.has_method("get_anchor_position"):
		anchor_pos = anchor.call("get_anchor_position")

	if enemy.global_position.distance_to(anchor_pos) > 18.0:
		enemy.call("behavior_move_toward", anchor_pos, profile.patrol_speed)
		return

	enemy.call("behavior_stop")
	blackboard.ambient_activity_timer += delta
	if blackboard.ambient_activity_timer >= profile.ambient_activity_duration_sec:
		_release_ambient_anchor(enemy)
		change_state(PATROL)


func _release_ambient_anchor(enemy: Node) -> void:
	if blackboard == null:
		return
	var anchor := blackboard.ambient_anchor
	if anchor != null and is_instance_valid(anchor) and anchor.has_method("release"):
		anchor.call("release", enemy)
	blackboard.ambient_anchor = null
	blackboard.ambient_activity_id = &"none"
	blackboard.ambient_activity_timer = 0.0
```

In `change_state`, before changing state, release the anchor if leaving ambient:

```gdscript
	if current_state == AMBIENT_ACTIVITY and new_state != AMBIENT_ACTIVITY and get_parent() != null:
		_release_ambient_anchor(get_parent())
```

---

# 10. Add smoke validation

Create:

```text
custodian/tools/validation/procgen_ascent_style_smoke.gd
```

```gdscript
extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const TerrainBuilderScript := preload("res://game/world/procgen/terrain/terrain_builder.gd")

func _init() -> void:
	var profile := WorldProgressProfileScript.load_from_path("res://content/procgen/world_profiles/sundered_keep_ascent.json")
	assert(profile != null)
	assert(profile.bands.size() >= 4)

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var floor_cells: Array[Vector2i] = []
	for x in range(0, 80):
		for y in range(0, 80):
			floor_cells.append(Vector2i(x, y))

	var required := [
		Vector2i(4, 4),
		Vector2i(20, 20),
		Vector2i(50, 50),
		Vector2i(72, 72)
	]

	var builder := TerrainBuilderScript.new()
	var result := builder.build_terrain(Rect2i(Vector2i.ZERO, Vector2i(80, 80)), rng, {
		"seed": 12345,
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"start_cell": Vector2i(4, 4),
		"required_cells": required,
		"enable_industrial_platform": false,
		"enable_mountain_boundary": false,
		"enable_ascent_route": true,
		"world_progress_profile": profile,
	})

	assert(result.has("height_by_cell"))
	assert(result.has("regions"))
	assert(int(result.get("debug_summary", {}).get("max_height", 0)) > 0)
	assert(bool(result.get("connectivity", {}).get("ok", false)))

	print("procgen_ascent_style_smoke: PASS")
	quit()
```

Create:

```text
custodian/tools/validation/faction_story_sites_smoke.gd
```

```gdscript
extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const FactionSitePlacerScript := preload("res://game/world/procgen/factions/faction_site_placer.gd")
const StoryRoomPlacerScript := preload("res://game/world/procgen/story/story_room_placer.gd")

func _init() -> void:
	var profile := WorldProgressProfileScript.load_from_path("res://content/procgen/world_profiles/sundered_keep_ascent.json")
	var floor_cells: Array[Vector2i] = []
	for x in range(0, 96):
		for y in range(0, 96):
			floor_cells.append(Vector2i(x, y))

	var faction_placer := FactionSitePlacerScript.new()
	var sites: Array = faction_placer.place_sites({
		"seed": 444,
		"map_size": Vector2i(96, 96),
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"required_cells": [Vector2i(0, 0)],
		"count": 12,
		"world_progress_profile": profile,
	})

	assert(sites.size() > 0)
	assert((sites[0] as Dictionary).has("faction_id"))
	assert((sites[0] as Dictionary).has("activity_id"))

	var story_placer := StoryRoomPlacerScript.new()
	var rooms: Array = story_placer.place_story_rooms({
		"seed": 777,
		"map_size": Vector2i(96, 96),
		"floor_cells": floor_cells,
		"blocked_cells": [],
		"required_cells": [Vector2i(0, 0)],
		"count": 6,
		"world_progress_profile": profile,
		"faction_sites": sites,
	})

	assert(rooms.size() > 0)
	assert((rooms[0] as Dictionary).has("story_id"))

	print("faction_story_sites_smoke: PASS")
	quit()
```

---

# 11. Validation commands

Run:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian

godot --headless --script res://tools/validation/procgen_ascent_style_smoke.gd
godot --headless --script res://tools/validation/faction_story_sites_smoke.gd
godot --headless --script res://tools/validation/elevation_map_smoke.gd
godot --headless --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --path . --quit
```

Then:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

git diff --stat
git diff -- custodian/game/world/procgen/terrain/terrain_region.gd
git diff -- custodian/game/world/procgen/terrain/terrain_builder.gd
git diff -- custodian/game/world/procgen/proc_gen_tilemap.gd
git diff -- custodian/game/actors/enemies/enemy_behavior_state_machine.gd
git diff -- custodian/game/actors/enemies/components/enemy_blackboard.gd
git diff -- custodian/game/actors/enemies/components/enemy_behavior_profile.gd
```

---

# 12. Documentation updates after implementation

Update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/CONTEXT.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/task_packets/PROCGEN_ASCENT_STYLE_FACTION_STORY_V1.md
```

Add to `CURRENT_STATE.md`:

```markdown
- Procgen world progression V1 is live as metadata-first distance-band progression. `ProcGenTilemap` loads `res://content/procgen/world_profiles/sundered_keep_ascent.json`, samples distance bands from player spawn/origin, passes the profile into `TerrainBuilder`, exports world progression samples through `get_level_data()`, and produces metadata for faction ambient sites and environmental story rooms.
- TerrainBuilder can now optionally stamp an uphill ascent route across existing generated floor cells using `AscentRoutePlanner`, raising route height over distance while preserving connectivity validation. This is still metadata-first elevation and does not yet rewrite full actor path traversal.
- Faction ambient site metadata now identifies non-combat faction activity pockets such as iconoclast inscription scraping, cult mechanist machine prayer, and scavenger salvage camps. These sites are exported through level data and marked in region metadata for debug/minimap consumers.
- Environmental story-room metadata V1 can place deterministic story room candidates such as first switchback camp, erased archive wall, machine pilgrim rest, collapsed stair underpass, and dead patrol overlook. V1 marks placement metadata; full authored geometry stamping is a follow-up.
- Enemy ambient routine support V1 adds ambient activity anchors and an `ambient_activity` behavior state so existing behavior-driven enemies can claim an anchor, move to it, idle/perform a non-combat routine, and escalate normally if alerted.
```

Add to `FILE_INDEX.md`:

```markdown
- `custodian/content/procgen/world_profiles/sundered_keep_ascent.json` — distance-band profile for procgen style transition, elevation pressure, faction presence, and story-room chance.
- `custodian/game/world/procgen/progression/world_style_band.gd` — data model for one distance/style/elevation band.
- `custodian/game/world/procgen/progression/world_progress_profile.gd` — deterministic profile loader and cell progress sampler.
- `custodian/game/world/procgen/progression/ascent_route_planner.gd` — metadata-first uphill route planner that raises an existing traversable route over distance.
- `custodian/game/world/procgen/factions/faction_activity_site.gd` — data model for non-combat faction activity sites.
- `custodian/game/world/procgen/factions/faction_site_placer.gd` — deterministic faction ambient site selector.
- `custodian/game/world/procgen/story/story_room_template.gd` — story room metadata template model.
- `custodian/game/world/procgen/story/story_room_placer.gd` — deterministic environmental story-room candidate placer.
- `custodian/game/actors/enemies/ambient/ambient_activity_anchor.gd` — claimable non-combat activity anchor used by behavior-driven enemies.
- `custodian/tools/validation/procgen_ascent_style_smoke.gd` — smoke validation for world profile loading and uphill ascent metadata.
- `custodian/tools/validation/faction_story_sites_smoke.gd` — smoke validation for faction ambient site and story-room candidate placement.
```

---

# 13. Acceptance criteria

Codex is done only when:

```text
Runtime:
- Existing procgen generation still loads.
- Existing terrain builder smoke still passes.
- Existing elevation map smoke still passes.
- New world profile loads from JSON.
- TerrainBuilder can stamp an ascent route without breaking connectivity.
- `get_level_data()` exports world progression samples.
- `get_level_data()` exports faction ambient sites.
- `get_level_data()` exports story room sites.
- Existing enemy behavior still works.
- Ambient activity anchors can be claimed/released.
- Ambient activity state does not force combat unless perception/blackboard alert state escalates.

Determinism:
- Same seed produces same ascent route.
- Same seed produces same faction sites.
- Same seed produces same story rooms.

Docs:
- Design spec created first.
- Task packet created/updated.
- CURRENT_STATE updated.
- CONTEXT updated if architecture wording changed.
- FILE_INDEX updated with all new files.

Non-goals:
- Do not make final production art.
- Do not implement full actor pathfinding elevation costs.
- Do not implement true same-coordinate stacked traversal.
- Do not build all story-room geometry yet.
- Do not replace the existing procgen generator.
```

---

# 14. Follow-up phase after this lands

After V1 metadata is stable, the next Codex task should be:

```text
Task: Convert procgen story-room metadata into actual geometry templates.

Implement:
- story room footprint reservation
- floor carving
- blocker clearing
- local prop marker placement
- ambient activity anchor instantiation
- optional non-hostile enemy spawn markers
- debug overlay labels
- minimap story/faction metadata
```

Do not skip the metadata V1. The current architecture already proves that metadata-first terrain/elevation is the correct spine, and your existing docs explicitly call out that elevation is currently authoritative as metadata while visual tiles are presentation. fileciteturn2file0
