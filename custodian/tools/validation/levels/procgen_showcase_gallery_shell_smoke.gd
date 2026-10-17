extends SceneTree

const LEVEL_SCENE := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.tscn")
const PLAYTEST_SCENE := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_playtest.tscn")
const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")
const EXPECTED_WINGS := [&"terrain", &"topology", &"sites", &"population", &"presentation"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await process_frame
	errors.append_array(_check_destination(level))
	_check_wrapper(errors)
	_check_registry(errors)
	await _check_ingress_return(errors)
	level.queue_free()
	await process_frame
	_finish(errors)


func _check_destination(level: Node) -> Array[String]:
	var errors: Array[String] = []
	for forbidden_name in ["Operator", "PlayerController", "Camera2D"]:
		if level.find_child(forbidden_name, true, false) != null:
			errors.append("production destination owns forbidden runtime node %s" % forbidden_name)
	if level.get_node_or_null("Collision/PathBoundaryCollision") == null:
		errors.append("authored boundary collision root missing")
	var boundary := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null or boundary.get_child_count() != 10:
		errors.append("expected seven outer bounds and three arena-threshold rail segments")
	var threshold := level.call("get_arena_threshold_segment") as Array
	var found_sealed_threshold := false
	if boundary != null:
		for child in boundary.get_children():
			if child.has_meta("boundary_a") and child.has_meta("boundary_b"):
				var a: Vector2 = child.get_meta("boundary_a")
				var b: Vector2 = child.get_meta("boundary_b")
				if a.is_equal_approx(threshold[0]) and b.is_equal_approx(threshold[1]):
					found_sealed_threshold = true
	if not found_sealed_threshold:
		errors.append("central arena threshold is not backed by authored collision")
	var marker_root := level.get_node_or_null("Markers")
	if marker_root == null:
		errors.append("authored marker root missing")
		return errors
	for marker_name in ["Spawn_Main", "Return_Main", "ArenaThreshold"]:
		if marker_root.get_node_or_null(marker_name) == null:
			errors.append("required marker %s is missing" % marker_name)
	var wing_ids: Array = level.call("get_gallery_wing_ids")
	if wing_ids != EXPECTED_WINGS:
		errors.append("gallery must expose exactly the five named exhibit wings")
	var regions: Array = level.call("get_gallery_floor_regions")
	if not _all_regions_connected(regions):
		errors.append("authored floor rectangles do not form one connected walkable region")
	for wing_id: StringName in EXPECTED_WINGS:
		var marker := level.get_node_or_null("PropsRoot/%sExhibitMarker" % String(wing_id).to_pascal_case()) as Marker2D
		if marker == null or not bool(marker.get_meta("placeholder_exhibit", false)):
			errors.append("wing %s lacks its neutral exhibit marker" % wing_id)
			continue
		if not _region_contains(regions, marker.position):
			errors.append("wing %s marker is outside authored floor" % wing_id)
	var exit := level.get_node_or_null("Exits/Exit_Main") as InteractableLevelExit2D
	if exit == null or exit.exit_id != &"return_world" or exit.trigger_on_body_entered:
		errors.append("return must use the explicit standard return_world route exit")
	elif exit.get_node_or_null("CollisionShape2D") == null or exit.global_position.distance_to((marker_root.get_node("Return_Main") as Node2D).global_position) > 1.0:
		errors.append("return exit collision/anchor does not match Return_Main")
	if level.find_child("ProcGenTilemap", true, false) != null or level.find_child("ProcGenMap", true, false) != null:
		errors.append("PGA-1 must not instantiate or fake a generated map")
	return errors


func _all_regions_connected(regions: Array) -> bool:
	if regions.is_empty():
		return false
	var reached := {0: true}
	var changed := true
	while changed:
		changed = false
		for left in range(regions.size()):
			if not reached.has(left):
				continue
			for right in range(regions.size()):
				if reached.has(right) or not _rectangles_touch(regions[left], regions[right]):
					continue
				reached[right] = true
				changed = true
	return reached.size() == regions.size()


func _rectangles_touch(left: Rect2, right: Rect2) -> bool:
	return left.grow(0.01).intersects(right)


func _region_contains(regions: Array, point: Vector2) -> bool:
	for region: Rect2 in regions:
		if region.has_point(point):
			return true
	return false


func _check_wrapper(errors: Array[String]) -> void:
	var wrapper := PLAYTEST_SCENE.instantiate()
	for node_name in ["Operator", "PlayerController", "Camera2D"]:
		if _count_named_nodes(wrapper, node_name) != 1:
			errors.append("standalone playtest must own exactly one %s" % node_name)
	for system_name in ["Combat", "NavigationSystem", "EnemyDirector", "WaveManager"]:
		if wrapper.get_node_or_null(system_name) == null:
			errors.append("standalone playtest is missing standard %s root" % system_name)
	var operator := wrapper.get_node_or_null("World/Operator")
	if operator == null or operator.get_script() == null or operator.get_script().resource_path != "res://game/actors/operator/operator.gd":
		errors.append("standalone wrapper does not instantiate the real Operator")
	if wrapper.get_node_or_null("World/Level/Operator") != null or wrapper.get_node_or_null("World/Level/Camera2D") != null:
		errors.append("production destination duplicates wrapper-owned presentation")
	wrapper.free()


func _count_named_nodes(parent: Node, target_name: String) -> int:
	var count := 1 if String(parent.name) == target_name else 0
	for child in parent.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _check_registry(errors: Array[String]) -> void:
	var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	if not bool(registry.call("load_index", "res://content/levels/levels.json")):
		errors.append_array(Array(registry.call("get_errors")))
		return
	var definition: RefCounted = registry.call("get_level", &"procgen_showcase_gallery")
	if definition == null:
		errors.append("procgen_showcase_gallery is not registered")
		return
	if not definition.has_tag(&"dev") or not definition.has_tag(&"world_ingress"):
		errors.append("gallery registration must remain dev-only and world-ingress enabled")
	if definition.call("get_entry_scene_path") != "res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery.tscn":
		errors.append("gallery definition points to the wrong production scene")
	if definition.ingress == null or definition.ingress.ingress_id != &"procgen_showcase_gallery" or definition.ingress.target_spawn_id != &"Spawn_Main":
		errors.append("gallery ingress must target the stable main spawn")
	if definition.call("get_lifecycle").get("state_policy", "") != "reset_on_entry":
		errors.append("gallery must reset on entry")


func _check_ingress_return(errors: Array[String]) -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "procgen_showcase_gallery", &"gameplay", &"Spawn_Main")
	var loader: Node = fixture.loader
	loader.set("_registry", null)
	loader.registry_index_path = "res://content/levels/levels.json"
	var ingress: Node = fixture.ingress
	ingress.call("configure_level", &"procgen_showcase_gallery", fixture.procgen)
	if loader.call("get_definition", &"procgen_showcase_gallery") == null:
		errors.append("registered gallery definition is unavailable to the lifecycle loader")
		fixture.game_root.free()
		return
	var actor: Node2D = fixture.actor
	var original_position := actor.global_position
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	await process_frame
	var first_level: Node = loader.call("get_active_level_instance") as Node
	if first_level == null:
		errors.append("registered ingress failed to enter gallery")
	else:
		if actor != fixture.actor or actor.global_position.distance_to(Vector2(-1220, 0)) > 2.0:
			errors.append("gallery entry replaced the Operator or missed Spawn_Main")
		var exit := first_level.get_node_or_null("Exits/Exit_Main") as InteractableLevelExit2D
		if exit == null:
			errors.append("active gallery has no return exit")
		else:
			actor.global_position = first_level.get_node("Markers/Return_Main").global_position
			exit.interact(actor)
		await process_frame
		if actor != fixture.actor or not actor.global_position.is_equal_approx(original_position):
			errors.append("return failed to preserve the original Operator and position")
		if loader.call("get_active_level_instance") != null:
			errors.append("return retained an active gallery instance")
		if bool(ingress.call("is_triggered")):
			errors.append("ingress remained locked after return")
		if exit != null:
			ingress.set("_triggered", true)
			ingress.call("_enter_approach", actor)
			await process_frame
			var second_level: Node = loader.call("get_active_level_instance") as Node
			if second_level == null or second_level == first_level:
				errors.append("reset-on-entry did not create a fresh gallery on re-entry")
			elif second_level.get_node_or_null("Markers/Spawn_Main") == null:
				errors.append("re-entered gallery lost its stable spawn")
			if second_level != null:
				var second_exit := second_level.get_node_or_null("Exits/Exit_Main") as InteractableLevelExit2D
				actor.global_position = second_level.get_node("Markers/Return_Main").global_position
				if second_exit != null:
					second_exit.interact(actor)
				await process_frame
				if actor != fixture.actor or not actor.global_position.is_equal_approx(original_position):
					errors.append("re-entry return changed the Operator or source position")
	fixture.game_root.free()


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[ProcgenShowcaseGalleryShellSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[ProcgenShowcaseGalleryShellSmoke] %s" % error)
	quit(1)
