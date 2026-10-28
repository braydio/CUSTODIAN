class_name OperatorRangedController
extends RefCounted

## Sole mutable authority for ranged action phases, ammo economy, and fire timing.
## Weapon-specific magazine, reload, and heat values live in
## OperatorWeaponRuntimeState instances owned by the loadout domain.
var fire_cooldown_remaining: float = 0.0
var last_fire_cooldown: float = 0.0
var reserve_by_type: Dictionary = {}
var capacity_by_type: Dictionary = {}
var last_fire_failure: StringName = &""
var failure_feedback_cooldown: float = 0.0
var last_failure_feedback: StringName = &""
var pending_shot: Dictionary = {}
var ready_active: bool = false
var ready_weapon_definition: OperatorWeaponDefinition = null

var sidearm_draw_active: bool = false
var sidearm_phase: StringName = &"holstered"
var sidearm_phase_started: bool = false
var sidearm_fire_buffered: bool = false
var sidearm_action_direction: Vector2 = Vector2.DOWN
var sidearm_recovery_remaining: float = 0.0

var primary_action_phase: StringName = &""
var primary_action_timer: float = 0.0
var primary_action_total: float = 0.0
var primary_action_direction: Vector2 = Vector2.RIGHT
var primary_action_suffix: StringName = &"right"
var loadout_controller: OperatorLoadoutController


func bind_loadout(controller: OperatorLoadoutController) -> void:
	loadout_controller = controller


func is_ready() -> bool:
	return ready_active and ready_weapon_definition != null


func weapon_runtime_state(weapon_key: String) -> OperatorWeaponRuntimeState:
	if loadout_controller == null:
		return null
	return loadout_controller.runtime_state(weapon_key)


func consume_loaded_ammo(weapon_key: String, amount: int) -> int:
	var state := weapon_runtime_state(weapon_key)
	if state == null:
		return 0
	var consumed := mini(maxi(0, amount), state.loaded_magazine)
	state.loaded_magazine -= consumed
	return consumed


func set_loaded_ammo(weapon_key: String, amount: int) -> void:
	var state := weapon_runtime_state(weapon_key)
	if state != null:
		state.loaded_magazine = maxi(0, amount)


func begin_reload(weapon_key: String, duration: float) -> void:
	var state := weapon_runtime_state(weapon_key)
	if state != null:
		state.begin_reload(duration)


func advance_reload(weapon_key: String, delta: float) -> bool:
	var state := weapon_runtime_state(weapon_key)
	return state != null and state.advance_reload(delta)


func is_reloading(weapon_key: String) -> bool:
	var state := weapon_runtime_state(weapon_key)
	return state != null and state.is_reloading


func add_ammo_type(operator: Node, ammo_type: String, amount: int) -> int:
	var normalized := "kinetic_light" if ammo_type == "kinetic" or ammo_type.is_empty() else ammo_type
	var capacity := int(capacity_by_type.get(normalized, 0))
	if capacity <= 0:
		return 0
	var old_amount := int(reserve_by_type.get(normalized, 0))
	reserve_by_type[normalized] = clampi(old_amount + maxi(0, amount), 0, capacity)
	operator.call("_sync_legacy_ammo_fields")
	return int(reserve_by_type[normalized]) - old_amount


func add_reserve(ammo_type: String, amount: int) -> int:
	var normalized := "kinetic_light" if ammo_type == "kinetic" or ammo_type.is_empty() else ammo_type
	var capacity := int(capacity_by_type.get(normalized, 0))
	if capacity <= 0:
		return 0
	var old_amount := int(reserve_by_type.get(normalized, 0))
	reserve_by_type[normalized] = clampi(old_amount + maxi(0, amount), 0, capacity)
	return int(reserve_by_type[normalized]) - old_amount


func register_ammo_type(ammo_type: String, capacity: int, starting_reserve: int = 0) -> void:
	var normalized := "kinetic_light" if ammo_type == "kinetic" or ammo_type.is_empty() else ammo_type
	capacity_by_type[normalized] = maxi(int(capacity_by_type.get(normalized, 0)), maxi(0, capacity))
	if not reserve_by_type.has(normalized):
		reserve_by_type[normalized] = clampi(starting_reserve, 0, int(capacity_by_type[normalized]))


func set_reserve(ammo_type: String, amount: int) -> void:
	var normalized := "kinetic_light" if ammo_type == "kinetic" or ammo_type.is_empty() else ammo_type
	var capacity := int(capacity_by_type.get(normalized, 0))
	if capacity > 0:
		reserve_by_type[normalized] = clampi(amount, 0, capacity)


func handle_sidearm_fire_input(operator: Node) -> void:
	if not bool(operator.call("_is_attack_primary_just_pressed")):
		return
	if sidearm_phase == &"held" and fire_cooldown_remaining <= 0.0 and pending_shot.is_empty():
		operator.call("_request_ranged_shot")
		return
	if sidearm_phase in [&"drawing", &"firing"] and not sidearm_fire_buffered:
		sidearm_fire_buffered = true
		operator.call("_obs_increment", &"player_ranged_fire_deferred_sidearm_not_ready")
		operator.call("_obs_log", &"player_ranged_fire_deferred", {
			"reason": "sidearm_not_ready",
			"phase": String(sidearm_phase),
		})


func try_consume_sidearm_fire_buffer(operator: Node) -> void:
	if not sidearm_fire_buffered:
		return
	if not bool(operator.call("_is_using_sidearm_ranged")) or not bool(operator.call("_is_ranged_ready_active")):
		sidearm_fire_buffered = false
		operator.call("_obs_increment", &"player_ranged_fire_deferred_cancelled_weapon_switch")
		return
	if sidearm_phase != &"held" or fire_cooldown_remaining > 0.0 or not pending_shot.is_empty():
		return
	sidearm_fire_buffered = false
	operator.call("_obs_increment", &"player_ranged_fire_deferred_consumed")
	operator.call("_request_ranged_shot")


func can_fire(operator: Node) -> bool:
	return is_ready() \
		and bool(operator.call("_is_ranged_aim_ready")) \
		and not bool(operator.get("_reload_active")) \
		and not bool(operator.call("_is_active_weapon_overheated")) \
		and int(operator.call("_get_current_loaded_ammo")) > 0 \
		and fire_cooldown_remaining <= 0.0 \
		and pending_shot.is_empty()


func cancel_reload(weapon_key: String) -> void:
	var state := weapon_runtime_state(weapon_key)
	if state != null:
		state.cancel_reload()


func advance_fire_cooldown(delta: float) -> void:
	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - maxf(0.0, delta))


func begin_pending_shot(timer: float, profile: Dictionary, direction: Vector2, aim_point: Vector2) -> void:
	pending_shot = {
		"timer": maxf(0.0, timer),
		"profile": profile.duplicate(true),
		"accepted_aim_direction": direction,
		"accepted_aim_world_position": aim_point,
	}


func advance_pending_shot(delta: float) -> bool:
	if pending_shot.is_empty():
		return false
	var remaining := maxf(0.0, float(pending_shot.get("timer", 0.0)) - maxf(0.0, delta))
	pending_shot["timer"] = remaining
	return remaining <= 0.0


func clear_pending_shot() -> void:
	pending_shot.clear()


func clear_sidearm_action() -> void:
	sidearm_draw_active = false
	sidearm_phase = &"holstered"
	sidearm_phase_started = false
	if sidearm_fire_buffered:
		sidearm_fire_buffered = false
	sidearm_recovery_remaining = 0.0


func begin_sidearm_recovery(duration: float) -> void:
	sidearm_phase = &"recovering"
	sidearm_phase_started = false
	sidearm_recovery_remaining = maxf(0.0, duration)


func advance_sidearm_recovery(delta: float) -> bool:
	if sidearm_phase != &"recovering":
		return false
	sidearm_recovery_remaining = maxf(0.0, sidearm_recovery_remaining - maxf(0.0, delta))
	if sidearm_recovery_remaining > 0.0:
		return false
	sidearm_phase = &"held"
	sidearm_phase_started = false
	return true


func set_primary_action(phase: StringName, duration: float, direction: Vector2 = Vector2.RIGHT, suffix: StringName = &"right") -> void:
	primary_action_phase = phase
	primary_action_timer = maxf(0.0, duration)
	primary_action_total = primary_action_timer
	primary_action_direction = direction
	primary_action_suffix = suffix


func clear_primary_action() -> void:
	primary_action_phase = &""
	primary_action_timer = 0.0
	primary_action_total = 0.0


func advance_primary_action(delta: float) -> bool:
	primary_action_timer = maxf(0.0, primary_action_timer - maxf(0.0, delta))
	return primary_action_timer <= 0.0


func transition_ratio() -> float:
	if primary_action_total <= 0.001:
		return 0.0
	return clampf(1.0 - primary_action_timer / primary_action_total, 0.0, 1.0)
