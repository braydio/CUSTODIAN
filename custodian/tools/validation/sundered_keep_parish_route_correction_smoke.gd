extends SceneTree

const APPROACH_SCENE := preload(
	"res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
)
const KEEP_SCENE := preload(
	"res://game/world/sundered_keep/sundered_keep_map.tscn"
)
const ROUTE_PATH := "res://content/routes/sundered_keep/sundered_keep_route.json"
const PARISH_PATH := "res://content/levels/sundered_keep/sundered_keep_approach_outskirts.json"

const ASSETS := {
	"res://content/sprites/world/return_causeway/path/overlays/sundered_keep_shore_parish_northbound_ground_01.png": Vector2i(768, 1024),
	"res://content/sprites/world/return_causeway/path/overlays/sundered_keep_outer_wall_east_traverse_ground_01.png": Vector2i(1024, 640),
	"res://content/backgrounds/sundered_keep/approach/near_detail/sundered_keep_outer_wall_checkpoint_detail_01.png": Vector2i(2048, 1024),
	"res://content/masters/sundered_keep/overlays/sundered_keep_front_gate_south_arrival_apron_01.png": Vector2i(2048, 1024),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var route := _read_json(ROUTE_PATH)
	var production := _profile(route, "production")
	for edge_id in ["enter_vista", "vista_to_keep_direct", "keep_to_vista_direct"]:
		var edge := _edge(route, edge_id)
		_check(str(edge.get("transition_style", "")) == "fade", "%s is not fade" % edge_id, errors)
		_check((production.get("enabled_edge_ids", []) as Array).has(edge_id), "%s is not production-enabled" % edge_id, errors)
	var route_text := JSON.stringify(route)
	_check(not route_text.contains("playable_blackout"), "production route contains playable blackout", errors)
	_check(not route_text.contains("occluded_handoff"), "production route contains occluded handoff", errors)

	for path in ASSETS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_check(not image.is_empty(), "asset did not load: %s" % path, errors)
		if not image.is_empty():
			_check(image.get_size() == ASSETS[path], "asset dimensions drifted: %s" % path, errors)
			_check(image.detect_alpha() != Image.ALPHA_NONE, "asset has no alpha: %s" % path, errors)

	var parish := _read_json(PARISH_PATH)
	var overlays := parish.get("visual_overlays", []) as Array
	_check(overlays.size() == 4, "Parish does not author four supplied overlays", errors)
	var exit_x := float((parish["markers"]["level_exit"]["position"] as Array)[0])
	_check(exit_x >= 1220.0 and exit_x <= 1280.0, "Parish exit is not at the extended terminal", errors)
	var fog_record := _overlay(overlays, "outer_wall_checkpoint_fog")
	_check(str(fog_record.get("kind", "")) == "procedural_fog_ribbon", "fog metadata is not procedural", errors)
	_check(not fog_record.has("texture_path"), "procedural fog still references an authored texture", errors)
	var fog_tint := fog_record.get("fog_tint", []) as Array
	_check(fog_tint.size() == 4 and float(fog_tint[3]) <= 0.3, "fog alpha exceeds 0.30", errors)
	_check(not ResourceLoader.exists("res://content/backgrounds/sundered_keep/approach/fog/outer_wall_checkpoint_fog_ribbon_01.png"), "retired fog sheet still exists", errors)

	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var actor := Node2D.new()
	actor.name = "Operator"
	world.add_child(actor)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var approach := APPROACH_SCENE.instantiate()
	root.add_child(approach)
	await process_frame
	await process_frame
	var fog := approach.get_node_or_null("UnderlayRoot/OuterWallCheckpointFog") as Sprite2D
	_check(fog is ProceduralFogRibbon2D and fog.material is ShaderMaterial, "runtime procedural fog contract failed", errors)
	var controller := approach.get_node_or_null("VistaController")
	var camera_state := controller.call("get_reveal_choreography_state") as Dictionary if controller != null else {}
	_check(str(camera_state.get("second_camera_phase", "")) == "SECOND_DISABLED", "Parish Camera 2 is not disabled", errors)
	_check(approach.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") == null, "full-screen final veil still exists", errors)

	var keep := KEEP_SCENE.instantiate()
	root.add_child(keep)
	await process_frame
	await process_frame
	var backtrack := keep.get_node_or_null("Exits/Exit_Backtrack") as LevelExit2D
	_check(backtrack != null and backtrack.arrival_guard_radius >= 144.0, "Front Gate arrival guard is below 144", errors)
	var keep_state := keep.call("get_sundered_keep_debug_state") as Dictionary
	_check(bool(keep_state.get("arrival_overlay_present", false)), "Front Gate arrival apron is missing", errors)
	var spawn := keep.find_child("EntrySpawn", true, false) as Node2D
	if spawn != null and backtrack != null:
		_check(spawn.global_position.distance_to(backtrack.global_position) >= 128.0, "spawn overlaps backtrack exit", errors)

	game_root.queue_free()
	approach.queue_free()
	keep.queue_free()
	await process_frame
	if errors.is_empty():
		print("[SunderedKeepParishRouteCorrectionSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepParishRouteCorrectionSmoke] %s" % error)
	quit(1)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _edge(route: Dictionary, edge_id: String) -> Dictionary:
	for item in route.get("edges", []):
		if str((item as Dictionary).get("edge_id", "")) == edge_id:
			return item as Dictionary
	return {}


func _profile(route: Dictionary, profile_id: String) -> Dictionary:
	for item in route.get("profiles", []):
		if str((item as Dictionary).get("profile_id", "")) == profile_id:
			return item as Dictionary
	return {}


func _overlay(overlays: Array, overlay_id: String) -> Dictionary:
	for item in overlays:
		if str((item as Dictionary).get("id", "")) == overlay_id:
			return item as Dictionary
	return {}


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)
