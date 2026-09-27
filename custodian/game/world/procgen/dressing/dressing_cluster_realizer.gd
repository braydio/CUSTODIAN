extends RefCounted
class_name DressingClusterRealizer


func realize(plan: Dictionary, context: Dictionary, foliage_spawner: ProcgenFoliageSpawner) -> Dictionary:
	var placed := 0
	var failed: Array[Vector2i] = []
	var children: Dictionary = plan.get("child_by_cell", {})
	var cells: Array = children.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y if a.y != b.y else a.x < b.x
	)
	for cell: Vector2i in cells:
		var child: Dictionary = children[cell]
		if foliage_spawner.place_at_kind(context, cell, StringName(child.kind), StringName(child.get("cluster_id", &""))):
			placed += 1
		elif bool(child.get("required", true)):
			failed.append(cell)
	return {"placed_child_count": placed, "failed_required_cells": failed}
