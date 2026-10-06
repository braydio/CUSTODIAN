extends SceneTree

## Covers PROCGEN_ARCHIVE_RESOLVE_SHADER (AR2): one shared ShaderMaterial on the
## batched veil, deterministic one-shot custom-data identity, pause-safe
## presentation_time sync, reduced-effects/disabled parity, REQUESTED/READY
## cover staying fully opaque, and no per-cell node/material growth.

const PRESENTATION_SCRIPT := preload("res://game/world/procgen/streaming/procgen_reveal_presentation.gd")
const NO_OPERATOR := Vector2i(999999, 999999)
const CHUNK := 6
const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_material_and_identity()
	_test_clock_and_controls()
	_test_scheduling_parity()
	_test_live_disable_and_scene_order()
	await _test_map_integration()
	if _errors.is_empty():
		print("[ProcgenArchiveResolveShaderSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenArchiveResolveShaderSmoke] %s" % error)
	quit(1)


func _make_owner(reduced: bool = false) -> ProcGenRevealPresentation:
	var owner_node := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	owner_node.slot_capacity = 256
	owner_node.resolve_starts_per_frame = 4
	owner_node.frontier_enabled = false  # AR3-era pure-owner fixture: legacy FIFO pacing
	owner_node.resolve_duration_sec = 0.1
	owner_node.safety_halo_tiles = 2
	owner_node.reduced_effects = reduced
	root.add_child(owner_node)
	owner_node.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	return owner_node


func _chunk_tiles(chunk: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(chunk.x * CHUNK, chunk.x * CHUNK + CHUNK):
		for y in range(chunk.y * CHUNK, chunk.y * CHUNK + CHUNK):
			tiles.append(Vector2i(x, y))
	return tiles


func _test_material_and_identity() -> void:
	var owner_node := _make_owner()
	var mat := owner_node.get_veil_material()
	_check(mat != null and owner_node.material == mat, "veil is not bound to exactly one shared ShaderMaterial")
	_check(mat != null and mat.shader != null and mat.shader.get_mode() == Shader.MODE_CANVAS_ITEM, "veil material is not the canvas_item Archive Resolve shader")
	var snap := owner_node.get_snapshot()
	_check(int(snap["shared_material_count"]) == 1 and bool(snap["shader_enabled"]) and bool(snap["custom_data_enabled"]), "material/custom-data telemetry is wrong")
	var chunk := Vector2i(3, 4)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, true)
	_check(owner_node.get_child_count() == 0 and owner_node.material == mat, "request grew nodes or replaced the shared material")
	# Identity is written once per slot assignment (headless MultiMesh buffers are
	# not readable, so the owner counts writes instead).
	_check(int(owner_node.get_snapshot()["identity_write_count"]) == tiles.size(), "identity was not written exactly once per assigned slot")
	_check(ProcGenRevealPresentation.cell_identity_hash(Vector2i(-7, 12)) == ProcGenRevealPresentation.cell_identity_hash(Vector2i(-7, 12)), "identity hash is not deterministic")
	var seen := {}
	for t in tiles:
		var h := ProcGenRevealPresentation.cell_identity_hash(t)
		_check(h >= 0.0 and h <= 1.0, "identity hash out of range")
		seen[h] = true
	_check(seen.size() > tiles.size() / 2, "identity hash has no per-cell variation")
	owner_node.note_tile_committed(tiles[0])
	for _i in range(10):
		owner_node.advance(0.05, NO_OPERATOR, CHUNK)
	_check(int(owner_node.get_snapshot()["identity_write_count"]) == tiles.size(), "advance rewrote slot identity (per-frame custom-data write)")
	for t in tiles.slice(1):
		_check(owner_node.get_tile_state(t) == ProcGenRevealPresentation.TileState.REQUESTED and owner_node.has_veil(t), "uncommitted cover was released")
		break
	# Settled/released slots are invisible and neutral; no per-cell material.
	_check(owner_node.get_veil_material() == mat, "shared material identity changed")
	owner_node.queue_free()


func _test_clock_and_controls() -> void:
	var owner_node := _make_owner()
	var mat := owner_node.get_veil_material()
	owner_node.advance(0.25, NO_OPERATOR, CHUNK)
	_check(is_equal_approx(float(mat.get_shader_parameter("presentation_time")), 0.25), "shader presentation_time does not track the owner clock")
	owner_node.advance(0.0, NO_OPERATOR, CHUNK)
	_check(is_equal_approx(float(mat.get_shader_parameter("presentation_time")), 0.25), "zero advance moved shader time (no pause-safe freeze)")
	owner_node.set_effect_enabled(false)
	owner_node.advance(1.0, NO_OPERATOR, CHUNK)
	_check(is_equal_approx(float(mat.get_shader_parameter("presentation_time")), 0.25), "disabled owner advanced shader time")
	owner_node.reduced_effects = true
	_check(float(mat.get_shader_parameter("phase_misregistration_intensity")) == 0.0, "reduced effects did not suppress phase misregistration")
	_check(float(mat.get_shader_parameter("registration_intensity")) < owner_node.registration_intensity, "reduced effects did not weaken registration")
	_check(float(mat.get_shader_parameter("unresolved_haze_intensity")) == owner_node.unresolved_haze_intensity, "reduced effects altered unresolved cover")
	owner_node.reduced_effects = false
	_check(float(mat.get_shader_parameter("phase_misregistration_intensity")) == owner_node.phase_misregistration_intensity, "leaving reduced effects did not restore controls")
	owner_node.queue_free()


func _trace(reduced: bool) -> Array:
	var owner_node := _make_owner(reduced)
	var chunk := Vector2i(2, 3)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	var out: Array = []
	for t in tiles:
		owner_node.note_tile_committed(t)
	for _i in range(40):
		owner_node.advance(0.02, NO_OPERATOR, CHUNK)
		out.append(owner_node.get_frontier_order().duplicate())
		var s := owner_node.get_snapshot()
		out.append([s["settled_count"], s["resolving_count"], s["active_instance_count"], s["requested_uncommitted_count"]])
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "settled terrain kept veil slots")
	owner_node.queue_free()
	return out


func _test_scheduling_parity() -> void:
	var a := _trace(false)
	var b := _trace(false)
	var r := _trace(true)
	_check(a == b and not a.is_empty(), "scheduling trace is not deterministic")
	_check(a == r, "reduced effects changed scheduling/order/timing")


func _test_live_disable_and_scene_order() -> void:
	# R0-01: a direct property write must not strand veil slots.
	var owner_node := _make_owner()
	var chunk := Vector2i(1, 1)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	for t in tiles.slice(0, 8):
		owner_node.note_tile_committed(t)
	owner_node.effect_enabled = false
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "direct effect_enabled=false stranded veil slots")
	owner_node.note_tile_committed(tiles[20])
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "late commit after disable re-veiled")
	owner_node.effect_enabled = true
	owner_node.note_tiles_requested(chunk, tiles, true)
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == tiles.size(), "re-enable did not restore veil coverage")
	owner_node.queue_free()
	# R0-02: ContractMap precedes z2 actor/item/projectile containers.
	var text := FileAccess.get_file_as_string("res://scenes/game.tscn")
	var cm := text.find('[node name="ContractMap" type="Node2D" parent="World"')
	_check(cm >= 0, "game.tscn has no World/ContractMap")
	for sibling in ["Enemies", "Projectiles", "Allies", "Items"]:
		var idx := text.find('[node name="%s" type="Node2D" parent="World"' % sibling)
		_check(idx > cm, "ContractMap does not precede World/%s" % sibling)
	_check(text.find('[node name="Operator" parent="World"') > cm, "ContractMap does not precede World/Operator")


func _make_map(slot_capacity: int) -> ProcGenTilemap:
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
	map.streaming_immediate_chunk_radius = 1
	map.streaming_active_chunk_radius = 2
	map.streaming_reveal_tiles_per_frame = 16
	map.build_runtime_wall_collision = true
	(map.get_node("ArchiveResolveVeil") as ProcGenRevealPresentation).slot_capacity = slot_capacity
	map.generate()
	return map


func _drain(map: ProcGenTilemap) -> void:
	var presentation := map.debug_get_reveal_presentation()
	var guard := 0
	while guard < 600 and (
		not (map.get("_streaming_reveal_queue") as Array).is_empty()
		or int(presentation.get_snapshot()["active_instance_count"]) > 0
	):
		await process_frame
		guard += 1
	await process_frame
	await process_frame


func _fingerprint(map: ProcGenTilemap) -> Array:
	var states: Array = []
	for entry in map.debug_get_chunk_lifecycle_states():
		states.append([entry.get("chunk"), entry.get("state"), entry.get("committed")])
	var health := map.get_runtime_health_snapshot()
	return [states, health.get("painted_floor_cell_count", -1), health.get("painted_wall_cell_count", -1)]


func _test_map_integration() -> void:
	# Baseline: default capacity, drained.
	var base_map := await _make_map(8192)
	await _drain(base_map)
	var baseline := _fingerprint(base_map)
	base_map.get_parent().queue_free()
	await process_frame

	# Live toggle (ARR1 R0-03): REQUESTED work exists, disable via the map API.
	var map := await _make_map(8192)
	var presentation := map.debug_get_reveal_presentation()
	_check(int(presentation.get_snapshot()["active_instance_count"]) > 0, "fixture produced no veiled work to toggle")
	map.set_archive_resolve_enabled(false)
	_check(int(presentation.get_snapshot()["active_instance_count"]) == 0, "live disable left active veil slots")
	await _drain(map)
	var off_snap := presentation.get_snapshot()
	_check(int(off_snap["active_instance_count"]) == 0 and not bool(off_snap["effect_enabled"]), "disabled map regained veils")
	_check(_fingerprint(map) == baseline, "live disable changed lifecycle/streaming fingerprint")
	map.set_archive_resolve_enabled(true)
	var victim := Vector2i(999999, 999999)
	var spawn_chunk := map.call("_tile_to_chunk", map.get_player_spawn()) as Vector2i
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var candidate := spawn_chunk + Vector2i(dx, dy)
			if candidate != spawn_chunk and victim == Vector2i(999999, 999999) \
					and int(map.debug_get_chunk_lifecycle_state(candidate)) == ProcGenChunkLifecycle.State.VISIBLE:
				victim = candidate
	_check(victim != Vector2i(999999, 999999), "no VISIBLE victim chunk for re-enable proof")
	if victim != Vector2i(999999, 999999):
		map.debug_force_unload_chunk(victim)
		map.call("_queue_chunk_for_reveal", victim, map.get_player_spawn())
		_check(int(presentation.get_snapshot()["active_instance_count"]) > 0, "re-enable did not veil a subsequent reveal")
		await _drain(map)
		_check(int(presentation.get_snapshot()["active_instance_count"]) == 0, "re-enabled reveal did not settle")
	map.get_parent().queue_free()
	await process_frame

	# Undersized pool inside the production map: bounded, fail-open, exact accounting.
	var small_map := await _make_map(64)
	var small := small_map.debug_get_reveal_presentation()
	var peak := 0
	var guard := 0
	while guard < 600 and (
		not (small_map.get("_streaming_reveal_queue") as Array).is_empty()
		or int(small.get_snapshot()["active_instance_count"]) > 0
	):
		peak = maxi(peak, int(small.get_snapshot()["active_instance_count"]))
		await process_frame
		guard += 1
	await process_frame
	var s := small.get_snapshot()
	_check(peak <= 64, "undersized pool was not bounded (peak=%d)" % peak)
	_check(int(s["overflow_count"]) > 0, "undersized pool recorded no overflow")
	_check(int(s["settled_count"]) == int(s["requested_total_count"]), "overflow cells did not fail open into settled accounting")
	_check(int(s["active_instance_count"]) == 0, "undersized pool left active veils")
	_check(_fingerprint(small_map) == baseline, "undersized pool changed lifecycle/streaming fingerprint")
	small_map.get_parent().queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
