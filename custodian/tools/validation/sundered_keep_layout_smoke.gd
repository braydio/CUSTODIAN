extends SceneTree

const SUNDERED_KEEP_MAP := preload("res://game/world/sundered_keep/sundered_keep_map.gd")

const REQUIRED_NODES := [
	"ReturnMooringInteraction",
	"MainGateInteraction",
	"GreatHallDoorInteraction",
	"SunderedGateKeyPickup",
	"SidearmLockerInteraction",
	"ReturnToMainMapGate",
	"Collision/PrefabGatehouseGateBlocker",
	"Collision/GreatHallDoorBlocker",
]
const TILE_SIZE := 32.0


func _init() -> void:
	var map := SUNDERED_KEEP_MAP.new()
	root.add_child(map)
	await process_frame

	for node_path in REQUIRED_NODES:
		_assert(map.get_node_or_null(node_path) != null, "missing required node: %s" % node_path)

	var state := map.get_sundered_keep_debug_state()
	_assert(int(state["floor_sprites"]) > 0, "no floor sprites placed")
	_assert(int(state["wall_sprites"]) > 0, "no wall sprites placed")
	_assert(int(state["prop_sprites"]) > 0, "no prop sprites placed")
	_assert(int(state["blocker_bodies"]) > 0, "no blocker bodies placed")
	_assert(int(state["interactable_areas"]) >= 4, "expected at least four interactables")
	_assert(state["main_gate_open"] == false, "main gate must start closed")
	_assert(state["great_hall_door_open"] == false, "great hall door must start closed")
	_assert(state["key_pickup_exists"] == true, "key pickup missing")
	_assert(state["sidearm_locker_exists"] == true, "sidearm locker missing")
	_assert(state["sidearm_locker_opened"] == false, "sidearm locker must start unopened")
	_assert(state["return_mooring_created"] == true, "return mooring was not created")
	_assert((state["map_size_tiles"] as Vector2i).x >= 96, "Sundered Keep map width did not expand")
	_assert((state["map_size_tiles"] as Vector2i).y >= 72, "Sundered Keep map height did not expand")
	_assert(map.get_entry_position() != Vector2.ZERO, "entrance tile did not resolve")
	_assert(map.get_return_gate_position() != Vector2.ZERO, "return gate tile did not resolve")
	_assert(not _has_blocker_covering_tile(map, Vector2i(56, 76)), "southern causeway spawn tile is blocked")
	_assert(_has_blocker_covering_tile(map, Vector2i(56, 78)), "submerged causeway continuation is not blocked")

	var missing_textures := _collect_missing_sprite_textures(map)
	for path in missing_textures:
		push_error("[SunderedKeepLayoutSmoke] Missing Sprite2D texture: %s" % path)
	_assert(missing_textures.is_empty(), "map contains Sprite2D nodes without textures")

	map.call("_try_open_main_gate")
	await process_frame
	_assert(map.get_node_or_null("Collision/PrefabGatehouseGateBlocker") != null, "gate opened without key")
	_assert(_has_blocker_covering_tile(map, Vector2i(55, 50)), "closed portcullis does not block the gate opening")
	_assert(_has_blocker_covering_tile(map, Vector2i(53, 50)), "left gate curtain can be walked around")
	_assert(_has_blocker_covering_tile(map, Vector2i(58, 50)), "right gate curtain can be walked around")

	map.call("_grant_sundered_gate_key")
	map.call("_try_open_main_gate")
	await process_frame
	state = map.get_sundered_keep_debug_state()
	_assert(state["main_gate_open"] == true, "main gate did not open after key acquisition")
	_assert(map.get_node_or_null("Collision/PrefabGatehouseGateBlocker") == null, "gate blocker remained after opening")
	_assert(not _has_blocker_covering_tile(map, Vector2i(55, 50)), "opened gate still blocks the route")
	_assert(_has_blocker_covering_tile(map, Vector2i(53, 50)), "left gate curtain was removed with the gate")
	_assert(_has_blocker_covering_tile(map, Vector2i(58, 50)), "right gate curtain was removed with the gate")
	_assert(_has_blocker_covering_tile(map, Vector2i(55, 30)), "great hall door does not start blocking its threshold")

	map.call("_try_open_great_hall_door")
	await process_frame
	state = map.get_sundered_keep_debug_state()
	_assert(state["great_hall_door_open"] == true, "great hall door did not open")
	_assert(map.get_node_or_null("Collision/GreatHallDoorBlocker") == null, "great hall door blocker remained after opening")
	_assert(not _has_blocker_covering_tile(map, Vector2i(55, 30)), "opened great hall door still blocks the route")

	print("[SunderedKeepLayoutSmoke] OK: mooring, key, gate, blockers, and textures validated")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[SunderedKeepLayoutSmoke] %s" % message)
	quit(1)


func _collect_missing_sprite_textures(node: Node, path := "") -> Array[String]:
	var current_path := path
	if current_path.is_empty():
		current_path = node.name
	else:
		current_path = "%s/%s" % [current_path, node.name]

	var missing: Array[String] = []
	if node is Sprite2D and (node as Sprite2D).texture == null:
		missing.append(current_path)
	for child in node.get_children():
		missing.append_array(_collect_missing_sprite_textures(child, current_path))
	return missing


func _has_blocker_covering_tile(map: Node, tile: Vector2i) -> bool:
	var collision := map.get_node_or_null("Collision")
	if collision == null:
		return false
	var point := Vector2((float(tile.x) + 0.5) * TILE_SIZE, (float(tile.y) + 0.5) * TILE_SIZE)
	for child in collision.get_children():
		if not (child is StaticBody2D):
			continue
		var body := child as StaticBody2D
		for shape_node in body.get_children():
			if not (shape_node is CollisionShape2D):
				continue
			var collision_shape := shape_node as CollisionShape2D
			if not (collision_shape.shape is RectangleShape2D):
				continue
			var rect_shape := collision_shape.shape as RectangleShape2D
			var center := body.position + collision_shape.position
			var rect := Rect2(center - rect_shape.size * 0.5, rect_shape.size)
			if rect.has_point(point):
				return true
	return false
