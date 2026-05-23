extends Node2D
class_name GothicCompoundMap

const TILE_SIZE := 32.0
const TRAVEL_GATE_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_travel_gate.gd")
const GOTHIC_CONTEXT_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_sprite_context.gd")
const GOTHIC_CONFIG_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_config.gd")
const GOTHIC_GENERATOR_SCRIPT := preload("res://game/world/procgen/gothic_compound/gothic_compound_generator.gd")

@export var map_size_tiles: Vector2i = Vector2i(82, 60)
@export var world_seed: int = 947113
@export var entrance_tile: Vector2i = Vector2i(41, 44)
@export var return_gate_tile: Vector2i = Vector2i(41, 45)

var main_map: Node = null
var main_return_position: Vector2 = Vector2.ZERO

var _built := false
var _camera_bounds := Rect2()
var _context: Node2D = null
var _return_gate: Node2D = null


func _ready() -> void:
	add_to_group("connected_map")
	add_to_group("gothic_compound_map")
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
		Vector2(float(map_size_tiles.x + 4) * TILE_SIZE, float(map_size_tiles.y + 4) * TILE_SIZE)
	)
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
		var gate_cell: Vector2i = result.get("gate_cell")
		entrance_tile = gate_cell + Vector2i(0, -2)
		return_gate_tile = gate_cell + Vector2i(0, -1)
	else:
		push_warning("[GothicCompoundMap] Blueprint generation failed; using default travel positions")


func _add_return_gate() -> void:
	_return_gate = TRAVEL_GATE_SCRIPT.new() as Node2D
	if _return_gate == null:
		return
	_return_gate.name = "ReturnToMainMapGate"
	_return_gate.call("configure", self, 1, "RETURN TO MAIN MAP")
	_return_gate.position = _tile_to_local(return_gate_tile)
	add_child(_return_gate)


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
