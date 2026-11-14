extends SceneTree

const PLAYTEST_SCENE := preload("res://game/world/levels/authored/dev/procgen_showcase_gallery/procgen_showcase_gallery_playtest.tscn")
const MAX_GENERATION_MSEC := 180000
const LAYER_NAMES := ["terrain", "route", "playability", "sites", "vistas"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var game := PLAYTEST_SCENE.instantiate() as Node2D
	game.name = "GameRoot"
	root.add_child(game)
	await process_frame
	var gallery := game.get_node("World/Level") as Node2D
	var session := gallery.get_node("ProcgenArenaSession") as Node
	var inspector := gallery.get_node("ProcgenGalleryInspector") as Node
	var overlay := inspector.get_node("ProcgenGalleryOverlay") as Node2D
	var controls := gallery.get_node("ProcgenGalleryControls") as Node
	if not await _wait_for_revision(session, 1):
		errors.append("accepted generated arena did not become ready: %s" % str(session.call("get_session_status").get("error", "timeout")))
		_finish(game, errors)
		return
	var first: Dictionary = inspector.call("get_snapshot")
	var first_status: Dictionary = session.call("get_session_status")
	if first.is_empty() or str(first.get("schema", "")) != "custodian.procgen_showcase_inspector_snapshot.v1":
		errors.append("inspector did not publish its versioned detached accepted-world snapshot")
	if str(first.get("generation_fingerprint", "")) != str(first_status.get("fingerprint", "")):
		errors.append("inspector fingerprint differs from the accepted session fingerprint")
	if not bool(first.get("spawn_valid", false)) or not bool(first.get("spawn_navigation_walkable", false)):
		errors.append("inspector did not report the accepted spawn as valid and navigation-walkable")
	if not _has_no_object_references(first):
		errors.append("inspector snapshot contains an Object/Node reference")
	var layers: Dictionary = first.get("layers", {})
	var limits: Dictionary = first.get("layer_limits", {})
	for layer in LAYER_NAMES:
		var descriptors: Variant = layers.get(layer, null)
		if not descriptors is Array:
			errors.append("overlay layer %s is missing its detached descriptor array" % layer)
		elif descriptors.size() > int(limits.get(layer, 0)) or descriptors.size() > 1024:
			errors.append("overlay layer %s exceeds its descriptor cap" % layer)
		else:
			for point: Variant in descriptors:
				if not point is Vector2:
					errors.append("overlay layer %s contains a non-position descriptor" % layer)
					break
	if not _provenance_is_exact(first):
		errors.append("catalog provenance was reported without an exact map authority ID match")
	var original_builds := int(inspector.call("get_snapshot_build_count"))
	var map := gallery.get_node("ProcgenArenaHost/GeneratedArenaRegion")
	var procgen: ProcGenTilemap = map.call("get_generated_map")
	var source_fingerprint := str(session.call("get_session_status").get("fingerprint", ""))
	var component_queries := int(procgen.get("main_playable_component_query_count"))
	inspector.call("refresh_snapshot")
	if int(inspector.call("get_snapshot_build_count")) != original_builds + 1:
		errors.append("explicit refresh did not rebuild one accepted-world snapshot")
	if int(procgen.get("main_playable_component_query_count")) != component_queries + 1:
		errors.append("explicit refresh did not use the canonical source projection exactly once")
	original_builds = int(inspector.call("get_snapshot_build_count"))
	component_queries = int(procgen.get("main_playable_component_query_count"))
	first["seed"] = -1
	(first.get("layers", {}).get("terrain", []) as Array).clear()
	if int(inspector.call("get_snapshot").get("seed", -1)) != 417203:
		errors.append("mutating the caller's snapshot changed the inspector's cached copy")
	for layer in LAYER_NAMES:
		inspector.call("set_layer_enabled", layer, true)
		inspector.call("set_layer_enabled", layer, false)
	if int(inspector.call("get_snapshot_build_count")) != original_builds:
		errors.append("overlay toggles rebuilt the accepted source snapshot")
	if int(procgen.get("main_playable_component_query_count")) != component_queries:
		errors.append("overlay toggles queried the source map again")
	if str(session.call("get_session_status").get("fingerprint", "")) != source_fingerprint:
		errors.append("overlay toggles changed the accepted map fingerprint")
	if overlay.is_processing() or overlay.is_physics_processing():
		errors.append("overlay runs a per-frame process loop")
	var revision_before := int(session.call("get_session_status").get("accepted_revision", 0))
	if not bool(session.call("reroll_explicit_seed", 417204)):
		errors.append("explicit replacement generation was rejected")
	else:
		var during_staging: Dictionary = inspector.call("get_snapshot")
		if str(during_staging.get("generation_fingerprint", "")) != source_fingerprint:
			errors.append("staging displaced the prior accepted snapshot before replacement commit")
		if not await _wait_for_revision(session, revision_before + 1):
			errors.append("replacement accepted generation did not complete: %s" % str(session.call("get_session_status").get("error", "timeout")))
		else:
			var replacement: Dictionary = inspector.call("get_snapshot")
			if int(replacement.get("seed", -1)) != 417204:
				errors.append("inspector retained stale seed data after accepted-host replacement")
			if str(replacement.get("generation_fingerprint", "")) != str(session.call("get_session_status").get("fingerprint", "")):
				errors.append("replacement snapshot fingerprint does not match the accepted session")
			var replacement_fingerprint := str(replacement.get("generation_fingerprint", ""))
			if bool(session.call("reroll_explicit_seed", 417205)):
				var cancelled := bool(session.call("cancel_generation"))
				if not cancelled:
					errors.append("staging cancellation request was rejected")
				for _frame in range(60):
					if int(session.call("get_session_status").get("staging_host_count", 0)) == 0:
						break
					await process_frame
				var after_cancel: Dictionary = inspector.call("get_snapshot")
				if str(after_cancel.get("generation_fingerprint", "")) != replacement_fingerprint:
					errors.append("cancelling staging lost or retained stale accepted-world state")
				if int(session.call("get_session_status").get("staging_host_count", -1)) != 0:
					errors.append("cancelled staging host was not released")
			else:
				errors.append("replacement generation could not start for cancellation coverage")
	inspector.call("_exit_tree")
	if not (inspector.call("get_snapshot") as Dictionary).is_empty():
		errors.append("inspector retained snapshot state after teardown invalidation")
	_finish(game, errors)


func _wait_for_revision(session: Node, target_revision: int) -> bool:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < MAX_GENERATION_MSEC:
		var status: Dictionary = session.call("get_session_status")
		if int(status.get("accepted_revision", 0)) >= target_revision and bool(status.get("accepted_ready", false)):
			return true
		await process_frame
	return false


func _provenance_is_exact(snapshot: Dictionary) -> bool:
	var data: Dictionary = snapshot.get("data", {})
	var observed: Dictionary = {}
	var biomes: Variant = data.get("biome_id_by_cell", {})
	if biomes is Dictionary:
		for value in biomes.values():
			observed[str(value)] = true
	var regions: Variant = data.get("region_tiles", {})
	if regions is Dictionary:
		for value: Variant in regions.values():
			if value is Dictionary:
				observed[str(value.get("region_type", ""))] = true
	for entry: Variant in snapshot.get("exhibit_provenance", []):
		if not entry is Dictionary or not observed.has(str(entry.get("source_authority_id", ""))):
			return false
	return true


func _has_no_object_references(value: Variant) -> bool:
	if value is Object:
		return false
	if value is Dictionary:
		for key: Variant in value:
			if not _has_no_object_references(key) or not _has_no_object_references(value[key]):
				return false
	if value is Array:
		for item: Variant in value:
			if not _has_no_object_references(item):
				return false
	return true


func _finish(game: Node, errors: Array[String]) -> void:
	if is_instance_valid(game):
		game.queue_free()
	await process_frame
	await process_frame
	if errors.is_empty():
		print("PROCGEN_SHOWCASE_RUNTIME_INSPECTOR_SMOKE_PASS")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
