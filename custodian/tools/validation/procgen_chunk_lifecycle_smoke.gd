extends SceneTree

## Covers PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md (M4) acceptance: pure
## unit-level state-machine contract plus live ProcGenTilemap integration
## for queued/immediate/paused reveal, zero-content chunks, DORMANT/VISIBLE
## active-window re-entry without duplicate work, and the debug-only
## UNLOADED seam.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CHUNK_LIFECYCLE_SCRIPT := preload("res://game/world/procgen/streaming/procgen_chunk_lifecycle.gd")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_unit_contract()
	await _test_tilemap_integration()
	if _errors.is_empty():
		print("[ProcgenChunkLifecycleSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenChunkLifecycleSmoke] %s" % error)
	quit(1)


func _test_unit_contract() -> void:
	var lifecycle := CHUNK_LIFECYCLE_SCRIPT.new()
	var state := CHUNK_LIFECYCLE_SCRIPT.State
	var chunk := Vector2i(3, 4)

	_check(lifecycle.get_state(chunk) == state.UNSEEN, "fresh chunk is not UNSEEN")
	_check(not lifecycle.is_requested(chunk), "fresh chunk reports requested")

	# Illegal calls on an unrequested chunk must fail loudly (counted), never
	# silently coerce state.
	lifecycle.note_prepared(chunk)
	lifecycle.note_committed(chunk)
	lifecycle.force_unload(chunk)
	_check(
		int(lifecycle.get_snapshot().get("illegal_transition_count", 0)) == 3,
		"illegal calls on an unrequested chunk were not all detected"
	)
	_check(lifecycle.get_state(chunk) == state.UNSEEN, "illegal calls mutated state instead of being rejected")

	# UNSEEN -> QUEUED, idempotent re-request.
	lifecycle.request(chunk, 3)
	_check(lifecycle.get_state(chunk) == state.QUEUED, "request did not transition to QUEUED")
	lifecycle.request(chunk, 999)
	_check(lifecycle.get_state(chunk) == state.QUEUED, "a duplicate request changed existing state")

	# QUEUED -> PREPARED only once every planned tile is prepared.
	lifecycle.note_prepared(chunk)
	lifecycle.note_prepared(chunk)
	_check(lifecycle.get_state(chunk) == state.QUEUED, "chunk reached PREPARED before every planned tile was prepared")
	lifecycle.note_prepared(chunk)
	_check(lifecycle.get_state(chunk) == state.PREPARED, "chunk did not reach PREPARED once every planned tile was prepared")

	# First commit -> REVEALING; full commit -> VISIBLE.
	lifecycle.note_committed(chunk)
	_check(lifecycle.get_state(chunk) == state.REVEALING, "first commit did not transition to REVEALING")
	lifecycle.note_committed(chunk)
	_check(lifecycle.get_state(chunk) == state.REVEALING, "chunk became VISIBLE before every tile committed")
	lifecycle.note_committed(chunk)
	_check(lifecycle.get_state(chunk) == state.VISIBLE, "chunk did not reach VISIBLE once every planned tile committed")

	# Zero-content chunk goes straight to VISIBLE and cannot churn/requeue.
	var empty_chunk := Vector2i(9, 9)
	lifecycle.request(empty_chunk, 0)
	_check(lifecycle.get_state(empty_chunk) == state.VISIBLE, "zero-content chunk did not become VISIBLE immediately")
	lifecycle.request(empty_chunk, 5)
	_check(lifecycle.get_state(empty_chunk) == state.VISIBLE, "zero-content chunk churned on a duplicate request")

	# Active-window DORMANT / VISIBLE re-entry.
	lifecycle.sync_active_window(Vector2i(100, 100), 1)
	_check(lifecycle.get_state(chunk) == state.DORMANT, "resident chunk outside the active window did not become DORMANT")
	_check(lifecycle.get_state(empty_chunk) == state.DORMANT, "resident chunk outside the active window did not become DORMANT")
	lifecycle.sync_active_window(chunk, 0)
	_check(lifecycle.get_state(chunk) == state.VISIBLE, "DORMANT chunk did not return to VISIBLE on re-entry")
	_check(lifecycle.get_state(empty_chunk) == state.DORMANT, "a chunk outside the window re-entered VISIBLE incorrectly")

	# Debug-only UNLOADED seam: legal from VISIBLE, illegal once already there.
	lifecycle.force_unload(chunk)
	_check(lifecycle.get_state(chunk) == state.UNLOADED, "force_unload did not reach UNLOADED from VISIBLE")
	lifecycle.force_unload(chunk)
	_check(
		int(lifecycle.get_snapshot().get("illegal_transition_count", 0)) == 4,
		"force_unload on an already-UNLOADED chunk was not rejected as illegal"
	)

	# Deterministic snapshot shape and coordinate-stable debug ordering.
	var snapshot := lifecycle.get_snapshot()
	_check(int(snapshot.get("chunk_count", -1)) == 2, "chunk_count did not match the two chunks ever requested")
	var debug_states := lifecycle.get_debug_chunk_states()
	_check(debug_states.size() == 2, "debug chunk state listing size mismatch")
	_check(
		debug_states[0]["chunk"] == Vector2i(3, 4) and debug_states[1]["chunk"] == Vector2i(9, 9),
		"debug chunk state ordering is not coordinate-stable"
	)


func _test_tilemap_integration() -> void:
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
	procgen.seed = 20261002
	procgen.map_size = Vector2i(24, 24)
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = true
	map.streaming_chunk_size_tiles = 6
	map.streaming_immediate_chunk_radius = 0
	map.streaming_active_chunk_radius = 1
	map.streaming_reveal_tiles_per_frame = 4
	map.build_runtime_wall_collision = true

	var state := CHUNK_LIFECYCLE_SCRIPT.State

	# Pure enumeration: calling it speculatively before any request must not
	# create or change lifecycle state.
	var probe_chunk := Vector2i(50, 50)
	map.call("_get_chunk_tiles", probe_chunk)
	map.call("_get_chunk_tiles", probe_chunk)
	_check(
		int(map.debug_get_chunk_lifecycle_state(probe_chunk)) == state.UNSEEN,
		"speculative chunk-tile enumeration mutated lifecycle state"
	)

	map.generate()

	var spawn_tile := map.get_player_spawn()
	var spawn_chunk := map.call("_tile_to_chunk", spawn_tile) as Vector2i
	_check(
		int(map.debug_get_chunk_lifecycle_state(spawn_chunk)) == state.VISIBLE,
		"the immediate-radius spawn chunk did not reach VISIBLE synchronously during generation"
	)

	# Find a queued (outer, non-immediate) chunk: still QUEUED immediately
	# after generation, before any frame has had a chance to prepare/commit.
	var queued_chunk := Vector2i(999999, 999999)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var candidate := spawn_chunk + Vector2i(dx, dy)
			if int(map.debug_get_chunk_lifecycle_state(candidate)) == state.QUEUED:
				queued_chunk = candidate
				break
		if queued_chunk != Vector2i(999999, 999999):
			break
	_check(queued_chunk != Vector2i(999999, 999999), "no outer chunk was left QUEUED immediately after generation")

	# Zero-content chunk: far outside generated bounds, enumerates to zero
	# tiles, must resolve straight to VISIBLE without ever queuing/committing.
	var empty_chunk := Vector2i(100000, 100000)
	map.call("_queue_chunk_for_reveal", empty_chunk, spawn_tile)
	_check(
		int(map.debug_get_chunk_lifecycle_state(empty_chunk)) == state.VISIBLE,
		"a zero-content chunk did not resolve directly to VISIBLE"
	)

	# Drain the queued chunk under a small per-frame budget so it must pass
	# through REVEALING (partial commit) before VISIBLE, and prove exact
	# per-tile visibility truth along the way.
	var queued_tiles: Array[Vector2i] = map.call("_get_chunk_tiles", queued_chunk)
	_check(not queued_tiles.is_empty(), "the chosen queued chunk has no generated tiles to drain")
	var sample_tile := queued_tiles[queued_tiles.size() - 1] if not queued_tiles.is_empty() else Vector2i.ZERO
	var saw_revealing := false
	var frames := 0
	while int(map.debug_get_chunk_lifecycle_state(queued_chunk)) != state.VISIBLE:
		if int(map.debug_get_chunk_lifecycle_state(queued_chunk)) == state.REVEALING:
			saw_revealing = true
		frames += 1
		if frames > 500:
			_check(false, "queued chunk never reached VISIBLE within the frame budget")
			break
		await process_frame
	_check(saw_revealing, "a tile-budgeted multi-frame chunk never reported REVEALING partway through")
	_check(
		bool(map.call("_is_tile_currently_visible", sample_tile)),
		"sample tile is not reported visible after its chunk reached VISIBLE"
	)

	# Active-window exit/re-entry: moving the center far away must mark the
	# now-VISIBLE queued_chunk DORMANT without touching its presentation or
	# committing/queuing it again; moving back must return it to VISIBLE.
	var health_before_window_move := map.get_runtime_health_snapshot()
	var committed_before: int = int(health_before_window_move.get("pause_aware_streaming", {}).get("committed", 0))
	var floor_before := map.get_floor_tilemap().get_used_cells().size()
	map.call("_update_streaming_chunks", spawn_chunk + Vector2i(50, 50), spawn_tile)
	_check(
		int(map.debug_get_chunk_lifecycle_state(queued_chunk)) == state.DORMANT,
		"chunk outside the moved active window did not become DORMANT"
	)
	_check(
		map.get_floor_tilemap().get_used_cells().size() == floor_before,
		"becoming DORMANT changed resident presentation"
	)
	map.call("_update_streaming_chunks", spawn_chunk, spawn_tile)
	_check(
		int(map.debug_get_chunk_lifecycle_state(queued_chunk)) == state.VISIBLE,
		"DORMANT chunk did not return to VISIBLE when the active window moved back"
	)
	var health_after_window_move := map.get_runtime_health_snapshot()
	var committed_after: int = int(health_after_window_move.get("pause_aware_streaming", {}).get("committed", 0))
	_check(
		committed_after == committed_before,
		"DORMANT -> VISIBLE re-entry duplicated tile commit work"
	)

	# Debug-only UNLOADED seam: erases presentation and reaches UNLOADED.
	map.debug_force_unload_chunk(queued_chunk)
	_check(
		int(map.debug_get_chunk_lifecycle_state(queued_chunk)) == state.UNLOADED,
		"debug_force_unload_chunk did not reach UNLOADED"
	)
	_check(
		not bool(map.call("_is_tile_currently_visible", sample_tile)),
		"sample tile is still reported visible after its chunk was force-unloaded"
	)

	map.queue_free()
	runtime_container.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
