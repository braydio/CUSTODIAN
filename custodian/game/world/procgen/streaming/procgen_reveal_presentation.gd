class_name ProcGenRevealPresentation
extends MultiMeshInstance2D

## Archive Resolve spine (AR1): the single presentation-only owner of the
## continuous world-space reveal frontier. It consumes tile-level request /
## commit / unload observations from ProcGenTilemap's existing streaming seams
## and renders unresolved cells through one batched flat diagnostic veil (this
## node's own MultiMesh). It never infers or mutates chunk lifecycle, never
## vetoes unload, and never touches generation, PREPARE/COMMIT, cache,
## residency, collision, navigation, or Region Frame state.
##
## Per-tile presentation states: REQUESTED (veiled, authoritative pixels not
## yet committed) -> READY (committed, waiting for a resolve slot) ->
## RESOLVING (veil ramping out) -> settled (veil slot released; tracked only as
## an aggregate counter). Only READY tiles may resolve. The presentation clock
## advances only through `advance()`, which ProcGenTilemap calls from its own
## unpaused `_process`, so pause freezes it with no time jump on resume.
##
## AR2 adds only the render encoding: one shared `ShaderMaterial` on this node
## (graphite/soot veil, ordered world-space dither resolve, restrained brass
## registration trace, optional <=1 px phase misregistration) and a one-shot
## per-slot identity write into MultiMesh custom data. `COLOR.a` stays the
## authoritative progress/opacity channel; the shader owns no lifecycle state and
## the scheduling above is unchanged.
##
## AR3 adds three presentation-only behaviours, all driven by the same unpaused
## clock and never by lifecycle truth: (1) a bounded semantic evidence echo
## (`ProcGenPresentationClass`) shown only for already-committed first-resolve
## cells, resolved lazily per starting tile through `class_resolver` and written
## once into the `.b/.a` custom-data channels; (2) a shorter, lighter
## reacquisition treatment keyed to the lifecycle identity; (3) a one-time
## ingress resolve that re-veils already-committed cells outside a settled
## safety pocket and releases them outward over `ingress_wave_sec`.

## AR4 adds the presentation frontier (`ProcGenVisualFrontier`): ordinary
## first-resolve, echo, ingress and reacquisition may only BEGIN for committed
## cells inside a distance cap that Operator line of sight and the camera rect
## also admit, paced by a time-based token budget. Settled cells are never
## re-veiled by the frontier, and RESOLVING cells always finish.

enum TileState { REQUESTED = 1, READY = 2, RESOLVING = 3, INGRESS = 4 }

const ARCHIVE_RESOLVE_SHADER := preload("res://game/world/procgen/streaming/archive_resolve.gdshader")

const NO_OPERATOR_TILE := Vector2i(999999, 999999)

## Veil quad overhang beyond the 32 px semantic cell, per side, in px.
const VEIL_OVERLAP_PX := 1.0

## Reduced-effects registration multiplier (misregistration is fully removed).
const REDUCED_REGISTRATION_SCALE := 0.25

## Master switch. Direct writes route through the same disable/settle path as
## `set_effect_enabled()`: disabling releases every veil slot immediately.
@export var effect_enabled: bool = true:
	set(value):
		if effect_enabled == value:
			return
		effect_enabled = value
		if not value:
			_settle_all_immediately()
@export_range(64, 65536, 1) var slot_capacity: int = 8192
## Ordinary settlement work bound: READY tiles that may begin resolving/frame.
## Legacy frame-based pacing; used only when `frontier_enabled` is false.
@export_range(1, 4096, 1) var resolve_starts_per_frame: int = 48
## AR4 master switch for the frontier + time-based pacing. Off restores the AR3
## FIFO behaviour (kept for pure-owner fixtures and as a debug fallback).
@export var frontier_enabled: bool = true
## Time-based start budget: tokens accrue per second of presentation time and
## are spent per started tile, capped per frame by `resolve_burst_cap`.
@export_range(1.0, 600.0, 1.0) var resolve_starts_per_sec: float = 84.0
@export_range(1, 256, 1) var resolve_burst_cap: int = 8
## Bounded per-frame eligibility scan of the READY queue (rotating cursor).
@export_range(16, 8192, 1) var eligibility_scan_per_frame: int = 1024
@export_range(1, 32, 1) var visual_resolve_radius_tiles: int = 11
@export_range(0, 8, 1) var visual_resolve_fringe_tiles: int = 2
@export_range(0, 16, 1) var camera_margin_tiles: int = 2
@export_range(0.0, 2.0, 0.01) var resolve_duration_sec: float = 0.22
## Reacquisition (previously resolved, later unloaded) settles much faster.
@export_range(0.0, 1.0, 0.01) var reacquisition_duration_sec: float = 0.12
## One-time ingress resolve: Chebyshev tile radius re-veiled around the final
## Operator tile, the always-settled pocket inside it, and the outward wave
## duration. First tiles start immediately; total settle is wave + resolve.
@export_range(2, 32, 1) var ingress_radius_tiles: int = 14
@export_range(0, 16, 1) var ingress_pocket_tiles: int = 4
@export_range(0.2, 2.0, 0.05) var ingress_wave_sec: float = 1.0
## Chebyshev tile radius around the Operator inside which already-committed
## cells are force-settled. Never reveals an uncommitted cell.
@export_range(0, 16, 1) var safety_halo_tiles: int = 3
@export var veil_color: Color = Color(0.07, 0.075, 0.085, 1.0)
@export_group("Archive Resolve Shader", "")
## Brass/amber registration trace strength at the dissolve boundary.
@export_range(0.0, 1.0, 0.01) var registration_intensity: float = 0.6:
	set(value):
		registration_intensity = value
		_sync_material_controls()
## Low-frequency soot/graphite variation across unresolved cover.
@export_range(0.0, 1.0, 0.01) var unresolved_haze_intensity: float = 0.5:
	set(value):
		unresolved_haze_intensity = value
		_sync_material_controls()
## <=1 px registration offset early in RESOLVING. Suppressed by reduced effects.
@export_range(0.0, 1.0, 0.01) var phase_misregistration_intensity: float = 0.5:
	set(value):
		phase_misregistration_intensity = value
		_sync_material_controls()
## Semantic evidence-echo strength (faint contour/registration hint).
@export_range(0.0, 1.0, 0.01) var semantic_echo_intensity: float = 0.5:
	set(value):
		semantic_echo_intensity = value
		_sync_material_controls()
## Calmer profile: no phase misregistration, much weaker registration trace,
## and no semantic evidence echo.
## Never changes request/commit/order/timing or the unresolved safety cover.
@export var reduced_effects: bool = false:
	set(value):
		reduced_effects = value
		_sync_material_controls()

var requested_count: int = 0
var forced_safety_settle_count: int = 0
var first_resolve_count: int = 0
var reacquisition_count: int = 0
var settled_count: int = 0
var overflow_count: int = 0
var unveiled_commit_count: int = 0
var identity_mismatch_count: int = 0
var identity_write_count: int = 0
var echo_write_count: int = 0
var echo_identity_hash: int = 0
var echo_class_counts: Array[int] = [0, 0, 0, 0, 0]
var ingress_begin_count: int = 0
var ingress_veiled_count: int = 0
var first_resolve_settle_count: int = 0
var first_resolve_age_sum: float = 0.0
var first_resolve_age_max: float = 0.0
var reacquisition_settle_count: int = 0
var reacquisition_age_sum: float = 0.0
var reacquisition_age_max: float = 0.0

## tile -> semantic class (int); read-only query supplied by the owner of the
## semantics. Null/invalid means every cell is natural.
var class_resolver: Callable = Callable()
## tile -> bool; true when the tile is an opaque canonical blocker (walls).
## Read-only presentation input supplied by the tilemap façade.
var occluder: Callable = Callable()
## () -> Rect2i of the active camera's tile rect, or an empty Rect2i.
var camera_rect_provider: Callable = Callable()
var frontier_start_tokens: float = 0.0
var frontier_started_count: int = 0
var frontier_burst_max: int = 0
var frontier_halo_blocked_count: int = 0

var _frontier: ProcGenVisualFrontier = ProcGenVisualFrontier.new()
var _scan_cursor: int = 0

var _ingress_active: bool = false
var _ingress_center: Vector2i = Vector2i.ZERO
var _ingress_t0: float = 0.0
var _ingress_chunk_size: int = 16
var _ingress_start: Dictionary = {}
var _ingress_queue: Array[Vector2i] = []
var _reacq_tiles: Dictionary = {}
var _echo_lead: Dictionary = {}
var _presentation_time: float = 0.0
var _tile_to_global: Callable = Callable()
var _tile_size: Vector2 = Vector2(32, 32)
var _states: Dictionary = {}
var _slot_of: Dictionary = {}
var _resolve_start: Dictionary = {}
var _free_slots: Array[int] = []
var _ready_queue: Array[Vector2i] = []
var _resolving_queue: Array[Vector2i] = []
var _ever_resolved_chunks: Dictionary = {}
var _multimesh_ready: bool = false
var _hidden_xform: Transform2D = Transform2D(0.0, Vector2.ZERO).scaled(Vector2.ZERO)
var _veil_material: ShaderMaterial = null


## `tile_to_global` maps a tile to its world-space cell centre. `tile_size` is
## the semantic cell footprint in world px.
func configure(tile_to_global: Callable, tile_size: Vector2 = Vector2(32, 32)) -> void:
	_tile_to_global = tile_to_global
	_tile_size = tile_size
	_build_multimesh()


func reset() -> void:
	_states.clear()
	_slot_of.clear()
	_resolve_start.clear()
	_ready_queue.clear()
	_resolving_queue.clear()
	_ever_resolved_chunks.clear()
	_presentation_time = 0.0
	_sync_material_time()
	requested_count = 0
	forced_safety_settle_count = 0
	first_resolve_count = 0
	reacquisition_count = 0
	settled_count = 0
	overflow_count = 0
	unveiled_commit_count = 0
	identity_mismatch_count = 0
	identity_write_count = 0
	echo_write_count = 0
	echo_identity_hash = 0
	echo_class_counts = [0, 0, 0, 0, 0]
	ingress_begin_count = 0
	ingress_veiled_count = 0
	first_resolve_settle_count = 0
	first_resolve_age_sum = 0.0
	first_resolve_age_max = 0.0
	reacquisition_settle_count = 0
	reacquisition_age_sum = 0.0
	reacquisition_age_max = 0.0
	_ingress_active = false
	_ingress_start.clear()
	_ingress_queue.clear()
	_reacq_tiles.clear()
	_echo_lead.clear()
	frontier_start_tokens = 0.0
	frontier_started_count = 0
	frontier_burst_max = 0
	frontier_halo_blocked_count = 0
	_scan_cursor = 0
	_frontier.reset()
	_frontier.set_occluder(occluder)
	_reset_slot_pool()


func set_effect_enabled(enabled: bool) -> void:
	effect_enabled = enabled


func set_presentation_class_resolver(resolver: Callable) -> void:
	class_resolver = resolver


func set_frontier_inputs(opaque_tile: Callable, camera_tile_rect: Callable) -> void:
	occluder = opaque_tile
	camera_rect_provider = camera_tile_rect
	_frontier.set_occluder(opaque_tile)


func get_frontier() -> ProcGenVisualFrontier:
	return _frontier


## REQUEST observation: called before any authoritative commit of these tiles.
## `reacquisition` is the lifecycle-derived identity (pre-request state was
## UNLOADED); the owner's own ever-resolved chunk set is only a consistency
## check and never overrides it.
func note_tiles_requested(chunk_pos: Vector2i, tiles: Array[Vector2i], reacquisition: bool) -> void:
	if _ever_resolved_chunks.has(chunk_pos) != reacquisition:
		identity_mismatch_count += 1
	for tile in tiles:
		requested_count += 1
		if reacquisition:
			reacquisition_count += 1
		else:
			first_resolve_count += 1
		if not effect_enabled or _states.has(tile):
			continue
		if _free_slots.is_empty():
			overflow_count += 1
			continue
		var slot: int = _free_slots.pop_back()
		_slot_of[tile] = slot
		_states[tile] = TileState.REQUESTED
		if reacquisition:
			_reacq_tiles[tile] = true
		_write_slot(slot, tile, 1.0)
		_write_slot_identity(slot, tile, reacquisition)


## COMMIT observation: only a committed tile may become eligible to resolve.
func note_tile_committed(tile: Vector2i) -> void:
	if int(_states.get(tile, 0)) == TileState.REQUESTED:
		if _ingress_active and not _reacq_tiles.has(tile):
			if _in_ingress_pocket(tile):
				_settle_tile(tile, _ingress_chunk_size)
				return
			if _in_ingress_ring(tile):
				_enqueue_ingress(tile, ingress_start_time(tile))
				return
		_states[tile] = TileState.READY
		_ready_queue.append(tile)
		return
	if not _states.has(tile):
		# No veil record (effect disabled or slot overflow): visible as-is.
		if effect_enabled:
			unveiled_commit_count += 1
		settled_count += 1


## UNLOAD observation (after the tilemap's own disposal): drops active veil
## slots for the chunk and keeps only the session reacquisition memory.
func note_chunk_unloaded(chunk_pos: Vector2i, chunk_size_tiles: int) -> void:
	_ever_resolved_chunks[chunk_pos] = true
	var removed := false
	var start_x := chunk_pos.x * chunk_size_tiles
	var start_y := chunk_pos.y * chunk_size_tiles
	for x in range(start_x, start_x + chunk_size_tiles):
		for y in range(start_y, start_y + chunk_size_tiles):
			var tile := Vector2i(x, y)
			if _states.has(tile):
				_release_tile(tile)
				removed = true
	if removed:
		_filter_queues_to_live_tiles()


## Advances the presentation clock and settlement. Called only from ordinary
## unpaused procgen processing; `chunk_size_tiles` maps tiles to chunks for
## the ever-resolved consistency memory.
func advance(delta: float, operator_tile: Vector2i, chunk_size_tiles: int) -> void:
	if not effect_enabled:
		return
	_presentation_time += maxf(0.0, delta)
	_sync_material_time()
	var gated := frontier_enabled and operator_tile != NO_OPERATOR_TILE
	if gated:
		_frontier.radius_tiles = visual_resolve_radius_tiles
		_frontier.fringe_tiles = visual_resolve_fringe_tiles
		_frontier.camera_margin_tiles = camera_margin_tiles
		var cam := Rect2i()
		if camera_rect_provider.is_valid():
			cam = camera_rect_provider.call() as Rect2i
			if cam.has_area():
				cam = cam.grow(camera_margin_tiles)
		_frontier.update(operator_tile, cam, _presentation_time)
	else:
		_frontier.update(NO_OPERATOR_TILE, Rect2i(), _presentation_time)
	_apply_safety_halo(operator_tile, chunk_size_tiles)
	if _ingress_active:
		_advance_ingress(gated)
	if gated:
		_start_ready_tiles_paced(delta)
	else:
		var starts := mini(resolve_starts_per_frame, _ready_queue.size())
		for i in range(starts):
			_begin_resolving(_ready_queue[i], _presentation_time)
		if starts > 0:
			_ready_queue = _ready_queue.slice(starts)
	var settled: Array[Vector2i] = []
	var still_resolving: Array[Vector2i] = []
	for tile in _resolving_queue:
		var age: float = _presentation_time - float(_resolve_start[tile])
		var lead: float = float(_echo_lead.get(tile, 0.0))
		var duration := _duration_for(tile)
		if age - lead >= duration:
			settled.append(tile)
			continue
		still_resolving.append(tile)
		if age < lead:
			continue
		_write_slot(int(_slot_of[tile]), tile, 1.0 - (age - lead) / maxf(duration, 0.0001))
	for tile in settled:
		_record_settle_age(tile, _presentation_time - float(_resolve_start[tile]))
		_settle_tile(tile, chunk_size_tiles)
	_resolving_queue = still_resolving


## AR4 ordinary start: token-bucket pacing in presentation time (frame-rate
## invariant), bounded burst, and a bounded rotating scan. Ineligible READY
## tiles stay veiled and consume no start budget.
func _start_ready_tiles_paced(delta: float) -> void:
	frontier_start_tokens = minf(
		frontier_start_tokens + maxf(0.0, delta) * resolve_starts_per_sec,
		float(resolve_burst_cap) + 1.0
	)
	var budget := mini(int(frontier_start_tokens), resolve_burst_cap)
	var count := _ready_queue.size()
	if count == 0:
		_scan_cursor = 0
		return
	if budget <= 0:
		return
	var scanned := mini(count, eligibility_scan_per_frame)
	var started: Dictionary = {}
	var idx := _scan_cursor % count
	for _i in range(scanned):
		if started.size() >= budget:
			break
		var tile := _ready_queue[idx]
		if _frontier.check(tile):
			started[tile] = true
			_begin_resolving(tile, _presentation_time)
		idx = (idx + 1) % count
	_scan_cursor = idx
	if started.is_empty():
		return
	frontier_start_tokens -= float(started.size())
	frontier_started_count += started.size()
	frontier_burst_max = maxi(frontier_burst_max, started.size())
	_ready_queue = _ready_queue.filter(func(t: Vector2i) -> bool: return not started.has(t))
	_scan_cursor = 0 if _ready_queue.is_empty() else mini(_scan_cursor, _ready_queue.size() - 1)


## One-time ingress resolve. Re-veils already-committed cells in the ring
## outside the always-settled pocket and releases them outward; cells in the
## ring that are only requested stay veiled and join the wave when they commit.
## `committed_tiles` is the caller's authoritative list of painted cells; it is
## never used to reveal anything. Returns the number of cells the wave owns.
func begin_ingress_resolve(center_tile: Vector2i, committed_tiles: Array[Vector2i], chunk_size_tiles: int = 16) -> int:
	if not effect_enabled or not _multimesh_ready:
		return 0
	_ingress_active = true
	_ingress_center = center_tile
	_ingress_t0 = _presentation_time
	_ingress_chunk_size = chunk_size_tiles
	ingress_begin_count += 1
	var owned := 0
	# The committed safety pocket is visible immediately: settle anything already
	# committed there. Requested-but-uncommitted pocket cover is never touched.
	var pocket := _pocket_radius()
	var settled_in_pocket := false
	for x in range(center_tile.x - pocket, center_tile.x + pocket + 1):
		for y in range(center_tile.y - pocket, center_tile.y + pocket + 1):
			var pocket_tile := Vector2i(x, y)
			var state := int(_states.get(pocket_tile, 0))
			if state == TileState.READY or state == TileState.RESOLVING or state == TileState.INGRESS:
				_settle_tile(pocket_tile, chunk_size_tiles)
				settled_in_pocket = true
	if settled_in_pocket:
		_filter_queues_to_live_tiles()
	# READY cells inside the ring leave the ordinary queue and join the wave.
	for tile in _ready_queue.duplicate():
		if _in_ingress_ring(tile):
			_ready_queue.erase(tile)
			_enqueue_ingress(tile, ingress_start_time(tile))
			owned += 1
	var fresh: Array[Vector2i] = []
	for tile in committed_tiles:
		if not _in_ingress_ring(tile) or _states.has(tile):
			continue
		fresh.append(tile)
	fresh.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var sa := ingress_start_time(a)
		var sb := ingress_start_time(b)
		if not is_equal_approx(sa, sb):
			return sa < sb
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	for tile in fresh:
		if _free_slots.is_empty():
			overflow_count += 1
			continue
		var slot: int = _free_slots.pop_back()
		_slot_of[tile] = slot
		_write_slot(slot, tile, 1.0)
		_write_slot_identity(slot, tile, false)
		_enqueue_ingress(tile, ingress_start_time(tile))
		ingress_veiled_count += 1
		owned += 1
	return owned


## Absolute presentation-clock time at which a ring cell starts resolving:
## outward by Euclidean distance with a tiny deterministic per-cell jitter.
func ingress_start_time(tile: Vector2i) -> float:
	var pocket := float(_pocket_radius())
	var span := maxf(1.0, float(ingress_radius_tiles) * 1.4142 - pocket)
	var dist := Vector2(tile - _ingress_center).length()
	var t := clampf((dist - pocket) / span, 0.0, 1.0)
	var jitter := (cell_identity_hash(tile) - 0.5) * 0.08
	return _ingress_t0 + maxf(0.0, t * ingress_wave_sec + jitter)


func _pocket_radius() -> int:
	return maxi(ingress_pocket_tiles, safety_halo_tiles)


func _in_ingress_pocket(tile: Vector2i) -> bool:
	return maxi(absi(tile.x - _ingress_center.x), absi(tile.y - _ingress_center.y)) <= _pocket_radius()


func _in_ingress_ring(tile: Vector2i) -> bool:
	var d := maxi(absi(tile.x - _ingress_center.x), absi(tile.y - _ingress_center.y))
	return d > _pocket_radius() and d <= ingress_radius_tiles


func _enqueue_ingress(tile: Vector2i, start_time: float) -> void:
	_states[tile] = TileState.INGRESS
	_ingress_start[tile] = start_time
	_ingress_queue.append(tile)


func _advance_ingress(gated: bool = false) -> void:
	if _ingress_queue.is_empty():
		if _presentation_time > _ingress_t0 + ingress_wave_sec + 0.1:
			_ingress_active = false
		return
	var waiting: Array[Vector2i] = []
	for tile in _ingress_queue:
		if not _states.has(tile) or int(_states[tile]) != TileState.INGRESS:
			continue
		var start := float(_ingress_start[tile])
		if start <= _presentation_time and (not gated or _frontier.check(tile)):
			_ingress_start.erase(tile)
			_begin_resolving(tile, start)
		else:
			waiting.append(tile)
	_ingress_queue = waiting


## READY/INGRESS -> RESOLVING. First-resolve cells with a non-natural class get
## a one-shot evidence-echo write and a short lead during which the veil stays
## fully opaque; reacquisition cells never echo. `base_start` is the schedule
## time (frame-rate independent for ingress).
func _begin_resolving(tile: Vector2i, base_start: float) -> void:
	_states[tile] = TileState.RESOLVING
	_resolve_start[tile] = base_start
	_resolving_queue.append(tile)
	if reduced_effects or _reacq_tiles.has(tile) or not class_resolver.is_valid():
		return
	var kind := int(class_resolver.call(tile))
	var lead := ProcGenPresentationClass.echo_lead_sec(kind)
	if lead <= 0.0:
		return
	_echo_lead[tile] = lead
	echo_write_count += 1
	echo_class_counts[clampi(kind, 0, ProcGenPresentationClass.KIND_COUNT - 1)] += 1
	echo_identity_hash = (echo_identity_hash * 31 + tile.x * 73856093 + tile.y * 19349663 + kind) & 0x7FFFFFFF
	multimesh.set_instance_custom_data(
		int(_slot_of[tile]),
		Color(cell_identity_hash(tile), 0.0, ProcGenPresentationClass.encode(kind), 1.0)
	)


func _duration_for(tile: Vector2i) -> float:
	return reacquisition_duration_sec if _reacq_tiles.has(tile) else resolve_duration_sec


func _record_settle_age(tile: Vector2i, age: float) -> void:
	if _reacq_tiles.has(tile):
		reacquisition_settle_count += 1
		reacquisition_age_sum += age
		reacquisition_age_max = maxf(reacquisition_age_max, age)
	else:
		first_resolve_settle_count += 1
		first_resolve_age_sum += age
		first_resolve_age_max = maxf(first_resolve_age_max, age)


func _filter_queues_to_live_tiles() -> void:
	_ready_queue = _ready_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))
	_resolving_queue = _resolving_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))
	_ingress_queue = _ingress_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))


func get_snapshot() -> Dictionary:
	var uncommitted := 0
	var ready := 0
	var resolving := 0
	var ingress := 0
	for state in _states.values():
		match int(state):
			TileState.REQUESTED:
				uncommitted += 1
			TileState.READY:
				ready += 1
			TileState.RESOLVING:
				resolving += 1
			TileState.INGRESS:
				ingress += 1
	return {
		"effect_enabled": effect_enabled,
		"requested_uncommitted_count": uncommitted,
		"committed_ready_count": ready,
		"resolving_count": resolving,
		"ingress_pending_count": ingress,
		"ingress_active": _ingress_active,
		"ingress_begin_count": ingress_begin_count,
		"ingress_veiled_count": ingress_veiled_count,
		"frontier": _frontier.get_snapshot(),
		"frontier_started_count": frontier_started_count,
		"frontier_burst_max": frontier_burst_max,
		"frontier_start_tokens": frontier_start_tokens,
		"frontier_halo_blocked_count": frontier_halo_blocked_count,
		"echo_write_count": echo_write_count,
		"echo_identity_hash": echo_identity_hash,
		"echo_class_counts": echo_class_counts.duplicate(),
		"first_resolve_settle_count": first_resolve_settle_count,
		"first_resolve_age_avg": first_resolve_age_sum / maxf(1.0, float(first_resolve_settle_count)),
		"first_resolve_age_max": first_resolve_age_max,
		"reacquisition_settle_count": reacquisition_settle_count,
		"reacquisition_age_avg": reacquisition_age_sum / maxf(1.0, float(reacquisition_settle_count)),
		"reacquisition_age_max": reacquisition_age_max,
		"settled_count": settled_count,
		"forced_safety_settle_count": forced_safety_settle_count,
		"first_resolve_count": first_resolve_count,
		"reacquisition_count": reacquisition_count,
		"requested_total_count": requested_count,
		"presentation_time": _presentation_time,
		"active_instance_count": _slot_of.size(),
		"slot_capacity": slot_capacity,
		"overflow_count": overflow_count,
		"unveiled_commit_count": unveiled_commit_count,
		"identity_mismatch_count": identity_mismatch_count,
		"identity_write_count": identity_write_count,
		"shared_material_count": 1 if _veil_material != null else 0,
		"shader_enabled": _veil_material != null and _veil_material.shader == ARCHIVE_RESOLVE_SHADER,
		"reduced_effects": reduced_effects,
		"custom_data_enabled": _multimesh_ready and multimesh.use_custom_data,
	}


## The one shared veil material (null before `configure`). Exposed so validation
## can assert material identity and uniform sync without scene sampling.
func get_veil_material() -> ShaderMaterial:
	return _veil_material


## Deterministic render identity for a world cell in [0, 1]; the value the
## shader receives as `INSTANCE_CUSTOM.r`. Pure function of the tile.
static func cell_identity_hash(tile: Vector2i) -> float:
	var h: int = (tile.x * 73856093) ^ (tile.y * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


func get_tile_state(tile: Vector2i) -> int:
	return int(_states.get(tile, 0))


func has_veil(tile: Vector2i) -> bool:
	return _slot_of.has(tile)


## Deterministic trace of tiles in the order they began resolving is the
## ready-queue/resolving-queue concatenation; exposed for the AR1 smoke.
func get_frontier_order() -> Array[Vector2i]:
	var order: Array[Vector2i] = []
	order.append_array(_resolving_queue)
	order.append_array(_ready_queue)
	return order


func _apply_safety_halo(operator_tile: Vector2i, chunk_size_tiles: int) -> void:
	if operator_tile == NO_OPERATOR_TILE or safety_halo_tiles <= 0:
		return
	var forced := false
	for x in range(operator_tile.x - safety_halo_tiles, operator_tile.x + safety_halo_tiles + 1):
		for y in range(operator_tile.y - safety_halo_tiles, operator_tile.y + safety_halo_tiles + 1):
			var tile := Vector2i(x, y)
			var state := int(_states.get(tile, 0))
			if state != TileState.READY and state != TileState.RESOLVING and state != TileState.INGRESS:
				continue
			# AR4: the pocket never punches through an opaque barrier.
			if frontier_enabled and _frontier.has_center() and not _frontier.is_visible_from_center(tile):
				frontier_halo_blocked_count += 1
				continue
			_settle_tile(tile, chunk_size_tiles)
			forced_safety_settle_count += 1
			forced = true
	if forced:
		_filter_queues_to_live_tiles()


func _settle_tile(tile: Vector2i, chunk_size_tiles: int) -> void:
	if not _states.has(tile):
		return
	_release_tile(tile)
	settled_count += 1
	var chunk := Vector2i(
		int(floor(float(tile.x) / float(maxi(1, chunk_size_tiles)))),
		int(floor(float(tile.y) / float(maxi(1, chunk_size_tiles))))
	)
	_ever_resolved_chunks[chunk] = true


func _settle_all_immediately() -> void:
	for tile in _states.keys():
		if int(_states[tile]) != TileState.REQUESTED:
			settled_count += 1
		_release_tile(tile)
	_ready_queue.clear()
	_resolving_queue.clear()
	_ingress_queue.clear()
	_ingress_start.clear()
	_reacq_tiles.clear()
	_echo_lead.clear()
	_ingress_active = false


func _release_tile(tile: Vector2i) -> void:
	var slot := int(_slot_of.get(tile, -1))
	if slot >= 0:
		_hide_slot(slot)
		_free_slots.append(slot)
	_slot_of.erase(tile)
	_states.erase(tile)
	_resolve_start.erase(tile)
	_ingress_start.erase(tile)
	_reacq_tiles.erase(tile)
	_echo_lead.erase(tile)


func _build_multimesh() -> void:
	var quad := QuadMesh.new()
	quad.size = _tile_size + Vector2(VEIL_OVERLAP_PX, VEIL_OVERLAP_PX) * 2.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = slot_capacity
	multimesh = mm
	_ensure_veil_material()
	_multimesh_ready = true
	_reset_slot_pool()


func _reset_slot_pool() -> void:
	_free_slots.clear()
	_free_slots.resize(slot_capacity)
	for i in range(slot_capacity):
		_free_slots[i] = slot_capacity - 1 - i
	if not _multimesh_ready:
		return
	for i in range(slot_capacity):
		_hide_slot(i)


func _hide_slot(slot: int) -> void:
	if not _multimesh_ready:
		return
	multimesh.set_instance_transform_2d(slot, _hidden_xform)
	multimesh.set_instance_color(slot, Color(0, 0, 0, 0))
	multimesh.set_instance_custom_data(slot, Color(0, 0, 0, 0))


func _write_slot(slot: int, tile: Vector2i, alpha: float) -> void:
	if not _multimesh_ready:
		return
	var local := to_local(_tile_to_global.call(tile) as Vector2)
	multimesh.set_instance_transform_2d(slot, Transform2D(0.0, local))
	var color := veil_color
	color.a = clampf(alpha, 0.0, 1.0)
	multimesh.set_instance_color(slot, color)


## One-shot per-slot render identity, written only on slot assignment (never
## rescanned per frame). r = deterministic cell hash, g = reacquisition flag
## (AR3 shader scales registration/misregistration by it), b = semantic class
## and a = evidence-echo strength, both written only when a committed
## first-resolve cell starts resolving (never for uncommitted cover).
func _write_slot_identity(slot: int, tile: Vector2i, reacquisition: bool) -> void:
	if not _multimesh_ready:
		return
	identity_write_count += 1
	multimesh.set_instance_custom_data(slot, Color(cell_identity_hash(tile), 1.0 if reacquisition else 0.0, 0.0, 0.0))


func _ensure_veil_material() -> void:
	if _veil_material == null:
		_veil_material = ShaderMaterial.new()
		_veil_material.shader = ARCHIVE_RESOLVE_SHADER
	material = _veil_material
	_sync_material_controls()
	_sync_material_time()


func _sync_material_controls() -> void:
	if _veil_material == null:
		return
	var registration := registration_intensity * (REDUCED_REGISTRATION_SCALE if reduced_effects else 1.0)
	var misregistration := 0.0 if reduced_effects else phase_misregistration_intensity
	_veil_material.set_shader_parameter("registration_intensity", registration)
	_veil_material.set_shader_parameter("unresolved_haze_intensity", unresolved_haze_intensity)
	_veil_material.set_shader_parameter("phase_misregistration_intensity", misregistration)
	_veil_material.set_shader_parameter("semantic_echo_intensity", 0.0 if reduced_effects else semantic_echo_intensity)


## Pause-safe: called only from reset() and the unpaused advance() clock. The
## shader must never read global TIME for pause-sensitive motion.
func _sync_material_time() -> void:
	if _veil_material != null:
		_veil_material.set_shader_parameter("presentation_time", _presentation_time)
