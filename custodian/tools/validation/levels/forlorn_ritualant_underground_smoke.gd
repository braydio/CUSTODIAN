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
		elif authored_level.get_spawn_position(&"Spawn_DescentLanding") != Vector2(0.0, 224.0):
			errors.append("Spawn_DescentLanding is not clear of the internal exit trigger")
		if authored_level.get_camera_bounds().size != Vector2(1120.0, 864.0):
			errors.append("authored chamber camera bounds are not 1120x864")

	if level.get_node_or_null("PlayableRoot/ForlornRitualantSite") == null:
		errors.append("existing ForlornRitualantSite is not instanced")
	var exit := level.get_node_or_null("Exits/Exit_ReturnWorld") as LevelExit2D
	if exit == null or exit.exit_id != &"return_world":
		errors.append("return_world authored exit is missing")

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
