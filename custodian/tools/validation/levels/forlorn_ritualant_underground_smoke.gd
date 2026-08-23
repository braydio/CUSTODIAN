extends SceneTree

const LEVEL_SCENE := preload(
	"res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"
)
const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY_SCRIPT := preload("res://game/world/routes/route_registry.gd")
const RETIRED_SPECIAL_ROOM_PATH := (
	"res://content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	if FileAccess.file_exists(RETIRED_SPECIAL_ROOM_PATH):
		errors.append("retired Ritualant special-room definition still exists")

	var level := LEVEL_SCENE.instantiate()
	get_root().add_child(level)
	await process_frame
	if not (level is AuthoredLevel2D):
		errors.append("production scene does not extend AuthoredLevel2D")
	else:
		var authored_level := level as AuthoredLevel2D
		if not authored_level.has_spawn(&"Spawn_DescentLanding"):
			errors.append("Spawn_DescentLanding does not resolve")
		elif authored_level.get_spawn_position(&"Spawn_DescentLanding") != Vector2(0.0, 1670.0):
			errors.append("Spawn_DescentLanding is not on the lower lift")
		if authored_level.get_camera_bounds() != Rect2(-1792.0, -2048.0, 3584.0, 4096.0):
			errors.append("authored Underground camera bounds are not 3584x4096")

	if level.get_node_or_null("PlayableRoot/ForlornRitualantSite") == null:
		errors.append("existing ForlornRitualantSite is not instanced")
	var exit := level.get_node_or_null("Exits/Exit_ReturnWorld") as LevelExit2D
	if exit == null or exit.exit_id != &"return_world":
		errors.append("return_world authored exit is missing")
	elif exit.trigger_on_body_entered:
		errors.append("lower lift still triggers travel on body entry")
	elif not exit.is_in_group("interactable"):
		errors.append("lower lift exit is not interactable")
	if level.get_node_or_null("PropsRoot/LowerLiftAssembly") == null:
		errors.append("shared lower lift assembly is missing")
	var underlay_quad := level.get_node_or_null(
		"PlayableRoot/ForlornRitualantSite/ForlornRitualantShaderFX/VoidUnderlay/RoomSizedQuad"
	) as TextureRect
	if underlay_quad == null:
		errors.append("explicit fixed room underlay quad is missing")
	elif underlay_quad.size != Vector2(1120.0, 864.0):
		errors.append("room underlay quad is not 1120x864")
	elif underlay_quad.material == null:
		errors.append("room underlay quad lacks explicit mask material")
	else:
		var shader_code := (underlay_quad.material as ShaderMaterial).shader.code
		if shader_code.find("room_silhouette_mask") < 0:
			errors.append("cosmic underlay shader does not sample room mask")
		if shader_code.find("void_reveal") < 0:
			errors.append("cosmic underlay shader lacks explicit reveal authority")
	if level.call("get_boundary_segments").size() != 50:
		errors.append("authored Underground boundary loop is incomplete")
	if level.call("get_walkable_probes").is_empty() \
			or level.call("get_void_probes").is_empty():
		errors.append("authored floor/void validation probes are missing")
	if level.find_child("ExitTrigger", true, false) != null:
		errors.append("legacy encounter exit trigger still competes with authored route")
	var marker_state := level.call("get_authoring_marker_state") as Dictionary
	if marker_state.size() != 3:
		errors.append("underground mapper must expose exactly three authoritative records")
	for marker_id: String in ["descent_landing", "return_world", "encounter_origin"]:
		if not marker_state.has(marker_id):
			errors.append("underground mapper is missing %s" % marker_id)
	if level.find_child("Return_CaveMouth", true, false) != null:
		errors.append("duplicate return marker still exists beside authoritative exit")
	if not FileAccess.file_exists("res://scenes/debug/forlorn_ritualant_underground_mapper.tscn"):
		errors.append("Forlorn Ritualant room mapper scene is missing")

	var levels: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	var levels_loaded := bool(levels.call("load_index"))
	if not levels_loaded:
		for error: String in levels.call("get_errors"):
			errors.append("level registry: %s" % error)
	elif levels.call("get_level", &"forlorn_ritualant_underground") == null:
		errors.append("authored Underground level is not registered")

	var routes: RefCounted = ROUTE_REGISTRY_SCRIPT.new()
	var routes_loaded := false
	if levels_loaded:
		routes_loaded = bool(routes.call(
			"load_index",
			ROUTE_REGISTRY_SCRIPT.DEFAULT_INDEX_PATH,
			levels
		))
		if not routes_loaded:
			for error: String in routes.call("get_errors"):
				errors.append("route registry: %s" % error)
	if routes_loaded:
		var route := routes.call(
			"get_route",
			&"forlorn_ritualant_underground"
		) as RefCounted
		if route == null:
			errors.append("authored Underground route is not registered")
		elif route.call("get_node_definition", &"ritual_cavern") == null:
			errors.append("ritual_cavern route node does not resolve")

	level.queue_free()
	await process_frame
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[ForlornRitualantUndergroundSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("[ForlornRitualantUndergroundSmoke] %s" % error)
	quit(1)
