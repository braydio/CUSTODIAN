class_name TurretPlacement
extends Node

## Handles player turret placement and dismantling.

signal placement_mode_changed(is_placing: bool)
signal turret_placed(turret: Node2D)
signal turret_dismantled(turret: Node2D, refund: int)

const TURRET_COSTS := {
	"gunner": 10,
	"blaster": 15,
	"repeater": 20,
	"sniper": 25,
}

const TURRET_REFUNDS := {
	"gunner": 5,
	"blaster": 8,
	"repeater": 10,
	"sniper": 12,
}

const MAX_DEFAULT_TURRETS := 10

@export var turret_scenes: Dictionary = {
	"gunner": preload("res://entities/sector/turret_gunner.tscn"),
	"blaster": preload("res://entities/sector/turret_blaster.tscn"),
	"repeater": preload("res://entities/sector/turret_repeater.tscn"),
	"sniper": preload("res://entities/sector/turret_sniper.tscn"),
}

var _is_placing: bool = false
var _selected_turret_type: String = ""
var _ghost_preview: Node2D = null
var _placement_valid: bool = false
var _placed_turrets: Array[Node2D] = []

var _game_state: Node = null
var _operator: Node2D = null
var _ui: Node = null

func _ready() -> void:
	# Get game state from group
	var game_states := get_tree().get_nodes_in_group("game_state")
	if game_states.size() > 0:
		_game_state = game_states[0]
	else:
		_game_state = get_node_or_null("/root/GameState")
	
	_operator = get_node_or_null("/root/GameRoot/World/Operator")
	_ui = get_node_or_null("/root/GameRoot/UI")
	_create_ghost_preview()
	
	print("[TurretPlacement] Initialized, game_state: ", _game_state)


func _create_ghost_preview() -> void:
	_ghost_preview = Node2D.new()
	_ghost_preview.name = "TurretGhost"
	_ghost_preview.visible = false
	add_child(_ghost_preview)
	
	var sprite := Sprite2D.new()
	sprite.modulate = Color(1, 1, 1, 0.5)
	sprite.name = "Sprite"
	_ghost_preview.add_child(sprite)


func _input(event: InputEvent) -> void:
	# B key - toggle placement mode or dismantle
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		_handle_build_input()
		return
	
	if not _is_placing:
		return
	
	# Q key - quit placement mode (separate from ESC which is terminal exit)
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		exit_placement_mode()
		print("[TurretPlacement] Exited placement mode (Q pressed)")
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attempt_place_turret(_get_world_mouse_position())


func _handle_build_input() -> void:
	if _is_placing:
		exit_placement_mode()
		return
	
	# Check if near a placed turret for dismantling
	if _operator != null:
		var mouse_pos := _get_world_mouse_position()
		for turret in _placed_turrets:
			if turret.global_position.distance_to(mouse_pos) < 40.0:
				_attempt_dismantle(turret)
				return
	
	# Show build menu - for now just enter placement with first available turret
	# TODO: Wire to UI for full turret selection
	if _game_state != null and _game_state.materials >= 10:
		enter_placement_mode("gunner")
	else:
		push_warning("[TurretPlacement] No materials available")


func _attempt_dismantle(turret: Node2D) -> void:
	if not _placed_turrets.has(turret):
		return
	
	var refund := 5 # Default fallback
	# Try to determine refund based on turret type
	for type in TURRET_COSTS.keys():
		if turret_scenes.has(type):
			var scene = turret_scenes[type]
			if turret.scene_file_path == scene.resource_path:
				refund = TURRET_REFUNDS.get(type, 5)
				break
	
	_placed_turrets.erase(turret)
	
	if _game_state != null and _game_state.has("materials"):
		_game_state.materials += refund
	
	turret.queue_free()
	turret_dismantled.emit(turret, refund)
	print("[TurretPlacement] Dismantled turret, refunded ", refund, " materials")


func _process(delta: float) -> void:
	if not _is_placing:
		return
	
	var mouse_pos: Vector2 = _get_world_mouse_position()
	_update_ghost_preview(mouse_pos)


func enter_placement_mode(turret_type: String) -> bool:
	if not TURRET_COSTS.has(turret_type):
		push_error("[TurretPlacement] Unknown turret type: " + turret_type)
		return false
	
	var cost: int = TURRET_COSTS[turret_type]
	var current_materials: int = 0
	if _game_state != null:
		current_materials = _game_state.materials
	
	if current_materials < cost:
		push_warning("[TurretPlacement] Insufficient materials for " + turret_type + " (have: " + str(current_materials) + ", need: " + str(cost) + ")")
		return false
	
	if get_turret_count() >= get_max_turrets():
		push_warning("[TurretPlacement] Max turrets reached")
		return false
	
	_selected_turret_type = turret_type
	_is_placing = true
	_ghost_preview.visible = true
	placement_mode_changed.emit(true)
	
	if _ui != null and _ui.has_method("enter_placement_mode_ui"):
		_ui.enter_placement_mode_ui()
	
	print("[TurretPlacement] Entered placement mode for: " + turret_type)
	return true


func exit_placement_mode() -> void:
	_is_placing = false
	_selected_turret_type = ""
	_ghost_preview.visible = false
	placement_mode_changed.emit(false)
	
	if _ui != null and _ui.has_method("exit_placement_mode_ui"):
		_ui.exit_placement_mode_ui()


func is_placing() -> bool:
	return _is_placing


func get_selected_type() -> String:
	return _selected_turret_type


func get_turret_count() -> int:
	return _placed_turrets.size()


func get_max_turrets() -> int:
	return MAX_DEFAULT_TURRETS


func _update_ghost_preview(mouse_pos: Vector2) -> void:
	var sprite := _ghost_preview.get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	
	sprite.position = Vector2.ZERO
	
	_placement_valid = _can_place_at(mouse_pos)
	
	if _placement_valid:
		sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		sprite.modulate = Color(1, 0, 0, 0.5)
	
	_ghost_preview.global_position = mouse_pos


func _can_place_at(position: Vector2) -> bool:
	if not _is_walkable_floor(position):
		return false
	if _is_occupied(position):
		return false
	return true


func _is_walkable_floor(position: Vector2) -> bool:
	var tilemap := get_tilemap_layer("Floor")
	if tilemap == null:
		return true
	
	var tile_pos := tilemap.local_to_map(position)
	var tile_data := tilemap.get_cell_tile_data(tile_pos)
	if tile_data == null:
		return false
	
	return true


func _is_occupied(position: Vector2) -> bool:
	var check_radius := 20.0
	for turret in _placed_turrets:
		if turret.global_position.distance_to(position) < check_radius:
			return true
	
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.global_position.distance_to(position) < check_radius:
			return true
	
	return false


func _attempt_place_turret(position: Vector2) -> void:
	if not _can_place_at(position):
		push_warning("[TurretPlacement] Cannot place here")
		return
	
	var cost: int = int(TURRET_COSTS.get(_selected_turret_type, 0))
	if _game_state and _game_state.has("materials"):
		_game_state.materials -= cost
	
	var scene: PackedScene = turret_scenes.get(_selected_turret_type, null)
	if scene == null:
		push_error("[TurretPlacement] Missing scene for: " + _selected_turret_type)
		return
	
	var turret: Node2D = scene.instantiate() as Node2D
	if turret == null:
		push_error("[TurretPlacement] Failed to instantiate turret")
		return
	
	get_parent().add_child(turret)
	turret.global_position = position
	
	_placed_turrets.append(turret)
	turret_placed.emit(turret)
	
	exit_placement_mode()


func get_tilemap_layer(layer_name: String) -> TileMapLayer:
	var root := get_tree().root
	var world := root.get_node_or_null("GameRoot/World")
	if world == null:
		return null
	
	var procgen_map := world.get_node_or_null("ProcGenMap")
	if procgen_map and procgen_map.has("procgen_node"):
		var tilemap: TileMapLayer = procgen_map.floor_tilemap
		return tilemap
	
	return null


func _get_world_mouse_position() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		return camera.get_global_mouse_position()
	return Vector2.ZERO


func attempt_dismantle(turret: Node2D) -> int:
	if not _placed_turrets.has(turret):
		return 0
	
	var refund: int = int(TURRET_REFUNDS.get(_selected_turret_type, 0))
	
	_placed_turrets.erase(turret)
	
	if _game_state and _game_state.has("materials"):
		_game_state.materials += refund
	
	turret.queue_free()
	turret_dismantled.emit(turret, refund)
	
	return refund
