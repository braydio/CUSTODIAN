extends Node
class_name ActorAllegianceComponent

signal allegiance_changed(previous: StringName, current: StringName)

const NEUTRAL: StringName = &"neutral"
const HOSTILE: StringName = &"hostile"
const OPERATOR_ALLIED: StringName = &"operator_allied"

var _actor: Node
var _allegiance: StringName = NEUTRAL

func configure(actor: Node, initial: StringName = NEUTRAL) -> void:
	_actor = actor
	_allegiance = _normalize(initial)
	_sync_legacy_groups()

func get_allegiance() -> StringName:
	return _allegiance

func set_allegiance(next: StringName) -> bool:
	var normalized := _normalize(next)
	if normalized == _allegiance:
		_sync_legacy_groups()
		return false
	var previous := _allegiance
	_allegiance = normalized
	_sync_legacy_groups()
	allegiance_changed.emit(previous, _allegiance)
	return true

func is_hostile_to(other: Node) -> bool:
	if _allegiance == NEUTRAL or other == null:
		return false
	var other_allegiance := ActorRelationshipResolver.resolve_allegiance(other)
	if _allegiance == HOSTILE:
		return other_allegiance == OPERATOR_ALLIED
	if _allegiance == OPERATOR_ALLIED:
		return other_allegiance == HOSTILE
	return false

func _normalize(value: StringName) -> StringName:
	if value in [HOSTILE, OPERATOR_ALLIED, NEUTRAL]:
		return value
	return NEUTRAL

func _sync_legacy_groups() -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	if _allegiance == HOSTILE:
		if not _actor.is_in_group("enemy"):
			_actor.add_to_group("enemy")
		_actor.remove_from_group("ally")
	elif _allegiance == OPERATOR_ALLIED:
		_actor.remove_from_group("enemy")
		if not _actor.is_in_group("ally"):
			_actor.add_to_group("ally")
	else:
		_actor.remove_from_group("enemy")
		_actor.remove_from_group("ally")
