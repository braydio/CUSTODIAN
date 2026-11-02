extends Node

@export var tile_size: int = 32
@export var cell_size_px := 64.0
@export var max_cells := 5000
@export var track_presence := true
@export var presence_sample_interval := 0.50

# Legacy channel storage remains available to the F9 overlay and existing callers.
var heat: Dictionary = {}
var active_channel: String = "presence"

var cells: Dictionary = {}
var event_type_counts: Dictionary = {}
var total_samples := 0
var _presence_accum := 0.0


func _process(delta: float) -> void:
	if not track_presence:
		return

	_presence_accum += maxf(delta, 0.0)
	if _presence_accum < maxf(presence_sample_interval, 0.01):
		return

	_presence_accum = 0.0
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D:
		add_event((player as Node2D).global_position, &"presence", 1.0)

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		observatory.call(
			"set_gauge",
			"heat_player_presence_cells",
			get_hot_cells("presence", 0.01).size()
		)


func add(
	world_position: Vector2,
	event_type: StringName = &"presence",
	weight: float = 1.0
) -> void:
	add_event(world_position, event_type, weight)


func add_event(
	world_position: Vector2,
	event_type: StringName,
	weight: float = 1.0,
	data: Dictionary = {}
) -> void:
	if not is_finite(weight):
		return

	var cell := _world_to_cell(world_position)
	var key := _cell_key(cell)
	if cells.size() >= maxi(max_cells, 0) and not cells.has(key):
		return

	var now := _get_uptime_sec()
	if not cells.has(key):
		var origin := _cell_origin(cell)
		cells[key] = {
			"cell": {"x": cell.x, "y": cell.y},
			"world": {"x": origin.x, "y": origin.y},
			"total": 0.0,
			"sample_count": 0,
			"first_seen_sec": now,
			"last_seen_sec": now,
			"by_type": {},
		}

	var type_key := String(event_type)
	var entry := cells[key] as Dictionary
	entry["total"] = float(entry.get("total", 0.0)) + weight
	entry["sample_count"] = int(entry.get("sample_count", 0)) + 1
	entry["last_seen_sec"] = now

	var by_type := entry.get("by_type", {}) as Dictionary
	by_type[type_key] = float(by_type.get(type_key, 0.0)) + weight
	entry["by_type"] = by_type
	cells[key] = entry

	event_type_counts[type_key] = (
		float(event_type_counts.get(type_key, 0.0)) + weight
	)
	total_samples += 1

	# Preserve the original channel API independently of the reporting grid.
	var legacy_cell := _cell(world_position)
	if not heat.has(legacy_cell):
		heat[legacy_cell] = {}
	var channels := heat[legacy_cell] as Dictionary
	channels[type_key] = float(channels.get(type_key, 0.0)) + weight
	heat[legacy_cell] = channels

	# Event metadata is intentionally not retained in the aggregate snapshot.
	if not data.is_empty():
		pass


func get_summary() -> Dictionary:
	return {
		"schema": "custodian.sector_heatmap.summary.v1",
		"cell_size_px": cell_size_px,
		"cell_count": cells.size(),
		"total_samples": total_samples,
		"event_type_counts": event_type_counts.duplicate(true),
		"top_cells": _get_top_cells(12),
	}


func export_snapshot() -> Dictionary:
	return {
		"schema": "custodian.sector_heatmap.v1",
		"cell_size_px": cell_size_px,
		"cell_count": cells.size(),
		"total_samples": total_samples,
		"event_type_counts": event_type_counts.duplicate(true),
		"cells": cells.duplicate(true),
	}


func clear() -> void:
	cells.clear()
	event_type_counts.clear()
	heat.clear()
	total_samples = 0
	_presence_accum = 0.0


func get_value(position: Vector2, channel: String) -> float:
	var cell := _cell(position)
	if not heat.has(cell):
		return 0.0
	return float((heat[cell] as Dictionary).get(channel, 0.0))


func get_hot_cells(channel: String, minimum := 1.0) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for cell in heat.keys():
		var value := float((heat[cell] as Dictionary).get(channel, 0.0))
		if value >= float(minimum):
			output.append({
				"cell": cell,
				"value": value,
			})
	return output


func get_top_hot_cells(channel: String, limit := 10) -> Array[Dictionary]:
	var hot_cells := get_hot_cells(channel, 0.01)
	hot_cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("value", 0.0)) > float(b.get("value", 0.0))
	)
	if hot_cells.size() <= limit:
		return hot_cells
	return hot_cells.slice(0, limit)


func get_active_channel() -> String:
	return active_channel


func set_active_channel(channel: String) -> void:
	active_channel = channel


func _get_top_cells(limit: int = 12) -> Array:
	var rows: Array = []
	for key in cells.keys():
		var entry := cells[key] as Dictionary
		rows.append({
			"key": key,
			"total": float(entry.get("total", 0.0)),
			"by_type": (entry.get("by_type", {}) as Dictionary).duplicate(true),
			"world": (entry.get("world", {}) as Dictionary).duplicate(true),
		})

	rows.sort_custom(func(a, b):
		return float(a.get("total", 0.0)) > float(b.get("total", 0.0))
	)
	if rows.size() > limit:
		rows.resize(limit)
	return rows


func _get_uptime_sec() -> float:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("get_uptime_sec"):
		return float(observatory.call("get_uptime_sec"))
	return float(Time.get_ticks_msec()) / 1000.0


func _world_to_cell(position: Vector2) -> Vector2i:
	var size := maxf(cell_size_px, 1.0)
	return Vector2i(
		floori(position.x / size),
		floori(position.y / size)
	)


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _cell_origin(cell: Vector2i) -> Vector2:
	return Vector2(
		float(cell.x) * cell_size_px,
		float(cell.y) * cell_size_px
	)


func _cell(pos: Vector2) -> Vector2i:
	var size := maxi(tile_size, 1)
	return Vector2i(
		floori(pos.x / float(size)),
		floori(pos.y / float(size))
	)
