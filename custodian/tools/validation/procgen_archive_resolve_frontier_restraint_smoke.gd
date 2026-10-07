extends SceneTree

## Covers PROCGEN_ARCHIVE_RESOLVE_FRONTIER_RESTRAINT (AR4): distance cap, wall/
## door line of sight with wall-destruction invalidation, camera margin, time-
## based pacing under two frame cadences, safety-halo occlusion, settled
## memory, semantic-echo gating, ingress/reacquisition eligibility, and a real
## ProcGenTilemap wiring check. Deterministic miniature fixture: the Operator
## stands in an open yard; a wall line at x=OP.x+4 has a door at y=OP.y; a room
## lies behind it.

const PRESENTATION_SCRIPT := preload("res://game/world/procgen/streaming/procgen_reveal_presentation.gd")
const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CHUNK := 16
const OP := Vector2i(100, 100)
const NO_OPERATOR := Vector2i(999999, 999999)

var _errors: Array[String] = []
var _walls: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_distance_cap()
	_test_los_and_door()
	_test_wall_destruction_invalidation()
	_test_camera_margin()
	_test_pacing_cadence_invariance()
	_test_halo_occlusion()
	_test_settled_memory()
	_test_operator_on_opaque_tile_fails_open()
	_test_echo_and_reacquisition_gate()
	_test_ingress_eligibility()
	_test_ingress_pocket_occlusion()
	await _test_tilemap_wiring()
	if _errors.is_empty():
		print("[ProcgenArchiveResolveFrontierRestraintSmoke] PASS")
		quit(0)
		return
	for e in _errors:
		push_error("[ProcgenArchiveResolveFrontierRestraintSmoke] %s" % e)
	quit(1)


func _is_wall(t: Vector2i) -> bool:
	return _walls.has(t)


func _fixture_walls() -> void:
	_walls.clear()
	for y in range(OP.y - 12, OP.y + 13):
		if y != OP.y:
			_walls[Vector2i(OP.x + 4, y)] = true


func _make(resolver: Callable = Callable()) -> ProcGenRevealPresentation:
	_fixture_walls()
	var o := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	o.slot_capacity = 4096
	o.safety_halo_tiles = 3
	o.visual_resolve_fringe_tiles = 0
	root.add_child(o)
	o.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	o.set_frontier_inputs(Callable(self, "_is_wall"), Callable())
	if resolver.is_valid():
		o.set_presentation_class_resolver(resolver)
	return o


func _commit(o: ProcGenRevealPresentation, tiles: Array[Vector2i], reacq: bool = false) -> void:
	var by_chunk: Dictionary = {}
	for t in tiles:
		var c := Vector2i(int(floor(float(t.x) / CHUNK)), int(floor(float(t.y) / CHUNK)))
		if not by_chunk.has(c):
			by_chunk[c] = [] as Array[Vector2i]
		(by_chunk[c] as Array[Vector2i]).append(t)
	for c in by_chunk:
		o.note_tiles_requested(c, by_chunk[c], reacq)
	for t in tiles:
		o.note_tile_committed(t)


func _rect(center: Vector2i, r: int) -> Array[Vector2i]:
	var a: Array[Vector2i] = []
	for x in range(center.x - r, center.x + r + 1):
		for y in range(center.y - r, center.y + r + 1):
			a.append(Vector2i(x, y))
	return a


func _run_for(o: ProcGenRevealPresentation, seconds: float, step: float, op: Vector2i = OP) -> void:
	var n := int(round(seconds / step))
	for _i in range(n):
		o.advance(step, op, CHUNK)


func _test_distance_cap() -> void:
	var o := _make()
	_walls.clear()
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	var near := Vector2i(OP.x + 5, OP.y + 5)
	var far := Vector2i(OP.x + 20, OP.y)
	_commit(o, [near, far])
	_run_for(o, 1.0, 0.016)
	_check(not o.has_veil(near), "near committed tile did not resolve")
	_check(o.has_veil(far) and o.get_tile_state(far) == ProcGenRevealPresentation.TileState.READY, "committed tile beyond the visual cap resolved or lost its veil")
	var snap: Dictionary = o.get_snapshot()
	_check(int((snap["frontier"] as Dictionary)["ineligible_distance"]) > 0, "distance gate was not counted")
	# fringe determinism: same tile -> same limit
	_check(o.get_frontier().distance_limit(far) == o.get_frontier().distance_limit(far), "fringe is not deterministic")
	o.queue_free()


func _test_los_and_door() -> void:
	var o := _make()
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	var behind := Vector2i(OP.x + 7, OP.y + 5)
	var wall := Vector2i(OP.x + 4, OP.y + 5)
	var through_door := Vector2i(OP.x + 7, OP.y)
	_commit(o, [behind, wall, through_door])
	_run_for(o, 1.0, 0.016)
	_check(not o.has_veil(wall), "the blocking wall itself did not resolve")
	_check(not o.has_veil(through_door), "cell visible through the door did not resolve")
	_check(o.has_veil(behind) and o.get_tile_state(behind) == ProcGenRevealPresentation.TileState.READY, "cell behind an opaque wall resolved")
	_check(int((o.get_snapshot()["frontier"] as Dictionary)["ineligible_occlusion"]) > 0, "occlusion gate was not counted")
	o.queue_free()


func _test_wall_destruction_invalidation() -> void:
	var o := _make()
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	var behind := Vector2i(OP.x + 7, OP.y + 5)
	_commit(o, [behind])
	_run_for(o, 0.6, 0.016)
	_check(o.has_veil(behind), "precondition: tile must stay veiled behind the wall")
	var rebuilds_before := int((o.get_snapshot()["frontier"] as Dictionary)["mask_rebuilds"])
	_walls.erase(Vector2i(OP.x + 4, OP.y + 4))
	_walls.erase(Vector2i(OP.x + 4, OP.y + 5))
	_walls.erase(Vector2i(OP.x + 4, OP.y + 3))
	_run_for(o, 0.6, 0.016)
	_check(not o.has_veil(behind), "wall destruction did not make the newly visible committed cell eligible")
	_check(int((o.get_snapshot()["frontier"] as Dictionary)["mask_rebuilds"]) > rebuilds_before, "mask was not rebuilt after the wall change")
	# No per-frame full rebuild while static.
	var o2 := _make()
	_run_for(o2, 1.0, 0.016)
	var rb := int((o2.get_snapshot()["frontier"] as Dictionary)["mask_rebuilds"])
	_check(rb <= 7, "visibility mask rebuilt %d times in 1 s static (per-frame rebuild)" % rb)
	o.queue_free()
	o2.queue_free()


func _test_camera_margin() -> void:
	var o := _make()
	_walls.clear()
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	var rect := Rect2i(OP + Vector2i(-6, -6), Vector2i(13, 13))
	o.set_frontier_inputs(Callable(self, "_is_wall"), func() -> Rect2i: return rect)
	var inside := OP + Vector2i(5, 0)
	var margin := OP + Vector2i(7, 0)
	var outside := OP + Vector2i(0, 10)
	_commit(o, [inside, margin, outside])
	_run_for(o, 1.0, 0.016)
	_check(not o.has_veil(inside) and not o.has_veil(margin), "camera-visible/margin tiles did not resolve")
	_check(o.has_veil(outside), "off-camera tile beyond the margin consumed ordinary resolve budget")
	_check(int((o.get_snapshot()["frontier"] as Dictionary)["ineligible_camera"]) > 0, "camera gate was not counted")
	o.queue_free()


func _pace(step: float) -> Dictionary:
	var o := _make()
	_walls.clear()
	o.visual_resolve_radius_tiles = 14
	var tiles := _rect(OP, 13)
	_commit(o, tiles)
	var max_frame := 0
	var before := 0
	for _i in range(int(round(2.0 / step))):
		var starts_before := o.frontier_started_count
		o.advance(step, OP, CHUNK)
		max_frame = maxi(max_frame, o.frontier_started_count - starts_before)
		before = o.frontier_started_count
	var out := {"started": before, "max_frame": max_frame, "burst_max": o.frontier_burst_max}
	o.queue_free()
	return out


func _test_pacing_cadence_invariance() -> void:
	var a := _pace(1.0 / 30.0)
	var b := _pace(1.0 / 144.0)
	var expected := 84.0 * 2.0
	for r in [a, b]:
		_check(absf(float(r["started"]) - expected) <= 12.0, "start count %d not ~%d over 2 s" % [int(r["started"]), int(expected)])
		_check(int(r["max_frame"]) <= 8, "per-frame burst %d exceeds cap" % int(r["max_frame"]))
	_check(absf(float(a["started"]) - float(b["started"])) <= 12.0, "pace differs across frame cadences: %d vs %d" % [int(a["started"]), int(b["started"])])


func _test_halo_occlusion() -> void:
	var o := _make()
	o.resolve_starts_per_sec = 1.0
	o.resolve_burst_cap = 1
	# Operator right next to the wall: halo (3) spans the wall line at +4? use +3 wall.
	_walls.clear()
	for y in range(OP.y - 6, OP.y + 7):
		_walls[Vector2i(OP.x + 2, y)] = true
	var wall_tile := Vector2i(OP.x + 2, OP.y + 1)
	var behind := Vector2i(OP.x + 3, OP.y + 1)
	var near_open := Vector2i(OP.x - 2, OP.y)
	_commit(o, [wall_tile, behind, near_open])
	o.advance(0.001, OP, CHUNK)
	_check(not o.has_veil(near_open), "halo did not settle a locally visible committed cell")
	_check(not o.has_veil(wall_tile), "halo did not settle the blocking wall face")
	_check(o.has_veil(behind), "halo force-settled a committed cell through an opaque wall")
	_check(int(o.get_snapshot()["frontier_halo_blocked_count"]) > 0, "halo occlusion was not counted")
	# uncommitted cells are never exposed
	var o3 := _make()
	var req := Vector2i(OP.x - 1, OP.y)
	o3.note_tiles_requested(Vector2i(6, 6), [req] as Array[Vector2i], false)
	o3.advance(0.5, OP, CHUNK)
	_check(o3.has_veil(req), "uncommitted tile was revealed by the frontier/halo")
	o.queue_free()
	o3.queue_free()


func _test_settled_memory() -> void:
	var o := _make()
	_walls.clear()
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	var t := OP + Vector2i(3, 3)
	_commit(o, [t])
	_run_for(o, 1.0, 0.016)
	_check(not o.has_veil(t), "precondition: tile settled")
	var settled_before := int(o.get_snapshot()["settled_count"])
	# Walk far away and turn behind cover.
	_run_for(o, 1.0, 0.016, OP + Vector2i(60, 0))
	_check(not o.has_veil(t) and o.get_tile_state(t) == 0, "settled tile re-veiled after leaving the frontier")
	_check(int(o.get_snapshot()["settled_count"]) == settled_before, "settled memory changed on departure")
	o.queue_free()


func _test_operator_on_opaque_tile_fails_open() -> void:
	var o := _make()
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	_walls[OP] = true
	var near := OP + Vector2i(3, 0)
	_commit(o, [near])
	_run_for(o, 1.0, 0.016)
	_check(not o.has_veil(near), "Operator on an opaque tile veiled the whole neighbourhood (must fail open)")
	o.queue_free()


func _echo_class(_t: Vector2i) -> int:
	return ProcGenPresentationClass.Kind.ROAD


func _test_echo_and_reacquisition_gate() -> void:
	var o := _make(Callable(self, "_echo_class"))
	o.resolve_burst_cap = 64
	o.resolve_starts_per_sec = 600.0
	var behind := Vector2i(OP.x + 7, OP.y + 5)
	var far := Vector2i(OP.x + 25, OP.y)
	var near := Vector2i(OP.x - 5, OP.y)
	_commit(o, [behind, far, near])
	_run_for(o, 1.0, 0.016)
	_check(int(o.get_snapshot()["echo_write_count"]) == 1, "echo leaked past the frontier (writes=%d)" % int(o.get_snapshot()["echo_write_count"]))
	# Reacquisition respects eligibility and stays shorter/weaker once eligible.
	var o2 := _make()
	o2.resolve_burst_cap = 64
	o2.resolve_starts_per_sec = 600.0
	var rnear := Vector2i(OP.x - 5, OP.y)
	var rbehind := Vector2i(OP.x + 7, OP.y + 5)
	var rfar := Vector2i(OP.x - 30, OP.y)
	o2.note_chunk_unloaded(Vector2i(int(floor(float(rnear.x) / CHUNK)), int(floor(float(rnear.y) / CHUNK))), CHUNK)
	_commit(o2, [rnear], true)
	_commit(o2, [rbehind, rfar], true)
	_run_for(o2, 0.6, 0.016)
	var snap := o2.get_snapshot()
	_check(not o2.has_veil(rnear), "eligible reacquisition cell never resolved")
	_check(o2.has_veil(rbehind) and o2.has_veil(rfar), "ineligible reacquisition cells resolved")
	_check(float(snap["reacquisition_age_max"]) <= o2.reacquisition_duration_sec + 0.05, "reacquisition no longer short once eligible")
	o.queue_free()
	o2.queue_free()


func _test_ingress_eligibility() -> void:
	var o := _make()
	_walls.clear()
	var ring_far := Vector2i(OP.x + 13, OP.y)
	var ring_near := Vector2i(OP.x + 6, OP.y)
	var cells: Array[Vector2i] = [ring_far, ring_near]
	o.begin_ingress_resolve(OP, cells, CHUNK)
	_run_for(o, 2.0, 0.016)
	_check(not o.has_veil(ring_near), "eligible ingress ring cell did not resolve")
	_check(o.has_veil(ring_far), "ingress started a cell beyond the visual frontier")
	# It resolves once the Operator approaches (state stays presentation-only).
	_run_for(o, 1.0, 0.016, Vector2i(OP.x + 8, OP.y))
	_check(not o.has_veil(ring_far), "deferred ingress cell never resolved after becoming eligible")
	o.queue_free()


func _test_ingress_pocket_occlusion() -> void:
	var target := OP + Vector2i(2, 1)
	var wall := OP + Vector2i(1, 1)
	var existing := _make()
	_walls.clear()
	_walls[wall] = true
	var uncommitted := target + Vector2i(0, 1)
	var uncommitted_chunk := Vector2i(int(floor(float(uncommitted.x) / CHUNK)), int(floor(float(uncommitted.y) / CHUNK)))
	existing.note_tiles_requested(uncommitted_chunk, [uncommitted], false)
	_commit(existing, [target])
	existing.begin_ingress_resolve(OP, [target], CHUNK)
	_check(existing.has_veil(target), "ingress settled an existing occluded pocket cell")
	_check(existing.has_veil(uncommitted), "ingress settled an uncommitted pocket cell")
	_walls.erase(wall)
	_run_for(existing, 0.6, 0.016)
	_check(not existing.has_veil(target), "existing pocket cell did not settle after visibility opened")
	existing.queue_free()

	var resolving := _make()
	resolving.safety_halo_tiles = 0
	_walls.clear()
	_commit(resolving, [target])
	resolving.advance(0.016, OP, CHUNK)
	_walls[wall] = true
	resolving.begin_ingress_resolve(OP, [target], CHUNK)
	_check(resolving.has_veil(target), "ingress canceled an already-resolving pocket cell")
	_run_for(resolving, resolving.resolve_duration_sec + 0.2, 0.016)
	_check(not resolving.has_veil(target), "already-resolving pocket cell did not finish monotonically")
	resolving.queue_free()

	var visible := _make()
	_walls.clear()
	_commit(visible, [target])
	visible.begin_ingress_resolve(OP, [target], CHUNK)
	_check(not visible.has_veil(target), "visible committed pocket cell did not settle immediately")
	visible.queue_free()

	var later_commit := _make()
	_walls.clear()
	_walls[wall] = true
	later_commit.begin_ingress_resolve(OP, [], CHUNK)
	_commit(later_commit, [target])
	_check(later_commit.has_veil(target), "later occluded pocket commit settled synchronously")
	later_commit.advance(0.016, OP, CHUNK)
	_check(later_commit.has_veil(target), "later occluded pocket commit settled before visibility opened")
	_walls.erase(wall)
	_run_for(later_commit, 0.6, 0.016)
	_check(not later_commit.has_veil(target), "later pocket commit did not settle after visibility opened")
	later_commit.queue_free()


func _test_tilemap_wiring() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	await process_frame
	var presentation := map.debug_get_reveal_presentation()
	_check(presentation != null and presentation.occluder.is_valid() and presentation.camera_rect_provider.is_valid(), "tilemap did not wire frontier inputs")
	var walls := map.get("_generated_wall_cells") as Dictionary
	var tile := Vector2i(-77, -77)
	walls[tile] = {"source_id": 0}
	_check(map.is_archive_resolve_occluder_tile(tile), "occluder does not follow canonical generated walls")
	walls.erase(tile)
	_check(not map.is_archive_resolve_occluder_tile(tile), "occluder kept a shadow wall after the owner changed")
	_check(not map.get_archive_resolve_camera_tile_rect().has_area(), "camera rect must be empty without a camera")
	map.queue_free()
	await process_frame


func _check(c: bool, m: String) -> void:
	if not c:
		_errors.append(m)
