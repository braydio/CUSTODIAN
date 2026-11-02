extends Node

signal stats_changed(snapshot: Dictionary)

var waves_survived: int = 0
var enemies_destroyed: int = 0
var power_failures: int = 0
var turrets_lost: int = 0


func _ready() -> void:
	add_to_group("game_stats")


func reset() -> void:
	waves_survived = 0
	enemies_destroyed = 0
	power_failures = 0
	turrets_lost = 0
	_emit_changed()


func record_wave_survived(wave_number: int) -> void:
	waves_survived = max(waves_survived, max(0, wave_number))
	_emit_changed()


func record_enemy_destroyed(_enemy_type: String = "") -> void:
	enemies_destroyed += 1
	_emit_changed()


func record_power_failure() -> void:
	power_failures += 1
	_emit_changed()


func record_turret_lost() -> void:
	turrets_lost += 1
	_emit_changed()


func get_snapshot() -> Dictionary:
	return {
		"waves_survived": waves_survived,
		"enemies_destroyed": enemies_destroyed,
		"power_failures": power_failures,
		"turrets_lost": turrets_lost,
	}


func _emit_changed() -> void:
	stats_changed.emit(get_snapshot())
