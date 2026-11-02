class_name ProcGenChunkResidencyPolicy
extends RefCounted

## M6 production distant-chunk eviction candidate selection (owns only a
## coordinate queue + counters). `ProcGenChunkLifecycle` (M4) remains the only
## owner of DORMANT/UNLOADED state and `ProcGenChunkPayloadCache` (M5) remains
## the only owner of cached payload; this class decides nothing beyond which
## currently-DORMANT, unprotected, far-enough chunk coordinates are eligible
## to unload next, in which order. It never touches TileMap/Node/collision/
## foliage state and never calls into the lifecycle or cache directly --
## `ProcGenTilemap` supplies the already-filtered DORMANT chunk list and
## protected set, and revalidates each taken candidate's state/distance/
## protection immediately before actually unloading it.

var refresh_count: int = 0
var selected_total: int = 0
var evicted_count: int = 0
var cancelled_count: int = 0
var protected_rejected_count: int = 0

var _queue: Array[Vector2i] = []
var _queued_set: Dictionary = {}


func reset() -> void:
	_queue.clear()
	_queued_set.clear()
	refresh_count = 0
	selected_total = 0
	evicted_count = 0
	cancelled_count = 0
	protected_rejected_count = 0


## Replace the candidate queue with the current deterministic eligible set.
## `dormant_chunks` must already be filtered to DORMANT lifecycle state only
## -- this class has no lifecycle authority of its own. A chunk is eligible
## when its Chebyshev distance from `center_chunk` is strictly greater than
## `unload_distance` and it is not a key in `protected_chunks`. Eligible
## chunks are ordered farthest-first, then coordinate-stable (x then y) for
## ties, so the drain order is deterministic across identical world state.
## Any previously queued chunk that is no longer eligible (player returned,
## it left DORMANT, or it became protected) is counted as cancelled.
func refresh_candidates(
	center_chunk: Vector2i,
	dormant_chunks: Array[Vector2i],
	protected_chunks: Dictionary,
	unload_distance: int
) -> void:
	refresh_count += 1
	var previous_set := _queued_set
	var eligible: Array[Vector2i] = []
	var new_set: Dictionary = {}
	for chunk_pos in dormant_chunks:
		if protected_chunks.has(chunk_pos):
			protected_rejected_count += 1
			continue
		var distance := maxi(absi(chunk_pos.x - center_chunk.x), absi(chunk_pos.y - center_chunk.y))
		if distance <= unload_distance:
			continue
		eligible.append(chunk_pos)
		new_set[chunk_pos] = true
	eligible.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := maxi(absi(a.x - center_chunk.x), absi(a.y - center_chunk.y))
		var db := maxi(absi(b.x - center_chunk.x), absi(b.y - center_chunk.y))
		if da != db:
			return da > db
		if a.x != b.x:
			return a.x < b.x
		return a.y < b.y
	)
	for chunk_pos in previous_set.keys():
		if not new_set.has(chunk_pos):
			cancelled_count += 1
	_queue = eligible
	_queued_set = new_set
	selected_total += _queue.size()


## Pop up to `max_count` candidates off the front (farthest-first) of the
## queue. The caller owns revalidating state/distance/protection immediately
## before unloading each one and must report the outcome via
## `note_evicted()`/`note_cancelled()`.
func take_candidates(max_count: int) -> Array[Vector2i]:
	var taken: Array[Vector2i] = []
	var remaining := maxi(0, max_count)
	while taken.size() < remaining and not _queue.is_empty():
		var chunk_pos: Vector2i = _queue.pop_front()
		_queued_set.erase(chunk_pos)
		taken.append(chunk_pos)
	return taken


## Caller reports a taken candidate that was actually unloaded.
func note_evicted(count: int = 1) -> void:
	evicted_count += maxi(0, count)


## Caller reports a taken candidate that failed revalidation immediately
## before unload (e.g. the player re-entered its hysteresis radius, it is no
## longer DORMANT, or it became protected between refresh and drain) and was
## therefore not unloaded this frame.
func note_cancelled(count: int = 1) -> void:
	cancelled_count += maxi(0, count)


func get_snapshot() -> Dictionary:
	return {
		"pending_count": _queue.size(),
		"refresh_count": refresh_count,
		"selected_total": selected_total,
		"evicted_count": evicted_count,
		"cancelled_count": cancelled_count,
		"protected_rejected_count": protected_rejected_count,
	}
