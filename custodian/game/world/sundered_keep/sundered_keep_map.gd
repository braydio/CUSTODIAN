extends Node2D
class_name SunderedKeepMap

const TILE_SIZE := 32.0
const MAP_SIZE_TILES := Vector2i(64, 44)
const TRAVEL_GATE_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_travel_gate.gd")

@export var entrance_tile: Vector2i = Vector2i(32, 39)
@export var return_gate_tile: Vector2i = Vector2i(32, 38)
@export var upper_stair_tile: Vector2i = Vector2i(21, 19)
@export var lower_stair_tile: Vector2i = Vector2i(16, 29)
@export var hatch_tile: Vector2i = Vector2i(15, 30)

var main_map: Node = null
var main_return_position: Vector2 = Vector2.ZERO

var _built := false
var _camera_bounds := Rect2()
var _layers: Dictionary = {}
var _textures: Dictionary = {}
var _return_gate: Node2D = null


func _ready() -> void:
	add_to_group("connected_map")
	add_to_group("sundered_keep_map")
	_build_once()


func configure_connection(p_main_map: Node, p_main_return_position: Vector2) -> void:
	main_map = p_main_map
	main_return_position = p_main_return_position


func get_entry_position() -> Vector2:
	return to_global(_tile_center(entrance_tile))


func get_return_gate_position() -> Vector2:
	return to_global(_tile_center(return_gate_tile))


func get_camera_bounds() -> Rect2:
	return Rect2(to_global(_camera_bounds.position), _camera_bounds.size)


func enter_from_main(actor: Node) -> void:
	if actor is Node2D:
		(actor as Node2D).global_position = get_entry_position()
	_refresh_camera(self, actor)


func return_to_main(actor: Node) -> void:
	if actor is Node2D:
		(actor as Node2D).global_position = main_return_position
	_refresh_camera(main_map, actor)


func _build_once() -> void:
	if _built:
		return
	_built = true
	_camera_bounds = Rect2(
		Vector2(-TILE_SIZE * 2.0, -TILE_SIZE * 2.0),
		Vector2(float(MAP_SIZE_TILES.x + 4) * TILE_SIZE, float(MAP_SIZE_TILES.y + 4) * TILE_SIZE)
	)
	_create_layers()
	_build_ocean_backdrop()
	_build_main_gate()
	_build_courtyard()
	_build_great_hall()
	_build_rampart_and_cliffs()
	_build_traversal_stubs()
	_add_return_gate()


func _create_layers() -> void:
	var names := [
		"TerrainBase",
		"TerrainEdges",
		"WallsLow",
		"WallsHigh",
		"PropsStatic",
		"PropsBlocking",
		"Traversal",
		"Hazards",
		"Overlays",
		"RoofOccluders",
		"Collision",
	]
	var z_by_name := {
		"TerrainBase": -80,
		"TerrainEdges": -70,
		"WallsLow": -35,
		"WallsHigh": -15,
		"PropsStatic": -5,
		"PropsBlocking": 5,
		"Traversal": 8,
		"Hazards": 10,
		"Overlays": 15,
		"RoofOccluders": 60,
		"Collision": 0,
	}
	for layer_name in names:
		var layer := Node2D.new()
		layer.name = layer_name
		layer.z_as_relative = false
		layer.z_index = int(z_by_name[layer_name])
		add_child(layer)
		_layers[layer_name] = layer


func _build_ocean_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "StormOceanBackdrop"
	backdrop.color = Color(0.014, 0.035, 0.064, 1.0)
	backdrop.size = Vector2(float(MAP_SIZE_TILES.x) * TILE_SIZE, float(MAP_SIZE_TILES.y) * TILE_SIZE)
	backdrop.z_as_relative = false
	backdrop.z_index = -120
	add_child(backdrop)

	for y in range(MAP_SIZE_TILES.y):
		for x in range(MAP_SIZE_TILES.x):
			if (x + y) % 3 == 0:
				_add_tile("TerrainBase", "ocean_dark_water_01", "cliffs", Vector2i(x, y))
			elif (x * 5 + y * 3) % 11 == 0:
				_add_tile("TerrainBase", "ocean_whitecap_01", "cliffs", Vector2i(x, y))


func _build_main_gate() -> void:
	_fill_rect(Rect2i(Vector2i(25, 36), Vector2i(14, 7)), "main_gate_threshold_stone_01")
	_fill_rect(Rect2i(Vector2i(29, 39), Vector2i(6, 5)), "main_courtyard_flagstone_wet_01")
	_add_wall_run(Rect2i(Vector2i(24, 35), Vector2i(16, 2)), "gothic_castle_wall_straight_s")
	_add_wall_run(Rect2i(Vector2i(24, 36), Vector2i(1, 7)), "gothic_castle_wall_straight_e")
	_add_wall_run(Rect2i(Vector2i(39, 36), Vector2i(1, 7)), "gothic_castle_wall_straight_w")
	_add_sprite("Traversal", "main_gate_portcullis_closed", "doors", Vector2i(31, 36), Vector2.ZERO)
	_add_blocker(Rect2i(Vector2i(31, 36), Vector2i(2, 1)), "MainPortcullisBlocker")
	_add_prop("PropsBlocking", "prop_gate_barricade_01", "gatehouse", Vector2i(34, 40))
	_add_prop("PropsStatic", "prop_gate_winch_01", "gatehouse", Vector2i(27, 37))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", "gatehouse", Vector2i(25, 37))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", "gatehouse", Vector2i(38, 37))
	_add_overlay("rain_puddle_overlay_01", Vector2i(30, 41))
	_add_overlay("rain_puddle_overlay_02", Vector2i(35, 38))


func _build_courtyard() -> void:
	var courtyard := Rect2i(Vector2i(18, 19), Vector2i(28, 17))
	_fill_rect(courtyard, "main_courtyard_flagstone_01")
	_scatter_floor_variants(courtyard, {
		"main_courtyard_flagstone_cracked_01": 7,
		"main_courtyard_flagstone_wet_01": 9,
		"main_courtyard_flagstone_mossy_01": 13,
	})
	_add_room_walls(courtyard, {"south_open_min": 30, "south_open_max": 34, "north_open_min": 31, "north_open_max": 33})
	_add_prop("PropsBlocking", "prop_courtyard_fountain_broken_01", "courtyard", Vector2i(30, 27))
	_add_prop("PropsBlocking", "prop_gothic_statue_broken_01", "courtyard", Vector2i(22, 24))
	_add_prop("PropsBlocking", "prop_gothic_statue_intact_01", "courtyard", Vector2i(42, 24))
	_add_prop("PropsBlocking", "prop_broken_cart_01", "courtyard", Vector2i(23, 31))
	_add_prop("PropsBlocking", "prop_crate_stack_wet_01", "courtyard", Vector2i(39, 31))
	_add_prop("PropsBlocking", "prop_barrel_wet_01", "courtyard", Vector2i(42, 32))
	_add_prop("PropsBlocking", "prop_fallen_masonry_01", "courtyard", Vector2i(19, 20))
	_add_prop("PropsBlocking", "prop_low_garden_wall_01", "courtyard", Vector2i(36, 24))
	_add_overlay("temporal_echo_overlay_01", Vector2i(33, 26))
	_add_overlay("moss_overlay_01", Vector2i(20, 34))
	_add_overlay("crack_overlay_01", Vector2i(44, 20))


func _build_great_hall() -> void:
	var hall := Rect2i(Vector2i(20, 5), Vector2i(24, 14))
	_fill_rect(hall, "great_hall_marble_floor_01")
	_scatter_floor_variants(hall, {
		"great_hall_marble_floor_cracked_01": 8,
		"great_hall_marble_floor_wet_01": 17,
	})
	for y in range(hall.position.y, hall.end.y):
		_add_tile("TerrainBase", "great_hall_carpet_runner_vertical_01", "floors", Vector2i(31, y))
		_add_tile("TerrainBase", "great_hall_carpet_runner_vertical_01", "floors", Vector2i(32, y))
	_add_room_walls(hall, {"south_open_min": 31, "south_open_max": 33, "east_open_min": 10, "east_open_max": 12})
	_add_sprite("Traversal", "gothic_double_door_closed_n", "doors", Vector2i(31, 18), Vector2.ZERO)
	_add_blocker(Rect2i(Vector2i(31, 18), Vector2i(2, 1)), "GreatHallDoorBlocker")
	_add_prop("PropsBlocking", "prop_banquet_table_long_01", "great_hall", Vector2i(23, 10))
	_add_prop("PropsBlocking", "prop_banquet_table_long_01", "great_hall", Vector2i(35, 10))
	_add_prop("PropsBlocking", "prop_banquet_table_broken_01", "great_hall", Vector2i(23, 14))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", "great_hall", Vector2i(21, 7))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", "great_hall", Vector2i(41, 7))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", "great_hall", Vector2i(21, 16))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", "great_hall", Vector2i(41, 16))
	_add_prop("PropsBlocking", "prop_fallen_chandelier_01", "great_hall", Vector2i(30, 13))
	_add_prop("PropsBlocking", "prop_throne_ruined_01", "great_hall", Vector2i(31, 6))
	_add_prop("PropsStatic", "prop_brazier_iron_01", "great_hall", Vector2i(28, 7))
	_add_prop("PropsStatic", "prop_brazier_iron_01", "great_hall", Vector2i(35, 7))
	_add_prop("PropsStatic", "prop_banner_torn_large_01", "great_hall", Vector2i(25, 5))
	_add_prop("PropsStatic", "prop_banner_torn_large_01", "great_hall", Vector2i(38, 5))


func _build_rampart_and_cliffs() -> void:
	var rampart := Rect2i(Vector2i(44, 7), Vector2i(16, 6))
	_fill_rect(rampart, "rampart_walkway_floor_01")
	_scatter_floor_variants(rampart, {"rampart_walkway_wet_01": 5})
	_add_wall_run(Rect2i(Vector2i(44, 6), Vector2i(16, 1)), "rampart_crenellation_s")
	_add_wall_run(Rect2i(Vector2i(58, 7), Vector2i(1, 6)), "rampart_parapet_w")
	_add_wall_run(Rect2i(Vector2i(44, 12), Vector2i(16, 1)), "rampart_broken_gap_n")
	_add_prop("PropsBlocking", "prop_gargoyle_perch_01", "exterior", Vector2i(57, 7))
	_add_prop("PropsStatic", "prop_lightning_rod_01", "exterior", Vector2i(52, 8))
	_add_prop("PropsStatic", "prop_rope_bridge_anchor_01", "exterior", Vector2i(45, 10))
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", "exterior", Vector2i(59, 15))
	_add_prop("PropsBlocking", "prop_broken_spire_chunk_01", "exterior", Vector2i(55, 13))

	for x in range(14, 61):
		_add_tile("TerrainEdges", "cliff_edge_n", "cliffs", Vector2i(x, 4))
		_add_tile("TerrainEdges", "cliff_face_slice_01", "cliffs", Vector2i(x, 3))
	for y in range(4, 41):
		_add_tile("TerrainEdges", "cliff_edge_e", "cliffs", Vector2i(60, y))
		_add_tile("TerrainEdges", "cliff_face_slice_wet_01", "cliffs", Vector2i(61, y))
	for x in range(9, 61):
		_add_tile("TerrainEdges", "ocean_foam_edge_s", "cliffs", Vector2i(x, 41))
	for y in range(8, 42):
		_add_tile("TerrainEdges", "ocean_foam_edge_e", "cliffs", Vector2i(9, y))
	_add_blocker(Rect2i(Vector2i(60, 4), Vector2i(3, 38)), "EastOceanBoundary")
	_add_blocker(Rect2i(Vector2i(9, 40), Vector2i(52, 3)), "SouthOceanBoundary")
	_add_blocker(Rect2i(Vector2i(9, 4), Vector2i(2, 38)), "WestOceanBoundary")
	_add_blocker(Rect2i(Vector2i(10, 3), Vector2i(52, 2)), "NorthOceanBoundary")


func _build_traversal_stubs() -> void:
	_add_sprite("Traversal", "stone_stairs_up_n", "stairs", upper_stair_tile, Vector2.ZERO)
	_add_sprite("Traversal", "stone_stairs_down_s", "stairs", lower_stair_tile, Vector2.ZERO)
	_add_sprite("Traversal", "floor_hatch_closed_01", "stairs", hatch_tile, Vector2.ZERO)
	_add_traversal_marker(upper_stair_tile, "UPPER RAMPART STUB")
	_add_traversal_marker(lower_stair_tile, "LOWER STAIR STUB")
	_add_traversal_marker(hatch_tile, "UNDERCROFT HATCH")


func _add_return_gate() -> void:
	_return_gate = TRAVEL_GATE_SCRIPT.new() as Node2D
	if _return_gate == null:
		return
	_return_gate.name = "ReturnToMainMapGate"
	_return_gate.call("configure", self, 1, "RETURN TO MAIN MAP")
	_return_gate.position = _tile_center(return_gate_tile)
	add_child(_return_gate)


func _fill_rect(rect: Rect2i, tile_id: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_tile("TerrainBase", tile_id, "floors", Vector2i(x, y))


func _scatter_floor_variants(rect: Rect2i, variants: Dictionary) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			for tile_id in variants.keys():
				var divisor := int(variants[tile_id])
				if divisor > 0 and ((x * 31 + y * 17 + tile_id.length()) % divisor) == 0:
					_add_tile("TerrainBase", tile_id, "floors", Vector2i(x, y))
					break


func _add_room_walls(rect: Rect2i, openings: Dictionary) -> void:
	for x in range(rect.position.x, rect.end.x):
		if not _is_opening(x, "north", openings):
			_add_wall_tile(Vector2i(x, rect.position.y - 1), "gothic_castle_wall_straight_s")
		if not _is_opening(x, "south", openings):
			_add_wall_tile(Vector2i(x, rect.end.y), "gothic_castle_wall_straight_n")
	for y in range(rect.position.y, rect.end.y):
		if not _is_opening(y, "west", openings):
			_add_wall_tile(Vector2i(rect.position.x - 1, y), "gothic_castle_wall_straight_e")
		if not _is_opening(y, "east", openings):
			_add_wall_tile(Vector2i(rect.end.x, y), "gothic_castle_wall_straight_w")
	_add_wall_tile(Vector2i(rect.position.x - 1, rect.position.y - 1), "gothic_castle_wall_outer_corner_se")
	_add_wall_tile(Vector2i(rect.end.x, rect.position.y - 1), "gothic_castle_wall_outer_corner_sw")
	_add_wall_tile(Vector2i(rect.position.x - 1, rect.end.y), "gothic_castle_wall_outer_corner_ne")
	_add_wall_tile(Vector2i(rect.end.x, rect.end.y), "gothic_castle_wall_outer_corner_nw")


func _is_opening(value: int, side: String, openings: Dictionary) -> bool:
	var min_key := "%s_open_min" % side
	var max_key := "%s_open_max" % side
	if not openings.has(min_key) or not openings.has(max_key):
		return false
	return value >= int(openings[min_key]) and value <= int(openings[max_key])


func _add_wall_run(rect: Rect2i, tile_id: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_wall_tile(Vector2i(x, y), tile_id)


func _add_wall_tile(tile: Vector2i, tile_id: String) -> void:
	_add_sprite("WallsHigh", tile_id, "walls", tile, Vector2(0.0, -32.0))
	_add_blocker(Rect2i(tile, Vector2i.ONE), "WallBlocker")


func _add_tile(layer_name: String, tile_id: String, category: String, tile: Vector2i) -> Sprite2D:
	return _add_sprite(layer_name, tile_id, category, tile, Vector2.ZERO)


func _add_prop(layer_name: String, prop_id: String, folder: String, tile: Vector2i) -> void:
	var path := "res://content/props/sundered_keep/%s/%s.png" % [folder, prop_id]
	var texture := _load_texture(path)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = prop_id
	sprite.texture = texture
	sprite.centered = false
	sprite.position = _tile_top_left(tile) + Vector2(0.0, TILE_SIZE - float(texture.get_height()))
	(_layers[layer_name] as Node2D).add_child(sprite)
	if layer_name == "PropsBlocking":
		var width_tiles := maxi(1, int(ceil(float(texture.get_width()) / TILE_SIZE)))
		var height_tiles := maxi(1, int(ceil(float(min(texture.get_height(), 64)) / TILE_SIZE)))
		_add_blocker(Rect2i(tile, Vector2i(width_tiles, height_tiles)), "%sBlocker" % prop_id)


func _add_sprite(layer_name: String, asset_id: String, category: String, tile: Vector2i, offset: Vector2) -> Sprite2D:
	var texture := _load_texture(_asset_path(asset_id, category))
	var sprite := Sprite2D.new()
	sprite.name = asset_id
	sprite.texture = texture
	sprite.centered = false
	sprite.position = _tile_top_left(tile) + offset
	if texture == null:
		sprite.modulate = Color(0.8, 0.2, 0.2, 1.0)
	(_layers[layer_name] as Node2D).add_child(sprite)
	return sprite


func _add_overlay(asset_id: String, tile: Vector2i) -> void:
	_add_sprite("Overlays", asset_id, "overlays", tile, Vector2.ZERO)


func _add_traversal_marker(tile: Vector2i, marker_name: String) -> void:
	var marker := Polygon2D.new()
	marker.name = marker_name
	marker.color = Color(0.36, 0.84, 0.82, 0.30)
	marker.polygon = PackedVector2Array([
		Vector2(-16, 0),
		Vector2(0, -10),
		Vector2(16, 0),
		Vector2(0, 10),
	])
	marker.position = _tile_center(tile)
	(_layers["Traversal"] as Node2D).add_child(marker)


func _add_blocker(rect: Rect2i, blocker_name: String) -> void:
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


func _asset_path(asset_id: String, category: String) -> String:
	return "res://content/tiles/sundered_keep/%s/%s.png" % [category, asset_id]


func _load_texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path] as Texture2D
	if not ResourceLoader.exists(path):
		push_warning("[SunderedKeepMap] Missing texture: %s" % path)
		_textures[path] = null
		return null
	var texture := load(path) as Texture2D
	_textures[path] = texture
	return texture


func _tile_top_left(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _tile_center(tile: Vector2i) -> Vector2:
	return _tile_top_left(tile) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func _refresh_camera(map_instance: Node, actor: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera != null and actor is Node2D:
		camera.global_position = (actor as Node2D).global_position
