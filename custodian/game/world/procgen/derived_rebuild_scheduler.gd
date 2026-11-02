class_name ProcGenDerivedRebuildScheduler
extends RefCounted

## Deterministic request ledger for expensive derived procgen state. It does not
## own rebuilds or decide when they commit; existing systems remain the owners.
const SYSTEMS: Array[StringName] = [
	&"topology", &"collision", &"walkable_boundary", &"navigation", &"shadows", &"presentation",
]

var _requested: Dictionary = {}
var _coalesced: Dictionary = {}
var _committed: Dictionary = {}
var _duration_usec: Dictionary = {}
var _pending_by_batch: Dictionary = {}


func request(system: StringName, reason: String, region: Rect2i, batch_id: int) -> bool:
	if not SYSTEMS.has(system):
		push_error("Unknown procgen derived rebuild system: %s" % system)
		return false
	_requested[system] = int(_requested.get(system, 0)) + 1
	var batch_key := "%d:%s" % [batch_id, system]
	if _pending_by_batch.has(batch_key):
		_coalesced[system] = int(_coalesced.get(system, 0)) + 1
		var prior: Dictionary = _pending_by_batch[batch_key]
		prior["reasons"][reason] = true
		prior["region"] = _union_rect(prior["region"] as Rect2i, region)
		_pending_by_batch[batch_key] = prior
		return false
	_pending_by_batch[batch_key] = {
		"system": system,
		"reasons": {reason: true},
		"region": region,
	}
	return true


func commit(system: StringName, duration_usec: int, batch_id: int) -> void:
	_committed[system] = int(_committed.get(system, 0)) + 1
	_duration_usec[system] = int(_duration_usec.get(system, 0)) + maxi(0, duration_usec)
	for key in _pending_by_batch.keys():
		var pending: Dictionary = _pending_by_batch[key]
		if pending.get("system") == system:
			_pending_by_batch.erase(key)


func get_snapshot() -> Dictionary:
	var systems: Dictionary = {}
	for system in SYSTEMS:
		systems[String(system)] = {
			"requested": int(_requested.get(system, 0)),
			"coalesced": int(_coalesced.get(system, 0)),
			"committed": int(_committed.get(system, 0)),
			"duration_usec_total": int(_duration_usec.get(system, 0)),
		}
	var pending: Array[Dictionary] = []
	var keys: Array = _pending_by_batch.keys()
	keys.sort()
	for key in keys:
		var entry: Dictionary = _pending_by_batch[key]
		var reasons: Array = entry["reasons"].keys()
		reasons.sort()
		pending.append({
			"batch": str(key),
			"system": String(entry["system"]),
			"reasons": reasons,
			"region": entry["region"],
		})
	return {"systems": systems, "pending": pending}


func _union_rect(a: Rect2i, b: Rect2i) -> Rect2i:
	if a.has_area() and b.has_area():
		return a.merge(b)
	return a if a.has_area() else b
