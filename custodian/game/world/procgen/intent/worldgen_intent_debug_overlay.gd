extends Node2D
class_name WorldgenIntentDebugOverlay

@export var tile_size: int = 32
@export var show_nodes: bool = true
@export var show_edges: bool = true
@export var show_regions: bool = true

var graph: WorldgenIntentGraph = null
var reserved_regions: Array[Dictionary] = []


func set_debug_data(p_graph: WorldgenIntentGraph, p_regions: Array[Dictionary]) -> void:
	graph = p_graph
	reserved_regions = p_regions
	queue_redraw()


func _draw() -> void:
	if graph == null:
		return

	if show_edges:
		for edge in graph.edges:
			var from_node: WorldgenIntentNode = graph.get_node_by_id(edge.from_id) as WorldgenIntentNode
			var to_node: WorldgenIntentNode = graph.get_node_by_id(edge.to_id) as WorldgenIntentNode
			if from_node == null or to_node == null:
				continue
			draw_line(_tile_to_local(from_node.cell), _tile_to_local(to_node.cell), Color(0.5, 0.8, 1.0, 0.55), 3.0)

	if show_regions:
		for region in reserved_regions:
			var rect: Rect2i = region.get("rect", Rect2i())
			var color := Color(0.8, 0.7, 0.3, 0.18)
			if String(region.get("kind", "")) == "story_room":
				color = Color(0.8, 0.3, 1.0, 0.22)
			elif String(region.get("kind", "")) == "faction_site":
				color = Color(1.0, 0.35, 0.2, 0.22)
			draw_rect(Rect2(Vector2(rect.position * tile_size), Vector2(rect.size * tile_size)), color, true)

	if show_nodes:
		for node in graph.nodes:
			draw_circle(_tile_to_local(node.cell), 7.0, Color(1.0, 1.0, 0.6, 0.9))


func _tile_to_local(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * tile_size + tile_size / 2, tile.y * tile_size + tile_size / 2)
