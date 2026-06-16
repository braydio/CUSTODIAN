# Codex Instructional Roadmap: Route-First Worldgen Correction

## Summary

Current `main` stays the integration base. The existing cave/BSP generator is **not deleted**. The correction is to put a new **worldgen intent spine** in front of the old generator, then gradually demote the old room/cave generator into a filler/detail pass.

**The blocker:** procgen world progression exists as a metadata layer over the existing room/corridor/cellular-automaton generator. The old generator still controls map shape via BSP partitioning, room placement, corridor routing, cellular automaton noise, flood fill, and smoothing. TerrainBuilder's ascent route is an optional pass discarded if connectivity fails — making ascent a safe overlay rather than the main topology. Progression metadata, faction sites, story-room candidates, and ambient anchors are exported as labels, not shape authority.

**The fix:** build a deterministic route-first intent graph that becomes the upstream shape contract. The old generator becomes texture/filler around the route-first ascent spine.

### Primary goal

Make the generated tactical world feel like a deliberate Sundered Keep / cosmic ruin ascent:

- spawn/lowlands
- approach routes
- foothill transition
- switchback/ridge ascent
- faction activity pockets
- story-room/setpiece insertions
- vista/reveal beats
- elevation and blocker metadata that the player can actually read and eventually feel

### Design rule — correct generation order

1. World profile and distance bands
2. Intent graph
3. Ascent spine
4. Region reservations
5. Terrain/elevation requests
6. Floor/wall carving
7. Faction/story/site stamping
8. Props/actors/ambient anchors
9. Debug export and validation

### Non-goals and guardrails

- Do not rewrite the entire procgen runtime in one pass.
- Do not delete the existing BSP/cave generator.
- Do not remove current road/elevation/terrain/faction/story metadata systems.
- Do not rewrite all pathfinding.
- Do not implement full stacked elevation.
- Do not create new production art in this pass.
- Do not convert every story room to final authored art in this pass.
- Do not keep adding metadata-only systems without changing map shape.
- Do not tune BSP/cellular parameters and call that the fix.
- Do not merge unknown branches wholesale.
- Do not replace the old generator in one pass.
- Do not move visual tile art into simulation authority.
- Do not let story/faction sites place visuals without claiming wall/collision/elevation authority.
- Do not make actor traversal changes so broad that enemy/operator movement regresses everywhere.
- **Build a new route-first "intent graph" layer and progressively let it become the authority for map shape.**

---

## Pre-Work — Branch and Context Audit

Codex should begin here. Do not assume local branches are all on GitHub.

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

git fetch --all --prune

echo "=== CURRENT BRANCH ==="
git branch --show-current
git status --short

echo
echo "=== RECENT LOCAL + REMOTE BRANCHES ==="
git for-each-ref \
  --sort=-committerdate \
  --format='%(committerdate:short) %(refname:short) %(objectname:short) %(subject)' \
  refs/heads refs/remotes/origin \
  | grep -v 'origin/HEAD' \
  | head -100

echo
echo "=== NOT MERGED INTO MAIN ==="
git branch --no-merged main || true
git branch -r --no-merged origin/main || true

echo
echo "=== WORLDGEN-RELEVANT DIFFS BY BRANCH ==="
for b in $(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin | grep -v 'origin/HEAD' | sort -u); do
  if [ "$b" = "main" ] || [ "$b" = "origin/main" ]; then
    continue
  fi

  changed=$(git diff --name-only main..."$b" -- \
    custodian/game/world/procgen \
    custodian/game/world/elevation \
    custodian/game/world/sundered_keep \
    custodian/content/procgen \
    design/02_features/procgen \
    design/02_features/world_expansion \
    design/05_levels \
    custodian/docs/ai_context/task_packets \
    2>/dev/null)

  if [ -n "$changed" ]; then
    echo
    echo "### $b"
    echo "$changed"
    echo "--- commits main..$b ---"
    git log --oneline --max-count=20 main.."$b" -- 2>/dev/null || true
  fi
done
```

Then search for features that may exist locally but not on `main`:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN

for b in $(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin | grep -v 'origin/HEAD' | sort -u); do
  echo
  echo "### $b"
  git grep -n \
    -e "sector_graph_builder" \
    -e "WorldgenIntent" \
    -e "IntentGraph" \
    -e "AscentSpine" \
    -e "story_room_geometry" \
    -e "claim_procgen_floor_rect" \
    -e "faction_site_geometry" \
    -e "maintenance_complex_generator" \
    -e "room_placer" \
    -e "corridor_router" \
    "$b" -- \
    custodian/game/world/procgen \
    custodian/content/procgen \
    design/02_features/procgen \
    design/02_features/world_expansion \
    design/05_levels \
    custodian/docs/ai_context/task_packets \
    2>/dev/null || true
done
```

**Acceptance:**

- Produce a short branch audit note in the new task packet.
- If a branch contains actual runtime worldgen files, do not merge blindly.
- Identify candidate files/commits for cherry-pick or manual port.
- If no useful branch exists, continue on main.

---

## Phase 1 — Create the task packet and design spec

Create these files:

```
custodian/docs/ai_context/task_packets/PROCGEN_INTENT_GRAPH_ASCENT_V1.md
design/02_features/procgen/PROCGEN_INTENT_GRAPH_ASCENT_V1.md
```

### Task packet content

```markdown
# Procgen Intent Graph + Ascent V1

## Status

- Status: active
- Owner: Codex
- Created: YYYY-MM-DD
- Last updated: YYYY-MM-DD

## Problem

Current procgen world progression is mostly metadata layered over the existing BSP/corridor/cellular-automaton generator. This means the generated map still behaves like rooms/caves with later overlays, rather than a deliberate route-first ascent with faction/story setpieces.

## Goal

Introduce a deterministic route-first worldgen intent graph that becomes the upstream shape authority for:

- main route beats
- ascent spine
- branch pockets
- faction site reservations
- story room reservations
- vista/reveal beats
- terrain/elevation requests
- future encounter insertion

The existing `ProcGen` cave/BSP generator remains available as filler/detail generation, not the primary topology authority.

## Non-goals

- Do not delete the current procgen generator.
- Do not rewrite all pathfinding.
- Do not implement full stacked elevation.
- Do not create new production art.
- Do not convert every story room to final authored art in this pass.

## Required validation

- Existing procgen still loads.
- Existing terrain/elevation smokes still pass.
- New intent graph smoke passes.
- Same seed produces same intent graph.
- Main route is connected.
- Story/faction reservations do not block required route.
```

### Design spec content

```markdown
# Procgen Intent Graph + Ascent V1

## Design Rule

Worldgen must be generated from player-facing route intent first, not from rooms first.

Correct order:

1. World profile and distance bands
2. Intent graph
3. Ascent spine
4. Region reservations
5. Terrain/elevation requests
6. Floor/wall carving
7. Faction/story/site stamping
8. Props/actors/ambient anchors
9. Debug export and validation

Incorrect order:

1. BSP rooms
2. Corridors
3. Cellular automaton
4. Metadata overlay
```

---

## Phase 2 — Intent graph data classes

Create folder:

```
custodian/game/world/procgen/intent/
```

### `worldgen_intent_node.gd`

```
custodian/game/world/procgen/intent/worldgen_intent_node.gd`
```

```gdscript
extends RefCounted
class_name WorldgenIntentNode

enum NodeKind {
	SPAWN,
	MAIN_ROUTE,
	ASCENT_BEAT,
	BRANCH,
	FACTION_SITE,
	STORY_ROOM,
	VISTA,
	RESOURCE_POCKET,
	SAFE_POCKET,
	SHORTCUT,
	EXIT_GATE,
}

var id: String = ""
var kind: NodeKind = NodeKind.MAIN_ROUTE
var cell: Vector2i = Vector2i.ZERO
var radius_tiles: int = 6
var band_id: String = ""
var style_id: String = ""
var faction_id: String = ""
var story_id: String = ""
var target_height: int = 0
var required: bool = false
var tags: Array[String] = []


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"kind_name": kind_to_string(kind),
		"cell": cell,
		"radius_tiles": radius_tiles,
		"band_id": band_id,
		"style_id": style_id,
		"faction_id": faction_id,
		"story_id": story_id,
		"target_height": target_height,
		"required": required,
		"tags": tags.duplicate(),
	}


static func kind_to_string(value: NodeKind) -> String:
	match value:
		NodeKind.SPAWN:
			return "spawn"
		NodeKind.ASCENT_BEAT:
			return "ascent_beat"
		NodeKind.BRANCH:
			return "branch"
		NodeKind.FACTION_SITE:
			return "faction_site"
		NodeKind.STORY_ROOM:
			return "story_room"
		NodeKind.VISTA:
			return "vista"
		NodeKind.RESOURCE_POCKET:
			return "resource_pocket"
		NodeKind.SAFE_POCKET:
			return "safe_pocket"
		NodeKind.SHORTCUT:
			return "shortcut"
		NodeKind.EXIT_GATE:
			return "exit_gate"
		_:
			return "main_route"
```

### `worldgen_intent_edge.gd`

```
custodian/game/world/procgen/intent/worldgen_intent_edge.gd
```

```gdscript
extends RefCounted
class_name WorldgenIntentEdge

enum EdgeKind {
	MAIN_ASCENT,
	BRANCH_PATH,
	SHORTCUT_LOCKED,
	RETURN_PATH,
	FACTION_APPROACH,
	STORY_APPROACH,
}

var id: String = ""
var from_id: String = ""
var to_id: String = ""
var kind: EdgeKind = EdgeKind.MAIN_ASCENT
var width_tiles: int = 5
var target_slope: int = 0
var tags: Array[String] = []


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"from_id": from_id,
		"to_id": to_id,
		"kind": kind,
		"kind_name": kind_to_string(kind),
		"width_tiles": width_tiles,
		"target_slope": target_slope,
		"tags": tags.duplicate(),
	}


static func kind_to_string(value: EdgeKind) -> String:
	match value:
		EdgeKind.BRANCH_PATH:
			return "branch_path"
		EdgeKind.SHORTCUT_LOCKED:
			return "shortcut_locked"
		EdgeKind.RETURN_PATH:
			return "return_path"
		EdgeKind.FACTION_APPROACH:
			return "faction_approach"
		EdgeKind.STORY_APPROACH:
			return "story_approach"
		_:
			return "main_ascent"
```

### `worldgen_intent_graph.gd`

```
custodian/game/world/procgen/intent/worldgen_intent_graph.gd
```

```gdscript
extends RefCounted
class_name WorldgenIntentGraph

const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")

var seed: int = 0
var map_size: Vector2i = Vector2i.ZERO
var origin_cell: Vector2i = Vector2i.ZERO
var nodes: Array[WorldgenIntentNode] = []
var edges: Array[WorldgenIntentEdge] = []


func add_node(node: WorldgenIntentNode) -> void:
	nodes.append(node)


func add_edge(edge: WorldgenIntentEdge) -> void:
	edges.append(edge)


func get_node_by_id(id: String) -> WorldgenIntentNode:
	for node in nodes:
		if node.id == id:
			return node
	return null


func get_required_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for node in nodes:
		if node.required:
			cells.append(node.cell)
	return cells


func get_main_route_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for node in nodes:
		if node.kind == WorldgenIntentNode.NodeKind.SPAWN \
				or node.kind == WorldgenIntentNode.NodeKind.MAIN_ROUTE \
				or node.kind == WorldgenIntentNode.NodeKind.ASCENT_BEAT \
				or node.kind == WorldgenIntentNode.NodeKind.EXIT_GATE:
			cells.append(node.cell)
	return cells


func to_dictionary() -> Dictionary:
	var node_dicts: Array[Dictionary] = []
	var edge_dicts: Array[Dictionary] = []
	for node in nodes:
		node_dicts.append(node.to_dictionary())
	for edge in edges:
		edge_dicts.append(edge.to_dictionary())
	return {
		"seed": seed,
		"map_size": map_size,
		"origin_cell": origin_cell,
		"nodes": node_dicts,
		"edges": edge_dicts,
	}
```

---

## Phase 3 — Ascent spine builder

Create:

```
custodian/game/world/procgen/intent/ascent_spine_builder.gd
```

```gdscript
extends RefCounted
class_name AscentSpineBuilder

const IntentGraphScript := preload("res://game/world/procgen/intent/worldgen_intent_graph.gd")
const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")

const DEFAULT_ROUTE_BEATS := 7


func build(context: Dictionary) -> WorldgenIntentGraph:
	var graph := IntentGraphScript.new()
	graph.seed = int(context.get("seed", 0))
	graph.map_size = context.get("map_size", Vector2i(160, 160))
	graph.origin_cell = context.get("origin_cell", Vector2i(graph.map_size.x / 2, graph.map_size.y - 12))

	var profile = context.get("world_progress_profile", nil)
	var rng := RandomNumberGenerator.new()
	rng.seed = graph.seed ^ 0xA5C70D1A

	var beat_count := int(context.get("route_beat_count", DEFAULT_ROUTE_BEATS))
	var spawn := _make_node(
		"spawn",
		IntentNodeScript.NodeKind.SPAWN,
		graph.origin_cell,
		8,
		0,
		true
	)
	_apply_progress(spawn, profile, graph.seed)
	graph.add_node(spawn)

	var previous_id := spawn.id
	var previous_cell := spawn.cell

	for index in range(1, beat_count + 1):
		var t := float(index) / float(beat_count)
		var y := lerpf(float(graph.origin_cell.y), 12.0, t)
		var x_wave := sin(t * PI * 2.5 + float(graph.seed % 17)) * float(graph.map_size.x) * 0.18
		var x_noise := rng.randi_range(-10, 10)
		var x := clampi(int(float(graph.origin_cell.x) + x_wave + x_noise), 12, graph.map_size.x - 13)
		var cell := Vector2i(x, clampi(int(y), 10, graph.map_size.y - 10))

		var kind := IntentNodeScript.NodeKind.ASCENT_BEAT
		if index == beat_count:
			kind = IntentNodeScript.NodeKind.EXIT_GATE
		var node := _make_node(
			"main_%02d" % index,
			kind,
			cell,
			8 + int(t * 4.0),
			int(round(t * 9.0)),
			true
		)
		_apply_progress(node, profile, graph.seed)
		graph.add_node(node)

		var edge := IntentEdgeScript.new()
		edge.id = "%s_to_%s" % [previous_id, node.id]
		edge.from_id = previous_id
		edge.to_id = node.id
		edge.kind = IntentEdgeScript.EdgeKind.MAIN_ASCENT
		edge.width_tiles = 5 if index < beat_count else 7
		edge.target_slope = node.target_height
		graph.add_edge(edge)

		previous_id = node.id
		previous_cell = cell

		if index > 1 and index < beat_count:
			_try_add_branch(graph, node, rng, profile)

	return graph


func _make_node(
	id: String,
	kind: int,
	cell: Vector2i,
	radius_tiles: int,
	target_height: int,
	required: bool
) -> WorldgenIntentNode:
	var node := IntentNodeScript.new()
	node.id = id
	node.kind = kind
	node.cell = cell
	node.radius_tiles = radius_tiles
	node.target_height = target_height
	node.required = required
	return node


func _try_add_branch(graph: WorldgenIntentGraph, parent: WorldgenIntentNode, rng: RandomNumberGenerator, profile) -> void:
	if rng.randf() > 0.65:
		return

	var side := -1 if rng.randf() < 0.5 else 1
	var distance := rng.randi_range(14, 28)
	var branch_cell := parent.cell + Vector2i(side * distance, rng.randi_range(-8, 8))
	branch_cell.x = clampi(branch_cell.x, 8, graph.map_size.x - 9)
	branch_cell.y = clampi(branch_cell.y, 8, graph.map_size.y - 9)

	var kind_roll := rng.randf()
	var kind := IntentNodeScript.NodeKind.RESOURCE_POCKET
	if kind_roll > 0.75:
		kind = IntentNodeScript.NodeKind.STORY_ROOM
	elif kind_roll > 0.50:
		kind = IntentNodeScript.NodeKind.FACTION_SITE
	elif kind_roll > 0.25:
		kind = IntentNodeScript.NodeKind.VISTA

	var node := _make_node(
		"%s_branch_%d" % [parent.id, graph.nodes.size()],
		kind,
		branch_cell,
		rng.randi_range(5, 10),
		parent.target_height,
		false
	)
	_apply_progress(node, profile, graph.seed)
	graph.add_node(node)

	var edge := IntentEdgeScript.new()
	edge.id = "%s_to_%s" % [parent.id, node.id]
	edge.from_id = parent.id
	edge.to_id = node.id
	edge.kind = IntentEdgeScript.EdgeKind.BRANCH_PATH
	if kind == IntentNodeScript.NodeKind.FACTION_SITE:
		edge.kind = IntentEdgeScript.EdgeKind.FACTION_APPROACH
	elif kind == IntentNodeScript.NodeKind.STORY_ROOM:
		edge.kind = IntentEdgeScript.EdgeKind.STORY_APPROACH
	edge.width_tiles = rng.randi_range(3, 5)
	edge.target_slope = node.target_height
	graph.add_edge(edge)


func _apply_progress(node: WorldgenIntentNode, profile, seed: int) -> void:
	if profile == null or not profile.has_method("get_cell_progress"):
		return
	var progress: Dictionary = profile.call("get_cell_progress", node.cell, seed)
	node.band_id = String(progress.get("band_id", ""))
	node.style_id = String(progress.get("dominant_style", ""))
	node.faction_id = String(progress.get("dominant_faction", ""))
```

**No per-phase acceptance** — covered by Phase 10 validation and the final checklist.

---

## Phase 4 — Region footprint reservation

Create:

```
custodian/game/world/procgen/intent/region_footprint_reserver.gd
```

```gdscript
extends RefCounted
class_name RegionFootprintReserver

const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")

const CELL_FLOOR := "floor"
const CELL_WALL := "wall"
const CELL_RESERVED := "reserved"


func build_reservations(graph: WorldgenIntentGraph, map_size: Vector2i) -> Dictionary:
	var floor_cells: Dictionary = {}
	var reserved_regions: Array[Dictionary] = []

	for edge in graph.edges:
		var from_node := graph.get_node_by_id(edge.from_id)
		var to_node := graph.get_node_by_id(edge.to_id)
		if from_node == null or to_node == null:
			continue
		_carve_path(floor_cells, from_node.cell, to_node.cell, edge.width_tiles)

	for node in graph.nodes:
		var rect := Rect2i(
			node.cell - Vector2i(node.radius_tiles, node.radius_tiles),
			Vector2i(node.radius_tiles * 2 + 1, node.radius_tiles * 2 + 1)
		)
		_carve_rect(floor_cells, rect)
		reserved_regions.append({
			"id": node.id,
			"kind": IntentNodeScript.kind_to_string(node.kind),
			"rect": rect,
			"center": node.cell,
			"radius_tiles": node.radius_tiles,
			"target_height": node.target_height,
			"band_id": node.band_id,
			"style_id": node.style_id,
			"faction_id": node.faction_id,
			"story_id": node.story_id,
			"required": node.required,
		})

	return {
		"floor_cells": floor_cells,
		"reserved_regions": reserved_regions,
	}


func _carve_path(floor_cells: Dictionary, from_cell: Vector2i, to_cell: Vector2i, width: int) -> void:
	var points := _bresenham(from_cell, to_cell)
	var radius := maxi(1, int(floor(float(width) * 0.5)))
	for point in points:
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if Vector2i(dx, dy).length_squared() <= radius * radius:
					floor_cells[point + Vector2i(dx, dy)] = true


func _carve_rect(floor_cells: Dictionary, rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			floor_cells[Vector2i(x, y)] = true


func _bresenham(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0 := a.x
	var y0 := a.y
	var x1 := b.x
	var y1 := b.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return points
```

---

## Phase 5 — Integrate intent graph into `ProcGenTilemap`

Modify:

```
custodian/game/world/procgen/proc_gen_tilemap.gd
```

### Add preloads

```gdscript
const ASCENT_SPINE_BUILDER_SCRIPT := preload("res://game/world/procgen/intent/ascent_spine_builder.gd")
const REGION_FOOTPRINT_RESERVER_SCRIPT := preload("res://game/world/procgen/intent/region_footprint_reserver.gd")
```

### Add exports

```gdscript
@export_group("Worldgen Intent", "worldgen_intent")
@export var worldgen_intent_enabled: bool = true
@export var worldgen_intent_route_beat_count: int = 7
@export var worldgen_intent_carve_before_detail: bool = true
@export var worldgen_intent_debug_logging: bool = true
@export_group("", "")
```

### Add member variables

```gdscript
var _worldgen_intent_graph: WorldgenIntentGraph = null
var _worldgen_reserved_regions: Array[Dictionary] = []
var _worldgen_intent_floor_cells: Dictionary = {}
```

### Add builder/reservation functions

```gdscript
func _build_worldgen_intent_graph(map_size: Vector2i) -> void:
	_worldgen_intent_graph = null
	_worldgen_reserved_regions.clear()
	_worldgen_intent_floor_cells.clear()

	if not worldgen_intent_enabled:
		return

	_ensure_world_progress_profile()

	var builder := ASCENT_SPINE_BUILDER_SCRIPT.new()
	var origin := get_player_spawn()
	if origin == Vector2i.ZERO:
		origin = Vector2i(map_size.x / 2, map_size.y - 12)

	_worldgen_intent_graph = builder.build({
		"seed": procgen_node.seed,
		"map_size": map_size,
		"origin_cell": origin,
		"route_beat_count": worldgen_intent_route_beat_count,
		"world_progress_profile": _world_progress_profile,
	})

	var reserver := REGION_FOOTPRINT_RESERVER_SCRIPT.new()
	var reservations: Dictionary = reserver.build_reservations(_worldgen_intent_graph, map_size)
	_worldgen_intent_floor_cells = reservations.get("floor_cells", {})
	_worldgen_reserved_regions = reservations.get("reserved_regions", [])

	if worldgen_intent_debug_logging:
		print("[ProcGenTilemap] intent graph nodes=%d edges=%d floor_cells=%d regions=%d" % [
			_worldgen_intent_graph.nodes.size(),
			_worldgen_intent_graph.edges.size(),
			_worldgen_intent_floor_cells.size(),
			_worldgen_reserved_regions.size(),
		])


func _apply_worldgen_intent_floor_cells(map_size: Vector2i) -> void:
	if _worldgen_intent_floor_cells.is_empty():
		return

	for key in _worldgen_intent_floor_cells.keys():
		if not (key is Vector2i):
			continue
		var tile := key as Vector2i
		if not _is_tile_inside_map(tile, map_size, 0):
			continue

		_generated_floor_cells[tile] = true
		_generated_wall_cells.erase(tile)

		if floor_tilemap != null:
			var source_id := _select_floor_source_id(tile)
			var atlas := _select_floor_coord(tile)
			floor_tilemap.set_cell(tile, source_id, atlas, 0)

		if walls_tilemap != null:
			walls_tilemap.erase_cell(tile)

		if build_runtime_wall_collision:
			_remove_runtime_wall_body(tile)

		_set_region_tile(tile, "worldgen_intent_floor", "ascent_route")
```

### Insert into the generation handoff

In `_fill_tilemaps()` or the main generation handoff, after the base generator has produced initial floor/wall cells but **before** terrain builder, roads, props, foliage, faction sites, and story sites:

```gdscript
	if worldgen_intent_enabled:
		_build_worldgen_intent_graph(map_size)
		if worldgen_intent_carve_before_detail:
			_apply_worldgen_intent_floor_cells(map_size)
```

### Patch `get_level_data()` to export the graph

```gdscript
		"worldgen_intent_enabled": worldgen_intent_enabled,
		"worldgen_intent_graph": _worldgen_intent_graph.to_dictionary() if _worldgen_intent_graph != null else {},
		"worldgen_reserved_regions": _worldgen_reserved_regions.duplicate(true),
```

---

## Phase 6 — Feed intent graph into `TerrainBuilder`

Current TerrainBuilder already supports required cells and an optional ascent route, but it chooses its own path against existing floors. Patch the context in `ProcGenTilemap._apply_terrain_builder()` so intent graph required cells become required connectivity anchors.

### In `ProcGenTilemap` — add required cells from intent graph

Find wherever `required_cells` is built. Add:

```gdscript
	if _worldgen_intent_graph != null:
		for cell in _worldgen_intent_graph.get_required_cells():
			required_cells[cell] = true
```

### Add intent data to the terrain builder context

```gdscript
		"worldgen_intent_graph": _worldgen_intent_graph,
		"worldgen_reserved_regions": _worldgen_reserved_regions,
		"worldgen_intent_floor_cells": _worldgen_intent_floor_cells,
```

### In `terrain_builder.gd` — apply reserved region elevation

Modify:

```
custodian/game/world/procgen/terrain/terrain_builder.gd
```

Add handling after baseline build, before the optional ascent route:

```gdscript
	if context.has("worldgen_reserved_regions"):
		_apply_reserved_region_elevation(result, context.get("worldgen_reserved_regions", []))
```

Add helper:

```gdscript
func _apply_reserved_region_elevation(result: Dictionary, reserved_regions: Array) -> void:
	for raw_region in reserved_regions:
		if not (raw_region is Dictionary):
			continue
		var region := raw_region as Dictionary
		var rect: Rect2i = region.get("rect", Rect2i())
		var target_height := int(region.get("target_height", HEIGHT_GROUND))
		var kind := String(region.get("kind", ""))

		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				var cell := Vector2i(x, y)
				if not result.get("height_by_cell", {}).has(cell):
					continue

				result["height_by_cell"][cell] = target_height
				result["traversal_by_cell"][cell] = TRAVERSAL_WALKABLE
				if target_height > HEIGHT_GROUND:
					result["terrain_type_by_cell"][cell] = TERRAIN_INDUSTRIAL_PLATFORM
					result["tile_by_cell"][cell] = TerrainTileIds.TILE_ELEVATED_FLOOR
				else:
					result["tile_by_cell"][cell] = NO_VISUAL_TILE

				if kind == "story_room" or kind == "faction_site":
					result["ramp_dir_by_cell"].erase(cell)
```

Important: this phase is still simple. It should establish height pressure and preserve connectivity, not solve every slope tile.

---

## Phase 7 — Story and faction site geometry stamping

This phase merges story-room and faction-site stamping into a single pattern. Both stampers use the same reservation contract (`claim_procgen_floor_rect_for_authored_scene_tiles`) that fixed the Forlorn-Ritualant wall/collision class of bug.

### Create stampers

#### Story room geometry stamper

```
custodian/game/world/procgen/story/story_room_geometry_stamper.gd
```

```gdscript
extends RefCounted
class_name StoryRoomGeometryStamper


func stamp_story_rooms(tilemap: Node, story_rooms: Array, reserved_regions: Array) -> void:
	if tilemap == null:
		return
	if not tilemap.has_method("claim_procgen_floor_rect_for_authored_scene_tiles"):
		return

	for region in reserved_regions:
		if not (region is Dictionary):
			continue
		if String(region.get("kind", "")) != "story_room":
			continue

		var center: Vector2i = region.get("center", Vector2i.ZERO)
		var rect: Rect2i = region.get("rect", Rect2i(center - Vector2i(5, 5), Vector2i(11, 11)))
		var size := rect.size

		tilemap.call(
			"claim_procgen_floor_rect_for_authored_scene_tiles",
			center,
			size,
			"story_room_floor",
			"story_room",
			1
		)
```

#### Faction site geometry stamper

```
custodian/game/world/procgen/factions/faction_site_geometry_stamper.gd
```

```gdscript
extends RefCounted
class_name FactionSiteGeometryStamper


func stamp_faction_sites(tilemap: Node, faction_sites: Array, reserved_regions: Array) -> void:
	if tilemap == null:
		return
	if not tilemap.has_method("claim_procgen_floor_rect_for_authored_scene_tiles"):
		return

	for region in reserved_regions:
		if not (region is Dictionary):
			continue
		if String(region.get("kind", "")) != "faction_site":
			continue

		var center: Vector2i = region.get("center", Vector2i.ZERO)
		var rect: Rect2i = region.get("rect", Rect2i(center - Vector2i(4, 4), Vector2i(9, 9)))
		var faction_id := String(region.get("faction_id", "unknown"))

		tilemap.call(
			"claim_procgen_floor_rect_for_authored_scene_tiles",
			center,
			rect.size,
			"faction_site_floor",
			"faction_%s" % faction_id,
			1
		)
```

### Modify `ProcGenTilemap` — add preloads

```gdscript
const STORY_ROOM_GEOMETRY_STAMPER_SCRIPT := preload("res://game/world/procgen/story/story_room_geometry_stamper.gd")
const FACTION_SITE_GEOMETRY_STAMPER_SCRIPT := preload("res://game/world/procgen/factions/faction_site_geometry_stamper.gd")
```

```gdscript
var _story_room_geometry_stamper: RefCounted = null
var _faction_site_geometry_stamper: RefCounted = null
```

### Insert into generation flow

After `_place_story_rooms(map_size)`:

```gdscript
	if _story_room_geometry_stamper == null:
		_story_room_geometry_stamper = STORY_ROOM_GEOMETRY_STAMPER_SCRIPT.new()
	_story_room_geometry_stamper.call("stamp_story_rooms", self, _story_room_sites, _worldgen_reserved_regions)
```

After `_place_faction_ambient_sites(map_size)`:

```gdscript
	if _faction_site_geometry_stamper == null:
		_faction_site_geometry_stamper = FACTION_SITE_GEOMETRY_STAMPER_SCRIPT.new()
	_faction_site_geometry_stamper.call("stamp_faction_sites", self, _faction_activity_sites, _worldgen_reserved_regions)
```

This is the first step from "metadata anchor" to "actual place."

**Future consolidation note:** The two stampers are intentionally parallel but separate so each can diverge independently when story rooms and faction sites acquire distinct geometry logic. If they remain identical across another phase boundary, merge them into a single `ReservedRegionGeometryStamper`.

---

## Phase 8 — Elevation traversal query hooks

Do not force all movement/pathing through elevation in one large risky patch. Add query APIs first.

### In `ProcGenTilemap` — add traversal API

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

### Navigation system integration — deferred scope

The existing navigation stack at:

```
custodian/game/systems/core/systems/navigation_system.gd
```

should eventually consume these APIs. In this pass, add only what is safe:

- Add a call-site or adapter method that can ask the current map for `can_actor_move_between_tiles()` before accepting a local neighbor.
- If the existing navigation stack cannot cheaply consume per-edge costs yet, expose debug helpers only and **defer full actor enforcement** to the follow-up task.

**Acceptance:**

- API exists and returns correct values.
- No global movement regression.
- No enemy pathfinding rewrite yet unless trivial.

---

## Phase 9 — Debug overlay

Create:

```
custodian/game/world/procgen/intent/worldgen_intent_debug_overlay.gd
```

```gdscript
extends Node2D
class_name WorldgenIntentDebugOverlay

@export var tile_size: int = 32
@export var show_nodes: bool = true
@export var show_edges: bool = true
@export var show_regions: bool = true

var graph: WorldgenIntentGraph = null
var reserved_regions: Array[Dictionary] = []


func set_debug_data(p_graph: WorldgenIntentGraph, p_regions: Array[Dictionary]) -> void:
	graph = p_graph
	reserved_regions = p_regions
	queue_redraw()


func _draw() -> void:
	if graph == null:
		return

	if show_edges:
		for edge in graph.edges:
			var from_node := graph.get_node_by_id(edge.from_id)
			var to_node := graph.get_node_by_id(edge.to_id)
			if from_node == null or to_node == null:
				continue
			draw_line(
				_tile_to_local(from_node.cell),
				_tile_to_local(to_node.cell),
				Color(0.5, 0.8, 1.0, 0.55),
				3.0
			)

	if show_regions:
		for region in reserved_regions:
			var rect: Rect2i = region.get("rect", Rect2i())
			var color := Color(0.8, 0.7, 0.3, 0.18)
			if String(region.get("kind", "")) == "story_room":
				color = Color(0.8, 0.3, 1.0, 0.22)
			elif String(region.get("kind", "")) == "faction_site":
				color = Color(1.0, 0.35, 0.2, 0.22)
			draw_rect(
				Rect2(
					Vector2(rect.position * tile_size),
					Vector2(rect.size * tile_size)
				),
				color,
				true
			)

	if show_nodes:
		for node in graph.nodes:
			draw_circle(_tile_to_local(node.cell), 7.0, Color(1.0, 1.0, 0.6, 0.9))


func _tile_to_local(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * tile_size + tile_size / 2, tile.y * tile_size + tile_size / 2)
```

In `ProcGenTilemap`, optionally instantiate this when debug is enabled, or expose the graph to the existing `terrain_debug_overlay.gd`.

---

## Phase 10 — Validation scripts

### Intent graph smoke

```
custodian/tools/validation/procgen_intent_graph_smoke.gd
```

```gdscript
extends SceneTree

const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const AscentSpineBuilderScript := preload("res://game/world/procgen/intent/ascent_spine_builder.gd")
const RegionFootprintReserverScript := preload("res://game/world/procgen/intent/region_footprint_reserver.gd")


func _init() -> void:
	var profile := WorldProgressProfileScript.load_from_path("res://content/procgen/world_profiles/sundered_keep_ascent.json")
	assert(profile != null)

	var builder := AscentSpineBuilderScript.new()
	var graph = builder.build({
		"seed": 99111,
		"map_size": Vector2i(160, 160),
		"origin_cell": Vector2i(80, 148),
		"route_beat_count": 7,
		"world_progress_profile": profile,
	})

	assert(graph != null)
	assert(graph.nodes.size() >= 8)
	assert(graph.edges.size() >= 7)
	assert(graph.get_required_cells().size() >= 2)

	var previous_y := 999999
	for cell in graph.get_main_route_cells():
		assert(cell.x >= 0 and cell.y >= 0)
		assert(cell.x < graph.map_size.x and cell.y < graph.map_size.y)
		previous_y = mini(previous_y, cell.y)

	var reserver := RegionFootprintReserverScript.new()
	var reservations: Dictionary = reserver.build_reservations(graph, graph.map_size)
	assert((reservations.get("floor_cells", {}) as Dictionary).size() > 0)
	assert((reservations.get("reserved_regions", []) as Array).size() > 0)

	var graph2 = builder.build({
		"seed": 99111,
		"map_size": Vector2i(160, 160),
		"origin_cell": Vector2i(80, 148),
		"route_beat_count": 7,
		"world_progress_profile": profile,
	})
	assert(JSON.stringify(graph.to_dictionary()) == JSON.stringify(graph2.to_dictionary()))

	print("procgen_intent_graph_smoke: PASS")
	quit(0)
```

### Full procgen shape smoke

```
custodian/tools/validation/procgen_worldgen_shape_smoke.gd
```

```gdscript
extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)

	var tilemap = map as ProcGenTilemap
	assert(tilemap != null)

	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	if procgen == null:
		procgen = map.find_child("ProcGen", true, false) as ProcGen
	assert(procgen != nil)

	procgen.generate_seed = false
	procgen.seed = 20260615
	procgen.map_size = Vector2i(160, 160)

	tilemap.worldgen_intent_enabled = true
	tilemap.world_progression_enabled = true
	tilemap.ascent_route_enabled = true
	tilemap.story_rooms_enabled = true
	tilemap.faction_ambient_sites_enabled = true
	tilemap.generate()

	for _i in range(120):
		await process_frame

	var data: Dictionary = tilemap.get_level_data()
	assert(bool(data.get("worldgen_intent_enabled", false)))
	assert(not (data.get("worldgen_intent_graph", {}) as Dictionary).is_empty())
	assert((data.get("worldgen_reserved_regions", []) as Array).size() > 0)
	assert((data.get("world_progress_samples", {}) as Dictionary).size() > 0)

	print("procgen_worldgen_shape_smoke: PASS")
	quit(0)
```

### Run all validation

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian

godot --headless --script res://tools/validation/procgen_intent_graph_smoke.gd
godot --headless --script res://tools/validation/procgen_worldgen_shape_smoke.gd
godot --headless --script res://tools/validation/terrain_builder_smoke.gd
godot --headless --script res://tools/validation/elevation_map_smoke.gd
godot --headless --path . --quit
```

> **Note:** The roadmap also references `procgen_placeholder_roads_smoke.gd` as an existing validation. If it exists, run it. If not (it is not created in any phase here), skip it. Consider adding it as a separate cleanup if road validation is needed.

---

## Phase 11 — Documentation updates and drift correction

Update these files:

```
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/CONTEXT.md
custodian/docs/ai_context/task_packets/PROCGEN_INTENT_GRAPH_ASCENT_V1.md
design/02_features/procgen/PROCGEN_INTENT_GRAPH_ASCENT_V1.md
```

### Add to `CURRENT_STATE.md`

```markdown
- Procgen Intent Graph / Ascent V1 is live as the first route-first worldgen correction layer. `ProcGenTilemap` can now build a deterministic `WorldgenIntentGraph` before terrain/detail passes, producing a main ascent spine, required route beats, branch pockets, faction-site reservations, story-room reservations, and reserved floor cells. The legacy BSP/corridor/cellular-automaton generator remains available as a filler/detail pass, but the new intent graph is the upstream shape target for world progression.
- World progression is no longer only exported metadata: reserved intent regions are carved into floor authority, cleared from procgen wall authority, and passed into TerrainBuilder for height/traversal metadata. Story-room and faction-site geometry stamping are still V1 reservations/clearings, not final authored room art.
- Elevation movement/pathing enforcement remains incremental. New map APIs expose actor elevation traversal/cost queries, but full Operator/enemy/vehicle pathing enforcement remains a follow-up unless implemented in the navigation layer during this pass.
```

### Add to `FILE_INDEX.md`

```markdown
- `custodian/game/world/procgen/intent/worldgen_intent_node.gd` — route-first procgen intent node model for spawn, ascent beats, branches, faction sites, story rooms, vistas, resources, shortcuts, and exits.
- `custodian/game/world/procgen/intent/worldgen_intent_edge.gd` — route-first procgen edge model for main ascent paths, branches, story approaches, faction approaches, and shortcuts.
- `custodian/game/world/procgen/intent/worldgen_intent_graph.gd` — deterministic graph container exported through procgen level data.
- `custodian/game/world/procgen/intent/ascent_spine_builder.gd` — deterministic ascent-spine generator driven by map size, seed, origin, and world progression profile.
- `custodian/game/world/procgen/intent/region_footprint_reserver.gd` — converts intent graph nodes/edges into floor reservations and region footprints.
- `custodian/game/world/procgen/intent/worldgen_intent_debug_overlay.gd` — optional debug visualization for intent graph nodes, edges, and reserved regions.
- `custodian/game/world/procgen/story/story_room_geometry_stamper.gd` — V1 story-room geometry reservation stamper.
- `custodian/game/world/procgen/factions/faction_site_geometry_stamper.gd` — V1 faction-site geometry reservation stamper.
- `custodian/tools/validation/procgen_intent_graph_smoke.gd` — deterministic intent graph and reservation validation.
- `custodian/tools/validation/procgen_worldgen_shape_smoke.gd` — integrated procgen shape validation for intent graph export and reserved-region generation.
```

---

## Acceptance Checklist

Do not mark complete until **all** of these are true:

### Generation shape

- A deterministic intent graph exists before terrain/detail passes.
- Main route has spawn, ascent beats, and exit/upper beat.
- Branches exist for side pockets.
- Faction/story site reservations exist beyond the lowland band.
- Reserved graph floor cells are carved into the generated map.
- Reserved cells clear procgen wall visual/collision authority.

### Progression

- Distance bands are sampled from the world profile.
- Later beats trend higher and farther from spawn.
- Faction/story sites inherit band/style/faction metadata.

### Terrain/elevation

- TerrainBuilder receives intent required cells.
- TerrainBuilder receives reserved regions.
- Reserved regions get walkable height/traversal metadata.
- Existing terrain/elevation tests still pass.

### Runtime

- `get_level_data()` exports the intent graph and reserved regions.
- Existing roads, walls, foliage, props, portals, and constructed interiors still load.
- Story/faction placeholders no longer appear as random isolated markers only; they have claimed floor reservations.

### Validation

- `procgen_intent_graph_smoke.gd` passes.
- `procgen_worldgen_shape_smoke.gd` passes.
- Existing `terrain_builder_smoke.gd` passes.
- Existing `elevation_map_smoke.gd` passes.
- Existing `procgen_placeholder_roads_smoke.gd` passes (if it exists — see Phase 10 note).
- Full headless boot still completes.

### Docs

- Task packet updated.
- Design spec updated.
- CURRENT_STATE updated.
- FILE_INDEX updated.
- Any branch-audit findings recorded.

---

## Follow-Up Task

After this pass lands, the next task should be:

```
PROCGEN_STORY_AND_FACTION_SETPIECE_GEOMETRY_V1

Goal:
Turn V1 reservations into actual setpiece geometry.

Implement:
- story room template footprints
- faction camp/worksite prop clusters
- ambient activity anchor placement inside reserved sites
- authored-scene insertion with procgen authority claim
- local encounter escalation triggers
- debug screenshot export
- minimap identity markers
```

---

**The key correction:** main should stop treating world progression as an overlay and start treating it as the upstream shape contract. The old cave generator remains, but becomes texture/filler around the route-first ascent spine, not the thing that decides what the world is.
