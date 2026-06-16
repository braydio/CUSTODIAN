extends RefCounted
class_name AscentSpineBuilder

const IntentGraphScript := preload("res://game/world/procgen/intent/worldgen_intent_graph.gd")
const IntentNodeScript := preload("res://game/world/procgen/intent/worldgen_intent_node.gd")
const IntentEdgeScript := preload("res://game/world/procgen/intent/worldgen_intent_edge.gd")

const DEFAULT_ROUTE_BEATS := 7


func build(context: Dictionary):
	var graph := IntentGraphScript.new()
	graph.seed = int(context.get("seed", 0))
	graph.map_size = context.get("map_size", Vector2i(160, 160))
	graph.origin_cell = context.get("origin_cell", Vector2i(graph.map_size.x / 2, graph.map_size.y - 12))

	var profile = context.get("world_progress_profile", null)
	var rng := RandomNumberGenerator.new()
	rng.seed = graph.seed ^ 0xA5C70D1A

	var beat_count := maxi(1, int(context.get("route_beat_count", DEFAULT_ROUTE_BEATS)))
	var spawn = _make_node("spawn", IntentNodeScript.NodeKind.SPAWN, graph.origin_cell, 8, 0, 0, true)
	_apply_progress(spawn, profile, graph.seed)
	graph.add_node(spawn)

	var previous_id = spawn.id
	for index in range(1, beat_count + 1):
		var t := float(index) / float(beat_count)
		var y := lerpf(float(graph.origin_cell.y), 12.0, t)
		var x_wave := sin(t * PI * 2.5 + float(graph.seed % 17)) * float(graph.map_size.x) * 0.18
		var x_noise := rng.randi_range(-10, 10)
		var x := clampi(int(float(graph.origin_cell.x) + x_wave + x_noise), 12, graph.map_size.x - 13)
		var cell := Vector2i(x, clampi(int(y), 10, graph.map_size.y - 10))
		var ascent_rank := int(round(t * 9.0))
		var runtime_height := clampi(int(floor(float(ascent_rank) / 5.0)), 0, 1)

		var kind := IntentNodeScript.NodeKind.ASCENT_BEAT
		if index == beat_count:
			kind = IntentNodeScript.NodeKind.EXIT_GATE
		var node = _make_node(
			"main_%02d" % index,
			kind,
			cell,
			8 + int(t * 4.0),
			runtime_height,
			ascent_rank,
			true
		)
		_apply_progress(node, profile, graph.seed)
		graph.add_node(node)

		var edge := IntentEdgeScript.new()
		edge.id = "%s_to_%s" % [previous_id, node.id]
		edge.from_id = previous_id
		edge.to_id = node.id
		edge.kind = IntentEdgeScript.EdgeKind.MAIN_ASCENT
		edge.width_tiles = 5 if index < beat_count else 7
		edge.target_slope = runtime_height
		graph.add_edge(edge)

		previous_id = node.id
		if index > 1 and index < beat_count:
			_try_add_branch(graph, node, rng, profile)

	_ensure_required_site_branches(graph, profile)
	return graph


func _make_node(
	node_id: String,
	kind: int,
	cell: Vector2i,
	radius_tiles: int,
	runtime_height: int,
	ascent_rank: int,
	required: bool
):
	var node := IntentNodeScript.new()
	node.id = node_id
	node.kind = kind
	node.cell = cell
	node.radius_tiles = radius_tiles
	node.runtime_height = runtime_height
	node.ascent_rank = ascent_rank
	node.required = required
	return node


func _try_add_branch(graph, parent, rng: RandomNumberGenerator, profile) -> void:
	if rng.randf() > 0.65:
		return

	var side := -1 if rng.randf() < 0.5 else 1
	var distance := rng.randi_range(14, 28)
	var branch_cell = parent.cell + Vector2i(side * distance, rng.randi_range(-8, 8))
	branch_cell.x = clampi(branch_cell.x, 8, graph.map_size.x - 9)
	branch_cell.y = clampi(branch_cell.y, 8, graph.map_size.y - 9)

	var kind_roll := rng.randf()
	var kind := IntentNodeScript.NodeKind.RESOURCE_POCKET
	if kind_roll > 0.75:
		kind = IntentNodeScript.NodeKind.STORY_ROOM
	elif kind_roll > 0.50:
		kind = IntentNodeScript.NodeKind.FACTION_SITE
	elif kind_roll > 0.25:
		kind = IntentNodeScript.NodeKind.VISTA

	var node = _make_node(
		"%s_branch_%d" % [parent.id, graph.nodes.size()],
		kind,
		branch_cell,
		rng.randi_range(5, 10),
		parent.runtime_height,
		parent.ascent_rank,
		false
	)
	_apply_progress(node, profile, graph.seed)
	graph.add_node(node)

	var edge := IntentEdgeScript.new()
	edge.id = "%s_to_%s" % [parent.id, node.id]
	edge.from_id = parent.id
	edge.to_id = node.id
	edge.kind = IntentEdgeScript.EdgeKind.BRANCH_PATH
	if kind == IntentNodeScript.NodeKind.FACTION_SITE:
		edge.kind = IntentEdgeScript.EdgeKind.FACTION_APPROACH
	elif kind == IntentNodeScript.NodeKind.STORY_ROOM:
		edge.kind = IntentEdgeScript.EdgeKind.STORY_APPROACH
	edge.width_tiles = rng.randi_range(3, 5)
	edge.target_slope = node.runtime_height
	graph.add_edge(edge)


func _ensure_required_site_branches(graph, profile) -> void:
	_ensure_site_branch_kind(graph, profile, IntentNodeScript.NodeKind.FACTION_SITE, "faction_site")
	_ensure_site_branch_kind(graph, profile, IntentNodeScript.NodeKind.STORY_ROOM, "story_room")


func _ensure_site_branch_kind(graph, profile, kind: int, label: String) -> void:
	for node in graph.nodes:
		if node.kind == kind:
			return
	var main_nodes: Array = []
	for node in graph.nodes:
		if node.kind == IntentNodeScript.NodeKind.ASCENT_BEAT:
			main_nodes.append(node)
	if main_nodes.is_empty():
		return
	var parent = main_nodes[mini(main_nodes.size() - 1, 2 if kind == IntentNodeScript.NodeKind.FACTION_SITE else 4)]
	var side := -1 if kind == IntentNodeScript.NodeKind.FACTION_SITE else 1
	var branch_cell = parent.cell + Vector2i(side * 22, 0)
	branch_cell.x = clampi(branch_cell.x, 8, graph.map_size.x - 9)
	branch_cell.y = clampi(branch_cell.y, 8, graph.map_size.y - 9)
	var node = _make_node(
		"%s_required_%d" % [label, graph.nodes.size()],
		kind,
		branch_cell,
		8,
		parent.runtime_height,
		parent.ascent_rank,
		false
	)
	_apply_progress(node, profile, graph.seed)
	graph.add_node(node)
	var edge := IntentEdgeScript.new()
	edge.id = "%s_to_%s" % [parent.id, node.id]
	edge.from_id = parent.id
	edge.to_id = node.id
	edge.kind = IntentEdgeScript.EdgeKind.FACTION_APPROACH if kind == IntentNodeScript.NodeKind.FACTION_SITE else IntentEdgeScript.EdgeKind.STORY_APPROACH
	edge.width_tiles = 7
	edge.target_slope = node.runtime_height
	graph.add_edge(edge)


func _apply_progress(node, profile, seed: int) -> void:
	if profile == null or not profile.has_method("get_cell_progress"):
		return
	var progress: Dictionary = profile.call("get_cell_progress", node.cell, seed)
	node.band_id = String(progress.get("band_id", ""))
	node.style_id = String(progress.get("dominant_style", ""))
	node.faction_id = String(progress.get("dominant_faction", ""))
