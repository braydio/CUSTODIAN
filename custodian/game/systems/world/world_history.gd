extends Node

@export var max_entries_per_sector: int = 512

var history: Dictionary = {}


func record(sector_id: String, kind: String, position: Vector2, data := {}) -> void:
	var resolved_sector_id := sector_id if not sector_id.is_empty() else infer_sector_id_from_position(position)
	if not history.has(resolved_sector_id):
		history[resolved_sector_id] = []

	var entry := {
		"time": Time.get_ticks_msec(),
		"kind": kind,
		"position": position,
		"data": data if data is Dictionary else {},
	}

	var entries: Array = history[resolved_sector_id]
	entries.append(entry)
	if entries.size() > max_entries_per_sector:
		entries.pop_front()
	history[resolved_sector_id] = entries

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		observatory.call("log_event", "world_history_recorded", {
			"sector_id": resolved_sector_id,
			"kind": kind,
		})


func get_sector_history(sector_id: String) -> Array:
	return (history.get(sector_id, []) as Array).duplicate(true)


func has_event(sector_id: String, kind: String) -> bool:
	for entry in history.get(sector_id, []):
		if String((entry as Dictionary).get("kind", "")) == kind:
			return true
	return false


func infer_sector_id_from_position(position: Vector2) -> String:
	var nearest_name := "global"
	var nearest_dist := INF
	for node in get_tree().get_nodes_in_group("structure"):
		if not (node is Node2D):
			continue
		var sector_name := ""
		if "sector_name" in node:
			sector_name = String(node.get("sector_name"))
		elif node.has_method("get_display_name"):
			sector_name = String(node.call("get_display_name"))
		if sector_name.is_empty():
			continue
		var dist := position.distance_squared_to((node as Node2D).global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_name = _slugify(sector_name)
	return nearest_name


func _slugify(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_")
