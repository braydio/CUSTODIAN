class_name TurretPlacement
extends Node

## Handles player turret placement and dismantling.

signal placement_mode_changed(is_placing: bool)
signal turret_placed(turret: Node2D)
signal turret_dismantled(turret: Node2D, refund: int)
signal turret_picked_up(turret_type: String)
signal build_token_placed(instance: Node2D, build_token_id: String)
signal build_placement_failed(build_token_id: String, reason: String)

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

const TURRET_BUILD_TOKENS := {
	"gunner": "turret_basic",
}

const BUILD_TOKEN_TO_PLACEABLE := {
	"turret_basic": {
		"placeable_type": "gunner",
		"kind": "turret",
	},
	"barricade_light": {
		"placeable_type": "light_barricade",
		"kind": "structure",
		"scene": preload("res://game/actors/structures/light_barricade.tscn"),
	},
	"capacitor_bank_mk1": {
		"placeable_type": "capacitor_bank_mk1",
		"kind": "structure",
		"scene": preload("res://game/infrastructure/structures/capacitor_bank_mk1.tscn"),
	},
}

const MAX_DEFAULT_TURRETS := 10
const TURRET_BUILD_ORDER := ["gunner", "blaster", "repeater", "sniper"]

@export var turret_scenes: Dictionary = {
	"gunner": preload("res://game/actors/sector/turret_gunner.tscn"),
	"blaster": preload("res://game/actors/sector/turret_blaster.tscn"),
	"repeater": preload("res://game/actors/sector/turret_repeater.tscn"),
	"sniper": preload("res://game/actors/sector/turret_sniper.tscn"),
}

var _is_placing: bool = false
var _selected_turret_type: String = ""
var _ghost_preview: Node2D = null
var _placement_valid: bool = false
var _placed_turrets: Array[Node2D] = []
var _placed_structures: Array[Node2D] = []
var _carried_turret_data: Dictionary = {}
var _preview_override_active: bool = false
var _preview_override_world_pos: Vector2 = Vector2.ZERO
var _build_cycle_index: int = -1
var _selected_build_token: String = ""
var _selected_placeable_type: String = ""

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

	var footprint := Polygon2D.new()
	footprint.name = "Footprint"
	footprint.polygon = PackedVector2Array([
		Vector2(-30.0, -14.0),
		Vector2(30.0, -14.0),
		Vector2(30.0, 14.0),
		Vector2(-30.0, 14.0),
	])
	footprint.color = Color(0.55, 0.72, 0.38, 0.55)
	_ghost_preview.add_child(footprint)


func _input(event: InputEvent) -> void:
	# B key - cycle placement mode or dismantle nearby turret
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
		_attempt_place_selected(_get_world_mouse_position())


func _handle_build_input() -> void:
	if _is_placing:
		if bool(_carried_turret_data.get("active", false)) or _selected_turret_type.is_empty():
			exit_placement_mode()
		else:
			_cycle_to_next_turret_type()
		return
	
	var turret_under_cursor := _get_turret_under_cursor(_get_world_mouse_position())
	if turret_under_cursor != null:
		_attempt_dismantle(turret_under_cursor)
		return
	
	_cycle_to_next_turret_type(true)


func _attempt_dismantle(turret: Node2D) -> void:
	var refund := attempt_dismantle(turret)
	if refund > 0:
		print("[TurretPlacement] Dismantled turret, refunded ", refund, " materials")


func _cycle_to_next_turret_type(include_current_index: bool = false) -> bool:
	if TURRET_BUILD_ORDER.is_empty():
		return false
	var active_materials := get_material_count()
	var current_count := get_turret_count()
	var max_turrets := get_max_turrets()
	for step in range(TURRET_BUILD_ORDER.size()):
		var candidate_index := 0
		if include_current_index and _build_cycle_index < 0 and step == 0:
			candidate_index = 0
		else:
			candidate_index = posmod(_build_cycle_index + step + 1, TURRET_BUILD_ORDER.size())
		var turret_type := String(TURRET_BUILD_ORDER[candidate_index])
		var is_redeploy := bool(_carried_turret_data.get("active", false)) and String(_carried_turret_data.get("type", "")) == turret_type
		if not is_redeploy and current_count >= max_turrets:
			continue
		if is_redeploy or _has_build_token_for_turret(turret_type) or active_materials >= get_cost_for_type(turret_type):
			return enter_placement_mode(turret_type)
	return false


func _get_turret_under_cursor(mouse_pos: Vector2) -> Node2D:
	for turret in _placed_turrets:
		if turret != null and is_instance_valid(turret) and turret.global_position.distance_to(mouse_pos) < 40.0:
			return turret
	return null


func _process(delta: float) -> void:
	_prune_placed_turrets()
	if not _is_placing:
		return
	
	var mouse_pos: Vector2 = _get_world_mouse_position()
	if _preview_override_active:
		mouse_pos = _preview_override_world_pos
	_update_ghost_preview(mouse_pos)


func enter_placement_mode(turret_type: String) -> bool:
	if not TURRET_COSTS.has(turret_type):
		push_error("[TurretPlacement] Unknown turret type: " + turret_type)
		return false
	
	var cost: int = TURRET_COSTS[turret_type]
	var current_materials: int = 0
	var is_redeploy := bool(_carried_turret_data.get("active", false)) and String(_carried_turret_data.get("type", "")) == turret_type
	var has_build_token := _has_build_token_for_turret(turret_type)
	if _game_state != null:
		current_materials = _game_state.materials
	
	if not is_redeploy and not has_build_token and current_materials < cost:
		push_warning("[TurretPlacement] Insufficient materials for " + turret_type + " (have: " + str(current_materials) + ", need: " + str(cost) + ")")
		return false
	
	if not is_redeploy and get_turret_count() >= get_max_turrets():
		push_warning("[TurretPlacement] Max turrets reached")
		return false
	
	_selected_turret_type = turret_type
	_selected_placeable_type = turret_type
	_build_cycle_index = TURRET_BUILD_ORDER.find(turret_type)
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
	_selected_build_token = ""
	_selected_placeable_type = ""
	_ghost_preview.visible = false
	_preview_override_active = false
	placement_mode_changed.emit(false)
	
	if _ui != null and _ui.has_method("exit_placement_mode_ui"):
		_ui.exit_placement_mode_ui()


func is_placing() -> bool:
	return _is_placing


func get_selected_type() -> String:
	return _selected_turret_type if not _selected_turret_type.is_empty() else _selected_placeable_type


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
	
	_ghost_preview.modulate = Color(0.75, 1.0, 0.65, 0.7) if _placement_valid else Color(1.0, 0.35, 0.35, 0.7)
	
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
	var check_radius := 40.0
	var occupied_nodes: Array[Node] = []
	for group_name in ["player", "enemy", "enemies", "turret", "structure"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not occupied_nodes.has(node):
				occupied_nodes.append(node)
	for node in occupied_nodes:
		if node is Node2D and is_instance_valid(node) and (node as Node2D).global_position.distance_to(position) < check_radius:
			return true
	
	return false


func _attempt_place_selected(position: Vector2) -> bool:
	if not _selected_turret_type.is_empty():
		return _attempt_place_turret(position)
	return _attempt_place_build_token(position)


func _attempt_place_turret(position: Vector2) -> bool:
	if not _can_place_at(position):
		_emit_build_placement_failed("invalid_site")
		return false
	
	var cost: int = int(TURRET_COSTS.get(_selected_turret_type, 0))
	var is_redeploy := bool(_carried_turret_data.get("active", false)) and String(_carried_turret_data.get("type", "")) == _selected_turret_type
	var used_build_token := false
	if not is_redeploy:
		used_build_token = _consume_build_token_for_turret(_selected_turret_type)
	if not is_redeploy and not _selected_build_token.is_empty() and not used_build_token:
		_emit_build_placement_failed("token_unavailable")
		return false
	if not is_redeploy and _selected_build_token.is_empty() and not used_build_token:
		if _game_state and _game_state.has_method("add_materials"):
			_game_state.add_materials(-cost)
	
	var scene: PackedScene = turret_scenes.get(_selected_turret_type, null)
	if scene == null:
		if used_build_token:
			_refund_build_token_for_turret(_selected_turret_type)
		push_error("[TurretPlacement] Missing scene for: " + _selected_turret_type)
		_emit_build_placement_failed("scene_unavailable")
		return false
	
	var turret: Node2D = scene.instantiate() as Node2D
	if turret == null:
		if used_build_token:
			_refund_build_token_for_turret(_selected_turret_type)
		push_error("[TurretPlacement] Failed to instantiate turret")
		_emit_build_placement_failed("scene_instantiate_failed")
		return false
	
	get_parent().add_child(turret)
	turret.global_position = position
	if is_redeploy:
		if "current_health" in turret and _carried_turret_data.has("current_health"):
			turret.set("current_health", float(_carried_turret_data.get("current_health", turret.get("current_health"))))
		if "state" in turret and _carried_turret_data.has("state"):
			turret.set("state", String(_carried_turret_data.get("state", turret.get("state"))))
		if turret.has_method("_update_damage_visuals"):
			turret.call("_update_damage_visuals")
		_carried_turret_data.clear()
	
	_placed_turrets.append(turret)
	turret_placed.emit(turret)
	var placed_token_id := _selected_build_token
	if not placed_token_id.is_empty():
		build_token_placed.emit(turret, placed_token_id)
	
	exit_placement_mode()
	return true


func _attempt_place_build_token(position: Vector2) -> bool:
	var build_token_id := _selected_build_token
	if build_token_id.is_empty() or not BUILD_TOKEN_TO_PLACEABLE.has(build_token_id):
		_emit_build_placement_failed("unknown_build_token")
		return false
	if not _can_place_at(position):
		_emit_build_placement_failed("invalid_site")
		return false
	var definition: Dictionary = BUILD_TOKEN_TO_PLACEABLE[build_token_id]
	var scene: PackedScene = definition.get("scene", null)
	if scene == null:
		_emit_build_placement_failed("scene_unavailable")
		return false
	var instance := scene.instantiate() as Node2D
	if instance == null:
		_emit_build_placement_failed("scene_instantiate_failed")
		return false
	if not _consume_build_token(build_token_id):
		instance.free()
		_emit_build_placement_failed("token_unavailable")
		return false
	get_parent().add_child(instance)
	instance.global_position = position
	if instance.has_method("begin_construction"):
		instance.call("begin_construction")
	_placed_structures.append(instance)
	build_token_placed.emit(instance, build_token_id)
	_observe_infrastructure_event(&"infrastructure_foundation_committed", {
		"build_token_id": build_token_id,
		"position": position,
	})
	exit_placement_mode()
	return true


func set_preview_world_position(position: Vector2) -> bool:
	if not _is_placing:
		return false
	_preview_override_active = true
	_preview_override_world_pos = position
	_update_ghost_preview(position)
	return _placement_valid


func clear_preview_world_override() -> void:
	_preview_override_active = false


func attempt_place_turret_at(position: Vector2) -> bool:
	if not _is_placing or _selected_turret_type.is_empty():
		return false
	return _attempt_place_turret(position)


func attempt_place_build_at(position: Vector2) -> bool:
	if not _is_placing:
		return false
	return _attempt_place_selected(position)


func get_preview_world_position() -> Vector2:
	if _ghost_preview == null:
		return Vector2.ZERO
	return _ghost_preview.global_position


func get_placement_valid() -> bool:
	return _placement_valid


func get_placed_turrets() -> Array[Node2D]:
	return _placed_turrets


func get_placed_structures() -> Array[Node2D]:
	_prune_placed_structures()
	return _placed_structures


func pick_up_turret(turret: Node2D) -> bool:
	if turret == null or not is_instance_valid(turret):
		return false
	var turret_type := _infer_turret_type(turret)
	if turret_type.is_empty():
		return false
	_prune_placed_turrets()
	_placed_turrets.erase(turret)
	_carried_turret_data = {
		"active": true,
		"type": turret_type,
		"current_health": float(turret.get("current_health")) if "current_health" in turret else 0.0,
		"state": String(turret.get("state")) if "state" in turret else "operational",
	}
	turret.queue_free()
	turret_picked_up.emit(turret_type)
	return enter_placement_mode(turret_type)


func get_material_count() -> int:
	if _game_state == null:
		return 0
	return int(_game_state.get("materials"))


func get_cost_for_type(turret_type: String) -> int:
	return int(TURRET_COSTS.get(turret_type, 0))


func _has_build_token_for_turret(turret_type: String) -> bool:
	var token_id := _get_build_token_for_turret(turret_type)
	if token_id.is_empty():
		return false
	var build_inventory := _get_build_inventory()
	return build_inventory != null and int(build_inventory.call("get_amount", token_id)) > 0


func _consume_build_token_for_turret(turret_type: String) -> bool:
	var token_id := _get_build_token_for_turret(turret_type)
	if token_id.is_empty():
		return false
	var build_inventory := _get_build_inventory()
	return build_inventory != null and bool(build_inventory.call("remove", token_id, 1))


func _refund_build_token_for_turret(turret_type: String) -> void:
	var token_id := _get_build_token_for_turret(turret_type)
	if token_id.is_empty():
		return
	var build_inventory := _get_build_inventory()
	if build_inventory != null:
		build_inventory.call("add", token_id, 1)


func _get_build_token_for_turret(turret_type: String) -> String:
	return String(TURRET_BUILD_TOKENS.get(turret_type, ""))


func get_turret_type_for_build_token(build_token_id: String) -> String:
	for turret_type_variant in TURRET_BUILD_TOKENS.keys():
		var turret_type := str(turret_type_variant)
		if String(TURRET_BUILD_TOKENS[turret_type_variant]) == build_token_id:
			return turret_type
	return ""


func get_build_token_for_turret_type(turret_type: String) -> String:
	return _get_build_token_for_turret(turret_type)


func get_placeable_type_for_build_token(build_token_id: String) -> String:
	var definition: Dictionary = BUILD_TOKEN_TO_PLACEABLE.get(build_token_id, {})
	return String(definition.get("placeable_type", ""))


func enter_build_token_placement(build_token_id: String) -> bool:
	var definition: Dictionary = BUILD_TOKEN_TO_PLACEABLE.get(build_token_id, {})
	if definition.is_empty() or not _has_build_token(build_token_id):
		return false
	var placeable_type := String(definition.get("placeable_type", ""))
	var kind := String(definition.get("kind", ""))
	_selected_build_token = build_token_id
	_selected_placeable_type = placeable_type
	if kind == "turret":
		if enter_placement_mode(placeable_type):
			return true
		_selected_build_token = ""
		_selected_placeable_type = ""
		return false
	if kind != "structure" or definition.get("scene", null) == null:
		_selected_build_token = ""
		_selected_placeable_type = ""
		return false
	_selected_turret_type = ""
	_is_placing = true
	_ghost_preview.visible = true
	placement_mode_changed.emit(true)
	if _ui != null and _ui.has_method("enter_placement_mode_ui"):
		_ui.enter_placement_mode_ui()
	return true


func _get_build_inventory() -> Node:
	return get_node_or_null("/root/BuildInventory")


func _has_build_token(build_token_id: String) -> bool:
	var build_inventory := _get_build_inventory()
	return build_inventory != null and int(build_inventory.call("get_amount", build_token_id)) > 0


func _consume_build_token(build_token_id: String) -> bool:
	var build_inventory := _get_build_inventory()
	return build_inventory != null and bool(build_inventory.call("remove", build_token_id, 1))


func _emit_build_placement_failed(reason: String) -> void:
	if not _selected_build_token.is_empty():
		build_placement_failed.emit(_selected_build_token, reason)
		_observe_infrastructure_event(&"infrastructure_package_placement_rejected", {
			"build_token_id": _selected_build_token,
			"reason": reason,
		})


func _observe_infrastructure_event(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)


func _infer_turret_type(turret: Node2D) -> String:
	if turret == null:
		return ""
	if "turret_type" in turret:
		var raw_type = turret.get("turret_type")
		if raw_type is String:
			return String(raw_type).to_lower()
		if raw_type is int:
			match int(raw_type):
				0:
					return "gunner"
				1:
					return "blaster"
				2:
					return "repeater"
				3:
					return "sniper"
	for type in turret_scenes.keys():
		var scene: PackedScene = turret_scenes.get(type, null)
		if scene != null and turret.scene_file_path == scene.resource_path:
			return String(type)
	return ""


func _prune_placed_turrets() -> void:
	_placed_turrets = _placed_turrets.filter(func(turret: Node2D) -> bool:
		return turret != null and is_instance_valid(turret)
	)


func _prune_placed_structures() -> void:
	_placed_structures = _placed_structures.filter(func(structure: Node2D) -> bool:
		return structure != null and is_instance_valid(structure)
	)


func get_tilemap_layer(layer_name: String) -> TileMapLayer:
	if layer_name != "Floor":
		return null
	var procgen_map := get_tree().get_first_node_in_group("procgen_tilemap")
	if procgen_map != null and procgen_map.has_method("get_floor_tilemap"):
		return procgen_map.call("get_floor_tilemap") as TileMapLayer
	return null


func _get_world_mouse_position() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		return camera.get_global_mouse_position()
	return Vector2.ZERO


func attempt_dismantle(turret: Node2D) -> int:
	_prune_placed_turrets()
	if not _placed_turrets.has(turret):
		return 0
	
	var turret_type := _infer_turret_type(turret)
	var refund: int = int(TURRET_REFUNDS.get(turret_type, 5))
	
	_placed_turrets.erase(turret)
	
	if _game_state and _game_state.has_method("add_materials"):
		_game_state.add_materials(refund)
	
	turret.queue_free()
	turret_dismantled.emit(turret, refund)
	
	return refund
