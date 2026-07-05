extends Node

const GAME_OVER_MODAL_SCENE := preload("res://game/ui/game_over/game_over_modal.tscn")

enum Phase {
	CONTRACT_BRIEFING,
	FREE_ROAM_PREP,
	ASSAULT_ACTIVE,
	POST_ASSAULT,
	EXFIL,
}

signal phase_changed(old_phase: int, new_phase: int)
signal resources_changed()
signal lives_changed(lives_left: int)
signal game_over_triggered(reason: String, stats: Dictionary)
signal contract_failed(result: Dictionary)

@export var total_lives: int = 1
@export var game_over_menu_scene_path: String = "res://ui/main_menu.tscn"
var lives_remaining: int = total_lives

var tick := 0
var paused := false
var game_over := false
var game_over_reason := ""

var current_phase: int = Phase.CONTRACT_BRIEFING
var phase_start_tick: int = 0
var assault_started_tick: int = -1
var contract_ready: bool = false
var contract_generation_failed: bool = false
var contract_failure_result: Dictionary = {}

var materials: int = 0
var defense_rating: float = 0.0
var _game_over_modal: Control = null


func _ready() -> void:
	add_to_group("game_state")
	reset_lives()


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
	contract_generation_failed = false
	contract_failure_result = {}
	if current_phase == Phase.CONTRACT_BRIEFING:
		set_phase(Phase.FREE_ROAM_PREP)


func mark_contract_failed(result: Dictionary = {}) -> void:
	contract_ready = false
	contract_generation_failed = true
	contract_failure_result = result.duplicate(true)
	contract_failed.emit(contract_failure_result)


func can_start_assault() -> bool:
	return contract_ready and not contract_generation_failed and not game_over and current_phase == Phase.FREE_ROAM_PREP


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
	var tree := get_tree()
	if tree != null:
		tree.paused = true
	var stats := _get_stats_snapshot()
	game_over_triggered.emit(game_over_reason, stats)
	_show_game_over_modal(game_over_reason, stats)

func lose_life(reason: String = "Custodian eliminated") -> int:
	if lives_remaining <= 0:
		return 0
	lives_remaining = max(0, lives_remaining - 1)
	lives_changed.emit(lives_remaining)
	if lives_remaining <= 0:
		trigger_game_over(reason)
	return lives_remaining

func reset_lives() -> void:
	var effective_total: int = max(1, total_lives)
	lives_remaining = effective_total
	lives_changed.emit(lives_remaining)


func reset_run_state(reset_stats: bool = true) -> void:
	var tree := get_tree()
	if tree != null:
		tree.paused = false
	paused = false
	game_over = false
	game_over_reason = ""
	tick = 0
	current_phase = Phase.CONTRACT_BRIEFING
	phase_start_tick = 0
	assault_started_tick = -1
	contract_ready = false
	contract_generation_failed = false
	contract_failure_result = {}
	materials = 0
	defense_rating = 0.0
	reset_lives()
	if reset_stats:
		var stats_node := get_node_or_null("/root/GameStats")
		if stats_node != null and stats_node.has_method("reset"):
			stats_node.call("reset")
	_clear_game_over_modal()


func _show_game_over_modal(reason: String, stats: Dictionary) -> void:
	_clear_game_over_modal()
	var tree := get_tree()
	if tree == null:
		return
	var modal := GAME_OVER_MODAL_SCENE.instantiate()
	_game_over_modal = modal
	if modal.has_method("configure"):
		modal.call("configure", reason, stats, game_over_menu_scene_path)
	var parent := tree.current_scene
	if parent == null:
		parent = tree.root
	parent.add_child(modal)


func _clear_game_over_modal() -> void:
	if _game_over_modal != null and is_instance_valid(_game_over_modal):
		_game_over_modal.queue_free()
	_game_over_modal = null


func _get_stats_snapshot() -> Dictionary:
	var stats_node := get_node_or_null("/root/GameStats")
	if stats_node != null and stats_node.has_method("get_snapshot"):
		var snapshot = stats_node.call("get_snapshot")
		if snapshot is Dictionary:
			return snapshot
	return {
		"waves_survived": 0,
		"enemies_destroyed": 0,
		"power_failures": 0,
		"turrets_lost": 0,
	}
