extends SceneTree

## Covers PROCGEN_ARCHIVE_RESOLVE_SEMANTIC_ECHO (AR3) at the owner and adapter
## level: bounded class vocabulary, echo only for committed first-resolve cells,
## measurably lighter/shorter reacquisition, deterministic echo identity, the
## one-time ingress wave (settled pocket, ~1.0-1.5 s outward, no exposure of
## uncommitted cover), pause/disabled/reduced fallbacks, and a read-only
## ProcGenTilemap class adapter that follows its owners with no shadow registry.

const PRESENTATION_SCRIPT := preload("res://game/world/procgen/streaming/procgen_reveal_presentation.gd")
const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const NO_OPERATOR := Vector2i(999999, 999999)
const CHUNK := 6
const TEST_SEED := 424242

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_vocabulary()
	_test_echo_first_resolve_only()
	_test_reacquisition_lighter_and_shorter()
	_test_determinism()
	_test_modes()
	_test_ingress_wave()
	await _test_tilemap_adapter()
	_test_no_new_component_query()
	if _errors.is_empty():
		print("[ProcgenArchiveResolveSemanticEchoSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenArchiveResolveSemanticEchoSmoke] %s" % error)
	quit(1)


func _make_owner(resolver: Callable = Callable()) -> ProcGenRevealPresentation:
	var owner_node := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	owner_node.slot_capacity = 2048
	owner_node.resolve_starts_per_frame = 64
	owner_node.frontier_enabled = false  # AR3-era pure-owner fixture: legacy FIFO pacing
	owner_node.resolve_duration_sec = 0.18
	owner_node.reacquisition_duration_sec = 0.12
	owner_node.safety_halo_tiles = 3
	root.add_child(owner_node)
	owner_node.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	if resolver.is_valid():
		owner_node.set_presentation_class_resolver(resolver)
	return owner_node


func _chunk_tiles(chunk: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(chunk.x * CHUNK, chunk.x * CHUNK + CHUNK):
		for y in range(chunk.y * CHUNK, chunk.y * CHUNK + CHUNK):
			tiles.append(Vector2i(x, y))
	return tiles


## Deterministic class fixture: stripes of every class, pure function of the tile.
func _stripe_class(tile: Vector2i) -> int:
	return posmod(tile.x + 2 * tile.y, ProcGenPresentationClass.KIND_COUNT)


func _test_vocabulary() -> void:
	var K := ProcGenPresentationClass.Kind
	_check(ProcGenPresentationClass.KIND_COUNT == 5, "class vocabulary is not bounded to the five locked classes")
	_check(ProcGenPresentationClass.classify(false, false, false, false) == K.NATURAL, "no facts must be natural")
	_check(ProcGenPresentationClass.classify(false, false, true, false) == K.ROAD, "road fact must be road")
	_check(ProcGenPresentationClass.classify(false, false, false, true) == K.CONSTRUCTED, "constructed fact must be constructed")
	_check(ProcGenPresentationClass.classify(false, true, true, true) == K.WALL_CLIFF, "wall/cliff must outrank road/constructed")
	_check(ProcGenPresentationClass.classify(true, true, true, true) == K.MAJOR_LANDMARK, "authored landmark claim must outrank everything")
	_check(ProcGenPresentationClass.echo_lead_sec(K.NATURAL) == 0.0, "natural cells must have no echo lead")
	var lead := ProcGenPresentationClass.echo_lead_sec(K.MAJOR_LANDMARK)
	_check(lead >= 0.1 and lead <= 0.15, "major landmark echo lead %.3f is outside ~100-150 ms" % lead)
	for kind in range(ProcGenPresentationClass.KIND_COUNT):
		_check(ProcGenPresentationClass.echo_lead_sec(kind) <= 0.15, "echo lead exceeds the 150 ms bound")
	_check(ProcGenPresentationClass.echo_lead_sec(99) == 0.0 and ProcGenPresentationClass.echo_lead_sec(-1) == 0.0, "out-of-range class must be inert")
	_check(is_equal_approx(ProcGenPresentationClass.encode(K.MAJOR_LANDMARK), 1.0) and ProcGenPresentationClass.encode(K.NATURAL) == 0.0, "class encoding is not normalised to [0,1]")


func _test_echo_first_resolve_only() -> void:
	var owner_node := _make_owner(Callable(self, "_stripe_class"))
	var chunk := Vector2i(3, 3)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	for _i in range(5):
		owner_node.advance(0.05, NO_OPERATOR, CHUNK)
	_check(int(owner_node.get_snapshot()["echo_write_count"]) == 0, "uncommitted cover received class/echo data (hidden-content leak)")
	for t in tiles:
		owner_node.note_tile_committed(t)
	_check(int(owner_node.get_snapshot()["echo_write_count"]) == 0, "commit alone wrote echo data")
	owner_node.advance(0.0, NO_OPERATOR, CHUNK)
	var snap := owner_node.get_snapshot()
	var expected := 0
	for t in tiles:
		if _stripe_class(t) != ProcGenPresentationClass.Kind.NATURAL:
			expected += 1
	_check(int(snap["echo_write_count"]) == expected, "echo writes %d != classed committed cells %d" % [int(snap["echo_write_count"]), expected])
	var counts: Array = snap["echo_class_counts"]
	_check(int(counts[0]) == 0 and int(counts[1]) > 0 and int(counts[4]) > 0, "echo class counts do not follow the fixture classes")
	# A classed cell holds its veil fully opaque through its echo lead.
	var landmark_tile := Vector2i.ZERO
	for t in tiles:
		if _stripe_class(t) == ProcGenPresentationClass.Kind.MAJOR_LANDMARK:
			landmark_tile = t
			break
	owner_node.advance(0.05, NO_OPERATOR, CHUNK)
	_check(owner_node.get_tile_state(landmark_tile) == ProcGenRevealPresentation.TileState.RESOLVING and owner_node.has_veil(landmark_tile), "landmark cell is not held in its echo/resolve window")
	var natural_tile := Vector2i.ZERO
	for t in tiles:
		if _stripe_class(t) == ProcGenPresentationClass.Kind.NATURAL:
			natural_tile = t
			break
	_check(owner_node.has_veil(natural_tile), "natural cell settled earlier than its resolve duration")
	for _i in range(20):
		owner_node.advance(0.02, NO_OPERATOR, CHUNK)
	snap = owner_node.get_snapshot()
	_check(int(snap["active_instance_count"]) == 0 and int(snap["resolving_count"]) == 0, "classed cells never settled (persistent effect)")
	_check(int(snap["identity_write_count"]) == tiles.size() and int(snap["echo_write_count"]) == expected, "advance rewrote identity/echo data per frame")
	owner_node.queue_free()


func _measure(reacq: bool) -> Dictionary:
	var owner_node := _make_owner(Callable(self, "_stripe_class"))
	var chunk := Vector2i(5, 5)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, reacq)
	for t in tiles:
		owner_node.note_tile_committed(t)
	for _i in range(60):
		owner_node.advance(0.01, NO_OPERATOR, CHUNK)
	var snap := owner_node.get_snapshot()
	owner_node.queue_free()
	return snap


func _test_reacquisition_lighter_and_shorter() -> void:
	var first := _measure(false)
	var reacq := _measure(true)
	_check(int(first["first_resolve_settle_count"]) == CHUNK * CHUNK and int(first["reacquisition_settle_count"]) == 0, "first-resolve settle accounting is wrong")
	_check(int(reacq["reacquisition_settle_count"]) == CHUNK * CHUNK and int(reacq["first_resolve_settle_count"]) == 0, "reacquisition settle accounting is wrong")
	_check(int(reacq["echo_write_count"]) == 0, "reacquisition replayed the evidence echo")
	_check(int(first["echo_write_count"]) > 0, "first resolve produced no echo (control)")
	var first_max := float(first["first_resolve_age_max"])
	var reacq_max := float(reacq["reacquisition_age_max"])
	_check(reacq_max < first_max, "reacquisition (%.3f s) is not shorter than first resolve (%.3f s)" % [reacq_max, first_max])
	_check(reacq_max >= 0.10 and reacq_max <= 0.16, "reacquisition settle %.3f s is outside the ~100-150 ms target" % reacq_max)
	_check(float(reacq["reacquisition_age_avg"]) < float(first["first_resolve_age_avg"]), "reacquisition is not lighter on average")
	_check(first_max <= 0.18 + 0.13 + 0.03, "first resolve exceeds resolve duration + landmark echo lead")


func _echo_trace() -> Array:
	var owner_node := _make_owner(Callable(self, "_stripe_class"))
	var out: Array = []
	for chunk in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		var tiles := _chunk_tiles(chunk)
		owner_node.note_tiles_requested(chunk, tiles, false)
		for t in tiles:
			owner_node.note_tile_committed(t)
	for _i in range(40):
		owner_node.advance(0.02, NO_OPERATOR, CHUNK)
		var s := owner_node.get_snapshot()
		out.append([s["echo_identity_hash"], s["echo_write_count"], s["resolving_count"], s["settled_count"], owner_node.get_frontier_order().size()])
	owner_node.queue_free()
	return out


func _test_determinism() -> void:
	var a := _echo_trace()
	var b := _echo_trace()
	_check(a == b, "same input did not produce identical class/echo/order identity")
	_check(int((a[-1] as Array)[0]) != 0 and int((a[-1] as Array)[1]) > 0, "determinism fixture produced no echo identity")


func _test_modes() -> void:
	# Pause: a zero-delta advance (what a paused tree delivers) starts nothing new.
	var paused := _make_owner(Callable(self, "_stripe_class"))
	var chunk := Vector2i(4, 1)
	paused.note_tiles_requested(chunk, _chunk_tiles(chunk), false)
	for t in _chunk_tiles(chunk):
		paused.note_tile_committed(t)
	paused.advance(0.0, NO_OPERATOR, CHUNK)
	var before := paused.get_snapshot()
	for _i in range(10):
		paused.advance(0.0, NO_OPERATOR, CHUNK)
	var after := paused.get_snapshot()
	_check(before["presentation_time"] == after["presentation_time"] and before["resolving_count"] == after["resolving_count"] and before["settled_count"] == after["settled_count"], "paused (zero-delta) advance moved presentation state")
	paused.queue_free()

	var reduced := _make_owner(Callable(self, "_stripe_class"))
	reduced.reduced_effects = true
	reduced.note_tiles_requested(chunk, _chunk_tiles(chunk), false)
	for t in _chunk_tiles(chunk):
		reduced.note_tile_committed(t)
	for _i in range(30):
		reduced.advance(0.02, NO_OPERATOR, CHUNK)
	_check(int(reduced.get_snapshot()["echo_write_count"]) == 0, "reduced effects still produced an evidence echo")
	_check(float(reduced.get_veil_material().get_shader_parameter("semantic_echo_intensity")) == 0.0, "reduced effects did not zero the shader echo")
	_check(int(reduced.get_snapshot()["active_instance_count"]) == 0, "reduced effects left veil slots behind")
	reduced.queue_free()

	var disabled := _make_owner(Callable(self, "_stripe_class"))
	disabled.set_effect_enabled(false)
	disabled.note_tiles_requested(chunk, _chunk_tiles(chunk), false)
	var committed: Array[Vector2i] = _chunk_tiles(chunk)
	_check(disabled.begin_ingress_resolve(Vector2i(25, 7), committed) == 0, "disabled owner accepted an ingress resolve")
	for t in _chunk_tiles(chunk):
		disabled.note_tile_committed(t)
	disabled.advance(0.1, NO_OPERATOR, CHUNK)
	var snap := disabled.get_snapshot()
	_check(int(snap["active_instance_count"]) == 0 and int(snap["echo_write_count"]) == 0 and int(snap["ingress_begin_count"]) == 0, "disabled owner kept presentation state")
	disabled.queue_free()


func _test_ingress_wave() -> void:
	var owner_node := _make_owner(Callable(self, "_stripe_class"))
	var center := Vector2i(30, 30)
	var radius := owner_node.ingress_radius_tiles
	var pocket := maxi(owner_node.ingress_pocket_tiles, owner_node.safety_halo_tiles)
	# Committed (painted) cells fill the whole square around the Operator.
	var committed: Array[Vector2i] = []
	for x in range(center.x - radius - 3, center.x + radius + 4):
		for y in range(center.y - radius - 3, center.y + radius + 4):
			committed.append(Vector2i(x, y))
	# One requested-but-uncommitted ring cell must stay veiled, never exposed.
	var pending := Vector2i(center.x + pocket + 2, center.y)
	owner_node.note_tiles_requested(Vector2i(0, 0), [pending], false)
	var owned := owner_node.begin_ingress_resolve(center, committed)
	var ring := (2 * radius + 1) * (2 * radius + 1) - (2 * pocket + 1) * (2 * pocket + 1)
	_check(owned == ring - 1, "ingress owns %d cells, expected %d ring cells minus the pending one" % [owned, ring - 1])
	for x in range(center.x - pocket, center.x + pocket + 1):
		for y in range(center.y - pocket, center.y + pocket + 1):
			if owner_node.has_veil(Vector2i(x, y)):
				_check(false, "safety pocket cell %s was re-veiled" % Vector2i(x, y))
				break
	_check(not owner_node.has_veil(center + Vector2i(radius + 1, 0)), "cell outside the ingress radius was veiled")
	_check(owner_node.get_tile_state(pending) == ProcGenRevealPresentation.TileState.REQUESTED, "pending uncommitted ring cell changed state")
	var snap := owner_node.get_snapshot()
	_check(int(snap["ingress_pending_count"]) == owned, "ingress telemetry disagrees with owned cells")
	_check(int(snap["resolving_count"]) == 0 and int(snap["committed_ready_count"]) == 0, "ingress cells leaked into the ordinary queues")

	# Operator-near cells resolve first; the far corner last, inside ~1.0-1.5 s.
	var near := center + Vector2i(pocket + 1, 0)
	var far := center + Vector2i(radius, radius)
	_check(owner_node.ingress_start_time(near) < owner_node.ingress_start_time(far), "ingress does not resolve outward")
	var elapsed := 0.0
	var near_settled_at := -1.0
	var done_at := -1.0
	var pending_committed := false
	while elapsed < 2.5:
		owner_node.advance(0.016, NO_OPERATOR, CHUNK)
		elapsed += 0.016
		if near_settled_at < 0.0 and not owner_node.has_veil(near):
			near_settled_at = elapsed
		if not pending_committed and elapsed > 0.2:
			owner_node.note_tile_committed(pending)
			pending_committed = true
		var s := owner_node.get_snapshot()
		if done_at < 0.0 and pending_committed and int(s["active_instance_count"]) == 0:
			done_at = elapsed
			break
		_check(owner_node.has_veil(pending) or pending_committed, "uncommitted ring cover was released early")
	_check(near_settled_at > 0.0 and near_settled_at < 0.6, "near-pocket ring did not clear early (%.2f s)" % near_settled_at)
	_check(done_at > 0.9 and done_at <= 1.6, "ingress wave settled at %.2f s, outside ~1.0-1.5 s" % done_at)
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "ingress left a persistent veil")
	owner_node.queue_free()

	# Operator walking into the wave force-settles nearby ingress cells.
	var walker := _make_owner()
	var cells: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			cells.append(Vector2i(x, y))
	walker.begin_ingress_resolve(center, cells)
	var stepped := center + Vector2i(pocket + 1, 0)
	walker.advance(0.001, stepped, CHUNK)
	_check(not walker.has_veil(stepped + Vector2i(1, 0)) and not walker.has_veil(stepped), "operator-halo did not settle ingress cells")
	walker.queue_free()

	# One-time: a second owner-level begin is the tilemap's guard; owner stays bounded.
	var twice := _make_owner()
	twice.begin_ingress_resolve(center, cells)
	var first_count := int(twice.get_snapshot()["active_instance_count"])
	twice.begin_ingress_resolve(center, cells)
	_check(int(twice.get_snapshot()["active_instance_count"]) == first_count, "repeat ingress begin grew the veil")
	twice.queue_free()


func _test_tilemap_adapter() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var generator := map.get_node("ProcGen2") as ProcGen
	generator.generate_seed = false
	generator.seed = TEST_SEED
	generator.map_size = Vector2i(112, 96)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.enable_final_foliage = false
	map.enable_ruin_prop_spawning = false
	map.interior_prop_spawning_enabled = false
	map.auto_bake_nav = false
	map.generate()
	await process_frame
	var K := ProcGenPresentationClass.Kind
	var floor_cells := (map.get("_generated_floor_cells") as Dictionary).keys()
	floor_cells.sort()
	var tile := Vector2i.ZERO
	for cell: Vector2i in floor_cells:
		if not (map.get("_generated_wall_cells") as Dictionary).has(cell) \
				and not map.is_road_surface_tile(cell) \
				and map.get_surface_material_at_tile(cell) in [&"natural_soft", &"natural_rock", &"wet_ground", &""]:
			tile = cell
			break
	_check(tile != Vector2i.ZERO, "adapter fixture needs a plain natural floor tile")
	_check(map.get_archive_resolve_presentation_class(tile) == K.NATURAL, "plain floor must classify as natural")
	var resolver: Callable = map.debug_get_reveal_presentation().class_resolver
	_check(resolver.is_valid() and int(resolver.call(tile)) == K.NATURAL, "presentation owner is not wired to the tilemap adapter")

	var materials := map.get("_surface_material_by_cell") as Dictionary
	var old_material: Variant = materials.get(tile, null)
	for pair in [[&"hardened_civic", K.CONSTRUCTED], [&"hardened_industrial", K.CONSTRUCTED], [&"bridge", K.CONSTRUCTED], [&"ruined_road", K.ROAD], [&"authored_landmark", K.CONSTRUCTED], [&"natural_soft", K.NATURAL]]:
		materials[tile] = pair[0]
		_check(map.get_archive_resolve_presentation_class(tile) == pair[1], "material %s did not drive class %d" % [pair[0], pair[1]])
	if old_material == null:
		materials.erase(tile)
	else:
		materials[tile] = old_material
	_check(map.get_archive_resolve_presentation_class(tile) == K.NATURAL, "class did not return to natural after the owner was restored (shadow cache)")
	# Real-map sanity: the hero-landmark class stays a small minority of floor.
	var sample_total := 0
	var sample_landmark := 0
	for cell: Vector2i in floor_cells:
		sample_total += 1
		if map.get_archive_resolve_presentation_class(cell) == K.MAJOR_LANDMARK:
			sample_landmark += 1
	_check(float(sample_landmark) / maxf(1.0, float(sample_total)) < 0.05, "hero-landmark class covers %d/%d floor cells (not restrained)" % [sample_landmark, sample_total])

	var road_authority: Variant = map.get("_road_authority")
	var road_tiles := road_authority.main_road_tiles as Dictionary
	road_tiles[tile] = true
	_check(map.get_archive_resolve_presentation_class(tile) == K.ROAD, "road authority did not drive the road class")
	road_tiles.erase(tile)
	_check(map.get_archive_resolve_presentation_class(tile) == K.NATURAL, "road class stuck after the road owner changed")

	var walls := map.get("_generated_wall_cells") as Dictionary
	walls[tile] = {"source_id": 0}
	_check(map.get_archive_resolve_presentation_class(tile) == K.WALL_CLIFF, "generated wall did not drive the wall/cliff class")
	roads_and_wall_priority(map, tile, road_tiles, walls)
	walls.erase(tile)
	_check(map.get_archive_resolve_presentation_class(tile) == K.NATURAL, "wall class stuck after the wall owner changed")

	var frontage := map.get("_sundered_keep_frontage") as Dictionary
	var saved_frontage := frontage.duplicate(true)
	frontage["terminal_apron_cells"] = {tile: true}
	_check(map.get_archive_resolve_presentation_class(tile) == K.MAJOR_LANDMARK, "authored frontage claim did not drive the landmark class")
	frontage.clear()
	frontage.merge(saved_frontage)
	_check(map.get_archive_resolve_presentation_class(tile) == K.NATURAL, "landmark class stuck after the claim owner changed")
	for kind in [map.get_archive_resolve_presentation_class(tile)]:
		_check(kind >= 0 and kind < ProcGenPresentationClass.KIND_COUNT, "adapter returned an out-of-vocabulary class")

	# Determinism + no leak into authority: classifying changes nothing else.
	var floor_before := (map.get("_generated_floor_cells") as Dictionary).size()
	var walls_before := walls.size()
	var first_pass: Array[int] = []
	var second_pass: Array[int] = []
	for i in range(0, mini(floor_cells.size(), 400), 3):
		first_pass.append(map.get_archive_resolve_presentation_class(floor_cells[i]))
	for i in range(0, mini(floor_cells.size(), 400), 3):
		second_pass.append(map.get_archive_resolve_presentation_class(floor_cells[i]))
	_check(first_pass == second_pass, "class assignment is not deterministic")
	_check(first_pass.has(K.NATURAL) and first_pass.size() > 10, "adapter fixture did not classify a real sample")
	_check((map.get("_generated_floor_cells") as Dictionary).size() == floor_before and walls.size() == walls_before, "classifying mutated generated authority")

	# One-time ingress guard on the tilemap, and no operator/validity involvement.
	var center_global := map.tile_to_global_position(tile)
	var first := map.begin_archive_resolve_ingress(center_global)
	var second := map.begin_archive_resolve_ingress(center_global)
	_check(bool(first["triggered"]) and not bool(second["triggered"]), "ingress is not one-time per generation")
	_check(first["center_tile"] == tile, "ingress did not centre on the supplied final position")
	map.queue_free()
	await process_frame


func roads_and_wall_priority(map: ProcGenTilemap, tile: Vector2i, road_tiles: Dictionary, _walls: Dictionary) -> void:
	road_tiles[tile] = true
	_check(map.get_archive_resolve_presentation_class(tile) == ProcGenPresentationClass.Kind.WALL_CLIFF, "wall/cliff must outrank road on the live adapter")
	road_tiles.erase(tile)


func _test_no_new_component_query() -> void:
	for path in [
		"res://game/world/procgen/streaming/procgen_presentation_class.gd",
		"res://game/world/procgen/streaming/procgen_reveal_presentation.gd",
		"res://game/world/procgen/streaming/archive_resolve.gdshader",
	]:
		var text := FileAccess.get_file_as_string(path)
		_check(text != "" and not text.contains("get_main_playable_component") and not text.contains("is_valid_spawn_cell"), "%s queries spawn validity/component authority" % path)
	var tilemap_text := FileAccess.get_file_as_string("res://game/world/procgen/proc_gen_tilemap.gd")
	var begin := tilemap_text.find("func begin_archive_resolve_ingress(")
	var finish := tilemap_text.find("\nfunc ", begin + 10)
	var body := tilemap_text.substr(begin, finish - begin)
	_check(begin >= 0 and not body.contains("get_main_playable_component") and not body.contains("is_valid_spawn_cell") and not body.contains("global_position ="), "ingress trigger touches spawn validity or moves nodes")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
