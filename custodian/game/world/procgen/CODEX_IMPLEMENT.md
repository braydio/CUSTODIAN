Yes. Gameplay/feel-wise, I would not start by adding more systems. I’d make the existing generated world feel more intentional, readable, and “touchable.”

This file is already doing a lot: compound layout, interior regions, foliage, props, portals, streaming reveal, wall damage, runtime collision, and minimap signals. The opportunity is to make those systems express stronger game feel instead of just filling space.

## 1. Make the portal feel like a destination, not a random prop

Right now portals are spawned through the ruin prop system, then nudged to safe floor tiles. That makes them technically safe, but not necessarily dramatic.

I would make portal placement create a small authored “landing plaza” around each portal:

```gdscript
func _stamp_portal_plaza(center: Vector2i, map_size: Vector2i) -> void:
	for x in range(-3, 4):
		for y in range(-2, 3):
			var tile := center + Vector2i(x, y)
			if tile.x <= 1 or tile.y <= 1 or tile.x >= map_size.x - 2 or tile.y >= map_size.y - 2:
				continue
			_set_floor_tile(tile)
			_set_region_tile(tile, "portal_plaza", "portal")
```

Then call it after resolving each portal endpoint tile.

Gameplay effect: the player sees “this is a traversal landmark,” not “some prop happened to spawn here.”

I’d also force a few nearby props/foliage exclusions and maybe spawn 2–4 decorative ruins around it.

---

## 2. Make streaming reveal slower near landmarks and faster in empty space

You already have:

```gdscript
streaming_reveal_tiles_per_frame
streaming_chunk_size_tiles
streaming_active_chunk_radius
```

Right now the reveal system is mostly technical. For feel, it should act like a camera/lens discovering the world.

I’d add “interest-biased reveal”:

- reveal tiles near the player first
- then corridors
- then walls/props/landmarks
- maybe delay far chunk edges slightly

For portals, compounds, and interiors, you could reveal their exterior silhouette before revealing full contents. That would make the world feel less like chunks popping in and more like the player is uncovering ruins.

Simple change: when sorting reveal queue tiles, bias non-wall floor tiles and nearby region markers:

```gdscript
tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
	var a_score := a.distance_squared_to(center_tile)
	var b_score := b.distance_squared_to(center_tile)

	if get_region_type_at_tile(a) != "exterior":
		a_score -= 64
	if get_region_type_at_tile(b) != "exterior":
		b_score -= 64

	return a_score < b_score
)
```

That makes constructed areas “resolve” slightly earlier and feel more intentional.

---

## 3. Turn wall damage into a traversal affordance

You already have `damage_wall_tile()` and destructible runtime walls. That’s huge. I’d lean into it.

Right now destroyed walls simply become floors. I would add:

- debris floor variant
- dust puff
- sound cue
- minimap update
- temporary navigation delay
- small chance to reveal hidden interior/loot node

Even just changing the floor tile under destroyed walls would help:

```gdscript
func _set_destroyed_wall_floor_tile(pos: Vector2i) -> void:
	_set_floor_tile(pos)
	_set_region_tile(pos, "destroyed_wall_floor", "debris")
```

Then inside `damage_wall_tile()` replace:

```gdscript
_set_floor_tile(pos)
```

with:

```gdscript
_set_destroyed_wall_floor_tile(pos)
```

Gameplay effect: breaking walls becomes a world interaction, not just deleting a tile.

---

## 4. Make interiors read as rooms, not just rectangles

The constructed interior system is promising, but it risks feeling like “procedural rectangles.”

I would add room identity tags at generation time:

```gdscript
"barracks"
"storage"
"generator"
"security"
"lab"
"archive"
"maintenance"
```

Then use those tags to bias prop placement.

Example:

```gdscript
func _pick_room_zone(room: Rect2i, index: int) -> String:
	var zones := ["storage", "security", "maintenance", "archive", "generator"]
	return zones[_tile_noise_hash(room.position + Vector2i(index, 777)) % zones.size()]
```

Then when carving rooms:

```gdscript
var zone := _pick_room_zone(room, _last_interior_rooms.size())
_carve_interior_floor_rect(room, zone)
```

This lets props, enemies, loot, and ambience key off the room’s purpose.

Gameplay effect: the player starts reading spaces as places, not cells.

---

## 5. Add “safe approach lanes” to points of interest

The compound, interiors, and portals all generate independently. I’d add a pass after generation that carves subtle paths between:

- player spawn
- compound ingress
- interior thresholds
- portal plazas
- major rooms

Not perfect roads. More like “worn traversal corridors.”

You can do a simple Manhattan carve:

```gdscript
func _carve_soft_path(from_tile: Vector2i, to_tile: Vector2i, width: int = 2) -> void:
	var current := from_tile

	while current.x != to_tile.x:
		current.x += signi(to_tile.x - current.x)
		_carve_path_brush(current, width)

	while current.y != to_tile.y:
		current.y += signi(to_tile.y - current.y)
		_carve_path_brush(current, width)


func _carve_path_brush(center: Vector2i, width: int) -> void:
	for x in range(-width, width + 1):
		for y in range(-width, width + 1):
			var tile := center + Vector2i(x, y)
			if _generated_wall_cells.has(tile):
				continue
			_set_floor_tile(tile)
```

Gameplay effect: the player gets subliminal guidance without arrows or UI.

---

## 6. Make foliage support stealth/readability instead of just decoration

The foliage occlusion system is close to becoming gameplay. Right now it mostly solves visibility.

I’d give foliage three roles:

1. small shrubs: readable cover/soft concealment
2. dense trees: path blockers / line-of-sight blockers
3. fruit shrubs: harvesting/resource hints

Since you already classify foliage as `"tree"` or `"shrub"`, add region metadata:

```gdscript
_set_region_tile(pos, "foliage_cover", foliage_kind)
```

Then enemies/projectiles can eventually ask:

```gdscript
get_region_type_at_tile(tile) == "foliage_cover"
```

Gameplay effect: foliage stops being visual noise and becomes tactical terrain.

---

## 7. Make compound ingress points feel defended

You generate compound ingress tiles, but I’d make each ingress a small encounter node.

For each ingress:

- clear 2–3 tiles outside
- add cover props nearby
- optionally place turret anchor
- add hazard marker / lights / barricade

Even without enemies, this improves composition.

Pseudo-hook:

```gdscript
func _decorate_compound_ingress(ingress: Vector2i, rect: Rect2i) -> void:
	var inward := _get_compound_ingress_inward(ingress, rect)
	var outside := ingress - inward

	for offset in [Vector2i.LEFT, Vector2i.RIGHT]:
		var cover_tile := outside + offset * 2
		if _generated_floor_cells.has(cover_tile):
			_set_region_tile(cover_tile, "cover_anchor", "compound_ingress")
```

Gameplay effect: every entrance becomes a “threshold moment.”

---

## 8. Add encounter intensity zones

This is the big design upgrade.

The map should not feel uniformly random. It should have intensity gradients:

- spawn area: low threat
- outer wilderness: light threat/resources
- compound perimeter: medium threat
- interior rooms: tense close quarters
- portal area: high mystery/reward
- farthest rooms: objective/reward

Add a function:

```gdscript
func get_intensity_at_tile(tile: Vector2i) -> float:
	var spawn := get_player_spawn()
	var dist := tile.distance_to(spawn)
	var max_dist := Vector2i(procgen_node.map_size).length()
	var value := clampf(dist / max_dist, 0.0, 1.0)

	var region := get_region_type_at_tile(tile)
	if region == "interior_floor":
		value += 0.20
	elif region == "interior_threshold":
		value += 0.10
	elif region == "portal_plaza":
		value += 0.30

	return clampf(value, 0.0, 1.0)
```

Then enemies, props, loot, hazards, and lighting can all use it.

Gameplay effect: the world starts having pacing.

---

## 9. Improve “first 10 seconds” readability

This matters a lot. The player spawn should always have:

- clear local floor
- no foliage crowding
- visible path outward
- one landmark visible nearby
- no immediate wall/portal clutter
- maybe one low-value resource node

You already have spawn clearance for foliage and props. I’d add a formal “spawn clearing stamp”:

```gdscript
func _stamp_spawn_clearing(map_size: Vector2i) -> void:
	var spawn := get_player_spawn()
	for x in range(-5, 6):
		for y in range(-4, 5):
			var tile := spawn + Vector2i(x, y)
			if tile.x <= 1 or tile.y <= 1 or tile.x >= map_size.x - 2 or tile.y >= map_size.y - 2:
				continue
			_set_floor_tile(tile)
			_set_region_tile(tile, "spawn_clearing", "safe")
```

Call it after compound/interior generation but before foliage/props.

Gameplay effect: the map starts cleanly instead of the player spawning into procedural soup.

---

## 10. Make portals require commitment

With the portal ramp system, I’d make the player deliberately walk onto it and pause briefly before teleporting. Not a long cutscene. Just enough for “oh, I’m entering this thing.”

Recommended feel:

- trigger only near top of ramp
- slow movement to ~0.75x on ramp
- activation frame delay
- small arrival lockout
- arrive at ramp bottom, not center
- destination portal flashes first, then player appears

You already have most of that. The key is tuning:

```gdscript
portal_trigger_radius = 10.0 to 12.0
portal_teleport_cooldown_frames = 45 to 75
portal_arrival_offset = Vector2(0, 54)
portal_arrival_animation_delay_seconds = 0.35 to 0.65
```

I would lower the arrival delay from `1.10` to around `0.45`. 1.10 seconds risks feeling laggy unless the player is frozen/intentionally staged.

---

# The best gameplay upgrade overall

The single best improvement would be this:

> Add explicit map “intent zones” and make every spawned thing ask what zone it is in.

You already have the start of that with `_region_tiles`. Expand it.

Use region types like:

```txt id="t0ggii"
spawn_clearing
compound_exterior
compound_ingress
compound_building
interior_floor
interior_threshold
portal_plaza
destroyed_wall_floor
foliage_cover
resource_patch
encounter_anchor
```

Then foliage, props, portals, enemies, loot, minimap, music, lighting, and navigation can all respond to the same semantic map.

That is the difference between:

> “the generator placed stuff”

and

> “the world has structure.”


# ADDENDUM : 


Below are exact patch-style changes for the gameplay/feel examples I gave. These all target `ProcGenTilemap.gd`, the file you pasted. 

---

## 0. Add gameplay-feel exports

Find this block near the top:

```gdscript
@export_range(0.0, 0.6, 0.01) var open_layout_carve_ratio: float = 0.20
@export_group("Constructed Interior Region", "interior_region")
```

Replace it with:

```gdscript
@export_range(0.0, 0.6, 0.01) var open_layout_carve_ratio: float = 0.20

@export_group("Gameplay Feel / Intent Zones", "intent")
@export var intent_spawn_clearing_enabled: bool = true
@export var intent_spawn_clearing_half_extents_tiles: Vector2i = Vector2i(5, 4)
@export var intent_soft_paths_enabled: bool = true
@export_range(0, 4, 1) var intent_soft_path_width: int = 1
@export var intent_portal_plazas_enabled: bool = true
@export var intent_portal_plaza_half_extents_tiles: Vector2i = Vector2i(3, 2)
@export var intent_mark_foliage_cover: bool = true
@export var intent_decorate_compound_ingress: bool = true
@export_group("", "")

@export_group("Constructed Interior Region", "interior_region")
```

---

## 1. Tune portal feel defaults

Find these portal exports:

```gdscript
@export_range(0, 96, 1) var portal_teleport_cooldown_frames: int = 24
@export_range(4.0, 48.0, 1.0) var portal_trigger_radius: float = 14.0
@export var portal_trigger_local_offset: Vector2 = Vector2(0, -65)
@export var portal_arrival_offset: Vector2 = Vector2(0, 54)
@export_range(0.0, 2.0, 0.05) var portal_arrival_animation_delay_seconds: float = 1.10
```

Replace with:

```gdscript
@export_range(0, 96, 1) var portal_teleport_cooldown_frames: int = 60
@export_range(4.0, 48.0, 1.0) var portal_trigger_radius: float = 12.0
@export var portal_trigger_local_offset: Vector2 = Vector2(0, -65)
@export var portal_arrival_offset: Vector2 = Vector2(0, 54)
@export_range(0.0, 2.0, 0.05) var portal_arrival_animation_delay_seconds: float = 0.50
```

This makes portals require slightly more commitment and reduces the “why am I waiting?” feeling on arrival.

---

## 2. Change `_fill_tilemaps()` to stamp spawn clearing and soft paths

Find this section inside `_fill_tilemaps()`:

```gdscript
if enable_compound_zone:
	_apply_compound_layout(map_size)
if interior_region_enabled:
	_apply_constructed_interior_region(map_size)
if use_cohesive_wall_visuals:
	_apply_wall_visuals(map_size)
_capture_generated_tile_state(map_size)
```

Replace it with:

```gdscript
if enable_compound_zone:
	_apply_compound_layout(map_size)
if interior_region_enabled:
	_apply_constructed_interior_region(map_size)

if intent_spawn_clearing_enabled:
	_stamp_spawn_clearing(map_size)

if intent_soft_paths_enabled:
	_carve_interest_paths(map_size)

if use_cohesive_wall_visuals:
	_apply_wall_visuals(map_size)
_capture_generated_tile_state(map_size)
```

---

## 3. Add spawn clearing + soft path helpers

Paste these functions near `_is_inside_compound_zone()` or before `_apply_compound_layout()`:

```gdscript
func _is_tile_inside_map(tile: Vector2i, map_size: Vector2i, margin: int = 1) -> bool:
	return tile.x >= margin and tile.y >= margin and tile.x < map_size.x - margin and tile.y < map_size.y - margin


func _stamp_spawn_clearing(map_size: Vector2i) -> void:
	if procgen_node == null:
		return

	var spawn := get_player_spawn()
	var half_extents := Vector2i(
		maxi(0, intent_spawn_clearing_half_extents_tiles.x),
		maxi(0, intent_spawn_clearing_half_extents_tiles.y)
	)

	for x in range(-half_extents.x, half_extents.x + 1):
		for y in range(-half_extents.y, half_extents.y + 1):
			var tile := spawn + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			_set_floor_tile(tile)
			_set_region_tile(tile, "spawn_clearing", "safe")


func _carve_interest_paths(map_size: Vector2i) -> void:
	if procgen_node == null:
		return

	var spawn := get_player_spawn()
	var path_width := maxi(0, intent_soft_path_width)

	for ingress in _last_compound_ingress:
		_carve_soft_path(spawn, ingress, path_width, map_size)

	for threshold in _last_interior_thresholds:
		_carve_soft_path(spawn, threshold, path_width, map_size)


func _carve_soft_path(from_tile: Vector2i, to_tile: Vector2i, width: int, map_size: Vector2i) -> void:
	var current := from_tile

	while current.x != to_tile.x:
		if to_tile.x > current.x:
			current.x += 1
		else:
			current.x -= 1
		_carve_path_brush(current, width, map_size)

	while current.y != to_tile.y:
		if to_tile.y > current.y:
			current.y += 1
		else:
			current.y -= 1
		_carve_path_brush(current, width, map_size)


func _carve_path_brush(center: Vector2i, width: int, map_size: Vector2i) -> void:
	for x in range(-width, width + 1):
		for y in range(-width, width + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			if walls_tilemap != null and walls_tilemap.get_cell_source_id(tile) >= 0:
				continue
			_set_floor_tile(tile)
			_set_region_tile(tile, "soft_path", "travel")
```

---

## 4. Make compound ingress points feel like threshold spaces

Find this section in `_apply_compound_layout()`:

```gdscript
for tile in ingress:
	_carve_compound_ingress(tile, rect, t)
```

Replace with:

```gdscript
for tile in ingress:
	_carve_compound_ingress(tile, rect, t)
	if intent_decorate_compound_ingress:
		_decorate_compound_ingress(tile, rect)
```

Then paste this helper near `_carve_compound_ingress()`:

```gdscript
func _decorate_compound_ingress(ingress: Vector2i, rect: Rect2i) -> void:
	if procgen_node == null:
		return

	var inward := _get_compound_ingress_inward(ingress, rect)
	var outward := -inward
	var map_size := procgen_node.map_size

	for step in range(1, 4):
		var approach_tile := ingress + outward * step
		if not _is_tile_inside_map(approach_tile, map_size, 1):
			continue
		_set_floor_tile(approach_tile)
		_set_region_tile(approach_tile, "compound_approach", "compound_ingress")

	var outside_anchor := ingress + outward * 2
	var side_axis := Vector2i(-inward.y, inward.x)

	for side in [-1, 1]:
		var cover_tile := outside_anchor + side_axis * side * 2
		if not _is_tile_inside_map(cover_tile, map_size, 1):
			continue
		if walls_tilemap != null and walls_tilemap.get_cell_source_id(cover_tile) >= 0:
			continue
		_set_region_tile(cover_tile, "cover_anchor", "compound_ingress")
```

---

## 5. Give interior rooms identity tags

Find this block in `_apply_constructed_interior_region()`:

```gdscript
var rooms := _build_constructed_interior_rooms(rect, hall_rect)
for room in rooms:
	_carve_interior_floor_rect(room, "room")
	_last_interior_rooms.append(room)
```

Replace it with:

```gdscript
var rooms := _build_constructed_interior_rooms(rect, hall_rect)
for room in rooms:
	var room_zone := _pick_room_zone(room, _last_interior_rooms.size())
	_carve_interior_floor_rect(room, room_zone)
	_last_interior_rooms.append(room)
```

Then paste this helper near `_build_constructed_interior_rooms()`:

```gdscript
func _pick_room_zone(room: Rect2i, room_index: int) -> String:
	var zones := [
		"storage",
		"security",
		"maintenance",
		"archive",
		"generator",
		"barracks",
		"lab"
	]

	var token := room.position + Vector2i(room_index * 37, 777)
	var index := _tile_noise_hash(token) % zones.size()
	return zones[index]
```

Optional but useful: tag interior props with the room zone.

Find this section inside `_place_interior_prop()`:

```gdscript
sprite.add_to_group("interior_runtime_props")
_ruin_prop_parent.add_child(sprite)
sprite.global_position = _tile_to_world_position(pos) + base_offset + _interior_prop_jitter(pos)
_interior_prop_nodes.append(sprite)
```

Replace with:

```gdscript
sprite.add_to_group("interior_runtime_props")
sprite.set_meta("source_tile", pos)
sprite.set_meta("region_zone", String(get_region_data_at_tile(pos).get("zone", "room")))
_ruin_prop_parent.add_child(sprite)
sprite.global_position = _tile_to_world_position(pos) + base_offset + _interior_prop_jitter(pos)
_interior_prop_nodes.append(sprite)
```

---

## 6. Add portal plazas and portal approach paths

First add this helper block near `_configure_portal_pair()`:

```gdscript
func _is_tile_currently_visible(tile: Vector2i) -> bool:
	if not enable_streaming_reveal:
		return true
	return _revealed_chunks.has(_tile_to_chunk(tile))


func _set_floor_tile_and_generated_state(pos: Vector2i, region_type: String = "", zone: String = "") -> void:
	if floor_tilemap == null or walls_tilemap == null:
		return

	var source_id := _select_floor_source_id(pos)
	var atlas := _select_floor_coord(pos)

	_generated_floor_cells[pos] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
	}
	_generated_wall_cells.erase(pos)
	_wall_health.erase(pos)

	if not region_type.is_empty():
		_set_region_tile(pos, region_type, zone)

	if _is_tile_currently_visible(pos):
		floor_tilemap.set_cell(pos, source_id, atlas, 0)
		walls_tilemap.erase_cell(pos)
		if build_runtime_wall_collision:
			_remove_runtime_wall_body(pos)


func _stamp_portal_plaza(center: Vector2i, map_size: Vector2i) -> void:
	if not intent_portal_plazas_enabled:
		return

	var half_extents := Vector2i(
		maxi(0, intent_portal_plaza_half_extents_tiles.x),
		maxi(0, intent_portal_plaza_half_extents_tiles.y)
	)

	for x in range(-half_extents.x, half_extents.x + 1):
		for y in range(-half_extents.y, half_extents.y + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			_set_floor_tile_and_generated_state(tile, "portal_plaza", "portal")
			_remove_foliage(tile)


func _carve_generated_soft_path(from_tile: Vector2i, to_tile: Vector2i, width: int, map_size: Vector2i) -> void:
	var current := from_tile

	while current.x != to_tile.x:
		if to_tile.x > current.x:
			current.x += 1
		else:
			current.x -= 1
		_carve_generated_path_brush(current, width, map_size)

	while current.y != to_tile.y:
		if to_tile.y > current.y:
			current.y += 1
		else:
			current.y -= 1
		_carve_generated_path_brush(current, width, map_size)


func _carve_generated_path_brush(center: Vector2i, width: int, map_size: Vector2i) -> void:
	for x in range(-width, width + 1):
		for y in range(-width, width + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			if _generated_wall_cells.has(tile):
				continue
			_set_floor_tile_and_generated_state(tile, "soft_path", "travel")
```

Now change `_configure_portal_pair()` in two places.

Find this inside the `for prop in spawned:` loop:

```gdscript
if bool(resolved_tile.get("ok", false)):
	var safe_tile := resolved_tile["tile"] as Vector2i
	prop.global_position = _portal_tile_to_world(safe_tile)
	prop.set_meta("source_tile", safe_tile)
	blocked_tiles[safe_tile] = true
	portal_props.append(prop)
```

Replace with:

```gdscript
if bool(resolved_tile.get("ok", false)):
	var safe_tile := resolved_tile["tile"] as Vector2i
	_stamp_portal_plaza(safe_tile, map_size)
	prop.global_position = _portal_tile_to_world(safe_tile)
	prop.set_meta("source_tile", safe_tile)
	blocked_tiles[safe_tile] = true
	portal_props.append(prop)
```

Then find this in the `while portal_props.size() < 2:` loop:

```gdscript
var tile := tile_result["tile"] as Vector2i
var prop := _spawn_guaranteed_ruin_prop(portal_definition, tile)
```

Replace with:

```gdscript
var tile := tile_result["tile"] as Vector2i
_stamp_portal_plaza(tile, map_size)
var prop := _spawn_guaranteed_ruin_prop(portal_definition, tile)
```

Finally, near the end of `_configure_portal_pair()`, find:

```gdscript
if portal_props.size() < 2:
	return

var first: Area2D = _attach_portal_teleporter(portal_props[0])
var second: Area2D = _attach_portal_teleporter(portal_props[1])
```

Replace with:

```gdscript
if portal_props.size() < 2:
	return

while portal_props.size() > 2:
	var extra := portal_props.pop_back()
	if extra != null and is_instance_valid(extra):
		extra.queue_free()

if intent_soft_paths_enabled:
	var spawn_tile := get_player_spawn()
	var portal_a_tile := _get_prop_source_tile(portal_props[0])
	var portal_b_tile := _get_prop_source_tile(portal_props[1])
	_carve_generated_soft_path(spawn_tile, portal_a_tile, intent_soft_path_width, map_size)
	_carve_generated_soft_path(spawn_tile, portal_b_tile, intent_soft_path_width, map_size)

var first: Area2D = _attach_portal_teleporter(portal_props[0])
var second: Area2D = _attach_portal_teleporter(portal_props[1])
```

---

## 7. Fix platform portal arrival offset and teleporter property drift

Find this block inside `_attach_portal_teleporter()`:

```gdscript
if portal_definition != null and portal_definition.portal_platform_enabled:
	teleporter.position = portal_definition.portal_platform_trigger_offset
	teleporter.set("ramp_top_local_offset", Vector2.ZERO)
	teleporter.set(
		"ramp_bottom_local_offset",
		portal_definition.portal_platform_bottom_offset - portal_definition.portal_platform_trigger_offset
	)
	teleporter.set("ramp_lane_half_width", portal_definition.portal_platform_lane_half_width)
	teleporter.set("ramp_bottom_width", portal_definition.portal_platform_bottom_width)
	teleporter.set("ramp_top_width", portal_definition.portal_platform_top_width)
	teleporter.set("ramp_side_block_width", portal_definition.portal_platform_side_block_width)
	teleporter.set("ramp_side_block_height", portal_definition.portal_platform_side_block_height)
	teleporter.set("ramp_required_elevation", portal_definition.portal_platform_required_elevation)
	teleporter.set("ramp_max_elevation", portal_definition.portal_platform_max_elevation)
	teleporter.set("ramp_speed_multiplier", portal_definition.portal_platform_speed_multiplier)
	teleporter.set("ramp_dual_approach", portal_definition.portal_platform_dual_approach)
	teleporter.set("fx_offset", portal_trigger_local_offset - portal_definition.portal_platform_trigger_offset)
	teleporter.set("generate_side_block_collision", portal_definition.collision_scene == null)
	teleporter.set("arrival_offset", Vector2.ZERO)
else:
	teleporter.position = portal_trigger_local_offset
	teleporter.set("arrival_offset", portal_arrival_offset)
```

Replace with:

```gdscript
if portal_definition != null and portal_definition.portal_platform_enabled:
	var ramp_bottom_offset := portal_definition.portal_platform_bottom_offset - portal_definition.portal_platform_trigger_offset

	teleporter.position = portal_definition.portal_platform_trigger_offset
	teleporter.set("ramp_top_local_offset", Vector2.ZERO)
	teleporter.set("ramp_bottom_local_offset", ramp_bottom_offset)
	teleporter.set("ramp_lane_half_width", portal_definition.portal_platform_lane_half_width)
	teleporter.set("ramp_bottom_width", portal_definition.portal_platform_bottom_width)
	teleporter.set("ramp_top_width", portal_definition.portal_platform_top_width)
	teleporter.set("ramp_side_block_width", portal_definition.portal_platform_side_block_width)
	teleporter.set("ramp_side_block_extra_height", portal_definition.portal_platform_side_block_height)
	teleporter.set("ramp_required_elevation", portal_definition.portal_platform_required_elevation)
	teleporter.set("ramp_max_elevation", portal_definition.portal_platform_max_elevation)
	teleporter.set("ramp_speed_multiplier", portal_definition.portal_platform_speed_multiplier)
	teleporter.set("ramp_dual_approach", portal_definition.portal_platform_dual_approach)
	teleporter.set("fx_offset", portal_trigger_local_offset - portal_definition.portal_platform_trigger_offset)
	teleporter.set("generate_side_block_collision", portal_definition.collision_scene == null)
	teleporter.set("arrival_offset", ramp_bottom_offset)
	teleporter.set("require_ramp_elevation_to_teleport", true)
	teleporter.set("require_body_still_in_trigger_at_teleport_frame", true)
	teleporter.set("stop_body_velocity_on_arrival", true)
else:
	teleporter.position = portal_trigger_local_offset
	teleporter.set("arrival_offset", portal_arrival_offset)
	teleporter.set("require_ramp_elevation_to_teleport", false)
	teleporter.set("require_body_still_in_trigger_at_teleport_frame", true)
	teleporter.set("stop_body_velocity_on_arrival", true)
```

---

## 8. Make destroyed walls become meaningful terrain

Find this block inside `damage_wall_tile()`:

```gdscript
_generated_wall_cells.erase(pos)
_generated_floor_cells[pos] = {
	"source_id": _select_floor_source_id(pos),
	"atlas": _select_floor_coord(pos),
}
_set_floor_tile(pos)
minimap_tile_changed.emit(pos, "floor")
```

Replace with:

```gdscript
_generated_wall_cells.erase(pos)
_set_destroyed_wall_floor_tile(pos)
minimap_tile_changed.emit(pos, "destroyed_wall_floor")
```

Then paste this helper near `_set_hole_tile()`:

```gdscript
func _set_destroyed_wall_floor_tile(pos: Vector2i) -> void:
	if floor_tilemap == null or walls_tilemap == null:
		return

	var source_id := _select_floor_source_id(pos)
	var atlas := _select_floor_coord(pos)

	_generated_floor_cells[pos] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
	}

	floor_tilemap.set_cell(pos, source_id, atlas, 0)
	walls_tilemap.erase_cell(pos)
	_wall_health.erase(pos)
	_set_region_tile(pos, "destroyed_wall_floor", "debris")
```

---

## 9. Mark foliage as tactical cover

Find this section near the end of `_place_foliage()`:

```gdscript
_foliage_nodes[pos] = {
	"node": sprite,
	"world_pos": world_pos,
	"base_y": world_pos.y + texture_size.y * 0.5,
	"size": texture_size,
	"kind": foliage_kind,
	"has_collision": has_trunk_collision,
}
	
# Optionally spawn fruit on this foliage
if enable_fruit_spawning and _fruit_texture != null and _should_place_fruit(pos, foliage_kind):
	_place_fruit(sprite, pos, texture_size, foliage_kind)
```

Replace with:

```gdscript
_foliage_nodes[pos] = {
	"node": sprite,
	"world_pos": world_pos,
	"base_y": world_pos.y + texture_size.y * 0.5,
	"size": texture_size,
	"kind": foliage_kind,
	"has_collision": has_trunk_collision,
}

if intent_mark_foliage_cover and get_region_type_at_tile(pos) == "exterior":
	_set_region_tile(pos, "foliage_cover", foliage_kind)
	
# Optionally spawn fruit on this foliage
if enable_fruit_spawning and _fruit_texture != null and _should_place_fruit(pos, foliage_kind):
	_place_fruit(sprite, pos, texture_size, foliage_kind)
```

Then modify `_remove_foliage()`.

Find:

```gdscript
func _remove_foliage(pos: Vector2i) -> void:
	var entry = _foliage_nodes.get(pos, null)
	var node := entry as Node2D
	if entry is Dictionary:
		node = entry.get("node", null) as Node2D
	if node != null and is_instance_valid(node):
		node.queue_free()
	_foliage_nodes.erase(pos)
```

Replace with:

```gdscript
func _remove_foliage(pos: Vector2i) -> void:
	var entry = _foliage_nodes.get(pos, null)
	var node := entry as Node2D
	if entry is Dictionary:
		node = entry.get("node", null) as Node2D
	if node != null and is_instance_valid(node):
		node.queue_free()
	_foliage_nodes.erase(pos)

	if get_region_type_at_tile(pos) == "foliage_cover":
		_region_tiles.erase(pos)
```

---

## 10. Make streaming reveal prioritize interesting areas

Find this function:

```gdscript
func _queue_chunk_for_reveal(chunk_pos: Vector2i, center_tile: Vector2i) -> void:
	if _revealed_chunks.has(chunk_pos) or _queued_chunks.has(chunk_pos):
		return
	_queued_chunks[chunk_pos] = true
	var tiles := _get_chunk_tiles(chunk_pos)
	tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(center_tile) < b.distance_squared_to(center_tile))
	for tile in tiles:
		_streaming_reveal_queue.append(tile)
```

Replace with:

```gdscript
func _queue_chunk_for_reveal(chunk_pos: Vector2i, center_tile: Vector2i) -> void:
	if _revealed_chunks.has(chunk_pos) or _queued_chunks.has(chunk_pos):
		return
	_queued_chunks[chunk_pos] = true
	var tiles := _get_chunk_tiles(chunk_pos)
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _streaming_reveal_priority(a, center_tile) < _streaming_reveal_priority(b, center_tile)
	)
	for tile in tiles:
		_streaming_reveal_queue.append(tile)
```

Then paste this helper near `_queue_chunk_for_reveal()`:

```gdscript
func _streaming_reveal_priority(tile: Vector2i, center_tile: Vector2i) -> float:
	var score := float(tile.distance_squared_to(center_tile))
	var region := get_region_type_at_tile(tile)

	match region:
		"spawn_clearing":
			score -= 240.0
		"compound_approach":
			score -= 180.0
		"compound_ingress":
			score -= 160.0
		"soft_path":
			score -= 120.0
		"portal_plaza":
			score -= 220.0
		"interior_threshold":
			score -= 140.0
		"interior_floor":
			score -= 80.0
		"destroyed_wall_floor":
			score -= 60.0
		"foliage_cover":
			score += 30.0

	if _generated_wall_cells.has(tile):
		score += 12.0

	return score
```

---

## 11. Add map intensity API for future enemies/loot/hazards

Paste this near `get_region_type_at_tile()` / `get_region_data_at_tile()`:

```gdscript
func get_intensity_at_tile(tile: Vector2i) -> float:
	if procgen_node == null:
		return 0.0

	var spawn := get_player_spawn()
	var map_vector := Vector2(float(procgen_node.map_size.x), float(procgen_node.map_size.y))
	var max_dist := maxf(1.0, map_vector.length())
	var value := clampf(tile.distance_to(spawn) / max_dist, 0.0, 1.0)

	var region := get_region_type_at_tile(tile)

	match region:
		"spawn_clearing":
			value -= 0.35
		"soft_path":
			value -= 0.10
		"compound_approach":
			value += 0.08
		"cover_anchor":
			value += 0.10
		"interior_threshold":
			value += 0.15
		"interior_floor":
			value += 0.22
		"portal_plaza":
			value += 0.30
		"destroyed_wall_floor":
			value += 0.12
		"foliage_cover":
			value += 0.05

	if _last_compound_rect.size.x > 0 and _last_compound_rect.has_point(tile):
		value += 0.08

	if _last_interior_region_rect.size.x > 0 and _last_interior_region_rect.has_point(tile):
		value += 0.12

	return clampf(value, 0.0, 1.0)
```

This gives future enemy spawners, loot tables, ambient audio, hazard systems, and minimap effects a single scalar to ask: “How spicy is this tile?”

---

## 12. Fix tile center placement

Find:

```gdscript
func _tile_to_world_position(pos: Vector2i) -> Vector2:
	if floor_tilemap == null:
		return Vector2.ZERO
	var local := floor_tilemap.map_to_local(pos)
	var tile_size := _get_tile_size()
	return floor_tilemap.to_global(local + tile_size * 0.5)
```

Replace with:

```gdscript
func _tile_to_world_position(pos: Vector2i) -> Vector2:
	if floor_tilemap == null:
		return Vector2.ZERO
	return floor_tilemap.to_global(floor_tilemap.map_to_local(pos))
```

This makes props, foliage, portal props, and minimap tile conversion agree on what “tile center” means.

---

## 13. Fix foliage occlusion bubble actually enabling

Find:

```gdscript
func _apply_foliage_occlusion_material(material: ShaderMaterial, active_centers: Array[Vector2]) -> void:
	var bubble_count := mini(active_centers.size(), _get_foliage_occlusion_bubble_limit())
	material.set_shader_parameter("bubble_radius", foliage_player_occlusion_radius)
	material.set_shader_parameter("bubble_softness", foliage_player_occlusion_softness)
	material.set_shader_parameter("bubble_alpha", foliage_player_occlusion_alpha)
	material.set_shader_parameter("bubble_enabled", false)
	material.set_shader_parameter("bubble_count", bubble_count)
	for bubble_index in range(FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES):
		var center := active_centers[bubble_index] if bubble_index < bubble_count else Vector2.ZERO
		material.set_shader_parameter("bubble_center_%d" % bubble_index, center)
```

Replace with:

```gdscript
func _apply_foliage_occlusion_material(material: ShaderMaterial, active_centers: Array[Vector2]) -> void:
	var bubble_count := mini(active_centers.size(), _get_foliage_occlusion_bubble_limit())
	material.set_shader_parameter("bubble_radius", foliage_player_occlusion_radius)
	material.set_shader_parameter("bubble_softness", foliage_player_occlusion_softness)
	material.set_shader_parameter("bubble_alpha", foliage_player_occlusion_alpha)
	material.set_shader_parameter("bubble_enabled", bubble_count > 0)
	material.set_shader_parameter("bubble_count", bubble_count)

	for bubble_index in range(FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES):
		var center := Vector2.ZERO
		if bubble_index < bubble_count:
			center = active_centers[bubble_index]
		material.set_shader_parameter("bubble_center_%d" % bubble_index, center)
```

---

## 14. Clear runtime wall collision on regeneration

Find this block inside `_fill_tilemaps()`:

```gdscript
if clear_first:
	floor_tilemap.clear()
	walls_tilemap.clear()
	_wall_health.clear()
	_clear_region_metadata()
	_clear_foliage()
	_clear_interior_props()
	_clear_ruin_props()
	_clear_horizontal_wall_overlays()
```

Replace with:

```gdscript
if clear_first:
	floor_tilemap.clear()
	walls_tilemap.clear()
	_wall_health.clear()
	_clear_region_metadata()
	_clear_foliage()
	_clear_interior_props()
	_clear_ruin_props()
	_clear_horizontal_wall_overlays()
	_clear_runtime_wall_collision()
	_rebuild_runtime_wall_collision_debug()
```

---

## 15. Normalize suspicious indentation

Find this in `_apply_constructed_interior_region()`:

```gdscript
for x in range(rect.position.x, rect.end.x):
	for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			_set_interior_wall_tile(tile)
			_set_region_tile(tile, "interior_wall", "military_complex")
```

Replace with:

```gdscript
for x in range(rect.position.x, rect.end.x):
	for y in range(rect.position.y, rect.end.y):
		var tile := Vector2i(x, y)
		_set_interior_wall_tile(tile)
		_set_region_tile(tile, "interior_wall", "military_complex")
```

Find this in `_carve_interior_floor_rect()`:

```gdscript
for x in range(rect.position.x, rect.end.x):
	for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			_set_interior_floor_tile(tile, zone)
			_set_region_tile(tile, "interior_floor", zone)
```

Replace with:

```gdscript
for x in range(rect.position.x, rect.end.x):
	for y in range(rect.position.y, rect.end.y):
		var tile := Vector2i(x, y)
		_set_interior_floor_tile(tile, zone)
		_set_region_tile(tile, "interior_floor", zone)
```

---

## 16. Keep destroyed wall neighbor state stable in streaming

Find `_refresh_wall_neighbors()`:

```gdscript
func _refresh_wall_neighbors(center_tile: Vector2i) -> void:
	for x in range(center_tile.x - 1, center_tile.x + 2):
		for y in range(center_tile.y - 1, center_tile.y + 2):
			var pos := Vector2i(x, y)
			if walls_tilemap.get_cell_source_id(pos) < 0:
				continue
			var source = high_walls_source_id if use_high_walls else walls_source_id
			walls_tilemap.set_cell(pos, source, _select_wall_coord(pos))
```

Replace with:

```gdscript
func _refresh_wall_neighbors(center_tile: Vector2i) -> void:
	for x in range(center_tile.x - 1, center_tile.x + 2):
		for y in range(center_tile.y - 1, center_tile.y + 2):
			var pos := Vector2i(x, y)
			if walls_tilemap.get_cell_source_id(pos) < 0:
				continue

			var source := high_walls_source_id if use_high_walls else walls_source_id
			var coord := _select_wall_coord(pos)
			var alternative := walls_tilemap.get_cell_alternative_tile(pos)

			walls_tilemap.set_cell(pos, source, coord, alternative)

			if _generated_wall_cells.has(pos):
				_generated_wall_cells[pos] = {
					"source_id": source,
					"atlas": coord,
					"alternative": alternative,
				}
```

---

## 17. Add navigation fallback

Find `_flush_navigation_rebuild()`:

```gdscript
func _flush_navigation_rebuild() -> void:
	_navigation_rebuild_deferred = false
	_navigation_rebuild_pending = false
	for navigation_node in get_tree().get_nodes_in_group("navigation"):
		if navigation_node != null and navigation_node.has_method("rebuild"):
			navigation_node.call("rebuild")
```

Replace with:

```gdscript
func _flush_navigation_rebuild() -> void:
	_navigation_rebuild_deferred = false
	_navigation_rebuild_pending = false

	var rebuilt := false

	for navigation_node in get_tree().get_nodes_in_group("navigation"):
		if navigation_node != null and navigation_node.has_method("rebuild"):
			navigation_node.call("rebuild")
			rebuilt = true

	if not rebuilt and nav_region != null:
		nav_region.bake_navigation_polygon(false)
```

---

## 18. Include intensity and zones in `get_level_data()`

Find this part in `get_level_data()`:

```gdscript
"region_tiles": _region_tiles.duplicate(true),
"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
"wall_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
"world_profile": get_planet_world_profile(),
```

Replace with:

```gdscript
"region_tiles": _region_tiles.duplicate(true),
"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
"wall_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
"world_profile": get_planet_world_profile(),
"intent_zones_enabled": true,
```

I would not dump an intensity value for every tile yet because that can get large. Keep `get_intensity_at_tile(tile)` as an API.

---

## Apply order

Apply in this order:

1. Exports.
2. `_fill_tilemaps()` change.
3. Helper functions.
4. Compound ingress replacement.
5. Interior room zone replacement.
6. Portal plaza changes.
7. Portal teleporter property block.
8. Destroyed wall change.
9. Foliage cover change.
10. Streaming priority change.
11. Tile center / occlusion / cleanup fixes.

After this, run Godot once and fix parse errors before tuning values. This is enough behavior change that `custodian/docs/ai_context/CURRENT_STATE.md` should mention: procgen now emits semantic intent zones (`spawn_clearing`, `soft_path`, `portal_plaza`, `foliage_cover`, `destroyed_wall_floor`) and exposes `get_intensity_at_tile(tile)` for downstream systems.
