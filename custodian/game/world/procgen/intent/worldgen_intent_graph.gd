extends RefCounted
class_name WorldgenIntentGraph

const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")

var seed: int = 0
var map_size: Vector2i = Vector2i.ZERO
var origin_cell: Vector2i = Vector2i.ZERO
var nodes: Array = []
var edges: Array = []


func add_node(node) -> void:
	nodes.append(node)


func add_edge(edge) -> void:
	edges.append(edge)


func get_node_by_id(node_id: String):
	for node in nodes:
		if node.id == node_id:
			return node
	return null


func get_required_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for node in nodes:
		if node.required:
			cells.append(node.cell)
	return cells


func get_main_route_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for node in nodes:
		if node.kind == IntentNodeScript.NodeKind.SPAWN \
				or node.kind == IntentNodeScript.NodeKind.MAIN_ROUTE \
				or node.kind == IntentNodeScript.NodeKind.ASCENT_BEAT \
				or node.kind == IntentNodeScript.NodeKind.EXIT_GATE:
			cells.append(node.cell)
	return cells


func to_dictionary() -> Dictionary:
	var node_dicts: Array[Dictionary] = []
	var edge_dicts: Array[Dictionary] = []
	for node in nodes:
		node_dicts.append(node.to_dictionary())
	for edge in edges:
		edge_dicts.append(edge.to_dictionary())
	return {
		"seed": seed,
		"map_size": map_size,
		"origin_cell": origin_cell,
		"nodes": node_dicts,
		"edges": edge_dicts,
	}
