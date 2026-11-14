extends Node2D
class_name ProcgenArenaHost

signal staging_finished(status: Dictionary)

const REGION_SCRIPT := preload("res://game/world/levels/generated_region_level.gd")
const GENERATION_SCENE := "res://game/world/procgen/proc_gen_map.tscn"
const PROFILE_ID := "sundered_keep_ascent"
const GENERATION_SEED := 417203
const MAP_SIZE := [96, 96]
const ROOM_COUNT := 12
const SPAWN_ID: StringName = &"ArenaSpawn"
const ENTRY_POSITION := Vector2(0, -440)
const MINIMUM_SEPARATION := 256.0
const PERFORMANCE_SNAPSHOT_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_performance_snapshot.gd")
const EXHIBIT_CATALOG_SCRIPT := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_exhibit_catalog.gd")
const PROFILE_PATHS := {
	"sundered_keep_ascent": "res://content/procgen/world_profiles/sundered_keep_ascent.json",
}

var _generation_request := {
	"preset_id": "ascent_compact",
	"seed": GENERATION_SEED,
	"map_size": MAP_SIZE.duplicate(),
	"room_count": ROOM_COUNT,
	"profile_id": PROFILE_ID,
}

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
var _staging_complete := false
var _session_managed := false
var _session_accepted := true
var _interaction_enabled := true
var _generation_fingerprint := ""
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
	var request_error := _validate_generation_request(_generation_request)
	if not request_error.is_empty():
		_last_failure = request_error
		_set_status("ARENA UNAVAILABLE")
		_finish_staging()
		return
	var world := _gallery.get_parent()
	var world_operator := world.get_node_or_null("Operator") if world != null else null
	var world_camera := world.get_node_or_null("Camera2D") if world != null else null
	if not world_operator is Node2D or not world_camera is Camera2D:
		_last_failure = "arena staging requires the existing world Operator and camera"
		_set_status("ARENA UNAVAILABLE")
		_finish_staging()
		return
	if _session_managed:
		call_deferred("_stage_generated_region")
		return
	await _stage_generated_region()


func _stage_generated_region() -> void:
	if _cancelled or not is_inside_tree():
		_last_failure = "generation cancelled before staging began"
		_finish_staging()
		return
	_region = REGION_SCRIPT.new()
	_region.name = "GeneratedArenaRegionStaging" if _session_managed and not _session_accepted else "GeneratedArenaRegion"
	_gallery.add_child(_region)
	var staging_margin := float(maxi(MAP_SIZE[0], MAP_SIZE[1])) * 32.0
	_region.position = Vector2(_gallery_world_bounds().end.x + MINIMUM_SEPARATION + staging_margin, 0.0)
	var profile_id := str(_generation_request.get("profile_id", PROFILE_ID))
	var profile := _load_profile(profile_id)
	if profile.is_empty():
		_last_failure = "arena world profile could not be loaded"
		_set_status("ARENA UNAVAILABLE")
		_region.queue_free()
		_region = null
		_finish_staging()
		return
	var result: Dictionary = await _region.call("prepare_generated_region", {
		"scene_path": GENERATION_SCENE,
		"seed": int(_generation_request.get("seed", GENERATION_SEED)),
		"map_size": _generation_request.get("map_size", MAP_SIZE),
		"room_count": int(_generation_request.get("room_count", ROOM_COUNT)),
		"profile_id": profile_id,
		"profile": profile,
		"spawns": [SPAWN_ID],
	})
	if _cancelled or not is_inside_tree():
		_dispose_region()
		_finish_staging()
		return
	if not bool(result.get("succeeded", false)):
		_last_failure = str(result.get("reason", "generated arena staging failed"))
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		_finish_staging()
		return
	if not bool(_region.call("has_spawn", SPAWN_ID)):
		_last_failure = "generated arena did not expose its named canonical spawn"
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		_finish_staging()
		return
	var map := _region.call("get_generated_map") as Node
	var floor_layer := map.call("get_floor_tilemap") as TileMapLayer if map != null else null
	if floor_layer == null:
		_last_failure = "generated arena has no accepted floor layer"
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		_finish_staging()
		return
	_ensure_region_separation(floor_layer)
	_arena_bounds = _get_map_bounds(map, floor_layer)
	if _arena_bounds.size == Vector2.ZERO or _arena_bounds.intersects(_gallery_world_bounds().grow(MINIMUM_SEPARATION)):
		_last_failure = "generated arena bounds overlap the authored gallery"
		_set_status("ARENA UNAVAILABLE")
		_dispose_region()
		_finish_staging()
		return
	map.visible = false
	map.process_mode = Node.PROCESS_MODE_DISABLED
	_generation_fingerprint = PERFORMANCE_SNAPSHOT_SCRIPT.fingerprint_generation(map as ProcGenTilemap)
	_entry_ready = true
	_status_label.text = "INTERACT · ENTER GENERATED ARENA"
	_finish_staging()
	if _session_managed and not _session_accepted:
		set_interaction_enabled(false)


func configure_generation_request(request: Dictionary) -> bool:
	if is_inside_tree() or _staging_complete:
		return false
	if not _validate_generation_request(request).is_empty():
		return false
	_generation_request = request.duplicate(true)
	_session_managed = true
	_session_accepted = false
	_interaction_enabled = false
	return true


func set_session_accepted(accepted: bool) -> void:
	_session_managed = true
	_session_accepted = accepted
	if accepted and is_instance_valid(_region):
		_region.name = "GeneratedArenaRegion"
	set_interaction_enabled(accepted)


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if is_instance_valid(_status_label) and _entry_ready:
		_status_label.visible = enabled or _arena_active


func dispose_if_safe() -> bool:
	if _arena_active or _transitioning:
		return false
	cancel_generation()
	if is_inside_tree():
		queue_free()
	return true


func _validate_generation_request(request: Dictionary) -> String:
	var seed_value := int(request.get("seed", -1))
	var map_size: Variant = request.get("map_size", [])
	var profile_id := str(request.get("profile_id", ""))
	if seed_value < 0 or seed_value > 2147483647:
		return "generation seed must be in the supported non-negative 32-bit range"
	if not map_size is Array or map_size.size() != 2 or int(map_size[0]) != 96 or int(map_size[1]) != 96:
		return "generation preset map size is not runtime-validated"
	if int(request.get("room_count", -1)) != ROOM_COUNT:
		return "generation preset room count is not runtime-validated"
	if not PROFILE_PATHS.has(profile_id):
		return "generation preset profile is not runtime-validated"
	if str(request.get("preset_id", "")) != "ascent_compact":
		return "generation preset ID is unknown"
	return ""


func _finish_staging() -> void:
	_staging_complete = true
	staging_finished.emit(get_arena_status())


func get_interaction_position() -> Vector2:
	if _arena_active and _region != null and bool(_region.call("has_spawn", SPAWN_ID)):
		return _region.call("get_spawn_position", SPAWN_ID) as Vector2
	return _gallery.to_global(ENTRY_POSITION) if _gallery != null else global_position


func get_interaction_distance() -> float:
	return 96.0


func can_interact(actor: Node = null) -> bool:
	if not _interaction_enabled or _transitioning or not is_instance_valid(actor) or not (actor is Node2D):
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
		"seed": int(_generation_request.get("seed", GENERATION_SEED)),
		"profile_id": str(_generation_request.get("profile_id", PROFILE_ID)),
		"preset_id": str(_generation_request.get("preset_id", "ascent_compact")),
		"map_size": _generation_request.get("map_size", MAP_SIZE),
		"room_count": int(_generation_request.get("room_count", ROOM_COUNT)),
		"map_bounds": _arena_bounds,
		"staging_complete": _staging_complete,
		"generation_fingerprint": _generation_fingerprint,
		"interaction_enabled": _interaction_enabled,
	}


## Returns only detached values for the gallery inspector; no runtime owner or
## map reference crosses this boundary.
func get_inspector_snapshot() -> Dictionary:
	if not _session_accepted or not is_instance_valid(_region) or not _region.has_method("get_generated_map"):
		return {}
	var map := _region.call("get_generated_map") as ProcGenTilemap
	if not is_instance_valid(map):
		return {}
	var level_data: Dictionary = map.call("get_level_data")
	var health: Dictionary = map.call("get_runtime_health_snapshot")
	var spawn: Vector2i = map.call("get_player_spawn")
	var component: Dictionary = map.call("get_main_playable_component")
	var host_status := get_arena_status()
	var floor_layer := map.call("get_floor_tilemap") as TileMapLayer
	var layers := {
		"terrain": _sample_cell_positions(level_data.get("floor_cells", []), floor_layer),
		"route": _sample_cell_positions(level_data.get("main_route_centerline_cells", level_data.get("main_route_cells", [])), floor_layer, false),
		"playability": _sample_cell_positions(_dictionary_keys(component), floor_layer),
		"vistas": _sample_cell_positions(level_data.get("vista_cells", []), floor_layer),
		"sites": _sample_site_positions(level_data, floor_layer),
	}
	var exact_exhibits := _matching_exhibit_provenance(level_data)
	var detached_data := {}
	for key in [
		"generation_id", "map_size", "wall_cells", "route_playability",
		"route_playability_audit", "biome_summary", "biome_id_by_cell", "region_tiles",
		"faction_activity_sites", "story_room_sites", "special_room_sites",
	]:
		if level_data.has(key):
			detached_data[key] = _copy_value(level_data[key])
	return {
		"schema": "custodian.procgen_showcase_inspector_snapshot.v1",
		"generation_fingerprint": str(host_status.get("generation_fingerprint", "")),
		"generation_id": str(level_data.get("generation_id", "")),
		"seed": int(host_status.get("seed", -1)),
		"preset_id": str(host_status.get("preset_id", "")),
		"profile_id": str(host_status.get("profile_id", "")),
		"map_size": _copy_value(host_status.get("map_size", Vector2i.ZERO)),
		"room_count": int(host_status.get("room_count", 0)),
		"map_bounds": _copy_value(host_status.get("map_bounds", Rect2())),
		"spawn": spawn,
		"spawn_valid": bool(map.call("is_valid_spawn_cell", spawn)),
		"spawn_navigation_walkable": bool(map.call("is_runtime_navigation_walkable", spawn)),
		"playable_component_count": component.size(),
		"operator_in_arena": bool(host_status.get("active", false)),
		"counts": {
			"floor": int(health.get("floor_cells", 0)),
			"walls": int(health.get("wall_cells", 0)),
			"route": _array_size(level_data.get("main_route_cells", [])),
			"vistas": _array_size(level_data.get("vista_cells", [])),
			"sites": _site_count(level_data),
		},
		"layers": layers,
		"layer_limits": {"terrain": 1024, "route": 1024, "playability": 1024, "vistas": 1024, "sites": 1024},
		"health": _select_health(health),
		"exhibit_provenance": exact_exhibits,
		"available_fields": {
			"route": level_data.has("main_route_cells"),
			"sites": level_data.has("faction_activity_sites") or level_data.has("story_room_sites") or level_data.has("special_room_sites"),
			"biome_provenance": not exact_exhibits.is_empty(),
		},
		"data": detached_data,
	}


func _sample_cell_positions(raw_cells: Variant, floor_layer: TileMapLayer, sort_cells: bool = true) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if floor_layer == null or not raw_cells is Array:
		return result
	var cells: Array = raw_cells.duplicate()
	if sort_cells:
		cells.sort_custom(func(a: Variant, b: Variant) -> bool:
			if not a is Vector2i or not b is Vector2i:
				return str(a) < str(b)
			return a.y < b.y if a.y != b.y else a.x < b.x
		)
	var stride := maxi(1, ceili(float(cells.size()) / 1024.0))
	for index in range(0, cells.size(), stride):
		var cell: Variant = cells[index]
		if cell is Vector2i:
			result.append(_cell_to_gallery_position(cell, floor_layer))
	return result


func _sample_site_positions(level_data: Dictionary, floor_layer: TileMapLayer) -> Array[Vector2]:
	var cells: Array[Vector2i] = []
	for key in ["faction_activity_sites", "story_room_sites", "special_room_sites"]:
		var sites: Variant = level_data.get(key, [])
		if not sites is Array:
			continue
		for site: Variant in sites:
			if site is Dictionary and site.get("cell") is Vector2i:
				cells.append(site.cell)
	return _sample_cell_positions(cells, floor_layer)


func _cell_to_gallery_position(cell: Vector2i, floor_layer: TileMapLayer) -> Vector2:
	var world_position := floor_layer.to_global(floor_layer.map_to_local(cell))
	return _gallery.to_local(world_position) if is_instance_valid(_gallery) else world_position


func _dictionary_keys(source: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key: Variant in source.keys():
		if key is Vector2i:
			result.append(key)
	return result


func _matching_exhibit_provenance(level_data: Dictionary) -> Array[Dictionary]:
	var observed_ids: Dictionary = {}
	var biome_ids: Variant = level_data.get("biome_id_by_cell", {})
	if biome_ids is Dictionary:
		for biome_id in biome_ids.values():
			observed_ids[str(biome_id)] = true
	var regions: Variant = level_data.get("region_tiles", {})
	if regions is Dictionary:
		for region: Variant in regions.values():
			if region is Dictionary:
				observed_ids[str(region.get("region_type", ""))] = true
	var report: Dictionary = EXHIBIT_CATALOG_SCRIPT.load_report()
	var matches: Array[Dictionary] = []
	for entry: Variant in report.get("valid", []):
		if not entry is Dictionary:
			continue
		var authority_id := str(entry.get("source_authority_id", ""))
		if not authority_id.is_empty() and observed_ids.has(authority_id):
			matches.append({
				"exhibit_id": str(entry.get("exhibit_id", "")),
				"source_authority_path": str(entry.get("source_authority_path", "")),
				"source_authority_id": authority_id,
			})
	return matches


func _select_health(health: Dictionary) -> Dictionary:
	var result := {}
	for key in ["floor_cells", "wall_cells", "runtime_wall_body_count", "navigation_revision", "painted_floor_cell_count", "painted_wall_cell_count"]:
		if health.has(key):
			result[key] = health[key]
	return result


func _copy_value(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			if not key is Object:
				result[_copy_value(key)] = _copy_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_copy_value(item))
		return result
	if value is Object:
		return null
	return value


func _array_size(value: Variant) -> int:
	return value.size() if value is Array else 0


func _site_count(level_data: Dictionary) -> int:
	return _array_size(level_data.get("faction_activity_sites", [])) \
		+ _array_size(level_data.get("story_room_sites", [])) \
		+ _array_size(level_data.get("special_room_sites", []))


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


func _load_profile(profile_id: String) -> Dictionary:
	var profile_path := str(PROFILE_PATHS.get(profile_id, ""))
	if profile_path.is_empty() or not FileAccess.file_exists(profile_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _dispose_region() -> void:
	if _region != null and is_instance_valid(_region):
		_region.queue_free()
	_region = null
	_entry_ready = false
	_arena_bounds = Rect2()
