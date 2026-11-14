extends Node2D
class_name ProcgenArenaHost

const REGION_SCRIPT := preload("res://game/world/levels/generated_region_level.gd")
const GENERATION_SCENE := "res://game/world/procgen/proc_gen_map.tscn"
const PROFILE_PATH := "res://content/procgen/world_profiles/sundered_keep_ascent.json"
const PROFILE_ID := "sundered_keep_ascent"
const GENERATION_SEED := 417203
const MAP_SIZE := [96, 96]
const ROOM_COUNT := 12
const SPAWN_ID: StringName = &"ArenaSpawn"
const ENTRY_POSITION := Vector2(0, -440)
const MINIMUM_SEPARATION := 256.0

var _gallery: Node2D
var _region: Node
var _operator: Node2D
var _camera: Camera2D
var _camera_parent: Node
var _camera_index := -1
var _arena_bounds := Rect2()
var _entry_ready := false
var _arena_active := false
var _transitioning := false
var _cancelled := false
var _gallery_return_position := Vector2.ZERO
var _last_failure := ""
var _status_label: Label


func _ready() -> void:
	add_to_group("interactable")
	_gallery = get_parent() as Node2D
	if _gallery == null:
		_last_failure = "arena host requires its authored gallery parent"
		return
	_status_label = Label.new()
	_status_label.name = "ArenaInteractionLabel"
	_status_label.text = "GENERATED ARENA · STAGING"
	_status_label.position = ENTRY_POSITION + Vector2(-150, -52)
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.modulate = Color("#f0d89d")
	add_child(_status_label)
	var world := _gallery.get_parent()
	var world_operator := world.get_node_or_null("Operator") if world != null else null
	var world_camera := world.get_node_or_null("Camera2D") if world != null else null
	if not world_operator is Node2D or not world_camera is Camera2D:
		_last_failure = "arena staging requires the existing world Operator and camera"
		_set_status("ARENA UNAVAILABLE")
		return
	_region = REGION_SCRIPT.new()
	_region.name = "GeneratedArenaRegion"
	_gallery.add_child(_region)
	var staging_margin := float(maxi(MAP_SIZE[0], MAP_SIZE[1])) * 32.0
	_region.position = Vector2(_gallery_world_bounds().end.x + MINIMUM_SEPARATION + staging_margin, 0.0)
	var profile := _load_profile()
	if profile.is_empty():
		_last_failure = "arena world profile could not be loaded"
		_set_status("ARENA UNAVAILABLE")
		_region.queue_free()
		_region = null
		return
	var result: Dictionary = await _region.call("prepare_generated_region", {
		"scene_path": GENERATION_SCENE,
		"seed": GENERATION_SEED,
		"map_size": MAP_SIZE,
		"room_count": ROOM_COUNT,
		"profile_id": PROFILE_ID,
		"profile": profile,
		"spawns": [SPAWN_ID],
	})
	if _cancelled or not is_inside_tree():
		_dispose_region()
		return
	if not bool(result.get("succeeded", false)):
		_last_failure = str(result.get("reason", "generated arena staging failed"))
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		return
	if not bool(_region.call("has_spawn", SPAWN_ID)):
		_last_failure = "generated arena did not expose its named canonical spawn"
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		return
	var map := _region.call("get_generated_map") as Node
	var floor_layer := map.call("get_floor_tilemap") as TileMapLayer if map != null else null
	if floor_layer == null:
		_last_failure = "generated arena has no accepted floor layer"
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		return
	_ensure_region_separation(floor_layer)
	_arena_bounds = _get_map_bounds(map, floor_layer)
	if _arena_bounds.size == Vector2.ZERO or _arena_bounds.intersects(_gallery_world_bounds().grow(MINIMUM_SEPARATION)):
		_last_failure = "generated arena bounds overlap the authored gallery"
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		return
	map.visible = false
	map.process_mode = Node.PROCESS_MODE_DISABLED
	_entry_ready = true
	_status_label.text = "INTERACT · ENTER GENERATED ARENA"


func get_interaction_position() -> Vector2:
	if _arena_active and _region != null and bool(_region.call("has_spawn", SPAWN_ID)):
		return _region.call("get_spawn_position", SPAWN_ID) as Vector2
	return _gallery.to_global(ENTRY_POSITION) if _gallery != null else global_position


func get_interaction_distance() -> float:
	return 96.0


func can_interact(actor: Node = null) -> bool:
	if _transitioning or not is_instance_valid(actor) or not (actor is Node2D):
		return false
	if _arena_active:
		return actor == _operator and _region != null and is_instance_valid(_region)
	return _entry_ready and actor.is_in_group("player") and _region != null and is_instance_valid(_region)


func get_interaction_prompt() -> String:
	if _transitioning:
		return ""
	if _arena_active:
		return "RETURN TO PROCGEN GALLERY" if _operator != null else ""
	if _entry_ready:
		return "ENTER GENERATED ARENA"
	return "ARENA GENERATING" if _last_failure.is_empty() else "ARENA UNAVAILABLE"


func interact(actor: Node) -> void:
	if not can_interact(actor):
		return
	if _arena_active:
		_return_to_gallery(actor as Node2D)
	else:
		_enter_arena(actor as Node2D)


func cancel_generation() -> void:
	_cancelled = true
	_entry_ready = false
	if not _arena_active:
		_dispose_region()


func _exit_tree() -> void:
	_cancelled = true
	if _arena_active and is_instance_valid(_operator) and is_instance_valid(_gallery):
		_operator.global_position = _gallery_return_position
		_ensure_camera_attached()
		_gallery.call("refresh_route_camera", _operator)
		_arena_active = false
	_operator = null
	_dispose_region()


func get_arena_status() -> Dictionary:
	return {
		"ready": _entry_ready,
		"active": _arena_active,
		"transitioning": _transitioning,
		"failure": _last_failure,
		"seed": GENERATION_SEED,
		"profile_id": PROFILE_ID,
		"map_bounds": _arena_bounds,
	}


func _enter_arena(actor: Node2D) -> void:
	if _transitioning or not _entry_ready:
		return
	_transitioning = true
	var prior_position := actor.global_position
	_gallery_return_position = prior_position
	_operator = actor
	_camera = get_node_or_null("/root/GameRoot/World/Camera2D") as Camera2D
	_camera_parent = _camera.get_parent() if is_instance_valid(_camera) else null
	_camera_index = _camera.get_index() if is_instance_valid(_camera) else -1
	var map := _region.call("get_generated_map") as Node
	if _camera == null or map == null:
		_last_failure = "arena entry requires the existing world camera and generated map"
		_operator = null
		_transitioning = false
		return
	map.visible = true
	map.process_mode = Node.PROCESS_MODE_INHERIT
	var activated := bool(_region.call("activate_route_node", actor, SPAWN_ID))
	if not activated:
		actor.global_position = prior_position
		var gallery_restored := _restore_gallery_camera(actor)
		map.visible = false
		map.process_mode = Node.PROCESS_MODE_DISABLED
		_dispose_region()
		_operator = null
		_camera = null
		_last_failure = "generated arena activation failed; gallery state restored" if gallery_restored else "generated arena activation failed; gallery camera restoration failed"
		_set_status("ARENA UNAVAILABLE")
		if not gallery_restored:
			push_error(_last_failure)
		_transitioning = false
		return
	_arena_active = true
	_entry_ready = false
	_status_label.text = "INTERACT · RETURN TO GALLERY"
	_transitioning = false


func _return_to_gallery(actor: Node2D) -> void:
	if _transitioning or actor != _operator:
		return
	_transitioning = true
	var prior_position := actor.global_position
	actor.global_position = _gallery_return_position
	if not _restore_gallery_camera(actor):
		actor.global_position = prior_position
		if _restore_region_camera(actor):
			_transitioning = false
			_last_failure = "gallery camera restoration failed; generated arena remains active"
			return
		actor.global_position = _gallery_return_position
		if _restore_gallery_camera(actor):
			_finish_gallery_return()
			return
		actor.global_position = prior_position
		_transitioning = false
		_last_failure = "camera could not be restored to a validated route; arena retained"
		push_error(_last_failure)
		return
	_finish_gallery_return()


func _finish_gallery_return() -> void:
	_arena_active = false
	_entry_ready = false
	_operator = null
	_camera = null
	_camera_parent = null
	_camera_index = -1
	_dispose_region()
	_status_label.text = "GENERATED ARENA · REOPEN THE GALLERY TO REGENERATE"
	_transitioning = false
	_last_failure = ""


func _restore_gallery_camera(actor: Node) -> bool:
	if not _ensure_camera_attached():
		return false
	return bool(_gallery.call("refresh_route_camera", actor)) and _camera.call("get_runtime_map") == _gallery


func _restore_region_camera(actor: Node) -> bool:
	if not _ensure_camera_attached() or not is_instance_valid(_region):
		return false
	var map := _region.call("get_generated_map") as Node
	return bool(_region.call("refresh_route_camera", actor)) and _camera.call("get_runtime_map") == map


func _ensure_camera_attached() -> bool:
	if not is_instance_valid(_camera) or not is_instance_valid(_camera_parent) or not _camera_parent.is_inside_tree():
		return false
	if not _camera.is_inside_tree():
		_camera_parent.add_child(_camera)
		if _camera_index >= 0:
			_camera_parent.move_child(_camera, mini(_camera_index, _camera_parent.get_child_count() - 1))
	return _camera.is_inside_tree()


func _set_status(message: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = message


func _ensure_region_separation(floor_layer: TileMapLayer) -> void:
	var gallery_bounds := _gallery_world_bounds()
	var used := floor_layer.get_used_rect()
	var local_left := floor_layer.map_to_local(Vector2i(used.position.x, used.position.y))
	var global_left := floor_layer.to_global(local_left)
	var needed_x := gallery_bounds.end.x + MINIMUM_SEPARATION - global_left.x
	if needed_x > 0.0:
		_region.position.x += needed_x


func _get_map_bounds(map: Node, floor_layer: TileMapLayer) -> Rect2:
	var procgen := map.get("procgen_node") as Node
	if procgen == null:
		return Rect2()
	var size: Vector2i = procgen.get("map_size")
	if size.x <= 0 or size.y <= 0:
		return Rect2()
	var corners: Array[Vector2] = [
		floor_layer.to_global(floor_layer.map_to_local(Vector2i(0, 0))),
		floor_layer.to_global(floor_layer.map_to_local(Vector2i(size.x - 1, 0))),
		floor_layer.to_global(floor_layer.map_to_local(Vector2i(0, size.y - 1))),
		floor_layer.to_global(floor_layer.map_to_local(Vector2i(size.x - 1, size.y - 1))),
	]
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for point in corners:
		low = low.min(point)
		high = high.max(point)
	var half_tile := Vector2(floor_layer.tile_set.tile_size) * 0.5
	return Rect2(low - half_tile, high - low + half_tile * 2.0)


func _gallery_world_bounds() -> Rect2:
	var bounds: Rect2 = _gallery.call("get_camera_bounds")
	return bounds


func _load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	return parsed as Dictionary if parsed is Dictionary else {}


func _dispose_region() -> void:
	if _region != null and is_instance_valid(_region):
		_region.queue_free()
	_region = null
	_entry_ready = false
	_arena_bounds = Rect2()

