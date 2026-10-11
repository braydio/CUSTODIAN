extends SceneTree

const LEVEL_SCENE := preload("res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena.tscn")
const PLAYTEST_SCENE := preload("res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena_playtest.tscn")
const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")

const SOCKETS := {
	"BrokenWarrantSocket": Vector2(-1024.0, 32.0),
	"MarineSocket": Vector2(-96.0, -128.0),
	"SavageSocket": Vector2(96.0, 128.0),
	"VaultwingSocket": Vector2(928.0, -128.0),
	"EscortFrameM7Socket": Vector2(1120.0, 128.0),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await process_frame
	_check_level_scene(level, errors)
	await _probe_walkability(level, errors)
	_check_wrapper(errors)
	_check_registry(errors)
	await _check_ingress_return(errors)
	level.queue_free()
	await process_frame
	_finish(errors)


func _check_level_scene(level: Node, errors: Array[String]) -> void:
	for forbidden_name in ["Operator", "PlayerController", "Camera2D"]:
		if level.find_child(forbidden_name, true, false) != null:
			errors.append("production destination owns forbidden runtime node %s" % forbidden_name)
	if level.get_node_or_null("Collision/PathBoundaryCollision") == null:
		errors.append("authored boundary collision root missing")
	var boundary := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null or boundary.get_child_count() != 12:
		errors.append("expected four outer rails and eight doorway-separated divider segments")
	var zone_ids: Array = level.call("get_showcase_zone_ids")
	if zone_ids.size() != 5:
		errors.append("arena must expose exactly five authored zones")
	var zones := level.get_tree().get_nodes_in_group("npa_showcase_zone")
	if zones.size() != 5:
		errors.append("expected five walkable zone roots, found %d" % zones.size())
	for zone in zones:
		var floor := zone.get_node_or_null("WalkableFloor") as Polygon2D
		var lane := zone.get_node_or_null("ConnectedWalkLane") as Polygon2D
		if floor == null or floor.polygon.size() != 4 or lane == null or lane.polygon.size() != 4:
			errors.append("zone %s lacks a bounded floor and connected route lane" % zone.name)
	var markers := level.get_node_or_null("Markers")
	if markers == null or markers.get_node_or_null("Spawn_Main") == null or markers.get_node_or_null("Return_Main") == null:
		errors.append("named Spawn_Main and Return_Main anchors are required")
	var exit := level.get_node_or_null("Exits/Exit_Main") as InteractableLevelExit2D
	if exit == null or exit.exit_id != &"return_world" or exit.get_node_or_null("CollisionShape2D") == null:
		errors.append("return_world must use the standard explicit InteractableLevelExit2D route exit")
	else:
		if exit.trigger_on_body_entered:
			errors.append("return exit must require explicit interaction")
		if exit.global_position.distance_to((markers.get_node("Return_Main") as Node2D).global_position) > 1.0:
			errors.append("return exit is not located at Return_Main")
	var sockets_root := level.get_node_or_null("EventMarkers/ActorSockets")
	if sockets_root == null or sockets_root.get_child_count() != SOCKETS.size():
		errors.append("expected exactly five empty actor sockets")
	else:
		for socket_name: String in SOCKETS:
			var socket := sockets_root.get_node_or_null(socket_name) as Marker2D
			if socket == null or not bool(socket.get_meta("empty_actor_socket", false)):
				errors.append("missing empty actor socket %s" % socket_name)
				continue
			if not socket.position.is_equal_approx(SOCKETS[socket_name]):
				errors.append("actor socket position drifted: %s" % socket_name)
			if socket.get_child_count() != 0:
				errors.append("actor socket %s must not instantiate an actor" % socket_name)
	var scenarios := level.get_node_or_null("EventRuntime/ScenarioRoots")
	if scenarios == null or scenarios.get_child_count() != 5:
		errors.append("expected one safe scenario root for each zone")
	else:
		for scenario in scenarios.get_children():
			if scenario.process_mode != Node.PROCESS_MODE_DISABLED or scenario.get_child_count() != 0:
				errors.append("scenario root %s must remain empty and disabled" % scenario.name)
	var return_world: Node2D = markers.get_node("Return_Main") if markers != null else null
	if return_world == null or return_world.global_position.distance_to(Vector2(-2200.0, 300.0)) > 1.0:
		errors.append("return anchor is outside the authored arrival zone")
	for socket_name: String in SOCKETS:
		var socket := sockets_root.get_node_or_null(socket_name) as Marker2D if sockets_root != null else null
		if socket == null or not Rect2(-2560.0, -768.0, 5120.0, 1536.0).has_point(socket.global_position):
			errors.append("socket %s is outside the bounded walkable arena" % socket_name)


func _check_wrapper(errors: Array[String]) -> void:
	var wrapper := PLAYTEST_SCENE.instantiate()
	for node_name in ["Operator", "PlayerController", "Camera2D"]:
		if _count_named_nodes(wrapper, node_name) != 1:
			errors.append("standalone playtest must own exactly one %s" % node_name)
	for system_name in ["Combat", "NavigationSystem", "EnemyDirector", "WaveManager"]:
		if wrapper.get_node_or_null(system_name) == null:
			errors.append("standalone playtest is missing standard %s root" % system_name)
	var wave_manager := wrapper.get_node_or_null("WaveManager")
	if wave_manager != null and bool(wave_manager.get("debug_spawn_grunt_on_start")):
		errors.append("showcase wrapper must not auto-spawn an unrelated debug grunt")
	if wrapper.get_node_or_null("World/Level/Operator") != null:
		errors.append("production destination must not duplicate the wrapper Operator")
	if wrapper.get_node_or_null("World/Level/PlayerController") != null or wrapper.get_node_or_null("World/Level/Camera2D") != null:
		errors.append("production destination must not duplicate wrapper controller or camera")
	var operator := wrapper.get_node_or_null("World/Operator")
	if operator == null or operator.get_script() == null or operator.get_script().resource_path != "res://game/actors/operator/operator.gd":
		errors.append("standalone wrapper does not instantiate the production Operator scene")
	wrapper.free()


func _count_named_nodes(parent: Node, target_name: String) -> int:
	var count := 1 if String(parent.name) == target_name else 0
	for child in parent.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _probe_walkability(level: Node2D, errors: Array[String]) -> void:
	var probe := CharacterBody2D.new()
	probe.name = "ValidationWalkabilityProbe"
	probe.position = Vector2(-2048.0, 0.0)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	shape_node.shape = shape
	probe.add_child(shape_node)
	level.add_child(probe)
	await physics_frame
	for next_room_x in [-1024.0, 0.0, 1024.0, 2048.0]:
		var collision := probe.move_and_collide(Vector2(1024.0, 0.0))
		if collision != null or absf(probe.global_position.x - next_room_x) > 2.0:
			errors.append("walkability probe could not cross doorway into zone centered at x=%s" % str(next_room_x))
			break
	var perimeter_collision := probe.move_and_collide(Vector2(0.0, -1024.0))
	if perimeter_collision == null:
		errors.append("walkability probe escaped the outer collision boundary")
	probe.queue_free()
	await physics_frame


func _check_registry(errors: Array[String]) -> void:
	var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	if not bool(registry.call("load_index", "res://content/levels/levels.json")):
		errors.append_array(Array(registry.call("get_errors")))
		return
	var definition: RefCounted = registry.call("get_level", &"npa_showcase_arena")
	if definition == null:
		errors.append("npa_showcase_arena is not in the level registry")
		return
	if not definition.has_tag(&"dev") or not definition.has_tag(&"world_ingress"):
		errors.append("registered arena must be dev-only and world-ingress enabled")
	if definition.call("get_entry_scene_path") != "res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena.tscn":
		errors.append("level registry points to the wrong production destination")
	if definition.ingress == null or definition.ingress.ingress_id != &"npa_showcase_arena" or definition.ingress.target_spawn_id != &"Spawn_Main":
		errors.append("registered ingress does not target the stable main spawn")
	if str(definition.get("playtest_scene_path")) != "res://game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena_playtest.tscn":
		errors.append("registered level is missing its standalone playtest scene")
	var lifecycle: Dictionary = definition.call("get_lifecycle")
	if str(lifecycle.get("state_policy", "")) != "reset_on_entry" or str(lifecycle.get("cache_policy", "")) != "snapshot_and_unload":
		errors.append("arena lifecycle must reset state across re-entry")


func _check_ingress_return(errors: Array[String]) -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "npa_showcase_arena", &"gameplay", &"Spawn_Main")
	var loader: Node = fixture.loader
	loader.set("_registry", null)
	loader.registry_index_path = "res://content/levels/levels.json"
	var ingress: Node = fixture.ingress
	ingress.call("configure_level", &"npa_showcase_arena", fixture.procgen)
	if loader.call("get_definition", &"npa_showcase_arena") == null:
		errors.append("real arena definition is unavailable to the lifecycle loader")
		fixture.game_root.free()
		return
	var actor: Node2D = fixture.actor
	var camera: Node = fixture.camera
	var origin_position := actor.global_position
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	await process_frame
	var first_level: Node = loader.call("get_active_level_instance") as Node
	if first_level == null:
		errors.append("registered ingress failed to enter the showcase")
	else:
		if first_level.name != "NpaShowcaseArena":
			errors.append("registered ingress loaded the wrong destination")
		if actor != fixture.actor or camera != fixture.camera or actor.global_position.distance_to(Vector2(-2200.0, 0.0)) > 2.0:
			errors.append("entry did not preserve and place the fixture Operator at Spawn_Main")
		var first_exit := first_level.get_node_or_null("Exits/Exit_Main") as InteractableLevelExit2D
		if first_exit == null:
			errors.append("entered showcase has no explicit route return")
		else:
			actor.global_position = first_level.get_node("Markers/Return_Main").global_position
			if first_exit.get_interaction_prompt() != "RETURN TO MAIN WORLD":
				errors.append("return exit does not expose its explicit interaction prompt")
			first_exit.interact(actor)
		await process_frame
		if actor != fixture.actor or camera != fixture.camera or not actor.global_position.is_equal_approx(origin_position):
			errors.append("return replaced the Operator/camera or lost the captured origin position")
		if loader.call("get_active_level_instance") != null:
			errors.append("return retained an active arena instance")
		if bool(ingress.call("is_triggered")):
			errors.append("ingress remained locked after return")
		ingress.set("_triggered", true)
		ingress.call("_enter_approach", actor)
		await process_frame
		var second_level: Node = loader.call("get_active_level_instance") as Node
		if second_level == null:
			errors.append("operator could not re-enter the showcase")
		elif second_level == first_level:
			errors.append("reset-on-entry reused the prior arena instance")
		if second_level != null:
			var second_exit := second_level.get_node_or_null("Exits/Exit_Main") as InteractableLevelExit2D
			if second_exit == null:
				errors.append("re-entered showcase has no explicit route return")
			else:
				actor.global_position = second_level.get_node("Markers/Return_Main").global_position
				second_exit.interact(actor)
			await process_frame
			if actor != fixture.actor or not actor.global_position.is_equal_approx(origin_position):
				errors.append("re-entry/return did not retain the same Operator and source position")
	fixture.game_root.free()


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[NpaShowcaseArenaFoundationSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[NpaShowcaseArenaFoundationSmoke] %s" % error)
	quit(1)
