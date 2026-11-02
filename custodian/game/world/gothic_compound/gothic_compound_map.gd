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
const MACHINE_HOUSE_FLOOR_ROOT := "res://content/tiles/interiors/runtime/"
const MACHINE_HOUSE_STRUCTURE_ROOT := "res://content/sprites/environment/structure/carrow_machine_house/runtime/"
const MACHINE_HOUSE_FLOOR_STATES := [
	"slab_plain_01", "slab_plain_01", "slab_plain_01", "slab_worn_01",
	"slab_worn_01", "slab_oil_01", "slab_plain_01", "slab_plain_01",
]
const MACHINE_HOUSE_SIZE := Vector2i(14, 10)
const MACHINE_HOUSE_LAYOUT := [
	"XXXXXXXXXXXXXX",
	"X............X",
	"XRRR......SSSX",
	"XRRR......SSSX",
	"XL..........CX",
	"XW..........PX",
	"X............X",
	"X............X",
	"X............X",
	"XXXXXDDDXXXXX",
]
const WEST_DRAFT_HOUSE_SIZE := Vector2i(12, 10)
const WEST_DRAFT_HOUSE_LAYOUT := [
	"XXXXXXXXXXXX",
	"X..........X",
	"XFFFF..HHHHX",
	"XFFFF..HHHHX",
	"X..........X",
	"XVV.......CX",
	"XVV......PPX",
	"X..........X",
	"X..........X",
	"XXXXXDDDXXXX",
]
const OPERATIONS_HOUSE_SIZE := Vector2i(20, 14)
const OPERATIONS_HOUSE_LAYOUT := [
	"XXXXXXXXXXXXXXXXXXXX",
	"X..................X",
	"XCCCCCCC.....RRRRRRX",
	"XCCCCCCC.....RRRRRRX",
	"X..................X",
	"XKKK.......SSS.....X",
	"XKKK.......SSS.....X",
	"X..................X",
	"X..................X",
	"XWWWW..............X",
	"XWWWW..............X",
	"X..................X",
	"X..................X",
	"XXXXXXXXXDDDXXXXXXXX",
]
const INTERIOR_ROOM_DEFINITIONS := {
	"east_machine_house": {
		"site_id": "machine_house",
		"node_name": "EastMachineHouseInterior",
		"size": MACHINE_HOUSE_SIZE,
		"layout": MACHINE_HOUSE_LAYOUT,
		"legacy_short_bottom_row": true,
		"origin_offset": Vector2i(8, 8),
		"spawn_offset": Vector2(6.5, 8.25),
		"exit_cell": Vector2i(6, 9),
		"profile_path": "res://content/lighting/profiles/carrow_machine_house_interior.tres",
		"environment_exposure": 0.10,
		"weather_exposure": 0.0,
		"floor_states": MACHINE_HOUSE_FLOOR_STATES,
	},
	"west_draft_house": {
		"site_id": "west_draft_house",
		"node_name": "WestDraftHouseInterior",
		"size": WEST_DRAFT_HOUSE_SIZE,
		"layout": WEST_DRAFT_HOUSE_LAYOUT,
		"origin_offset": Vector2i(8, MACHINE_HOUSE_SIZE.y + 15),
		"spawn_offset": Vector2(6.5, 8.25),
		"exit_cell": Vector2i(6, 9),
		"profile_path": "res://content/lighting/profiles/carrow_machine_house_interior.tres",
		"environment_exposure": 0.10,
		"weather_exposure": 0.0,
		"floor_states": MACHINE_HOUSE_FLOOR_STATES,
	},
	"operations_house": {
		"site_id": "operations_house",
		"node_name": "OperationsHouseInterior",
		"size": OPERATIONS_HOUSE_SIZE,
		"layout": OPERATIONS_HOUSE_LAYOUT,
		"origin_offset": Vector2i(8, 40),
		"spawn_offset": Vector2(9.5, 12.25),
		"exit_cell": Vector2i(10, 13),
		"profile_path": "res://content/lighting/profiles/carrow_operations_house_interior.tres",
		"environment_exposure": 0.10,
		"weather_exposure": 0.0,
		"floor_states": MACHINE_HOUSE_FLOOR_STATES,
	},
}

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
var _interior_rooms: Dictionary = {}
var active_interior_id: StringName = &""
var _active_interior_actor_id := 0
var _structure_sites: Dictionary = {}
var _travel_route_active := false
var _travel_gates: Array[WeakRef] = []


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


func is_travel_route_active() -> bool:
	return _travel_route_active


func register_travel_gate(gate: Node) -> void:
	if gate == null or not is_instance_valid(gate):
		return
	for reference in _travel_gates:
		if reference.get_ref() == gate:
			if _travel_route_active and gate.has_method("set_presentation_state"):
				gate.call("set_presentation_state", 3)
			return
	_travel_gates.append(weakref(gate))
	if _travel_route_active and gate.has_method("set_presentation_state"):
		gate.call("set_presentation_state", 3)


func activate_travel_route() -> void:
	_travel_route_active = true
	var alive: Array[WeakRef] = []
	for reference in _travel_gates:
		var gate := reference.get_ref() as Node
		if not is_instance_valid(gate):
			continue
		alive.append(reference)
		if gate.has_method("set_presentation_state"):
			gate.call("set_presentation_state", 3)
	_travel_gates = alive


func get_entry_position() -> Vector2:
	return to_global(_tile_to_local(entrance_tile))


func get_return_gate_position() -> Vector2:
	return to_global(_tile_to_local(return_gate_tile))


func get_camera_bounds() -> Rect2:
	var room := _interior_rooms.get(String(active_interior_id), {}) as Dictionary
	var bounds: Rect2 = room.get("camera_bounds", _yard_camera_bounds)
	return Rect2(to_global(bounds.position), bounds.size)


func enter_from_main(actor: Node) -> void:
	active_interior_id = &""
	_active_interior_actor_id = 0
	_set_main_procgen_backdrop_isolated(true)
	if actor is Node2D:
		(actor as Node2D).global_position = get_entry_position()
	_refresh_camera(self, actor)


func return_to_main(actor: Node) -> void:
	active_interior_id = &""
	_active_interior_actor_id = 0
	_set_main_procgen_backdrop_isolated(false)
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
		_add_registered_interiors(result)
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


func _add_registered_interiors(result: Variant) -> void:
	_add_east_machine_house_interior(result)
	_add_west_draft_house_interior(result)
	_add_operations_house_interior(result)


func _interior_definition(room_id: StringName) -> Dictionary:
	var definition := (INTERIOR_ROOM_DEFINITIONS.get(String(room_id), {}) as Dictionary).duplicate(true)
	if definition.is_empty():
		return {}
	if room_id == &"east_machine_house":
		definition["art"] = _machine_house_art()
		definition["resource_bindings"] = [
			{"id": "carrow_service_parts_locker", "display_name": "Service Parts Locker", "tile_offset": Vector2i(1, 5), "resources": {&"ruin_scrap": 52, &"structural_alloy": 4}, "art_name": "PartsLocker"},
			{"id": "carrow_structural_spares_rack", "display_name": "Structural Spares Rack", "tile_offset": Vector2i(4, 5), "resources": {&"structural_alloy": 14, &"ruin_scrap": 16}, "art_name": "ReplacementModules"},
			{"id": "carrow_power_components_cabinet", "display_name": "Power Components Cabinet", "tile_offset": Vector2i(12, 6), "resources": {&"power_components": 4, &"capacitor_dust": 3, &"ruin_scrap": 10}, "art_name": "PowerCabinet"},
		]
		definition["entry_door_name"] = "EnterEastMachineHouse"
		definition["exit_door_name"] = "LeaveEastMachineHouse"
		definition["entry_prompt"] = "ENTER EAST MACHINE HOUSE"
		definition["exit_prompt"] = "LEAVE EAST MACHINE HOUSE"
		definition["exit_cell"] = Vector2i(6, 9)
	elif room_id == &"west_draft_house":
		definition["art"] = _west_draft_house_art()
		definition["resource_bindings"] = [
			{"id": "carrow_draft_filter_cradle", "display_name": "Service Filter Cradle", "tile_offset": Vector2i(2, 7), "resources": {&"ruin_scrap": 18, &"structural_alloy": 2}, "art_name": "FilterCradle"},
			{"id": "carrow_emergency_parts_rack", "display_name": "Emergency Parts Rack", "tile_offset": Vector2i(9, 7), "resources": {&"structural_alloy": 6, &"power_components": 1, &"ruin_scrap": 8}, "art_name": "EmergencyPartsRack"},
		]
		definition["entry_door_name"] = "EnterWestDraftHouse"
		definition["exit_door_name"] = "LeaveWestDraftHouse"
		definition["entry_prompt"] = "ENTER WEST DRAFT HOUSE"
		definition["exit_prompt"] = "LEAVE WEST DRAFT HOUSE"
	elif room_id == &"operations_house":
		definition["art"] = _operations_house_art()
		definition["resource_bindings"] = [
			{"id": "carrow_operations_emergency_spares", "display_name": "Emergency Spares Rack", "tile_offset": Vector2i(11, 5), "resources": {&"ruin_scrap": 22, &"structural_alloy": 3, &"power_components": 1}, "art_name": "EmergencySparesRack"},
		]
		definition["entry_door_name"] = "EnterOperationsHouse"
		definition["exit_door_name"] = "LeaveOperationsHouse"
		definition["entry_prompt"] = "ENTER OPERATIONS HOUSE"
		definition["exit_prompt"] = "LEAVE OPERATIONS HOUSE"
	else:
		return {}
	return definition


func _add_east_machine_house_interior(result: Variant) -> void:
	if VAULT_STORAGE_SCENE == null or result == null:
		return
	var structure_sites := result.get("structure_sites") as Dictionary
	var machine_site := structure_sites.get("machine_house", {}) as Dictionary
	var definition := _interior_definition(&"east_machine_house")
	if not _is_valid_structure_site(machine_site) or not _is_valid_interior_definition(definition):
		if not machine_site.is_empty():
			push_warning("[CarrowYard] East Machine House site or room definition is invalid; interior unavailable")
		return
	if not _interior_assets_available(definition, definition.art as Array[Dictionary]):
		push_warning("[CarrowYard] East Machine House registered art is incomplete; interior unavailable")
		return
	var room_origin := Vector2i(map_size_tiles.x + int(definition.origin_offset.x), int(definition.origin_offset.y))
	var room_rect := Rect2(_tile_to_local(room_origin), Vector2(MACHINE_HOUSE_SIZE) * TILE_SIZE)
	var room_camera_bounds := room_rect.grow(TILE_SIZE * 2.0)
	if not _interior_bounds_available(room_rect, room_camera_bounds):
		push_warning("[CarrowYard] East Machine House bounds overlap an existing interior; interior unavailable")
		return
	_machine_house_root = Node2D.new()
	_machine_house_root.name = "EastMachineHouseInterior"
	_machine_house_root.add_to_group("carrow_machine_house_interior")
	add_child(_machine_house_root)

	_machine_house_interior_rect = room_rect
	_machine_house_camera_bounds = room_camera_bounds
	_add_machine_house_floor(room_origin)
	_build_interior_art(_machine_house_root, room_origin, definition.art as Array[Dictionary], false)
	_add_machine_house_layout(room_origin)
	_add_definition_storage(_machine_house_root, room_origin, definition)
	_add_machine_house_lighting(room_origin)
	_add_definition_doors(_machine_house_root, &"east_machine_house", machine_site, room_origin, definition)
	_register_interior_room(&"east_machine_house", _machine_house_root, room_origin, machine_site)


func _add_west_draft_house_interior(result: Variant) -> void:
	if VAULT_STORAGE_SCENE == null or result == null:
		return
	var site := _structure_sites.get("west_draft_house", {}) as Dictionary
	var definition := _interior_definition(&"west_draft_house")
	if not _is_valid_structure_site(site) or not _is_valid_interior_definition(definition):
		if not site.is_empty():
			push_warning("[CarrowYard] West Draft House site or room definition is invalid; interior unavailable")
		return
	if not _interior_assets_available(definition, definition.art as Array[Dictionary]):
		push_warning("[CarrowYard] West Draft House registered art is incomplete; interior unavailable")
		return
	var room_origin := Vector2i(map_size_tiles.x + int(definition.origin_offset.x), int(definition.origin_offset.y))
	var room_size: Vector2i = definition.size
	var room_rect := Rect2(_tile_to_local(room_origin), Vector2(room_size) * TILE_SIZE)
	var camera_bounds := room_rect.grow(TILE_SIZE * 2.0)
	if not _interior_bounds_available(room_rect, camera_bounds):
		push_warning("[CarrowYard] West Draft House bounds overlap an existing interior; interior unavailable")
		return
	var root := Node2D.new()
	root.name = String(definition.node_name)
	root.add_to_group("carrow_named_interior")
	root.add_to_group("carrow_west_draft_house_interior")
	add_child(root)
	_build_interior_floor(root, room_origin, room_size, "WestDraftHouse", definition.floor_states)
	var art_count := _build_interior_art(root, room_origin, definition.art as Array[Dictionary], true)
	if art_count != (definition.art as Array).size():
		root.queue_free()
		return
	_build_interior_layout(root, room_origin, definition.layout)
	_add_definition_storage(root, room_origin, definition)
	_add_interior_lighting(root, definition, room_origin, "WestDraftHouse", true)
	_add_definition_doors(root, &"west_draft_house", site, room_origin, definition)
	_register_interior_room(&"west_draft_house", root, room_origin, site)


func _add_operations_house_interior(result: Variant) -> void:
	if VAULT_STORAGE_SCENE == null or result == null:
		return
	var site := _structure_sites.get("operations_house", {}) as Dictionary
	var definition := _interior_definition(&"operations_house")
	if not _is_valid_structure_site(site) or not _is_valid_interior_definition(definition):
		if not site.is_empty():
			push_warning("[CarrowYard] Operations House site or room definition is invalid; interior unavailable")
		return
	if not _interior_assets_available(definition, definition.art as Array[Dictionary]):
		push_warning("[CarrowYard] Operations House registered art is incomplete; interior unavailable")
		return
	var room_origin := Vector2i(map_size_tiles.x + int(definition.origin_offset.x), int(definition.origin_offset.y))
	var room_size: Vector2i = definition.size
	var room_rect := Rect2(_tile_to_local(room_origin), Vector2(room_size) * TILE_SIZE)
	var camera_bounds := room_rect.grow(TILE_SIZE * 2.0)
	if not _interior_bounds_available(room_rect, camera_bounds):
		push_warning("[CarrowYard] Operations House bounds overlap an existing interior; interior unavailable")
		return
	var interior_root := Node2D.new()
	interior_root.name = String(definition.node_name)
	interior_root.add_to_group("carrow_named_interior")
	interior_root.add_to_group("carrow_operations_house_interior")
	add_child(interior_root)
	_build_interior_floor(interior_root, room_origin, room_size, "OperationsHouse", definition.floor_states)
	var art_count := _build_interior_art(interior_root, room_origin, definition.art as Array[Dictionary], true)
	if art_count != (definition.art as Array).size():
		interior_root.queue_free()
		return
	_build_interior_layout(interior_root, room_origin, definition.layout)
	_add_definition_storage(interior_root, room_origin, definition)
	_add_operations_house_lighting(interior_root, definition, room_origin)
	_add_definition_doors(interior_root, &"operations_house", site, room_origin, definition)
	_register_interior_room(&"operations_house", interior_root, room_origin, site)


func _operations_house_art() -> Array[Dictionary]:
	return [
		{"name": "NorthControlBay", "path": "walls/wall_carrow_control_bay_01.png", "cell": Vector2i(4, 2), "z": -18},
		{"name": "NorthRecordsWall", "path": "walls/wall_carrow_wall_run_panelled_long_01.png", "cell": Vector2i(15, 2), "z": -18},
		{"name": "DispatchRelayBank", "path": "props/carrow_machine_house_relay_bank.png", "cell": Vector2i(4, 3), "z": -12},
		{"name": "DispatchWorkbench", "path": "props/carrow_machine_house_workbench.png", "cell": Vector2i(2, 5), "z": -10},
		{"name": "EmergencySparesRack", "path": "props/carrow_machine_house_replacement_modules.png", "cell": Vector2i(11, 5), "z": -10},
		{"name": "MunicipalRecordsBoard", "path": "props/carrow_machine_house_tool_board.png", "cell": Vector2i(15, 3), "z": -12},
		{"name": "WestLogisticsCabinet", "path": "props/carrow_machine_house_service_cabinet.png", "cell": Vector2i(2, 9), "z": -10},
		{"name": "ServiceCart", "path": "props/carrow_machine_house_maintenance_cart.png", "cell": Vector2i(3, 10), "z": -9},
	]


func _add_operations_house_lighting(root: Node2D, definition: Dictionary, room_origin: Vector2i) -> void:
	_add_interior_lighting(root, definition, room_origin, "OperationsHouse", true)
	var amber_light := root.get_node_or_null("DraftHouseServiceLight") as LightRig2D
	if amber_light != null:
		amber_light.name = "DispatchDeskPracticalLight"
		amber_light.position = _tile_to_local(room_origin + Vector2i(5, 7)) + Vector2.ONE * TILE_SIZE * 0.5
	var status_light := root.get_node_or_null("ColdDeadVentLight") as LightRig2D
	if status_light != null:
		status_light.name = "NorthStatusPanelLight"
		status_light.position = _tile_to_local(room_origin + Vector2i(15, 3)) + Vector2.ONE * TILE_SIZE * 0.5
		status_light.light_color = Color(0.55, 0.69, 0.82, 1.0)
		status_light.energy = 0.10
		status_light.glow_scale = 0.7


func _add_machine_house_floor(room_origin: Vector2i) -> void:
	_build_interior_floor(_machine_house_root, room_origin, MACHINE_HOUSE_SIZE, "MachineHouse", MACHINE_HOUSE_FLOOR_STATES)


func _build_interior_floor(root: Node2D, room_origin: Vector2i, room_size: Vector2i, name_prefix: String, floor_states: Array) -> void:
	if root == null:
		return
	var backing := Polygon2D.new()
	backing.name = "%sInteriorBacking" % name_prefix
	backing.color = Color(0.035, 0.038, 0.042, 1.0)
	backing.z_as_relative = false
	backing.z_index = -42
	var backing_rect := Rect2(
		_tile_to_local(room_origin) - Vector2.ONE * TILE_SIZE * 1.5,
		Vector2(room_size) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 3.0
	)
	backing.polygon = PackedVector2Array([
		backing_rect.position,
		backing_rect.position + Vector2(backing_rect.size.x, 0.0),
		backing_rect.end,
		backing_rect.position + Vector2(0.0, backing_rect.size.y),
	])
	root.add_child(backing)
	var floor := Polygon2D.new()
	floor.name = "HardenedMachineFloor" if name_prefix == "MachineHouse" else "%sFloor" % name_prefix
	floor.color = Color(0.105, 0.11, 0.115, 1.0)
	floor.z_as_relative = false
	floor.z_index = -40
	var top_left := _tile_to_local(room_origin)
	var extent := Vector2(room_size) * TILE_SIZE
	floor.polygon = PackedVector2Array([
		top_left,
		top_left + Vector2(extent.x, 0.0),
		top_left + extent,
		top_left + Vector2(0.0, extent.y),
	])
	root.add_child(floor)
	var floor_tiles := Node2D.new()
	floor_tiles.name = "CarrowFloorTiles"
	floor_tiles.z_index = -39
	root.add_child(floor_tiles)
	if floor_states.is_empty():
		return
	for y in range(room_size.y):
		for x in range(room_size.x):
			var state: String = String(floor_states[(x * 3 + y * 5) % floor_states.size()])
			var sprite := Sprite2D.new()
			sprite.name = "Floor_%02d_%02d" % [x, y]
			sprite.texture = load(MACHINE_HOUSE_FLOOR_ROOT + "floor_carrow_%s_32.png" % state) as Texture2D
			sprite.position = _tile_to_local(room_origin + Vector2i(x, y)) + Vector2.ONE * TILE_SIZE * 0.5
			floor_tiles.add_child(sprite)


func _add_machine_house_production_art(room_origin: Vector2i) -> void:
	_build_interior_art(_machine_house_root, room_origin, _machine_house_art(), false)


func _machine_house_art() -> Array[Dictionary]:
	return [
		{"name": "NorthWallPanelled", "path": "walls/wall_carrow_wall_run_panelled_long_01.png", "cell": Vector2i(4, 2), "z": -18},
		{"name": "NorthWallConduit", "path": "walls/wall_carrow_wall_run_conduit_long_01.png", "cell": Vector2i(10, 2), "z": -18},
		{"name": "WestWall", "path": "walls/wall_carrow_pillar_lit_01.png", "cell": Vector2i(1, 5), "z": -17},
		{"name": "EastWall", "path": "walls/wall_carrow_pillar_plain_02.png", "cell": Vector2i(13, 5), "z": -17},
		{"name": "SouthDoorway", "path": "walls/wall_carrow_doorframe_recessed_01.png", "cell": Vector2i(6, 10), "z": -16},
		{"name": "RelayBank", "path": "props/carrow_machine_house_relay_bank.png", "cell": Vector2i(3, 3), "z": -12},
		{"name": "Switchgear", "path": "props/carrow_machine_house_switchgear.png", "cell": Vector2i(11, 3), "z": -12},
		{"name": "PartsLocker", "path": "props/carrow_machine_house_parts_locker.png", "cell": Vector2i(1, 5), "z": -10},
		{"name": "Workbench", "path": "props/carrow_machine_house_workbench.png", "cell": Vector2i(2, 6), "z": -10},
		{"name": "ServiceCabinet", "path": "props/carrow_machine_house_service_cabinet.png", "cell": Vector2i(4, 6), "z": -10},
		{"name": "ReplacementModules", "path": "props/carrow_machine_house_replacement_modules.png", "cell": Vector2i(4, 5), "z": -10},
		{"name": "ConduitJunction", "path": "props/carrow_machine_house_conduit_junction.png", "cell": Vector2i(12, 4), "z": -10},
		{"name": "PowerCabinet", "path": "props/carrow_machine_house_power_cabinet.png", "cell": Vector2i(12, 6), "z": -10},
	]


func _west_draft_house_art() -> Array[Dictionary]:
	return [
		{"name": "NorthFanBay", "path": "walls/wall_carrow_fan_bay_01.png", "cell": Vector2i(1, 2), "z": -18},
		{"name": "NorthHeatExchanger", "path": "walls/wall_carrow_vent_wall_medium_01.png", "cell": Vector2i(8, 2), "z": -18},
		{"name": "WestFilterVent", "path": "walls/wall_carrow_vent_wall_wide_01.png", "cell": Vector2i(1, 5), "z": -16},
		{"name": "EastDraftControls", "path": "walls/wall_carrow_control_bay_01.png", "cell": Vector2i(8, 4), "z": -16},
		{"name": "PressureSwitchgear", "path": "props/carrow_machine_house_switchgear.png", "cell": Vector2i(8, 5), "z": -10},
		{"name": "FilterCradle", "path": "props/carrow_machine_house_parts_locker.png", "cell": Vector2i(2, 7), "z": -10},
		{"name": "EmergencyPartsRack", "path": "props/carrow_machine_house_replacement_modules.png", "cell": Vector2i(9, 7), "z": -10},
		{"name": "AuxiliaryPowerJunction", "path": "props/carrow_machine_house_conduit_junction.png", "cell": Vector2i(9, 6), "z": -11},
	]


func _build_interior_art(root: Node2D, room_origin: Vector2i, placements: Array[Dictionary], require_all: bool) -> int:
	if root == null:
		return 0
	var art := Node2D.new()
	art.name = "ProductionArt"
	root.add_child(art)
	for placement in placements:
		var cell: Vector2i = placement.get("cell", Vector2i.ZERO)
		var added := _add_machine_house_art_sprite(art, String(placement.get("name", "")), String(placement.get("path", "")), room_origin + cell, int(placement.get("z", -10)))
		if require_all and not added:
			art.queue_free()
			return 0
	return art.get_child_count()


func _add_machine_house_art_sprite(parent: Node2D, sprite_name: String, relative_path: String, anchor_cell: Vector2i, z: int) -> bool:
	var texture := load(MACHINE_HOUSE_STRUCTURE_ROOT + relative_path) as Texture2D
	if texture == null:
		push_warning("[CarrowYard] Missing Machine House art: %s" % relative_path)
		return false
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _tile_to_local(anchor_cell) - Vector2(0.0, float(texture.get_height()) * 0.5)
	sprite.z_as_relative = false
	sprite.z_index = z
	parent.add_child(sprite)
	return true


func _add_machine_house_layout(room_origin: Vector2i) -> void:
	_build_interior_layout(_machine_house_root, room_origin, MACHINE_HOUSE_LAYOUT)


func _build_interior_layout(root: Node2D, room_origin: Vector2i, layout: Array) -> void:
	if root == null:
		return
	for y in range(layout.size()):
		var row: String = String(layout[y])
		for x in range(row.length()):
			var symbol := row.substr(x, 1)
			if symbol == ".":
				continue
			var cell := room_origin + Vector2i(x, y)
			_add_room_cell_collision(root, cell, symbol)


func _add_machine_house_cell_collision(cell: Vector2i, symbol: String) -> void:
	_add_room_cell_collision(_machine_house_root, cell, symbol)


func _add_room_cell_collision(root: Node2D, cell: Vector2i, symbol: String) -> void:
	if root == null or symbol == "." or symbol == "D":
		return
	var body := StaticBody2D.new()
	body.name = "Boundary%s_%d_%d" % [symbol, cell.x, cell.y]
	body.position = _tile_to_local(cell) + Vector2.ONE * TILE_SIZE * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2.ONE * TILE_SIZE
	shape.shape = rectangle
	body.add_child(shape)
	root.add_child(body)


func _add_machine_house_storage(storage_id: String, display_name: String, tile: Vector2i, starting_resources: Dictionary) -> void:
	_add_room_storage(_machine_house_root, storage_id, display_name, tile, starting_resources)


func _add_room_storage(root: Node2D, storage_id: String, display_name: String, tile: Vector2i, starting_resources: Dictionary) -> void:
	var storage := VAULT_STORAGE_SCENE.instantiate()
	if storage == null:
		return
	storage.name = storage_id.to_pascal_case()
	storage.set("storage_id", StringName(storage_id))
	storage.set("display_name", display_name)
	storage.set("starting_resources", starting_resources)
	storage.set("default_visual_enabled", false)
	if storage is Node2D:
		(storage as Node2D).position = _tile_to_local(tile)
	root.add_child(storage)


func _add_definition_storage(root: Node2D, room_origin: Vector2i, definition: Dictionary) -> void:
	for binding_variant in definition.get("resource_bindings", []):
		var binding := binding_variant as Dictionary
		var tile_offset: Vector2i = binding.get("tile_offset", Vector2i.ZERO)
		_add_room_storage(
			root,
			String(binding.get("id", "")),
			String(binding.get("display_name", "")),
			room_origin + tile_offset,
			binding.get("resources", {}) as Dictionary
		)


func _add_machine_house_lighting(room_origin: Vector2i) -> void:
	var definition := (INTERIOR_ROOM_DEFINITIONS.get("east_machine_house", {}) as Dictionary).duplicate(true)
	_add_interior_lighting(_machine_house_root, definition, room_origin, "MachineHouse", false)


func _add_interior_lighting(root: Node2D, definition: Dictionary, room_origin: Vector2i, name_prefix: String, draft_house: bool) -> void:
	if root == null:
		return
	var zone := LIGHTING_ZONE_SCRIPT.new() as LightingZone2D
	zone.name = "%sLightingZone" % name_prefix
	zone.profile = load(String(definition.get("profile_path", ""))) as LightingProfile
	zone.profile_priority = 20
	var room_size: Vector2i = definition.get("size", MACHINE_HOUSE_SIZE)
	zone.position = _tile_to_local(room_origin) + Vector2(room_size) * TILE_SIZE * 0.5
	var zone_shape := CollisionShape2D.new()
	var zone_rectangle := RectangleShape2D.new()
	zone_rectangle.size = Vector2(room_size) * TILE_SIZE - Vector2.ONE * TILE_SIZE
	zone_shape.shape = zone_rectangle
	zone.add_child(zone_shape)
	root.add_child(zone)

	var rig := LIGHT_RIG_SCENE.instantiate() as LightRig2D
	if rig != null:
		rig.name = "SwitchBankMaintenanceLight" if not draft_house else "DraftHouseServiceLight"
		rig.position = _tile_to_local(room_origin + Vector2i(10, 2)) + Vector2.ONE * TILE_SIZE * 0.5
		rig.light_color = Color(1.0, 0.72, 0.42, 1.0)
		rig.energy = 0.9 if not draft_house else 0.52
		rig.glow_scale = 1.8 if not draft_house else 1.15
		rig.shadows_enabled = true
		root.add_child(rig)
	if draft_house:
		var dead_vent_light := LIGHT_RIG_SCENE.instantiate() as LightRig2D
		if dead_vent_light != null:
			dead_vent_light.name = "ColdDeadVentLight"
			dead_vent_light.position = _tile_to_local(room_origin + Vector2i(2, 4)) + Vector2.ONE * TILE_SIZE * 0.5
			dead_vent_light.light_color = Color(0.54, 0.72, 0.82, 1.0)
			dead_vent_light.energy = 0.14
			dead_vent_light.glow_scale = 0.8
			dead_vent_light.shadows_enabled = false
			root.add_child(dead_vent_light)


func _add_machine_house_doors(machine_site: Dictionary, room_origin: Vector2i) -> void:
	var definition := _interior_definition(&"east_machine_house")
	_add_definition_doors(_machine_house_root, &"east_machine_house", machine_site, room_origin, definition)
	var site_cell: Vector2i = machine_site.get("cell", Vector2i.ZERO)
	var footprint: Vector2i = machine_site.get("footprint", Vector2i(7, 8))
	_machine_house_exterior_return_position = _tile_to_local(site_cell + Vector2i(int(footprint.x / 2), footprint.y + 2))


func _add_definition_doors(room_root: Node2D, room_id: StringName, site: Dictionary, room_origin: Vector2i, definition: Dictionary) -> void:
	var exit_cell: Vector2i = definition.get("exit_cell", Vector2i.ZERO)
	_add_interior_doors(
		room_root,
		room_id,
		site,
		room_origin,
		exit_cell,
		String(definition.get("entry_door_name", "")),
		String(definition.get("exit_door_name", "")),
		String(definition.get("entry_prompt", "")),
		String(definition.get("exit_prompt", ""))
	)


func _add_interior_doors(room_root: Node2D, room_id: StringName, site: Dictionary, room_origin: Vector2i, exit_cell: Vector2i, entry_name: String, exit_name: String, entry_prompt: String, exit_prompt: String) -> void:
	if room_root == null or not _is_valid_structure_site(site):
		return
	var site_cell: Vector2i = site.get("cell", Vector2i.ZERO)
	var footprint: Vector2i = site.get("footprint", Vector2i.ZERO)
	var exterior_door := MACHINE_HOUSE_DOOR_SCRIPT.new() as CarrowMachineHouseDoor
	exterior_door.name = entry_name
	exterior_door.configure_interior(self, room_id, CarrowMachineHouseDoor.TravelMode.ENTER_MACHINE_HOUSE, entry_prompt)
	exterior_door.position = _tile_to_local(site_cell) + Vector2(float(footprint.x) * TILE_SIZE * 0.5, float(footprint.y) * TILE_SIZE)
	add_child(exterior_door)
	var interior_door := MACHINE_HOUSE_DOOR_SCRIPT.new() as CarrowMachineHouseDoor
	interior_door.name = exit_name
	interior_door.configure_interior(self, room_id, CarrowMachineHouseDoor.TravelMode.LEAVE_MACHINE_HOUSE, exit_prompt)
	interior_door.position = _tile_to_local(room_origin + exit_cell)
	room_root.add_child(interior_door)


func enter_machine_house(actor: Node) -> void:
	enter_carrow_interior(&"east_machine_house", actor)


func leave_machine_house(actor: Node) -> void:
	leave_carrow_interior(&"east_machine_house", actor)


func enter_carrow_interior(room_id: StringName, actor: Node) -> void:
	var room := _interior_rooms.get(String(room_id), {}) as Dictionary
	if room.is_empty() or not is_instance_valid(actor) or not actor is Node2D:
		return
	if active_interior_id != &"":
		if active_interior_id == room_id and _active_interior_actor_id == actor.get_instance_id():
			return
		return
	var root := room.get("root") as Node2D
	if root == null or not is_instance_valid(root):
		return
	active_interior_id = room_id
	_active_interior_actor_id = actor.get_instance_id()
	_set_main_procgen_backdrop_isolated(true)
	var room_rect: Rect2 = room.get("world_rect", Rect2())
	var spawn_offset: Vector2 = room.get("spawn_offset", Vector2.ZERO)
	(actor as Node2D).global_position = to_global(room_rect.position + spawn_offset * TILE_SIZE)
	_refresh_camera(self, actor)


func leave_carrow_interior(room_id: StringName, actor: Node) -> void:
	if active_interior_id != room_id or not is_instance_valid(actor) or actor.get_instance_id() != _active_interior_actor_id:
		return
	var room := _interior_rooms.get(String(room_id), {}) as Dictionary
	if room.is_empty():
		return
	var return_position: Vector2 = room.get("exterior_return_position", Vector2.ZERO)
	active_interior_id = &""
	_active_interior_actor_id = 0
	_set_main_procgen_backdrop_isolated(true)
	if actor is Node2D:
		(actor as Node2D).global_position = to_global(return_position)
	_refresh_camera(self, actor)


func get_active_interior_id() -> StringName:
	return active_interior_id


func get_interior_debug_state(room_id: StringName) -> Dictionary:
	var room := _interior_rooms.get(String(room_id), {}) as Dictionary
	if room.is_empty():
		return {}
	var root := room.get("root") as Node2D
	var layout: Array = (room.get("layout", []) as Array).duplicate()
	return {
		"id": room_id,
		"site_id": room.get("site_id", ""),
		"origin": room.get("origin", Vector2i.ZERO),
		"interior_rect": room.get("world_rect", Rect2()),
		"camera_bounds": room.get("camera_bounds", Rect2()),
		"layout": layout,
		"inside": active_interior_id == room_id,
		"exterior_return_position": room.get("exterior_return_position", Vector2.ZERO),
		"has_entry_door": get_node_or_null(String(room.get("entry_door_name", ""))) != null,
		"has_exit_door": root != null and root.get_node_or_null(String(room.get("exit_door_name", ""))) != null,
		"floor_tile_count": root.get_node("CarrowFloorTiles").get_child_count() if root != null and root.has_node("CarrowFloorTiles") else 0,
		"production_art_count": root.get_node("ProductionArt").get_child_count() if root != null and root.has_node("ProductionArt") else 0,
		"root": root,
	}


func get_environment_region_at_global(world_position: Vector2) -> Dictionary:
	var local_position := to_local(world_position)
	for room in _interior_rooms.values():
		var room_data := room as Dictionary
		var room_rect: Rect2 = room_data.get("world_rect", Rect2())
		if room_rect.has_point(local_position):
			return {
				"contains": true,
				"indoor": true,
				"environment_exposure": float(room_data.get("environment_exposure", 0.10)),
				"weather_exposure": float(room_data.get("weather_exposure", 0.0)),
				"interior_id": room_data.get("id", &""),
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
	var state := get_interior_debug_state(&"east_machine_house")
	state["canonical_id"] = "carrow_yard"
	state["structure_sites"] = _structure_sites.duplicate(true)
	return state


func get_west_draft_house_debug_state() -> Dictionary:
	var state := get_interior_debug_state(&"west_draft_house")
	state["structure_sites"] = _structure_sites.duplicate(true)
	return state


func get_operations_house_debug_state() -> Dictionary:
	var state := get_interior_debug_state(&"operations_house")
	state["structure_sites"] = _structure_sites.duplicate(true)
	return state


func _register_interior_room(room_id: StringName, root: Node2D, room_origin: Vector2i, site: Dictionary) -> void:
	var definition := _interior_definition(room_id)
	if root == null or not _is_valid_structure_site(site) or not _is_valid_interior_definition(definition):
		return
	var room_size: Vector2i = definition.size
	var room_rect := Rect2(_tile_to_local(room_origin), Vector2(room_size) * TILE_SIZE)
	var camera_bounds := room_rect.grow(TILE_SIZE * 2.0)
	if not _interior_bounds_available(room_rect, camera_bounds, room_id):
		return
	var site_cell: Vector2i = site.cell
	var footprint: Vector2i = site.footprint
	var exterior_return := _tile_to_local(site_cell + Vector2i(int(footprint.x / 2), footprint.y + 2))
	_interior_rooms[String(room_id)] = {
		"id": room_id,
		"site_id": StringName(definition.site_id),
		"root": root,
		"origin": room_origin,
		"world_rect": room_rect,
		"camera_bounds": camera_bounds,
		"layout": (definition.layout as Array).duplicate(),
		"spawn_offset": definition.spawn_offset,
		"exit_cell": definition.exit_cell,
		"exterior_return_position": exterior_return,
		"entry_door_name": String(definition.get("entry_door_name", "")),
		"exit_door_name": String(definition.get("exit_door_name", "")),
		"resource_bindings": (definition.get("resource_bindings", []) as Array).duplicate(true),
		"environment_exposure": float(definition.environment_exposure),
		"weather_exposure": float(definition.weather_exposure),
	}
	if room_id == &"east_machine_house":
		_machine_house_interior_rect = room_rect
		_machine_house_camera_bounds = camera_bounds
		_machine_house_exterior_return_position = exterior_return


func _is_valid_structure_site(site: Dictionary) -> bool:
	if site.is_empty():
		return false
	var cell: Variant = site.get("cell")
	var footprint: Variant = site.get("footprint")
	return cell is Vector2i and footprint is Vector2i and (footprint as Vector2i).x > 0 and (footprint as Vector2i).y > 0


func _is_valid_interior_definition(definition: Dictionary) -> bool:
	if definition.is_empty():
		return false
	var size: Variant = definition.get("size")
	var layout: Variant = definition.get("layout")
	var spawn: Variant = definition.get("spawn_offset")
	var exit_cell: Variant = definition.get("exit_cell")
	if not (size is Vector2i and layout is Array and spawn is Vector2 and exit_cell is Vector2i):
		return false
	var room_size := size as Vector2i
	if room_size.x < 3 or room_size.y < 3 or layout.size() != room_size.y:
		return false
	var allowed := "X.DRFHVCPRSLWK"
	for row_index in range(layout.size()):
		var row_variant: Variant = layout[row_index]
		var row := String(row_variant)
		var legacy_bottom_row := bool(definition.get("legacy_short_bottom_row", false)) and row_index == room_size.y - 1 and row.length() == room_size.x - 1
		if row.length() != room_size.x and not legacy_bottom_row:
			return false
		for x in range(row.length()):
			if allowed.find(row.substr(x, 1)) < 0:
				return false
	var bottom_row := String(layout[room_size.y - 1])
	if String(layout[0]).find("X") != 0 or String(layout[0]).count("X") != room_size.x:
		return false
	for y in range(1, room_size.y - 1):
		var boundary_row := String(layout[y])
		if boundary_row.substr(0, 1) != "X" or boundary_row.substr(boundary_row.length() - 1, 1) != "X":
			return false
	var door_indices: Array[int] = []
	for x in range(bottom_row.length()):
		if bottom_row.substr(x, 1) == "D":
			door_indices.append(x)
	if door_indices.size() != 3 or door_indices[1] != door_indices[0] + 1 or door_indices[2] != door_indices[1] + 1:
		return false
	for x in range(bottom_row.length()):
		if x not in door_indices and bottom_row.substr(x, 1) != "X":
			return false
	var spawn_cell := Vector2i(floori((spawn as Vector2).x), floori((spawn as Vector2).y))
	if spawn_cell.x < 0 or spawn_cell.y < 0 or spawn_cell.x >= room_size.x or spawn_cell.y >= room_size.y:
		return false
	if String(layout[spawn_cell.y]).substr(spawn_cell.x, 1) != ".":
		return false
	var exit_tile := exit_cell as Vector2i
	return exit_tile.x in door_indices and exit_tile.y == room_size.y - 1


func _interior_assets_available(definition: Dictionary, art: Array[Dictionary]) -> bool:
	var profile_path := String(definition.get("profile_path", ""))
	if profile_path.is_empty() or not ResourceLoader.exists(profile_path):
		return false
	var profile := ResourceLoader.load(profile_path) as LightingProfile
	if profile == null:
		return false
	var states: Array = definition.get("floor_states", [])
	if states.is_empty():
		return false
	for state in states:
		var floor_path := MACHINE_HOUSE_FLOOR_ROOT + "floor_carrow_%s_32.png" % String(state)
		if not ResourceLoader.exists(floor_path) or (ResourceLoader.load(floor_path) as Texture2D) == null:
			return false
	for placement in art:
		var art_path := MACHINE_HOUSE_STRUCTURE_ROOT + String(placement.get("path", ""))
		if not ResourceLoader.exists(art_path) or (ResourceLoader.load(art_path) as Texture2D) == null:
			return false
	return true


func _interior_bounds_available(room_rect: Rect2, camera_bounds: Rect2, ignore_id: StringName = &"") -> bool:
	for key_variant in _interior_rooms:
		var key := StringName(str(key_variant))
		if key == ignore_id:
			continue
		var other := _interior_rooms[key_variant] as Dictionary
		var other_rect: Rect2 = other.get("world_rect", Rect2())
		var other_camera: Rect2 = other.get("camera_bounds", Rect2())
		if room_rect.intersects(other_rect) or camera_bounds.intersects(other_camera):
			return false
	return true


func _tile_to_local(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _refresh_camera(map_instance: Node, actor: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera != null and actor is Node2D:
		camera.global_position = (actor as Node2D).global_position


func _set_main_procgen_backdrop_isolated(isolated: bool) -> void:
	var candidates: Array[Node] = []
	if main_map != null and is_instance_valid(main_map):
		candidates.append(main_map)
	for candidate in get_tree().get_nodes_in_group("procgen_render_isolation"):
		if candidate is Node and is_instance_valid(candidate):
			candidates.append(candidate)
	var seen: Dictionary = {}
	for candidate in candidates:
		var key := candidate.get_instance_id()
		if seen.has(key):
			continue
		seen[key] = true
		var backdrop := candidate as ProcgenDepthBackdrop
		if backdrop == null:
			backdrop = candidate.get_node_or_null("DepthBackdrop") as ProcgenDepthBackdrop
		if backdrop == null:
			backdrop = candidate.find_child("DepthBackdrop", true, false) as ProcgenDepthBackdrop
		if backdrop != null:
			backdrop.set_connected_map_isolation(isolated)


func _update_depth_sort() -> void:
	if _context == null or not _context.has_method("update_depth_sort"):
		return
	var operator := get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	if operator != null:
		_context.call("update_depth_sort", operator)
