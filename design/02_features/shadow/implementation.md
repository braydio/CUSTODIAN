# Shadow System - Implementation Addendum

> Detailed example code for ShadowSystem implementation
> Reference: Main design in `SHADOW_SYSTEM.md`

---

## File Structure

```
custodian/
├── core/
│   └── systems/
│       ├── shadow_system.gd      # Main shadow generation + procedural overlay system
│       └── navigation_system.gd  # Existing - provides tile data
├── entities/
│   ├── effects/
│   │   └── blob_shadow.gd        # Code-drawn ellipse shadow for actors
│   └── operator/
│       └── operator.tscn         # Add blob shadow node
├── scenes/
│   └── game.tscn                 # Existing runtime root
├── procgen/
│   ├── proc_gen_map.tscn         # Add ShadowOverlay node between floor and walls
│   └── proc_gen_tilemap.gd       # Trigger shadow regeneration after tile changes
```

## Implementation Note

The original design assumed a dedicated `ShadowTileMap` atlas. The current repo can implement the underlying behavior immediately without waiting on new art by drawing stylized procedural shadows from procgen tile data. That is the preferred first pass.

---

## 1. ShadowSystem.gd (Main System)

```gdscript
## ShadowSystem.gd
## Generates stylized shadows for tiles and entities
## 
## Usage:
##   var shadow_system = ShadowSystem.new()
##   shadow_system.initialize(floor_tilemap, wall_tilemap, shadow_tilemap)
##   shadow_system.generate_shadows()
##
## @category: Systems
## @tags: shadow, lighting, tilemap

class_name ShadowSystem
extends Node

# ═══════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════

## Global light direction - all shadows offset this way
## Top-left light → shadows go bottom-right
const SHADOW_OFFSET := Vector2i(2, 2)

## Shadow alpha range
const SHADOW_ALPHA_MIN := 0.15
const SHADOW_ALPHA_MAX := 0.35

## Corner shadow alpha (slightly darker)
const CORNER_ALPHA := 0.40

## Fade-in delay after tiles place (seconds)
const FADE_IN_DELAY := 0.02

# ═══════════════════════════════════════════════════════════════
# TILEMAP REFERENCES
# ═══════════════════════════════════════════════════════════════

## Floor tilemap (for detecting floor tiles)
var floor_tilemap: TileMapLayer

## Wall tilemap (for detecting wall tiles)
var wall_tilemap: TileMapLayer

## Shadow tilemap (where shadows are placed)
var shadow_tilemap: TileMapLayer

## Navigation system reference (for walkable data)
var navigation_system: NavigationSystem

# ═══════════════════════════════════════════════════════════════
# TILE DATA SOURCE
# ═══════════════════════════════════════════════════════════════

## Cached tile data - rebuilt when tilemaps change
var _floor_cells: Dictionary = {}      # Vector2i → bool (has floor)
var _wall_cells: Dictionary = {}       # Vector2i → bool (has wall)
var _used_cells: Array[Vector2i] = []

# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	Debug.log("[ShadowSystem] Initialized")


func initialize(
	p_floor_tilemap: TileMapLayer,
	p_wall_tilemap: TileMapLayer,
	p_shadow_tilemap: TileMapLayer,
	p_navigation_system: NavigationSystem = null
) -> void:
	"""
	Initialize the shadow system with tilemap references.
	Call this after all tilemaps are ready.
	"""
	floor_tilemap = p_floor_tilemap
	wall_tilemap = p_wall_tilemap
	shadow_tilemap = p_shadow_tilemap
	navigation_system = p_navigation_system
	
	# Build initial tile data
	_rebuild_tile_data()
	
	Debug.log("[ShadowSystem] Initialized with tilemaps")


func _rebuild_tile_data() -> void:
	"""
	Rebuild cached tile data from tilemaps.
	Call this when tilemaps change.
	"""
	_floor_cells.clear()
	_wall_cells.clear()
	_used_cells.clear()
	
	# Get floor cells
	if floor_tilemap:
		var floor_cells = floor_tilemap.get_used_cells()
		for cell in floor_cells:
			_floor_cells[cell] = true
			_used_cells.append(cell)
	
	# Get wall cells
	if wall_tilemap:
		var wall_cells = wall_tilemap.get_used_cells()
		for cell in wall_cells:
			_wall_cells[cell] = true
			if cell not in _used_cells:
				_used_cells.append(cell)
	
	Debug.log("[ShadowSystem] Tile data rebuilt: %d floor, %d wall" % [_floor_cells.size(), _wall_cells.size()])


# ═══════════════════════════════════════════════════════════════
# MAIN GENERATION
# ═══════════════════════════════════════════════════════════════

func generate_shadows() -> void:
	"""
	Generate all shadows - call this from procgen after tiles are placed.
	"""
	if not shadow_tilemap:
		push_warning("[ShadowSystem] No shadow tilemap set, skipping generation")
		return
	
	# Clear existing shadows
	_clear_shadows()
	
	# Rebuild tile data to ensure accuracy
	_rebuild_tile_data()
	
	# Generate shadows in priority order
	_generate_edge_shadows()      # Method 1 - most important
	_generate_corner_shadows()    # Method 3 - corner darkening
	
	Debug.log("[ShadowSystem] Shadows generated")


func _clear_shadows() -> void:
	"""Clear all shadows from shadow tilemap."""
	if shadow_tilemap:
		shadow_tilemap.clear()


# ═══════════════════════════════════════════════════════════════
# METHOD 1: EDGE SHADOWS
# ═══════════════════════════════════════════════════════════════

func _generate_edge_shadows() -> void:
	"""
	Method 1: Edge Shadows
	- Any wall tile that borders a floor tile casts a shadow onto the floor
	- Gives walls depth - makes them feel raised
	"""
	if not shadow_tilemap:
		return
	
	var shadow_count := 0
	
	for cell in _wall_cells.keys():
		# Check all 4 cardinal directions
		var directions := [
			Vector2i(0, 1),   # Below
			Vector2i(0, -1),  # Above
			Vector2i(1, 0),   # Right
			Vector2i(-1, 0)  # Left
		]
		
		for dir in directions:
			var neighbor = cell + dir
			
			# If wall borders floor, place shadow on floor
			if _is_floor(neighbor):
				_shadow_cell(neighbor, SHADOW_OFFSET)
				shadow_count += 1
	
	Debug.log("[ShadowSystem] Edge shadows placed: %d" % shadow_count)


# ═══════════════════════════════════════════════════════════════
# METHOD 3: CORNER DARKENING
# ═══════════════════════════════════════════════════════════════

func _generate_corner_shadows() -> void:
	"""
	Method 3: Corner Darkening
	- Detect corners where walls meet
	- Makes rooms feel enclosed, corridors feel deeper
	"""
	if not shadow_tilemap:
		return
	
	var corner_count := 0
	
	for cell in _wall_cells.keys():
		# Check for L-shaped corners (wall to right AND wall below)
		var right = cell + Vector2i(1, 0)
		var below = cell + Vector2i(0, 1)
		
		if _is_wall(right) and _is_wall(below):
			# Place corner shadow at the intersection
			_shadow_cell(cell, SHADOW_OFFSET, CORNER_ALPHA)
			corner_count += 1
		
		# Also check other L orientations
		var left = cell + Vector2i(-1, 0)
		var above = cell + Vector2i(0, -1)
		
		if _is_wall(left) and _is_wall(above):
			_shadow_cell(cell, SHADOW_OFFSET, CORNER_ALPHA)
			corner_count += 1
	
	Debug.log("[ShadowSystem] Corner shadows placed: %d" % corner_count)


# ═══════════════════════════════════════════════════════════════
# SHADOW PLACEMENT
# ═══════════════════════════════════════════════════════════════

func _shadow_cell(
	p_cell: Vector2i,
	p_offset: Vector2i = Vector2i.ZERO,
	p_alpha: float = SHADOW_ALPHA_MIN
) -> void:
	"""
	Place a shadow tile at the given cell with offset.
	"""
	if not shadow_tilemap:
		return
	
	var shadow_cell := p_cell + p_offset
	
	# Use source ID and atlas coordinates for shadow tile
	# Assuming atlas layout per SHADOW_SYSTEM.md
	var source_id := 0  # Adjust based on your tileset
	var atlas_coord := Vector2i(0, 0)  # Edge shadow default
	
	var data := TileMapCell.new()
	data.source_id = source_id
	data.atlas_coord = atlas_coord
	
	shadow_tilemap.set_cell(
		TileMapLayer.CELL_LAYOUT_SHIFTED,
		shadow_cell,
		source_id,
		atlas_coord
	)
	
	# Apply alpha via cell data (if your tileset supports it)
	# Or use modulate on the tilemap layer


# ═══════════════════════════════════════════════════════════════
# TILE CHECKING UTILITIES
# ═══════════════════════════════════════════════════════════════

func _is_floor(p_cell: Vector2i) -> bool:
	"""Check if cell has a floor tile."""
	return _floor_cells.has(p_cell)


func _is_wall(p_cell: Vector2i) -> bool:
	"""Check if cell has a wall tile."""
	return _wall_cells.has(p_cell)


func _is_walkable(p_cell: Vector2i) -> bool:
	"""
	Check if cell is walkable (has floor AND no wall).
	Uses navigation system if available.
	"""
	if navigation_system:
		return navigation_system.is_walkable(p_cell)
	
	# Fallback: has floor, no wall
	return _is_floor(p_cell) and not _is_wall(p_cell)


# ═══════════════════════════════════════════════════════════════
# PROCGEN INTEGRATION
# ═══════════════════════════════════════════════════════════════

## Call this from your procgen after placing tiles:
##   generate_chunk(chunk):
##       place_floor()
##       place_walls()
##       shadow_system.generate_shadows()  # <-- Add this
##       rebuild_navigation()


# ═══════════════════════════════════════════════════════════════
# REGENERATION (for dynamic worlds)
# ═══════════════════════════════════════════════════════════════

func regenerate() -> void:
	"""
	Regenerate all shadows - call this when tiles change.
	"""
	generate_shadows()


func set_shadow_offset(p_offset: Vector2i) -> void:
	"""
	Set global shadow offset direction.
	Top-left light → shadows go bottom-right
	"""
	SHADOW_OFFSET = p_offset
	regenerate()


func set_shadow_alpha(p_min: float, p_max: float = -1.0) -> void:
	"""
	Set shadow alpha range.
	"""
	SHADOW_ALPHA_MIN = p_min
	if p_max > 0:
		SHADOW_ALPHA_MAX = p_max
	regenerate()


# ═══════════════════════════════════════════════════════════════
# DEBUG
# ═══════════════════════════════════════════════════════════════

func get_shadow_count() -> int:
	"""Return count of placed shadows."""
	if shadow_tilemap:
		return shadow_tilemap.get_used_cells().size()
	return 0


func _to_string() -> String:
	return "[ShadowSystem: floor=%d, wall=%d, shadows=%d]" % [
		_floor_cells.size(),
		_wall_cells.size(),
		get_shadow_count()
	]
```

---

## 2. Integration with ProcGen

```gdscript
## In your procgen system (e.g., WorldGenerator.gd)

@export var shadow_system: ShadowSystem

func generate_chunk(chunk: Chunk) -> void:
	# ... existing tile placement ...
	place_floor(chunk)
	place_walls(chunk)
	
	# Generate shadows AFTER tiles (Method 5)
	if shadow_system:
		shadow_system.generate_shadows()
	
	# Rebuild navigation AFTER everything
	rebuild_navigation()
```

---

## 3. Integration with Game.tscn

```gdscript
## In game.gd or world.gd

@onready var floor_tilemap = $TileMap_Floor
@onready var wall_tilemap = $TileMap_Walls
@onready var shadow_tilemap = $TileMap_Shadow
@onready var navigation_system = $NavigationSystem
@onready var shadow_system = $ShadowSystem

func _ready() -> void:
	# Initialize shadow system after tilemaps ready
	shadow_system.initialize(
		floor_tilemap,
		wall_tilemap,
		shadow_tilemap,
		navigation_system
	)
```

---

## 4. Blob Shadow for Player

```gdscript
## In player.gd - Add blob shadow sprite

class_name Player
extends CharacterBody2D

## Blob shadow sprite
@onready var blob_shadow: Sprite2D = $BlobShadow

## Shadow offset from player
const BLOB_SHADOW_OFFSET := Vector2(0, 20)

## Shadow scale
const BLOB_SCALE := Vector2(1.2, 0.6)

## Shadow alpha
const BLOB_ALPHA := 0.25

func _ready() -> void:
	super._ready()
	_setup_blob_shadow()


func _setup_blob_shadow() -> void:
	"""Initialize blob shadow appearance."""
	if blob_shadow:
		blob_shadow.scale = BLOB_SCALE
		blob_shadow.modulate.a = BLOB_ALPHA
		blob_shadow.position = BLOB_SHADOW_OFFSET


func _physics_process(delta: float) -> void:
	# ... existing movement code ...
	
	# Update blob shadow position
	_update_blob_shadow()


func _update_blob_shadow() -> void:
	"""
	Update blob shadow - stretch with movement (Method 2 enhancement).
	"""
	if not blob_shadow:
		return
	
	# Base position
	blob_shadow.position = BLOB_SHADOW_OFFSET
	
	# Reactive stretch based on velocity
	var speed := velocity.length()
	var stretch := clampf(speed * 0.01, 0.0, 0.3)
	
	blob_shadow.scale = Vector2(
		BLOB_SCALE.x + stretch,
		BLOB_SCALE.y - stretch * 0.5
	)
```

### Blob Shadow Scene Setup

```
Player/
├── CollisionShape2D
├── Sprite2D (player art)
└── BlobShadow/ (Node2D or Sprite2D)
    ├── scale: (1.2, 0.6)
    ├── modulate: (0, 0, 0, 0.25)
    └── texture: ellipse_shadow.png
```

---

## 5. ShadowDebug.gd (Optional Debug)

```gdscript
## ShadowDebug.gd
## Debug visualization for shadow system
## Toggle with: Debug.toggle_shadows()

class_name ShadowDebug
extends Node2D

var shadow_system: ShadowSystem
var enabled := false

func _ready() -> void:
	visible = false


func setup(p_shadow_system: ShadowSystem) -> void:
	shadow_system = p_shadow_system


func _draw() -> void:
	if not enabled or not shadow_system:
		return
	
	# Draw shadow tiles for visualization
	var shadow_cells = shadow_system.get_shadow_tilemap().get_used_cells()
	
	for cell in shadow_cells:
		var world_pos = shadow_system.get_shadow_tilemap().map_to_local(cell)
		draw_rect(
			Rect2(world_pos, Vector2(32, 32)),
			Color(1, 1, 0, 0.3),  # Yellow, semi-transparent
			false,
			2.0
		)


func toggle() -> void:
	enabled = not enabled
	visible = enabled
	if enabled:
		queue_redraw()
```

---

## 6. Tilemap Setup (Editor)

### TileMap Layer Order (Bottom to Top)

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | `TileMap_Floor` | Walkable floor tiles |
| 2 | `TileMap_Shadow` | Generated shadow tiles |
| 3 | `TileMap_Walls` | Wall tiles (low) |
| 4 | `TileMap_HighWalls` | Blocking walls |
| 5 | `Entities` | Player, enemies, turrets |

### Shadow Tileset Atlas Layout

```
ShadowTileset.png (32x32 per tile):

Row 0: Edge Shadows
├── (0,0): Edge-bottom
├── (1,0): Edge-top  
├── (2,0): Edge-left
├── (3,0): Edge-right
├── (4,0): Edge-corner-bl
├── (5,0): Edge-corner-br
├── (6,0): Edge-corner-tl
└── (7,0): Edge-corner-tr

Row 1: Corner Shadows (darker)
├── (0,1): Corner-inner-bl
├── (1,1): Corner-inner-br
├── (2,1): Corner-inner-tl
└── (3,1): Corner-inner-tr
```

---

## 7. Complete Integration Example

```gdscript
## Full integration in game.tscn.gd

extends Node2D

@onready var floor_tilemap = $TileMapLayer_Floor
@onready var wall_tilemap = $TileMapLayer_Walls
@onready var shadow_tilemap = $TileMapLayer_Shadow
@onready var navigation_system = $NavigationSystem
@onready var shadow_system = $ShadowSystem

func _ready() -> void:
	# Wait for procgen to complete
	await procgen generation_complete
	
	# Initialize and generate shadows
	shadow_system.initialize(
		floor_tilemap,
		wall_tilemap,
		shadow_tilemap,
		navigation_system
	)
	
	# Method 6: Fade-in effect
	await get_tree().create_timer(FADE_IN_DELAY).timeout
	shadow_system.generate_shadows()
	
	Debug.log("[Game] Shadow system integrated")


# External trigger - call when world changes
func on_world_regenerate() -> void:
	shadow_system.regenerate()
```

---

## Summary

| Component | File | Purpose |
|-----------|------|---------|
| Main System | `shadow_system.gd` | Edge + corner shadow generation |
| Integration | `game.gd` | Hook into procgen |
| Player Shadow | `player.gd` | Blob shadow sprite |
| Debug | `shadow_debug.gd` | Visualization |

## Implementation Status (2026-03-30)

- `custodian/core/systems/shadow_system.gd` already generates the edge/corner overlays described in this doc, respects the global offset/alpha settings, and exposes `request_regenerate` so the procgen flow can refresh shadows whenever tiles change.
- Blob shadows are live under `custodian/entities/operator/operator.tscn`; the ellipse shader in `custodian/entities/effects/blob_shadow.gd` stretches with the operator's movement.
- `procgen/proc_gen_tilemap.gd` now looks up the `ShadowOverlay` node and calls `_refresh_shadows()` right after floor/wall updates, ensuring runtime walls fountain as expected.
- Remaining work includes authoring a dedicated `ShadowTileset` atlas for the shadow `TileMap`, providing a `ShadowDebug` helper (for visualization/testing), and the fade-in/settling timing once art assets finalize.

---

*Addendum created: 2026-03-26*
*Main design: `SHADOW_SYSTEM.md`*
