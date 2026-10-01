class_name ProcGenChunkLifecycle
extends RefCounted

## Single owner of deterministic per-chunk streaming lifecycle state (M4).
## Replaces the old `_revealed_chunks`/`_queued_chunks` dictionaries, which
## were not truthful: they marked a chunk "revealed" the moment its tiles
## were enumerated for queueing, not when any tile actually committed.
##
## This authority owns only chunk-level request/progress/interest
## bookkeeping and telemetry. It never touches TileMap/Node state, floor/wall
## semantic authority, collision, navigation, or candidate evaluation --
## `ProcGenTilemap` keeps owning those, and `ProcGenPauseAwareStreaming` (M3)
## remains the only owner of the tile work queue and its PREPARE/COMMIT
## phases. Callers report tile-level progress here through narrow
## `request`/`note_prepared`/`note_committed` calls; this class derives chunk
## state from that, it never infers it independently.

enum State {
	UNSEEN,
	QUEUED,
	PREPARED,
	REVEALING,
	VISIBLE,
	DORMANT,
	UNLOADED,
}

const STATE_NAMES := {
	State.UNSEEN: "UNSEEN",
	State.QUEUED: "QUEUED",
	State.PREPARED: "PREPARED",
	State.REVEALING: "REVEALING",
	State.VISIBLE: "VISIBLE",
	State.DORMANT: "DORMANT",
	State.UNLOADED: "UNLOADED",
}


class ChunkRecord:
	var state: int = ProcGenChunkLifecycle.State.UNSEEN
	var planned_tile_count: int = 0
	var prepared_tile_count: int = 0
	var committed_tile_count: int = 0


var _records: Dictionary = {}
var _transition_count: int = 0
var _illegal_transition_count: int = 0


func reset() -> void:
	_records.clear()
	_transition_count = 0
	_illegal_transition_count = 0


## True once a chunk has been requested and is still tracked as pending or
## resident (QUEUED/PREPARED/REVEALING/VISIBLE/DORMANT). UNLOADED does not
## count: the mechanism of re-requesting an unloaded chunk is not itself the
## M6-owned reload *policy* (when/whether to evict and reload), so it must
## keep working in M4. Callers use this as the single dedup guard before
## enumerating/queueing a chunk, replacing the old
## `_revealed_chunks.has(..) or _queued_chunks.has(..)` combined check.
func is_requested(chunk_pos: Vector2i) -> bool:
	var record: ChunkRecord = _records.get(chunk_pos)
	return record != null and record.state != State.UNLOADED


func get_state(chunk_pos: Vector2i) -> int:
	var record: ChunkRecord = _records.get(chunk_pos)
	return record.state if record != null else State.UNSEEN


## UNSEEN -> QUEUED for a chunk with planned work, or UNSEEN -> VISIBLE
## immediately for a zero-content chunk so it never churns/requeues.
## Idempotent against any already-pending/resident chunk. An UNLOADED chunk
## starts a fresh record (UNLOADED -> QUEUED/VISIBLE) rather than being
## treated as already requested -- see `is_requested()`.
func request(chunk_pos: Vector2i, planned_tile_count: int) -> void:
	if is_requested(chunk_pos):
		return
	var record := ChunkRecord.new()
	record.planned_tile_count = maxi(0, planned_tile_count)
	_records[chunk_pos] = record
	if record.planned_tile_count <= 0:
		_transition(record, State.VISIBLE)
	else:
		_transition(record, State.QUEUED)


## QUEUED -> PREPARED once every planned tile is prepared and none have
## committed yet. Reports progress only; never mutates world state.
func note_prepared(chunk_pos: Vector2i) -> void:
	var record: ChunkRecord = _records.get(chunk_pos)
	if record == null:
		_illegal_transition_count += 1
		push_error("ProcGenChunkLifecycle: note_prepared on unrequested chunk %s" % chunk_pos)
		return
	record.prepared_tile_count += 1
	if record.state == State.QUEUED \
			and record.committed_tile_count == 0 \
			and record.prepared_tile_count >= record.planned_tile_count:
		_transition(record, State.PREPARED)


## QUEUED/PREPARED -> REVEALING on the first authoritative tile commit, then
## -> VISIBLE once every planned tile has committed.
func note_committed(chunk_pos: Vector2i) -> void:
	var record: ChunkRecord = _records.get(chunk_pos)
	if record == null:
		_illegal_transition_count += 1
		push_error("ProcGenChunkLifecycle: note_committed on unrequested chunk %s" % chunk_pos)
		return
	record.committed_tile_count += 1
	if record.state == State.QUEUED or record.state == State.PREPARED:
		_transition(record, State.REVEALING)
	if record.committed_tile_count >= record.planned_tile_count:
		_transition(record, State.VISIBLE)


## VISIBLE -> DORMANT for resident chunks that fall outside the active
## interest window, and DORMANT -> VISIBLE for ones that re-enter it.
## Presentation is never touched; M4 keeps resident chunks painted.
## QUEUED/PREPARED/REVEALING chunks are left alone -- in-flight work is
## allowed to finish rather than being cancelled by player movement.
func sync_active_window(center_chunk: Vector2i, radius: int) -> void:
	for chunk_pos in _records.keys():
		var record: ChunkRecord = _records[chunk_pos]
		var distance := maxi(absi(chunk_pos.x - center_chunk.x), absi(chunk_pos.y - center_chunk.y))
		if record.state == State.VISIBLE and distance > radius:
			_transition(record, State.DORMANT)
		elif record.state == State.DORMANT and distance <= radius:
			_transition(record, State.VISIBLE)


## Chunks whose presentation is currently resident (painted), i.e. the exact
## set the old disabled unload path should ever consider erasing.
func get_resident_chunks() -> Array[Vector2i]:
	var resident: Array[Vector2i] = []
	for chunk_pos in _records.keys():
		var record: ChunkRecord = _records[chunk_pos]
		if record.state == State.VISIBLE or record.state == State.DORMANT:
			resident.append(chunk_pos)
	return resident


## Chunks requested but not yet fully resident: still QUEUED, PREPARED, or
## partway through REVEALING.
func get_pending_chunks() -> Array[Vector2i]:
	var pending: Array[Vector2i] = []
	for chunk_pos in _records.keys():
		var record: ChunkRecord = _records[chunk_pos]
		if record.state == State.QUEUED or record.state == State.PREPARED or record.state == State.REVEALING:
			pending.append(chunk_pos)
	return pending


## Narrow debug/test seam for the UNLOADED state the lifecycle contract
## declares but M4 never reaches in production (`streaming_unload_distant_chunks`
## defaults false and this is the only call site). UNLOADED is sticky in M4;
## M6 owns the real DORMANT -> UNLOADED -> reload policy, so a chunk unloaded
## here is not re-requestable within this slice.
func force_unload(chunk_pos: Vector2i) -> void:
	var record: ChunkRecord = _records.get(chunk_pos)
	if record == null or (record.state != State.VISIBLE and record.state != State.DORMANT):
		_illegal_transition_count += 1
		push_error("ProcGenChunkLifecycle: force_unload on non-resident chunk %s" % chunk_pos)
		return
	_transition(record, State.UNLOADED)


func get_snapshot() -> Dictionary:
	var by_state: Dictionary = {}
	for state_name in STATE_NAMES.values():
		by_state[state_name] = 0
	for chunk_pos in _records.keys():
		var record: ChunkRecord = _records[chunk_pos]
		var name: String = STATE_NAMES[record.state]
		by_state[name] = int(by_state[name]) + 1
	return {
		"by_state": by_state,
		"chunk_count": _records.size(),
		"transition_count": _transition_count,
		"illegal_transition_count": _illegal_transition_count,
	}


## Stable (coordinate-sorted) per-chunk debug snapshot for deterministic test
## assertions, not for per-frame runtime use.
func get_debug_chunk_states() -> Array[Dictionary]:
	var keys: Array = _records.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x != b.x:
			return a.x < b.x
		return a.y < b.y
	)
	var out: Array[Dictionary] = []
	for chunk_pos in keys:
		var record: ChunkRecord = _records[chunk_pos]
		out.append({
			"chunk": chunk_pos,
			"state": STATE_NAMES[record.state],
			"planned": record.planned_tile_count,
			"prepared": record.prepared_tile_count,
			"committed": record.committed_tile_count,
		})
	return out


func _transition(record: ChunkRecord, new_state: int) -> void:
	if record.state == new_state:
		return
	record.state = new_state
	_transition_count += 1
