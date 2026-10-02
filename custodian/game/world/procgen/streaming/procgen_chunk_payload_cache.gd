class_name ProcGenChunkPayloadCache
extends RefCounted

## Lazy, invalidatable, generation-scoped derived cache for per-chunk reveal
## payloads (M5). It caches two things ProcGenTilemap otherwise recomputed on
## every access/re-reveal:
##  - deterministic chunk tile membership, in the exact canonical order the
##    owner's pure `_get_chunk_tiles()` builder already returns it;
##  - reusable per-tile floor/wall PREPARE records derived from the owner's
##    canonical `_generated_floor_cells`/`_generated_wall_cells` semantic
##    authority.
##
## This class owns no Node/TileMapLayer/CanvasItem/Texture/Resource/collision
## body/foliage node/road decal node/gameplay Callable state, and it is never
## semantic authority: every cached value is a read-only derived view the
## owner can always rebuild from its own canonical generated floor/wall
## dictionaries via the `builder` Callable supplied at each call site. It does
## not own the M3 tile queue (`ProcGenPauseAwareStreaming`) or the M4 chunk
## lifecycle (`ProcGenChunkLifecycle`), does not decide reveal order (the
## owner's live `_streaming_reveal_priority()` stays the only priority
## authority and is never cached), and implements no M6
## eviction/unload/hysteresis policy.
##
## Staleness model: every cached tile record is stamped with the
## `generation_id` and per-chunk `revision` it was built under. `reset()`
## bumps `generation_id` and clears everything (a true map
## generation/streaming-reset boundary). `invalidate_chunk()` bumps that one
## chunk's revision and drops its cached membership (a precise post-cache
## runtime semantic mutation, e.g. wall destruction or an authored-scene
## claim). `invalidate_all()` clears every cached payload without bumping
## `generation_id` (a bulk late-generation-finalization boundary, where
## treating "clear everything built so far" as simpler and
## behavior-preserving is explicitly allowed). A record carried externally
## (e.g. sitting in M3's `_prepared` queue across resume frames) can be
## checked against current identity via `is_record_stale()` /
## `revalidate_record_before_commit()` immediately before authoritative
## COMMIT mutation, so a stale Dictionary already queued elsewhere can never
## silently repaint a destroyed/claimed/repainted semantic truth.

const GENERATION_KEY := "_cache_generation_id"
const REVISION_KEY := "_cache_chunk_revision"

var hit_count: int = 0
var miss_count: int = 0
var invalidation_count: int = 0
var stale_refresh_count: int = 0
var reset_count: int = 0

var _generation_id: int = 0
var _chunk_membership: Dictionary = {}  # Vector2i chunk -> Array[Vector2i] tiles
var _chunk_revision: Dictionary = {}    # Vector2i chunk -> int revision
var _tile_records: Dictionary = {}      # Vector2i tile -> Dictionary stamped record


## True generation/streaming-reset boundary: drop every cached payload and
## start a new generation identity. Chunk revisions are also cleared since
## nothing from the previous generation can ever be compared again.
func reset() -> void:
	_generation_id += 1
	_chunk_membership.clear()
	_chunk_revision.clear()
	_tile_records.clear()
	reset_count += 1


## Explicit bulk invalidation primitive: drop every cached payload without
## changing generation identity. The current generation/runtime path uses
## precise per-chunk invalidation instead, so this remains available only for
## a future boundary that genuinely requires clearing all derived payloads.
## Chunk revisions are intentionally preserved -- they stay valid
## monotonically increasing identities, they just no longer have cached
## payload to match until something is accessed again.
func invalidate_all() -> void:
	if _chunk_membership.is_empty() and _tile_records.is_empty():
		return
	invalidation_count += maxi(1, _chunk_membership.size())
	_chunk_membership.clear()
	_tile_records.clear()


## Precise post-cache runtime invalidation for one chunk: wall destruction,
## authored-scene/world-overlook claims, or any other live semantic mutation
## of `_generated_floor_cells`/`_generated_wall_cells` after cache
## population. Bumps the chunk's revision (so any externally-held stale
## record for a tile in this chunk is detectable) and drops cached
## membership for the chunk so the next access rebuilds it from canonical
## state.
func invalidate_chunk(chunk_pos: Vector2i) -> void:
	_chunk_revision[chunk_pos] = int(_chunk_revision.get(chunk_pos, 0)) + 1
	_chunk_membership.erase(chunk_pos)
	invalidation_count += 1


func get_generation_id() -> int:
	return _generation_id


func get_chunk_revision(chunk_pos: Vector2i) -> int:
	return int(_chunk_revision.get(chunk_pos, 0))


## Lazily returns canonical chunk tile membership in the exact order
## `builder.call(chunk_pos)` produces it. Always returns a duplicate so a
## caller sorting/mutating the result (e.g. priority sort before enqueue)
## never corrupts the cached canonical copy.
func get_chunk_tiles(chunk_pos: Vector2i, builder: Callable) -> Array[Vector2i]:
	if _chunk_membership.has(chunk_pos):
		hit_count += 1
		var cached: Array[Vector2i] = _chunk_membership[chunk_pos]
		return cached.duplicate()
	miss_count += 1
	var tiles: Array[Vector2i] = builder.call(chunk_pos)
	_chunk_membership[chunk_pos] = tiles.duplicate()
	return tiles


## Lazily returns a reusable PREPARE record for `tile`, stamped with the
## generation/chunk-revision identity it was built under. A hit requires an
## exact match on both; otherwise it is treated as a miss and rebuilt.
func get_tile_record(tile: Vector2i, chunk_pos: Vector2i, builder: Callable) -> Dictionary:
	var current_revision := get_chunk_revision(chunk_pos)
	if _tile_records.has(tile):
		var cached: Dictionary = _tile_records[tile]
		if int(cached.get(GENERATION_KEY, -1)) == _generation_id \
				and int(cached.get(REVISION_KEY, -1)) == current_revision:
			hit_count += 1
			return cached
	miss_count += 1
	return _build_and_store(tile, current_revision, builder)


## True when `record` was stamped under a generation/chunk-revision that is
## no longer current -- i.e. it was built before a chunk invalidation or
## generation reset that this record's holder (e.g. M3's `_prepared` queue)
## does not know about. An unstamped record (never routed through this
## cache) is never considered stale here.
func is_record_stale(record: Dictionary, chunk_pos: Vector2i) -> bool:
	if not record.has(GENERATION_KEY):
		return false
	return int(record.get(GENERATION_KEY, -1)) != _generation_id \
			or int(record.get(REVISION_KEY, -1)) != get_chunk_revision(chunk_pos)


## Call immediately before authoritative COMMIT mutation. Returns `record`
## unchanged if it is still current; otherwise rebuilds+recaches it from
## `builder` and counts a stale refresh. This is the defense against a
## PREPARE-time Dictionary that is still sitting in M3's `_prepared` queue
## after its chunk was invalidated: invalidating only this cache is not
## enough on its own, because the queue already holds the old Dictionary by
## value.
func revalidate_record_before_commit(
	record: Dictionary, tile: Vector2i, chunk_pos: Vector2i, builder: Callable
) -> Dictionary:
	if not is_record_stale(record, chunk_pos):
		return record
	stale_refresh_count += 1
	return _build_and_store(tile, get_chunk_revision(chunk_pos), builder)


func _build_and_store(tile: Vector2i, revision: int, builder: Callable) -> Dictionary:
	var record: Dictionary = builder.call(tile)
	record[GENERATION_KEY] = _generation_id
	record[REVISION_KEY] = revision
	_tile_records[tile] = record
	return record


func get_cached_chunk_count() -> int:
	return _chunk_membership.size()


func get_cached_tile_record_count() -> int:
	return _tile_records.size()


## Deterministic, bounded telemetry snapshot -- no per-frame logging, safe to
## call from `ProcGenTilemap.get_runtime_health_snapshot()` or any debug
## accessor.
func get_telemetry_snapshot() -> Dictionary:
	return {
		"generation_id": _generation_id,
		"reset_count": reset_count,
		"cached_chunk_count": get_cached_chunk_count(),
		"cached_tile_record_count": get_cached_tile_record_count(),
		"hit_count": hit_count,
		"miss_count": miss_count,
		"invalidation_count": invalidation_count,
		"stale_refresh_count": stale_refresh_count,
	}
