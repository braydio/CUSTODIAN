class_name LevelScaffoldRequest
extends RefCounted

var level_id := ""
var display_name := ""
var region := ""
var class_name_value := ""
var spawn_id := "Spawn_Main"
var return_spawn_id := "Return_Main"
var ingress_prompt := ""
var world_context := "campaign_region"
var placement_strategy := "near_compound_ingress"
var placement_offsets: Array[Vector2i] = [Vector2i(8, 0), Vector2i(-8, 0), Vector2i(0, 8), Vector2i(0, -8)]
var interaction_distance := 92.0
var playtest_profile := "movement"
var canvas_size := Vector2i(2048, 2048)
var output_root := ""
var dry_run := false
var register_level := true
var force_generated := false
var adopt_existing := false
var json_report_path := ""
var route_id := ""
var route_node_id := ""
var entry_spawn_id := ""
var exits: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var cache_policy := "keep_during_route"
var state_policy := "session"
var presentation_profile := "gameplay"
var create_route := false
var append_to_route := false
var route_data: Dictionary = {}


func configure(data: Dictionary) -> void:
	level_id = str(data.get("level_id", level_id)).strip_edges().to_snake_case()
	display_name = str(data.get("display_name", display_name)).strip_edges()
	region = str(data.get("region", region)).strip_edges().to_snake_case()
	class_name_value = str(data.get("class_name", class_name_value)).strip_edges()
	if class_name_value.is_empty():
		class_name_value = level_id.to_pascal_case()
	spawn_id = str(data.get("spawn_id", spawn_id)).strip_edges()
	return_spawn_id = str(data.get("return_spawn_id", return_spawn_id)).strip_edges()
	ingress_prompt = str(data.get("ingress_prompt", ingress_prompt)).strip_edges()
	if ingress_prompt.is_empty() and not display_name.is_empty():
		ingress_prompt = "ENTER %s" % display_name.to_upper()
	world_context = str(data.get("world_context", world_context)).strip_edges()
	placement_strategy = str(data.get("placement_strategy", placement_strategy)).strip_edges()
	interaction_distance = float(data.get("interaction_distance", interaction_distance))
	playtest_profile = str(data.get("playtest_profile", playtest_profile)).strip_edges()
	canvas_size = data.get("canvas_size", canvas_size) as Vector2i
	output_root = str(data.get("output_root", output_root)).strip_edges()
	dry_run = bool(data.get("dry_run", dry_run))
	register_level = bool(data.get("register_level", register_level))
	force_generated = bool(data.get("force_generated", force_generated))
	adopt_existing = bool(data.get("adopt_existing", adopt_existing))
	json_report_path = str(data.get("json_report_path", json_report_path)).strip_edges()
	route_id = str(data.get("route_id", route_id)).strip_edges().to_snake_case()
	route_node_id = str(data.get("route_node_id", route_node_id)).strip_edges().to_snake_case()
	entry_spawn_id = str(data.get("entry_spawn_id", spawn_id)).strip_edges()
	cache_policy = str(data.get("cache_policy", cache_policy)).strip_edges()
	state_policy = str(data.get("state_policy", state_policy)).strip_edges()
	presentation_profile = str(data.get("presentation_profile", presentation_profile)).strip_edges()
	create_route = bool(data.get("create_route", create_route))
	append_to_route = bool(data.get("append_to_route", append_to_route))
	exits.assign(data.get("exits", []))
	edges.assign(data.get("edges", []))
	if exits.is_empty():
		exits.append({"exit_id": "return_world", "node_name": "Exit_Main"})
	var offsets: Variant = data.get("placement_offsets", [])
	if offsets is Array and not offsets.is_empty():
		placement_offsets.clear()
		for raw: Variant in offsets:
			if raw is Vector2i:
				placement_offsets.append(raw)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_identifier(level_id, "level_id", errors)
	_validate_identifier(region, "region", errors)
	_validate_node_name(spawn_id, "spawn_id", errors)
	_validate_node_name(return_spawn_id, "return_spawn_id", errors)
	if display_name.is_empty(): errors.append("display_name is required")
	if ingress_prompt.is_empty(): errors.append("ingress_prompt is required")
	if playtest_profile not in ["movement", "combat", "full"]: errors.append("playtest_profile must be movement, combat, or full")
	if canvas_size.x <= 0 or canvas_size.y <= 0: errors.append("canvas_size must be positive")
	if interaction_distance <= 0.0: errors.append("interaction_distance must be positive")
	if cache_policy not in ["destroy_on_exit", "destroy_on_forward_exit", "keep_during_route", "snapshot_and_unload"]: errors.append("invalid cache_policy")
	if state_policy not in ["reset_on_entry", "session", "persistent"]: errors.append("invalid state_policy")
	if create_route and append_to_route: errors.append("create_route and append_to_route are mutually exclusive")
	if (create_route or append_to_route) and route_id.is_empty(): errors.append("route_id is required for route mutation")
	if not route_id.is_empty() and route_node_id.is_empty(): errors.append("route_node_id is required with route_id")
	if not route_id.is_empty(): _validate_identifier(route_id, "route_id", errors)
	if not route_node_id.is_empty(): _validate_identifier(route_node_id, "route_node_id", errors)
	_validate_node_name(entry_spawn_id, "entry_spawn_id", errors)
	var exit_ids := {}
	for exit_data in exits:
		var exit_id := str(exit_data.get("exit_id", ""))
		var node_name := str(exit_data.get("node_name", ""))
		_validate_identifier(exit_id, "exit_id", errors)
		_validate_node_name(node_name, "exit node_name", errors)
		if exit_ids.has(exit_id): errors.append("duplicate exit_id: %s" % exit_id)
		exit_ids[exit_id] = true
	var edge_ids := {}
	for edge in edges:
		for field in ["edge_id", "from_node_id", "exit_id", "to_node_id", "direction"]:
			if str(edge.get(field, "")).is_empty(): errors.append("edge %s is required" % field)
		if str(edge.get("direction", "")) not in ["forward", "back", "lateral", "exfil"]: errors.append("edge has invalid direction")
		var edge_id := str(edge.get("edge_id", ""))
		if edge_ids.has(edge_id): errors.append("duplicate edge_id: %s" % edge_id)
		edge_ids[edge_id] = true
	return errors


func _validate_identifier(value: String, label: String, errors: PackedStringArray) -> void:
	if value.is_empty():
		errors.append("%s is required" % label)
		return
	if not value.is_valid_identifier() or value != value.to_snake_case():
		errors.append("%s must be a snake_case identifier" % label)


func _validate_node_name(value: String, label: String, errors: PackedStringArray) -> void:
	if value.is_empty() or value.validate_node_name() != value:
		errors.append("%s must be a valid node name" % label)
