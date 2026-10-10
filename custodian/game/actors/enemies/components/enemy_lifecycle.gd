extends RefCounted
class_name EnemyLifecycle

const ENEMY_CORPSE_LOOT_SCRIPT := preload("res://game/actors/enemies/components/enemy_corpse_loot.gd")

enum LifeState {
	ALIVE,
	DYING,
	LOOTABLE_CORPSE,
	EMPTY_CORPSE,
}

var host: Enemy
var config: EnemyLifecycleConfig

var health := 50.0
var max_health := 50.0
var dead := false
var life_state: int = LifeState.ALIVE
var _pending_corpse_payload: Dictionary = {}
var _corpse_loot: EnemyCorpseLoot = null
var _empty_corpse_age_sec := 0.0
var _corpse_cleanup_timer_sec := 0.0
var _pending_payload_built := false
var _health_was_set_before_setup := false
var _max_health_was_set_before_setup := false


func setup(new_host: Enemy, new_config: EnemyLifecycleConfig) -> void:
	host = new_host
	config = new_config
	if config == null:
		config = EnemyLifecycleConfig.new()
	if not _health_was_set_before_setup:
		health = config.starting_health
	if not _max_health_was_set_before_setup:
		max_health = config.maximum_health


func set_health(value: float) -> void:
	health = value
	if config == null:
		_health_was_set_before_setup = true


func set_max_health(value: float) -> void:
	max_health = value
	if config == null:
		_max_health_was_set_before_setup = true


func set_life_state(value: int) -> void:
	life_state = value


func restore_state(
	current_health: float,
	maximum: float,
	is_dead: bool,
	state: int
) -> void:
	health = current_health
	max_health = maximum
	dead = is_dead
	life_state = state
	_pending_payload_built = state != LifeState.ALIVE
	_health_was_set_before_setup = true
	_max_health_was_set_before_setup = true


func apply_damage(amount: float, reject_when_dead: bool = true) -> Dictionary:
	var health_before := maxf(0.0, health)
	if health_before <= 0.0 or (reject_when_dead and dead):
		return {
			"accepted": false,
			"health_before": health_before,
			"applied_damage": 0.0,
		}
	var applied_damage := minf(maxf(0.0, amount), health_before)
	if applied_damage > 0.0:
		health = maxf(0.0, health_before - applied_damage)
	return {
		"accepted": true,
		"health_before": health_before,
		"applied_damage": applied_damage,
	}


func build_damage_result(
	applied_damage: float,
	target_was_alive: bool,
	team: String,
	passive: bool
) -> Dictionary:
	var safe_applied := maxf(0.0, applied_damage)
	var health_after := maxf(0.0, health)
	return {
		"applied_damage": safe_applied,
		"damage_applied": safe_applied,
		"target_was_alive": target_was_alive,
		"target_health_before": health_after + safe_applied,
		"target_health_after": health_after,
		"lethal": dead or health <= 0.0,
		"blocked": false,
		"eligible_hostile": team == "enemy" and not passive,
		"passive": passive,
		"structure": false,
		"deflected": false,
		"invulnerable": false,
	}


func begin_death() -> bool:
	if life_state != LifeState.ALIVE:
		return false
	life_state = LifeState.DYING
	dead = true
	return true


func build_pending_payload_once() -> void:
	if not dead or life_state != LifeState.DYING or _pending_payload_built:
		return
	_pending_corpse_payload = build_corpse_payload_once()
	_pending_payload_built = true


func build_corpse_payload_once() -> Dictionary:
	var resource_payload := _roll_loot_table_payload()
	var vault_payload := {}
	var carrier := host.get_node_or_null("EnemyLootCarrier")
	if carrier != null and carrier.has_method("take_payload"):
		vault_payload = carrier.call("take_payload") as Dictionary
	var legacy_materials := 0
	# Preserve the existing rule: any configured table suppresses fallback PARTS,
	# including a roll where every chance misses.
	if config.loot_table.is_empty() and config.material_drop_fallback_enabled:
		legacy_materials = _roll_legacy_material_payload()
	return {
		"resource_ledger": resource_payload,
		"vault_recovery": vault_payload,
		"legacy_materials": legacy_materials,
		"items": [],
	}


func complete_death_presentation() -> void:
	if life_state != LifeState.DYING:
		return
	if _structured_payload_has_loot(_pending_corpse_payload):
		life_state = LifeState.LOOTABLE_CORPSE
		_corpse_loot = ENEMY_CORPSE_LOOT_SCRIPT.new() as EnemyCorpseLoot
		_corpse_loot.name = "CorpseLoot"
		_corpse_loot.pickup_radius_px = config.corpse_loot_pickup_radius_px
		_corpse_loot.marker_offset = config.corpse_loot_marker_offset
		host.add_child(_corpse_loot)
		_corpse_loot.loot_collected.connect(_on_corpse_loot_collected)
		_corpse_loot.activate(_pending_corpse_payload, host.get_corpse_visual_owner())
	else:
		_enter_empty_corpse_state()
	_pending_corpse_payload.clear()


func advance_dead(delta: float) -> bool:
	if life_state != LifeState.EMPTY_CORPSE:
		return false
	_empty_corpse_age_sec += delta
	_corpse_cleanup_timer_sec -= delta
	if _empty_corpse_age_sec >= config.empty_corpse_hard_lifetime_sec:
		return true
	if _empty_corpse_age_sec < config.empty_corpse_min_lifetime_sec or _corpse_cleanup_timer_sec > 0.0:
		return false
	_corpse_cleanup_timer_sec = 0.5
	return _is_outside_active_camera(config.corpse_offscreen_margin_px)


func get_debug_state() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"dead": dead,
		"life_state": int(life_state),
		"pending_payload": _pending_corpse_payload.duplicate(true),
		"corpse_loot": (
			_corpse_loot.get_debug_snapshot()
			if _corpse_loot != null and is_instance_valid(_corpse_loot)
			else {}
		),
		"empty_corpse_age_sec": _empty_corpse_age_sec,
		"corpse_cleanup_timer_sec": _corpse_cleanup_timer_sec,
	}


func _on_corpse_loot_collected(_payload: Dictionary) -> void:
	_enter_empty_corpse_state()


func _enter_empty_corpse_state() -> void:
	life_state = LifeState.EMPTY_CORPSE
	_empty_corpse_age_sec = 0.0
	_corpse_cleanup_timer_sec = 0.0


func _is_outside_active_camera(margin: float) -> bool:
	var viewport := host.get_viewport()
	if viewport == null:
		return false
	var camera := viewport.get_camera_2d()
	if camera == null:
		return false
	var half_size := viewport.get_visible_rect().size * 0.5 / camera.zoom
	var camera_rect := Rect2(camera.get_screen_center_position() - half_size, half_size * 2.0)
	return not camera_rect.grow(maxf(0.0, margin)).has_point(host.global_position)


func _roll_legacy_material_payload() -> int:
	var drop_min: int = max(0, config.material_drop_min)
	var drop_max: int = max(drop_min, config.material_drop_max)
	if drop_max <= 0:
		return 0
	return randi_range(drop_min, drop_max)


func _roll_loot_table_payload() -> Dictionary:
	var rolled := {}
	if config.loot_table.is_empty():
		return rolled
	for entry in config.loot_table:
		if not (entry is Dictionary):
			continue
		var resource_id := str(entry.get("resource_id", entry.get("id", ""))).strip_edges()
		if resource_id.is_empty():
			continue
		var chance := clampf(float(entry.get("chance", 1.0)), 0.0, 1.0)
		if chance < 1.0 and randf() > chance:
			continue
		var min_amount: int = max(0, int(entry.get("min", entry.get("amount", 0))))
		var max_amount: int = max(min_amount, int(entry.get("max", min_amount)))
		if max_amount <= 0:
			continue
		var amount := randi_range(min_amount, max_amount)
		if amount <= 0:
			continue
		var key := StringName(resource_id)
		rolled[key] = int(rolled.get(key, 0)) + amount
	if not rolled.is_empty():
		print("ENEMY LOOT ROLLED: ", host.enemy_name, " table=", config.loot_table_id, " drops=", rolled)
	return rolled


func _structured_payload_has_loot(payload: Dictionary) -> bool:
	return not (payload.get("resource_ledger", {}) as Dictionary).is_empty() \
		or not (payload.get("vault_recovery", {}) as Dictionary).is_empty() \
		or int(payload.get("legacy_materials", 0)) > 0 \
		or not (payload.get("items", []) as Array).is_empty()
