extends Node2D
class_name Damageable

signal damaged(amount: float, new_hp: float)
signal repaired(amount: float, new_hp: float)
signal destroyed()
signal state_changed(new_state: String)

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var projectile_armor: float = 0.0

var state: String = "operational"


func _ready() -> void:
	current_health = clamp(current_health, 0.0, max_health)
	_update_state()


func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return

	var applied = max(0.0, amount)
	if applied <= 0.0:
		return

	current_health = max(0.0, current_health - applied)
	damaged.emit(applied, current_health)
	_update_state()

	if current_health <= 0.0:
		_on_destroyed()


func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
	var incoming: float = max(0.0, amount)
	var applied: float = max(0.0, incoming - max(0.0, projectile_armor))
	if applied <= 0.0:
		return {
			"blocked": true,
			"applied_damage": 0.0,
		}
	take_damage(applied)
	return {
		"blocked": false,
		"applied_damage": applied,
	}


func repair(amount: float) -> void:
	var applied = max(0.0, amount)
	if applied <= 0.0:
		return
	if state == "destroyed":
		return
	if current_health >= max_health:
		return

	current_health = min(max_health, current_health + applied)
	repaired.emit(applied, current_health)
	_update_state()


func heal(amount: float) -> void:
	# Compatibility alias for older callers.
	repair(amount)


func get_efficiency() -> float:
	if max_health <= 0.0:
		return 0.0
	return clamp(current_health / max_health, 0.0, 1.0)


func get_state() -> String:
	return state


func is_dead() -> bool:
	return current_health <= 0.0 or state == "destroyed"


func _update_state() -> void:
	var hp_percent = get_efficiency() * 100.0
	var new_state: String
	if hp_percent >= 60.0:
		new_state = "operational"
	elif hp_percent >= 30.0:
		new_state = "damaged"
	elif hp_percent > 0.0:
		new_state = "critical"
	else:
		new_state = "destroyed"

	if new_state != state:
		state = new_state
		state_changed.emit(state)
		_on_state_changed(state)


func _on_state_changed(_new_state: String) -> void:
	pass


func _on_destroyed() -> void:
	destroyed.emit()
