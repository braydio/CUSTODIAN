extends SceneTree

## Covers PROCGEN_PAUSE_AWARE_STREAMING.md (M3) acceptance: request -> pause ->
## preparation -> frozen authority -> resume -> single bounded commit.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# ProcGenTilemap._process() only does streaming-reveal/commit work when its
	# parent is literally named "ProcGenRuntime" (_is_attached_to_runtime_world);
	# match the real ContractWorldLoader container shape (plain Node2D,
	# default inherited process_mode) rather than adding it under `root`
	# directly, or per-frame commit draining would never run at all.
	var runtime_container := Node2D.new()
	runtime_container.name = "ProcGenRuntime"
	root.add_child(runtime_container)
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	runtime_container.add_child(map)
	await process_frame
	var legacy := map.get_node_or_null("ProcGen")
	if legacy != null:
		legacy.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	procgen.generate_seed = false
	procgen.seed = 20261001
	procgen.map_size = Vector2i(24, 24)
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = true
	map.streaming_chunk_size_tiles = 6
	map.streaming_immediate_chunk_radius = 0
	map.streaming_active_chunk_radius = 1
	map.streaming_reveal_tiles_per_frame = 8
	map.build_runtime_wall_collision = true

	map.generate()

	# Let generation's own immediate-chunk reveal settle (its call_deferred
	# navigation/boundary/shadow flush fires on the next idle frame regardless
	# of pause state) before taking the pre-pause baseline, so that settling
	# is never mistaken for streaming work advancing while paused.
	for _settle_frame in range(2):
		await process_frame

	var queued_before_pause := (map.get("_streaming_reveal_queue") as Array).size()
	_check(queued_before_pause > map.streaming_reveal_tiles_per_frame, "expected already-queued reveal work larger than one frame's budget before pause")

	var floor_used_before_pause := map.get_floor_tilemap().get_used_cells().size()
	var health_before_pause := map.get_runtime_health_snapshot()
	var pas_before_pause: Dictionary = health_before_pause.get("pause_aware_streaming", {})
	# Cumulative-since-session-start baselines: the two unpaused settle frames
	# above already commit up to one frame's worth of normal (never-paused)
	# reveal work, so pause-time assertions must check deltas from here, not
	# absolute zero.
	var prepared_before_pause := int(pas_before_pause.get("prepared", 0))
	var committed_before_pause := int(pas_before_pause.get("committed", 0))
	var resumed_before_pause := int(pas_before_pause.get("resumed", 0))

	paused = true

	for _frame in range(6):
		await process_frame

	var health_mid := map.get_runtime_health_snapshot()
	var pas_mid: Dictionary = health_mid.get("pause_aware_streaming", {})
	_check(int(pas_mid.get("prepared", 0)) > prepared_before_pause, "PREPARE did not advance for already-queued work while paused")
	_check(int(pas_mid.get("committed", 0)) == committed_before_pause, "COMMIT advanced while paused")
	_check(
		map.get_floor_tilemap().get_used_cells().size() == floor_used_before_pause,
		"visible floor topology advanced while paused"
	)
	_check(
		int(health_mid.get("navigation_rebuild_completed_count", -1))
			== int(health_before_pause.get("navigation_rebuild_completed_count", -2)),
		"navigation publication advanced while paused"
	)
	_check(
		int(health_mid.get("walkable_boundary_rebuild_count", -1))
			== int(health_before_pause.get("walkable_boundary_rebuild_count", -2)),
		"walkable boundary publication advanced while paused"
	)
	_check(
		int(health_mid.get("runtime_wall_rebuild_count", -1))
			== int(health_before_pause.get("runtime_wall_rebuild_count", -2)),
		"wall collision publication advanced while paused"
	)
	var queue_plus_prepared_mid := int((map.get("_streaming_reveal_queue") as Array).size()) + int(pas_mid.get("prepared_pending", 0))
	_check(
		queue_plus_prepared_mid == queued_before_pause,
		"prepared work was duplicated or lost relative to the original queue"
	)

	paused = false

	await process_frame
	var pas_one_frame: Dictionary = map.get_runtime_health_snapshot().get("pause_aware_streaming", {})
	var committed_delta_one_frame := int(pas_one_frame.get("committed", 0)) - committed_before_pause
	_check(committed_delta_one_frame > 0, "resume did not commit anything on the first unpaused frame")
	_check(
		committed_delta_one_frame <= map.streaming_reveal_tiles_per_frame,
		"resume committed more than the bounded per-frame budget in a single frame"
	)
	_check(int(pas_one_frame.get("resumed", 0)) == resumed_before_pause + 1, "resume event was not recorded exactly once")

	var frames_to_drain := 1
	while true:
		var pas_poll: Dictionary = map.get_runtime_health_snapshot().get("pause_aware_streaming", {})
		if int(pas_poll.get("deferred", 0)) == 0 and int(pas_poll.get("prepared_pending", 0)) == 0:
			break
		frames_to_drain += 1
		if frames_to_drain > 200:
			_check(false, "pause-aware streaming did not finish draining within the frame budget")
			break
		await process_frame

	var pas_final: Dictionary = map.get_runtime_health_snapshot().get("pause_aware_streaming", {})
	_check(frames_to_drain > 1, "the entire prepared/queued batch committed in a single frame instead of the bounded budget")
	_check(
		int(pas_final.get("requested", 0)) == int(pas_final.get("committed", 0)),
		"requested/committed count mismatch: duplicate or missing commits"
	)
	_check(int(pas_final.get("resumed", 0)) == resumed_before_pause + 1, "resume event fired more than once")
	_check(
		map.get_floor_tilemap().get_used_cells().size() > floor_used_before_pause,
		"resume did not expand visible floor topology"
	)

	var scheduler_after: Dictionary = map.get_runtime_health_snapshot().get("derived_rebuild_scheduler", {}).get("systems", {})
	var navigation_committed := int(scheduler_after.get("navigation", {}).get("committed", 0))
	_check(navigation_committed >= 1, "M2 navigation scheduler recorded no commit from the resumed batch")
	_check(
		navigation_committed < frames_to_drain,
		"navigation publication looks uncoalesced (expected far fewer commits than drained frames)"
	)

	map.queue_free()
	runtime_container.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[ProcgenPauseAwareStreamingSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenPauseAwareStreamingSmoke] %s" % error)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
