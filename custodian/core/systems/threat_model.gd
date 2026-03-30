extends Node
class_name ThreatModel

signal threat_updated(new_threat: float)

@export var base_threat: float = 3.0
@export var threat_per_wave: float = 1.5
@export var threat_per_destroyed_structure: float = 6.0
@export var threat_per_minute: float = 0.35

var elapsed_minutes: float = 0.0
var _last_threat: float = -1.0

func _process(delta: float) -> void:
	elapsed_minutes += delta / 60.0

func calculate_threat(wave_number: int, destroyed_structures: int) -> float:
	var threat := base_threat
	threat += float(wave_number) * threat_per_wave
	threat += float(destroyed_structures) * threat_per_destroyed_structure
	threat += elapsed_minutes * threat_per_minute
	if abs(threat - _last_threat) > 0.001:
		_last_threat = threat
		threat_updated.emit(threat)
	return threat

func reset() -> void:
	elapsed_minutes = 0.0
	_last_threat = -1.0
