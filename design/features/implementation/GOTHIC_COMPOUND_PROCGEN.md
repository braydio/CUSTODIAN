# Gothic Compound Procgen

Status: implemented-first-slice

## Goal

Guarantee one readable gothic-industrial compound through a deterministic authored/procedural hybrid:

1. reserve area
2. fill continuous terrain
3. build perimeter
4. cut south gate
5. carve road connectivity
6. place required structures
7. place props/resources/markers
8. validate required invariants

## Current Implementation

The first implementation slice lives under `custodian/game/world/procgen/gothic_compound/` and is wired into the connected gothic compound destination map at `custodian/game/world/gothic_compound/gothic_compound_map.gd`.

The generator currently uses a Sprite2D adapter for the authored connected-map prototype. The split is intentionally kept compatible with a later TileMapLayer adapter for the main tactical procgen map.

The connected-map prototype now uses explicit render bands for the Sprite2D adapter: terrain, roads, and decals render below the operator; low/static cover renders as normal props; large buildings and tall exterior occluders carry metadata for player-relative depth sorting. The connected map calls the sprite context each frame so the operator renders in front of buildings until their feet cross the building's depth horizon.

## Required Invariants

- One compound rect exists.
- Compound rect has continuous base terrain fill.
- Perimeter wall exists.
- South main gate exists.
- Gate passage is walkable.
- Road connects south map edge to gate.
- Internal road connects gate to command keep.
- Command keep exists.
- Terminal exists.
- Required route is not blocked.
- Exterior resource nodes are reachable.

## Asset Source

Use sliced PNG assets in:

`custodian/content/procgen/special_rooms/gothic_compound/`

Master sheets are source assets only.

## Layer Model

- Base terrain: no collision, always below the player.
- Roads/platforms: no collision, always below the player.
- Decals/grates/light pools: no collision, always below the player.
- Walls/static low cover: collision where appropriate, fixed prop/wall render band.
- Large structures/tall props: collision where appropriate, top-left anchored with footprint metadata and player-relative depth sorting.
- Open gate threshold: no collision.
- Markers: hidden/debug only.

## Validation

If validation fails, retry candidate placement. If all retries fail, place fallback blueprint centered on the map.

## Original Review Notes

The remainder of this document is the original review/spec that drove the implementation.

---

Below is a **Codex-ready implementation spec** with concrete GDScript examples. The intent is to replace the current “asset scatter grid” behavior with a **guaranteed compound blueprint pass**: reserve area → fill ground → build perimeter → cut gate → place roads → place required structures → decorate → validate.

This should be treated as a Godot runtime change under `custodian/`, and your repo guidance says Godot runtime changes should update `./design/` first and active AI context docs when runtime state/architecture changes. The available gothic compound assets are already sliced under `custodian/content/procgen/special_rooms/gothic_compound/`, including terrain, walls, roads, gates, structures, props, resource nodes, markers, and decals.

---

# 1. Implementation objective

## Current failure

The screenshot shows this failure mode:

```text
terrain patches are being placed like props
roads are decorative, not connectivity-driven
walls do not form a perimeter
large structures overlap the layout grammar
scatter is placed before the compound exists
```

## Required behavior

Every generated map should contain a readable gothic compound with:

```text
continuous compound ground
enclosing perimeter wall
south-facing gate
approach road from map edge
inner road from gate to keep
command keep
terminal
at least one utility structure
some defensive props
some exterior resources
hidden spawn/debug markers
validation/fallback if generation fails
```

---

# 2. Add these files

Tell Codex to create:

```text
custodian/game/world/procgen/gothic_compound/
├── gothic_compound_assets.gd
├── gothic_compound_config.gd
├── gothic_compound_result.gd
├── gothic_compound_generator.gd
└── gothic_compound_validator.gd
```

Also create the design note first:

```text
design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md
```

If your current procgen folder uses a different convention, Codex can adapt the paths, but it should keep the split between **asset registry**, **config**, **generator**, and **validator**.

---

# 3. Design note Codex should write first

Create:

```text
design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md
```

Content:

```markdown
# Gothic Compound Procgen

Status: draft

## Goal

Guarantee one readable gothic-industrial compound per generated map.

The compound is generated as a deterministic authored/procedural hybrid:

1. reserve area
2. fill terrain
3. build perimeter
4. cut gate
5. carve road connectivity
6. place required structures
7. place props/resources/markers
8. validate required invariants

## Current bug being fixed

The old pass placed terrain assets as isolated decorative stamps, causing visible grid repetition and no real compound structure.

## Required invariants

- One compound rect exists.
- Compound rect has continuous base terrain fill.
- Perimeter wall exists.
- South main gate exists.
- Gate passage is walkable.
- Road connects south map edge to gate.
- Internal road connects gate to command keep.
- Command keep exists.
- Terminal exists.
- Required route is not blocked.
- Exterior resource nodes are reachable.

## Asset source

Use sliced PNG assets in:

`custodian/content/procgen/special_rooms/gothic_compound/`

Master sheets are source assets only.

## Layer model

- Base terrain: no collision.
- Roads/platforms: no collision.
- Walls/gates/large structures/heavy cover: collision.
- Open gate threshold: no collision.
- Markers: hidden/debug only.

## Validation

If validation fails, retry candidate placement. If all retries fail, place fallback blueprint centered on the map.
```

---

# 4. Core data model

## `gothic_compound_config.gd`

```gdscript
extends Resource
class_name GothicCompoundConfig

@export var enabled: bool = true

@export var tile_size: int = 32

@export var min_size: Vector2i = Vector2i(34, 26)
@export var max_size: Vector2i = Vector2i(46, 34)
@export var margin_from_map_edge: int = 6
@export var max_placement_attempts: int = 40

@export var gate_side: String = "south"
@export var gate_width_tiles: int = 5

@export var outer_margin_fill: int = 5
@export var inner_wall_margin: int = 1

@export var wall_pillar_stride: int = 5
@export var wall_damage_chance: float = 0.10

@export var exterior_resource_count: int = 2
@export var enemy_marker_count: int = 4

@export var decorative_scatter_chance: float = 0.08
@export var exterior_scatter_chance: float = 0.06

@export var debug_mark_required_paths: bool = false
```

---

## `gothic_compound_result.gd`

```gdscript
extends RefCounted
class_name GothicCompoundResult

var ok: bool = false
var used_fallback: bool = false
var rect: Rect2i
var gate_cell: Vector2i
var command_keep_cell: Vector2i
var terminal_cell: Vector2i

var approach_path: Array[Vector2i] = []
var internal_path: Array[Vector2i] = []
var required_walkable: Dictionary = {}

var placed_walls: Array[Vector2i] = []
var placed_structures: Array[Vector2i] = []
var placed_props: Array[Vector2i] = []
var placed_resources: Array[Vector2i] = []
var placed_markers: Array[Vector2i] = []

var errors: Array[String] = []

func mark_required_path(path: Array[Vector2i]) -> void:
	for c in path:
		required_walkable[c] = true
```

---

# 5. Asset registry

Use logical keys instead of raw filenames throughout generator code.

## `gothic_compound_assets.gd`

```gdscript
extends RefCounted
class_name GothicCompoundAssets

const ROOT := "res://content/procgen/special_rooms/gothic_compound/"

const TERRAIN := {
	"ash_a": ROOT + "01_terrain_ash_base_dark_a.png",
	"ash_b": ROOT + "02_terrain_ash_base_dark_b.png",
	"ash_roots": ROOT + "03_terrain_ash_roots_cracked_a.png",
	"rocky_ash": ROOT + "05_terrain_rocky_ash_base_a.png",
	"cracked_rock_a": ROOT + "06_terrain_cracked_rock_base_a.png",
	"cracked_rock_b": ROOT + "07_terrain_cracked_rock_base_b.png",
	"stone_a": ROOT + "12_terrain_stone_cracked_base_a.png",
	"stone_b": ROOT + "13_terrain_stone_cracked_base_b.png",
	"stone_c": ROOT + "14_terrain_stone_cracked_base_c.png",
}

const ROADS := {
	"ew": ROOT + "15_road_straight_ew_long.png",
	"ns_a": ROOT + "16_road_straight_ns_a.png",
	"ns_b": ROOT + "17_road_straight_ns_b.png",
	"ns_cracked": ROOT + "21_road_straight_ns_cracked.png",
	"cross": ROOT + "29_road_cross_intersection.png",
	"end_s": ROOT + "18_road_end_s_rounded.png",
	"corner_sw": ROOT + "19_road_corner_or_end_sw.png",
	"corner_se": ROOT + "20_road_corner_or_end_se.png",
	"t_s_a": ROOT + "22_road_t_junction_s_a.png",
	"t_s_b": ROOT + "23_road_t_junction_s_b.png",
	"t_s_c": ROOT + "24_road_t_junction_s_c.png",
	"t_s_d": ROOT + "25_road_t_junction_s_d.png",
	"dirt_ns_a": ROOT + "36_road_straight_ns_dirt_edge_a.png",
	"dirt_ns_b": ROOT + "37_road_straight_ns_dirt_edge_b.png",
	"path_a": ROOT + "47_path_worn_dirt_vertical_a.png",
	"path_b": ROOT + "48_path_worn_dirt_vertical_b.png",
	"path_c": ROOT + "49_path_worn_dirt_vertical_c.png",
}

const WALLS := {
	"h_a": ROOT + "01_wall_straight_w_pillar_conn_e.png",
	"h_b": ROOT + "25_wall_straight_conn_e_w_left_pillar.png",
	"h_c": ROOT + "27_wall_straight_conn_w_e_right_pillar.png",
	"h_damaged": ROOT + "06_wall_straight_damaged_conn_w_e.png",
	"h_broken": ROOT + "26_wall_broken_rubble_conn_w_e_left_pillar.png",

	"v_a": ROOT + "21_wall_straight_vertical_conn_n_s_large.png",
	"pillar": ROOT + "02_wall_pillar_spire_single.png",
	"pillar_thin": ROOT + "23_wall_pillar_thin_small.png",

	"corner_se": ROOT + "03_wall_corner_l_conn_s_e.png",
	"corner_sw": ROOT + "04_wall_corner_l_conn_s_w.png",
	"corner_spire_sw": ROOT + "08_wall_corner_spire_conn_s_w.png",
	"curve_sw": ROOT + "13_wall_curve_corner_conn_s_w.png",
	"curve_se": ROOT + "14_wall_curve_corner_conn_s_e.png",

	"gap_broken": ROOT + "30_wall_broken_rubble_gap.png",
}

const GATES := {
	"gatehouse_open": ROOT + "36_gatehouse_main_open_large.png",
	"gatehouse_closed": ROOT + "35_gatehouse_main_closed_large.png",
	"heavy_closed": ROOT + "37_gate_heavy_closed_blocking.png",
	"open_arch": ROOT + "39_gate_open_arch_frame.png",
	"threshold_open": ROOT + "15_gate_threshold_open_walkable.png",
	"threshold_closed": ROOT + "14_gate_threshold_closed_blocking.png",
	"threshold_stone": ROOT + "44_threshold_stone_small.png",
}

const STRUCTURES := {
	"command_keep": ROOT + "01_structure_command_keep_gothic_large.png",
	"utility_fan": ROOT + "02_structure_utility_fan_roof_block.png",
	"machine_house": ROOT + "03_structure_machine_house_gothic_industrial.png",
	"platform_plain": ROOT + "04_platform_stone_plain_large.png",
	"platform_symbol": ROOT + "05_platform_stone_symbol_large.png",
	"platform_hazard": ROOT + "06_platform_hazard_striped_large.png",
	"fountain": ROOT + "08_structure_dry_fountain_basin_octagonal.png",
	"bell_frame": ROOT + "09_bell_frame_gothic_small.png",
	"terminal": ROOT + "13_terminal_compound_control_console.png",
	"dead_pylon": ROOT + "43_pylon_dead_light.png",
}

const PROPS := {
	"sandbag_h": ROOT + "01_cover_sandbag_straight_h.png",
	"sandbag_curve": ROOT + "02_cover_sandbag_corner_curve.png",
	"stone_cover_h": ROOT + "03_cover_stone_low_wall_h.png",
	"fence_long_h": ROOT + "04_fence_wrought_iron_long_h.png",
	"fence_short_h": ROOT + "05_fence_wrought_iron_short_h.png",
	"spike_h": ROOT + "06_spike_barricade_h.png",
	"chain_posts_h": ROOT + "07_barrier_chain_posts_h.png",
	"crate": ROOT + "08_crate_single.png",
	"crates": ROOT + "09_crate_stack_large.png",
	"barrel": ROOT + "10_barrel_single.png",
	"barrels": ROOT + "11_barrel_stack_cluster.png",
	"generator": ROOT + "12_generator_block_industrial.png",
	"lamp": ROOT + "13_lamp_post_amber.png",
	"banner": ROOT + "16_banner_black_torn.png",
	"rubble_s": ROOT + "19_rubble_pile_small.png",
	"rubble_m": ROOT + "20_rubble_pile_medium.png",
	"rubble_l": ROOT + "21_rubble_pile_large.png",
	"dead_shrub": ROOT + "23_dead_shrub_small.png",
	"dead_tree": ROOT + "25_dead_tree_large.png",
	"collapsed_spire": ROOT + "42_collapsed_spire_ruin_large.png",
}

const RESOURCES := {
	"ruin_scrap": ROOT + "32_resource_node_ruin_scrap_gothic.png",
	"blackwood": ROOT + "33_resource_node_blackwood_deadfall_gothic.png",
}

const MARKERS := {
	"spawn_plain": ROOT + "34_marker_hidden_spawn_x_plain.png",
	"spawn_amber": ROOT + "35_marker_hidden_spawn_x_amber.png",
	"spawn_rocky": ROOT + "36_marker_hidden_spawn_rocky_x.png",
	"spawn_ring": ROOT + "37_marker_hidden_spawn_ring_amber.png",
	"spawn_stone": ROOT + "38_marker_hidden_spawn_stone_ring.png",
	"spawn_ember": ROOT + "39_marker_hidden_spawn_ember_star.png",
}

const DECALS := {
	"grate_square": ROOT + "50_grate_square_metal.png",
	"grate_round": ROOT + "51_grate_round_metal.png",
	"floor_sigil": ROOT + "52_floor_sigil_stone_square.png",
	"light_pool": ROOT + "53_decal_light_pool_amber.png",
	"shadow": ROOT + "54_decal_shadow_smoke_dark.png",
}
```

---

# 6. Generator API assumptions

Because I do not have your exact current Godot procgen API in this prompt, the implementation should use an adapter interface. Codex should wire these adapter methods to your actual TileMap/scene-spawn calls.

The generator below assumes a `ctx` object with these methods:

```gdscript
ctx.map_size: Vector2i
ctx.world_seed: int

ctx.set_floor(cell: Vector2i, asset_path: String) -> void
ctx.set_road(cell: Vector2i, asset_path: String) -> void
ctx.set_wall(cell: Vector2i, asset_path: String, blocks: bool = true) -> void
ctx.set_decal(cell: Vector2i, asset_path: String) -> void

ctx.spawn_prop(cell: Vector2i, asset_path: String, blocks: bool = false, size: Vector2i = Vector2i.ONE) -> void
ctx.spawn_marker(cell: Vector2i, asset_path: String, marker_type: String) -> void

ctx.clear_cell(cell: Vector2i) -> void
ctx.reserve_cell(cell: Vector2i) -> void
ctx.is_blocked(cell: Vector2i) -> bool
ctx.is_reserved(cell: Vector2i) -> bool
ctx.mark_blocked(cell: Vector2i, blocked: bool = true) -> void
ctx.mark_walkable(cell: Vector2i, walkable: bool = true) -> void
ctx.is_walkable(cell: Vector2i) -> bool
```

Codex should either:

1. map these to existing procgen functions, or
2. create a small adapter class around the current TileMap nodes.

---

# 7. Generator implementation

## `gothic_compound_generator.gd`

```gdscript
extends RefCounted
class_name GothicCompoundGenerator

const GothicCompoundAssets = preload("res://game/world/procgen/gothic_compound/gothic_compound_assets.gd")
const GothicCompoundConfig = preload("res://game/world/procgen/gothic_compound/gothic_compound_config.gd")
const GothicCompoundResult = preload("res://game/world/procgen/gothic_compound/gothic_compound_result.gd")
const GothicCompoundValidator = preload("res://game/world/procgen/gothic_compound/gothic_compound_validator.gd")

var cfg: GothicCompoundConfig
var rng := RandomNumberGenerator.new()

func _init(config: GothicCompoundConfig = null) -> void:
	cfg = config if config != null else GothicCompoundConfig.new()

func generate(ctx) -> GothicCompoundResult:
	var result := GothicCompoundResult.new()

	if not cfg.enabled:
		result.errors.append("Gothic compound generation disabled.")
		return result

	rng.seed = _compound_seed(ctx.world_seed)

	for attempt in range(cfg.max_placement_attempts):
		var rect := _find_candidate_rect(ctx)
		if rect.size == Vector2i.ZERO:
			continue

		result = _generate_at_rect(ctx, rect, false)

		if GothicCompoundValidator.validate(ctx, result):
			result.ok = true
			return result

		_rollback_or_rebuild_world_if_supported(ctx, result)

	result = _generate_at_rect(ctx, _fallback_rect(ctx), true)
	result.used_fallback = true

	if GothicCompoundValidator.validate(ctx, result):
		result.ok = true
	else:
		result.ok = false
		result.errors.append("Fallback gothic compound failed validation.")

	return result

func _compound_seed(world_seed: int) -> int:
	return hash(str(world_seed) + ":gothic_compound_v1")

func _find_candidate_rect(ctx) -> Rect2i:
	var w := rng.randi_range(cfg.min_size.x, cfg.max_size.x)
	var h := rng.randi_range(cfg.min_size.y, cfg.max_size.y)

	var min_x := cfg.margin_from_map_edge
	var min_y := cfg.margin_from_map_edge
	var max_x := ctx.map_size.x - w - cfg.margin_from_map_edge
	var max_y := ctx.map_size.y - h - cfg.margin_from_map_edge

	if max_x <= min_x or max_y <= min_y:
		return Rect2i()

	var pos := Vector2i(
		rng.randi_range(min_x, max_x),
		rng.randi_range(min_y, max_y)
	)

	var rect := Rect2i(pos, Vector2i(w, h))

	if _rect_has_conflicts(ctx, rect.grow(cfg.outer_margin_fill)):
		return Rect2i()

	return rect

func _fallback_rect(ctx) -> Rect2i:
	var size := Vector2i(
		min(cfg.min_size.x, ctx.map_size.x - cfg.margin_from_map_edge * 2),
		min(cfg.min_size.y, ctx.map_size.y - cfg.margin_from_map_edge * 2)
	)

	var pos := Vector2i(
		(ctx.map_size.x - size.x) / 2,
		max(cfg.margin_from_map_edge, (ctx.map_size.y - size.y) / 2)
	)

	return Rect2i(pos, size)

func _rect_has_conflicts(ctx, rect: Rect2i) -> bool:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var c := Vector2i(x, y)
			if not _in_map(ctx, c):
				return true
			if ctx.is_reserved(c):
				return true
	return false

func _generate_at_rect(ctx, rect: Rect2i, fallback: bool) -> GothicCompoundResult:
	var result := GothicCompoundResult.new()
	result.rect = rect
	result.used_fallback = fallback

	_reserve_and_clear(ctx, rect)
	_fill_base_terrain(ctx, rect)
	_build_perimeter(ctx, result, rect)
	_place_gate(ctx, result, rect)
	_carve_approach_road(ctx, result)
	_carve_internal_road(ctx, result, rect)
	_place_required_structures(ctx, result, rect)
	_place_utility_structures(ctx, result, rect)
	_place_defenses(ctx, result, rect)
	_place_exterior_resources(ctx, result, rect)
	_place_scatter_and_decals(ctx, result, rect)
	_place_spawn_markers(ctx, result, rect)

	return result
```

---

# 8. Reserve and continuous terrain fill

This fixes the visible checkerboard floor problem.

```gdscript
func _reserve_and_clear(ctx, rect: Rect2i) -> void:
	var grown := rect.grow(cfg.outer_margin_fill)

	for y in range(grown.position.y, grown.position.y + grown.size.y):
		for x in range(grown.position.x, grown.position.x + grown.size.x):
			var c := Vector2i(x, y)
			if not _in_map(ctx, c):
				continue
			ctx.clear_cell(c)
			ctx.reserve_cell(c)

func _fill_base_terrain(ctx, rect: Rect2i) -> void:
	var outer := rect.grow(cfg.outer_margin_fill)

	for y in range(outer.position.y, outer.position.y + outer.size.y):
		for x in range(outer.position.x, outer.position.x + outer.size.x):
			var c := Vector2i(x, y)
			if not _in_map(ctx, c):
				continue

			var inside := rect.has_point(c)
			var asset := ""

			if inside:
				asset = _pick_inside_ground(c)
			else:
				asset = _pick_exterior_ground(c)

			ctx.set_floor(c, asset)
			ctx.mark_walkable(c, true)

func _pick_inside_ground(cell: Vector2i) -> String:
	var roll := _stable_noise01(cell, 11)

	if roll < 0.55:
		return GothicCompoundAssets.TERRAIN["stone_a"]
	if roll < 0.78:
		return GothicCompoundAssets.TERRAIN["stone_b"]
	if roll < 0.90:
		return GothicCompoundAssets.TERRAIN["stone_c"]
	if roll < 0.96:
		return GothicCompoundAssets.TERRAIN["cracked_rock_a"]
	return GothicCompoundAssets.TERRAIN["ash_a"]

func _pick_exterior_ground(cell: Vector2i) -> String:
	var roll := _stable_noise01(cell, 17)

	if roll < 0.45:
		return GothicCompoundAssets.TERRAIN["ash_a"]
	if roll < 0.70:
		return GothicCompoundAssets.TERRAIN["ash_b"]
	if roll < 0.84:
		return GothicCompoundAssets.TERRAIN["rocky_ash"]
	if roll < 0.94:
		return GothicCompoundAssets.TERRAIN["ash_roots"]
	return GothicCompoundAssets.TERRAIN["cracked_rock_b"]

func _stable_noise01(cell: Vector2i, salt: int) -> float:
	var h := hash(str(cell.x) + ":" + str(cell.y) + ":" + str(salt))
	return float(abs(h % 10000)) / 10000.0
```

**Critical fix:** `ctx.set_floor()` must write to a continuous tile/floor layer. It must not spawn 32×32 terrain sprites at sparse intervals.

---

# 9. Perimeter generation

This gives the map an actual compound boundary.

```gdscript
func _build_perimeter(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.position.x + rect.size.x - 1
	var y1 := rect.position.y + rect.size.y - 1

	var gate_center_x := x0 + rect.size.x / 2
	var gate_half := cfg.gate_width_tiles / 2

	for x in range(x0, x1 + 1):
		var north := Vector2i(x, y0)
		_place_wall_cell(ctx, result, north, "h")

		var south := Vector2i(x, y1)

		if abs(x - gate_center_x) <= gate_half:
			continue

		_place_wall_cell(ctx, result, south, "h")

	for y in range(y0, y1 + 1):
		var west := Vector2i(x0, y)
		var east := Vector2i(x1, y)
		_place_wall_cell(ctx, result, west, "v")
		_place_wall_cell(ctx, result, east, "v")

	_place_corner(ctx, result, Vector2i(x0, y0), "nw")
	_place_corner(ctx, result, Vector2i(x1, y0), "ne")
	_place_corner(ctx, result, Vector2i(x0, y1), "sw")
	_place_corner(ctx, result, Vector2i(x1, y1), "se")

	_place_wall_pillars(ctx, result, rect)

func _place_wall_cell(ctx, result: GothicCompoundResult, cell: Vector2i, orientation: String) -> void:
	var asset := ""

	if orientation == "v":
		asset = GothicCompoundAssets.WALLS["v_a"]
	else:
		var roll := rng.randf()
		if roll < cfg.wall_damage_chance:
			asset = GothicCompoundAssets.WALLS["h_damaged"]
		elif roll < cfg.wall_damage_chance + 0.04:
			asset = GothicCompoundAssets.WALLS["h_broken"]
		else:
			asset = GothicCompoundAssets.WALLS["h_a"]

	ctx.set_wall(cell, asset, true)
	ctx.mark_blocked(cell, true)
	result.placed_walls.append(cell)

func _place_corner(ctx, result: GothicCompoundResult, cell: Vector2i, kind: String) -> void:
	var asset := GothicCompoundAssets.WALLS["pillar"]

	match kind:
		"sw":
			asset = GothicCompoundAssets.WALLS["corner_sw"]
		"se":
			asset = GothicCompoundAssets.WALLS["corner_se"]
		"nw":
			asset = GothicCompoundAssets.WALLS["corner_spire_sw"]
		"ne":
			asset = GothicCompoundAssets.WALLS["corner_se"]

	ctx.set_wall(cell, asset, true)
	ctx.mark_blocked(cell, true)
	result.placed_walls.append(cell)

func _place_wall_pillars(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.position.x + rect.size.x - 1
	var y1 := rect.position.y + rect.size.y - 1

	for x in range(x0 + cfg.wall_pillar_stride, x1, cfg.wall_pillar_stride):
		_place_pillar(ctx, result, Vector2i(x, y0))
		if abs(x - (x0 + rect.size.x / 2)) > cfg.gate_width_tiles:
			_place_pillar(ctx, result, Vector2i(x, y1))

	for y in range(y0 + cfg.wall_pillar_stride, y1, cfg.wall_pillar_stride):
		_place_pillar(ctx, result, Vector2i(x0, y))
		_place_pillar(ctx, result, Vector2i(x1, y))

func _place_pillar(ctx, result: GothicCompoundResult, cell: Vector2i) -> void:
	ctx.set_wall(cell, GothicCompoundAssets.WALLS["pillar"], true)
	ctx.mark_blocked(cell, true)
	result.placed_walls.append(cell)
```

---

# 10. Gate placement

The main gate must cut through the perimeter and be walkable.

```gdscript
func _place_gate(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var gate_center := Vector2i(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y - 1
	)

	result.gate_cell = gate_center

	var gate_half := cfg.gate_width_tiles / 2

	for dx in range(-gate_half, gate_half + 1):
		var c := gate_center + Vector2i(dx, 0)
		ctx.clear_cell(c)
		ctx.set_road(c, GothicCompoundAssets.GATES["threshold_open"])
		ctx.mark_blocked(c, false)
		ctx.mark_walkable(c, true)
		result.required_walkable[c] = true

	# Place the big visual gatehouse slightly above the wall line.
	# Size is approximate; use real sprite dimensions if available.
	var gatehouse_cell := gate_center + Vector2i(-2, -2)
	ctx.spawn_prop(
		gatehouse_cell,
		GothicCompoundAssets.GATES["gatehouse_open"],
		true,
		Vector2i(5, 4)
	)

	# Re-open the actual passage cells because the gatehouse visual should not block them.
	for dx in range(-gate_half, gate_half + 1):
		var passage := gate_center + Vector2i(dx, 0)
		ctx.mark_blocked(passage, false)
		ctx.mark_walkable(passage, true)
```

**Important:** if the gatehouse sprite visually overlaps the road, its collision should be custom, not a full rectangle. In v0, use a simplified collision mask that leaves the central passage open.

---

# 11. Approach road

This replaces decorative cross placement with real connectivity.

```gdscript
func _carve_approach_road(ctx, result: GothicCompoundResult) -> void:
	var start := Vector2i(result.gate_cell.x, ctx.map_size.y - 2)
	var end := result.gate_cell + Vector2i(0, 1)

	var path := _orthogonal_path(start, end, false)

	for c in path:
		if not _in_map(ctx, c):
			continue

		var asset := _pick_ns_road()
		ctx.set_road(c, asset)
		ctx.mark_walkable(c, true)
		ctx.mark_blocked(c, false)

	result.approach_path = path
	result.mark_required_path(path)

func _pick_ns_road() -> String:
	var roll := rng.randf()

	if roll < 0.60:
		return GothicCompoundAssets.ROADS["ns_a"]
	if roll < 0.82:
		return GothicCompoundAssets.ROADS["ns_b"]
	if roll < 0.92:
		return GothicCompoundAssets.ROADS["ns_cracked"]
	if roll < 0.96:
		return GothicCompoundAssets.ROADS["dirt_ns_a"]
	return GothicCompoundAssets.ROADS["dirt_ns_b"]
```

---

# 12. Inner yard and internal road

```gdscript
func _carve_internal_road(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var yard_center := Vector2i(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)

	var keep_cell := Vector2i(
		rect.position.x + rect.size.x / 2,
		rect.position.y + 5
	)

	result.command_keep_cell = keep_cell

	var from_gate := result.gate_cell + Vector2i(0, -1)
	var to_keep := keep_cell + Vector2i(0, 4)

	var path := _orthogonal_path(from_gate, to_keep, true)

	for c in path:
		if not rect.has_point(c):
			continue

		var asset := GothicCompoundAssets.ROADS["ns_a"]
		if c == yard_center:
			asset = GothicCompoundAssets.ROADS["cross"]
		ctx.set_road(c, asset)
		ctx.mark_walkable(c, true)
		ctx.mark_blocked(c, false)

	# horizontal yard axis
	var left := Vector2i(rect.position.x + 7, yard_center.y)
	var right := Vector2i(rect.position.x + rect.size.x - 8, yard_center.y)

	for c in _orthogonal_path(left, right, false):
		ctx.set_road(c, GothicCompoundAssets.ROADS["ew"])
		ctx.mark_walkable(c, true)
		ctx.mark_blocked(c, false)

	result.internal_path = path
	result.mark_required_path(path)

	# Visual focal point at road crossing
	ctx.spawn_prop(yard_center + Vector2i(-1, -1), GothicCompoundAssets.STRUCTURES["fountain"], false, Vector2i(3, 3))
```

Path helper:

```gdscript
func _orthogonal_path(start: Vector2i, end: Vector2i, vertical_first: bool) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := start

	if vertical_first:
		while current.y != end.y:
			path.append(current)
			current.y += signi(end.y - current.y)
		while current.x != end.x:
			path.append(current)
			current.x += signi(end.x - current.x)
	else:
		while current.x != end.x:
			path.append(current)
			current.x += signi(end.x - current.x)
		while current.y != end.y:
			path.append(current)
			current.y += signi(end.y - current.y)

	path.append(end)
	return path

func signi(v: int) -> int:
	if v < 0:
		return -1
	if v > 0:
		return 1
	return 0
```

---

# 13. Required structures with occupancy checks

This prevents giant buildings from stomping roads.

```gdscript
func _place_required_structures(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var keep_size := Vector2i(9, 7)
	var keep_pos := result.command_keep_cell - Vector2i(keep_size.x / 2, 1)

	_place_blocking_structure_checked(
		ctx,
		result,
		keep_pos,
		keep_size,
		GothicCompoundAssets.STRUCTURES["command_keep"],
		true,
		"command_keep"
	)

	var terminal_pos := result.command_keep_cell + Vector2i(6, 5)
	result.terminal_cell = terminal_pos

	_place_blocking_structure_checked(
		ctx,
		result,
		terminal_pos,
		Vector2i(2, 2),
		GothicCompoundAssets.STRUCTURES["terminal"],
		true,
		"terminal"
	)

func _place_blocking_structure_checked(
	ctx,
	result: GothicCompoundResult,
	pos: Vector2i,
	size: Vector2i,
	asset: String,
	blocks: bool,
	label: String
) -> bool:
	if not _can_place_rect(ctx, result, pos, size, true):
		result.errors.append("Could not place required structure: " + label)
		return false

	ctx.spawn_prop(pos, asset, blocks, size)

	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var c := Vector2i(x, y)
			if blocks:
				ctx.mark_blocked(c, true)
			result.placed_structures.append(c)

	return true

func _can_place_rect(ctx, result: GothicCompoundResult, pos: Vector2i, size: Vector2i, respect_required_path: bool) -> bool:
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var c := Vector2i(x, y)

			if not _in_map(ctx, c):
				return false

			if respect_required_path and result.required_walkable.has(c):
				return false

			if ctx.is_blocked(c):
				return false

	return true
```

---

# 14. Optional structures

```gdscript
func _place_utility_structures(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var candidates := [
		{
			"cell": Vector2i(rect.position.x + 5, rect.position.y + rect.size.y / 2 - 3),
			"size": Vector2i(5, 5),
			"asset": GothicCompoundAssets.STRUCTURES["utility_fan"],
			"label": "utility_fan"
		},
		{
			"cell": Vector2i(rect.position.x + rect.size.x - 10, rect.position.y + rect.size.y / 2 - 3),
			"size": Vector2i(5, 5),
			"asset": GothicCompoundAssets.STRUCTURES["machine_house"],
			"label": "machine_house"
		},
		{
			"cell": Vector2i(rect.position.x + 6, rect.position.y + rect.size.y - 9),
			"size": Vector2i(3, 4),
			"asset": GothicCompoundAssets.STRUCTURES["bell_frame"],
			"label": "bell_frame"
		}
	]

	for entry in candidates:
		_place_blocking_structure_checked(
			ctx,
			result,
			entry["cell"],
			entry["size"],
			entry["asset"],
			true,
			entry["label"]
		)
```

---

# 15. Defensive props

```gdscript
func _place_defenses(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var gate := result.gate_cell

	var placements := [
		{ "cell": gate + Vector2i(-6, -3), "asset": GothicCompoundAssets.PROPS["sandbag_h"], "size": Vector2i(3, 1), "blocks": true },
		{ "cell": gate + Vector2i(3, -3), "asset": GothicCompoundAssets.PROPS["sandbag_h"], "size": Vector2i(3, 1), "blocks": true },
		{ "cell": gate + Vector2i(-8, -6), "asset": GothicCompoundAssets.PROPS["spike_h"], "size": Vector2i(3, 1), "blocks": true },
		{ "cell": gate + Vector2i(5, -6), "asset": GothicCompoundAssets.PROPS["spike_h"], "size": Vector2i(3, 1), "blocks": true },
		{ "cell": Vector2i(rect.position.x + 3, rect.position.y + rect.size.y / 2), "asset": GothicCompoundAssets.PROPS["fence_long_h"], "size": Vector2i(4, 1), "blocks": true },
		{ "cell": Vector2i(rect.position.x + rect.size.x - 7, rect.position.y + rect.size.y / 2), "asset": GothicCompoundAssets.PROPS["fence_long_h"], "size": Vector2i(4, 1), "blocks": true },
	]

	for p in placements:
		_place_prop_checked(ctx, result, p["cell"], p["size"], p["asset"], p["blocks"])

func _place_prop_checked(ctx, result: GothicCompoundResult, pos: Vector2i, size: Vector2i, asset: String, blocks: bool) -> bool:
	if not _can_place_rect(ctx, result, pos, size, true):
		return false

	ctx.spawn_prop(pos, asset, blocks, size)

	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			var c := Vector2i(x, y)
			result.placed_props.append(c)
			if blocks:
				ctx.mark_blocked(c, true)

	return true
```

---

# 16. Exterior resources

```gdscript
func _place_exterior_resources(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var positions := [
		Vector2i(rect.position.x - 4, rect.position.y + rect.size.y / 2),
		Vector2i(rect.position.x + rect.size.x + 2, rect.position.y + rect.size.y / 2),
		Vector2i(rect.position.x + 4, rect.position.y + rect.size.y + 4),
	]

	var assets := [
		GothicCompoundAssets.RESOURCES["ruin_scrap"],
		GothicCompoundAssets.RESOURCES["blackwood"],
		GothicCompoundAssets.RESOURCES["ruin_scrap"],
	]

	for i in range(min(cfg.exterior_resource_count, positions.size())):
		var pos := positions[i]
		if not _in_map(ctx, pos):
			continue
		if ctx.is_blocked(pos):
			continue

		ctx.spawn_prop(pos, assets[i], false, Vector2i(2, 2))
		ctx.mark_walkable(pos, true)
		result.placed_resources.append(pos)
```

---

# 17. Scatter and decals last

This fixes the current ordering bug.

```gdscript
func _place_scatter_and_decals(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var outer := rect.grow(cfg.outer_margin_fill)

	for y in range(outer.position.y, outer.position.y + outer.size.y):
		for x in range(outer.position.x, outer.position.x + outer.size.x):
			var c := Vector2i(x, y)

			if not _in_map(ctx, c):
				continue
			if result.required_walkable.has(c):
				continue
			if ctx.is_blocked(c):
				continue

			var inside := rect.has_point(c)
			var chance := cfg.decorative_scatter_chance if inside else cfg.exterior_scatter_chance

			if rng.randf() > chance:
				continue

			if inside:
				_place_inside_decal(ctx, c)
			else:
				_place_exterior_scatter(ctx, result, c)

func _place_inside_decal(ctx, cell: Vector2i) -> void:
	var roll := rng.randf()

	if roll < 0.35:
		ctx.set_decal(cell, GothicCompoundAssets.DECALS["grate_square"])
	elif roll < 0.55:
		ctx.set_decal(cell, GothicCompoundAssets.DECALS["grate_round"])
	elif roll < 0.70:
		ctx.set_decal(cell, GothicCompoundAssets.DECALS["floor_sigil"])
	elif roll < 0.85:
		ctx.set_decal(cell, GothicCompoundAssets.DECALS["light_pool"])
	else:
		ctx.set_decal(cell, GothicCompoundAssets.DECALS["shadow"])

func _place_exterior_scatter(ctx, result: GothicCompoundResult, cell: Vector2i) -> void:
	var roll := rng.randf()
	var asset := GothicCompoundAssets.PROPS["rubble_s"]
	var size := Vector2i(1, 1)
	var blocks := false

	if roll < 0.22:
		asset = GothicCompoundAssets.PROPS["rubble_s"]
	elif roll < 0.40:
		asset = GothicCompoundAssets.PROPS["rubble_m"]
		size = Vector2i(2, 2)
	elif roll < 0.52:
		asset = GothicCompoundAssets.PROPS["dead_shrub"]
	elif roll < 0.62:
		asset = GothicCompoundAssets.PROPS["dead_tree"]
		size = Vector2i(3, 3)
		blocks = true
	elif roll < 0.72:
		asset = GothicCompoundAssets.PROPS["collapsed_spire"]
		size = Vector2i(3, 3)
		blocks = true
	else:
		asset = GothicCompoundAssets.PROPS["banner"]
		blocks = true

	_place_prop_checked(ctx, result, cell, size, asset, blocks)
```

---

# 18. Spawn markers

```gdscript
func _place_spawn_markers(ctx, result: GothicCompoundResult, rect: Rect2i) -> void:
	var marker_cells := [
		Vector2i(result.gate_cell.x, result.gate_cell.y + 8),
		Vector2i(rect.position.x - 5, rect.position.y + rect.size.y / 2),
		Vector2i(rect.position.x + rect.size.x + 4, rect.position.y + rect.size.y / 2),
		Vector2i(rect.position.x + rect.size.x / 2, rect.position.y - 5),
	]

	var marker_assets := [
		GothicCompoundAssets.MARKERS["spawn_plain"],
		GothicCompoundAssets.MARKERS["spawn_amber"],
		GothicCompoundAssets.MARKERS["spawn_stone"],
		GothicCompoundAssets.MARKERS["spawn_ember"],
	]

	for i in range(min(cfg.enemy_marker_count, marker_cells.size())):
		var c := marker_cells[i]
		if not _in_map(ctx, c):
			continue
		if ctx.is_blocked(c):
			continue

		ctx.spawn_marker(c, marker_assets[i], "enemy_spawn")
		result.placed_markers.append(c)
```

---

# 19. Validator

## `gothic_compound_validator.gd`

```gdscript
extends RefCounted
class_name GothicCompoundValidator

static func validate(ctx, result: GothicCompoundResult) -> bool:
	result.errors.clear()

	_require(result.rect.size != Vector2i.ZERO, result, "No compound rect.")
	_require(result.gate_cell != Vector2i.ZERO, result, "No gate cell.")
	_require(result.command_keep_cell != Vector2i.ZERO, result, "No command keep cell.")
	_require(result.terminal_cell != Vector2i.ZERO, result, "No terminal cell.")
	_require(result.placed_walls.size() >= 20, result, "Too few wall cells.")
	_require(result.approach_path.size() >= 4, result, "No approach path.")
	_require(result.internal_path.size() >= 4, result, "No internal path.")
	_require(result.placed_resources.size() >= 1, result, "No resource nodes.")

	if result.errors.size() > 0:
		return false

	_validate_required_walkable(ctx, result)
	_validate_gate_passage(ctx, result)
	_validate_path(ctx, result, result.approach_path, "approach")
	_validate_path(ctx, result, result.internal_path, "internal")

	return result.errors.is_empty()

static func _require(condition: bool, result: GothicCompoundResult, message: String) -> void:
	if not condition:
		result.errors.append(message)

static func _validate_required_walkable(ctx, result: GothicCompoundResult) -> void:
	for c in result.required_walkable.keys():
		if ctx.is_blocked(c):
			result.errors.append("Required path cell is blocked: " + str(c))

static func _validate_gate_passage(ctx, result: GothicCompoundResult) -> void:
	if ctx.is_blocked(result.gate_cell):
		result.errors.append("Gate cell is blocked: " + str(result.gate_cell))
	if not ctx.is_walkable(result.gate_cell):
		result.errors.append("Gate cell is not walkable: " + str(result.gate_cell))

static func _validate_path(ctx, result: GothicCompoundResult, path: Array[Vector2i], label: String) -> void:
	for c in path:
		if ctx.is_blocked(c):
			result.errors.append("%s path blocked at %s" % [label, str(c)])
			return
		if not ctx.is_walkable(c):
			result.errors.append("%s path not walkable at %s" % [label, str(c)])
			return
```

This catches the exact problems visible in the screenshot: missing perimeter, blocked gate, non-continuous route, structures blocking roads, and no guaranteed compound form.

---

# 20. Optional: hard fallback blueprint

If you want the guarantee to be absolute, add a deterministic fallback that ignores candidate placement and always draws the same 34×26 layout.

```gdscript
func _generate_fallback_blueprint(ctx) -> GothicCompoundResult:
	var rect := _fallback_rect(ctx)
	var result := GothicCompoundResult.new()
	result.rect = rect
	result.used_fallback = true

	_reserve_and_clear(ctx, rect)
	_fill_base_terrain(ctx, rect)
	_build_perimeter(ctx, result, rect)
	_place_gate(ctx, result, rect)
	_carve_approach_road(ctx, result)
	_carve_internal_road(ctx, result, rect)
	_place_required_structures(ctx, result, rect)

	# Fixed utility placements.
	_place_blocking_structure_checked(
		ctx,
		result,
		Vector2i(rect.position.x + 5, rect.position.y + 12),
		Vector2i(5, 5),
		GothicCompoundAssets.STRUCTURES["utility_fan"],
		true,
		"fallback_utility_fan"
	)

	_place_blocking_structure_checked(
		ctx,
		result,
		Vector2i(rect.position.x + rect.size.x - 10, rect.position.y + 12),
		Vector2i(5, 5),
		GothicCompoundAssets.STRUCTURES["machine_house"],
		true,
		"fallback_machine_house"
	)

	_place_defenses(ctx, result, rect)
	_place_exterior_resources(ctx, result, rect)
	_place_spawn_markers(ctx, result, rect)

	result.ok = GothicCompoundValidator.validate(ctx, result)
	return result
```

---

# 21. Adapter example for a Node2D sprite-based prototype

If your current implementation is not using a proper TileSet yet and is just spawning sprites, Codex can still fix the layout by using a layer adapter like this.

```gdscript
extends Node2D
class_name GothicCompoundSpriteMapContext

@export var tile_size: int = 32
@export var map_size: Vector2i = Vector2i(80, 60)
@export var world_seed: int = 12345

@onready var terrain_layer := $TerrainLayer
@onready var road_layer := $RoadLayer
@onready var wall_layer := $WallLayer
@onready var prop_layer := $PropLayer
@onready var decal_layer := $DecalLayer
@onready var marker_layer := $MarkerLayer

var blocked := {}
var reserved := {}
var walkable := {}

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * tile_size, cell.y * tile_size)

func clear_cell(cell: Vector2i) -> void:
	blocked.erase(cell)
	walkable.erase(cell)

func reserve_cell(cell: Vector2i) -> void:
	reserved[cell] = true

func is_reserved(cell: Vector2i) -> bool:
	return reserved.has(cell)

func is_blocked(cell: Vector2i) -> bool:
	return blocked.get(cell, false)

func mark_blocked(cell: Vector2i, value: bool = true) -> void:
	blocked[cell] = value

func mark_walkable(cell: Vector2i, value: bool = true) -> void:
	walkable[cell] = value

func is_walkable(cell: Vector2i) -> bool:
	return walkable.get(cell, false)

func set_floor(cell: Vector2i, asset_path: String) -> void:
	_spawn_sprite(terrain_layer, cell, asset_path)

func set_road(cell: Vector2i, asset_path: String) -> void:
	_spawn_sprite(road_layer, cell, asset_path)

func set_wall(cell: Vector2i, asset_path: String, blocks: bool = true) -> void:
	_spawn_sprite(wall_layer, cell, asset_path)
	if blocks:
		mark_blocked(cell, true)

func set_decal(cell: Vector2i, asset_path: String) -> void:
	_spawn_sprite(decal_layer, cell, asset_path)

func spawn_prop(cell: Vector2i, asset_path: String, blocks: bool = false, size: Vector2i = Vector2i.ONE) -> void:
	_spawn_sprite(prop_layer, cell, asset_path)

	if blocks:
		for y in range(cell.y, cell.y + size.y):
			for x in range(cell.x, cell.x + size.x):
				mark_blocked(Vector2i(x, y), true)

func spawn_marker(cell: Vector2i, asset_path: String, marker_type: String) -> void:
	var s := _spawn_sprite(marker_layer, cell, asset_path)
	s.visible = false
	s.set_meta("marker_type", marker_type)

func _spawn_sprite(parent: Node, cell: Vector2i, asset_path: String) -> Sprite2D:
	var tex := load(asset_path)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = grid_to_world(cell)
	sprite.centered = false
	parent.add_child(sprite)
	return sprite
```

This will still be less efficient than a TileMap, but it will immediately fix the visible layout grammar.

---

# 22. Better adapter for TileMapLayer / TileSet workflow

The proper long-term solution is TileMap/TileSet source IDs, not one Sprite2D per tile. If Codex sees an existing `TileMap`/`TileMapLayer`, it should implement a mapping table like:

```gdscript
const TILE_ATLAS := {
	"terrain_ash_a": Vector2i(0, 0),
	"terrain_ash_b": Vector2i(1, 0),
	"terrain_stone_a": Vector2i(0, 2),
	"road_ns": Vector2i(0, 5),
	"road_ew": Vector2i(1, 5),
	"road_cross": Vector2i(2, 5),
	"wall_h": Vector2i(0, 8),
	"wall_v": Vector2i(1, 8),
	"wall_corner": Vector2i(2, 8),
}
```

Then:

```gdscript
func set_floor(cell: Vector2i, key: String) -> void:
	base_terrain_layer.set_cell(cell, GOTHIC_SOURCE_ID, TILE_ATLAS[key])

func set_road(cell: Vector2i, key: String) -> void:
	road_layer.set_cell(cell, GOTHIC_SOURCE_ID, TILE_ATLAS[key])
```

But given your current assets are separate PNG slices, the Sprite2D adapter may be faster for prototype validation. After the layout is fixed, convert the repetitive 32×32 terrain/road pieces to TileMap.

---

# 23. Test script Codex can add

Create:

```text
custodian/game/world/procgen/gothic_compound/test_gothic_compound_generation.gd
```

Example:

```gdscript
extends Node

const GothicCompoundConfig = preload("res://game/world/procgen/gothic_compound/gothic_compound_config.gd")
const GothicCompoundGenerator = preload("res://game/world/procgen/gothic_compound/gothic_compound_generator.gd")
const GothicCompoundValidator = preload("res://game/world/procgen/gothic_compound/gothic_compound_validator.gd")

func _ready() -> void:
	var ctx := GothicCompoundSpriteMapContext.new()
	ctx.map_size = Vector2i(80, 60)
	ctx.world_seed = 12345
	add_child(ctx)

	var cfg := GothicCompoundConfig.new()
	var gen := GothicCompoundGenerator.new(cfg)
	var result := gen.generate(ctx)

	if not result.ok:
		push_error("Gothic compound generation failed: " + str(result.errors))
	else:
		print("Gothic compound OK.")
		print("Rect: ", result.rect)
		print("Gate: ", result.gate_cell)
		print("Keep: ", result.command_keep_cell)
		print("Fallback: ", result.used_fallback)
```

For actual project validation, Codex should also run the Godot project if feasible, consistent with your repo validation guidance.

---

# 24. Debug visualization

Add a temporary debug draw overlay to see whether path/collision data is correct.

```gdscript
extends Node2D
class_name ProcgenDebugOverlay

var blocked_cells: Dictionary = {}
var required_path_cells: Dictionary = {}
var tile_size: int = 32

func _draw() -> void:
	for c in blocked_cells.keys():
		draw_rect(
			Rect2(Vector2(c.x * tile_size, c.y * tile_size), Vector2(tile_size, tile_size)),
			Color(1, 0, 0, 0.25),
			true
		)

	for c in required_path_cells.keys():
		draw_rect(
			Rect2(Vector2(c.x * tile_size, c.y * tile_size), Vector2(tile_size, tile_size)),
			Color(0, 1, 0, 0.25),
			true
		)

func refresh(blocked: Dictionary, required: Dictionary) -> void:
	blocked_cells = blocked
	required_path_cells = required
	queue_redraw()
```

Expected debug outcome:

```text
green path: map edge → gate → keep
red blocked cells: walls, towers, structures, heavy props
green should never overlap red
```

---

# 25. Exact fix list for the screenshot

Tell Codex to treat the screenshot as failing unless all of these are fixed:

```text
1. No isolated checkerboard terrain patches.
2. Compound interior has continuous terrain/floor fill.
3. Compound has a complete perimeter boundary.
4. Gate is clearly cut into perimeter.
5. Gate threshold is walkable.
6. Approach road reaches map edge.
7. Internal road reaches command keep.
8. Command keep does not overlap required road.
9. Terminal is inside compound and reachable.
10. Decorative scatter is placed after validation only.
```

---

# 26. Codex-ready full prompt

Paste this to Codex:

```markdown
Implement the gothic compound procgen fix.

Read AGENTS.md first. This is a Godot runtime change under `custodian/`, so create/update a design note first:
`design/features/implementation/GOTHIC_COMPOUND_PROCGEN.md`

Current bug:
The screenshot shows asset-stamping, not compound generation. Terrain patches are placed as isolated repeated squares, roads are decorative, walls do not form a perimeter, and large props overlap layout. Fix by making the generator constraint-first.

Available assets:
`custodian/content/procgen/special_rooms/gothic_compound/`

Use sliced PNGs in that folder. Treat master sheets as source only.

Create:
`custodian/game/world/procgen/gothic_compound/gothic_compound_assets.gd`
`custodian/game/world/procgen/gothic_compound/gothic_compound_config.gd`
`custodian/game/world/procgen/gothic_compound/gothic_compound_result.gd`
`custodian/game/world/procgen/gothic_compound/gothic_compound_generator.gd`
`custodian/game/world/procgen/gothic_compound/gothic_compound_validator.gd`

Core rule:
Do not place terrain as isolated prop sprites. Fill the whole compound rect and surrounding margin with continuous base terrain first. Then place roads, walls, structures, props, decals.

Generation order:

1. deterministic RNG from map/world seed
2. find candidate rect or fallback rect
3. reserve and clear rect
4. fill continuous terrain
5. build perimeter wall rectangle
6. cut south gate opening
7. place open gatehouse/threshold
8. carve road from south map edge to gate
9. carve internal road from gate to command keep
10. place command keep
11. place terminal
12. place utility structures
13. place defensive props
14. place exterior resources
15. place scatter/decals last
16. place hidden spawn markers
17. validate
18. retry or fallback if validation fails

Required validation:

- perimeter exists
- main gate exists
- gate is walkable
- command keep exists
- terminal exists
- road exists from map edge to gate
- road exists from gate to command keep
- no required path cell is blocked
- resources exist
- fallback blueprint works if random candidate fails

Use an occupancy map:

- blocked cells
- reserved cells
- walkable cells
- required path cells

Layer/collision rules:

- terrain, roads, platforms, decals: no collision
- walls, closed gates, towers, large structures, heavy barricades: collision
- open gate threshold: no collision
- markers: hidden/debug only

If current procgen is Sprite2D-based, add an adapter with:
set_floor, set_road, set_wall, set_decal, spawn_prop, spawn_marker, mark_blocked, mark_walkable, is_blocked, is_walkable.
If current procgen uses TileMap/TileMapLayer, wire these calls to the existing layers instead.

After implementation:

- update `custodian/docs/ai_context/CURRENT_STATE.md` if runtime architecture/paths changed
- update FILE_INDEX if present
- run `cd custodian && godot` if feasible
- summarize changed files and remaining assumptions
```

---

# 27. Documentation drift check Codex should perform

After implementing, Codex should check:

```text
Does CURRENT_STATE.md mention old procgen behavior?
Does FILE_INDEX.md mention the new gothic compound procgen files?
Does any doc claim terrain is sprite-scattered instead of TileMap/floor filled?
Does any doc still treat master sheets as runtime assets?
Does any doc omit the new special-room path?
```

Recommended doc update snippet:

```markdown
## Gothic Compound Procgen

A deterministic special-room generator now guarantees a gothic industrial compound per generated map. The generator reserves a compound rect, fills continuous terrain, builds a perimeter, cuts a south gate, carves required roads, places command keep/terminal/utility structures, then decorates with props/resources/markers. Required routes are validated before generation succeeds.

Runtime assets:
`custodian/content/procgen/special_rooms/gothic_compound/`

Runtime code:
`custodian/game/world/procgen/gothic_compound/`
```

The point is simple: **terrain fill and required topology must happen before decoration**. Once Codex implements that, your screenshot should stop looking like a collage of stamps and start reading as a generated fortified compound.

---

# 28. 2026-05-19 Layout Grammar Hardening

Status: implemented in Godot runtime.

The connected gothic compound generator now has a metadata-aware layout pass instead of treating every sliced PNG as an interchangeable one-cell stamp.

Runtime additions:

- `custodian/game/world/procgen/gothic_compound/gothic_compound_asset_defs.gd`
- `custodian/game/world/procgen/gothic_compound/gothic_compound_sprite_context.gd`
- `custodian/game/world/procgen/gothic_compound/gothic_compound_generator.gd`
- `custodian/game/world/procgen/gothic_compound/gothic_compound_result.gd`
- `custodian/game/world/procgen/gothic_compound/gothic_compound_validator.gd`

Implemented rules:

- Assets are addressed through logical metadata definitions with path, kind, grid footprint, anchor, blocking behavior, and z-index.
- `GothicCompoundSpriteContext` uses top-left sprite anchoring for metadata-aware placement and offsets collision rectangles from that anchor.
- Large and multi-tile assets are spawned as footprint-aware props; the long east-west road is placed in chunks instead of once per road cell.
- Interior terrain is now mostly calm stone base with deterministic macro patches rather than full per-cell high-frequency variation.
- Interior decals are quota/anchor based: light pools are placed near major focal points and small floor decals are capped.
- Generation records layout zones for perimeter, inner yard, keep pad, utility pads, gate killzone, and exterior ruin belt.
- Command keep and terminal placement set explicit flags and placement errors; optional utility structures no longer fail generation if a zone is crowded.
- The validator preserves generator placement errors, checks required flags, validates walkable required paths, and verifies perimeter topology with a walkable south gate gap.
- Sandbags and spikes are secondary gate/killzone cover, while the perimeter is wall-driven.

Remaining visual-tuning assumptions:

- Footprints are grid approximations based on current PNG sizes and screenshot diagnosis.
- A screenshot/playtest pass should still tune exact footprints for command keep, gatehouse, utility structures, and large exterior props.

---

# 29. 2026-05-19 Perimeter And Readability Pass

Status: implemented in Godot runtime.

This pass keeps the existing generator architecture and focuses only on composition discipline:

- The perimeter is wall/post/gatehouse dominant; sandbags remain secondary cover around the gate and defensive lanes.
- Horizontal wall runs now vary between base, alternate, damaged, broken, and pillar accents, with extra corner bastion posts to reduce the flat repeated-strip read.
- The south gate now has explicit side pillars, an open threshold lane, and flanking amber gate lamps.
- The command keep defines a `keep_plaza` exclusion zone in front of its entrance; random props, grates, rubble, fences, trees, smoke/light decals, and other filler are kept out of that zone.
- Interior floor decals are zone-specific rather than generic scatter: grates are anchored near terminal/utility zones and one sigil can mark the central yard.
- Exterior scatter is emitted as small cause-based clusters (`ruin`, `deadwood`, `funerary`, and `roadside`) while the approach road remains clear.

Deferred:

- Exact visual footprint tuning still needs live screenshot review.
- Main tactical TileMapLayer adapter integration remains a separate implementation slice.
