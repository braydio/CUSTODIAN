extends SceneTree

## Covers PROCGEN_PAUSE_AWARE_STREAMING.md (M3) acceptance: request -> pause ->
## preparation -> frozen authority -> resume -> single bounded commit.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const PAUSE_AWARE_STREAMING_SCRIPT := preload("res://game/world/procgen/streaming/procgen_pause_aware_streaming.gd")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_priority_ordering_checks()
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
	var requested_before_pause := int(pas_before_pause.get("requested", 0))
	var committed_before_pause := int(pas_before_pause.get("committed", 0))
	var resumed_before_pause := int(pas_before_pause.get("resumed", 0))
	var pending_before_pause := queued_before_pause + int(pas_before_pause.get("prepared_pending", 0))

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
		queue_plus_prepared_mid == pending_before_pause,
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


func _run_priority_ordering_checks() -> void:
	var queue: Array[Vector2i] = [Vector2i(40, 40), Vector2i(1, 0), Vector2i(20, 20), Vector2i(2, 0)]
	var committed: Array[Vector2i] = []
	var streaming := PAUSE_AWARE_STREAMING_SCRIPT.new() as ProcGenPauseAwareStreaming
	streaming.configure(queue, func(tile: Vector2i) -> Dictionary: return {"tile": tile}, func(record: Dictionary) -> void: committed.append(record["tile"]), func() -> int: return 0)
	streaming.enqueue_many([])
	streaming.requested_count = queue.size()
	streaming.reprioritize_pending([Vector2i(2, 0), Vector2i(1, 0)])
	_check(queue == [Vector2i(2, 0), Vector2i(1, 0), Vector2i(40, 40), Vector2i(20, 20)], "relocation priority did not promote near work while preserving far backlog order")
	_check(streaming.drain_commit(1) == 1 and committed == [Vector2i(2, 0)], "commit did not take the highest-priority relocated tile")
	_check(streaming.get_snapshot().get("requested") == queue.size() + committed.size(), "relocation changed the request count")

	var pocket_queue: Array[Vector2i] = [Vector2i(20, 20), Vector2i(4, 4), Vector2i(40, 40), Vector2i(4, 5), Vector2i(5, 5)]
	var pocket_streaming := PAUSE_AWARE_STREAMING_SCRIPT.new() as ProcGenPauseAwareStreaming
	pocket_streaming.configure(pocket_queue, func(tile: Vector2i) -> Dictionary: return {"tile": tile}, func(_record: Dictionary) -> void: pass, func() -> int: return 0)
	pocket_streaming.reprioritize_pending([Vector2i(4, 4), Vector2i(4, 5), Vector2i(5, 5)])
	_check(pocket_queue.slice(0, 3) == [Vector2i(4, 4), Vector2i(4, 5), Vector2i(5, 5)], "tiny pending pocket did not precede distant backlog")

	var prepared_queue: Array[Vector2i] = [Vector2i(8, 8)]
	var prepared_commits: Array[Vector2i] = []
	var prepared_streaming := PAUSE_AWARE_STREAMING_SCRIPT.new() as ProcGenPauseAwareStreaming
	prepared_streaming.configure(prepared_queue, func(tile: Vector2i) -> Dictionary: return {"tile": tile}, func(record: Dictionary) -> void: prepared_commits.append(record["tile"]), func() -> int: return 0)
	prepared_streaming._prepared.append({"tile": Vector2i(30, 30)})
	prepared_streaming.prepared_count = 1
	prepared_streaming.requested_count = 2
	prepared_streaming.reprioritize_pending([Vector2i(8, 8), Vector2i(30, 30)])
	prepared_streaming.drain_commit(1)
	_check(prepared_commits == [Vector2i(8, 8)], "higher-priority queued tile did not outrank a farther prepared record")
	_check(prepared_streaming.get_snapshot().get("requested") == 2, "prepared/queued priority changed the request count")

	var tie_queue: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(40, 40)]
	var tie_streaming := PAUSE_AWARE_STREAMING_SCRIPT.new() as ProcGenPauseAwareStreaming
	tie_streaming.configure(tie_queue, func(tile: Vector2i) -> Dictionary: return {"tile": tile}, func(_record: Dictionary) -> void: pass, func() -> int: return 0)
	tie_streaming.reprioritize_pending([Vector2i(0, 1), Vector2i(1, 0)])
	_check(tie_queue.slice(0, 2) == [Vector2i(0, 1), Vector2i(1, 0)], "equal-priority ordering was not stable and deterministic")
