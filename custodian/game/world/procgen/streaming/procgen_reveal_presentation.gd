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
## Flat diagnostic look only; graphite/dither/brass treatment belongs to AR2.

enum TileState { REQUESTED = 1, READY = 2, RESOLVING = 3 }

const NO_OPERATOR_TILE := Vector2i(999999, 999999)

## Veil quad overhang beyond the 32 px semantic cell, per side, in px.
const VEIL_OVERLAP_PX := 1.0

@export var effect_enabled: bool = true
@export_range(64, 65536, 1) var slot_capacity: int = 8192
## Ordinary settlement work bound: READY tiles that may begin resolving/frame.
@export_range(1, 4096, 1) var resolve_starts_per_frame: int = 48
@export_range(0.0, 2.0, 0.01) var resolve_duration_sec: float = 0.18
## Chebyshev tile radius around the Operator inside which already-committed
## cells are force-settled. Never reveals an uncommitted cell.
@export_range(0, 16, 1) var safety_halo_tiles: int = 3
@export var veil_color: Color = Color(0.07, 0.075, 0.085, 1.0)

var requested_count: int = 0
var forced_safety_settle_count: int = 0
var first_resolve_count: int = 0
var reacquisition_count: int = 0
var settled_count: int = 0
var overflow_count: int = 0
var unveiled_commit_count: int = 0
var identity_mismatch_count: int = 0

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
	requested_count = 0
	forced_safety_settle_count = 0
	first_resolve_count = 0
	reacquisition_count = 0
	settled_count = 0
	overflow_count = 0
	unveiled_commit_count = 0
	identity_mismatch_count = 0
	_reset_slot_pool()


func set_effect_enabled(enabled: bool) -> void:
	if effect_enabled == enabled:
		return
	effect_enabled = enabled
	if not enabled:
		_settle_all_immediately()


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
		_write_slot(slot, tile, 1.0)


## COMMIT observation: only a committed tile may become eligible to resolve.
func note_tile_committed(tile: Vector2i) -> void:
	if int(_states.get(tile, 0)) == TileState.REQUESTED:
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
		_ready_queue = _ready_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))
		_resolving_queue = _resolving_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))


## Advances the presentation clock and settlement. Called only from ordinary
## unpaused procgen processing; `chunk_size_tiles` maps tiles to chunks for
## the ever-resolved consistency memory.
func advance(delta: float, operator_tile: Vector2i, chunk_size_tiles: int) -> void:
	if not effect_enabled:
		return
	_presentation_time += maxf(0.0, delta)
	_apply_safety_halo(operator_tile, chunk_size_tiles)
	var starts := mini(resolve_starts_per_frame, _ready_queue.size())
	for i in range(starts):
		var tile: Vector2i = _ready_queue[i]
		_states[tile] = TileState.RESOLVING
		_resolve_start[tile] = _presentation_time
		_resolving_queue.append(tile)
	if starts > 0:
		_ready_queue = _ready_queue.slice(starts)
	var settle_count := 0
	for tile in _resolving_queue:
		var age: float = _presentation_time - float(_resolve_start[tile])
		if age >= resolve_duration_sec:
			settle_count += 1
			continue
		_write_slot(int(_slot_of[tile]), tile, 1.0 - age / maxf(resolve_duration_sec, 0.0001))
	for i in range(settle_count):
		_settle_tile(_resolving_queue[i], chunk_size_tiles)
	if settle_count > 0:
		_resolving_queue = _resolving_queue.slice(settle_count)


func get_snapshot() -> Dictionary:
	var uncommitted := 0
	var ready := 0
	var resolving := 0
	for state in _states.values():
		match int(state):
			TileState.REQUESTED:
				uncommitted += 1
			TileState.READY:
				ready += 1
			TileState.RESOLVING:
				resolving += 1
	return {
		"effect_enabled": effect_enabled,
		"requested_uncommitted_count": uncommitted,
		"committed_ready_count": ready,
		"resolving_count": resolving,
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
	}


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
			if state != TileState.READY and state != TileState.RESOLVING:
				continue
			_settle_tile(tile, chunk_size_tiles)
			forced_safety_settle_count += 1
			forced = true
	if forced:
		_ready_queue = _ready_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))
		_resolving_queue = _resolving_queue.filter(func(t: Vector2i) -> bool: return _states.has(t))


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


func _release_tile(tile: Vector2i) -> void:
	var slot := int(_slot_of.get(tile, -1))
	if slot >= 0:
		_hide_slot(slot)
		_free_slots.append(slot)
	_slot_of.erase(tile)
	_states.erase(tile)
	_resolve_start.erase(tile)


func _build_multimesh() -> void:
	var quad := QuadMesh.new()
	quad.size = _tile_size + Vector2(VEIL_OVERLAP_PX, VEIL_OVERLAP_PX) * 2.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = slot_capacity
	multimesh = mm
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


func _write_slot(slot: int, tile: Vector2i, alpha: float) -> void:
	if not _multimesh_ready:
		return
	var local := to_local(_tile_to_global.call(tile) as Vector2)
	multimesh.set_instance_transform_2d(slot, Transform2D(0.0, local))
	var color := veil_color
	color.a = clampf(alpha, 0.0, 1.0)
	multimesh.set_instance_color(slot, color)
