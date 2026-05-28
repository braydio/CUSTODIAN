extends RefCounted
class_name TerminalSnapshot


func build(ui: Node) -> Dictionary:
	var sectors := collect_sectors(ui)
	var enemies := collect_enemies(ui)
	var wave := collect_wave(ui)
	var director := get_local_director_status(ui)
	var contract := collect_contract(ui)
	var game_state := get_game_state(ui)
	var power_pct := get_power_utilization_pct(ui)
	return {
		"time": str(Time.get_time_string_from_system()),
		"threat": "%.1f" % float(director.get("threat", 0.0)) if not director.is_empty() else "?",
		"threat_raw": float(director.get("threat", 0.0)) if not director.is_empty() else 0.0,
		"assault": "%s/%s" % [
			str(director.get("lane", "none")).to_upper(),
			str(director.get("objective", "none")).to_upper(),
		] if not director.is_empty() else "?",
		"player_mode": "LIVE",
		"contract_phase": game_state.get_phase_name() if game_state != null else "UNKNOWN",
		"materials": int(game_state.materials) if game_state != null else 0,
		"defense_rating": snapped(float(game_state.defense_rating), 0.1) if game_state != null else 0.0,
		"sectors": sectors,
		"enemies": enemies,
		"wave": wave,
		"contract": contract,
		"power_pct": power_pct,
		"arrn": collect_arrn(ui),
		"tactical_entities": collect_tactical_entities(ui),
		"vault": collect_vault(ui),
	}


func collect_sectors(ui: Node) -> Array[Dictionary]:
	var sectors: Array[Dictionary] = []
	for node in ui.get_tree().get_nodes_in_group("structure"):
		if not (node is Node2D):
			continue
		var entry: Dictionary = {}
		entry["name"] = str(node.get("sector_name") if "sector_name" in node else node.name)
		entry["status"] = str(node.get("state") if "state" in node else "unknown")
		entry["world_pos"] = node.global_position
		if "current_health" in node and "max_health" in node:
			var hp: float = float(node.get("current_health"))
			var hp_max: float = max(1.0, float(node.get("max_health")))
			entry["hp_pct"] = int(round((hp / hp_max) * 100.0))
		if "power_tier" in node:
			entry["power_tier"] = str(node.get("power_tier"))
		if "effective_output" in node:
			entry["effective_output"] = snapped(float(node.get("effective_output")) * 100.0, 0.1)
		if "power_priority" in node:
			entry["power_priority"] = int(node.get("power_priority"))
		if "power" in node and "standard_power_required" in node:
			entry["power_allocated"] = snapped(float(node.get("power")), 0.1)
			entry["power_standard"] = snapped(float(node.get("standard_power_required")), 0.1)
		sectors.append(entry)
	sectors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return sectors


func collect_enemies(ui: Node) -> Dictionary:
	var summary := {"total": 0, "drone": 0, "fast": 0, "heavy": 0, "searching_storage": 0, "carrying_loot": 0}
	for enemy in ui.get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		summary["total"] = int(summary["total"]) + 1
		var enemy_name := str(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name).to_upper()
		if enemy_name.find("FAST") >= 0:
			summary["fast"] = int(summary["fast"]) + 1
		elif enemy_name.find("HEAVY") >= 0:
			summary["heavy"] = int(summary["heavy"]) + 1
		else:
			summary["drone"] = int(summary["drone"]) + 1
		if enemy.has_method("get_behavior_snapshot"):
			var behavior: Dictionary = enemy.call("get_behavior_snapshot")
			var state := str(behavior.get("state", ""))
			if state in ["seek_objective", "open_storage", "steal_resources"]:
				summary["searching_storage"] = int(summary["searching_storage"]) + 1
			var blackboard: Dictionary = behavior.get("blackboard", {})
			if bool(blackboard.get("carrying_loot", false)):
				summary["carrying_loot"] = int(summary["carrying_loot"]) + 1
	return summary


func collect_tactical_entities(ui: Node) -> Dictionary:
	var entities := {
		"operator": [],
		"turrets": [],
		"enemies": [],
	}
	var operator := ui.get_node_or_null("/root/GameRoot/World/Operator")
	if operator and operator is Node2D:
		entities["operator"].append({"pos": operator.global_position})
	for turret in ui.get_tree().get_nodes_in_group("turret"):
		if turret is Node2D:
			entities["turrets"].append({
				"pos": turret.global_position,
				"health": turret.get("health") if "health" in turret else null,
			})
	for enemy in ui.get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D:
			var behavior: Dictionary = enemy.call("get_behavior_snapshot") if enemy.has_method("get_behavior_snapshot") else {}
			var blackboard: Dictionary = behavior.get("blackboard", {}) if behavior is Dictionary else {}
			entities["enemies"].append({
				"pos": enemy.global_position,
				"type": str(enemy.get("enemy_name") if "enemy_name" in enemy else enemy.name),
				"alert_state": bool(blackboard.get("alerted", false)),
				"carrying_loot": bool(blackboard.get("carrying_loot", false)),
				"objective_type": str(blackboard.get("objective_type", "none")),
			})
	return entities


func collect_vault(ui: Node) -> Dictionary:
	var manager := ui.get_node_or_null("/root/VaultManager")
	if manager != null and manager.has_method("get_debug_snapshot"):
		var snapshot = manager.call("get_debug_snapshot")
		if snapshot is Dictionary:
			return snapshot
	return {}


func get_power_utilization_pct(ui: Node) -> float:
	var power_system := ui.get_node_or_null("/root/GameRoot/Power")
	if power_system == null or not power_system.has_method("get_power_status"):
		return 0.0
	var status: Dictionary = power_system.get_power_status()
	var total := float(status.get("total", 0.0))
	var max_value := float(status.get("max", 0.0))
	if max_value <= 0.001:
		return 0.0
	return clampf((total / max_value) * 100.0, 0.0, 100.0)


func get_power_status(ui: Node) -> Dictionary:
	var power_system := ui.get_node_or_null("/root/GameRoot/Power")
	if power_system == null or not power_system.has_method("get_power_status"):
		return {}
	var status = power_system.call("get_power_status")
	return status if status is Dictionary else {}


func collect_wave(ui: Node) -> Dictionary:
	var wave_manager := ui.get_node_or_null("/root/GameRoot/WaveManager")
	if wave_manager and wave_manager.has_method("get_wave_status"):
		var status = wave_manager.call("get_wave_status")
		if status is Dictionary:
			return status
	return {}


func get_game_state(ui: Node) -> Node:
	return ui.get_node_or_null("/root/GameState")


func get_local_director_status(ui: Node) -> Dictionary:
	var director := ui.get_node_or_null("/root/GameRoot/EnemyDirector")
	if director and director.has_method("get_director_status"):
		var status = director.call("get_director_status")
		if status is Dictionary:
			return status
	if director and director.has_method("get_debug_status"):
		var status = director.call("get_debug_status")
		if status is Dictionary:
			return status
	return {}


func collect_contract(ui: Node) -> Dictionary:
	if ui.get("_terminal_contract_snapshot") is Dictionary:
		return ui.get("_terminal_contract_snapshot")
	return {}


func collect_arrn(ui: Node) -> Dictionary:
	var arrn_manager := ui.get_node_or_null("/root/ARRNManager")
	if arrn_manager == null or not arrn_manager.has_method("get_snapshot"):
		return {}
	var snapshot = arrn_manager.call("get_snapshot", "FULL")
	return snapshot if snapshot is Dictionary else {}
