extends SceneTree

const GAME_SCENE_PATH := "res://scenes/game.tscn"
const LEGACY_OPERATOR_POSITION := Vector2(717.45905, -485.33954)
const TEST_SEED := 1773840677
const STARTUP_TIMEOUT_SEC := 300.0

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bootstrap := root.get_node_or_null("WorldContractBootstrap")
	var packed := load(GAME_SCENE_PATH) as PackedScene
	_expect(packed != null, "literal production game.tscn must load")
	if packed == null:
		_finish()
		return
	var game_root := packed.instantiate()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	current_scene = game_root
	if bootstrap != null and bootstrap.has_method("ensure_started"):
		bootstrap.call("ensure_started", TEST_SEED)
	await process_frame

	var game_state := root.get_node_or_null("GameState")
	var deadline := Time.get_ticks_msec() + int(STARTUP_TIMEOUT_SEC * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if game_state != null and (
			bool(game_state.get("contract_ready"))
			or bool(game_state.get("contract_generation_failed"))
		):
			break
		await process_frame

	var terminal := game_state != null and (
		bool(game_state.get("contract_ready"))
		or bool(game_state.get("contract_generation_failed"))
	)
	_expect(terminal, "production ContractMap/ContractWorldLoader boot must reach a terminal contract state before timeout")
	if not terminal:
		_finish()
		return

	var world := game_root.get_node_or_null("World")
	var operator := world.get_node_or_null("Operator") as Node2D if world != null else null
	var loader := game_root.get_node_or_null("ContractWorldLoader")
	var contract_map := world.get_node_or_null("ContractMap") if world != null else null
	var player_nodes := get_nodes_in_group("player")
	var selected_receipt: Dictionary = {}
	if loader != null and loader.has_method("get_operator_placement_receipt"):
		selected_receipt = loader.call("get_operator_placement_receipt") as Dictionary
	var trace: Array = loader.call("get_install_trace") if loader != null and loader.has_method("get_install_trace") else []
	var contract: Dictionary = contract_map.call("get_latest_contract") if contract_map != null and contract_map.has_method("get_latest_contract") else {}
	var map_block: Dictionary = contract.get("map", {}) as Dictionary
	var map := map_block.get("instance") as Node if map_block.get("instance") is Node else null
	var ready := bool(game_state.get("contract_ready"))
	var legacy_match := operator != null and operator.global_position.is_equal_approx(LEGACY_OPERATOR_POSITION)
	var operator_placed := _trace_has_phase(trace, &"operator_placed")
	var sampled_player_differs := player_nodes.size() > 0 and operator != null and player_nodes[0] != operator
	var root_cause := "not_reproduced"
	var failure_reason := String((game_state.get("contract_failure_result") as Dictionary).get("failure_reason", "")) if game_state != null else ""
	if legacy_match and sampled_player_differs:
		root_cause = "wrong_player_identity_sampled"
	elif legacy_match and operator_placed:
		root_cause = "placement_ran_then_was_clobbered"
	elif legacy_match and failure_reason == "no_canonical_safe_spawn":
		root_cause = "placement_skipped_no_canonical_safe_spawn"
	elif legacy_match:
		root_cause = "placement_never_ran_or_canonical_operator_was_missing"
	elif not ready:
		root_cause = "startup_failed_before_placement_acceptance"
	var final_tile := Vector2i.ZERO
	var receipt_round_trip_tile := Vector2i.ZERO
	var ready_detail := _trace_detail(trace, &"contract_ready")
	var placement_validation: Dictionary = ready_detail.get("placement_validation", {}) as Dictionary
	var ready_operator: Dictionary = placement_validation.get("operator", {}) as Dictionary
	var player_spawn_tile := Vector2i.ZERO
	var player_spawn_flags: Dictionary = {}
	var ingress_clearance_rects: Variant = []
	if map != null and map.has_method("_global_to_tile") and operator != null:
		final_tile = map.call("_global_to_tile", operator.global_position)
	var receipt_position: Variant = selected_receipt.get("world_position", Vector2.INF)
	if map != null and map.has_method("_global_to_tile") and receipt_position is Vector2:
		receipt_round_trip_tile = map.call("_global_to_tile", receipt_position)
	if map != null and map.has_method("get_player_spawn"):
		player_spawn_tile = map.call("get_player_spawn")
		player_spawn_flags = {
			"canonical_spawn_valid": map.call("is_valid_spawn_cell", player_spawn_tile),
			"runtime_navigation_walkable": map.call("is_runtime_navigation_walkable", player_spawn_tile),
			"inside_ingress_clearance": map.call("is_inside_world_ingress_dressing_clearance", player_spawn_tile),
		}
		ingress_clearance_rects = map.get("_world_ingress_dressing_clearance_rects")
	var evidence := {
		"scene": game_root.scene_file_path,
		"terminal_ready": ready,
		"terminal_failure": game_state.get("contract_failure_result"),
		"failure_reason": failure_reason,
		"player_group_count": player_nodes.size(),
		"player_group_paths": player_nodes.map(func(node: Node) -> String: return str(node.get_path())),
		"canonical_operator_path": str(operator.get_path()) if operator != null else "missing",
		"canonical_operator_id": operator.get_instance_id() if operator != null else -1,
		"operator_position": operator.global_position if operator != null else Vector2.INF,
		"operator_visible": operator.visible if operator != null else false,
		"operator_process_mode": operator.process_mode if operator != null else Node.PROCESS_MODE_DISABLED,
		"legacy_position_match": legacy_match,
		"root_cause_hypothesis": root_cause,
		"map_path": str(map.get_path()) if map != null else "missing",
		"final_tile": final_tile,
		"ready_operator": ready_operator,
		"ready_placement_validation": placement_validation,
		"receipt_round_trip_tile": receipt_round_trip_tile,
		"player_spawn_tile": player_spawn_tile,
		"player_spawn_flags": player_spawn_flags,
		"ingress_clearance_rects": ingress_clearance_rects,
		"contract_seed": contract.get("contract_seed", -1),
		"map_seed": map_block.get("map_seed", -1),
		"placement_receipt": selected_receipt,
		"install_trace": trace,
		"loader_bound": loader != null and loader.get("_contract_map_node") == contract_map,
	}
	print("GAME_SCENE_OPERATOR_STARTUP_EVIDENCE: %s" % JSON.stringify(evidence))
	_expect(game_root.scene_file_path == GAME_SCENE_PATH, "smoke must instantiate the literal production scene")
	_expect(loader != null and contract_map != null, "production scene must contain ContractWorldLoader and ContractMap")
	_expect(ready, "real production contract install must reach ready")
	_expect(player_nodes.size() == 1, "production boot must expose exactly one player-group identity")
	_expect(operator != null and operator.get_path() == NodePath("/root/GameRoot/World/Operator"), "canonical production Operator identity must exist at the expected path")
	_expect(player_nodes.size() == 1 and player_nodes[0] == operator, "the canonical Operator must be the unique player-group identity")
	_expect(_trace_count(trace, &"contract_generation_received") == 1, "one active generation must have one successful install attempt")
	_expect(operator != null and not legacy_match, "successful production boot must relocate the Operator from the authored placeholder")
	_expect(not selected_receipt.is_empty(), "successful production boot must expose a placement receipt")
	_expect(bool(placement_validation.get("valid", false)), "loader must prove placement consistency immediately before contract_ready")
	_expect(map != null and selected_receipt.get("tile") == receipt_round_trip_tile, "receipt world position must round-trip to its selected canonical tile")
	_expect(ready_operator.get("canonical_position") == selected_receipt.get("world_position"), "contract_ready snapshot must retain the exact selected Operator position")
	_expect(operator != null and operator.visible and operator.process_mode != Node.PROCESS_MODE_DISABLED, "successful production boot must restore Operator visibility and processing")
	_expect(_ordered_phases(trace, [
		&"registered_ingress_placed",
		&"operator_placed",
		&"compound_connection_placed",
		&"archive_resolve_ingress",
		&"camera_refresh",
		&"navigation_rebuilt",
		&"contract_ready",
	]), "production startup phase ordering must preserve ingress, placement, compound, Archive Resolve, camera, navigation, and ready")
	_finish()


func _trace_has_phase(trace: Array, phase: StringName) -> bool:
	for entry_variant in trace:
		if entry_variant is Dictionary and (entry_variant as Dictionary).get("phase") == phase:
			return true
	return false


func _trace_count(trace: Array, phase: StringName) -> int:
	var count := 0
	for entry_variant in trace:
		if entry_variant is Dictionary and (entry_variant as Dictionary).get("phase") == phase:
			count += 1
	return count


func _trace_detail(trace: Array, phase: StringName) -> Dictionary:
	for entry_variant in trace:
		if entry_variant is Dictionary and (entry_variant as Dictionary).get("phase") == phase:
			return (entry_variant as Dictionary).get("detail", {}) as Dictionary
	return {}


func _ordered_phases(trace: Array, phases: Array[StringName]) -> bool:
	var previous_index := -1
	for phase in phases:
		var found_index := -1
		for index in range(trace.size()):
			var entry: Variant = trace[index]
			if entry is Dictionary and (entry as Dictionary).get("phase") == phase:
				found_index = index
				break
		if found_index <= previous_index:
			return false
		previous_index = found_index
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _finish() -> void:
	if _errors.is_empty():
		print("GAME_SCENE_OPERATOR_STARTUP_INTEGRITY_SMOKE: PASS")
		quit(0)
		return
	for message in _errors:
		push_error(message)
	quit(1)
