extends Node2D
class_name GothicCompoundMap

const TILE_SIZE := 32.0
const TRAVEL_GATE_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_travel_gate.gd")
const GOTHIC_CONTEXT_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_sprite_context.gd")
const GOTHIC_CONFIG_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_config.gd")
const GOTHIC_GENERATOR_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_generator.gd")
const VAULT_STORAGE_SCENE := preload("res://game/actors/storage/vault_storage.tscn")
const MACHINE_HOUSE_DOOR_SCRIPT := preload("res://game/world/gothic_compound/carrow_machine_house_door.gd")
const LIGHTING_ZONE_SCRIPT := preload("res://game/world/lighting/lighting_zone_2d.gd")
const LIGHT_RIG_SCENE := preload("res://game/world/lighting/light_rig_2d.tscn")
const MACHINE_HOUSE_LIGHTING_PROFILE := preload("res://content/lighting/profiles/carrow_machine_house_interior.tres")
const MACHINE_HOUSE_SIZE := Vector2i(12, 8)
const MACHINE_HOUSE_LAYOUT := [
	"XXXXXXXXXXXX",
	"XRRR....SSSX",
	"XRRR....SSSX",
	"X..........X",
	"X..GGGGGG..X",
	"X..........X",
	"XLL......BBX",
	"XXXXXDDXXXXX",
]

@export var map_size_tiles: Vector2i = Vector2i(82, 60)
@export var world_seed: int = 947113
@export var entrance_tile: Vector2i = Vector2i(41, 44)
@export var return_gate_tile: Vector2i = Vector2i(41, 45)

var main_map: Node = null
var main_return_position: Vector2 = Vector2.ZERO

var _built := false
var _camera_bounds := Rect2()
var _yard_camera_bounds := Rect2()
var _machine_house_camera_bounds := Rect2()
var _machine_house_interior_rect := Rect2()
var _context: Node2D = null
var _return_gate: Node2D = null
var _machine_house_root: Node2D = null
var _machine_house_exterior_return_position := Vector2.ZERO
var _operator_inside_machine_house := false
var _structure_sites: Dictionary = {}


func _ready() -> void:
	add_to_group("connected_map")
	add_to_group("gothic_compound_map")
	add_to_group("carrow_yard_map")
	add_to_group("environment_region_provider")
	_build_once()


func _process(_delta: float) -> void:
	_update_depth_sort()


func configure_connection(p_main_map: Node, p_main_return_position: Vector2) -> void:
	main_map = p_main_map
	main_return_position = p_main_return_position


func get_entry_position() -> Vector2:
	return to_global(_tile_to_local(entrance_tile))


func get_return_gate_position() -> Vector2:
	return to_global(_tile_to_local(return_gate_tile))


func get_camera_bounds() -> Rect2:
	var bounds := _machine_house_camera_bounds if _operator_inside_machine_house else _yard_camera_bounds
	return Rect2(to_global(bounds.position), bounds.size)


func enter_from_main(actor: Node) -> void:
	if actor is Node2D:
		(actor as Node2D).global_position = get_entry_position()
	_refresh_camera(self, actor)


func return_to_main(actor: Node) -> void:
	_operator_inside_machine_house = false
	if actor is Node2D:
		(actor as Node2D).global_position = main_return_position
	_refresh_camera(main_map, actor)


func _build_once() -> void:
	if _built:
		return
	_built = true
	_camera_bounds = Rect2(
		Vector2(-TILE_SIZE * 2.0, -TILE_SIZE * 2.0),
		Vector2(float(map_size_tiles.x + 4) * TILE_SIZE, float(map_size_tiles.y + 4) * TILE_SIZE)
	)
	_yard_camera_bounds = _camera_bounds
	_build_blueprint_compound()
	_add_return_gate()


func _build_blueprint_compound() -> void:
	var backdrop := Polygon2D.new()
	backdrop.name = "AshWastesBackdrop"
	backdrop.color = Color(0.08, 0.075, 0.07, 1.0)
	backdrop.z_as_relative = false
	backdrop.z_index = -200
	backdrop.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(float(map_size_tiles.x) * TILE_SIZE, 0.0),
		Vector2(float(map_size_tiles.x) * TILE_SIZE, float(map_size_tiles.y) * TILE_SIZE),
		Vector2(0.0, float(map_size_tiles.y) * TILE_SIZE),
	])
	add_child(backdrop)

	_context = GOTHIC_CONTEXT_SCRIPT.new() as Node2D
	_context.name = "BlueprintContext"
	_context.set("tile_size", int(TILE_SIZE))
	_context.set("map_size", map_size_tiles)
	_context.set("world_seed", world_seed)
	add_child(_context)

	var config := GOTHIC_CONFIG_SCRIPT.new()
	config.tile_size = int(TILE_SIZE)
	config.min_size = Vector2i(46, 34)
	config.max_size = Vector2i(58, 42)
	config.margin_from_map_edge = 6
	var generator := GOTHIC_GENERATOR_SCRIPT.new(config)
	var result: Variant = generator.call("generate", _context)
	if result != null and result.get("ok"):
		_structure_sites = (result.get("structure_sites") as Dictionary).duplicate(true)
		var gate_cell: Vector2i = result.get("gate_cell")
		entrance_tile = gate_cell + Vector2i(0, -2)
		return_gate_tile = gate_cell + Vector2i(0, -1)
		_add_east_machine_house_interior(result)
	else:
		push_warning("[GothicCompoundMap] Blueprint generation failed; using default travel positions")


func _add_return_gate() -> void:
	_return_gate = TRAVEL_GATE_SCRIPT.new() as Node2D
	if _return_gate == null:
		return
	_return_gate.name = "ReturnToMainMapGate"
	_return_gate.call("configure", self, 1, "LEAVE CARROW YARD")
	_return_gate.position = _tile_to_local(return_gate_tile)
	add_child(_return_gate)


func _add_east_machine_house_interior(result: Variant) -> void:
	if VAULT_STORAGE_SCENE == null or result == null:
		return
	var structure_sites := result.get("structure_sites") as Dictionary
	var machine_site := structure_sites.get("machine_house", {}) as Dictionary
	if machine_site.is_empty():
		push_warning("[CarrowYard] East Machine House was not placed; interior unavailable")
		return
	_machine_house_root = Node2D.new()
	_machine_house_root.name = "EastMachineHouseInterior"
	_machine_house_root.add_to_group("carrow_machine_house_interior")
	add_child(_machine_house_root)

	var room_origin := Vector2i(map_size_tiles.x + 8, 8)
	_machine_house_interior_rect = Rect2(
		_tile_to_local(room_origin),
		Vector2(MACHINE_HOUSE_SIZE) * TILE_SIZE
	)
	_machine_house_camera_bounds = _machine_house_interior_rect.grow(TILE_SIZE * 2.0)
	_add_machine_house_floor(room_origin)
	_add_machine_house_layout(room_origin)
	_add_machine_house_storage("carrow_service_parts_locker", "Service Parts Locker", room_origin + Vector2i(3, 6), {&"ruin_scrap": 52, &"structural_alloy": 4})
	_add_machine_house_storage("carrow_structural_spares_rack", "Structural Spares Rack", room_origin + Vector2i(6, 6), {&"structural_alloy": 14, &"ruin_scrap": 16})
	_add_machine_house_storage("carrow_power_components_cabinet", "Power Components Cabinet", room_origin + Vector2i(8, 5), {&"power_components": 4, &"capacitor_dust": 3, &"ruin_scrap": 10})
	_add_machine_house_lighting(room_origin)
	_add_machine_house_doors(machine_site, room_origin)


func _add_machine_house_floor(room_origin: Vector2i) -> void:
	var floor := Polygon2D.new()
	floor.name = "HardenedMachineFloor"
	floor.color = Color(0.105, 0.11, 0.115, 1.0)
	floor.z_as_relative = false
	floor.z_index = -40
	var top_left := _tile_to_local(room_origin)
	var extent := Vector2(MACHINE_HOUSE_SIZE) * TILE_SIZE
	floor.polygon = PackedVector2Array([
		top_left,
		top_left + Vector2(extent.x, 0.0),
		top_left + extent,
		top_left + Vector2(0.0, extent.y),
	])
	_machine_house_root.add_child(floor)


func _add_machine_house_layout(room_origin: Vector2i) -> void:
	for y in range(MACHINE_HOUSE_LAYOUT.size()):
		var row: String = MACHINE_HOUSE_LAYOUT[y]
		for x in range(row.length()):
			var symbol := row.substr(x, 1)
			if symbol == ".":
				continue
			var cell := room_origin + Vector2i(x, y)
			_add_machine_house_cell_visual(cell, symbol)
			if symbol in ["X", "R", "S", "L", "B"]:
				_add_machine_house_cell_collision(cell, symbol)


func _add_machine_house_cell_visual(cell: Vector2i, symbol: String) -> void:
	var colors := {
		"X": Color(0.16, 0.17, 0.18, 1.0),
		"R": Color(0.20, 0.24, 0.25, 1.0),
		"S": Color(0.24, 0.22, 0.18, 1.0),
		"G": Color(0.11, 0.14, 0.15, 1.0),
		"L": Color(0.19, 0.20, 0.19, 1.0),
		"B": Color(0.24, 0.19, 0.14, 1.0),
		"D": Color(0.42, 0.31, 0.16, 1.0),
	}
	var visual := Polygon2D.new()
	visual.name = "Cell%s_%d_%d" % [symbol, cell.x, cell.y]
	visual.color = colors.get(symbol, Color.WHITE)
	visual.z_as_relative = false
	visual.z_index = -35 if symbol == "G" or symbol == "D" else -20
	var top_left := _tile_to_local(cell)
	visual.polygon = PackedVector2Array([
		top_left,
		top_left + Vector2(TILE_SIZE, 0.0),
		top_left + Vector2(TILE_SIZE, TILE_SIZE),
		top_left + Vector2(0.0, TILE_SIZE),
	])
	_machine_house_root.add_child(visual)


func _add_machine_house_cell_collision(cell: Vector2i, symbol: String) -> void:
	var body := StaticBody2D.new()
	body.name = "Boundary%s_%d_%d" % [symbol, cell.x, cell.y]
	body.position = _tile_to_local(cell) + Vector2.ONE * TILE_SIZE * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2.ONE * TILE_SIZE
	shape.shape = rectangle
	body.add_child(shape)
	_machine_house_root.add_child(body)


func _add_machine_house_storage(storage_id: String, display_name: String, tile: Vector2i, starting_resources: Dictionary) -> void:
	var storage := VAULT_STORAGE_SCENE.instantiate()
	if storage == null:
		return
	storage.name = storage_id.to_pascal_case()
	storage.set("storage_id", StringName(storage_id))
	storage.set("display_name", display_name)
	storage.set("starting_resources", starting_resources)
	if storage is Node2D:
		(storage as Node2D).position = _tile_to_local(tile)
	_machine_house_root.add_child(storage)


func _add_machine_house_lighting(room_origin: Vector2i) -> void:
	var zone := LIGHTING_ZONE_SCRIPT.new() as LightingZone2D
	zone.name = "MachineHouseLightingZone"
	zone.profile = MACHINE_HOUSE_LIGHTING_PROFILE
	zone.profile_priority = 20
	zone.position = _tile_to_local(room_origin) + Vector2(MACHINE_HOUSE_SIZE) * TILE_SIZE * 0.5
	var zone_shape := CollisionShape2D.new()
	var zone_rectangle := RectangleShape2D.new()
	zone_rectangle.size = Vector2(MACHINE_HOUSE_SIZE) * TILE_SIZE - Vector2.ONE * TILE_SIZE
	zone_shape.shape = zone_rectangle
	zone.add_child(zone_shape)
	_machine_house_root.add_child(zone)

	var rig := LIGHT_RIG_SCENE.instantiate() as LightRig2D
	if rig != null:
		rig.name = "SwitchBankMaintenanceLight"
		rig.position = _tile_to_local(room_origin + Vector2i(8, 2)) + Vector2.ONE * TILE_SIZE * 0.5
		rig.light_color = Color(1.0, 0.72, 0.42, 1.0)
		rig.energy = 0.9
		rig.glow_scale = 1.8
		rig.shadows_enabled = true
		_machine_house_root.add_child(rig)


func _add_machine_house_doors(machine_site: Dictionary, room_origin: Vector2i) -> void:
	var machine_cell: Vector2i = machine_site.get("cell", Vector2i.ZERO)
	var footprint: Vector2i = machine_site.get("footprint", Vector2i(7, 8))
	_machine_house_exterior_return_position = _tile_to_local(
		machine_cell + Vector2i(int(footprint.x / 2), footprint.y + 2)
	)

	var exterior_door := MACHINE_HOUSE_DOOR_SCRIPT.new() as CarrowMachineHouseDoor
	exterior_door.name = "EnterEastMachineHouse"
	exterior_door.configure(self, CarrowMachineHouseDoor.TravelMode.ENTER_MACHINE_HOUSE, "ENTER EAST MACHINE HOUSE")
	exterior_door.position = _tile_to_local(machine_cell) + Vector2(float(footprint.x) * TILE_SIZE * 0.5, float(footprint.y) * TILE_SIZE)
	add_child(exterior_door)

	var interior_door := MACHINE_HOUSE_DOOR_SCRIPT.new() as CarrowMachineHouseDoor
	interior_door.name = "LeaveEastMachineHouse"
	interior_door.configure(self, CarrowMachineHouseDoor.TravelMode.LEAVE_MACHINE_HOUSE, "LEAVE EAST MACHINE HOUSE")
	interior_door.position = _tile_to_local(room_origin + Vector2i(6, 7))
	_machine_house_root.add_child(interior_door)


func enter_machine_house(actor: Node) -> void:
	if _machine_house_interior_rect.size == Vector2.ZERO:
		return
	_operator_inside_machine_house = true
	if actor is Node2D:
		(actor as Node2D).global_position = to_global(
			_machine_house_interior_rect.position
			+ Vector2(5.5 * TILE_SIZE, 6.25 * TILE_SIZE)
		)
	_refresh_camera(self, actor)


func leave_machine_house(actor: Node) -> void:
	_operator_inside_machine_house = false
	if actor is Node2D:
		(actor as Node2D).global_position = to_global(_machine_house_exterior_return_position)
	_refresh_camera(self, actor)


func get_environment_region_at_global(world_position: Vector2) -> Dictionary:
	var local_position := to_local(world_position)
	if _machine_house_interior_rect.has_point(local_position):
		return {
			"contains": true,
			"indoor": true,
			"environment_exposure": 0.10,
			"weather_exposure": 0.0,
		}
	if not _yard_camera_bounds.has_point(local_position):
		return {}
	return {
		"contains": true,
		"indoor": false,
		"environment_exposure": 1.0,
		"weather_exposure": 1.0,
	}


func get_machine_house_debug_state() -> Dictionary:
	return {
		"canonical_id": "carrow_yard",
		"interior_rect": _machine_house_interior_rect,
		"layout": MACHINE_HOUSE_LAYOUT.duplicate(),
		"inside": _operator_inside_machine_house,
		"exterior_return_position": _machine_house_exterior_return_position,
		"has_entry_door": get_node_or_null("EnterEastMachineHouse") != null,
		"has_exit_door": _machine_house_root != null and _machine_house_root.get_node_or_null("LeaveEastMachineHouse") != null,
		"structure_sites": _structure_sites.duplicate(true),
	}


func _tile_to_local(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _refresh_camera(map_instance: Node, actor: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera != null and actor is Node2D:
		camera.global_position = (actor as Node2D).global_position


func _update_depth_sort() -> void:
	if _context == null or not _context.has_method("update_depth_sort"):
		return
	var operator := get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	if operator != null:
		_context.call("update_depth_sort", operator)
