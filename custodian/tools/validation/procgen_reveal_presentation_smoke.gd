extends SceneTree

## Covers PROCGEN_ARCHIVE_RESOLVE_PRESENTATION_SPINE (AR1) acceptance: the
## ProcGenRevealPresentation owner's committed-only settlement, safety halo,
## unload/reacquisition identity, deterministic frontier order, disabled
## fallback and bounded batched slots (pure fixture), plus production
## integration through ProcGenTilemap: request-before-commit on both queued and
## immediate paths (no commit without a veil record), shared commit-adapter
## lifecycle parity against the disabled-effect oracle, pause freeze, unload /
## reacquisition identity, and the single batched veil node.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const PRESENTATION_SCRIPT := preload("res://game/world/procgen/streaming/procgen_reveal_presentation.gd")
const CHUNK_LIFECYCLE_SCRIPT := preload("res://game/world/procgen/streaming/procgen_chunk_lifecycle.gd")

const NO_OPERATOR := Vector2i(999999, 999999)
const CHUNK := 6

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_pure_owner()
	await _test_runtime_integration()
	if _errors.is_empty():
		print("[ProcgenRevealPresentationSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenRevealPresentationSmoke] %s" % error)
	quit(1)


func _make_owner(capacity: int = 256) -> ProcGenRevealPresentation:
	var owner_node := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	owner_node.slot_capacity = capacity
	owner_node.resolve_starts_per_frame = 4
	owner_node.resolve_duration_sec = 0.1
	owner_node.safety_halo_tiles = 2
	root.add_child(owner_node)
	owner_node.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	return owner_node


func _chunk_tiles(chunk: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(chunk.x * CHUNK, chunk.x * CHUNK + CHUNK):
		for y in range(chunk.y * CHUNK, chunk.y * CHUNK + CHUNK):
			tiles.append(Vector2i(x, y))
	return tiles


# --- (0) Pure owner fixture ------------------------------------------------

func _test_pure_owner() -> void:
	var owner_node := _make_owner()
	var chunk := Vector2i(5, 5)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	var snap := owner_node.get_snapshot()
	_check(int(snap["requested_uncommitted_count"]) == tiles.size(), "request did not veil every requested tile")
	_check(int(snap["active_instance_count"]) == tiles.size(), "active instance count does not match requested veil slots")
	_check(int(snap["first_resolve_count"]) == tiles.size() and int(snap["reacquisition_count"]) == 0, "first request was not classified first_resolve")

	# Committed-only settlement: uncommitted tiles never resolve, however long.
	for _i in range(40):
		owner_node.advance(0.05, NO_OPERATOR, CHUNK)
	snap = owner_node.get_snapshot()
	_check(int(snap["settled_count"]) == 0 and int(snap["requested_uncommitted_count"]) == tiles.size(), "an uncommitted tile settled before authoritative COMMIT")

	# Commit half; only those may resolve, bounded by the per-frame start budget.
	var committed: Array[Vector2i] = tiles.slice(0, 12)
	for tile in committed:
		owner_node.note_tile_committed(tile)
	owner_node.advance(0.01, NO_OPERATOR, CHUNK)
	snap = owner_node.get_snapshot()
	_check(int(snap["resolving_count"]) == 4, "settlement work was not bounded by resolve_starts_per_frame")
	for _i in range(40):
		owner_node.advance(0.05, NO_OPERATOR, CHUNK)
	snap = owner_node.get_snapshot()
	_check(int(snap["settled_count"]) == committed.size(), "committed tiles did not all settle")
	_check(int(snap["requested_uncommitted_count"]) == tiles.size() - committed.size(), "uncommitted veil coverage changed while committed tiles settled")
	_check(int(snap["active_instance_count"]) == tiles.size() - committed.size(), "settled tiles did not release their veil slots")
	for tile in tiles.slice(12):
		_check(owner_node.has_veil(tile) and owner_node.get_tile_state(tile) == ProcGenRevealPresentation.TileState.REQUESTED, "uncommitted tile lost its veil")
		break
	_check(owner_node.get_child_count() == 0, "veil created per-cell child nodes")
	_check(owner_node.multimesh.instance_count == 256, "batched slot capacity is not the fixed pool size")

	# Safety halo force-settles only committed nearby cells.
	var halo_owner := _make_owner()
	var halo_chunk := Vector2i(0, 0)
	halo_owner.note_tiles_requested(halo_chunk, _chunk_tiles(halo_chunk), false)
	halo_owner.note_tile_committed(Vector2i(2, 2))
	halo_owner.note_tile_committed(Vector2i(5, 5))
	halo_owner.advance(0.0, Vector2i(3, 3), CHUNK)
	_check(not halo_owner.has_veil(Vector2i(2, 2)), "halo did not settle a committed cell near the Operator")
	_check(halo_owner.has_veil(Vector2i(3, 3)) and halo_owner.get_tile_state(Vector2i(3, 3)) == ProcGenRevealPresentation.TileState.REQUESTED, "halo revealed an uncommitted cell")
	_check(int(halo_owner.get_snapshot()["forced_safety_settle_count"]) == 2, "halo forced-settle count is wrong (expected committed in-halo cells only)")
	halo_owner.queue_free()

	# Unload / reacquisition identity.
	var reacq_owner := _make_owner()
	var rc := Vector2i(1, 1)
	var rtiles := _chunk_tiles(rc)
	reacq_owner.note_tiles_requested(rc, rtiles, false)
	for tile in rtiles:
		reacq_owner.note_tile_committed(tile)
	for _i in range(60):
		reacq_owner.advance(0.05, NO_OPERATOR, CHUNK)
	_check(int(reacq_owner.get_snapshot()["settled_count"]) == rtiles.size(), "fixture chunk did not settle")
	reacq_owner.note_chunk_unloaded(rc, CHUNK)
	reacq_owner.note_tiles_requested(rc, rtiles, true)
	var rs := reacq_owner.get_snapshot()
	_check(int(rs["reacquisition_count"]) == rtiles.size() and int(rs["first_resolve_count"]) == rtiles.size(), "reacquisition identity was not distinct from first_resolve")
	_check(int(rs["identity_mismatch_count"]) == 0, "ever-resolved memory disagreed with lifecycle identity")
	# Unload drops active slots without settling uncommitted tiles into history.
	reacq_owner.note_chunk_unloaded(rc, CHUNK)
	_check(int(reacq_owner.get_snapshot()["active_instance_count"]) == 0, "unload did not release the chunk's veil slots")
	reacq_owner.queue_free()

	# Determinism: same committed sequence + deterministic clock => same order.
	var trace_a := _frontier_trace()
	var trace_b := _frontier_trace()
	_check(trace_a == trace_b and not trace_a.is_empty(), "same committed sequence produced a different frontier trace")

	# Disabled fallback: no veil, committed presentation settles immediately.
	var off_owner := _make_owner()
	off_owner.set_effect_enabled(false)
	off_owner.note_tiles_requested(chunk, tiles, false)
	for tile in tiles:
		off_owner.note_tile_committed(tile)
	var off := off_owner.get_snapshot()
	_check(int(off["active_instance_count"]) == 0 and int(off["settled_count"]) == tiles.size(), "disabled effect left veil instances or unsettled commits")
	off_owner.queue_free()

	# Bounded capacity: overflow fails open and is counted.
	var small_owner := _make_owner(64)
	small_owner.note_tiles_requested(chunk, tiles.slice(0, 36), false)
	small_owner.note_tiles_requested(Vector2i(6, 6), _chunk_tiles(Vector2i(6, 6)), false)
	var small := small_owner.get_snapshot()
	_check(int(small["active_instance_count"]) <= 64 and int(small["overflow_count"]) == 8, "slot pool is not bounded or overflow was not counted")
	small_owner.queue_free()
	owner_node.queue_free()


func _frontier_trace() -> Array:
	var owner_node := _make_owner()
	var chunk := Vector2i(2, 3)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	var order: Array = []
	for tile in tiles:
		owner_node.note_tile_committed(tile)
	for _i in range(12):
		owner_node.advance(0.02, Vector2i(chunk.x * CHUNK, chunk.y * CHUNK), CHUNK)
		order.append(owner_node.get_frontier_order().duplicate())
		order.append(owner_node.get_snapshot()["settled_count"])
	owner_node.queue_free()
	return order


# --- (1+) Runtime integration ---------------------------------------------

func _make_map(archive_enabled: bool, immediate_radius: int) -> ProcGenTilemap:
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
	procgen.map_size = Vector2i(48, 48)
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = true
	map.streaming_chunk_size_tiles = CHUNK
	map.streaming_immediate_chunk_radius = immediate_radius
	map.streaming_active_chunk_radius = 2
	map.streaming_reveal_tiles_per_frame = 16
	map.build_runtime_wall_collision = true
	map.streaming_unload_distant_chunks = true
	map.streaming_unload_chunk_distance = 3
	map.archive_resolve_enabled = archive_enabled
	map.generate()
	return map


func _lifecycle_fingerprint(map: ProcGenTilemap) -> Dictionary:
	var health := map.get_runtime_health_snapshot()
	var pas: Dictionary = health.get("pause_aware_streaming", {})
	# PREPARE progress is excluded: the enabled run pauses the tree (where M3
	# PREPARE legitimately advances) and the disabled oracle run does not.
	var states: Array = []
	for entry in map.debug_get_chunk_lifecycle_states():
		states.append([entry.get("chunk"), entry.get("state"), entry.get("planned"), entry.get("committed")])
	return {
		"states": states,
		"requested": pas.get("requested", -1),
		"prepared": pas.get("prepared", -1),
		"committed": pas.get("committed", -1),
		"floor_cells": health.get("painted_floor_cell_count", -1),
		"wall_cells": health.get("painted_wall_cell_count", -1),
	}


func _test_runtime_integration() -> void:
	var state := CHUNK_LIFECYCLE_SCRIPT.State
	var map := await _make_map(true, 1)
	var presentation := map.debug_get_reveal_presentation()
	_check(presentation != null and presentation.get_parent() == map, "the veil owner is not integrated under the procgen map")
	_check(presentation.z_index == 2 and presentation.multimesh != null, "veil layer is not a batched MultiMesh at the actor-below presentation layer")
	var snap := presentation.get_snapshot()

	# Request-before-commit on both paths: any commit lacking a veil record
	# would have incremented unveiled_commit_count.
	_check(int(snap["unveiled_commit_count"]) == 0, "an immediate-path commit reached presentation without a veil record")
	_check(int(snap["requested_total_count"]) > 0, "no tile request was observed")
	var queued: Array[Vector2i] = (map.get("_streaming_reveal_queue") as Array[Vector2i]).duplicate()
	_check(not queued.is_empty(), "fixture produced no queued reveal work")
	for tile in queued:
		if not presentation.has_veil(tile):
			_check(false, "queued tile %s has no veil before commit" % [tile])
			break
	_check(int(snap["requested_uncommitted_count"]) >= queued.size(), "queued tiles are not all veiled as requested/uncommitted")
	_check(map.get_child_count() > 0 and presentation.get_child_count() == 0, "veil created per-cell nodes")

	# Committed-only: still-queued tiles remain REQUESTED after frames pass.
	await process_frame
	await process_frame
	var still_queued: Array[Vector2i] = (map.get("_streaming_reveal_queue") as Array[Vector2i]).duplicate()
	if not still_queued.is_empty():
		_check(
			presentation.get_tile_state(still_queued[0]) == ProcGenRevealPresentation.TileState.REQUESTED,
			"an uncommitted queued tile left the requested state"
		)
	var halo_probe := presentation.get_snapshot()
	_check(int(halo_probe["identity_mismatch_count"]) == 0, "lifecycle and presentation disagree on first-resolution identity")

	# Pause freezes the presentation clock; resume continues without a jump.
	var time_before := float(presentation.get_snapshot()["presentation_time"])
	var committed_before_pause := int(_lifecycle_fingerprint(map)["committed"])
	var settled_before_pause := int(presentation.get_snapshot()["settled_count"])
	paused = true
	for _i in range(6):
		await process_frame
	var time_paused := float(presentation.get_snapshot()["presentation_time"])
	_check(is_equal_approx(time_before, time_paused), "presentation clock advanced while paused")
	_check(int(_lifecycle_fingerprint(map)["committed"]) == committed_before_pause, "COMMIT advanced while paused")
	_check(int(presentation.get_snapshot()["settled_count"]) == settled_before_pause, "presentation settled tiles behind pause")
	paused = false
	await process_frame
	await process_frame
	var time_resumed := float(presentation.get_snapshot()["presentation_time"])
	_check(time_resumed > time_paused and time_resumed - time_paused < 1.0, "presentation clock did not resume smoothly")

	# Drain everything: committed work settles, no veil survives, parity holds.
	var guard := 0
	while guard < 600 and (
		not (map.get("_streaming_reveal_queue") as Array).is_empty()
		or int(presentation.get_snapshot()["active_instance_count"]) > 0
	):
		await process_frame
		guard += 1
	var drained := presentation.get_snapshot()
	_check(int(drained["active_instance_count"]) == 0, "veil did not fully settle after all work committed (%s)" % [drained])
	_check(int(drained["settled_count"]) == int(drained["requested_total_count"]), "settled count does not equal requested count after drain")
	var enabled_fingerprint := _lifecycle_fingerprint(map)

	# Unload then reacquire a settled chunk: deterministic reacquisition identity.
	var victim := Vector2i(999999, 999999)
	var spawn_chunk := map.call("_tile_to_chunk", map.get_player_spawn()) as Vector2i
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var candidate := spawn_chunk + Vector2i(dx, dy)
			if candidate != spawn_chunk and victim == Vector2i(999999, 999999) \
					and int(map.debug_get_chunk_lifecycle_state(candidate)) == state.VISIBLE:
				victim = candidate
	_check(victim != Vector2i(999999, 999999), "no VISIBLE victim chunk to unload")
	if victim != Vector2i(999999, 999999):
		var first_before := int(presentation.get_snapshot()["first_resolve_count"])
		var reacq_before := int(presentation.get_snapshot()["reacquisition_count"])
		map.debug_force_unload_chunk(victim)
		_check(int(map.debug_get_chunk_lifecycle_state(victim)) == state.UNLOADED, "victim did not unload")
		map.call("_queue_chunk_for_reveal", victim, map.get_player_spawn())
		var after := presentation.get_snapshot()
		var victim_tiles: Array[Vector2i] = map.call("_get_chunk_tiles", victim)
		_check(int(after["reacquisition_count"]) - reacq_before == victim_tiles.size(), "reacquired tiles were not counted as reacquisition")
		_check(int(after["first_resolve_count"]) == first_before, "reacquisition was misclassified as first_resolve")
		_check(int(after["identity_mismatch_count"]) == 0, "reacquisition identity disagreed with ever-resolved memory")
		for tile in victim_tiles:
			if not presentation.has_veil(tile):
				_check(false, "reacquired tile %s has no veil before commit" % [tile])
				break

	map.get_parent().queue_free()
	await process_frame

	# Disabled-effect oracle: identical streaming/lifecycle fingerprint, zero veil.
	var off_map := await _make_map(false, 1)
	var off_presentation := off_map.debug_get_reveal_presentation()
	var off_guard := 0
	while off_guard < 600 and not (off_map.get("_streaming_reveal_queue") as Array).is_empty():
		await process_frame
		off_guard += 1
	var off_snap := off_presentation.get_snapshot()
	_check(int(off_snap["active_instance_count"]) == 0 and not bool(off_snap["effect_enabled"]), "disabled effect still has veil instances")
	await process_frame
	await process_frame
	var disabled_fingerprint := _lifecycle_fingerprint(off_map)
	_check(
		disabled_fingerprint["states"] == enabled_fingerprint["states"]
			and disabled_fingerprint["committed"] == enabled_fingerprint["committed"]
			and disabled_fingerprint["floor_cells"] == enabled_fingerprint["floor_cells"]
			and disabled_fingerprint["wall_cells"] == enabled_fingerprint["wall_cells"],
		"enabling Archive Resolve changed lifecycle/streaming fingerprints (%s vs %s)" % [enabled_fingerprint, disabled_fingerprint]
	)
	off_map.get_parent().queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
