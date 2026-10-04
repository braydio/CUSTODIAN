class_name OperatorActionController
extends RefCounted

## Arbitration-only authority for the Operator's mutually exclusive actions.
##
## It has no actor, input, renderer, animation, or combat-domain dependency.
## The Operator owns action behavior and consumes these lifecycle signals.

signal action_entered(action: StringName, sequence: int, reentry: bool)
signal action_exited(action: StringName, sequence: int)

const NONE: StringName = &""
const FAST_ATTACK: StringName = &"attack_fast"
const HEAVY_ATTACK: StringName = &"attack_heavy"
const BLOCK: StringName = &"block"
const EQUIP: StringName = &"equip_weapon"
const SHEATHE: StringName = &"sheathe_weapon"
const DAMAGE_REACTION: StringName = &"hit_recoil"
const DEATH: StringName = &"death"

const ACTIONS: Array[StringName] = [
	FAST_ATTACK, HEAVY_ATTACK, BLOCK, EQUIP, SHEATHE, DAMAGE_REACTION, DEATH,
]

var current_action: StringName = NONE
var current_priority := 0
var elapsed := 0.0
var transition_sequence := 0
var terminal := false


func request(action: StringName, priority := 0, force := false) -> bool:
	if not ACTIONS.has(action):
		return false
	if terminal and action != DEATH:
		return false
	if action == DEATH:
		force = true
	if current_action == action:
		if not _can_reenter(action, priority):
			return true
		_exit_current()
		_enter(action, priority, true)
		return true
	if not current_action.is_empty() and not force and not _can_interrupt(action, priority):
		return false
	_exit_current()
	if action == DEATH:
		terminal = true
	_enter(action, priority, false)
	return true


func complete(action: StringName = NONE) -> bool:
	if current_action.is_empty():
		return false
	if not action.is_empty() and action != current_action:
		return false
	if terminal:
		return false
	_exit_current()
	return true


func force_neutralize() -> bool:
	if terminal:
		return false
	_exit_current()
	return true


func reset_for_respawn() -> void:
	_exit_current()
	terminal = false


func advance(delta: float) -> void:
	if not current_action.is_empty():
		elapsed += maxf(0.0, delta)


func is_active(action: StringName) -> bool:
	return current_action == action


func _can_interrupt(_next_action: StringName, priority: int) -> bool:
	match current_action:
		FAST_ATTACK, HEAVY_ATTACK:
			return priority >= 8
		BLOCK, EQUIP, SHEATHE:
			return false
		DAMAGE_REACTION:
			return false
		DEATH:
			return false
	return true


func _can_reenter(action: StringName, priority: int) -> bool:
	match action:
		FAST_ATTACK, HEAVY_ATTACK:
			return priority >= 8
		DAMAGE_REACTION:
			return priority >= 20
	return false


func _exit_current() -> void:
	if current_action.is_empty():
		return
	var exited := current_action
	current_action = NONE
	current_priority = 0
	elapsed = 0.0
	transition_sequence += 1
	action_exited.emit(exited, transition_sequence)


func _enter(action: StringName, priority: int, reentry: bool) -> void:
	current_action = action
	current_priority = priority
	elapsed = 0.0
	transition_sequence += 1
	action_entered.emit(action, transition_sequence, reentry)
