extends Node

enum Phase {
	CONTRACT_BRIEFING,
	FREE_ROAM_PREP,
	ASSAULT_ACTIVE,
	POST_ASSAULT,
	EXFIL,
}

signal phase_changed(old_phase: int, new_phase: int)
signal resources_changed()

var tick := 0
var paused := false
var game_over := false
var game_over_reason := ""

var current_phase: int = Phase.CONTRACT_BRIEFING
var phase_start_tick: int = 0
var assault_started_tick: int = -1
var contract_ready: bool = false

var materials: int = 0
var defense_rating: float = 0.0


func _ready() -> void:
	add_to_group("game_state")


func advance() -> void:
	if not paused and not game_over:
		tick += 1


func set_phase(new_phase: int) -> void:
	if current_phase == new_phase:
		return
	var old_phase := current_phase
	current_phase = new_phase
	phase_start_tick = tick
	phase_changed.emit(old_phase, new_phase)


func get_phase_name(phase: int = -1) -> String:
	var target_phase := current_phase if phase < 0 else phase
	if target_phase < 0 or target_phase >= Phase.size():
		return "UNKNOWN"
	return String(Phase.keys()[target_phase])


func mark_contract_ready() -> void:
	contract_ready = true
	if current_phase == Phase.CONTRACT_BRIEFING:
		set_phase(Phase.FREE_ROAM_PREP)


func can_start_assault() -> bool:
	return contract_ready and not game_over and current_phase == Phase.FREE_ROAM_PREP


func start_assault() -> bool:
	if not can_start_assault():
		return false
	assault_started_tick = tick
	set_phase(Phase.ASSAULT_ACTIVE)
	return true


func complete_assault() -> void:
	if current_phase == Phase.ASSAULT_ACTIVE:
		set_phase(Phase.POST_ASSAULT)


func add_materials(amount: int) -> void:
	if amount == 0:
		return
	materials = max(0, materials + amount)
	resources_changed.emit()


func set_defense_rating(value: float) -> void:
	var clamped_value: float = maxf(0.0, value)
	if is_equal_approx(defense_rating, clamped_value):
		return
	defense_rating = clamped_value
	resources_changed.emit()


func trigger_game_over(reason: String = "Command Post destroyed") -> void:
	if game_over:
		return
	game_over = true
	paused = true
	game_over_reason = reason
