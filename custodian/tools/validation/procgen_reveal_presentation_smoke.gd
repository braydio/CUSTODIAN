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
	owner_node.frontier_enabled = false  # AR3-era pure-owner fixture: legacy FIFO pacing
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
	_test_connected_cascade()

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


func _test_connected_cascade() -> void:
	var owner_node := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	owner_node.slot_capacity = 128
	owner_node.safety_halo_tiles = 0
	owner_node.resolve_starts_per_sec = 600.0
	owner_node.resolve_burst_cap = 8
	owner_node.resolve_duration_sec = 2.0
	owner_node.visual_resolve_radius_tiles = 18
	owner_node.cascade_neighbor_stagger_sec = 0.03
	root.add_child(owner_node)
	owner_node.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	var tiles: Array[Vector2i] = []
	for x in range(20, 27):
		for y in range(20, 27):
			var tile := Vector2i(x, y)
			tiles.append(tile)
	owner_node.note_tiles_requested(Vector2i(3, 3), tiles, false)
	for tile in tiles:
		owner_node.note_tile_committed(tile)
	for _i in range(30):
		owner_node.advance(0.02, Vector2i(23, 23), CHUNK)
	var starts: Dictionary = owner_node._resolve_start
	var waves: Dictionary = {}
	for tile_variant: Variant in starts.keys():
		var tile := tile_variant as Vector2i
		var wave := int(owner_node._cascade_wave_by_tile.get(tile, 0))
		waves[wave] = true
		if wave == 0:
			_check(false, "connected cascade start has no cascade identity")
			continue
		var has_earlier_parent := false
		for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = tile + offset
			if starts.has(neighbor) and int(owner_node._cascade_wave_by_tile.get(neighbor, 0)) == wave \
					and float(starts.get(neighbor, 1e9)) < float(starts[tile]):
				has_earlier_parent = true
				break
		if not has_earlier_parent and float(starts[tile]) > 0.03:
			_check(false, "non-origin cascade start is not four-connected to an earlier start")
	_check(waves.size() <= owner_node.cascade_max_origins, "connected patch exceeded bounded origin count")
	_check(starts.size() > 12, "connected cascade did not traverse the committed patch")
	owner_node.queue_free()
	var late_owner := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	late_owner.slot_capacity = 8
	late_owner.safety_halo_tiles = 0
	late_owner.resolve_starts_per_sec = 600.0
	late_owner.resolve_duration_sec = 2.0
	root.add_child(late_owner)
	late_owner.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	var seed_tile := Vector2i(20, 20)
	var late_tile := seed_tile + Vector2i.RIGHT
	late_owner.note_tiles_requested(Vector2i(3, 3), [seed_tile] as Array[Vector2i], false)
	late_owner.note_tile_committed(seed_tile)
	late_owner.advance(0.02, seed_tile, CHUNK)
	late_owner.note_tiles_requested(Vector2i(3, 3), [late_tile] as Array[Vector2i], false)
	late_owner.note_tile_committed(late_tile)
	for _i in range(8):
		late_owner.advance(0.02, seed_tile, CHUNK)
	_check(late_owner.get_tile_state(late_tile) == ProcGenRevealPresentation.TileState.RESOLVING, "late committed neighbor did not join an active cascade")
	_check(late_owner._cascade_wave_by_tile.get(late_tile, 0) == late_owner._cascade_wave_by_tile.get(seed_tile, -1), "late neighbor joined a different cascade origin")
	var onset_delta := float(late_owner._resolve_start[late_tile]) - float(late_owner._resolve_start[seed_tile])
	_check(onset_delta >= 0.03 and onset_delta <= 0.09, "late neighbor onset stagger is outside the bounded near-neighbor window")
	late_owner.queue_free()
	var companion_owner := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	companion_owner.slot_capacity = 8
	companion_owner.safety_halo_tiles = 0
	companion_owner.resolve_starts_per_sec = 600.0
	companion_owner.resolve_duration_sec = 2.0
	root.add_child(companion_owner)
	companion_owner.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	var frontier_tile := Vector2i(30, 30)
	var fascia_tile := frontier_tile + Vector2i(0, 1)
	companion_owner.set_cliff_companion_cells({frontier_tile: [fascia_tile]})
	companion_owner.note_tiles_requested(Vector2i(5, 5), [frontier_tile] as Array[Vector2i], false)
	_check(companion_owner.has_veil(frontier_tile) and companion_owner.has_veil(fascia_tile), "cliff companion was not veiled through the owner frontier request")
	companion_owner.note_tile_committed(frontier_tile)
	companion_owner.advance(0.02, frontier_tile, CHUNK)
	_check(companion_owner.get_tile_state(frontier_tile) == ProcGenRevealPresentation.TileState.RESOLVING, "visible cliff owner frontier did not begin resolving")
	_check(companion_owner.get_tile_state(fascia_tile) == ProcGenRevealPresentation.TileState.RESOLVING, "cliff companion did not resolve with its existing owner frontier")
	_check(is_equal_approx(float(companion_owner._resolve_start[frontier_tile]), float(companion_owner._resolve_start[fascia_tile])), "cliff companion diverged from owner frontier timing")
	companion_owner.queue_free()

	# A true singleton gets one deterministic age-based fallback instead of
	# remaining READY forever, while the initial independent origin budget stays bounded.
	var isolated := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	isolated.slot_capacity = 8
	isolated.safety_halo_tiles = 0
	isolated.resolve_starts_per_sec = 600.0
	isolated.resolve_duration_sec = 2.0
	isolated.visual_resolve_radius_tiles = 18
	isolated.cascade_isolated_fallback_sec = 0.75
	root.add_child(isolated)
	isolated.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	var lone := Vector2i(30, 30)
	var disconnected: Array[Vector2i] = [Vector2i(10, 10), Vector2i(30, 10), Vector2i(10, 30), lone]
	isolated.note_tiles_requested(Vector2i(3, 3), disconnected, false)
	for tile in disconnected:
		isolated.note_tile_committed(tile)
	for _i in range(30):
		isolated.advance(0.02, Vector2i(20, 20), CHUNK)
	var resolving_before_fallback := 0
	var fallback_tile := Vector2i(999999, 999999)
	for tile in disconnected:
		if isolated.get_tile_state(tile) == ProcGenRevealPresentation.TileState.RESOLVING:
			resolving_before_fallback += 1
		elif isolated.get_tile_state(tile) == ProcGenRevealPresentation.TileState.READY:
			fallback_tile = tile
	_check(resolving_before_fallback == isolated.cascade_max_origins, "disconnected wave origins exceeded the bounded initial origin budget")
	_check(fallback_tile != Vector2i(999999, 999999), "isolated fallback started before its bounded age")
	for _i in range(15):
		isolated.advance(0.02, Vector2i(20, 20), CHUNK)
	_check(isolated.get_tile_state(fallback_tile) == ProcGenRevealPresentation.TileState.RESOLVING, "isolated eligible cell never entered bounded fallback")
	isolated.queue_free()


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
	_check(presentation.z_index == 200 and not presentation.z_as_relative and presentation.multimesh != null, "veil is not an absolute batched world-presentation layer above ordinary world content")
	var underfield := map.get_node_or_null("ArchiveResolveUnrequestedUnderfield") as ColorRect
	_check(underfield != null and underfield.material is ShaderMaterial, "unrequested in-bounds world has no shared graphite underfield")
	var underfield_material := underfield.material as ShaderMaterial if underfield != null else null
	_check(underfield_material != null and underfield_material.shader.resource_path.ends_with("archive_resolve_underfield.gdshader"), "unrequested underfield is not the Archive Resolve world-space shader")
	if underfield != null:
		var first_center := map.floor_tilemap.to_global(map.floor_tilemap.map_to_local(Vector2i.ZERO))
		var underfield_parent := underfield.get_parent() as Node2D
		var expected_position: Vector2 = underfield_parent.global_transform.affine_inverse() * first_center - Vector2(map._get_tile_size()) * 0.5
		var expected_size := Vector2(map.procgen_node.map_size) * Vector2(map._get_tile_size())
		_check(underfield.visible, "in-bounds underfield was hidden after generation")
		_check(underfield.position.is_equal_approx(expected_position), "underfield origin does not align to the first world tile")
		_check(underfield.size.is_equal_approx(expected_size), "underfield spills beyond or stops short of the generated map bounds")
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
