extends RefCounted
class_name SunderedKeepLandmarkIntentBuilder

const INTENT_NODE := preload(
	"res://game/world/procgen/intent/worldgen_intent_node.gd"
)
const INTENT_EDGE := preload(
	"res://game/world/procgen/intent/worldgen_intent_edge.gd"
)

const LANDMARK_ID := "sundered_keep_frontage"
const FRONTAGE_TAG := "sundered_keep_frontage_generated"


func add_sundered_keep_intent(
	graph,
	context: Dictionary
) -> Dictionary:
	if graph == null or graph.nodes.is_empty():
		return {}
	var terminal = _find_terminal(graph)
	if terminal == null:
		return {}
	var map_size: Vector2i = context.get("map_size", graph.map_size)
	var entry_min_y := clampi(
		int(round(float(map_size.y) * 0.25)),
		28,
		map_size.y - 24
	)
	terminal.cell = Vector2i(
		terminal.cell.x,
		maxi(terminal.cell.y, entry_min_y)
	)
	terminal.kind = INTENT_NODE.NodeKind.ASCENT_BEAT
	if not terminal.tags.has("sundered_keep_frontage_entry"):
		terminal.tags.append("sundered_keep_frontage_entry")

	var seed := int(context.get("seed", graph.seed))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed ^ 0x5A4B31D7
	var gate_x := clampi(
		int(round(float(map_size.x) * 0.78)) + rng.randi_range(-8, 8),
		16,
		map_size.x - 10
	)
	var gate := Vector2i(
		gate_x,
		clampi(18 + rng.randi_range(-1, 2), 16, map_size.y - 12)
	)
	var lateral_sign := 1 if gate.x >= terminal.cell.x else -1
	var delta: Vector2i = gate - terminal.cell
	var overlook: Vector2i = terminal.cell + Vector2i(
		int(round(float(delta.x) * 0.28)),
		int(round(float(delta.y) * 0.28)) + rng.randi_range(-2, 2)
	)
	var frontage: Vector2i = terminal.cell + Vector2i(
		int(round(float(delta.x) * 0.60)),
		int(round(float(delta.y) * 0.60)) + rng.randi_range(-2, 2)
	)
	var compression: Vector2i = terminal.cell + Vector2i(
		int(round(float(delta.x) * 0.84)),
		int(round(float(delta.y) * 0.72))
	)
	overlook = _clamp_cell(overlook, map_size, 6)
	frontage = _clamp_cell(frontage, map_size, 6)
	compression = _clamp_cell(compression, map_size, 6)
	gate = _clamp_cell(gate, map_size, 16)

	var overlook_node = _make_node(
		"sundered_keep_overlook",
		INTENT_NODE.NodeKind.VISTA,
		overlook,
		8,
		terminal.ascent_rank + 1,
		true,
		["vista", "fortress", FRONTAGE_TAG, "first_reveal"]
	)
	var frontage_node = _make_node(
		"sundered_keep_outer_wall",
		INTENT_NODE.NodeKind.ASCENT_BEAT,
		frontage,
		9,
		terminal.ascent_rank + 2,
		true,
		["fortress", FRONTAGE_TAG, "outer_wall_traverse"]
	)
	var compression_node = _make_node(
		"sundered_keep_gate_compression",
		INTENT_NODE.NodeKind.MAIN_ROUTE,
		compression,
		6,
		terminal.ascent_rank + 3,
		true,
		["fortress", FRONTAGE_TAG, "gate_compression"]
	)
	var gate_node = _make_node(
		LANDMARK_ID,
		INTENT_NODE.NodeKind.EXIT_GATE,
		gate,
		7,
		terminal.ascent_rank + 4,
		true,
		[
			"vista",
			"fortress",
			"campaign_ingress",
			"high_ground",
			FRONTAGE_TAG,
		]
	)
	for node in [
		overlook_node,
		frontage_node,
		compression_node,
		gate_node,
	]:
		graph.add_node(node)

	var route_nodes := [
		terminal,
		overlook_node,
		frontage_node,
		compression_node,
		gate_node,
	]
	var route_edges: Array = []
	for index in range(route_nodes.size() - 1):
		var edge := INTENT_EDGE.new()
		edge.id = "%s_to_%s" % [
			route_nodes[index].id,
			route_nodes[index + 1].id,
		]
		edge.from_id = route_nodes[index].id
		edge.to_id = route_nodes[index + 1].id
		edge.kind = INTENT_EDGE.EdgeKind.MAIN_ASCENT
		edge.width_tiles = 9 if index < route_nodes.size() - 2 else 7
		edge.target_slope = 1
		edge.tags = [
			"primary_route",
			"fortress_approach",
			"scenic",
			FRONTAGE_TAG,
		]
		graph.add_edge(edge)
		route_edges.append(edge)

	var side_offset := Vector2i(
		-lateral_sign * rng.randi_range(10, 15),
		rng.randi_range(7, 11)
	)
	var pocket_cell := _clamp_cell(frontage + side_offset, map_size, 7)
	var pocket_node = _make_node(
		"sundered_keep_side_pocket",
		INTENT_NODE.NodeKind.BRANCH,
		pocket_cell,
		rng.randi_range(5, 8),
		frontage_node.ascent_rank,
		false,
		[FRONTAGE_TAG, "side_pocket", "optional"]
	)
	graph.add_node(pocket_node)
	var pocket_edge := INTENT_EDGE.new()
	pocket_edge.id = "%s_to_%s" % [frontage_node.id, pocket_node.id]
	pocket_edge.from_id = frontage_node.id
	pocket_edge.to_id = pocket_node.id
	pocket_edge.kind = INTENT_EDGE.EdgeKind.BRANCH_PATH
	pocket_edge.width_tiles = 5
	pocket_edge.target_slope = 1
	pocket_edge.tags = [FRONTAGE_TAG, "side_pocket"]
	graph.add_edge(pocket_edge)

	return {
		"landmark_node": gate_node,
		"entry_node": terminal,
		"route_nodes": route_nodes,
		"route_edges": route_edges,
		"side_pocket_node": pocket_node,
		"side_pocket_edge": pocket_edge,
		"fortress_outward_direction": Vector2i.UP,
	}


func _find_terminal(graph):
	for index in range(graph.nodes.size() - 1, -1, -1):
		var node = graph.nodes[index]
		if node.kind == INTENT_NODE.NodeKind.EXIT_GATE:
			return node
	return graph.nodes.back()


func _make_node(
	node_id: String,
	kind: int,
	cell: Vector2i,
	radius_tiles: int,
	ascent_rank: int,
	required: bool,
	tags: Array[String]
):
	var node := INTENT_NODE.new()
	node.id = node_id
	node.kind = kind
	node.cell = cell
	node.radius_tiles = radius_tiles
	node.runtime_height = 1
	node.ascent_rank = ascent_rank
	node.required = required
	node.tags = tags
	return node


func _clamp_cell(
	cell: Vector2i,
	map_size: Vector2i,
	margin: int
) -> Vector2i:
	return Vector2i(
		clampi(cell.x, margin, map_size.x - margin - 1),
		clampi(cell.y, margin, map_size.y - margin - 1)
	)
