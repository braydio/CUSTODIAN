class_name ProcGenPauseAwareStreaming
extends Node

## Single owner of the PREPARE/COMMIT lifecycle for already-requested procgen
## streaming-reveal work (M3). ProcGenTilemap supplies the shared pending-tile
## queue (the same Array[Vector2i] it already exposes as
## `_streaming_reveal_queue`) and two narrow Callables -- a pure
## `build_record(tile) -> Dictionary` lookup and a mutating
## `commit_record(record) -> void` application -- and stays the only owner of
## tile/world semantics (TileMap cells, foliage, collision, decals). This
## authority never touches TileMap/Node state itself.
##
## PREPARE (pause-only): while `SceneTree.paused` is true, this node's own
## `_process` (PROCESS_MODE_ALWAYS, explicitly gated on `SceneTree.paused`)
## budgets deterministic `build_record` calls that convert already-queued
## tiles into immutable prepared records, without enqueueing new tiles and
## without mutating live world state. Pausing never adds to the queue because
## the only producer (ProcGenTilemap's player-chunk-change detection) lives in
## ProcGenTilemap's own `_process`, which already stops while paused.
##
## COMMIT (resume/normal play): `drain_commit` applies prepared records first
## (FIFO, preserving the original reveal order), then falls through to
## building+committing any remaining queued tiles directly -- identical to the
## pre-M3 unpaused path whenever nothing was ever prepared, so normal
## (never-paused) streaming is unchanged.

var requested_count: int = 0
var prepared_count: int = 0
var resumed_count: int = 0
var committed_count: int = 0

var _queue: Array[Vector2i] = []
var _prepared: Array[Dictionary] = []
var _build_record: Callable = Callable()
var _commit_record: Callable = Callable()
var _get_prepare_budget: Callable = Callable()
var _resume_event_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## `queue_ref` must be the exact Array[Vector2i] the owner also exposes as its
## own pending-reveal field; it is shared by reference (never duplicated) so
## owner introspection and this authority's bookkeeping always agree.
func configure(
	queue_ref: Array[Vector2i],
	build_record: Callable,
	commit_record: Callable,
	get_prepare_budget: Callable
) -> void:
	_queue = queue_ref
	_build_record = build_record
	_commit_record = commit_record
	_get_prepare_budget = get_prepare_budget


func reset() -> void:
	_queue.clear()
	_prepared.clear()
	requested_count = 0
	prepared_count = 0
	resumed_count = 0
	committed_count = 0
	_resume_event_pending = false


## Appends already-sorted reveal tiles to the shared queue. Callers keep
## ownership of reveal-priority ordering; this authority only tracks counts
## and later lifecycle state for them.
func enqueue_many(tiles: Array[Vector2i]) -> void:
	if tiles.is_empty():
		return
	for tile in tiles:
		_queue.append(tile)
	requested_count += tiles.size()


func has_prepared() -> bool:
	return not _prepared.is_empty()


func is_idle() -> bool:
	return _queue.is_empty() and _prepared.is_empty()


## True exactly once per pause episode that produced prepared work, the first
## time this is polled after resume. Callers should log/telemetry it once and
## stop polling until the next transition.
func take_resume_event() -> bool:
	if not _resume_event_pending:
		return false
	_resume_event_pending = false
	resumed_count += 1
	return true


func get_snapshot() -> Dictionary:
	return {
		"requested": requested_count,
		"prepared": prepared_count,
		"deferred": _queue.size(),
		"prepared_pending": _prepared.size(),
		"resumed": resumed_count,
		"committed": committed_count,
	}


## Applies up to `max_count` tiles of already-requested reveal work: prepared
## records first (FIFO), then remaining queued tiles built+committed directly.
## Returns the number committed. Safe to call every frame unconditionally.
func drain_commit(max_count: int) -> int:
	var remaining := max_count
	var committed := 0
	while remaining > 0 and not _prepared.is_empty():
		_commit_record.call(_prepared.pop_front())
		committed += 1
		committed_count += 1
		remaining -= 1
	while remaining > 0 and not _queue.is_empty():
		var tile: Vector2i = _queue.pop_front()
		_commit_record.call(_build_record.call(tile))
		committed += 1
		committed_count += 1
		remaining -= 1
	return committed


func _process(_delta: float) -> void:
	if not is_inside_tree() or not get_tree().paused:
		return
	_advance_prepare()


## Marks `_resume_event_pending` directly whenever a paused tick actually
## prepares work, rather than inferring the pause->unpause transition from
## this node's own tick ordering relative to its owner's. The owner's
## `_process` only ever runs while unpaused, so the first time it polls
## `take_resume_event()` after this is necessarily the resume -- with no
## dependency on sibling/parent process order within a frame.
func _advance_prepare() -> void:
	if _queue.is_empty() or not _build_record.is_valid():
		return
	var budget := int(_get_prepare_budget.call()) if _get_prepare_budget.is_valid() else 0
	var prepared_any := false
	while budget > 0 and not _queue.is_empty():
		var tile: Vector2i = _queue.pop_front()
		_prepared.append(_build_record.call(tile))
		prepared_count += 1
		prepared_any = true
		budget -= 1
	if prepared_any:
		_resume_event_pending = true
