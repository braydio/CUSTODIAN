extends SceneTree

const LEVEL_DEFINITION_SCRIPT := preload("res://game/world/levels/level_definition.gd")
const SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")


class PocketMap:
	extends Node2D

	var claim_count := 0

	func is_walkable_floor_tile(_tile: Vector2i) -> bool:
		return true

	func claim_world_overlook_pocket(
		center_tile: Vector2i,
		size_tiles: Vector2i,
		_unlock_causeway: Dictionary = {}
	) -> Rect2i:
		claim_count += 1
		return Rect2i(
			center_tile - Vector2i(
				int(size_tiles.x / 2),
				int(size_tiles.y / 2)
			),
			size_tiles
		)


class RetryPocketMap:
	extends PocketMap

	func evaluate_runtime_walkable_connector(
		_start: Vector2, _direction: Vector2i, _width: int, _length: int,
		_connector_id: String, _resource_id: String, _lateral: int = -1
	) -> Dictionary:
		if claim_count == 1:
			return {"ok": false, "reason": "no mainland endpoint within connector budget"}
		return {
			"ok": true, "cells": [Vector2i.ZERO],
			"island_anchor_tile": Vector2i.ZERO, "endpoint_tile": Vector2i.DOWN,
		}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	world.name = "World"
	root.add_child(world)
	var map := Node2D.new()
	map.name = "ProcGenRuntime"
	world.add_child(map)
	var spawner := SPAWNER_SCRIPT.new()
	world.add_child(spawner)
	var definitions := [
		_definition("alpha_level", "alpha_ingress", [[4, 0]], 100),
		_definition("beta_level", "beta_ingress", [[4, 0], [-8, 0]], 90),
	]
	var level_data := {
		"compound_ingress": [Vector2i(20, 20)],
		"player_spawn": Vector2i(4, 4),
	}
	var placed: Array = spawner.call("place_all", level_data, map, world, null, definitions)
	var errors: Array[String] = []
	if placed.size() != 2: errors.append("expected two generated ingresses, got %d" % placed.size())
	var placements := spawner.call("get_last_placements") as Dictionary
	if not placements.has("alpha_level") or not placements.has("beta_level"):
		errors.append("placement diagnostics omitted a level")
	else:
		var alpha := placements.alpha_level as Vector2i
		var beta := placements.beta_level as Vector2i
		if alpha.distance_squared_to(beta) < 100: errors.append("minimum spacing was not honored")
	for ingress in placed:
		if not ingress.is_in_group("generated_world_ingress"): errors.append("generated ingress group missing")
		if String(ingress.get("level_id")).is_empty(): errors.append("generated ingress has no level ID")
	var first_snapshot := placements.duplicate(true)
	for ingress in placed: ingress.queue_free()
	await process_frame
	var repeated: Array = spawner.call("place_all", level_data, map, world, null, definitions)
	if spawner.call("get_last_placements") != first_snapshot: errors.append("placement is not deterministic")
	if repeated.size() != 2: errors.append("repeat placement count changed")
	for ingress in repeated:
		ingress.queue_free()
	await process_frame
	var vista_level_data := {
		"map_size": Vector2i(96, 96),
		"compound_ingress": [Vector2i(48, 48)],
	}
	var vista_definitions := [
		_overlook_definition(),
	]
	var vista_placed: Array = spawner.call(
		"place_all",
		vista_level_data,
		map,
		world,
		null,
		vista_definitions
	)
	if vista_placed.size() != 1:
		errors.append("north-edge overlook ingress was not placed")
	else:
		var vista_ingress := vista_placed[0] as Node
		if vista_ingress.get_meta(
			"world_ingress_outward_direction",
			Vector2i.ZERO
		) != Vector2i.UP:
			errors.append("north-edge orientation metadata was not propagated")
		var edge_distance := int(
			vista_ingress.get_meta(
				"world_ingress_edge_distance_tiles",
				-1
			)
		)
		if edge_distance < 0 or edge_distance > 8:
			errors.append("north-edge distance metadata was invalid")
	for ingress in vista_placed:
		ingress.queue_free()
	await process_frame
	var pocket_map := PocketMap.new()
	pocket_map.name = "PocketMap"
	world.add_child(pocket_map)
	var authored_vista: Array = spawner.call(
		"place_all",
		vista_level_data,
		pocket_map,
		world,
		null,
		vista_definitions
	)
	if authored_vista.size() != 1:
		errors.append("naturally walkable authored overlook was not placed")
	if pocket_map.claim_count != 1:
		errors.append(
			"naturally walkable north-edge overlook did not claim its mandatory pocket"
		)
	var retry_map := RetryPocketMap.new()
	retry_map.name = "RetryPocketMap"
	world.add_child(retry_map)
	var retried: Array = spawner.call(
		"place_all", vista_level_data, retry_map, world, null,
		[_overlook_definition(true)]
	)
	if retried.size() != 1:
		errors.append("connector-invalid Ash Bell candidate was not retried to placement")
	if retry_map.claim_count != 2:
		errors.append("connector-invalid candidate retry count was not deterministic")
	_finish(errors)


func _definition(level_id: String, ingress_id: String, offsets: Array, priority: int) -> RefCounted:
	var definition: RefCounted = LEVEL_DEFINITION_SCRIPT.new()
	definition.call("configure_from_dictionary", {
		"level_id": level_id,
		"display_name": level_id.to_pascal_case(),
		"target_scene_path": "res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn",
		"tags": ["world_ingress"],
		"ingress": {
			"ingress_id": ingress_id,
			"prompt_text": "ENTER",
			"target_spawn_id": "EntrySpawn",
			"interaction_distance": 92.0,
			"placement": {
				"priority": priority,
				"minimum_spacing_tiles": 10,
				"search_radius_tiles": 14,
				"offset_candidates_tiles": offsets,
			},
		},
	})
	return definition


func _overlook_definition(with_unlock_contract: bool = false) -> RefCounted:
	var definition: RefCounted = LEVEL_DEFINITION_SCRIPT.new()
	definition.call("configure_from_dictionary", {
		"level_id": "vista_level",
		"display_name": "Vista Level",
		"target_scene_path": (
			"res://game/world/approaches/sundered_keep/"
			+ "sundered_keep_approach.tscn"
		),
		"tags": ["world_ingress"],
		"ingress": {
			"ingress_id": "vista_ingress",
			"prompt_text": "ENTER",
			"target_spawn_id": "EntrySpawn",
			"interaction_distance": 92.0,
			"placement": {
				"strategy": "north_edge_overlook",
				"priority": 200,
				"minimum_spacing_tiles": 10,
				"max_edge_distance_tiles": 8,
				"approach_depth_tiles": 10,
				"lateral_search_tiles": 28,
				"unlock_causeway": {
					"initially_isolated": true, "width_tiles": 3,
					"max_length_tiles": 18, "gap_depth_tiles": 2,
				} if with_unlock_contract else {},
			},
		},
	})
	return definition


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[WorldIngressSpawnerSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[WorldIngressSpawnerSmoke] %s" % error)
	quit(1)
