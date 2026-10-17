extends SceneTree

const PLANNER := preload("res://game/world/compound/rooms/persistent_compound_layout_planner.gd")
const WORLD_EXPORT := preload("res://game/world/procgen/generation/accepted_world_export.gd")
const PROFILE_IDS: Array[StringName] = [&"legacy", &"walled_yard", &"connected_bunker"]
const SEEDS := [1, 2, 3, 10, 42, 99, 1337]
const RECT := Rect2i(8, 8, 64, 52)
const INGRESS: Array[Vector2i] = [Vector2i(24, 8), Vector2i(56, 59)]

class FakeIntentGraph extends RefCounted:
	func to_dictionary() -> Dictionary:
		return {}

var _failed := false


func _init() -> void:
	for seed in SEEDS:
		var baseline := _generate(seed)
		_expect(bool(baseline.get("valid", false)), "legacy seed %d must remain valid" % seed)
		for profile_id in PROFILE_IDS:
			var first := _generate(seed, profile_id)
			var second := _generate(seed, profile_id)
			_expect(first == second, "%s seed %d must be repeatable" % [profile_id, seed])
			_expect(bool(first.get("valid", false)), "%s seed %d must be valid" % [profile_id, seed])
			_expect(String(first.get("archetype_id", "")) == String(profile_id), "%s identity must be preserved" % profile_id)
			_expect(String(first.get("layer_id", "")) == "surface", "%s uses the current surface layer" % profile_id)
			_expect(_topology(first) == _topology(baseline), "%s must preserve legacy geometry and connectors for seed %d" % [profile_id, seed])
			_validate_identities(first, profile_id, seed)

	var unknown := _generate(42, &"unknown_profile")
	_expect(not bool(unknown.get("valid", true)), "unknown profile ID must fail closed")
	_expect(String((unknown.get("diagnostics", {}) as Dictionary).get("failure_reason", "")) == "unknown_archetype_id", "unknown profile reports its rejection")
	_validate_level_data_export()
	_finish()


func _generate(seed: int, profile_id: StringName = &"") -> Dictionary:
	var planner := PLANNER.new()
	_expect(planner.load_default_graph(), "graph and profile catalog must load")
	return planner.generate_layout(seed, RECT, INGRESS, profile_id)


func _topology(layout: Dictionary) -> Dictionary:
	var rooms: Array[Dictionary] = []
	for value in layout.get("rooms", []):
		var room := (value as Dictionary).duplicate(true)
		room.erase("archetype_id")
		room.erase("layer_id")
		room.erase("archetype_profile_version")
		rooms.append(room)
	var connections: Array[Dictionary] = []
	for value in layout.get("connections", []):
		var connection := (value as Dictionary).duplicate(true)
		connection.erase("archetype_id")
		connection.erase("layer_id")
		connection.erase("archetype_profile_version")
		connections.append(connection)
	return {
		"rooms": rooms,
		"connections": connections,
		"corridor_cells": layout.get("corridor_cells", []),
		"courtyard_cells": layout.get("courtyard_cells", []),
		"buildings": layout.get("buildings", []),
		"primary_anchor": layout.get("primary_anchor", Vector2i.ZERO),
		"terminal_anchor": layout.get("terminal_anchor", Vector2i.ZERO),
		"fabricator_anchor": layout.get("fabricator_anchor", Vector2i.ZERO),
		"construction_zone_anchor": layout.get("construction_zone_anchor", Vector2i.ZERO),
	}


func _validate_identities(layout: Dictionary, profile_id: StringName, seed: int) -> void:
	var room_by_id := {}
	for room_variant in layout.get("rooms", []):
		var room := room_variant as Dictionary
		var room_id := String(room.get("id", ""))
		_expect(not room_id.is_empty(), "%s seed %d room IDs must be non-empty" % [profile_id, seed])
		_expect(not room_by_id.has(room_id), "%s seed %d room IDs must be unique" % [profile_id, seed])
		room_by_id[room_id] = room
		_expect(String(room.get("archetype_id", "")) == String(profile_id), "room metadata carries selected archetype")
		_expect(String(room.get("layer_id", "")) == "surface", "room metadata carries current layer")
	var connection_ids := {}
	for connection_variant in layout.get("connections", []):
		var connection := connection_variant as Dictionary
		var connection_id := String(connection.get("id", ""))
		var from_id := String(connection.get("from_room_id", ""))
		var to_id := String(connection.get("to_room_id", ""))
		_expect(not connection_id.is_empty() and not connection_ids.has(connection_id), "connector IDs must be unique")
		connection_ids[connection_id] = true
		_expect(room_by_id.has(from_id) and room_by_id.has(to_id), "connector endpoints must reference existing rooms")
		if room_by_id.has(from_id) and room_by_id.has(to_id):
			_expect(connection_id == "%s__%s" % [from_id, to_id], "connector ID must match its room endpoints")
			_expect((room_by_id[from_id].get("connection_ids", []) as Array).has(connection_id), "source room must retain connector identity")
			_expect((room_by_id[to_id].get("connection_ids", []) as Array).has(connection_id), "target room must retain connector identity")
		_expect(String(connection.get("archetype_id", "")) == String(profile_id), "connector metadata carries selected archetype")
		_expect(String(connection.get("layer_id", "")) == "surface", "connector metadata carries current layer")
	for room_id in room_by_id:
		for connection_id in room_by_id[room_id].get("connection_ids", []):
			_expect(connection_ids.has(String(connection_id)), "room connector list cannot reference a missing connector")


func _validate_level_data_export() -> void:
	var sources := {}
	for entry in WORLD_EXPORT.LEVEL_DATA_SCHEMA:
		sources[String(entry[0])] = {}
	sources["compound_archetype_id"] = "connected_bunker"
	sources["compound_layer_id"] = "surface"
	sources["compound_archetype_profile_version"] = 1
	sources["worldgen_intent_graph"] = FakeIntentGraph.new()
	var data: Dictionary = WORLD_EXPORT.build_level_data(sources)
	_expect(data.get("compound_archetype_id") == "connected_bunker", "level data exports selected archetype")
	_expect(data.get("compound_layer_id") == "surface", "level data exports current layer")
	_expect(data.get("compound_archetype_profile_version") == 1, "level data exports profile version")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		push_error("compound_archetype_profile_smoke failed")
		quit(1)
		return
	print("compound_archetype_profile_smoke passed")
	quit()
