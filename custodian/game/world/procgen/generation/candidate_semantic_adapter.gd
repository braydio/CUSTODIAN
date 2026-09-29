extends RefCounted

## Builds custodian.procgen_candidate_semantic_model.v1 snapshots: a
## deterministic, data-only projection of an already-generated candidate.
##
## This is the one seam allowed to touch the live candidate Node/TileMap and
## the ingress placement subsystem. It never duplicates or reinterprets their
## logic; it captures each fact once so CandidateEvaluator's snapshot-based
## functions never need live references afterward.

const WORLD_INGRESS_SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")

const SCHEMA := "custodian.procgen_candidate_semantic_model.v1"
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## seed_identity is caller-supplied provenance (contract seed, attempt index,
## attempt seed, ...); it is carried through unchanged for fingerprinting and
## later comparison, never interpreted here.
func build_snapshot(map_instance: Node, level_data: Dictionary, seed_identity: Dictionary = {}) -> Dictionary:
	var map_size := _resolve_map_size(map_instance, level_data)
	var walkable_cells := {}
	var elevation_blocked_edges := {}
	var has_map_instance := map_instance != null and _get_procgen_node(map_instance) != null

	if has_map_instance and map_size != Vector2i.ZERO:
		for x in range(map_size.x):
			for y in range(map_size.y):
				var tile := Vector2i(x, y)
				if _is_layout_walkable_tile(map_instance, tile):
					walkable_cells[tile] = true
		for tile_variant: Variant in walkable_cells.keys():
			var tile := tile_variant as Vector2i
			for direction in DIRECTIONS:
				var next := tile + direction
				if not walkable_cells.has(next):
					continue
				if map_instance.has_method("can_traverse_elevation") \
						and not bool(map_instance.call("can_traverse_elevation", tile, next)):
					var blocked: Array = elevation_blocked_edges.get(tile, [])
					blocked.append(next)
					elevation_blocked_edges[tile] = blocked

	var required_ingresses_valid := false
	var required_ingress_failures: Array = []
	if has_map_instance:
		var ingress_validator: Node = WORLD_INGRESS_SPAWNER_SCRIPT.new()
		var ingress_result: Dictionary = ingress_validator.call(
			"validate_required_ingresses",
			level_data,
			map_instance
		) as Dictionary
		ingress_validator.free()
		required_ingresses_valid = bool(ingress_result.get("ok", false))
		required_ingress_failures = (ingress_result.get("failures", []) as Array).duplicate(true)

	var snapshot := {
		"schema": SCHEMA,
		"seed_identity": seed_identity.duplicate(true),
		"map_size": map_size,
		"level_data": level_data,
		"walkable_cells": walkable_cells,
		"elevation_blocked_edges": elevation_blocked_edges,
		"has_map_instance": has_map_instance,
		"required_ingresses_valid": required_ingresses_valid,
		"required_ingress_failures": required_ingress_failures,
	}
	snapshot["fingerprint"] = fingerprint_snapshot(snapshot)
	return snapshot


## Deterministic same-candidate fingerprint over walkable-cell identity and
## the seed/map-size identity fields. Two builds of the same candidate must
## fingerprint identically; contents never change once a snapshot is built.
func fingerprint_snapshot(snapshot: Dictionary) -> String:
	var rows := PackedStringArray()
	var walkable_cells: Dictionary = snapshot.get("walkable_cells", {})
	for tile_variant: Variant in walkable_cells.keys():
		if tile_variant is Vector2i:
			var tile := tile_variant as Vector2i
			rows.append("%d,%d" % [tile.x, tile.y])
	rows.sort()
	var identity := "%s|%s" % [
		str(snapshot.get("map_size", Vector2i.ZERO)),
		str(snapshot.get("seed_identity", {})),
	]
	return str(("\n".join(rows) + "|" + identity).hash())


func _resolve_map_size(map_instance: Node, level_data: Dictionary) -> Vector2i:
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	if map_size != Vector2i.ZERO:
		return map_size
	if map_instance == null:
		return Vector2i.ZERO
	var procgen: Variant = _get_procgen_node(map_instance)
	if procgen == null:
		return Vector2i.ZERO
	return (procgen as Object).get("map_size")


func _is_layout_walkable_tile(map_instance: Node, tile: Vector2i) -> bool:
	if map_instance != null and map_instance.has_method("is_valid_spawn_cell"):
		return bool(map_instance.call("is_valid_spawn_cell", tile))
	if map_instance != null and _get_procgen_node(map_instance) != null:
		return not bool((_get_procgen_node(map_instance) as Object).call("is_full_at", tile))
	return false


func _get_procgen_node(map_instance: Node) -> Variant:
	return map_instance.get("procgen_node") if map_instance != null else null
