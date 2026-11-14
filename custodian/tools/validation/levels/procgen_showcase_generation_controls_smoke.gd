extends SceneTree

const PLAYTEST_SCENE := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_playtest.tscn")
const MAX_GENERATION_MSEC := 150000

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
	var session := gallery.get_node("ProcgenArenaSession") as Node
	if not is_instance_valid(session):
		_finish(game, ["gallery did not construct the generation session controller"])
		return
	var operator := world.get_node("Operator") as Node2D
	var camera := world.get_node("Camera2D") as Camera2D
	var operator_id := operator.get_instance_id()
	var camera_id := camera.get_instance_id()
	var level_id := world.get_node("LevelLoader").get_instance_id() if world.has_node("LevelLoader") else -1
	if not await _wait_until_ready(session):
		errors.append("initial real arena generation failed: %s" % _failure_detail(session))
		_finish(game, errors)
		return
	var initial_host := gallery.get_node_or_null("ProcgenArenaHost") as Node
	var initial_fingerprint := str(session.call("get_session_status").get("fingerprint", ""))
	if not is_instance_valid(initial_host) or initial_fingerprint.is_empty():
		errors.append("initial accepted arena host or semantic fingerprint is missing")
		_finish(game, errors)
		return
	if not bool(initial_host.call("can_interact", operator)):
		errors.append("first accepted arena is not interactable")
	var initial_map_count := _count_procgen_maps(game)

	# Explicit seed B then A verifies seed selection and A → B → A reproducibility.
	if not bool(session.call("reroll_explicit_seed", 417204)):
		errors.append("explicit-seed reroll was rejected")
	else:
		if bool(session.call("request_generation", 417203, "ascent_compact")):
			errors.append("overlapping generation request was accepted")
		if not await _wait_until_ready(session):
			errors.append("seed B generation failed: %s" % _failure_detail(session))
	var fingerprint_b := str(session.call("get_session_status").get("fingerprint", ""))
	if fingerprint_b == initial_fingerprint:
		errors.append("explicitly different seed produced the same semantic fingerprint")
	var seed_b_host := gallery.get_node_or_null("ProcgenArenaHost") as Node
	if not bool(session.call("regenerate_same_seed")):
		errors.append("same-seed regeneration request was rejected while idle")
	elif not await _wait_until_ready(session):
		errors.append("same-seed B repeat failed: %s" % str(session.call("get_session_status").get("error", "timeout")))
	elif str(session.call("get_session_status").get("fingerprint", "")) != fingerprint_b:
		errors.append("identical B seed/preset did not reproduce its semantic fingerprint")
	if gallery.get_node_or_null("ProcgenArenaHost") == seed_b_host:
		errors.append("accepted arena regeneration did not replace its host")
	await process_frame
	if _count_procgen_maps(game) != initial_map_count:
		errors.append("replacement leaked or duplicated a generated map")
	if not bool(session.call("reroll_explicit_seed", 417203)):
		errors.append("return to seed A was rejected")
	elif not await _wait_until_ready(session):
		errors.append("seed A regeneration failed: %s" % str(session.call("get_session_status").get("error", "timeout")))
	elif str(session.call("get_session_status").get("fingerprint", "")) != initial_fingerprint:
		errors.append("A → B → A did not restore the original semantic fingerprint")

	# Cancellation must invalidate its token and release the staging owner before retry.
	var host_before_cancel := gallery.get_node_or_null("ProcgenArenaHost") as Node
	var fingerprint_before_cancel := str(session.call("get_session_status").get("fingerprint", ""))
	if bool(session.call("request_generation", 517203, "ascent_compact")):
		if not bool(session.call("cancel_generation")):
			errors.append("in-flight generation could not be cancelled")
		var cancel_deadline := Time.get_ticks_msec() + 10000
		while int(session.call("get_session_status").get("staging_host_count", 0)) != 0 and Time.get_ticks_msec() < cancel_deadline:
			await process_frame
		if int(session.call("get_session_status").get("staging_host_count", 0)) != 0:
			errors.append("cancelled staging host did not release its session ownership")
		if gallery.get_node_or_null("ProcgenArenaHost") != host_before_cancel or not is_instance_valid(host_before_cancel):
			errors.append("cancelled candidate replaced the accepted arena")
		if str(session.call("get_session_status").get("fingerprint", "")) != fingerprint_before_cancel:
			errors.append("cancelled candidate changed the accepted fingerprint")
		if int(session.call("get_session_status").get("staging_host_count", 0)) == 0:
			if not bool(session.call("request_generation", 417203, "ascent_compact")):
				errors.append("retry was rejected after cancellation resources were released")
			elif not await _wait_until_ready(session):
				errors.append("retry after cancellation failed")
	else:
		errors.append("cancellation setup request was rejected")

	# Invalid input and Operator-in-arena generation must fail closed.
	var preserved_host := gallery.get_node_or_null("ProcgenArenaHost") as Node
	if bool(session.call("request_generation", -1, "ascent_compact")):
		errors.append("negative seed was accepted")
	if bool(session.call("request_generation", 42, "unknown_preset")):
		errors.append("unknown preset was accepted")
	preserved_host.call("interact", operator)
	if not bool(preserved_host.call("get_arena_status").get("active", false)):
		errors.append("Operator could not enter the accepted arena for the safety check")
	if bool(session.call("request_generation", 417204, "ascent_compact")):
		errors.append("regeneration was accepted while Operator occupied the active arena")
	if camera.call("get_runtime_map") == gallery:
		errors.append("arena entry did not transfer the existing camera to the generated map")
	preserved_host.call("interact", operator)
	if bool(preserved_host.call("get_arena_status").get("active", true)):
		errors.append("Operator could not safely return to the gallery")
	if camera.call("get_runtime_map") != gallery:
		errors.append("return did not restore the existing camera to the gallery")
	if operator.get_instance_id() != operator_id or camera.get_instance_id() != camera_id:
		errors.append("generation controls replaced the Operator or camera")
	if level_id >= 0 and world.get_node("LevelLoader").get_instance_id() != level_id:
		errors.append("generation controls replaced the LevelLoader destination")
	if _count_named_nodes(game, "Operator") != 1 or _count_named_nodes(game, "Camera2D") != 1:
		errors.append("generation controls created duplicate Operator/camera nodes")
	if _count_procgen_maps(game) != initial_map_count:
		errors.append("final active-map count differs from the single accepted-map baseline")

	_finish(game, errors)


func _wait_until_ready(session: Node) -> bool:
	var deadline_msec := Time.get_ticks_msec() + MAX_GENERATION_MSEC
	while Time.get_ticks_msec() < deadline_msec:
		var status: Dictionary = session.call("get_session_status")
		if str(status.get("state", "")) == "READY":
			return true
		if str(status.get("state", "")) == "FAILED":
			return false
		await process_frame
	return false


func _failure_detail(session: Node) -> String:
	var status: Dictionary = session.call("get_session_status")
	var candidate := session.get("_staging_host") as Node
	if not is_instance_valid(candidate):
		candidate = session.get("_accepted_host") as Node
	var host_status: Dictionary = candidate.call("get_arena_status") if is_instance_valid(candidate) else {}
	return "state=%s session_error=%s host_failure=%s staging_complete=%s" % [
		str(status.get("state", "unknown")),
		str(status.get("error", "")),
		str(host_status.get("failure", "")),
		str(host_status.get("staging_complete", false)),
	]


func _count_procgen_maps(node: Node) -> int:
	var count := 1 if node is ProcGenTilemap else 0
	for child in node.get_children():
		count += _count_procgen_maps(child)
	return count


func _count_named_nodes(node: Node, target_name: String) -> int:
	var count := 1 if node.name == target_name else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


func _finish(game: Node, errors: Array[String]) -> void:
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
	await process_frame
	if _count_named_nodes(root, "GeneratedArenaRegion") > 0 or _count_named_nodes(root, "GeneratedArenaRegionStaging") > 0:
		errors.append("generated-region owners remain after gallery teardown")
	if errors.is_empty():
		print("PROCGEN_SHOWCASE_GENERATION_CONTROLS_SMOKE_PASS")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
