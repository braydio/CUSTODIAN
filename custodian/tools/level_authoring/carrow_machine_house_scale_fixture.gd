extends Node2D
class_name CarrowMachineHouseScaleFixture

const TILE_SIZE := 32
const STRUCTURE_ROOT := "res://content/sprites/environment/structure/carrow_machine_house/runtime/"
const FLOOR_ROOT := "res://content/tiles/interiors/runtime/"
const FLOOR_STATES := [
	"slab_plain_01", "slab_plain_01", "slab_plain_01", "slab_worn_01",
	"slab_worn_01", "slab_oil_01", "slab_plain_01", "slab_plain_01",
]
const VARIANTS := {
	"24x18": Vector2i(24, 18),
	"30x22": Vector2i(30, 22),
	"36x26": Vector2i(36, 26),
}
const EQUIPMENT_RECTS := [
	{"owner": "nw_relay", "origin": Vector2i(3, 3), "size": Vector2i(6, 4)},
	{"owner": "ne_switchgear", "origin_from_edge": Vector2i(-9, 3), "size": Vector2i(6, 4)},
	{"owner": "sw_service", "origin_from_edge": Vector2i(3, -8), "size": Vector2i(5, 3)},
	{"owner": "se_power", "origin_from_edge": Vector2i(-8, -8), "size": Vector2i(5, 3)},
]
const ART_PLACEMENTS := [
	{"name": "NorthWallPanelled", "path": "walls/wall_carrow_wall_run_panelled_long_01.png", "offset": Vector2i(-5, 2), "center_x": true, "z": -18},
	{"name": "NorthWallConduit", "path": "walls/wall_carrow_wall_run_conduit_long_01.png", "offset": Vector2i(3, 2), "center_x": true, "z": -18},
	{"name": "WestWall", "path": "walls/wall_carrow_pillar_lit_01.png", "offset": Vector2i(1, 0), "edge": false, "y_mid": true, "z": -17},
	{"name": "EastWall", "path": "walls/wall_carrow_pillar_plain_02.png", "offset": Vector2i(-1, 0), "edge_x": true, "y_mid": true, "z": -17},
	{"name": "SouthDoorway", "path": "walls/wall_carrow_doorframe_recessed_01.png", "offset": Vector2i(-1, 0), "center_x": true, "y_edge": true, "z": -16},
	{"name": "RelayBank", "path": "props/carrow_machine_house_relay_bank.png", "anchor": Vector2i(4, 4), "z": -12},
	{"name": "Switchgear", "path": "props/carrow_machine_house_switchgear.png", "offset": Vector2i(-7, 4), "edge_x": true, "z": -12},
	{"name": "PartsLocker", "path": "props/carrow_machine_house_parts_locker.png", "offset": Vector2i(3, -7), "edge": false, "y_edge": true, "z": -10},
	{"name": "Workbench", "path": "props/carrow_machine_house_workbench.png", "offset": Vector2i(6, -7), "edge": false, "y_edge": true, "z": -10},
	{"name": "ServiceCabinet", "path": "props/carrow_machine_house_service_cabinet.png", "offset": Vector2i(4, -5), "edge": false, "y_edge": true, "z": -10},
	{"name": "ReplacementModules", "path": "props/carrow_machine_house_replacement_modules.png", "offset": Vector2i(7, -6), "edge": false, "y_edge": true, "z": -10},
	{"name": "ConduitJunction", "path": "props/carrow_machine_house_conduit_junction.png", "offset": Vector2i(-5, 0), "edge_x": true, "y_mid": true, "z": -10},
	{"name": "PowerCabinet", "path": "props/carrow_machine_house_power_cabinet.png", "offset": Vector2i(-5, -6), "edge_x": true, "y_edge": true, "z": -10},
]
const STORAGE_DEFINITIONS := [
	{"id": "carrow_service_parts_locker", "name": "Service Parts Locker", "art": "PartsLocker", "resources": {&"ruin_scrap": 52, &"structural_alloy": 4}},
	{"id": "carrow_structural_spares_rack", "name": "Structural Spares Rack", "art": "ReplacementModules", "resources": {&"structural_alloy": 14, &"ruin_scrap": 16}},
	{"id": "carrow_power_components_cabinet", "name": "Power Components Cabinet", "art": "PowerCabinet", "resources": {&"power_components": 4, &"capacitor_dust": 3, &"ruin_scrap": 10}},
]
const WAYPOINTS := [&"ENTRY", &"CENTER", &"NORTH"]
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CAMERA_SCRIPT := preload("res://game/world/camera.gd")
const STORAGE_SCENE := preload("res://game/actors/storage/vault_storage.tscn")
const LIGHTING_ZONE_SCRIPT := preload("res://game/world/lighting/lighting_zone_2d.gd")
const LIGHT_RIG_SCENE := preload("res://game/world/lighting/light_rig_2d.tscn")

@export_enum("24x18", "30x22", "36x26") var variant_id := "24x18"

var room_size := Vector2i.ZERO
var operator: CharacterBody2D
var camera: CameraController
var collision_shapes: Array[CollisionShape2D] = []
var collider_overlay: Node2D
var grid_overlay: Node2D
var values_label: Label
var _waypoint_index := 0
var _colliders_visible := false
var _grid_visible := false


func _ready() -> void:
	if not VARIANTS.has(variant_id):
		push_error("Unknown Carrow scale fixture variant: %s" % variant_id)
		set_process_input(false)
		return
	room_size = VARIANTS[variant_id]
	var window := get_window()
	window.size = Vector2i(768, 576)
	window.content_scale_size = Vector2i(768, 576)
	var equipment := _resolved_equipment_rects()
	var art_paths: Array[String] = []
	for placement in ART_PLACEMENTS:
		art_paths.append(String(placement.path))
	if not validate_geometry(room_size, equipment) or not validate_art_paths(art_paths):
		push_error("Carrow scale fixture configuration failed closed: %s" % variant_id)
		set_process_input(false)
		return
	_build_room()
	_build_actor_and_camera()
	_build_overlays()
	_teleport_to_waypoint(0)


func _process(_delta: float) -> void:
	if _colliders_visible and collider_overlay != null:
		collider_overlay.queue_redraw()
	if values_label != null and values_label.visible:
		_update_values_label()


func _build_room() -> void:
	var floor_root := Node2D.new()
	floor_root.name = "Native32pxFloor"
	floor_root.z_index = -40
	add_child(floor_root)
	for y in range(room_size.y):
		for x in range(room_size.x):
			var state: String = FLOOR_STATES[(x * 3 + y * 5) % FLOOR_STATES.size()]
			var sprite := Sprite2D.new()
			sprite.name = "Floor_%02d_%02d" % [x, y]
			sprite.texture = load(FLOOR_ROOT + "floor_carrow_%s_32.png" % state) as Texture2D
			sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
			floor_root.add_child(sprite)

	var backing := Polygon2D.new()
	backing.name = "FixtureBacking"
	backing.color = Color(0.035, 0.038, 0.042, 1.0)
	backing.z_index = -42
	backing.polygon = PackedVector2Array([
		Vector2(-TILE_SIZE * 1.5, -TILE_SIZE * 1.5),
		Vector2(room_size.x * TILE_SIZE + TILE_SIZE * 1.5, -TILE_SIZE * 1.5),
		Vector2(room_size.x * TILE_SIZE + TILE_SIZE * 1.5, room_size.y * TILE_SIZE + TILE_SIZE * 1.5),
		Vector2(-TILE_SIZE * 1.5, room_size.y * TILE_SIZE + TILE_SIZE * 1.5),
	])
	add_child(backing)

	for y in range(room_size.y):
		for x in range(room_size.x):
			var cell := Vector2i(x, y)
			if _is_perimeter(cell) and not _is_door_cell(cell):
				_add_cell_collider(cell, "perimeter")
	for rect_definition in _resolved_equipment_rects():
		var rect: Rect2i = rect_definition.rect
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_add_cell_collider(Vector2i(x, y), String(rect_definition.owner))
	_build_art_and_storage()
	_build_lighting()


func _resolved_equipment_rects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in EQUIPMENT_RECTS:
		var origin: Vector2i = item.get("origin", Vector2i.ZERO)
		if item.has("origin_from_edge"):
			var edge_offset: Vector2i = item.origin_from_edge
			match String(item.owner):
				"ne_switchgear": origin = Vector2i(room_size.x + edge_offset.x, edge_offset.y)
				"sw_service": origin = Vector2i(edge_offset.x, room_size.y + edge_offset.y)
				"se_power": origin = Vector2i(room_size.x + edge_offset.x, room_size.y + edge_offset.y)
		result.append({"owner": String(item.owner), "rect": Rect2i(origin, item.size)})
	return result


static func validate_art_paths(paths: Array) -> bool:
	if paths.size() != ART_PLACEMENTS.size():
		return false
	var names := {}
	for path_variant in paths:
		var path := String(path_variant)
		if path.is_empty() or not ResourceLoader.exists(STRUCTURE_ROOT + path, "Texture2D"):
			return false
		if names.has(path):
			return false
		names[path] = true
	return true


static func validate_geometry(size: Vector2i, equipment: Array, forced_blocked_cells: Array = []) -> bool:
	if not VARIANTS.values().has(size) or size.x % 2 != 0:
		return false
	var expected_rects := {
		"nw_relay": Rect2i(3, 3, 6, 4),
		"ne_switchgear": Rect2i(size.x - 9, 3, 6, 4),
		"sw_service": Rect2i(3, size.y - 8, 5, 3),
		"se_power": Rect2i(size.x - 8, size.y - 8, 5, 3),
	}
	if equipment.size() != expected_rects.size():
		return false
	var occupied := {}
	var owners := {}
	var aisle_left := (size.x >> 1) - 2
	var aisle_right := aisle_left + 4
	for value in equipment:
		if not (value is Dictionary) or not (value.get("rect", null) is Rect2i):
			return false
		var rect: Rect2i = value.rect
		var owner := String(value.get("owner", ""))
		if not expected_rects.has(owner) or expected_rects[owner] != rect or owners.has(owner):
			return false
		owners[owner] = true
		if rect.size.x <= 0 or rect.size.y <= 0 or rect.position.x < 1 or rect.position.y < 1:
			return false
		if rect.end.x > size.x - 1 or rect.end.y > size.y - 1:
			return false
		if rect.position.x < aisle_right and rect.end.x > aisle_left:
			return false
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if occupied.has(cell):
					return false
				occupied[cell] = true
	if owners.size() != expected_rects.size():
		return false
	for value in forced_blocked_cells:
		if not (value is Vector2i):
			return false
		var cell: Vector2i = value
		if cell.y == size.y - 1 and cell.x >= aisle_left and cell.x < aisle_right:
			return false
	return true


func _add_cell_collider(cell: Vector2i, owner: String) -> void:
	var body := StaticBody2D.new()
	body.name = "Solid_%s_%d_%d" % [owner, cell.x, cell.y]
	body.position = Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("tile", cell)
	body.set_meta("owner", owner)
	var shape := CollisionShape2D.new()
	shape.name = "CellCollider"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2.ONE * TILE_SIZE
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)
	collision_shapes.append(shape)


func _build_art_and_storage() -> void:
	var art_root := Node2D.new()
	art_root.name = "ProductionArt"
	add_child(art_root)
	var anchor_by_name: Dictionary = {}
	for placement in ART_PLACEMENTS:
		var anchor := _resolve_art_anchor(placement)
		anchor_by_name[String(placement.name)] = anchor
		var texture := load(STRUCTURE_ROOT + String(placement.path)) as Texture2D
		if texture == null:
			push_error("Missing Carrow scale fixture art: %s" % placement.path)
			continue
		var sprite := Sprite2D.new()
		sprite.name = String(placement.name)
		sprite.texture = texture
		sprite.centered = true
		sprite.position = Vector2(anchor * TILE_SIZE) - Vector2(0.0, texture.get_height() * 0.5)
		sprite.z_as_relative = false
		sprite.z_index = int(placement.z)
		sprite.set_meta("fixture_source_path", String(placement.path))
		art_root.add_child(sprite)
		var overlaps_walkable: Array[Vector2i] = _art_walkable_overlap(anchor, texture.get_size())
		sprite.set_meta("fixture_anchor", anchor)
		sprite.set_meta("fixture_walkable_overlap", overlaps_walkable)

	var storage_root := Node2D.new()
	storage_root.name = "ArtBoundStorage"
	add_child(storage_root)
	for storage_definition in STORAGE_DEFINITIONS:
		var storage := STORAGE_SCENE.instantiate()
		if storage == null:
			push_error("Unable to instantiate Carrow scale fixture storage")
			continue
		storage.name = String(storage_definition.id).to_pascal_case()
		storage.set("storage_id", StringName(storage_definition.id))
		storage.set("display_name", String(storage_definition.name))
		storage.set("starting_resources", storage_definition.resources.duplicate(true))
		storage.set("default_visual_enabled", false)
		var art_anchor: Vector2i = anchor_by_name[String(storage_definition.art)]
		storage.position = Vector2(art_anchor * TILE_SIZE)
		storage_root.add_child(storage)


func _resolve_art_anchor(placement: Dictionary) -> Vector2i:
	if placement.has("anchor"):
		return placement.anchor
	var offset: Vector2i = placement.offset
	var x := offset.x if not bool(placement.get("edge_x", false)) else room_size.x + offset.x
	if bool(placement.get("center_x", false)):
		x = (room_size.x >> 1) + offset.x
	var y := offset.y
	if bool(placement.get("y_mid", false)):
		y = room_size.y / 2 + offset.y
	elif bool(placement.get("y_edge", false)):
		y = room_size.y + offset.y
	return Vector2i(x, y)


func _art_walkable_overlap(anchor: Vector2i, texture_size: Vector2i) -> Array[Vector2i]:
	var art_rect := Rect2(
		Vector2(anchor.x * TILE_SIZE - texture_size.x / 2, anchor.y * TILE_SIZE - texture_size.y),
		Vector2(texture_size)
	)
	var result: Array[Vector2i] = []
	var left := floori(art_rect.position.x / TILE_SIZE)
	var top := floori(art_rect.position.y / TILE_SIZE)
	var right := ceili(art_rect.end.x / TILE_SIZE)
	var bottom := ceili(art_rect.end.y / TILE_SIZE)
	for y in range(top, bottom):
		for x in range(left, right):
			var cell := Vector2i(x, y)
			if _cell_is_floor(cell) and not _cell_has_collider(cell):
				if art_rect.intersects(Rect2(Vector2(cell * TILE_SIZE), Vector2.ONE * TILE_SIZE)):
					result.append(cell)
	return result


func _build_lighting() -> void:
	var zone := LIGHTING_ZONE_SCRIPT.new() as Area2D
	zone.name = "MachineHouseLightingZone"
	zone.set("profile", load("res://content/lighting/profiles/carrow_machine_house_interior.tres"))
	zone.set("profile_priority", 20)
	zone.position = Vector2(room_size * TILE_SIZE) * 0.5
	var zone_shape := CollisionShape2D.new()
	var zone_rect := RectangleShape2D.new()
	zone_rect.size = Vector2(room_size * TILE_SIZE) - Vector2.ONE * TILE_SIZE
	zone_shape.shape = zone_rect
	zone.add_child(zone_shape)
	add_child(zone)
	var light := LIGHT_RIG_SCENE.instantiate() as Node2D
	if light != null:
		light.name = "SwitchBankMaintenanceLight"
		light.position = Vector2(Vector2i(10, 2) * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5
		add_child(light)


func _build_actor_and_camera() -> void:
	var camera_node := Camera2D.new()
	camera_node.set_script(CAMERA_SCRIPT)
	camera = camera_node as CameraController
	camera.name = "Camera2D"
	camera.authored_map_bounds = Rect2(Vector2.ZERO, Vector2(room_size * TILE_SIZE))
	camera.enabled = true
	add_child(camera)
	camera.make_current()
	operator = OPERATOR_SCENE.instantiate() as CharacterBody2D
	operator.name = "Operator"
	add_child(operator)
	camera.operator_ref = operator
	camera.set_follow_target(operator)
	# Keep every A/B/C viewport on the real camera's shipped base profile;
	# room-dependent contextual auto-zoom would otherwise change the comparison.
	camera.auto_zoom_enabled = false
	camera.zoom = camera.base_zoom
	camera.target_zoom = camera.base_zoom
	camera._locked_zoom = camera.base_zoom


func _build_overlays() -> void:
	collider_overlay = _FixtureOverlay.new()
	collider_overlay.name = "PhysicsColliderOverlay"
	collider_overlay.z_index = 900
	collider_overlay.visible = false
	add_child(collider_overlay)
	grid_overlay = _FixtureOverlay.new()
	grid_overlay.name = "TileGridOverlay"
	grid_overlay.z_index = 899
	grid_overlay.visible = false
	add_child(grid_overlay)
	var canvas := CanvasLayer.new()
	canvas.name = "FixtureHUD"
	canvas.layer = 20
	add_child(canvas)
	values_label = Label.new()
	values_label.name = "ReadOnlyValues"
	values_label.position = Vector2(12, 10)
	values_label.size = Vector2(744, 68)
	values_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	values_label.add_theme_font_size_override("font_size", 12)
	values_label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.94, 1.0))
	values_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.025, 1.0))
	values_label.add_theme_constant_override("shadow_offset_x", 1)
	values_label.add_theme_constant_override("shadow_offset_y", 1)
	values_label.text = "1/2/3: ENTRY/CENTER/NORTH   R: RESET   F1: COLLIDERS   F2: GRID   F3: VALUES"
	canvas.add_child(values_label)
	_refresh_overlays()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_1 or key == KEY_2 or key == KEY_3:
		_teleport_to_waypoint(key - KEY_1)
	elif key == KEY_R:
		_teleport_to_waypoint(0)
	elif key == KEY_F1:
		_colliders_visible = not _colliders_visible
	elif key == KEY_F2:
		_grid_visible = not _grid_visible
	elif key == KEY_F3:
		values_label.visible = not values_label.visible
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh_overlays()


func _teleport_to_waypoint(index: int) -> void:
	_waypoint_index = clampi(index, 0, 2)
	var cell := waypoint_cell(_waypoint_index)
	operator.global_position = Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5
	operator.velocity = Vector2.ZERO
	if camera != null:
		camera.reset_smoothing()
		camera.global_position = operator.global_position
	_refresh_overlays()


func debug_teleport_to_waypoint(name: StringName) -> bool:
	var index := WAYPOINTS.find(name)
	if index < 0:
		return false
	_teleport_to_waypoint(index)
	return true


func waypoint_cell(index: int) -> Vector2i:
	match index:
		0:
			return Vector2i(room_size.x / 2, room_size.y - 3)
		1:
			return Vector2i(room_size.x / 2, room_size.y / 2)
		_:
			return Vector2i(room_size.x / 2, 7)


func get_fixture_snapshot() -> Dictionary:
	var size_px := room_size * TILE_SIZE
	var solid_cells: Array[Dictionary] = []
	for child in get_children():
		if child is StaticBody2D and child.has_meta("tile"):
			solid_cells.append({"tile": child.get_meta("tile"), "owner": child.get_meta("owner")})
	var art_records: Array[Dictionary] = []
	var art_root := get_node_or_null("ProductionArt") as Node2D
	if art_root != null:
		for child in art_root.get_children():
			if child is Sprite2D:
				var texture := (child as Sprite2D).texture
				var anchor: Vector2i = child.get_meta("fixture_anchor", Vector2i.ZERO)
				var rect := Rect2(
					Vector2(anchor.x * TILE_SIZE - texture.get_width() / 2, anchor.y * TILE_SIZE - texture.get_height()),
					Vector2(texture.get_size())
				)
				art_records.append({
					"name": child.name,
					"source": String(child.get_meta("fixture_source_path", "")),
					"anchor_tile": anchor,
					"native_pixel_size": texture.get_size(),
					"z_index": (child as Sprite2D).z_index,
					"scale": (child as Sprite2D).scale,
					"pixel_rect": rect,
					"walkable_cells_covered_by_art_rect": child.get_meta("fixture_walkable_overlap", []),
				})
		art_records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.name) < String(b.name))
	var collider_records: Array[Dictionary] = []
	for child in get_children():
		if child is StaticBody2D and child.has_meta("tile"):
			collider_records.append({"tile": child.get_meta("tile"), "owner": child.get_meta("owner")})
	var operator_shape := operator.get_node("CollisionShape2D") as CollisionShape2D
	var door_cells: Array[Vector2i] = []
	for x in range((room_size.x >> 1) - 2, (room_size.x >> 1) + 2):
		door_cells.append(Vector2i(x, room_size.y - 1))
	var aisle_cells: Array[Vector2i] = []
	for y in range(1, room_size.y - 1):
		for x in range((room_size.x >> 1) - 2, (room_size.x >> 1) + 2):
			aisle_cells.append(Vector2i(x, y))
	var operator_script := operator.get_script() as GDScript
	var operator_speed := float(operator_script.get_script_constant_map().get("SPEED", -1.0)) if operator_script != null else -1.0
	var camera_settings := {
		"zoom": camera.zoom,
		"base_zoom": camera.base_zoom,
		"auto_zoom_enabled": camera.auto_zoom_enabled,
		"authored_bounds": camera.authored_map_bounds,
		"viewport_size": get_viewport_rect().size,
		"operator_speed_px_per_sec": operator_speed,
		"operator_scale": operator.scale,
	}
	return {
		"variant_id": variant_id,
		"tile_size_px": TILE_SIZE,
		"grid_cells": room_size,
		"pixel_extent": size_px,
		"floor_cell_count": room_size.x * room_size.y,
		"perimeter_collision_cell_count": (room_size.x * 2) + ((room_size.y - 2) * 2) - 4,
		"equipment_rects": _resolved_equipment_rects(),
		"solid_cells": solid_cells,
		"collider_shape_count": collision_shapes.size(),
		"door_cells": door_cells,
		"aisle_cells": aisle_cells,
		"art_count": art_records.size(),
		"art": art_records,
		"storage_count": STORAGE_DEFINITIONS.size(),
		"storage": _storage_snapshot(),
		"operator_shape": {
			"type": operator_shape.shape.get_class(),
			"radius_px": (operator_shape.shape as CapsuleShape2D).radius if operator_shape.shape is CapsuleShape2D else 0.0,
			"height_px": (operator_shape.shape as CapsuleShape2D).height if operator_shape.shape is CapsuleShape2D else 0.0,
			"local_position_px": operator_shape.position,
			"scale": operator_shape.scale,
		},
		"operator_current_tile": (operator.global_position / TILE_SIZE).floor(),
		"waypoints": _waypoint_snapshot(),
		"camera": camera_settings,
	}


func _storage_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var storage_root := get_node_or_null("ArtBoundStorage") as Node2D
	if storage_root == null:
		return result
	for node in storage_root.get_children():
		result.append({
			"node": node.name,
			"storage_id": String(node.get("storage_id")),
			"position_px": node.position,
			"contents": (node.get("starting_resources") as Dictionary).duplicate(true),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.storage_id) < String(b.storage_id))
	return result


func _waypoint_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(3):
		var cell := waypoint_cell(index)
		result.append({"name": String(WAYPOINTS[index]), "tile": cell, "center_px": Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5})
	return result


func _refresh_overlays() -> void:
	if collider_overlay == null:
		return
	collider_overlay.visible = _colliders_visible
	collider_overlay.configure(self, room_size, collision_shapes, operator)
	grid_overlay.visible = _grid_visible
	grid_overlay.configure_grid(room_size, TILE_SIZE)
	if values_label != null:
		_update_values_label()


func _update_values_label() -> void:
	if values_label == null or operator == null or camera == null:
		return
	values_label.text = "%s  %d×%d cells / %d×%d px  |  floor %d / solids %d / art 13 / storage 3\nOperator tile %s  |  camera zoom %s\n1 ENTRY  2 CENTER  3 NORTH  |  R reset  |  F1 colliders  F2 grid  F3 values" % [
		variant_id, room_size.x, room_size.y, room_size.x * TILE_SIZE, room_size.y * TILE_SIZE,
		room_size.x * room_size.y, collision_shapes.size(), str((operator.global_position / TILE_SIZE).floor()), str(camera.zoom),
	]


func _is_perimeter(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == room_size.x - 1 or cell.y == room_size.y - 1


func _is_door_cell(cell: Vector2i) -> bool:
	return cell.y == room_size.y - 1 and cell.x >= (room_size.x >> 1) - 2 and cell.x < (room_size.x >> 1) + 2


func _cell_is_floor(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < room_size.x and cell.y < room_size.y


func _cell_has_collider(cell: Vector2i) -> bool:
	if _is_perimeter(cell) and not _is_door_cell(cell):
		return true
	for item in _resolved_equipment_rects():
		if (item.rect as Rect2i).has_point(cell):
			return true
	return false


class _FixtureOverlay extends Node2D:
	var _owner: CarrowMachineHouseScaleFixture
	var _size := Vector2i.ZERO
	var _tile := 32
	var _colliders: Array[CollisionShape2D] = []
	var _operator: CharacterBody2D

	func configure(owner_node: CarrowMachineHouseScaleFixture, size: Vector2i, colliders: Array[CollisionShape2D], actor: CharacterBody2D) -> void:
		_owner = owner_node
		_size = size
		_colliders = colliders
		_operator = actor
		queue_redraw()

	func configure_grid(size: Vector2i, tile_size: int) -> void:
		_size = size
		_tile = tile_size
		queue_redraw()

	func _draw() -> void:
		if _owner == null:
			var color := Color(0.87, 0.91, 0.96, 0.24)
			for x in range(_size.x + 1):
				draw_line(Vector2(x * _tile, 0), Vector2(x * _tile, _size.y * _tile), color, 1.0)
			for y in range(_size.y + 1):
				draw_line(Vector2(0, y * _tile), Vector2(_size.x * _tile, y * _tile), color, 1.0)
			return
		for shape_node in _colliders:
			if not is_instance_valid(shape_node) or not shape_node.shape is RectangleShape2D:
				continue
			var body := shape_node.get_parent() as StaticBody2D
			var color := Color(1.0, 0.34, 0.24, 0.9) if String(body.get_meta("owner", "")) == "perimeter" else Color(1.0, 0.76, 0.23, 0.9)
			var center := to_local(shape_node.global_position)
			draw_rect(Rect2(center - Vector2.ONE * _tile * 0.5, Vector2.ONE * _tile), color, false, 1.5)
		if _operator != null:
			var actor_shape := _operator.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if actor_shape != null and actor_shape.shape is CapsuleShape2D:
				var capsule := actor_shape.shape as CapsuleShape2D
				var center := to_local(actor_shape.global_position)
				var straight_half := maxf(0.0, capsule.height * 0.5 - capsule.radius)
				var actor_color := Color(0.24, 0.96, 0.58, 0.95)
				draw_arc(center + Vector2(0, straight_half), capsule.radius, 0.0, PI, 24, actor_color, 2.0)
				draw_arc(center - Vector2(0, straight_half), capsule.radius, PI, TAU, 24, actor_color, 2.0)
				draw_line(center + Vector2(-capsule.radius, -straight_half), center + Vector2(-capsule.radius, straight_half), actor_color, 2.0)
				draw_line(center + Vector2(capsule.radius, -straight_half), center + Vector2(capsule.radius, straight_half), actor_color, 2.0)
