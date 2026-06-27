extends Node

@export_range(0.05, 2.0, 0.01) var refresh_seconds: float = 0.25
@export var max_actor_snapshots: int = 48

var _elapsed := 0.0


func _process(delta: float) -> void:
	var bus := _debug_bus()
	if bus == null or not bool(bus.get("enabled")):
		return
	_elapsed += delta
	if _elapsed < refresh_seconds:
		return
	_elapsed = 0.0
	_collect(bus)


func _collect(bus: Node) -> void:
	bus.call("set_category", "WORLD", _collect_world_snapshot())
	bus.call("set_category", "SECTORS", _collect_sector_snapshots())
	bus.call("set_category", "COMBAT", _collect_combat_snapshot())
	bus.call("set_category", "ACTORS", _collect_actor_summaries())
	_collect_selected_entity(bus)

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("get_recent_events"):
		var recent = observatory.call("get_recent_events", "", 25)
		if recent is Array:
			bus.call("import_observatory_events", recent)


func _collect_world_snapshot() -> Dictionary:
	var procgen := get_tree().get_first_node_in_group("procgen_tilemap")
	var snapshot := {
		"seed": "unknown",
		"profile": "unknown",
		"map_size": "unknown",
		"terrain_connectivity": true,
		"terrain_fallback": false,
		"required_cell_count": 0,
		"missing_required_count": 0,
		"rescue_carved_cells": 0,
		"generation_mode": "unknown",
	}
	if procgen == null:
		return snapshot

	if procgen.get("procgen_node") != null:
		var procgen_node = procgen.get("procgen_node")
		snapshot["seed"] = procgen_node.get("seed") if _object_has_property(procgen_node, "seed") else "unknown"
		snapshot["map_size"] = procgen_node.get("map_size") if _object_has_property(procgen_node, "map_size") else "unknown"
	if procgen.has_method("get_planet_world_profile"):
		var profile = procgen.call("get_planet_world_profile")
		if profile is Dictionary:
			snapshot["profile"] = str(profile.get("profile_id", profile.get("planet_key", "world_profile")))
	if procgen.has_method("get_level_data"):
		var level_data = procgen.call("get_level_data")
		if level_data is Dictionary:
			var terrain: Dictionary = level_data.get("terrain_builder", {})
			var summary: Dictionary = terrain.get("summary", {})
			snapshot["terrain_connectivity"] = bool(terrain.get("connectivity_ok", true))
			snapshot["terrain_fallback"] = bool(terrain.get("fallback_used", false))
			snapshot["required_cell_count"] = int(summary.get("required_cell_count", 0))
			snapshot["missing_required_count"] = int(summary.get("missing_required_count", 0))
			snapshot["rescue_carved_cells"] = int(summary.get("rescue_carved_cells", 0))
			snapshot["generation_mode"] = str(summary.get("generation_mode", "unknown"))
	return snapshot


func _collect_sector_snapshots() -> Array[Dictionary]:
	var sectors: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("structure"):
		if not (node is Node2D):
			continue
		var entry := {
			"name": str(node.get("sector_name") if _object_has_property(node, "sector_name") else node.name),
			"threat": "UNKNOWN",
			"enemy_count": 0,
			"power": "UNKNOWN",
			"defenses": "?",
			"damage_pct": 0,
			"objective": str(node.get("objective") if _object_has_property(node, "objective") else ""),
			"pathable": true,
		}
		if _object_has_property(node, "current_health") and _object_has_property(node, "max_health"):
			var hp := float(node.get("current_health"))
			var max_hp := maxf(1.0, float(node.get("max_health")))
			entry["damage_pct"] = int(round((1.0 - clampf(hp / max_hp, 0.0, 1.0)) * 100.0))
		if _object_has_property(node, "power"):
			entry["power"] = "ON" if float(node.get("power")) > 0.0 else "OFF"
		sectors.append(entry)
	sectors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return sectors


func _collect_combat_snapshot() -> Dictionary:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var projectiles := get_tree().get_nodes_in_group("projectile")
	var operator := get_node_or_null("/root/GameRoot/World/Operator")
	var heat := 0.0
	var ammo := ""
	if operator != null and operator.has_method("get_weapon_status"):
		var weapon_status: Dictionary = operator.call("get_weapon_status")
		heat = float(weapon_status.get("heat", 0.0))
		ammo = "%s/%s + %s" % [
			str(weapon_status.get("magazine_loaded", 0)),
			str(weapon_status.get("magazine_size", 0)),
			str(weapon_status.get("reserve_ammo", 0)),
		]
	return {
		"enemies_alive": enemies.size(),
		"projectiles": projectiles.size(),
		"operator_heat": heat,
		"operator_ammo": ammo,
		"slowmo": bool(_debug_bus().get("debug_overrides").get("slowmo", false)) if _debug_bus() != null else false,
	}


func _collect_actor_summaries() -> Array[Dictionary]:
	var actors: Array[Dictionary] = []
	for group_name in ["enemy", "turret", "player"]:
		for actor in get_tree().get_nodes_in_group(group_name):
			if not (actor is Node2D):
				continue
			actors.append(_actor_snapshot(actor as Node2D, group_name))
			if actors.size() >= max_actor_snapshots:
				return actors
	return actors


func _collect_selected_entity(bus: Node) -> void:
	var selected = bus.get("selected_entity")
	if selected is Node2D and is_instance_valid(selected):
		bus.call("set_selected_entity_snapshot", _actor_snapshot(selected as Node2D, "selected"))


func _actor_snapshot(actor: Node2D, group_name: String) -> Dictionary:
	var snapshot := {
		"node": actor.name,
		"group": group_name,
		"path": str(actor.get_path()),
		"position": actor.global_position,
	}
	if _object_has_property(actor, "health"):
		snapshot["hp"] = actor.get("health")
	if _object_has_property(actor, "max_health"):
		snapshot["max_hp"] = actor.get("max_health")
	if _object_has_property(actor, "target"):
		var target = actor.get("target")
		snapshot["target"] = str(target.name) if target is Node else "none"
	if actor.has_method("get_behavior_snapshot"):
		var behavior = actor.call("get_behavior_snapshot")
		if behavior is Dictionary:
			snapshot["behavior"] = behavior
	if actor.has_method("get_weapon_status"):
		var weapon = actor.call("get_weapon_status")
		if weapon is Dictionary:
			snapshot["weapon"] = weapon
	return snapshot


func _debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false
