class_name OperatorWeaponRuntimeState
extends RefCounted

## Mutable combat state keyed to one weapon identity. Definition resources stay
## reusable tuning data; this object owns the values that change during play.
var loaded_magazine: int = 0
var is_reloading: bool = false
var reload_remaining: float = 0.0
var reload_total: float = 0.0


func begin_reload(duration: float) -> void:
	is_reloading = true
	reload_total = maxf(0.0, duration)
	reload_remaining = reload_total


func advance_reload(delta: float) -> bool:
	if not is_reloading:
		return false
	reload_remaining = maxf(0.0, reload_remaining - maxf(0.0, delta))
	return reload_remaining <= 0.0


func cancel_reload() -> void:
	is_reloading = false
	reload_remaining = 0.0
