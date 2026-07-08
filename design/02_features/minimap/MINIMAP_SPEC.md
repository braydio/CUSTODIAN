
Below is a **Codex-ready implementation spec** for a custom CUSTODIAN minimap.

Core decision: **build a custom data-driven minimap**, not an addon and not a tiny duplicate camera render. Your `ProcGenTilemap` already captures generated floor/wall state and emits `level_data_ready(data)` after generation, so the minimap should consume that data directly.  

---

# CUSTODIAN Tactical Minimap Implementation Spec

## Goal

Implement a tactical minimap UI for the Godot runtime that shows:

* generated floor/wall layout
* player position
* room centers / major compound footprint
* optional enemy/objective pips
* future fog/reveal support

The minimap should look like a **military tactical sensor panel**, not a camera thumbnail.

---

## Documentation / workflow note

Active runtime is Godot under `custodian/`, and Godot implementation specs should live under `./design/` before runtime changes unless Codex is doing direct implementation. 

Create:

```text
design/02_features/minimap/MINIMAP_SYSTEM.md
design/02_features/minimap/MINIMAP_SYSTEM_CODE.md
```

After implementation, update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
```

**Documentation drift warning:** older terminal docs mention a read-only sector map fetched from `/snapshot`; that is legacy terminal-era behavior, not the Godot runtime minimap target. The active implementation should integrate with `ProcGenTilemap`, `UI`, and the current Godot scene tree instead. 

---

# Recommended architecture

## Use this structure

```text
custodian/game/ui/minimap/
  minimap_panel.tscn
  minimap_controller.gd
  minimap_view.gd
  minimap_types.gd       optional, later
```

## Scene tree

Add this under the existing `UI` CanvasLayer:

```text
UI
└── MinimapPanel
    ├── Background
    ├── MinimapView
    └── Frame
```

Use a `Control`-based UI, not `SubViewport`, for production.

---

# Why data-driven

Your current procgen code already:

* fills floor/wall TileMap layers
* captures `_generated_floor_cells`
* captures `_generated_wall_cells`
* exposes `get_level_data()`
* emits `level_data_ready(data)` after generation

So the minimap should not rescan the visual world every frame. It should receive a compact terrain map once, build a tiny texture, then only redraw dynamic pips.

---

# Required changes to `ProcGenTilemap`

## File

```text
custodian/game/world/procgen/proc_gen_tilemap.gd
```

## Add terrain data to `get_level_data()`

Your current `get_level_data()` returns map metadata like `map_size`, spawn, rooms, compound rect, ingress, buildings, and world profile. 

Add floor/wall cell arrays:

```gdscript
func _dict_keys_as_vector2i_array(source: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key in source.keys():
		if key is Vector2i:
			result.append(key)
	return result
```

Then update `get_level_data()`:

```gdscript
func get_level_data() -> Dictionary:
	return {
		"map_size": procgen_node.map_size,
		"tile_size": get_runtime_tile_size(),
		"player_spawn": get_player_spawn(),
		"rooms": get_room_centers(),
		"rooms_by_distance": get_rooms_by_distance_from_spawn(),
		"corridor_spawns": get_corridor_spawn_points(),
		"random_floor_tiles": get_random_floor_tiles_in_rooms(20),
		"compound_rect": _last_compound_rect,
		"compound_ingress": _last_compound_ingress,
		"compound_buildings": _last_compound_buildings,
		"world_profile": get_planet_world_profile(),
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"wall_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
	}
```

## Add public coordinate helpers

Your script already has private `_global_to_tile()` and `get_runtime_tile_size()`.  Add public wrappers:

```gdscript
func global_to_minimap_tile(global_position: Vector2) -> Vector2i:
	return _global_to_tile(global_position)


func minimap_tile_to_global(tile: Vector2i) -> Vector2:
	if floor_tilemap != null:
		return floor_tilemap.to_global(floor_tilemap.map_to_local(tile))
	return Vector2.ZERO
```

## Add terrain-change signal for destructible walls

Your `damage_wall_tile()` already changes a destroyed wall into a floor tile and updates `_generated_wall_cells` / `_generated_floor_cells`.  Add:

```gdscript
signal minimap_tile_changed(tile: Vector2i, terrain_kind: String)
```

Inside `damage_wall_tile()`, after the wall becomes floor:

```gdscript
minimap_tile_changed.emit(pos, "floor")
```

This lets the minimap update after wall destruction without full regeneration.

---

# `minimap_view.gd`

## Purpose

Draw the tactical map.

This node should:

* build a cached `ImageTexture` from floor/wall cells
* draw that cached texture scaled into the panel
* draw dynamic pips each frame
* avoid per-tile drawing every `_draw()` unless debugging

## File

```text
custodian/game/ui/minimap/minimap_view.gd
```

## Script

```gdscript
class_name MinimapView
extends Control

@export var background_color: Color = Color(0.025, 0.030, 0.032, 0.95)
@export var floor_color: Color = Color(0.18, 0.20, 0.19, 1.0)
@export var wall_color: Color = Color(0.045, 0.055, 0.060, 1.0)
@export var compound_color: Color = Color(0.28, 0.32, 0.18, 0.65)
@export var room_color: Color = Color(0.42, 0.48, 0.28, 0.85)
@export var player_color: Color = Color(0.75, 0.95, 0.95, 1.0)
@export var enemy_color: Color = Color(0.85, 0.20, 0.16, 1.0)
@export var objective_color: Color = Color(0.95, 0.72, 0.22, 1.0)

@export var map_padding_px: float = 6.0
@export var player_pip_radius_px: float = 3.0
@export var enemy_pip_radius_px: float = 2.0
@export var room_marker_radius_px: float = 1.5

var map_size: Vector2i = Vector2i.ZERO
var tile_size: Vector2 = Vector2(32, 32)
var floor_cells: Array[Vector2i] = []
var wall_cells: Array[Vector2i] = []
var rooms: Array = []
var compound_rect: Rect2i = Rect2i()
var compound_ingress: Array = []
var compound_buildings: Array = []

var map_texture: ImageTexture
var procgen_tilemap: Node = null
var player_node: Node2D = null
var enemy_nodes: Array[Node2D] = []
var objective_nodes: Array[Node2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)


func set_level_data(data: Dictionary) -> void:
	map_size = data.get("map_size", Vector2i.ZERO)
	tile_size = data.get("tile_size", Vector2(32, 32))
	floor_cells = data.get("floor_cells", [])
	wall_cells = data.get("wall_cells", [])
	rooms = data.get("rooms", [])
	compound_rect = data.get("compound_rect", Rect2i())
	compound_ingress = data.get("compound_ingress", [])
	compound_buildings = data.get("compound_buildings", [])
	_rebuild_map_texture()
	queue_redraw()


func set_procgen_tilemap(node: Node) -> void:
	procgen_tilemap = node


func set_player(node: Node2D) -> void:
	player_node = node


func set_enemies(nodes: Array[Node2D]) -> void:
	enemy_nodes = nodes


func set_objectives(nodes: Array[Node2D]) -> void:
	objective_nodes = nodes


func update_tile(tile: Vector2i, terrain_kind: String) -> void:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_size.x or tile.y >= map_size.y:
		return

	if terrain_kind == "floor":
		if not floor_cells.has(tile):
			floor_cells.append(tile)
		wall_cells.erase(tile)
	elif terrain_kind == "wall":
		if not wall_cells.has(tile):
			wall_cells.append(tile)
		floor_cells.erase(tile)

	_rebuild_map_texture()
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _rebuild_map_texture() -> void:
	if map_size.x <= 0 or map_size.y <= 0:
		map_texture = null
		return

	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	image.fill(background_color)

	for tile in floor_cells:
		if _is_tile_inside(tile):
			image.set_pixel(tile.x, tile.y, floor_color)

	for tile in wall_cells:
		if _is_tile_inside(tile):
			image.set_pixel(tile.x, tile.y, wall_color)

	map_texture = ImageTexture.create_from_image(image)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color, true)

	if map_texture == null or map_size.x <= 0 or map_size.y <= 0:
		return

	var map_rect := _get_map_rect()
	draw_texture_rect(map_texture, map_rect, false)

	_draw_compound_overlay(map_rect)
	_draw_room_markers(map_rect)
	_draw_objective_pips(map_rect)
	_draw_enemy_pips(map_rect)
	_draw_player_pip(map_rect)


func _get_map_rect() -> Rect2:
	var available := size - Vector2(map_padding_px * 2.0, map_padding_px * 2.0)
	var scale := min(available.x / float(map_size.x), available.y / float(map_size.y))
	var draw_size := Vector2(float(map_size.x), float(map_size.y)) * scale
	var origin := (size - draw_size) * 0.5
	return Rect2(origin, draw_size)


func _tile_to_panel(tile: Vector2i, map_rect: Rect2) -> Vector2:
	var sx := map_rect.size.x / float(max(1, map_size.x))
	var sy := map_rect.size.y / float(max(1, map_size.y))
	return map_rect.position + Vector2((float(tile.x) + 0.5) * sx, (float(tile.y) + 0.5) * sy)


func _global_to_tile(global_position: Vector2) -> Vector2i:
	if procgen_tilemap != null and procgen_tilemap.has_method("global_to_minimap_tile"):
		return procgen_tilemap.call("global_to_minimap_tile", global_position)
	return Vector2i(
		int(round(global_position.x / max(1.0, tile_size.x))),
		int(round(global_position.y / max(1.0, tile_size.y)))
	)


func _draw_player_pip(map_rect: Rect2) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return
	var tile := _global_to_tile(player_node.global_position)
	if not _is_tile_inside(tile):
		return
	var p := _tile_to_panel(tile, map_rect)
	draw_circle(p, player_pip_radius_px + 1.5, Color.BLACK)
	draw_circle(p, player_pip_radius_px, player_color)


func _draw_enemy_pips(map_rect: Rect2) -> void:
	for enemy in enemy_nodes:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var tile := _global_to_tile(enemy.global_position)
		if not _is_tile_inside(tile):
			continue
		draw_circle(_tile_to_panel(tile, map_rect), enemy_pip_radius_px, enemy_color)


func _draw_objective_pips(map_rect: Rect2) -> void:
	for objective in objective_nodes:
		if objective == null or not is_instance_valid(objective):
			continue
		var tile := _global_to_tile(objective.global_position)
		if not _is_tile_inside(tile):
			continue
		draw_circle(_tile_to_panel(tile, map_rect), enemy_pip_radius_px + 1.0, objective_color)


func _draw_room_markers(map_rect: Rect2) -> void:
	for room_tile in rooms:
		if room_tile is Vector2i and _is_tile_inside(room_tile):
			draw_circle(_tile_to_panel(room_tile, map_rect), room_marker_radius_px, room_color)


func _draw_compound_overlay(map_rect: Rect2) -> void:
	if compound_rect.size.x <= 0 or compound_rect.size.y <= 0:
		return

	var sx := map_rect.size.x / float(max(1, map_size.x))
	var sy := map_rect.size.y / float(max(1, map_size.y))
	var rect := Rect2(
		map_rect.position + Vector2(compound_rect.position.x * sx, compound_rect.position.y * sy),
		Vector2(compound_rect.size.x * sx, compound_rect.size.y * sy)
	)
	draw_rect(rect, compound_color, false, 1.0)


func _is_tile_inside(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size.x and tile.y < map_size.y
```

---

# `minimap_controller.gd`

## Purpose

Find the runtime world objects, connect to procgen, and feed the minimap view.

## File

```text
custodian/game/ui/minimap/minimap_controller.gd
```

## Script

```gdscript
class_name MinimapController
extends Control

@export var minimap_view_path: NodePath
@export var procgen_tilemap_path: NodePath
@export var player_group_name: StringName = &"player"
@export var enemy_group_name: StringName = &"enemy"
@export var objective_group_name: StringName = &"objective"
@export var refresh_entities_interval: float = 0.25

var minimap_view: MinimapView
var procgen_tilemap: Node
var _refresh_accum: float = 0.0

func _ready() -> void:
	minimap_view = get_node_or_null(minimap_view_path) as MinimapView

	if procgen_tilemap_path != NodePath():
		procgen_tilemap = get_node_or_null(procgen_tilemap_path)

	if procgen_tilemap == null:
		procgen_tilemap = _find_procgen_tilemap()

	_connect_procgen()
	_refresh_dynamic_nodes()


func _process(delta: float) -> void:
	_refresh_accum += delta
	if _refresh_accum >= refresh_entities_interval:
		_refresh_accum = 0.0
		_refresh_dynamic_nodes()


func _find_procgen_tilemap() -> Node:
	var nodes := get_tree().get_nodes_in_group("procgen_tilemap")
	if not nodes.is_empty():
		return nodes[0]

	# Fallback by class name / script class.
	var root := get_tree().current_scene
	if root == null:
		return null
	return _find_child_by_class(root, "ProcGenTilemap")


func _find_child_by_class(root: Node, class_name_text: String) -> Node:
	if root.get_class() == class_name_text or root.is_class(class_name_text):
		return root
	if root.get_script() != null and String(root.get_script().get_global_name()) == class_name_text:
		return root

	for child in root.get_children():
		var found := _find_child_by_class(child, class_name_text)
		if found != null:
			return found
	return null


func _connect_procgen() -> void:
	if procgen_tilemap == null or minimap_view == null:
		push_warning("MinimapController: missing procgen_tilemap or minimap_view")
		return

	minimap_view.set_procgen_tilemap(procgen_tilemap)

	if procgen_tilemap.has_signal("level_data_ready"):
		procgen_tilemap.level_data_ready.connect(_on_level_data_ready)

	if procgen_tilemap.has_signal("minimap_tile_changed"):
		procgen_tilemap.minimap_tile_changed.connect(_on_minimap_tile_changed)

	if procgen_tilemap.has_method("get_level_data"):
		var data: Dictionary = procgen_tilemap.call("get_level_data")
		if data.has("map_size"):
			_on_level_data_ready(data)


func _on_level_data_ready(data: Dictionary) -> void:
	if minimap_view != null:
		minimap_view.set_level_data(data)


func _on_minimap_tile_changed(tile: Vector2i, terrain_kind: String) -> void:
	if minimap_view != null:
		minimap_view.update_tile(tile, terrain_kind)


func _refresh_dynamic_nodes() -> void:
	if minimap_view == null:
		return

	var player := get_tree().get_first_node_in_group(player_group_name) as Node2D
	if player != null:
		minimap_view.set_player(player)

	var enemies: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(enemy_group_name):
		if node is Node2D:
			enemies.append(node)

	var objectives: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(objective_group_name):
		if node is Node2D:
			objectives.append(node)

	minimap_view.set_enemies(enemies)
	minimap_view.set_objectives(objectives)
```

---

# `minimap_panel.tscn`

Create the scene manually in Godot or let Codex make it.

Recommended structure:

```text
MinimapPanel : Control
  script = minimap_controller.gd
  anchors = top-right
  size = 220x220

  Background : ColorRect
    anchors = full
    color = dark transparent black

  MinimapView : Control
    script = minimap_view.gd
    anchors = full
    margins = 12 px

  Frame : NinePatchRect
    texture = res://content/ui/map/map_frame_large_9slice.png
    anchors = full
    mouse_filter = ignore
```

Recommended layout:

```text
Position: top-right
Size: 220x220
Margin: 20 px from top/right
```

Terminal mode now reuses the same `MinimapPanel` / `MinimapView` path inside the command terminal tactical panel. The terminal instance should share live procgen terrain and actor pips with the HUD minimap, while exposing `local_to_world()` so terminal click-to-place workflows can convert panel input into world positions.

Passive ambient creatures should not use the hostile enemy marker. Hostile enemies remain red dots, while passive creatures such as Shrumbs use a distinct non-red marker from the same actor feed, classified through `ambient_critter` or `is_passive_enemy()`.

---

# Scene integration

Add to the active UI CanvasLayer:

```text
UI
└── MinimapPanel
```

Your scene already has a `UI` CanvasLayer and runtime systems like `ContractWorldLoader`, `WaveManager`, `EnemyDirector`, and a `Camera2D`, so the minimap should sit in UI rather than under world space. 

Add `ProcGenTilemap` to a group during `_ready()`:

```gdscript
add_to_group("procgen_tilemap")
```

That makes controller discovery reliable even if the contract world is instanced dynamically.

---

# Assets you need to make

## Required for MVP

**None.**

The minimap can be fully code-drawn using `Control._draw()`, rectangles, circles, and colors.

## Strongly recommended for final CUSTODIAN style

### 1. `map_frame_large_9slice.png`

```text
Path: custodian/content/ui/map/map_frame_large_9slice.png
Size: 128x128
9-slice margins: 24px
Background: transparent center
Purpose: tactical minimap frame
Style: dark metal, military instrument corners, subtle olive accents
```

You already discussed this asset earlier. This is the main one worth making.

### 2. `map_grid_tile.png`

```text
Path: custodian/content/ui/map/map_grid_tile.png
Size: 32x32
Background: transparent
Purpose: subtle grid overlay
Style: 1px dim olive/gray grid lines, very low contrast
```

Optional if you draw grid lines in code.

### 3. `minimap_icon_atlas_16.png`

```text
Path: custodian/content/ui/map/minimap_icon_atlas_16.png
Size: 128x16
Cell size: 16x16
Background: transparent
```

Icons:

```text
0 player
1 enemy_unknown
2 enemy_melee
3 enemy_ranged
4 objective
5 exit / extraction
6 supply
7 alert
```

Not needed immediately. Code-drawn pips are better for the first pass.

### 4. `map_noise_overlay_64.png`

```text
Path: custodian/content/ui/map/map_noise_overlay_64.png
Size: 64x64
Background: transparent
Purpose: subtle CRT/sensor imperfection
```

Optional polish only.

---

# Visual rules

Use these defaults:

```text
Floor: very dark desaturated gray-green
Wall: nearly black blue-gray
Player: pale cyan / white
Enemies: muted red
Objectives: amber
Rooms: dim olive dots
Compound outline: muted olive rectangle
```

Do **not** render the actual floor/wall art into the minimap. The minimap should simplify the world into readable tactical geometry.

---

# Controls / UX behavior

MVP:

```text
Always visible
North-up
No rotation
No zoom control
No click interaction
```

Later:

```text
M key toggles expanded tactical map
Mouse hover shows room/sector label
Click objective pings target
Command Center mode reveals more enemy classification
```

Do not add click commands in v1. Make it readable first.

---

# Fog / reveal future hook

Your `ProcGenTilemap` already has streaming reveal behavior and revealed chunk tracking.  For v1, show the full generated map. For v2, add:

```gdscript
"revealed_cells": _dict_keys_as_vector2i_array(_revealed_tiles_or_chunks)
```

Then in `MinimapView`, draw unrevealed cells as black/transparent.

Future rule:

```text
Normal field mode: only revealed/nearby data
Command Center mode: full tactical map
Sensor upgrades: improve enemy classification, not raw map accuracy
```

That fits the CUSTODIAN “legibility, not power scaling” direction.

---

# Acceptance criteria

Codex should confirm:

1. Minimap appears in UI.
2. Minimap updates after procgen finishes.
3. Floor and wall structure matches generated map.
4. Player pip moves correctly.
5. Enemy pips appear if enemies are in the configured enemy group.
6. Destroyed walls become floor on the minimap.
7. No crash when procgen is not loaded.
8. No SubViewport is used.
9. No addon dependency is introduced.
10. The minimap is readable at 180–240 px.

---

# Test plan

Run:

```bash
cd custodian
godot
```

Manual tests:

```text
1. Generate procgen map.
2. Confirm minimap terrain appears.
3. Walk player around.
4. Confirm player pip tracks position.
5. Spawn enemies.
6. Confirm enemy pips appear if grouped.
7. Destroy a wall.
8. Confirm minimap tile changes from wall to floor.
9. Resize UI scale if needed.
```

Debug helper:

```gdscript
print("[Minimap] map_size=", map_size, " floors=", floor_cells.size(), " walls=", wall_cells.size())
```

---

# My recommended implementation order

1. Add `floor_cells` / `wall_cells` to `get_level_data()`.
2. Add `global_to_minimap_tile()`.
3. Add `minimap_tile_changed`.
4. Create `minimap_view.gd`.
5. Create `minimap_controller.gd`.
6. Create `minimap_panel.tscn`.
7. Add panel to `UI`.
8. Add `map_frame_large_9slice.png` later.

The only asset I would make **right now** is:

```text
custodian/content/ui/map/map_frame_large_9slice.png
128x128
transparent center
24px 9-slice margins
```

Everything else can be drawn in code until the minimap behavior feels good.
