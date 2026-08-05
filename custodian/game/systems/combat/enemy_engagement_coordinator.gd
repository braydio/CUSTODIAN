extends Node

const DEFAULT_INFLUENCE_RADIUS_PX := 260.0
const DEFAULT_MAX_COMMITTED_ATTACKERS := 1

var influence_radius_px := DEFAULT_INFLUENCE_RADIUS_PX
var max_committed_attackers := DEFAULT_MAX_COMMITTED_ATTACKERS
var _tokens: Dictionary = {}


func request_committed_attack(
	attacker: Node2D,
	operator: Node2D,
	hold_duration_sec: float
) -> bool:
	if attacker == null or operator == null:
		return false
	_prune_tokens()
	var attacker_id := attacker.get_instance_id()
	if _tokens.has(attacker_id):
		_tokens[attacker_id]["expires_msec"] = _expiry_msec(hold_duration_sec)
		return true
	if attacker.global_position.distance_to(operator.global_position) > influence_radius_px:
		return true
	var committed_near_operator := 0
	for token_variant: Variant in _tokens.values():
		var token := token_variant as Dictionary
		var token_operator := (token.get("operator", null) as WeakRef).get_ref() as Node2D
		if token_operator == operator:
			committed_near_operator += 1
	if committed_near_operator >= max_committed_attackers:
		return false
	_tokens[attacker_id] = {
		"attacker": weakref(attacker),
		"operator": weakref(operator),
		"expires_msec": _expiry_msec(hold_duration_sec),
	}
	return true


func release_committed_attack(attacker: Node) -> void:
	if attacker != null:
		_tokens.erase(attacker.get_instance_id())


func has_committed_attack(attacker: Node) -> bool:
	_prune_tokens()
	return attacker != null and _tokens.has(attacker.get_instance_id())


func clear() -> void:
	_tokens.clear()


func get_debug_state() -> Dictionary:
	_prune_tokens()
	return {
		"active_tokens": _tokens.size(),
		"influence_radius_px": influence_radius_px,
		"max_committed_attackers": max_committed_attackers,
	}


func _expiry_msec(duration_sec: float) -> int:
	return Time.get_ticks_msec() + int(maxf(0.05, duration_sec) * 1000.0)


func _prune_tokens() -> void:
	var now := Time.get_ticks_msec()
	var stale: Array[int] = []
	for attacker_id_variant: Variant in _tokens:
		var attacker_id := int(attacker_id_variant)
		var token := _tokens[attacker_id_variant] as Dictionary
		var attacker_ref := token.get("attacker", null) as WeakRef
		var operator_ref := token.get("operator", null) as WeakRef
		if (
			attacker_ref == null
			or operator_ref == null
			or attacker_ref.get_ref() == null
			or operator_ref.get_ref() == null
			or now >= int(token.get("expires_msec", 0))
		):
			stale.append(attacker_id)
	for attacker_id: int in stale:
		_tokens.erase(attacker_id)
