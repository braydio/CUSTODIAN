@tool
extends Node2D
class_name ReturnCausewayLayout


# ------------------------------------------------------------------------------
# Return Causeway production route node — Procedural Tilemap Builder
#
# Builds the longer bridge route from the Vista Approach to Sundered Keep as an
# authored
# vertical slice: Arrival Beach → Return Mooring → Broken Causeway →
# Shore Path / Buried Terminal → Intact Causeway → Gatehouse Threshold →
# Outer Keep Yard → Transition to Sundered Keep Main Map.
#
# Route topology is owned by RouteTraversalManager; this scene owns only local
# traversal geometry, presentation, encounters, state hooks, spawns, and exits.
# ------------------------------------------------------------------------------

# -- Constants ---------------------------------------------------------------

const TILE_SIZE := 32.0
const MAP_SIZE_TILES := Vector2i(96, 72)
const ELEVATION_STEP_PX := 24.0

# Asset catalog.
const SUNDERED_KEEP_ASSETS := preload("res://content/runtime/sundered_keep/sundered_keep_game32_assets.gd")
const SUNDERED_KEEP_INTERACTABLE := preload("res://game/world/sundered_keep/sundered_keep_interactable.gd")
const ELEVATION_MAP_SCRIPT := preload("res://game/world/elevation/elevation_map.gd")
const PARALLAX_RIG_SCRIPT := preload(
	"res://game/world/sundered_keep/presentation/sundered_keep_parallax_rig.gd"
)

# Music.
const MUSIC_PATH := "res://content/audio/music/return_causeway/return_causeway_01.ogg"

# -- Sector Anchor Tiles ------------------------------------------------------
# These define the key locations used throughout the level. All positions are
# in tile coordinates (32×32 px grid).

const ENTRANCE_TILE := Vector2i(45, 63)          # Player spawn
const RETURN_MOORING_ORIGIN := Vector2i(43, 56)  # 5×5 mooring pad origin
const BROKEN_GAP_CENTER := Vector2i(45, 46)      # Center of the broken bridge gap
const SHORE_STAIRS_BOTTOM := Vector2i(49, 49)    # Bottom of stairs from shore to causeway
const BURIED_TERMINAL_TILE := Vector2i(68, 46)   # Buried Terminal interaction
const GATEHOUSE_GATE_TILE := Vector2i(45, 24)    # Gatehouse portcullis
const TRANSITION_TILE := Vector2i(45, 9)          # Travel gate to Sundered Keep main map

# -- State --------------------------------------------------------------------

var _built := false
var _layers: Dictionary = {}
var _textures: Dictionary = {}
var _camera_bounds := Rect2()
var _elevation_map: Node = null
var _last_actor_elevation_tile := Vector2i(-9999, -9999)
var _stats := {
	"floors": 0, "edges": 0, "walls": 0, "props": 0,
	"blockers": 0, "interactables": 0, "missing_assets": 0,
}

var _buried_terminal_activated := false
var _gatehouse_unlocked := false
var _gatehouse_opened := false
var _return_mooring_created := false

# Node references.
var _return_mooring_interaction: Node2D = null
var _buried_terminal_interaction: Node2D = null
var _gatehouse_interaction: Node2D = null
var _gatehouse_closed_sprite: Sprite2D = null
var _gatehouse_blockers: Array[Node] = []
var _continue_exit: LevelExit2D = null
var _backtrack_exit: LevelExit2D = null
var _return_mooring_active_overlay: Sprite2D = null
var _buried_terminal_overlay: Sprite2D = null
var _music_player: AudioStreamPlayer2D = null
var _parallax_rig: SunderedKeepParallaxRig = null


# -- Lifecycle ----------------------------------------------------------------

func _ready() -> void:
	add_to_group("connected_map")
	add_to_group("return_causeway")
	_build_once()
	_obs_log(&"sundered_keep_flow_entered_return_causeway", {
		"entry_position": get_entry_position(),
		"camera_bounds": get_camera_bounds(),
		"flow_branch": "return_causeway",
	})
	set_process(true)


func _process(_delta: float) -> void:
	_update_actor_elevation()


func get_entry_position() -> Vector2:
	return to_global(_tile_center(ENTRANCE_TILE))


func get_camera_bounds() -> Rect2:
	return Rect2(to_global(_camera_bounds.position), _camera_bounds.size)


func get_elevation_map() -> Node:
	return _elevation_map


func get_elevation_at_tile(tile: Vector2i) -> int:
	if _elevation_map == null:
		return 0
	return int(_elevation_map.call("get_height", tile))


func can_traverse_elevation(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	if _elevation_map == null:
		return true
	return bool(_elevation_map.call("can_traverse", from_tile, to_tile))


func has_spawn(spawn_id: StringName) -> bool:
	return find_child(String(spawn_id), true, false) is Node2D


func get_spawn_position(spawn_id: StringName) -> Vector2:
	var marker := find_child(String(spawn_id), true, false) as Node2D
	return marker.global_position if marker != null else global_position


func activate_route_node(actor: Node, spawn_id: StringName) -> bool:
	if not (actor is Node2D) or not has_spawn(spawn_id):
		return false
	(actor as Node2D).global_position = get_spawn_position(spawn_id)
	_refresh_camera(self, actor)
	return true


func capture_route_state() -> Dictionary:
	return {
		"buried_terminal_activated": _buried_terminal_activated,
		"gatehouse_unlocked": _gatehouse_unlocked,
		"gatehouse_opened": _gatehouse_opened,
	}


func restore_route_state(state: Dictionary) -> bool:
	_buried_terminal_activated = bool(state.get("buried_terminal_activated", false))
	_gatehouse_unlocked = bool(state.get("gatehouse_unlocked", _buried_terminal_activated))
	_set_gatehouse_gate_open(bool(state.get("gatehouse_opened", false)))
	if _buried_terminal_overlay != null:
		_buried_terminal_overlay.visible = _buried_terminal_activated
	return true


func prepare_route_deactivation(_context: Dictionary) -> void:
	pass


func complete_route_activation(_context: Dictionary) -> bool:
	return true


func refresh_route_camera(actor: Node) -> bool:
	_refresh_camera(self, actor)
	return true


# -- Build Orchestrator -------------------------------------------------------

func _build_once() -> void:
	if _built:
		return
	_built = true

	_camera_bounds = Rect2(
		Vector2(-TILE_SIZE * 2.0, -TILE_SIZE * 2.0),
		Vector2(float(MAP_SIZE_TILES.x + 4) * TILE_SIZE, float(MAP_SIZE_TILES.y + 4) * TILE_SIZE)
	)

	_create_layers()
	_build_entry_affordance()
	_ensure_elevation_map()
	_build_parallax_backdrop()
	_build_ocean_backdrop()
	_build_arrival_beach()
	_build_return_mooring()
	_build_broken_causeway()
	_build_causeway_underbridge()
	_build_shore_path()
	_build_buried_terminal()
	_build_shore_stairs_up()
	_build_intact_causeway()
	_build_gatehouse_threshold()
	_build_outer_keep_yard()
	_build_ocean_boundaries()
	_build_gatehouse_gate()
	_add_travel_gate()
	_setup_music()

	_debug_print_summary()


func _create_layers() -> void:
	var z_by_name := {
		"TerrainBase": -90,
		"TerrainEdges": -75,
		"FloorDetail": -60,
		"WallsLow": -35,
		"WallsHigh": -15,
		"PropsStatic": -5,
		"PropsBlocking": 5,
		"Traversal": 8,
		"Hazards": 10,
		"Overlays": 15,
		"Effects": 25,
		"WorldUI": 45,
		"Collision": 0,
	}
	for name in z_by_name.keys():
		var layer := Node2D.new()
		layer.name = name
		layer.z_as_relative = false
		layer.z_index = z_by_name[name]
		add_child(layer)
		_layers[name] = layer


func _build_entry_affordance() -> void:
	var world_ui := _layers.get("WorldUI") as Node2D
	if world_ui == null:
		return
	var title := Label.new()
	title.name = "ReturnCausewayEntryAffordance"
	title.text = "RETURN CAUSEWAY\nRE-ESTABLISHING KEEP APPROACH"
	title.position = _tile_center(ENTRANCE_TILE) + Vector2(-240.0, -122.0)
	title.size = Vector2(480.0, 72.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.84, 0.92, 0.96, 0.96))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	world_ui.add_child(title)


func _obs_log(kind: StringName, data: Dictionary = {}) -> void:
	if Engine.is_editor_hint() or get_tree() == null:
		return
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", kind, data)


# -- Sector Builders -----------------------------------------------------------

func _build_parallax_backdrop() -> void:
	var existing := get_node_or_null("ParallaxRoot")
	if existing != null:
		remove_child(existing)
		existing.free()

	_parallax_rig = (
		PARALLAX_RIG_SCRIPT.new()
		as SunderedKeepParallaxRig
	)
	_parallax_rig.name = "ParallaxRoot"
	add_child(_parallax_rig)

	var map_pixel_size := Vector2(
		float(MAP_SIZE_TILES.x) * TILE_SIZE,
		float(MAP_SIZE_TILES.y) * TILE_SIZE
	)
	_parallax_rig.build(
		SunderedKeepParallaxRig.Profile.RETURN_CAUSEWAY,
		Rect2(Vector2.ZERO, map_pixel_size)
	)
	_stats["missing_assets"] = (
		int(_stats["missing_assets"])
		+ _parallax_rig.get_missing_asset_count()
	)


func _build_ocean_backdrop() -> void:
	# Full-map dark ocean backdrop.
	var backdrop := ColorRect.new()
	backdrop.name = "StormOceanBackdrop"
	backdrop.color = Color(0.014, 0.035, 0.064, 1.0)
	backdrop.size = Vector2(float(MAP_SIZE_TILES.x) * TILE_SIZE, float(MAP_SIZE_TILES.y) * TILE_SIZE)
	backdrop.z_as_relative = false
	backdrop.z_index = -130
	add_child(backdrop)

	# Scatter dark water tiles across the ocean void.
	for y in range(MAP_SIZE_TILES.y):
		for x in range(MAP_SIZE_TILES.x):
			if ((x * 17 + y * 31) % 41) == 0:
				_add_tile("TerrainBase", "ocean_dark_water_01", "cliffs", Vector2i(x, y))

	# Ocean void holes define landmass shape.
	var void_rects := [
		# West ocean void.
		Rect2i(Vector2i(0, 0), Vector2i(35, MAP_SIZE_TILES.y)),
		# East ocean void.
		Rect2i(Vector2i(76, 0), Vector2i(20, MAP_SIZE_TILES.y)),
	]
	for rect in void_rects:
		_add_ocean_hole(rect, "OceanVoid_%s_%s" % [rect.position.x, rect.position.y])


func _build_arrival_beach() -> void:
	# Rocky beach at the south end where the player arrives.
	var beach_rect := Rect2i(Vector2i(36, 58), Vector2i(22, 8))
	_fill_rect(beach_rect, "cliff_rock_floor_01")
	_scatter_variants(beach_rect, {"cliff_rock_floor_cracked_01": 4})

	# Cliff edge to the north (transition to return mooring plateau).
	for x in range(38, 56):
		_add_tile("TerrainEdges", "cliff_edge_n", "cliffs", Vector2i(x, 57))

	# Props.
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(38, 64))
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(52, 62))
	_add_prop("PropsStatic", "prop_broken_spire_chunk_01", Vector2i(46, 65))

	# Blocker: south ocean boundary.
	_add_blocker(Rect2i(Vector2i(36, 66), Vector2i(22, 2)), "BeachSouthBoundary")


func _build_return_mooring() -> void:
	_return_mooring_created = true

	# Mooring pad (elevated from beach).
	var pad_rect := Rect2i(Vector2i(38, 51), Vector2i(22, 6))
	_fill_rect(pad_rect, "main_gate_threshold_stone_01")

	# Cliff edge transition from beach up to mooring.
	for x in range(38, 60):
		_add_tile("TerrainEdges", "cliff_edge_n", "cliffs", Vector2i(x, 57))

	# Barricade walls flanking the path.
	_add_wall_run(Rect2i(RETURN_MOORING_ORIGIN + Vector2i(0, 0), Vector2i(5, 1)), "rampart_parapet_s")
	_add_wall_run(Rect2i(RETURN_MOORING_ORIGIN + Vector2i(0, 0), Vector2i(1, 5)), "rampart_parapet_e")
	_add_wall_run(Rect2i(RETURN_MOORING_ORIGIN + Vector2i(4, 0), Vector2i(1, 3)), "rampart_parapet_w")

	# 3×3 mooring ring.
	var layout := [
		["return_mooring_floor_corner_nw", "return_mooring_floor_ring_n", "return_mooring_floor_corner_ne"],
		["return_mooring_floor_ring_w", "return_mooring_floor_center_01", "return_mooring_floor_ring_e"],
		["return_mooring_floor_corner_sw", "return_mooring_floor_ring_s", "return_mooring_floor_corner_se"],
	]
	for row in range(3):
		for col in range(3):
			_add_tile("FloorDetail", str(layout[row][col]), "return_mooring_floor",
				RETURN_MOORING_ORIGIN + Vector2i(col + 1, row + 1))

	var center_tile := RETURN_MOORING_ORIGIN + Vector2i(2, 2)
	_add_tile("Overlays", "return_mooring_glow_overlay_01", "return_mooring_overlay", center_tile)
	_return_mooring_active_overlay = _add_tile("Effects", "return_mooring_active_overlay_01",
		"return_mooring_overlay", center_tile)
	_add_tile("WorldUI", "return_mooring_prompt_marker_01", "return_mooring_overlay", center_tile)

	# Mooring props.
	_add_prop("PropsBlocking", "prop_return_beacon_01", RETURN_MOORING_ORIGIN + Vector2i(2, 1))
	_add_prop("PropsBlocking", "prop_return_console_ruined_01", RETURN_MOORING_ORIGIN + Vector2i(4, 3))

	_add_blocker(Rect2i(RETURN_MOORING_ORIGIN + Vector2i(2, 1), Vector2i.ONE), "ReturnMooringBeaconBlocker")
	_add_blocker(Rect2i(RETURN_MOORING_ORIGIN + Vector2i(4, 3), Vector2i(2, 1)), "ReturnMooringConsoleBlocker")

	# Interaction.
	_return_mooring_interaction = _add_interactable(
		"ReturnMooringInteraction", &"return_mooring",
		"ACTIVATE RETURN MOORING", center_tile, 72.0
	)

	# Path from mooring north toward causeway.
	var path_rect := Rect2i(Vector2i(41, 50), Vector2i(6, 2))
	_fill_rect(path_rect, "entrance_causeway_floor_01")
	_scatter_variants(path_rect, {"entrance_causeway_floor_cracked_01": 4})


func _build_broken_causeway() -> void:
	# Bridge deck from mooring area up to the gap.
	var bridge_deck := Rect2i(Vector2i(40, 40), Vector2i(10, 8))
	_fill_rect(bridge_deck, "entrance_causeway_floor_01")
	_scatter_variants(bridge_deck, {"entrance_causeway_floor_cracked_01": 5})

	# The broken gap — 3-tile wide gap at y=45-46.
	var gap_rect := Rect2i(Vector2i(42, 45), Vector2i(6, 2))
	_fill_rect(gap_rect, "ocean_void_01")
	_add_blocker(gap_rect, "CausewayGapBlocker")

	# Decorative gap edges.
	for x in range(42, 48):
		_add_tile("FloorDetail", "entrance_causeway_broken_gap_01", "entrance", Vector2i(x, 45))
	for x in range(42, 48):
		_add_tile("FloorDetail", "entrance_causeway_broken_gap_01", "entrance", Vector2i(x, 46))

	# Gap edge tiles on north/south edges of gap.
	for x in range(42, 48):
		_add_tile("FloorDetail", "entrance_causeway_broken_gap_edge_w", "entrance", Vector2i(x, 44))
		_add_tile("FloorDetail", "entrance_causeway_broken_gap_edge_e", "entrance", Vector2i(x, 47))

	# Approach warning: broken masonry at gap edge.
	_add_prop("PropsBlocking", "prop_broken_spire_chunk_01", Vector2i(41, 45))
	_add_prop("PropsBlocking", "prop_broken_spire_chunk_01", Vector2i(48, 46))

	# Cliff edges on both sides (prevent falling into ocean).
	for y in range(40, 52):
		_add_tile("TerrainEdges", "cliff_edge_w", "cliffs", Vector2i(39, y))
		_add_tile("TerrainEdges", "cliff_edge_e", "cliffs", Vector2i(51, y))

	# Blockers for cliff edges.
	_add_blocker(Rect2i(Vector2i(39, 40), Vector2i(1, 12)), "CausewayWestCliff")
	_add_blocker(Rect2i(Vector2i(51, 40), Vector2i(1, 12)), "CausewayEastCliff")


func _build_causeway_underbridge() -> void:
	# Space under the elevated causeway deck at height 0.
	# This is the walkable path connecting beach to shore path.
	var under_rect := Rect2i(Vector2i(40, 43), Vector2i(10, 10))
	_fill_rect(under_rect, "cliff_rock_floor_cracked_01")

	# IMPORTANT:
	# Do not place a full StaticBody2D over this rect.
	# The old UnderbridgeBlocker made the visible walk path behave like collision.
	# If supports are needed later, add small support blockers that do not cover
	# the route corridor.


func _build_shore_path() -> void:
	# Shore path east from the broken causeway area.
	# Runs along the base of the cliff at height 0.
	var shore_rect := Rect2i(Vector2i(52, 40), Vector2i(24, 12))
	_fill_rect(shore_rect, "cliff_rock_floor_cracked_01")
	_scatter_variants(shore_rect, {"cliff_rock_floor_01": 6})

	# North cliff wall (the island cliff face).
	for y in range(40, 46):
		_add_tile("TerrainEdges", "cliff_edge_s", "cliffs", Vector2i(52, y))
		for x in range(53, 76):
			_add_tile("TerrainEdges", "cliff_edge_s", "cliffs", Vector2i(x, y))

	# South ocean edge.
	for x in range(52, 76):
		_add_tile("TerrainEdges", "cliff_edge_n", "cliffs", Vector2i(x, 51))

	# Ocean south of shore path.
	_add_blocker(Rect2i(Vector2i(52, 52), Vector2i(24, 4)), "ShorePathSouthOcean")

	# West edge (transition from underbridge).
	_add_tile("TerrainEdges", "cliff_edge_w", "cliffs", Vector2i(51, 40))
	_add_tile("TerrainEdges", "cliff_edge_w", "cliffs", Vector2i(51, 41))

	# East ocean boundary at shore path end.
	for y in range(40, 52):
		_add_tile("TerrainEdges", "cliff_edge_e", "cliffs", Vector2i(76, y))

	# Props along shore.
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(55, 44))
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(62, 47))
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(70, 43))
	_add_prop("PropsStatic", "prop_broken_spire_chunk_01", Vector2i(58, 48))
	_add_prop("PropsStatic", "prop_crate_stack_wet_01", Vector2i(74, 44))

	# East cliff edge.
	_add_blocker(Rect2i(Vector2i(76, 40), Vector2i(2, 12)), "ShorePathEastOcean")


func _build_buried_terminal() -> void:
	# Semi-buried structure at the base of the cliff on the shore path.
	var terminal_rect := Rect2i(Vector2i(64, 42), Vector2i(10, 7))
	_fill_rect(terminal_rect, "great_hall_marble_floor_01")  # Material shift indoors

	# Walls — buried structure uses stone wall faces.
	for y in range(42, 49):
		_add_wall_tile(Vector2i(64, y), "causeway_keep_wall_face_plain_01")
	for y in range(42, 49):
		_add_wall_tile(Vector2i(73, y), "causeway_keep_wall_face_plain_01")

	# North interior wall (back of structure).
	for x in range(65, 73):
		_add_wall_tile(Vector2i(x, 42), "causeway_keep_wall_face_plain_01")

	# Entrance is open to the south (south edge of rect is open).
	for x in range(65, 73):
		_add_tile("FloorDetail", "dungeon_stone_floor_01", "floors", Vector2i(x, 49))

	# The terminal console.
	_add_prop("PropsBlocking", "prop_return_console_ruined_01", Vector2i(69, 45))

	# Overlay glow (hidden until activated).
	_buried_terminal_overlay = _add_tile("Effects", "return_mooring_active_overlay_01",
		"return_mooring_overlay", Vector2i(69, 44))
	if _buried_terminal_overlay != null:
		_buried_terminal_overlay.visible = false

	# Interaction.
	_buried_terminal_interaction = _add_interactable(
		"BuriedTerminalInteraction", &"buried_terminal",
		"IMPRINT CUSTODIAN IDENTITY", Vector2i(69, 46), 72.0
	)


func _build_shore_stairs_up() -> void:
	# Stairs from shore path up to the intact causeway deck.
	var stairs_rect := Rect2i(Vector2i(49, 43), Vector2i(3, 6))
	_fill_rect(stairs_rect, "cobblestone_stairs_vertical_01")
	_add_sprite("Traversal", "cobblestone_stairs_center_01", "stairs", Vector2i(50, 44), Vector2.ZERO)
	_add_sprite("Traversal", "cobblestone_stairs_center_01", "stairs", Vector2i(50, 45), Vector2.ZERO)
	_add_sprite("Traversal", "cobblestone_stairs_center_01", "stairs", Vector2i(50, 46), Vector2.ZERO)


func _build_intact_causeway() -> void:
	# The main intact causeway section — walled, exposed to ocean.
	var deck_rect := Rect2i(Vector2i(40, 30), Vector2i(10, 10))
	_fill_rect(deck_rect, "entrance_causeway_floor_01")
	_scatter_variants(deck_rect, {"entrance_causeway_floor_cracked_01": 5})

	# Cliff edges (west and east) — visual drop-off into ocean.
	for y in range(30, 42):
		_add_tile("TerrainEdges", "cliff_edge_w", "cliffs", Vector2i(39, y))
		_add_tile("TerrainEdges", "cliff_edge_e", "cliffs", Vector2i(51, y))

	# West and east cliff blockers prevent falling off.
	_add_blocker(Rect2i(Vector2i(39, 30), Vector2i(1, 12)), "IntactCausewayWestCliff")
	_add_blocker(Rect2i(Vector2i(51, 30), Vector2i(1, 12)), "IntactCausewayEastCliff")

	# Props.
	_add_prop("PropsStatic", "causeway_lit_brazier_bowl_01", Vector2i(42, 33))
	_add_prop("PropsStatic", "causeway_lit_brazier_bowl_01", Vector2i(48, 33))
	_add_prop("PropsStatic", "causeway_lit_brazier_bowl_01", Vector2i(42, 37))
	_add_prop("PropsStatic", "causeway_lit_brazier_bowl_01", Vector2i(48, 37))

	# Ocean foam edges along the causeway.
	for y in range(30, 42):
		_add_tile("TerrainEdges", "ocean_foam_edge_w", "cliffs", Vector2i(38, y))
		_add_tile("TerrainEdges", "ocean_foam_edge_e", "cliffs", Vector2i(52, y))


func _build_gatehouse_threshold() -> void:
	# Gatehouse area — fortified approach before the portcullis.
	var threshold_rect := Rect2i(Vector2i(35, 20), Vector2i(20, 10))
	_fill_rect(threshold_rect, "main_gate_threshold_stone_01")

	# Gatehouse walls flanking the approach.
	var wall_west_start := Vector2i(35, 22)
	var wall_east_start := Vector2i(55, 22)

	# West gatehouse wall.
	_add_wall_run(Rect2i(wall_west_start, Vector2i(1, 8)), "gothic_castle_wall_straight_e")
	# East gatehouse wall.
	_add_wall_run(Rect2i(wall_east_start, Vector2i(1, 8)), "gothic_castle_wall_straight_w")

	# North wall with gate opening.
	for x in range(35, 40):
		_add_wall_tile(Vector2i(x, 20), "gothic_castle_wall_straight_s")
	for x in range(51, 55):
		_add_wall_tile(Vector2i(x, 20), "gothic_castle_wall_straight_s")

	# Gate opening (x=40 to x=50) is the portcullis area.

	# Floor detail transition.
	var inner_rect := Rect2i(Vector2i(38, 22), Vector2i(14, 6))
	_scatter_variants(inner_rect, {"cobblestone_floor_01": 3})

	# Props — torches flanking the gate.
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(40, 22))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(50, 22))

	# Chains.
	_add_prop("PropsStatic", "causeway_large_chain_vertical_01", Vector2i(42, 20))
	_add_prop("PropsStatic", "causeway_large_chain_vertical_01", Vector2i(48, 20))

	# Fallen masonry debris.
	_add_prop("PropsBlocking", "prop_broken_spire_chunk_01", Vector2i(37, 26))
	_add_prop("PropsBlocking", "prop_broken_spire_chunk_01", Vector2i(53, 24))

	# Transition from causeway to threshold (south edge).
	for x in range(37, 54):
		_add_tile("TerrainEdges", "cliff_edge_n", "cliffs", Vector2i(x, 30))


func _build_outer_keep_yard() -> void:
	# Small walled yard before the keep entrance.
	var yard_rect := Rect2i(Vector2i(37, 9), Vector2i(16, 9))
	_fill_rect(yard_rect, "main_courtyard_flagstone_01")
	_scatter_variants(yard_rect, {
		"main_courtyard_flagstone_cracked_01": 6,
		"main_courtyard_flagstone_mossy_01": 10,
	})

	# Keep walls.
	for x in range(37, 44):
		_add_wall_tile(Vector2i(x, 10), "gothic_castle_wall_straight_s")
	for x in range(47, 53):
		_add_wall_tile(Vector2i(x, 10), "gothic_castle_wall_straight_s")

	# Gate opening at x=44-46 (for the transition travel gate).
	# Side walls.
	_add_wall_run(Rect2i(Vector2i(37, 11), Vector2i(1, 6)), "rampart_parapet_e")
	_add_wall_run(Rect2i(Vector2i(53, 11), Vector2i(1, 6)), "rampart_parapet_w")

	# South wall (transition from gatehouse).
	for x in range(37, 53):
		_add_wall_tile(Vector2i(x, 18), "gothic_castle_wall_straight_n")

	# Props.
	_add_prop("PropsBlocking", "prop_gothic_statue_broken_01", Vector2i(40, 13))
	_add_prop("PropsBlocking", "prop_crate_stack_wet_01", Vector2i(50, 15))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(39, 11))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(51, 11))


func _build_ocean_boundaries() -> void:
	# Outer ocean boundaries preventing the player from leaving the map.
	_add_blocker(Rect2i(Vector2i(0, 0), Vector2i(MAP_SIZE_TILES.x, 4)), "NorthOceanBoundary")
	_add_blocker(Rect2i(Vector2i(0, 0), Vector2i(34, MAP_SIZE_TILES.y)), "WestOceanBoundary")
	_add_blocker(Rect2i(Vector2i(78, 0), Vector2i(18, MAP_SIZE_TILES.y)), "EastOceanBoundary")
	_add_blocker(Rect2i(Vector2i(0, 68), Vector2i(MAP_SIZE_TILES.x, 4)), "SouthOceanBoundary")


func _build_gatehouse_gate() -> void:
	# The locked portcullis at the gatehouse threshold.
	var prefab_tile := GATEHOUSE_GATE_TILE

	# Closed gate sprite.
	_gatehouse_closed_sprite = _add_sprite("WallsHigh", "gateway_prefab_structure",
		"entrance_prefabs", prefab_tile, Vector2.ZERO)

	# Gate blockers — solid collision until unlocked.
	_gatehouse_blockers.append(_add_blocker(
		Rect2i(GATEHOUSE_GATE_TILE + Vector2i(-1, 0), Vector2i(6, 2)),
		"GatehouseGateBlocker"
	))

	# Custodian state panel beside the gate (non-interactable initially).
	var panel_tile := GATEHOUSE_GATE_TILE + Vector2i(4, 1)
	_add_prop("PropsStatic", "prop_return_console_ruined_01", panel_tile)

	# Interaction point — changes prompt based on state.
	_gatehouse_interaction = _add_interactable(
		"GatehouseGateInteraction", &"gatehouse_gate",
		"OPEN GATEHOUSE GATE", GATEHOUSE_GATE_TILE + Vector2i(2, 1), 96.0
	)

	# Set initial state.
	_set_gatehouse_gate_open(false)


# -- Travel Gate ---------------------------------------------------------------

func _add_travel_gate() -> void:
	var keep_return_spawn := find_child("KeepReturnSpawn", true, false) as Marker2D
	if keep_return_spawn == null:
		push_error("[ReturnCauseway] Missing authored KeepReturnSpawn")
	else:
		keep_return_spawn.position = _tile_center(TRANSITION_TILE + Vector2i(0, 2))
	_continue_exit = get_node_or_null("Exits/Exit_Continue") as LevelExit2D
	_backtrack_exit = get_node_or_null("Exits/Exit_Backtrack") as LevelExit2D
	if _continue_exit == null:
		push_error("[ReturnCauseway] Missing authored Exit_Continue")
	else:
		_continue_exit.position = _tile_center(TRANSITION_TILE)
	if _backtrack_exit == null:
		push_error("[ReturnCauseway] Missing authored Exit_Backtrack")
	else:
		_backtrack_exit.position = _tile_center(ENTRANCE_TILE + Vector2i(0, 2))


# -- Music --------------------------------------------------------------------

func _setup_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	_music_player = AudioStreamPlayer2D.new()
	_music_player.name = "MusicPlayer"
	_music_player.stream = load(MUSIC_PATH)
	_music_player.autoplay = true
	_music_player.volume_db = -6.0
	_music_player.max_distance = 2000.0
	add_child(_music_player)


# -- Gatehouse Gate Logic -----------------------------------------------------

func _handle_sundered_interaction(kind: StringName, actor: Node) -> void:
	match kind:
		&"return_mooring":
			_activate_return_mooring()
		&"buried_terminal":
			_activate_buried_terminal()
		&"gatehouse_gate":
			_try_open_gatehouse_gate()


func _activate_return_mooring() -> void:
	if _return_mooring_active_overlay != null:
		_return_mooring_active_overlay.visible = true
	print("[ReturnCauseway] Return Mooring activated.")


func _activate_buried_terminal() -> void:
	if _buried_terminal_activated:
		return
	_buried_terminal_activated = true
	_gatehouse_unlocked = true

	# Visual feedback.
	if _buried_terminal_overlay != null:
		_buried_terminal_overlay.visible = true

	# Log.
	print("[ReturnCauseway] CUSTODIAN IDENTITY ESTABLISHED — Gatehouse unlocked.")
	print("[ReturnCauseway] The buried terminal imprints your identity. The gatehouse mechanism grinds to life.")


func _try_open_gatehouse_gate() -> void:
	if _gatehouse_opened:
		return
	if not _gatehouse_unlocked:
		print("[ReturnCauseway] Gatehouse gate is locked. Find the Buried Terminal to establish identity.")
		return
	_set_gatehouse_gate_open(true)


func _set_gatehouse_gate_open(open: bool) -> void:
	_gatehouse_opened = open
	if _gatehouse_closed_sprite != null:
		_gatehouse_closed_sprite.visible = not open
	if open:
		_clear_gatehouse_blockers()
		if _gatehouse_interaction != null:
			_gatehouse_interaction.remove_from_group("interactable")
			_gatehouse_interaction.visible = false
		print("[ReturnCauseway] Gatehouse gate opens.")
	else:
		_add_gatehouse_blockers()


func _add_gatehouse_blockers() -> void:
	_clear_gatehouse_blockers()
	_gatehouse_blockers.append(_add_blocker(
		Rect2i(GATEHOUSE_GATE_TILE + Vector2i(-1, 0), Vector2i(6, 2)),
		"GatehouseGateBlocker"
	))


func _clear_gatehouse_blockers() -> void:
	for blocker in _gatehouse_blockers:
		if blocker != null and is_instance_valid(blocker):
			blocker.queue_free()
	_gatehouse_blockers.clear()


# -- Elevation -----------------------------------------------------------------

func _ensure_elevation_map() -> void:
	_elevation_map = ELEVATION_MAP_SCRIPT.new()
	_elevation_map.name = "ElevationMap"
	add_child(_elevation_map)
	_build_elevation()


func _build_elevation() -> void:
	_elevation_map.call("clear")

	# Height 0 zones (beach, shore path, buried terminal, underbridge).
	_fill_elevation_rect(Rect2i(Vector2i(36, 58), Vector2i(24, 10)), 0, "walkable")    # Arrival beach
	_fill_elevation_rect(Rect2i(Vector2i(40, 43), Vector2i(12, 10)), 0, "walkable")    # Underbridge
	_fill_elevation_rect(Rect2i(Vector2i(52, 40), Vector2i(26, 12)), 0, "walkable")    # Shore path
	_fill_elevation_rect(Rect2i(Vector2i(64, 42), Vector2i(10, 7)), 0, "walkable")     # Buried terminal

	# Height 1 zones (stairs from shore up to causeway).
	_fill_elevation_rect(Rect2i(Vector2i(49, 43), Vector2i(3, 6)), 1, "stair")         # Shore stairs

	# Height 2 zones (causeway deck, return mooring, outer keep yard).
	_fill_elevation_rect(Rect2i(Vector2i(38, 51), Vector2i(22, 6)), 2, "walkable")     # Return mooring pad
	_fill_elevation_rect(Rect2i(Vector2i(40, 30), Vector2i(12, 14)), 2, "walkable")    # Causeway decks (intact + broken)
	_fill_elevation_rect(Rect2i(Vector2i(37, 9), Vector2i(16, 9)), 2, "walkable")      # Outer keep yard

	# Height 3 zone (gatehouse interior).
	_fill_elevation_rect(Rect2i(Vector2i(37, 20), Vector2i(16, 10)), 3, "walkable")    # Gatehouse threshold

	# Ledge/drop zones at edges.
	_fill_elevation_rect(Rect2i(Vector2i(39, 30), Vector2i(1, 14)), 2, "ledge")        # West causeway edge
	_fill_elevation_rect(Rect2i(Vector2i(51, 30), Vector2i(1, 14)), 2, "ledge")        # East causeway edge


func _fill_elevation_rect(rect: Rect2i, height: int, traversal: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_elevation_map.call("set_cell", Vector2i(x, y), height, traversal)


# -- Actor Elevation Tracking --------------------------------------------------

func _update_actor_elevation() -> void:
	if _elevation_map == null or get_tree() == null:
		return
	var actor := _find_operator_actor()
	if actor == null:
		return
	var actor_tile := _global_to_tile((actor as Node2D).global_position)
	if actor_tile == _last_actor_elevation_tile:
		return
	_last_actor_elevation_tile = actor_tile
	if actor.has_method("set_fake_elevation"):
		actor.call("set_fake_elevation", float(get_elevation_at_tile(actor_tile)) * ELEVATION_STEP_PX)


func _find_operator_actor() -> Node2D:
	var actor := get_node_or_null("/root/GameRoot/World/Operator")
	if actor is Node2D:
		return actor as Node2D
	if get_tree() == null:
		return null
	for player_node in get_tree().get_nodes_in_group("player"):
		if player_node is Node2D:
			return player_node as Node2D
	return null


# -- Tile Primitives -----------------------------------------------------------

func _fill_rect(rect: Rect2i, tile_id: String, category := "") -> void:
	if category.is_empty():
		category = _category_for_id(tile_id)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_tile("TerrainBase", tile_id, category, Vector2i(x, y))


func _scatter_variants(rect: Rect2i, variants: Dictionary) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			for tile_id in variants.keys():
				var divisor := int(variants[tile_id])
				if divisor > 0 and ((x * 31 + y * 17 + tile_id.length()) % divisor) == 0:
					_add_tile("FloorDetail", tile_id, _category_for_id(tile_id), Vector2i(x, y))
					break


func _add_ocean_hole(rect: Rect2i, blocker_name: String) -> void:
	_fill_rect(rect, "ocean_void_01")
	_add_blocker(rect, blocker_name)


func _add_tile(layer_name: String, tile_id: String, category: String, tile: Vector2i) -> Sprite2D:
	var sprite := _add_sprite(layer_name, tile_id, category, tile, Vector2.ZERO)
	if sprite != null and (category == "floors" or category == "causeway_floors"
			or category == "return_mooring_floor" or category == "entrance"
			or category == "cliffs"):
		_stats["floors"] = int(_stats["floors"]) + 1
	elif sprite != null and layer_name == "TerrainEdges":
		_stats["edges"] = int(_stats["edges"]) + 1
	return sprite


func _add_wall_run(rect: Rect2i, tile_id: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_wall_tile(Vector2i(x, y), tile_id)


func _add_wall_tile(tile: Vector2i, tile_id: String) -> void:
	var sprite := _add_sprite("WallsHigh", tile_id, "walls", tile, Vector2(0.0, -32.0))
	if sprite != null:
		_stats["walls"] = int(_stats["walls"]) + 1
	_add_blocker(Rect2i(tile, Vector2i.ONE), "WallBlocker_%s" % tile_id)


func _add_prop(layer_name: String, prop_id: String, tile: Vector2i, category := "props") -> Sprite2D:
	var path := _asset_path(prop_id, category)
	var texture := _load_texture(path)
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = prop_id
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_size := texture.get_size()
	sprite.position = _tile_top_left(tile) + Vector2(
		(TILE_SIZE - tex_size.x) * 0.5,
		TILE_SIZE - tex_size.y
	)
	(_layers[layer_name] as Node2D).add_child(sprite)
	_stats["props"] = int(_stats["props"]) + 1
	if layer_name == "PropsBlocking":
		_add_blocker(Rect2i(tile, Vector2i.ONE), "%sBlocker" % prop_id)
	return sprite


func _add_sprite(layer_name: String, asset_id: String, category: String, tile: Vector2i, offset: Vector2) -> Sprite2D:
	var path := _asset_path(asset_id, category)
	var texture := _load_texture(path)
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = asset_id
	sprite.texture = texture
	sprite.centered = false
	var tex_size := texture.get_size()
	if category == "floors" or category == "return_mooring_floor" or category == "return_mooring_overlay":
		sprite.position = _tile_top_left(tile) + offset
	else:
		sprite.position = _tile_top_left(tile) + Vector2(
			(TILE_SIZE - tex_size.x) * 0.5,
			TILE_SIZE - tex_size.y
		) + offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	(_layers[layer_name] as Node2D).add_child(sprite)
	return sprite


func _add_blocker(rect: Rect2i, blocker_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = blocker_name
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(float(rect.size.x) * TILE_SIZE, float(rect.size.y) * TILE_SIZE)
	shape.shape = rectangle
	shape.position = Vector2(rectangle.size.x * 0.5, rectangle.size.y * 0.5)
	body.position = _tile_top_left(rect.position)
	body.add_child(shape)
	(_layers["Collision"] as Node2D).add_child(body)
	_stats["blockers"] = int(_stats["blockers"]) + 1
	return body


func _add_interactable(node_name: String, kind: StringName, prompt: String, tile: Vector2i, distance: float) -> Node2D:
	var interactable := SUNDERED_KEEP_INTERACTABLE.new() as Node2D
	interactable.name = node_name
	interactable.position = _tile_center(tile)
	interactable.call("configure", self, kind, prompt, distance)
	add_child(interactable)
	_stats["interactables"] = int(_stats["interactables"]) + 1
	return interactable


# -- Asset Path Resolution -----------------------------------------------------

func _asset_path(asset_id: String, category: String) -> String:
	# Check runtime asset catalog first.
	if SUNDERED_KEEP_ASSETS.ASSETS.has(asset_id):
		var entry: Dictionary = SUNDERED_KEEP_ASSETS.ASSETS[asset_id]
		return str(entry.get("texture", ""))

	# Category-based paths.
	match category:
		"floors":
			return "res://content/tiles/sundered_keep/floors/%s.png" % asset_id
		"cliffs":
			return "res://content/tiles/sundered_keep/entrance/cliffs/%s.png" % asset_id
		"entrance":
			return "res://content/tiles/sundered_keep/entrance/%s.png" % asset_id
		"causeway_floors":
			return "res://content/tiles/sundered_keep/entrance/causeway_floors/%s.png" % asset_id
		"causeway_surfaces":
			return "res://content/tiles/sundered_keep/entrance/causeway_surfaces/%s.png" % asset_id
		"entrance_prefabs":
			return "res://content/tiles/sundered_keep/entrance/prefabs/%s.png" % asset_id
		"entrance_overlays":
			return "res://content/tiles/sundered_keep/entrance/overlays/%s.png" % asset_id
		"return_mooring_floor":
			return "res://content/tiles/sundered_keep/return_mooring/floors/%s.png" % asset_id
		"return_mooring_overlay":
			return "res://content/tiles/sundered_keep/return_mooring/overlays/%s.png" % asset_id
		"walls":
			return _resolve_wall_path(asset_id)
		"props":
			return _resolve_prop_path(asset_id)
		"stairs":
			return "res://content/tiles/sundered_keep/entrance/causeway_floors/%s.png" % asset_id
		_:
			return "res://content/tiles/sundered_keep/%s/%s.png" % [category, asset_id]


func _resolve_wall_path(tile_id: String) -> String:
	var dirs := [
		"res://content/tiles/sundered_keep/entrance/causeway_walls",
		"res://content/tiles/sundered_keep/walls/gatehouse",
		"res://content/tiles/sundered_keep/walls/gothic_castle",
		"res://content/tiles/sundered_keep/walls/ramparts",
		"res://content/tiles/sundered_keep/walls",
	]
	for dir in dirs:
		var wall_path := "%s/%s.png" % [dir, tile_id]
		if ResourceLoader.exists(wall_path):
			return wall_path
	return "res://content/tiles/sundered_keep/walls/gothic_castle/%s.png" % tile_id


func _resolve_prop_path(prop_id: String) -> String:
	var prop_paths := [
		"res://content/props/sundered_keep/causeway/%s.png" % prop_id,
		"res://content/props/sundered_keep/return_mooring/%s.png" % prop_id,
		"res://content/props/sundered_keep/entrance/%s.png" % prop_id,
		"res://content/tiles/sundered_keep/entrance/props/%s.png" % prop_id,
		# Runtime prop subdirectories (same as sundered_keep_map.gd).
		"res://content/runtime/sundered_keep/props/prop_anchor/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_barrier/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_column/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_debris/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_furniture/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_hanging/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_large/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_light/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_mechanical/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_medium/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_observatory/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_rock/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_rooftop/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_rubble/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_statue/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_storage/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_table/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_tall/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_throne/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_tomb/%s.png" % prop_id,
		"res://content/runtime/sundered_keep/props/prop_wall_low/%s.png" % prop_id,
	]
	for prop_path in prop_paths:
		if ResourceLoader.exists(prop_path):
			return prop_path
	return "res://content/tiles/sundered_keep/entrance/props/%s.png" % prop_id


func _load_texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path] as Texture2D
	if not ResourceLoader.exists(path):
		_stats["missing_assets"] = int(_stats["missing_assets"]) + 1
		_textures[path] = null
		return null
	var texture := load(path) as Texture2D
	_textures[path] = texture
	return texture


func _category_for_id(tile_id: String) -> String:
	# Check for subfloor identifiers first (before broad prefix matches).
	if tile_id.begins_with("return_mooring_floor"):
		return "return_mooring_floor"
	if tile_id.begins_with("return_mooring_"):
		return "return_mooring_overlay"
	# Tiles containing "_floor" are floor tiles regardless of prefix.
	# e.g. cliff_rock_floor_01 is in floors/ not cliffs/.
	if "_floor" in tile_id or "_flagstone" in tile_id or "_threshold" in tile_id or "_carpet" in tile_id:
		return "floors"
	# Cobblestone is in causeway_floors/ not floors/.
	if tile_id.begins_with("cobblestone_"):
		return "causeway_floors"
	# Cliff edges and ocean foam are terrain edges.
	if tile_id.begins_with("cliff_edge_") or tile_id.begins_with("cliff_inner_") or tile_id.begins_with("cliff_outer_"):
		return "cliffs"
	if tile_id.begins_with("ocean_foam_"):
		return "cliffs"
	# Ocean tiles.
	if tile_id == "ocean_void_01":
		return "floors"
	if tile_id.begins_with("ocean_"):
		return "cliffs"
	if tile_id.begins_with("entrance_causeway"):
		return "entrance"
	if tile_id.begins_with("main_gate_") or tile_id.begins_with("main_courtyard_"):
		return "floors"
	if tile_id.begins_with("great_hall_"):
		return "floors"
	if tile_id.begins_with("gateway_prefab"):
		return "entrance_prefabs"
	if tile_id.begins_with("dungeon_"):
		return "floors"
	return "floors"


# -- Coordinate Helpers --------------------------------------------------------

func _tile_top_left(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _tile_center(tile: Vector2i) -> Vector2:
	return _tile_top_left(tile) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func _global_to_tile(global_position: Vector2) -> Vector2i:
	var local_position := to_local(global_position)
	return Vector2i(floori(local_position.x / TILE_SIZE), floori(local_position.y / TILE_SIZE))


func _refresh_camera(map_instance: Node, actor: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera != null and actor is Node2D:
		camera.global_position = (actor as Node2D).global_position


# -- Debug ---------------------------------------------------------------------

func _debug_print_summary() -> void:
	print("[ReturnCauseway] Level built: map=%sx%s floors=%d edges=%d walls=%d props=%d blockers=%d interactables=%d missing_assets=%d" % [
		MAP_SIZE_TILES.x, MAP_SIZE_TILES.y,
		int(_stats["floors"]), int(_stats["edges"]), int(_stats["walls"]),
		int(_stats["props"]), int(_stats["blockers"]), int(_stats["interactables"]),
		int(_stats["missing_assets"]),
	])
