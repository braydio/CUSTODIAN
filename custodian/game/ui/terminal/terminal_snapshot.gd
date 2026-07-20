extends RefCounted
class_name TerminalSnapshot

const TerminalFidelityPolicyScript := preload("res://game/ui/terminal/terminal_fidelity_policy.gd")

var _fidelity_policy: TerminalFidelityPolicy = TerminalFidelityPolicyScript.new()


func build(ui: Node) -> Dictionary:
	var sectors := collect_sectors(ui)
	var operator_context := collect_operator_context(ui, sectors)
	_enrich_sector_diagnostics(ui, sectors, operator_context)
	var enemies := collect_enemies(ui)
	var wave := collect_wave(ui)
	var director := get_local_director_status(ui)
	var contract := collect_contract(ui)
	var game_state := get_game_state(ui)
	var power_pct := get_power_utilization_pct(ui)
	var power_status := get_power_status(ui)
	var terminal_mode: StringName = &"command" if bool(operator_context.get("command_center_occupied", false)) else &"field"
	var base_fidelity := _fidelity_policy.resolve(terminal_mode, sectors)
	var arrn := collect_arrn(ui, String(base_fidelity).to_upper())
	var fidelity := _fidelity_policy.resolve(terminal_mode, sectors, arrn)
	var simulation_tick := int(game_state.get("tick")) if game_state != null and "tick" in game_state else Engine.get_physics_frames()
	var simulation_ticks_per_second := 60
	var system_counts := _collect_system_counts(sectors)
	return {
		"simulation_tick": simulation_tick,
		"simulation_seconds": float(simulation_tick) / float(simulation_ticks_per_second),
		"simulation_rate": Engine.time_scale,
		"time": _format_simulation_time(float(simulation_tick) / float(simulation_ticks_per_second)),
		"terminal_mode": terminal_mode,
		"fidelity": fidelity,
		"archive_state": resolve_archive_state(ui),
		"operator_location": StringName(String(operator_context.get("operator_location", "FIELD"))),
		"command_center_occupied": bool(operator_context.get("command_center_occupied", false)),
		"systems_compromised_count": int(system_counts.get("compromised", 0)),
		"systems_offline_count": int(system_counts.get("offline", 0)),
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
		"power_status": power_status,
		"infrastructure": collect_infrastructure(ui),
		"arrn": arrn,
		"tactical_entities": collect_tactical_entities(ui),
		"vault": collect_vault(ui),
	}


func collect_infrastructure(ui: Node) -> Array[Dictionary]:
	var registry := ui.get_node_or_null("/root/InfrastructureRegistry")
	if registry != null and registry.has_method("get_structure_snapshot"):
		var snapshot = registry.call("get_structure_snapshot")
		if snapshot is Array:
			var result: Array[Dictionary] = []
			for entry in snapshot:
				if entry is Dictionary:
					result.append((entry as Dictionary).duplicate(true))
			return result
	return []


func collect_sectors(ui: Node) -> Array[Dictionary]:
	var sectors: Array[Dictionary] = []
	for node in ui.get_tree().get_nodes_in_group("sector"):
		if not (node is Sector):
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
		if "sector_type" in node:
			entry["sector_type"] = str(node.get("sector_type"))
		if "effective_output" in node:
			entry["effective_output"] = snapped(float(node.get("effective_output")) * 100.0, 0.1)
		if "power_priority" in node:
			entry["power_priority"] = int(node.get("power_priority"))
		if "power" in node and "standard_power_required" in node:
			entry["power_allocated"] = snapped(float(node.get("power")), 0.1)
			entry["power_standard"] = snapped(float(node.get("standard_power_required")), 0.1)
			entry["power_margin"] = snapped(float(node.get("power")) - float(node.get("standard_power_required")), 0.1)
		entry["strategic_priority"] = int(entry.get("power_priority", 0)) >= 85
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


func collect_arrn(ui: Node, requested_fidelity: String = "FULL") -> Dictionary:
	var arrn_manager := ui.get_node_or_null("/root/ARRNManager")
	if arrn_manager == null or not arrn_manager.has_method("get_snapshot"):
		return {}
	var snapshot = arrn_manager.call("get_snapshot", requested_fidelity)
	return snapshot if snapshot is Dictionary else {}


func collect_operator_context(ui: Node, sectors: Array[Dictionary]) -> Dictionary:
	var operator := ui.get_node_or_null("/root/GameRoot/World/Operator") as Node2D
	if operator == null:
		return {
			"operator_location": "UNAVAILABLE",
			"command_center_occupied": false,
		}
	var location := _nearest_sector_name(operator.global_position, sectors)
	var command_center_occupied := false
	for terminal in ui.get_tree().get_nodes_in_group("command_terminal"):
		if not (terminal is Node2D):
			continue
		if terminal.has_method("grants_command_mode") and not bool(terminal.call("grants_command_mode")):
			continue
		var interaction_distance := 88.0
		if terminal.has_method("get_interaction_distance"):
			interaction_distance = float(terminal.call("get_interaction_distance"))
		if operator.global_position.distance_to((terminal as Node2D).global_position) <= interaction_distance + 12.0:
			command_center_occupied = true
			break
	return {
		"operator_location": location,
		"command_center_occupied": command_center_occupied,
		"operator_position": operator.global_position,
	}


func resolve_archive_state(ui: Node) -> StringName:
	var archive := ui.get_node_or_null("/root/ArchiveManager")
	if archive == null:
		return &"unavailable"
	for method_name in [&"get_terminal_state", &"get_archive_state", &"get_status"]:
		if not archive.has_method(method_name):
			continue
		var state: Variant = archive.call(method_name)
		if state is Dictionary:
			state = (state as Dictionary).get("state", "unavailable")
		var normalized := String(state).strip_edges().to_lower()
		if not normalized.is_empty():
			return StringName(normalized)
	return &"unavailable"


func _enrich_sector_diagnostics(ui: Node, sectors: Array[Dictionary], operator_context: Dictionary) -> void:
	var operator_location := String(operator_context.get("operator_location", ""))
	for sector in sectors:
		sector["operator_present"] = String(sector.get("name", "")) == operator_location
		sector["hostile_count"] = 0
		sector["hostile_objective_active"] = false
		var state := String(sector.get("status", "")).to_upper()
		sector["unresolved_critical_incident"] = state.contains("CRITICAL") or state.contains("BREACH") or state.contains("OFFLINE")
	for enemy in ui.get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var sector_index := _nearest_sector_index((enemy as Node2D).global_position, sectors)
		if sector_index < 0:
			continue
		var sector: Dictionary = sectors[sector_index]
		sector["hostile_count"] = int(sector.get("hostile_count", 0)) + 1
		var objective := ""
		var alerted := false
		if enemy.has_method("get_behavior_snapshot"):
			var behavior: Variant = enemy.call("get_behavior_snapshot")
			if behavior is Dictionary:
				var blackboard: Dictionary = (behavior as Dictionary).get("blackboard", {})
				objective = String(blackboard.get("objective_type", "")).to_lower()
				alerted = bool(blackboard.get("alerted", false))
		sector["hostile_objective_active"] = bool(sector.get("hostile_objective_active", false)) or alerted or objective not in ["", "none", "idle"]
		sectors[sector_index] = sector


func _collect_system_counts(sectors: Array[Dictionary]) -> Dictionary:
	var compromised := 0
	var offline := 0
	for sector in sectors:
		var state := "%s %s" % [String(sector.get("status", "")), String(sector.get("power_tier", ""))]
		state = state.to_upper()
		if state.contains("OFFLINE") or state.contains("DESTROYED"):
			offline += 1
		if state.contains("BREACH") or state.contains("DAMAGED") or state.contains("CRITICAL"):
			compromised += 1
	return {"compromised": compromised, "offline": offline}


func _nearest_sector_name(position: Vector2, sectors: Array[Dictionary]) -> String:
	var index := _nearest_sector_index(position, sectors)
	if index < 0:
		return "FIELD"
	return String(sectors[index].get("name", "FIELD"))


func _nearest_sector_index(position: Vector2, sectors: Array[Dictionary]) -> int:
	var nearest_index := -1
	var nearest_distance := INF
	for index in range(sectors.size()):
		var sector: Dictionary = sectors[index]
		if not sector.get("world_pos", null) is Vector2:
			continue
		var distance := position.distance_squared_to(sector["world_pos"])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index


func _format_simulation_time(seconds: float) -> String:
	var whole_seconds := maxi(0, int(floor(seconds)))
	return "%02d:%02d:%02d" % [whole_seconds / 3600, (whole_seconds % 3600) / 60, whole_seconds % 60]
