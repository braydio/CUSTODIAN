extends RefCounted
class_name TerminalFidelityPolicy

const FULL := &"full"
const DEGRADED := &"degraded"
const FRAGMENTED := &"fragmented"
const LOST := &"lost"

const _ORDER := {
	FULL: 0,
	DEGRADED: 1,
	FRAGMENTED: 2,
	LOST: 3,
}


func resolve(
	terminal_mode: StringName,
	sectors: Array,
	arrn_snapshot: Dictionary = {}
) -> StringName:
	var fidelity := FULL if terminal_mode == &"command" else DEGRADED
	var communications_state := _communications_state(sectors)
	match communications_state:
		&"degraded":
			fidelity = _worse_of(fidelity, DEGRADED)
		&"fragmented":
			fidelity = _worse_of(fidelity, FRAGMENTED)
		&"lost":
			fidelity = LOST

	var arrn_fidelity := normalize(arrn_snapshot.get("fidelity", ""))
	if not arrn_fidelity.is_empty():
		fidelity = arrn_fidelity
	# Field access is intentionally never as exact as an occupied command post,
	# even when ARRN reconstruction improves a damaged communications return.
	if terminal_mode != &"command":
		fidelity = _worse_of(fidelity, DEGRADED)
	return fidelity


func normalize(value: Variant) -> StringName:
	var normalized := String(value).strip_edges().to_lower()
	match normalized:
		"full":
			return FULL
		"degraded":
			return DEGRADED
		"fragmented":
			return FRAGMENTED
		"lost":
			return LOST
	return &""


func allows_exact_counts(fidelity: StringName) -> bool:
	return normalize(fidelity) == FULL


func allows_exact_location(fidelity: StringName, terminal_mode: StringName) -> bool:
	return normalize(fidelity) == FULL and terminal_mode == &"command"


func _communications_state(sectors: Array) -> StringName:
	for sector_variant in sectors:
		if not (sector_variant is Dictionary):
			continue
		var sector: Dictionary = sector_variant
		var identity := "%s %s" % [
			String(sector.get("name", "")),
			String(sector.get("sector_type", "")),
		]
		identity = identity.to_upper()
		if identity.find("COMMS") < 0 and identity.find("COMMUNICATION") < 0:
			continue
		var state := "%s %s" % [
			String(sector.get("status", "")),
			String(sector.get("power_tier", "")),
		]
		state = state.to_upper()
		if state.contains("OFFLINE") or state.contains("DESTROYED"):
			return LOST
		if state.contains("CRITICAL") or state.contains("BREACH"):
			return FRAGMENTED
		if state.contains("DAMAGED") or state.contains("DEGRADED"):
			return DEGRADED
		return FULL
	return &""


func _worse_of(left: StringName, right: StringName) -> StringName:
	var normalized_left := normalize(left)
	var normalized_right := normalize(right)
	if normalized_left.is_empty():
		return normalized_right
	if normalized_right.is_empty():
		return normalized_left
	return normalized_right if int(_ORDER[normalized_right]) > int(_ORDER[normalized_left]) else normalized_left
