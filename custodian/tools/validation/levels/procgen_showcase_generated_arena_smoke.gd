extends SceneTree

const PLAYTEST_SCENE := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_playtest.tscn")
const HOST_PATH := "ProcgenArenaHost"
const MAX_GENERATION_FRAMES := 1800


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var game := PLAYTEST_SCENE.instantiate() as Node2D
	game.name = "GameRoot"
	root.add_child(game)
	await process_frame
	var world := game.get_node("World") as Node2D
	var gallery := world.get_node("Level") as Node2D
	var host := gallery.get_node(HOST_PATH) as Node
	var operator := world.get_node("Operator") as Node2D
	var camera := world.get_node("Camera2D") as Camera2D
	var camera_parent := camera.get_parent()
	var operator_id := operator.get_instance_id()
	var wait_frames := 0
	while not bool(host.call("get_arena_status").get("ready", false)) and wait_frames < MAX_GENERATION_FRAMES:
		if not str(host.call("get_arena_status").get("failure", "")).is_empty():
			break
		await process_frame
		wait_frames += 1
	var status: Dictionary = host.call("get_arena_status")
	if not bool(status.get("ready", false)):
		errors.append("real generated arena did not stage: %s" % str(status.get("failure", "timeout after %d frames" % wait_frames)))
		_finish(game, errors)
		return
	var region := gallery.get_node_or_null("GeneratedArenaRegion") as Node
	if region == null or not region.has_method("get_generated_map"):
		errors.append("arena host did not retain its generated-region owner")
		_finish(game, errors)
		return
	var map := region.call("get_generated_map") as Node
	if map == null or not map is ProcGenTilemap:
		errors.append("arena staging did not use a real ProcGenTilemap")
	else:
		var procgen := map.get("procgen_node") as Node
		var spawn_cell: Vector2i = map.call("get_player_spawn")
		var component: Dictionary = map.call("get_main_playable_component")
		if procgen == null or int(procgen.get("seed")) != 417203:
			errors.append("arena generation seed was not explicit and stable")
		if procgen == null or procgen.get("map_size") != Vector2i(96, 96):
			errors.append("arena generation dimensions were not 96x96")
		if not component.has(spawn_cell) or not bool(map.call("is_valid_spawn_cell", spawn_cell)) or not bool(map.call("is_runtime_navigation_walkable", spawn_cell)):
			errors.append("generated arena spawn is not accepted and navigation-walkable")
		if not bool(region.call("has_spawn", &"ArenaSpawn")):
			errors.append("generated region omitted its named ArenaSpawn")
		if map.visible or map.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("staged arena should be hidden and inactive before interaction")
	var gallery_bounds: Rect2 = gallery.call("get_camera_bounds")
	var map_bounds: Rect2 = status.get("map_bounds", Rect2())
	if not _world_rect_contains_local_rect(gallery, gallery_bounds, Rect2(-1, -1, 2, 2)):
		errors.append("gallery camera bounds are not expressed in the gallery world coordinates")
	for floor_region: Rect2 in gallery.call("get_gallery_floor_regions"):
		if not _world_rect_contains_local_rect(gallery, gallery_bounds, floor_region):
			errors.append("gallery camera bounds omit an authored playable floor region")
			break
	for segment: Array in gallery.call("get_boundary_segments"):
		if segment.size() != 2 or not gallery_bounds.has_point(gallery.to_global(segment[0])) or not gallery_bounds.has_point(gallery.to_global(segment[1])):
			errors.append("gallery camera bounds omit an authored collision rail endpoint")
			break
	if map_bounds.position.x < gallery_bounds.end.x + 256.0:
		errors.append("generated map does not preserve the 256-world-unit gap beyond the complete gallery envelope")
	if map_bounds.intersects(gallery_bounds.grow(256.0)):
		errors.append("generated map bounds overlap the protected authored gallery envelope")
	if camera.call("get_runtime_map") != gallery:
		errors.append("staging changed the active gallery camera binding")
	var boundary := gallery.get_node("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null or boundary.get_child_count() != 10:
		errors.append("arena entry modified the sealed threshold collision rail")
	if _count_named_nodes(game, "ProcgenArenaHost") != 1 or _count_named_nodes(game, "GeneratedArenaRegion") != 1:
		errors.append("gallery owns duplicate arena hosts or generated regions")

	# Missing camera must fail closed before moving the Operator or accepting entry.
	var prior_position := operator.global_position
	camera_parent.remove_child(camera)
	host.call("interact", operator)
	if operator.global_position != prior_position or bool(host.call("get_arena_status").get("active", false)):
		errors.append("failed entry changed Operator position or arena ownership")
	camera_parent.add_child(camera)
	await process_frame

	host.call("interact", operator)
	if not bool(host.call("get_arena_status").get("active", false)):
		errors.append("explicit arena interaction did not commit entry")
	if operator.get_instance_id() != operator_id or operator != world.get_node("Operator"):
		errors.append("arena entry replaced the existing Operator")
	if _count_named_nodes(game, "Operator") != 1 or _count_named_nodes(game, "Camera2D") != 1:
		errors.append("arena entry created a duplicate Operator or camera")
	if _count_named_nodes(game, "Level") != 1:
		errors.append("arena entry created a duplicate authored LevelLoader destination")
	if not status.get("map_bounds", Rect2()).has_point(operator.global_position):
		errors.append("Operator did not arrive inside the accepted generated map bounds")
	if camera.call("get_runtime_map") != map:
		errors.append("arena entry did not bind the existing camera to the generated map")
	var entered_position := operator.global_position
	host.call("_enter_arena", operator)
	if operator.global_position != entered_position:
		errors.append("double entry moved the Operator a second time")

	# Simulate a failed gallery rebind; the host must keep a usable generated route.
	host.set("_camera", null)
	host.call("interact", operator)
	if not bool(host.call("get_arena_status").get("active", false))  or operator.global_position != entered_position or camera.call("get_runtime_map") != map:
		errors.append("failed return did not preserve a safe Operator and camera on the arena")
	host.set("_camera", camera)
	host.call("interact", operator)
	if bool(host.call("get_arena_status").get("active", true)):
		errors.append("deliberate return interaction did not leave the arena")
	if operator.global_position.distance_to(prior_position) > 0.1:
		errors.append("arena return did not restore the original safe gallery position")
	if camera.call("get_runtime_map") != gallery:
		errors.append("arena return did not restore the gallery camera binding")
	await process_frame
	if gallery.get_node_or_null("GeneratedArenaRegion") != null:
		errors.append("returned arena map owner was not cleaned up")

	host.call("cancel_generation")
	await process_frame
	if bool(host.call("get_arena_status").get("ready", false)):
		errors.append("cancelled arena host remained interactable")
	_finish(game, errors)


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if node.name == target_name else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _world_rect_contains_local_rect(owner: Node2D, world_bounds: Rect2, local_rect: Rect2) -> bool:
	var corners: Array[Vector2] = [
		owner.to_global(local_rect.position),
		owner.to_global(Vector2(local_rect.end.x, local_rect.position.y)),
		owner.to_global(local_rect.end),
		owner.to_global(Vector2(local_rect.position.x, local_rect.end.y)),
	]
	for corner in corners:
		if not world_bounds.has_point(corner):
			return false
	return true


func _finish(game: Node, errors: Array[String]) -> void:
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
	if errors.is_empty():
		print("PROCGEN_SHOWCASE_GENERATED_ARENA_SMOKE_PASS")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
