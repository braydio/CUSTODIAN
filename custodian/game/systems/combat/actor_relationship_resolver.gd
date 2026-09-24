extends RefCounted
class_name ActorRelationshipResolver

const NEUTRAL: StringName = &"neutral"
const HOSTILE: StringName = &"hostile"
const OPERATOR_ALLIED: StringName = &"operator_allied"

static func resolve_allegiance(actor: Node) -> StringName:
	if actor == null or not is_instance_valid(actor):
		return NEUTRAL
	if actor.has_method("get_allegiance"):
		return StringName(str(actor.call("get_allegiance")))
	if actor.is_in_group("player") or actor.is_in_group("defense") or actor.is_in_group("turret") or actor.is_in_group("ally"):
		return OPERATOR_ALLIED
	if actor.is_in_group("enemy") or actor.is_in_group("enemies"):
		return HOSTILE
	var actor_team: Variant = actor.get("team")
	if actor_team != null:
		var team := StringName(str(actor_team))
		if team in [&"player", &"defense", &"turret"]:
			return OPERATOR_ALLIED
		if team == &"enemy":
			return HOSTILE
	return NEUTRAL

static func are_hostile(attacker: Node, target: Node, attacker_team: StringName = &"") -> bool:
	if attacker != null and is_instance_valid(attacker) and attacker.has_method("is_hostile_to"):
		return bool(attacker.call("is_hostile_to", target))
	var attacker_allegiance := _allegiance_for_attacker(attacker, attacker_team)
	var target_allegiance := resolve_allegiance(target)
	return (attacker_allegiance == HOSTILE and target_allegiance == OPERATOR_ALLIED) or (attacker_allegiance == OPERATOR_ALLIED and target_allegiance == HOSTILE)

static func can_target(attacker: Node, target: Node, attacker_team: StringName = &"") -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_dead") and bool(target.call("is_dead")):
		return false
	if target.has_method("is_combat_targetable_by"):
		if not bool(target.call("is_combat_targetable_by", attacker, attacker_team)):
			return false
	return are_hostile(attacker, target, attacker_team)

static func _allegiance_for_attacker(attacker: Node, attacker_team: StringName) -> StringName:
	if attacker != null and is_instance_valid(attacker):
		var explicit := resolve_allegiance(attacker)
		if explicit != NEUTRAL:
			return explicit
	if attacker_team in [&"player", &"defense", &"turret"]:
		return OPERATOR_ALLIED
	if attacker_team == &"enemy":
		return HOSTILE
	return NEUTRAL
