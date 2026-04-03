class_name DeerFlowStateSnapshot
extends Node

## Generates minimal game state snapshots for AI analysis.

## Snapshot Schema
## {
##   "tick": int,
##   "phase": string,
##   "sector": string,
##   "threat_level": float,
##   "entities": [],
##   "resources": {},
##   "active_events": [],
##   "difficulty_score": float
## }

signal snapshot_generated(snapshot: Dictionary)


func _ready() -> void:
	add_to_group("deerflow_snapshot")
	print("[DeerFlowStateSnapshot] Initialized")


func generate_snapshot() -> Dictionary:
	var snapshot: Dictionary = {
		"tick": _get_tick(),
		"phase": _get_phase(),
		"sector": _get_current_sector(),
		"threat_level": _get_threat_level(),
		"entities": _get_entity_summary(),
		"resources": _get_resources(),
		"active_events": _get_active_events(),
		"difficulty_score": _calculate_difficulty_score(),
	}
	
	snapshot_generated.emit(snapshot)
	return snapshot


func _get_tick() -> int:
	var gs = _get_game_state()
	if gs:
		return gs.tick
	return 0


func _get_phase() -> String:
	var gs = _get_game_state()
	if gs and gs.has("current_phase"):
		var phases = {0: "CONTRACT_BRIEFING", 1: "FREE_ROAM_PREP", 2: "ASSAULT_ACTIVE", 3: "POST_ASSAULT", 4: "EXFIL"}
		return phases.get(gs.current_phase, "UNKNOWN")
	return "UNKNOWN"


func _get_current_sector() -> String:
	var sectors = get_tree().get_nodes_in_group("sector")
	if sectors.size() > 0:
		return str(_get_node_property(sectors[0], "sector_name", "UNKNOWN"))
	return "UNKNOWN"


func _get_threat_level() -> float:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var base_threat = enemies.size() * 0.5
	
	var turrets = get_tree().get_nodes_in_group("turret")
	var turret_defense = turrets.size() * 0.3
	
	return clampf(base_threat - turret_defense + 1.0, 1.0, 10.0)


func _get_entity_summary() -> Array:
	var entities: Array = []
	
	# Operator
	var operator = get_node_or_null("/root/GameRoot/World/Operator")
	if operator:
		var hp = _get_node_property(operator, "hp", 100)
		var max_hp = _get_node_property(operator, "max_hp", 100)
		entities.append({
			"type": "operator",
			"hp": hp,
			"max_hp": max_hp,
			"alive": true
		})
	
	# Turrets
	var turrets = get_tree().get_nodes_in_group("turret")
	var working_turrets = 0
	var damaged_turrets = 0
	for turret in turrets:
		if turret.has("health"):
			var turret_hp = _get_node_property(turret, "health", 100)
			if turret_hp > 50:
				working_turrets += 1
			else:
				damaged_turrets += 1
	
	entities.append({
		"type": "turret",
		"working": working_turrets,
		"damaged": damaged_turrets,
		"total": turrets.size()
	})
	
	# Enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	var enemy_types: Dictionary = {}
	for enemy in enemies:
		var e_type = str(_get_node_property(enemy, "enemy_type", "drone"))
		enemy_types[e_type] = enemy_types.get(e_type, 0) + 1
	
	entities.append({
		"type": "enemy",
		"count": enemies.size(),
		"types": enemy_types
	})
	
	return entities


func _get_resources() -> Dictionary:
	var gs = _get_game_state()
	var resources = {
		"power": 0,
		"materials": 0,
	}
	
	if gs:
		var power = get_node_or_null("/root/GameRoot/Power")
		if power and power.has("total_power"):
			resources["power"] = _get_node_property(power, "total_power", 0)
		
		resources["materials"] = _get_node_property(gs, "materials", 0)
	
	return resources


func _get_active_events() -> Array:
	# Events currently running in the game
	var active: Array = []
	
	# Check for any time-based effects currently active
	# This would be expanded as events are implemented
	return active


func _calculate_difficulty_score() -> float:
	var threat = _get_threat_level()
	var entities = _get_entity_summary()
	var resources = _get_resources()
	
	# Simple difficulty calculation
	var enemy_factor = 0.0
	var turret_factor = 0.0
	var resource_factor = 0.0
	
	for entity in entities:
		if entity.get("type") == "enemy":
			enemy_factor = entity.get("count", 0) * 0.2
		elif entity.get("type") == "turret":
			turret_factor = entity.get("working", 0) * 0.15
	
	resource_factor = clampf(resources.get("power", 0) / 100.0, 0.0, 1.0)
	
	return clampf(enemy_factor - turret_factor + resource_factor + 1.0, 1.0, 10.0)


func _get_game_state() -> Node:
	var states = get_tree().get_nodes_in_group("game_state")
	if states.size() > 0:
		return states[0]
	return get_node_or_null("/root/GameState")


func _get_node_property(node: Node, property_name: String, default_value: Variant) -> Variant:
	if node == null:
		return default_value
	if node.has_method("get"):
		var value: Variant = node.get(property_name)
		if value != null:
			return value
	return default_value


func get_minimal_json() -> String:
	var snapshot = generate_snapshot()
	return JSON.stringify(snapshot, "  ")
