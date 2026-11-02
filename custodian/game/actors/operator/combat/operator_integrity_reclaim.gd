class_name OperatorIntegrityReclaim
extends RefCounted

const CombatConstants := preload(
	"res://game/systems/combat/combat_constants.gd"
)

const DAMAGE_TO_POOL := 0.55
const MAX_POOL_FRACTION := 0.30
const LIGHT_WINDOW := 2.10
const HEAVY_WINDOW := 3.00
const FULL_VALUE_HOLD := 0.60
const MELEE_EFFICIENCY := 0.45
const CRITICAL_EFFICIENCY := 0.55
const RANGED_EFFICIENCY := 0.20
const REHIT_FORFEIT_FRACTION := 0.25

var _max_health := 100.0
var _packets: Array[Dictionary] = []
var _events: Array[Dictionary] = []


func configure(max_health: float) -> void:
	_max_health = maxf(1.0, max_health)
	var cap_excess := maxf(
		0.0,
		get_active_amount() - _max_health * MAX_POOL_FRACTION
	)
	_consume_amount(cap_excess)


func record_incoming_damage(
	applied_damage: float,
	hit_context: Dictionary
) -> void:
	var applied := maxf(0.0, applied_damage)
	if applied <= 0.0 \
	or not bool(hit_context.get("reclaim_eligible", false)) \
	or bool(hit_context.get("blocked", false)) \
	or bool(hit_context.get("guard_blocked", false)) \
	or bool(hit_context.get("guard_chip", false)):
		_events.append({
			"kind": &"rejected",
			"reason": &"incoming_ineligible",
			"amount": applied,
		})
		return

	var existing := get_active_amount()
	var forfeited := _consume_amount(
		existing * REHIT_FORFEIT_FRACTION
	)
	if forfeited > 0.0:
		_events.append({
			"kind": &"forfeited",
			"reason": &"struck_again",
			"amount": forfeited,
		})

	var cap := _max_health * MAX_POOL_FRACTION
	var available_capacity := maxf(0.0, cap - get_active_amount())
	var added := minf(applied * DAMAGE_TO_POOL, available_capacity)
	if added <= 0.0:
		_events.append({
			"kind": &"rejected",
			"reason": &"pool_cap",
			"amount": applied,
		})
		return

	var hit_strength := int(
		hit_context.get(
			"hit_strength",
			CombatConstants.HitStrength.LIGHT
		)
	)
	var window := (
		HEAVY_WINDOW
		if hit_strength == CombatConstants.HitStrength.HEAVY
		else LIGHT_WINDOW
	)
	_packets.append({
		"amount": added,
		"initial_amount": added,
		"time_remaining": window,
		"hold_remaining": FULL_VALUE_HOLD,
		"decay_rate": added / maxf(0.001, window - FULL_VALUE_HOLD),
		"health_ceiling": float(
			hit_context.get("target_health_before", _max_health)
		),
	})
	_events.append({
		"kind": &"pool_added",
		"amount": added,
		"window": window,
	})


func record_confirmed_damage(
	applied_damage: float,
	damage_context: Dictionary
) -> float:
	var applied := maxf(0.0, applied_damage)
	var rejection := _confirmed_damage_rejection(
		applied,
		damage_context
	)
	if not rejection.is_empty():
		_events.append({
			"kind": &"rejected",
			"reason": rejection,
			"amount": applied,
		})
		return 0.0

	var efficiency := _efficiency_for(
		StringName(str(damage_context.get("reclaim_kind", "")))
	)
	if efficiency <= 0.0:
		_events.append({
			"kind": &"rejected",
			"reason": &"damage_kind",
			"amount": applied,
		})
		return 0.0

	var requested := applied * efficiency
	var current_health := float(
		damage_context.get("current_health", 0.0)
	)
	var restored := 0.0
	var ordered := _packet_indices_by_expiration()
	for index: int in ordered:
		if requested <= 0.000001:
			break
		var packet := _packets[index]
		var ceiling := float(packet.get("health_ceiling", _max_health))
		var ceiling_room := maxf(
			0.0,
			ceiling - (current_health + restored)
		)
		var consumed := minf(
			requested,
			minf(float(packet.get("amount", 0.0)), ceiling_room)
		)
		if consumed <= 0.0:
			continue
		packet["amount"] = maxf(
			0.0,
			float(packet.get("amount", 0.0)) - consumed
		)
		_packets[index] = packet
		requested -= consumed
		restored += consumed
	_remove_empty_packets()
	if restored > 0.0:
		_events.append({
			"kind": &"restored",
			"amount": restored,
			"source_damage": applied,
			"reclaim_kind": str(
				damage_context.get("reclaim_kind", "")
			),
		})
	else:
		_events.append({
			"kind": &"rejected",
			"reason": &"no_recoverable_room",
			"amount": applied,
		})
	return restored


func advance_fixed(delta: float) -> void:
	var step := maxf(0.0, delta)
	if step <= 0.0 or _packets.is_empty():
		return
	for index in range(_packets.size()):
		var packet := _packets[index]
		var old_amount := float(packet.get("amount", 0.0))
		var hold_remaining := float(
			packet.get("hold_remaining", 0.0)
		)
		var decay_step := maxf(0.0, step - hold_remaining)
		packet["hold_remaining"] = maxf(
			0.0,
			hold_remaining - step
		)
		packet["time_remaining"] = maxf(
			0.0,
			float(packet.get("time_remaining", 0.0)) - step
		)
		if decay_step > 0.0:
			packet["amount"] = maxf(
				0.0,
				old_amount
					- float(packet.get("decay_rate", 0.0))
					* decay_step
			)
		_packets[index] = packet
	for index in range(_packets.size() - 1, -1, -1):
		var packet := _packets[index]
		if float(packet.get("time_remaining", 0.0)) > 0.0 \
		and float(packet.get("amount", 0.0)) > 0.000001:
			continue
		var expired_amount := maxf(
			0.0,
			float(packet.get("amount", 0.0))
		)
		_events.append({
			"kind": &"expired",
			"amount": expired_amount,
		})
		_packets.remove_at(index)


func clamp_to_missing_health(missing_health: float) -> void:
	var excess := maxf(
		0.0,
		get_active_amount() - maxf(0.0, missing_health)
	)
	var removed := _consume_amount(excess)
	if removed > 0.0:
		_events.append({
			"kind": &"forfeited",
			"reason": &"healing_clamp",
			"amount": removed,
		})


func get_active_amount() -> float:
	var total := 0.0
	for packet: Dictionary in _packets:
		total += maxf(0.0, float(packet.get("amount", 0.0)))
	return total


func get_packet_count() -> int:
	return _packets.size()


func get_window_remaining() -> float:
	if _packets.is_empty():
		return 0.0
	var nearest := INF
	for packet: Dictionary in _packets:
		nearest = minf(
			nearest,
			float(packet.get("time_remaining", 0.0))
		)
	return 0.0 if nearest == INF else nearest


func get_debug_packets() -> Array[Dictionary]:
	return _packets.duplicate(true)


func drain_events() -> Array[Dictionary]:
	var result := _events.duplicate(true)
	_events.clear()
	return result


func clear(reason: StringName) -> void:
	var removed := get_active_amount()
	_packets.clear()
	if removed > 0.0:
		_events.append({
			"kind": &"forfeited",
			"reason": reason,
			"amount": removed,
		})


func _confirmed_damage_rejection(
	applied_damage: float,
	context: Dictionary
) -> StringName:
	if applied_damage <= 0.0:
		return &"no_applied_damage"
	if not bool(context.get("operator_owned", false)):
		return &"not_operator_owned"
	if not bool(context.get("direct", false)):
		return &"not_direct"
	if not bool(context.get("hostile", false)):
		return &"not_hostile"
	if bool(context.get("passive", false)):
		return &"passive_target"
	if bool(context.get("structure", false)):
		return &"structure_target"
	if bool(context.get("damage_over_time", false)):
		return &"damage_over_time"
	if bool(context.get("deflected", false)) \
	or bool(context.get("invulnerable", false)):
		return &"no_confirmed_contact"
	if not bool(context.get("target_was_alive", false)):
		return &"target_not_alive"
	return &""


func _efficiency_for(kind: StringName) -> float:
	match kind:
		&"melee", &"unarmed":
			return MELEE_EFFICIENCY
		&"critical", &"riposte":
			return CRITICAL_EFFICIENCY
		&"ranged":
			return RANGED_EFFICIENCY
		_:
			return 0.0


func _consume_amount(requested: float) -> float:
	var remaining := maxf(0.0, requested)
	var consumed := 0.0
	for index: int in _packet_indices_by_expiration():
		if remaining <= 0.000001:
			break
		var packet := _packets[index]
		var amount := float(packet.get("amount", 0.0))
		var take := minf(amount, remaining)
		packet["amount"] = maxf(0.0, amount - take)
		_packets[index] = packet
		remaining -= take
		consumed += take
	_remove_empty_packets()
	return consumed


func _packet_indices_by_expiration() -> Array[int]:
	var result: Array[int] = []
	for index in range(_packets.size()):
		result.append(index)
	result.sort_custom(
		func(a: int, b: int) -> bool:
			return float(
				_packets[a].get("time_remaining", 0.0)
			) < float(
				_packets[b].get("time_remaining", 0.0)
			)
	)
	return result


func _remove_empty_packets() -> void:
	for index in range(_packets.size() - 1, -1, -1):
		if float(_packets[index].get("amount", 0.0)) <= 0.000001:
			_packets.remove_at(index)
