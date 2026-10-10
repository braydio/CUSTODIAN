extends Node
class_name ContractWorldLoader

signal contract_activation_finished(result: Dictionary)

@export var contract_map_path: NodePath = NodePath("/root/GameRoot/World/ContractMap")
@export var world_path: NodePath = NodePath("/root/GameRoot/World")
@export var sectors_container_path: NodePath = NodePath("/root/GameRoot/World/Sectors")
@export var operator_path: NodePath = NodePath("/root/GameRoot/World/Operator")
@export var spawn_nodes_path: NodePath = NodePath("/root/GameRoot/World/SpawnNodes")
@export var command_terminal_path: NodePath = NodePath("/root/GameRoot/World/CommandTerminal")
@export var field_fabricator_path: NodePath = NodePath("/root/GameRoot/World/FieldFabricatorMk1")
@export var fabrication_construction_zone_path: NodePath = NodePath("/root/GameRoot/World/FabricationConstructionZone")
@export var vehicle_root_path: NodePath = NodePath("/root/GameRoot/World")
@export var items_root_path: NodePath = NodePath("/root/GameRoot/World/Items")
@export var camera_path: NodePath = NodePath("/root/GameRoot/World/Camera2D")
@export var navigation_system_path: NodePath = NodePath("/root/GameRoot/NavigationSystem")
@export var runtime_map_container_name: String = "ProcGenRuntime"
@export var hide_static_sectors: bool = true
@export var reposition_operator_from_contract: bool = true
@export var reposition_spawn_nodes_from_contract: bool = true
@export var reposition_terminal_from_contract: bool = true
@export var reposition_construction_population_from_contract: bool = true
@export var reposition_vehicles_from_contract: bool = true
@export var reposition_items_from_contract: bool = true
@export var reposition_camera_from_contract: bool = true
@export var place_arrn_relays_from_contract: bool = true
@export var place_tutorial_resource_nodes_from_contract: bool = true
@export var place_expedition_resource_nodes_from_contract: bool = true
@export var place_gothic_compound_connection: bool = true
@export var place_registered_level_connections: bool = true
@export var place_sundered_keep_connection: bool = true
@export var place_ambient_enemy_camps_from_contract: bool = true
@export var ambient_enemy_spawner_path: NodePath = NodePath("/root/GameRoot/AmbientEnemySpawner")
@export var place_vaultwing_markers_from_contract: bool = true
@export var vaultwing_spawner_path: NodePath = NodePath("/root/GameRoot/VaultwingSpawner")
@export_range(4, 24, 1) var vaultwing_perch_spacing_tiles: int = 10
@export_range(0, 6, 1) var ambient_enemy_camp_count: int = 2
@export_range(8, 96, 1) var ambient_enemy_min_distance_tiles: int = 26
@export_range(8, 128, 1) var ambient_enemy_camp_spacing_tiles: int = 44
@export var place_debug_sundered_keep_gateway: bool = false
@export var debug_start_near_sundered_keep_entrance: bool = false
@export var debug_sundered_keep_start_offset: Vector2 = Vector2(48.0, 0.0)
@export_range(0, 7, 1) var tutorial_resource_node_count: int = 3
@export_range(2, 64, 1) var tutorial_resource_min_distance_tiles: int = 10
@export_range(4, 96, 1) var tutorial_resource_max_distance_tiles: int = 42
@export_range(2, 32, 1) var tutorial_resource_min_spacing_tiles: int = 12
@export_range(0, 24, 1) var expedition_resource_node_count: int = 8
@export_range(8, 160, 1) var expedition_resource_min_distance_tiles: int = 46
@export_range(2, 48, 1) var expedition_resource_min_spacing_tiles: int = 10
@export_range(0.0, 1.0, 0.01) var expedition_resource_min_intensity: float = 0.30
@export var fallback_tile_size: float = 32.0

const ARRN_RELAY_SCENE := preload("res://game/actors/relay/relay.tscn")
const RESOURCE_NODE_SCENE := preload("res://game/resources/resource_node.tscn")
const GOTHIC_COMPOUND_MAP_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_map.gd")
const GOTHIC_COMPOUND_TRAVEL_GATE_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_travel_gate.gd")
const SUNDERED_KEEP_MAP_SCRIPT := preload("res://game/world/sundered_keep/sundered_keep_map.gd")
const WORLD_INGRESS_SITE_SCRIPT := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
const WORLD_INGRESS_SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")
const SUNDERED_KEEP_FRONTAGE_VISUAL_SPAWNER_SCRIPT := preload(
	"res://game/world/procgen/landmarks/sundered_keep/"
	+ "sundered_keep_frontage_visual_spawner.gd"
)
const SUNDERED_KEEP_LEVEL_ID := &"sundered_keep_front_gate"
const WORLD_ORIGIN_BRANCH_GROUP := &"world_origin_branch"
const AMBIENT_ENEMY_MARKER_GROUP := &"ambient_enemy_camp_marker"
const GENERATED_AMBIENT_ENEMY_MARKER_GROUP := &"generated_procgen_ambient_enemy_marker"
const LEGACY_OPERATOR_PLACEHOLDER_POSITION := Vector2(717.45905, -485.33954)
const SECTOR_TILE_PX := 24.0
const LEGACY_PROCGEN_SECTOR_LAYOUT := {
	"ARCHIVE": 0,
	"POWER": 1,
	"DEFENSE": 2,
	"STORAGE": 3,
}
const DEFENSE_TURRET_LAYOUT := {
	"TurretGunner": Vector2(-0.26, -0.18),
	"TurretBlaster": Vector2(0.24, -0.12),
	"TurretRepeater": Vector2(-0.18, 0.22),
	"TurretSniper": Vector2(0.20, 0.26),
}

var _contract_map_node: Node = null
var _active_procgen_map: Node = null
var _contract_generation_failed: bool = false
var _last_failure_result: Dictionary = {}
## Ordered phase log of the latest successful `_on_contract_generated()` and
## the telemetry of its one-time Archive Resolve ingress trigger. Validation
## seam only; nothing in gameplay reads it.
var _install_trace: Array[Dictionary] = []
var _last_archive_resolve_ingress: Dictionary = {}
var _operator_failure_state: Dictionary = {}
var _operator_placement_receipt: Dictionary = {}
var _active_generation_identity: String = ""
var _install_started_usec: int = 0
var _last_install_phase_usec: int = 0
var _contract_activation_result: Dictionary = {}


func _ready() -> void:
	add_to_group("contract_world_loader")
	var game_root := get_node_or_null("/root/GameRoot")
	if game_root != null and bool(game_root.get_meta("command_pressure_scenario_active", false)):
		return
	if reposition_operator_from_contract:
		_disable_operator_until_safe_placement()
		_observe_startup_transition(&"operator_held_for_generated_spawn", _operator_identity_snapshot())
	call_deferred("_bind_contract_map")


func _exit_tree() -> void:
	var callback := Callable(self, "_on_contract_generated")
	var failure_callback := Callable(self, "_on_contract_generation_failed")
	if _contract_map_node != null and is_instance_valid(_contract_map_node):
		if _contract_map_node.is_connected("contract_generated", callback):
			_contract_map_node.disconnect("contract_generated", callback)
		if _contract_map_node.has_signal("contract_generation_failed") and _contract_map_node.is_connected("contract_generation_failed", failure_callback):
			_contract_map_node.disconnect("contract_generation_failed", failure_callback)
	var enemy_root := get_node_or_null("/root/GameRoot/World/Enemies")
	var enemy_callback := Callable(self, "_on_failed_enemy_child_entered")
	if enemy_root != null and enemy_root.is_connected("child_entered_tree", enemy_callback):
		enemy_root.disconnect("child_entered_tree", enemy_callback)
	var node_added_callback := Callable(self, "_on_failed_runtime_node_added")
	if get_tree() != null and get_tree().is_connected("node_added", node_added_callback):
		get_tree().disconnect("node_added", node_added_callback)
	_contract_map_node = null
	_active_procgen_map = null
	_contract_generation_failed = false
	_last_failure_result = {}


func _bind_contract_map() -> void:
	if _contract_generation_failed:
		return
	_contract_map_node = get_node_or_null(contract_map_path)
	if _contract_map_node == null:
		push_warning("[ContractWorldLoader] ContractMap not found at %s" % String(contract_map_path))
		_observe_startup_transition(&"contract_map_unbound", {"path": str(contract_map_path)})
		_on_contract_generation_failed({
			"generation_failed": true,
			"failure_reason": "contract_map_missing",
			"detail": {"path": str(contract_map_path)},
		})
		return
	if not _contract_map_node.has_signal("contract_generated"):
		push_warning("[ContractWorldLoader] ContractMap missing signal: contract_generated")
		_observe_startup_transition(&"contract_map_unbound", {"path": str(contract_map_path), "reason": "contract_generated_signal_missing"})
		_on_contract_generation_failed({
			"generation_failed": true,
			"failure_reason": "contract_map_signal_missing",
			"detail": {"path": str(contract_map_path)},
		})
		return

	var callback := Callable(self, "_on_contract_generated")
	if not _contract_map_node.is_connected("contract_generated", callback):
		_contract_map_node.connect("contract_generated", callback)
	_observe_startup_transition(&"contract_map_bound", {"path": str(_contract_map_node.get_path())})
	if _contract_map_node.has_signal("contract_generation_failed"):
		var failure_callback := Callable(self, "_on_contract_generation_failed")
		if not _contract_map_node.is_connected("contract_generation_failed", failure_callback):
			_contract_map_node.connect("contract_generation_failed", failure_callback)

	if _contract_map_node.has_method("get_latest_contract"):
		var latest: Variant = _contract_map_node.call("get_latest_contract")
		if latest is Dictionary and not (latest as Dictionary).is_empty():
			_on_contract_generated(latest)
	if _contract_map_node.has_method("get_latest_generation_failure"):
		var failure: Variant = _contract_map_node.call("get_latest_generation_failure")
		if failure is Dictionary and not (failure as Dictionary).is_empty():
			_on_contract_generation_failed(failure as Dictionary)


func _on_contract_generated(contract: Dictionary) -> void:
	_contract_activation_result.clear()
	var map_block: Dictionary = contract.get("map", {}) as Dictionary
	var map_instance_variant: Variant = map_block.get("instance")
	if (
		map_instance_variant == null
		or not is_instance_valid(map_instance_variant)
		or not (map_instance_variant is Node)
	):
		_on_contract_generation_failed({
			"generation_failed": true,
			"failure_reason": "contract_map_instance_missing",
			"detail": "ContractWorldLoader received a generated contract without a live map instance.",
		})
		return
	var map_instance := map_instance_variant as Node
	var generation_identity := _contract_generation_identity(contract, map_instance)
	_active_generation_identity = generation_identity
	_contract_generation_failed = false
	_last_failure_result = {}
	if reposition_operator_from_contract:
		_disable_operator_until_safe_placement()
	_install_trace.clear()
	_last_archive_resolve_ingress = {}
	_operator_placement_receipt.clear()
	_install_started_usec = Time.get_ticks_usec()
	_last_install_phase_usec = _install_started_usec
	var bootstrap := get_node_or_null("/root/WorldContractBootstrap")
	var bootstrap_metrics: Dictionary = bootstrap.call("get_metrics") if bootstrap != null and bootstrap.has_method("get_metrics") else {}
	_trace_install(&"contract_generation_received", {
		"generation_identity": generation_identity,
		"contract_seed": contract.get("contract_seed", -1),
		"map_seed": map_block.get("map_seed", -1),
		"bootstrap": bootstrap_metrics,
	})
	var world_profile: Dictionary = contract.get("world_profile", {}) as Dictionary
	_apply_contract_lighting_profile(world_profile)
	var level_data: Dictionary = map_block.get("level_data", {}) as Dictionary
	if bool(level_data.get("generation_failed", false)):
		_on_contract_generation_failed(level_data)
		return
	var placement_context := _build_placement_context(map_instance, level_data)
	_attach_procgen_map(map_instance)
	_apply_contract_environment(contract, map_instance)
	if place_registered_level_connections:
		if not _place_registered_world_ingresses(level_data, map_instance):
			return
		_trace_install(&"registered_ingress_placed")
	elif place_sundered_keep_connection:
		_place_sundered_keep_connection(level_data, map_instance)

	var sectors_positioned := _position_static_sectors_from_contract(level_data, map_instance, placement_context)

	if hide_static_sectors and not sectors_positioned:
		var sectors_node := get_node_or_null(sectors_container_path)
		_deactivate_static_sectors(sectors_node)

	if reposition_operator_from_contract:
		if not _position_operator(level_data, map_instance):
			var spawn_failure_detail := "no candidate passed canonical spawn validity and main playable component membership"
			var failure_reason := "no_canonical_safe_spawn"
			if not _install_trace.is_empty():
				var last_spawn_trace: Dictionary = _install_trace[-1]
				spawn_failure_detail += "; trace=%s" % str(last_spawn_trace)
				if last_spawn_trace.get("phase") == &"spawn_presentation_realization_failed":
					failure_reason = "spawn_presentation_realization_failed"
			_on_contract_generation_failed({
				"generation_failed": true,
				"failure_reason": failure_reason,
				"detail": spawn_failure_detail,
			})
			return
		_trace_install(&"operator_placed", {"component_queries": _component_query_count(map_instance)})
	if reposition_spawn_nodes_from_contract:
		_position_spawn_nodes(level_data, map_instance)
	if reposition_terminal_from_contract:
		_position_command_terminal(level_data, map_instance)
	if reposition_construction_population_from_contract:
		_position_construction_population(level_data, map_instance)
	if reposition_vehicles_from_contract:
		_position_vehicles(level_data, map_instance)
	if reposition_items_from_contract:
		_position_item_anchors(level_data, map_instance)
	if place_tutorial_resource_nodes_from_contract:
		_position_tutorial_resource_nodes(level_data, map_instance)
	if place_expedition_resource_nodes_from_contract:
		_position_expedition_resource_nodes(level_data, map_instance)
	if place_arrn_relays_from_contract:
		_position_arrn_relays(level_data, map_instance)
	if place_ambient_enemy_camps_from_contract:
		_place_ambient_enemy_camps(level_data, map_instance)
	if place_vaultwing_markers_from_contract:
		_place_vaultwing_markers(level_data, map_instance)
	if place_gothic_compound_connection:
		_place_gothic_compound_connection(level_data, map_instance)
		_trace_install(&"compound_connection_placed", {"component_queries": _component_query_count(map_instance)})
	if reposition_operator_from_contract:
		_begin_archive_resolve_ingress(map_instance)
	if reposition_camera_from_contract:
		_refresh_camera(map_instance)
		_trace_install(&"camera_refresh")
	_rebuild_navigation(map_instance)
	_trace_install(&"navigation_rebuilt")
	if reposition_operator_from_contract:
		var operator := get_node_or_null(operator_path) as Node2D
		if operator != null:
			_restore_operator_after_safe_placement(operator)
			_operator_placement_receipt["visible_after_restore"] = operator.visible
			_operator_placement_receipt["process_mode_after_restore"] = operator.process_mode
			var player_nodes := get_tree().get_nodes_in_group("player") if get_tree() != null else []
			_operator_placement_receipt["player_group_count"] = player_nodes.size()
			_operator_placement_receipt["player_group_identity_matches"] = (
				operator.get_path() != NodePath("/root/GameRoot/World/Operator")
				or (player_nodes.size() == 1 and player_nodes[0] == operator)
			)
		_trace_install(&"operator_placement_receipt", _operator_placement_receipt)
	var placement_validation := _validate_operator_placement_before_ready(map_instance)
	if not bool(placement_validation.get("valid", false)):
		_trace_install(&"operator_placement_diverged_before_ready", placement_validation)
		_disable_operator_until_safe_placement()
		_on_contract_generation_failed({
			"generation_failed": true,
			"failure_reason": "operator_placement_diverged_before_ready",
			"detail": placement_validation,
		})
		return
	_trace_install(&"contract_ready", {
		"placement_validation": placement_validation,
		"placement_receipt": get_operator_placement_receipt(),
	})
	_mark_contract_ready()


## One-time presentation-only arrival resolve, centred on the Operator's
## already-final position. Never moves the Operator, never queries spawn
## validity or the playable component, and never gates control.
func _begin_archive_resolve_ingress(map_instance: Node) -> void:
	if not (map_instance is ProcGenTilemap):
		return
	var operator := get_node_or_null(operator_path) as Node2D
	if operator == null:
		return
	var pg := map_instance as ProcGenTilemap
	_last_archive_resolve_ingress = pg.begin_archive_resolve_ingress(operator.global_position)
	_last_archive_resolve_ingress["operator_global_position"] = operator.global_position
	_last_archive_resolve_ingress["component_queries"] = _component_query_count(map_instance)
	_trace_install(&"archive_resolve_ingress", _last_archive_resolve_ingress)


func _component_query_count(map_instance: Node) -> int:
	if map_instance is ProcGenTilemap:
		return (map_instance as ProcGenTilemap).main_playable_component_query_count
	return 0


func _trace_install(phase: StringName, detail: Dictionary = {}) -> void:
	var now_usec := Time.get_ticks_usec()
	var timing := {
		"phase_elapsed_ms": maxf(0.0, float(now_usec - _last_install_phase_usec) / 1000.0),
		"install_elapsed_ms": maxf(0.0, float(now_usec - _install_started_usec) / 1000.0),
	}
	_last_install_phase_usec = now_usec
	_install_trace.append({"phase": phase, "detail": detail.duplicate(true), "timing": timing})
	_observe_startup_transition(phase, {
		"generation_identity": _active_generation_identity,
		"detail": detail.duplicate(true),
		"timing": timing,
	})


func get_install_trace() -> Array[Dictionary]:
	return _install_trace.duplicate(true)


func get_last_archive_resolve_ingress() -> Dictionary:
	return _last_archive_resolve_ingress.duplicate(true)


func get_operator_placement_receipt() -> Dictionary:
	return _operator_placement_receipt.duplicate(true)


func get_startup_diagnostics() -> Dictionary:
	var contract_map := get_node_or_null(contract_map_path)
	var player_nodes := get_tree().get_nodes_in_group("player") if get_tree() != null else []
	return {
		"loader_bound": contract_map != null and _contract_map_node == contract_map,
		"generation_identity": _active_generation_identity,
		"terminal_state": "failed" if _contract_generation_failed else ("ready" if not _install_trace.is_empty() and _install_trace[-1].get("phase") == &"contract_ready" else "pending"),
		"placement_receipt": get_operator_placement_receipt(),
		"failure": get_last_failure_result(),
		"player_group_count": player_nodes.size(),
		"player_group_paths": player_nodes.map(func(node: Node) -> String: return str(node.get_path())),
		"install_trace": get_install_trace(),
	}


func _contract_generation_identity(contract: Dictionary, map_instance: Node) -> String:
	var map_block: Dictionary = contract.get("map", {}) as Dictionary
	return "%s:%s:%s" % [
		str(contract.get("contract_seed", "unknown")),
		str(map_block.get("map_seed", "unknown")),
		str(map_instance.get_instance_id()),
	]


func _operator_identity_snapshot() -> Dictionary:
	var operator := get_node_or_null(operator_path)
	var players := get_tree().get_nodes_in_group("player") if get_tree() != null else []
	return {
		"canonical_path": str(operator.get_path()) if operator != null else "missing",
		"canonical_instance_id": operator.get_instance_id() if operator != null else -1,
		"canonical_position": (operator as Node2D).global_position if operator is Node2D else Vector2.INF,
		"player_group_count": players.size(),
		"player_group_paths": players.map(func(node: Node) -> String: return str(node.get_path())),
	}


func _observe_startup_transition(phase: StringName, detail: Dictionary = {}) -> void:
	if not is_inside_tree():
		return
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null:
		return
	var snapshot := _operator_identity_snapshot()
	var terminal_state := "failed" if _contract_generation_failed else "pending"
	if phase == &"contract_ready":
		terminal_state = "ready"
	elif phase == &"contract_failed":
		terminal_state = "failed"
	snapshot.merge({
		"phase": String(phase),
		"generation_identity": _active_generation_identity,
		"loader_bound": _contract_map_node != null and is_instance_valid(_contract_map_node),
		"terminal_state": terminal_state,
		"receipt": get_operator_placement_receipt(),
		"detail": detail.duplicate(true),
	}, true)
	if observatory.has_method("set_gauge"):
		observatory.call("set_gauge", &"contract_world_startup", snapshot)
	if observatory.has_method("log_event"):
		observatory.call("log_event", &"contract_world_startup_transition", snapshot)


func _place_ambient_enemy_camps(level_data: Dictionary, map_instance: Node) -> void:
	_clear_generated_ambient_enemy_markers()
	var encounter_plan := level_data.get("encounter_plan", {}) as Dictionary
	var encounters := encounter_plan.get("encounters", []) as Array
	if String(encounter_plan.get("schema", "")) == "custodian.procgen_encounter_plan.v1":
		_place_encounter_plan_markers(encounters, map_instance)
	else:
		_place_legacy_ambient_enemy_markers(level_data, map_instance)
	_request_ambient_spawner_refresh()


func _clear_generated_ambient_enemy_markers() -> void:
	for existing in get_tree().get_nodes_in_group(GENERATED_AMBIENT_ENEMY_MARKER_GROUP):
		if existing is Node and is_instance_valid(existing):
			(existing as Node).queue_free()


func _place_encounter_plan_markers(encounters: Array, map_instance: Node) -> void:
	for encounter_variant in encounters:
		var encounter := encounter_variant as Dictionary
		var marker := Marker2D.new()
		var encounter_id := String(encounter.get("encounter_id", "combat"))
		marker.name = "AmbientEnemyCampMarker_%s" % encounter_id
		marker.add_to_group(AMBIENT_ENEMY_MARKER_GROUP)
		marker.add_to_group(GENERATED_AMBIENT_ENEMY_MARKER_GROUP)
		for key in ["encounter_id", "tier", "pocket_index", "home_tile", "leash_radius_tiles", "spawn_radius_tiles", "activation_range_tiles", "enemy_count_min", "enemy_count_max", "behavior_profile_id"]:
			var metadata_key: String = "encounter_tier" if key == "tier" else String(key)
			marker.set_meta(metadata_key, encounter.get(key))
		marker.set_meta("camp_id", encounter_id)
		var anchor := encounter.get("anchor_tile", Vector2i.ZERO) as Vector2i
		marker.set_meta("camp_tile", anchor)
		map_instance.add_child(marker)
		marker.global_position = _tile_to_world(map_instance, anchor)


func _place_legacy_ambient_enemy_markers(level_data: Dictionary, map_instance: Node) -> void:
	if ambient_enemy_camp_count <= 0:
		return
	var candidates := _build_ambient_enemy_candidate_tiles(level_data, map_instance)
	if candidates.is_empty():
		push_warning("[ContractWorldLoader] No walkable ambient enemy camp candidates")
		return
	var chosen: Array[Vector2i] = []
	var spacing_sq := ambient_enemy_camp_spacing_tiles * ambient_enemy_camp_spacing_tiles
	for tile in candidates:
		var sufficiently_spaced := true
		for existing_tile in chosen:
			if tile.distance_squared_to(existing_tile) < spacing_sq:
				sufficiently_spaced = false
				break
		if not sufficiently_spaced:
			continue
		var marker := Marker2D.new()
		marker.name = "AmbientEnemyCampMarker_%02d" % (chosen.size() + 1)
		marker.add_to_group(AMBIENT_ENEMY_MARKER_GROUP)
		marker.add_to_group(GENERATED_AMBIENT_ENEMY_MARKER_GROUP)
		marker.set_meta("camp_tile", tile)
		map_instance.add_child(marker)
		marker.global_position = _tile_to_world(map_instance, tile)
		chosen.append(tile)
		if chosen.size() >= ambient_enemy_camp_count:
			break


func _request_ambient_spawner_refresh() -> void:
	var spawner := get_node_or_null(ambient_enemy_spawner_path)
	if spawner != null and spawner.has_method("spawn_from_markers"):
		spawner.call("spawn_from_markers")

func _place_vaultwing_markers(level_data: Dictionary, map_instance: Node) -> void:
	var spawner := get_node_or_null(vaultwing_spawner_path)
	if spawner != null and spawner.has_method("reset_for_world"):
		spawner.call("reset_for_world")
	for existing in get_tree().get_nodes_in_group("generated_vaultwing_marker"):
		if existing is Node and is_instance_valid(existing): (existing as Node).queue_free()
	var candidates := _build_ambient_enemy_candidate_tiles(level_data, map_instance)
	var world_identity := str(level_data.get("generation_id", level_data.get("seed", "unknown_contract")))
	_place_vaultwing_markers_from_candidates(candidates, map_instance, spawner, world_identity)

## Validation seam for the production marker algorithm. Candidate selection is
## still owned by the loader; this only lets a bounded fixture supply a
## deterministic candidate set without recreating marker/spacing logic.
func place_vaultwing_markers_for_candidates(candidate_tiles: Array[Vector2i], map_instance: Node) -> void:
	var spawner := get_node_or_null(vaultwing_spawner_path)
	if spawner != null and spawner.has_method("reset_for_world"):
		spawner.call("reset_for_world")
	for existing in get_tree().get_nodes_in_group("generated_vaultwing_marker"):
		if existing is Node and is_instance_valid(existing): (existing as Node).queue_free()
	_place_vaultwing_markers_from_candidates(candidate_tiles, map_instance, spawner, "fixture_world")

func _place_vaultwing_markers_from_candidates(
	candidates: Array[Vector2i],
	map_instance: Node,
	spawner: Node,
	world_identity := "unknown_contract"
) -> void:
	if candidates.is_empty(): return
	var spawn_marker := Marker2D.new()
	spawn_marker.name = "VaultwingSpawnMarker"
	spawn_marker.add_to_group("vaultwing_spawn_marker")
	spawn_marker.add_to_group("generated_vaultwing_marker")
	spawn_marker.set_meta("vaultwing_world_identity", world_identity)
	spawn_marker.set_meta("vaultwing_marker_identity", "vaultwing_common_spawn_00")
	map_instance.add_child(spawn_marker)
	spawn_marker.global_position = _tile_to_world(map_instance, candidates[0])
	var perch_candidates: Array = []
	for candidate in candidates:
		if candidate.distance_to(candidates[0]) < vaultwing_perch_spacing_tiles:
			continue
		var spaced := true
		for prior in perch_candidates:
			if candidate.distance_to(prior) < vaultwing_perch_spacing_tiles:
				spaced = false
				break
		if spaced:
			perch_candidates.append(candidate)
		if perch_candidates.size() >= 2:
			break
	for index in perch_candidates.size():
		var perch := Marker2D.new()
		perch.name = "VaultwingPerch_%02d" % index
		perch.add_to_group("vaultwing_perch")
		perch.add_to_group("generated_vaultwing_marker")
		map_instance.add_child(perch)
		perch.global_position = _tile_to_world(map_instance, perch_candidates[index])
	if spawner != null and spawner.has_method("spawn_from_markers"):
		spawner.call_deferred("spawn_from_markers")


func _build_ambient_enemy_candidate_tiles(
	level_data: Dictionary,
	map_instance: Node
) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	var raw_tiles: Array = []
	for candidate_key in [
		"vista_cells",
		"main_route_cells",
		"random_floor_tiles",
		"floor_cells",
	]:
		raw_tiles.append_array(level_data.get(candidate_key, []) as Array)
	var player_spawn: Variant = level_data.get("player_spawn")
	var spawn_tile := player_spawn as Vector2i if player_spawn is Vector2i else Vector2i.ZERO
	var min_distance_sq := ambient_enemy_min_distance_tiles * ambient_enemy_min_distance_tiles
	var compound_rect: Rect2i = level_data.get("compound_rect", Rect2i()) as Rect2i
	for raw_tile in raw_tiles:
		if not (raw_tile is Vector2i):
			continue
		var tile := raw_tile as Vector2i
		if seen.has(tile):
			continue
		seen[tile] = true
		if tile.distance_squared_to(spawn_tile) < min_distance_sq:
			continue
		if compound_rect.has_area() and compound_rect.has_point(tile):
			continue
		if not _is_walkable_floor_tile(map_instance, tile):
			continue
		if _count_walkable_neighbors(map_instance, tile) < 3:
			continue
		candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score := _ambient_enemy_tile_score(a, spawn_tile)
		var b_score := _ambient_enemy_tile_score(b, spawn_tile)
		if a_score == b_score:
			return a.x == b.x and a.y < b.y or a.x < b.x
		return a_score < b_score
	)
	return candidates


func _ambient_enemy_tile_score(tile: Vector2i, spawn_tile: Vector2i) -> int:
	var stable_hash: int = absi((tile.x * 73856093) ^ (tile.y * 19349663))
	return int(tile.distance_squared_to(spawn_tile)) + stable_hash % 997


func _apply_contract_lighting_profile(world_profile: Dictionary) -> void:
	if world_profile.is_empty():
		return
	var director := get_tree().get_first_node_in_group("world_lighting_director")
	if director != null and director.has_method("apply_world_profile_overrides"):
		director.call("apply_world_profile_overrides", world_profile, false)


func _apply_contract_environment(contract: Dictionary, map_instance: Node) -> void:
	var director := get_tree().get_first_node_in_group("world_environment_director")
	if director != null and director.has_method("configure_from_contract"):
		director.call("configure_from_contract", contract, map_instance)


func _on_contract_generation_failed(result: Dictionary) -> void:
	_contract_generation_failed = true
	_last_failure_result = result.duplicate(true)
	_active_procgen_map = null
	if is_inside_tree():
		_disable_operator_until_safe_placement()
	print("[ContractWorldLoader] Contract generation failed; runtime world activation aborted %s" % str(result))
	if is_inside_tree():
		_mark_contract_failed(result)
	_observe_startup_transition(&"contract_failed", {"failure": result.duplicate(true)})
	_stop_combat_activation()


func is_contract_activation_aborted() -> bool:
	return _contract_generation_failed


func is_contract_world_pending() -> bool:
	return _active_procgen_map == null and not _contract_generation_failed


func get_last_failure_result() -> Dictionary:
	return _last_failure_result.duplicate(true)


func _mark_contract_ready() -> void:
	var bootstrap := get_node_or_null("/root/WorldContractBootstrap")
	if bootstrap != null and bootstrap.has_method("mark_claimed"):
		bootstrap.call("mark_claimed")
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("mark_contract_ready"):
		game_state.call("mark_contract_ready")
	_observe_startup_transition(&"contract_ready", {"placement_receipt": get_operator_placement_receipt()})
	_contract_activation_result = {
		"ready": true,
		"code": "CONTRACT_ACTIVATED",
		"generation_identity": _active_generation_identity,
		"map_instance_id": _active_procgen_map.get_instance_id() if is_instance_valid(_active_procgen_map) else -1,
		"placement_receipt": get_operator_placement_receipt(),
	}
	contract_activation_finished.emit(_contract_activation_result.duplicate(true))


func _mark_contract_failed(result: Dictionary) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("mark_contract_failed"):
		game_state.call("mark_contract_failed", result)
	_contract_activation_result = {
		"ready": false,
		"code": "CONTRACT_ACTIVATION_FAILED",
		"failure": result.duplicate(true),
	}
	contract_activation_finished.emit(_contract_activation_result.duplicate(true))


func _stop_combat_activation() -> void:
	if not is_inside_tree():
		return
	var node_added_callback := Callable(self, "_on_failed_runtime_node_added")
	if get_tree() != null and not get_tree().is_connected("node_added", node_added_callback):
		get_tree().connect("node_added", node_added_callback)
	var wave_manager := get_node_or_null("/root/GameRoot/WaveManager")
	if wave_manager != null:
		wave_manager.set("active", false)
		wave_manager.set("debug_spawn_grunt_on_start", false)
		_disable_runtime_node(wave_manager)
	var supply_drop_manager := get_node_or_null("/root/GameRoot/SupplyDropManager")
	if supply_drop_manager != null:
		supply_drop_manager.set("_active", false)
		var drop_timer: Variant = supply_drop_manager.get("_timer")
		if drop_timer is Timer:
			(drop_timer as Timer).stop()
		var countdown_timer: Variant = supply_drop_manager.get("_countdown_timer")
		if countdown_timer is Timer:
			(countdown_timer as Timer).stop()
		_disable_runtime_node(supply_drop_manager)
	var ambient_critter_manager := get_node_or_null("/root/GameRoot/AmbientCritterManager")
	if ambient_critter_manager != null:
		ambient_critter_manager.set("ambient_spawn_enabled", false)
		ambient_critter_manager.set("critter_count", 0)
		ambient_critter_manager.set("ambient_max_count", 0)
		if ambient_critter_manager.has_method("_clear_spawned_critters"):
			ambient_critter_manager.call("_clear_spawned_critters")
		_disable_runtime_node(ambient_critter_manager)
	for spawn_node in get_tree().get_nodes_in_group("enemy_spawn"):
		if spawn_node is Node:
			spawn_node.set("active", false)
			_disable_runtime_node(spawn_node)
	for camp in get_tree().get_nodes_in_group("ambient_enemy_camp"):
		if camp is Node:
			camp.set("initially_active", false)
			camp.set("respawn_enabled", false)
			_disable_runtime_node(camp)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node:
			_remove_failed_enemy(enemy)
	var enemy_root := get_node_or_null("/root/GameRoot/World/Enemies")
	if enemy_root != null:
		enemy_root.process_mode = Node.PROCESS_MODE_DISABLED
		var enemy_callback := Callable(self, "_on_failed_enemy_child_entered")
		if not enemy_root.is_connected("child_entered_tree", enemy_callback):
			enemy_root.connect("child_entered_tree", enemy_callback)
		for child in enemy_root.get_children():
			_disable_runtime_node(child)


func _on_failed_enemy_child_entered(node: Node) -> void:
	if not _contract_generation_failed:
		return
	_remove_failed_enemy(node)


func _on_failed_runtime_node_added(node: Node) -> void:
	if not _contract_generation_failed or node == null:
		return
	call_deferred("_disable_failed_runtime_node_if_needed", node.get_instance_id())


func _disable_failed_runtime_node_if_needed(instance_id: int) -> void:
	var node := instance_from_id(instance_id) as Node
	if not _contract_generation_failed or node == null or not is_instance_valid(node):
		return
	if node.is_in_group("enemy"):
		_remove_failed_enemy(node)
	elif node.is_in_group("enemy_spawn") or node.is_in_group("ambient_enemy_camp"):
		_disable_runtime_node(node)


func _remove_failed_enemy(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	_disable_runtime_node(node)
	if not node.is_queued_for_deletion():
		node.queue_free()


func _disable_runtime_node(node: Node) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		if child is Node:
			_disable_runtime_node(child)


func _position_static_sectors_from_contract(
	level_data: Dictionary,
	map_instance: Node,
	placement_context: WorldPlacementContext = null
) -> bool:
	var sectors_root := get_node_or_null(sectors_container_path)
	if sectors_root == null:
		return false
	var context := placement_context
	if context == null:
		context = _build_placement_context(map_instance, level_data)
	var semantic_rooms := context.get_compound_rooms_by_sector_id()
	if not semantic_rooms.is_empty():
		var semantic_positioned := false
		var ingress_tiles := context.get_compound_ingress_tiles()
		for sector_id in semantic_rooms.keys():
			var sector_node := sectors_root.get_node_or_null(String(sector_id)) as Node2D
			if sector_node == null:
				continue
			var room: Dictionary = semantic_rooms[sector_id]
			var sector_rect: Rect2i = room.get("rect", Rect2i())
			if sector_rect.size.x <= 0 or sector_rect.size.y <= 0:
				continue
			_position_sector_node(sector_node, sector_rect, ingress_tiles, map_instance)
			semantic_positioned = true
			if String(sector_id) == "DEFENSE":
				_position_defense_turrets(sector_node, sector_rect)
		return semantic_positioned

	var building_tiles: Array[Rect2i] = []
	for item in level_data.get("compound_buildings", []):
		if item is Rect2i:
			building_tiles.append(item as Rect2i)
	if building_tiles.is_empty():
		return false

	var ingress_tiles: Array[Vector2i] = []
	for item in level_data.get("compound_ingress", []):
		if item is Vector2i:
			ingress_tiles.append(item as Vector2i)

	var positioned_any := false
	for sector_name in LEGACY_PROCGEN_SECTOR_LAYOUT.keys():
		var sector_index: int = int(LEGACY_PROCGEN_SECTOR_LAYOUT[sector_name])
		if sector_index >= building_tiles.size():
			continue
		var sector_node := sectors_root.get_node_or_null(String(sector_name)) as Node2D
		if sector_node == null:
			continue
		var sector_rect: Rect2i = building_tiles[sector_index]
		_position_sector_node(sector_node, sector_rect, ingress_tiles, map_instance)
		positioned_any = true
		if sector_name == "DEFENSE":
			_position_defense_turrets(sector_node, sector_rect)

	return positioned_any


func _build_placement_context(map_instance: Node, level_data: Dictionary) -> WorldPlacementContext:
	var generation_id: Variant = level_data.get("generation_id", level_data.get("seed", "unknown"))
	var observer := func(event_name: StringName, payload: Dictionary) -> void:
		_observe_population_placement(event_name, {"generation_id": generation_id}, payload)
	return WorldPlacementContext.new(map_instance, level_data, observer)


func _position_sector_node(sector_node: Node2D, sector_rect: Rect2i, ingress_tiles: Array[Vector2i], map_instance: Node) -> void:
	sector_node.visible = true
	sector_node.process_mode = Node.PROCESS_MODE_INHERIT
	sector_node.scale = _get_sector_runtime_scale(map_instance)
	sector_node.global_position = _rect_center_to_world(map_instance, sector_rect)

	if sector_node is Sector:
		var sector := sector_node as Sector
		sector.size_tiles = sector_rect.size
		sector.door_sides = _infer_sector_doors(sector_rect, ingress_tiles)
		sector._build_geometry()
		_disable_sector_runtime_shell(sector)
		sector.update_visuals()


func _position_defense_turrets(defense_sector: Node2D, sector_rect: Rect2i) -> void:
	var half_w := float(sector_rect.size.x) * SECTOR_TILE_PX * 0.5
	var half_h := float(sector_rect.size.y) * SECTOR_TILE_PX * 0.5
	for child in defense_sector.get_children():
		if not (child is Node2D):
			continue
		var turret := child as Node2D
		var normalized: Vector2 = DEFENSE_TURRET_LAYOUT.get(String(turret.name), Vector2.ZERO)
		turret.position = Vector2(half_w * normalized.x, half_h * normalized.y)
		turret.visible = true
		turret.process_mode = Node.PROCESS_MODE_INHERIT


func _rect_center_to_world(map_instance: Node, rect: Rect2i) -> Vector2:
	var center_tile := Vector2i(
		rect.position.x + int(rect.size.x / 2),
		rect.position.y + int(rect.size.y / 2)
	)
	return _tile_to_world(map_instance, center_tile)


func _infer_sector_doors(sector_rect: Rect2i, ingress_tiles: Array[Vector2i]) -> PackedStringArray:
	var doors := PackedStringArray()
	var max_distance := 4
	for ingress in ingress_tiles:
		if ingress.y >= sector_rect.position.y - max_distance and ingress.y <= sector_rect.position.y + max_distance:
			if ingress.x >= sector_rect.position.x and ingress.x < sector_rect.end.x and not doors.has("N"):
				doors.append("N")
		if ingress.y >= sector_rect.end.y - 1 - max_distance and ingress.y <= sector_rect.end.y - 1 + max_distance:
			if ingress.x >= sector_rect.position.x and ingress.x < sector_rect.end.x and not doors.has("S"):
				doors.append("S")
		if ingress.x >= sector_rect.position.x - max_distance and ingress.x <= sector_rect.position.x + max_distance:
			if ingress.y >= sector_rect.position.y and ingress.y < sector_rect.end.y and not doors.has("W"):
				doors.append("W")
		if ingress.x >= sector_rect.end.x - 1 - max_distance and ingress.x <= sector_rect.end.x - 1 + max_distance:
			if ingress.y >= sector_rect.position.y and ingress.y < sector_rect.end.y and not doors.has("E"):
				doors.append("E")
	if doors.is_empty():
		doors.append("N")
	return doors


func _attach_procgen_map(map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		push_warning("[ContractWorldLoader] World not found at %s" % String(world_path))
		return

	var runtime_container := world.get_node_or_null(runtime_map_container_name) as Node2D
	if runtime_container == null:
		runtime_container = Node2D.new()
		runtime_container.name = runtime_map_container_name
		runtime_container.z_index = -100
		world.add_child(runtime_container)

	runtime_container.add_to_group(WORLD_ORIGIN_BRANCH_GROUP)

	if map_instance.get_parent() != runtime_container:
		map_instance.reparent(runtime_container)

	map_instance.visible = true
	map_instance.z_index = -100
	_active_procgen_map = map_instance


func _position_operator(level_data: Dictionary, map_instance: Node) -> bool:
	var operator := get_node_or_null(operator_path) as Node2D
	if operator == null:
		_trace_install(&"operator_identity_missing", {"operator_path": str(operator_path)})
		return false
	var main_component := _get_main_playable_component(map_instance)
	var selection := _pick_compound_spawn_result(level_data, map_instance, main_component)
	if selection.is_empty():
		var player_spawn: Variant = level_data.get("player_spawn")
		if player_spawn is Vector2i and _is_safe_operator_spawn_tile(
			map_instance, player_spawn as Vector2i, main_component
		):
			selection = {"tile": player_spawn as Vector2i, "source": "player_spawn"}
	if selection.is_empty():
		var fallback_tile: Variant = _pick_main_component_fallback_tile(
			level_data, map_instance, main_component
		)
		if fallback_tile != null:
			selection = {"tile": fallback_tile as Vector2i, "source": "main_component_fallback"}
	if selection.is_empty():
		var safe_component_tile_count := 0
		var ingress_clearance_excluded_tile_count := 0
		for key: Variant in main_component.keys():
			if key is Vector2i:
				var candidate := key as Vector2i
				if _is_safe_operator_spawn_tile(map_instance, candidate, main_component):
					safe_component_tile_count += 1
				elif _is_inside_ingress_clearance(map_instance, candidate):
					ingress_clearance_excluded_tile_count += 1
		_trace_install(&"operator_spawn_unavailable", {
			"reason": "no_canonical_safe_spawn",
			"player_spawn": _operator_spawn_anchor(level_data, map_instance),
			"main_component_tile_count": main_component.size(),
			"safe_component_tile_count": safe_component_tile_count,
			"ingress_clearance_excluded_tile_count": ingress_clearance_excluded_tile_count,
		})
		return false
	var selected_tile: Vector2i = selection["tile"]
	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		var realized := pg.ensure_spawn_presentation_ready(selected_tile)
		if not realized or not _is_walkable_floor_tile(map_instance, selected_tile):
			var chunk_size := maxi(1, pg.streaming_chunk_size_tiles)
			var chunk := Vector2i(
				int(floor(float(selected_tile.x) / float(chunk_size))),
				int(floor(float(selected_tile.y) / float(chunk_size)))
			)
			_trace_install(&"spawn_presentation_realization_failed", {
				"tile": selected_tile,
				"chunk": chunk,
				"lifecycle_state": pg.debug_get_chunk_lifecycle_state(chunk),
				"floor_source_id": pg.floor_tilemap.get_cell_source_id(selected_tile) if pg.floor_tilemap != null else -1,
				"wall_source_id": pg.walls_tilemap.get_cell_source_id(selected_tile) if pg.walls_tilemap != null else -1,
				"reason": "readiness_seam_failed_or_tile_not_painted_floor",
			})
			return false
		_trace_install(&"spawn_presentation_ready", {"tile": selected_tile, "source": selection["source"]})
	elif not _is_walkable_floor_tile(map_instance, selected_tile):
		return false
	var selected_world_position := _tile_to_world(map_instance, selected_tile)
	operator.global_position = selected_world_position
	var round_trip_tile := _world_to_tile(map_instance, operator.global_position)
	if round_trip_tile != selected_tile or not _is_safe_operator_spawn_tile(
		map_instance, round_trip_tile, main_component
	):
		push_warning(
			"[ContractWorldLoader] Final Operator spawn round-trip failed "
			+ "selected=%s round_trip=%s" % [selected_tile, round_trip_tile]
		)
		return false
	_trace_install(&"operator_spawn_selected", {
		"source": selection["source"],
		"tile": selected_tile,
		"world_position": operator.global_position,
	})
	var player_nodes := get_tree().get_nodes_in_group("player") if get_tree() != null else []
	var canonical_identity_required := operator.get_path() == NodePath("/root/GameRoot/World/Operator")
	_operator_placement_receipt = {
		"schema": "custodian.operator_placement_receipt.v1",
		"generation_identity": _active_generation_identity,
		"operator_instance_id": operator.get_instance_id(),
		"operator_path": str(operator.get_path()),
		"source": String(selection["source"]),
		"tile": selected_tile,
		"world_position": operator.global_position,
		"presentation_ready": true,
		"component_query_count": _component_query_count(map_instance),
		"accepted_main_component": main_component.has(selected_tile),
		"canonical_spawn_valid": map_instance is ProcGenTilemap and (map_instance as ProcGenTilemap).is_valid_spawn_cell(selected_tile),
		"runtime_navigation_walkable": map_instance is ProcGenTilemap and (map_instance as ProcGenTilemap).is_runtime_navigation_walkable(selected_tile),
		"outside_ingress_clearance": not _is_inside_ingress_clearance(map_instance, selected_tile),
		"painted_floor": _is_walkable_floor_tile(map_instance, selected_tile),
		"visible_after_restore": bool(_operator_failure_state.get("visible", operator.visible)),
		"process_mode_after_restore": int(_operator_failure_state.get("process_mode", operator.process_mode)),
		"player_group_count": player_nodes.size(),
		"player_group_identity_matches": not canonical_identity_required or (player_nodes.size() == 1 and player_nodes[0] == operator),
	}
	return true


func _validate_operator_placement_before_ready(map_instance: Node) -> Dictionary:
	if not reposition_operator_from_contract:
		return {"valid": true, "skipped": true}
	var operator := get_node_or_null(operator_path) as Node2D
	var players := get_tree().get_nodes_in_group("player") if get_tree() != null else []
	var reasons: Array[String] = []
	if operator == null:
		reasons.append("canonical_operator_missing")
	if _operator_placement_receipt.is_empty():
		reasons.append("placement_receipt_missing")
	if operator != null:
		if operator.global_position.is_equal_approx(LEGACY_OPERATOR_PLACEHOLDER_POSITION):
			reasons.append("operator_at_legacy_scene_placeholder")
		if int(_operator_placement_receipt.get("operator_instance_id", -1)) != operator.get_instance_id():
			reasons.append("operator_instance_diverged")
		if String(_operator_placement_receipt.get("operator_path", "")) != str(operator.get_path()):
			reasons.append("operator_path_diverged")
		if not operator.global_position.is_equal_approx(_operator_placement_receipt.get("world_position", Vector2.INF) as Vector2):
			reasons.append("operator_position_diverged")
		var selected_tile := _operator_placement_receipt.get("tile", Vector2i.ZERO) as Vector2i
		var current_tile := _world_to_tile(map_instance, operator.global_position)
		if _operator_has_physics_overlap(operator):
			reasons.append("operator_spawn_physics_overlap")
		if current_tile != selected_tile:
			reasons.append("operator_tile_diverged")
		if not _is_walkable_floor_tile(map_instance, current_tile):
			reasons.append("operator_tile_not_painted_floor")
		if _is_inside_ingress_clearance(map_instance, current_tile):
			reasons.append("operator_tile_inside_ingress_clearance")
		if map_instance is ProcGenTilemap:
			var pg := map_instance as ProcGenTilemap
			if not pg.is_valid_spawn_cell(current_tile):
				reasons.append("operator_tile_not_canonical_spawn_valid")
			if not pg.is_runtime_navigation_walkable(current_tile):
				reasons.append("operator_tile_not_runtime_walkable")
		if not operator.visible:
			reasons.append("operator_not_visible_after_restore")
		if operator.process_mode == Node.PROCESS_MODE_DISABLED:
			reasons.append("operator_processing_disabled_after_restore")
	if operator != null and operator.get_path() == NodePath("/root/GameRoot/World/Operator"):
		if players.size() != 1 or players[0] != operator:
			reasons.append("player_group_identity_mismatch")
	if not bool(_operator_placement_receipt.get("accepted_main_component", false)):
		reasons.append("selected_tile_not_recorded_in_accepted_component")
	if not bool(_operator_placement_receipt.get("presentation_ready", false)):
		reasons.append("spawn_presentation_not_ready")
	if not bool(_operator_placement_receipt.get("player_group_identity_matches", false)):
		reasons.append("player_identity_did_not_match_at_placement")
	return {
		"valid": reasons.is_empty(),
		"reasons": reasons,
		"generation_identity": _active_generation_identity,
		"receipt": get_operator_placement_receipt(),
		"operator": _operator_identity_snapshot(),
	}


func _operator_has_physics_overlap(operator: Node2D) -> bool:
	if not operator is CharacterBody2D:
		return false
	var collision_shape := operator.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null or operator.get_world_2d() == null:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collision_mask = (operator as CharacterBody2D).collision_mask
	query.exclude = [operator.get_rid()]
	return not operator.get_world_2d().direct_space_state.intersect_shape(query, 8).is_empty()


func _pick_main_component_fallback_tile(
	level_data: Dictionary,
	map_instance: Node,
	main_component: Dictionary
) -> Variant:
	var candidates: Array[Vector2i] = []
	for key: Variant in main_component.keys():
		if key is Vector2i and _is_safe_operator_spawn_tile(
			map_instance, key as Vector2i, main_component
		):
			candidates.append(key as Vector2i)
	if candidates.is_empty():
		return null
	var open_candidates := _filter_open_tiles(candidates, map_instance)
	var ranked_candidates := open_candidates if not open_candidates.is_empty() else candidates
	var anchor := _operator_spawn_anchor(level_data, map_instance)
	ranked_candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_distance := a.distance_squared_to(anchor)
		var b_distance := b.distance_squared_to(anchor)
		if a_distance != b_distance:
			return a_distance < b_distance
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x
	)
	return ranked_candidates[0]


func _operator_spawn_anchor(level_data: Dictionary, map_instance: Node) -> Vector2i:
	var compound_rect: Variant = level_data.get("compound_rect")
	if compound_rect is Rect2i and (compound_rect as Rect2i).has_area():
		return Vector2i((compound_rect as Rect2i).get_center())
	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		return player_spawn as Vector2i
	if map_instance is ProcGenTilemap:
		return (map_instance as ProcGenTilemap).get_player_spawn()
	return Vector2i.ZERO


func _disable_operator_until_safe_placement() -> void:
	var operator := get_node_or_null(operator_path) as Node2D
	if operator == null:
		return
	if _operator_failure_state.is_empty():
		_operator_failure_state = {
			"instance_id": operator.get_instance_id(),
			"visible": operator.visible,
			"process_mode": operator.process_mode,
		}
	operator.visible = false
	operator.process_mode = Node.PROCESS_MODE_DISABLED


func _restore_operator_after_safe_placement(operator: Node2D) -> void:
	if _operator_failure_state.is_empty():
		return
	if int(_operator_failure_state.get("instance_id", -1)) != operator.get_instance_id():
		_operator_failure_state.clear()
		return
	operator.visible = bool(_operator_failure_state.get("visible", true))
	operator.process_mode = int(
		_operator_failure_state.get("process_mode", Node.PROCESS_MODE_INHERIT)
	)
	_operator_failure_state.clear()


## A final Operator spawn must be painted walkable floor outside ingress
## clearance AND (on a ProcGenTilemap) pass canonical spawn validity, runtime
## walkability, and membership in the accepted main playable component.
## `main_component` comes from `ProcGenTilemap.get_main_playable_component()`;
## the loader owns no connectivity computation of its own.
func _is_safe_operator_spawn_tile(
	map_instance: Node,
	tile: Vector2i,
	main_component: Dictionary = {}
) -> bool:
	if _is_inside_ingress_clearance(map_instance, tile):
		return false
	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		return (
			pg.is_valid_spawn_cell(tile)
			and pg.is_runtime_navigation_walkable(tile)
			and main_component.has(tile)
		)
	return _is_walkable_floor_tile(map_instance, tile)


func _get_main_playable_component(map_instance: Node) -> Dictionary:
	if map_instance is ProcGenTilemap:
		return (map_instance as ProcGenTilemap).get_main_playable_component()
	return {}


func _world_to_tile(map_instance: Node, world_position: Vector2) -> Vector2i:
	if map_instance is ProcGenTilemap:
		return (map_instance as ProcGenTilemap).global_to_minimap_tile(world_position)
	if map_instance is Node2D:
		return Vector2i(((map_instance as Node2D).to_local(world_position) / fallback_tile_size).floor())
	return Vector2i((world_position / fallback_tile_size).floor())


func _position_spawn_nodes(level_data: Dictionary, map_instance: Node) -> void:
	var spawn_root := get_node_or_null(spawn_nodes_path)
	if spawn_root == null:
		return

	var nodes: Array[Node2D] = []
	for child in spawn_root.get_children():
		if child is Node2D:
			nodes.append(child as Node2D)
	if nodes.is_empty():
		return

	var compound_ingress_raw: Array = level_data.get("compound_ingress", [])
	var map_size_variant: Variant = level_data.get("map_size", Vector2i.ZERO)
	var corridor_spawns_raw: Array = level_data.get("corridor_spawns", [])
	var room_fallback_raw: Array = level_data.get("rooms_by_distance", [])
	var tiles: Array[Vector2i] = []
	for item in compound_ingress_raw:
		if item is Vector2i and map_size_variant is Vector2i:
			var projected := _project_ingress_to_edge(item as Vector2i, map_size_variant as Vector2i)
			tiles.append(projected)
	for item in corridor_spawns_raw:
		if item is Vector2i:
			tiles.append(item as Vector2i)
	if tiles.is_empty():
		for item in room_fallback_raw:
			if item is Vector2i:
				tiles.append(item as Vector2i)
	if tiles.is_empty():
		return

	for i in range(nodes.size()):
		var tile_index: int = 0
		if tiles.size() > 1 and nodes.size() > 1:
			tile_index = int(round(float(i) * float(tiles.size() - 1) / float(nodes.size() - 1)))
		tile_index = clamp(tile_index, 0, tiles.size() - 1)
		nodes[i].global_position = _tile_to_world(map_instance, tiles[tile_index])


func _refresh_camera(map_instance: Node) -> void:
	var camera := get_node_or_null(camera_path) as Node
	if camera == null:
		return
	if camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	if camera.has_method("snap_to_player_spawn"):
		var operator := get_node_or_null(operator_path) as Node2D
		if operator != null:
			camera.call("snap_to_player_spawn", operator.global_position)


func _rebuild_navigation(map_instance: Node) -> void:
	var nav := get_node_or_null(navigation_system_path)
	if nav == null:
		push_warning("[ContractWorldLoader] NavigationSystem not found at %s" % String(navigation_system_path))
		return
	if not nav.has_method("rebuild"):
		push_warning("[ContractWorldLoader] NavigationSystem missing rebuild method")
		return

	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		if nav.has_method("set_runtime_tilemaps"):
			nav.call("set_runtime_tilemaps", pg.floor_tilemap, pg.walls_tilemap, pg)
		else:
			if pg.floor_tilemap:
				nav.floor_tilemap = pg.floor_tilemap
			if pg.walls_tilemap:
				nav.walls_tilemap = pg.walls_tilemap
	nav.rebuild()
	print("[ContractWorldLoader] Navigation rebuilt with procgen tilemaps")


func get_active_map_instance() -> Node:
	return _active_procgen_map


func return_preloaded_map_to_bootstrap() -> bool:
	if _active_procgen_map == null or not is_instance_valid(_active_procgen_map):
		return false
	var bootstrap := get_node_or_null("/root/WorldContractBootstrap")
	if bootstrap == null:
		return false
	_active_procgen_map.visible = false
	_active_procgen_map.reparent(bootstrap)
	_active_procgen_map = null
	_contract_activation_result.clear()
	return bool(bootstrap.call("restore_ready_after_deployment_rollback")) if bootstrap.has_method("restore_ready_after_deployment_rollback") else true


func wait_for_contract_activation(max_frames: int = 3600) -> Dictionary:
	for _frame in range(maxi(1, max_frames)):
		if not _contract_activation_result.is_empty():
			return _contract_activation_result.duplicate(true)
		if not is_inside_tree() or get_tree() == null:
			return {"ready": false, "code": "LOADER_LEFT_TREE"}
		await get_tree().process_frame
	return {"ready": false, "code": "ACTIVATION_TIMEOUT"}


func _position_command_terminal(level_data: Dictionary, map_instance: Node) -> void:
	var terminal := get_node_or_null(command_terminal_path) as Node2D
	if terminal == null:
		return

	var compound_rect: Variant = level_data.get("compound_rect")
	var compound_tiles := _get_compound_walkable_tiles(level_data, map_instance)
	var main_component := _get_main_playable_component(map_instance)
	var player_spawn_tile := _pick_compound_spawn_tile(
		level_data, map_instance, main_component
	)
	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn_tile == Vector2i.ZERO and player_spawn is Vector2i:
		player_spawn_tile = player_spawn as Vector2i

	var target_tile := Vector2i.ZERO
	var semantic_anchor: Variant = level_data.get("compound_terminal_anchor", Vector2i.ZERO)
	if semantic_anchor is Vector2i and semantic_anchor != Vector2i.ZERO:
		target_tile = semantic_anchor
	if player_spawn_tile != Vector2i.ZERO:
		if target_tile == Vector2i.ZERO:
			target_tile = player_spawn_tile
	if compound_rect is Rect2i and target_tile == Vector2i.ZERO:
		target_tile = Vector2i((compound_rect as Rect2i).get_center())

	var chosen_tile := _pick_closest_tile(compound_tiles, target_tile)
	if chosen_tile == Vector2i.ZERO:
		chosen_tile = player_spawn_tile
	var operator := get_node_or_null(operator_path) as Node2D
	if operator != null:
		var operator_tile := _world_to_tile(map_instance, operator.global_position)
		if chosen_tile == operator_tile:
			var non_overlapping_tiles: Array[Vector2i] = []
			for tile in compound_tiles:
				if tile != operator_tile:
					non_overlapping_tiles.append(tile)
			if not non_overlapping_tiles.is_empty():
				chosen_tile = _pick_closest_tile(non_overlapping_tiles, target_tile)
	terminal.global_position = _tile_to_world(map_instance, chosen_tile)
	if operator != null and chosen_tile == _world_to_tile(map_instance, operator.global_position):
		# A compound with only its spawn tile still needs a walkable terminal
		# offset; its static body must not depenetrate the player during startup.
		terminal.global_position = operator.global_position + Vector2(32.0, 0.0)


func _position_construction_population(level_data: Dictionary, map_instance: Node) -> void:
	_place_population_node(
		get_node_or_null(field_fabricator_path) as Node2D,
		level_data,
		&"compound_fabricator_anchor",
		&"field_fabricator",
		map_instance
	)
	_place_population_node(
		get_node_or_null(fabrication_construction_zone_path) as Node2D,
		level_data,
		&"compound_construction_zone_anchor",
		&"construction_zone",
		map_instance
	)


func _place_population_node(
	node: Node2D,
	level_data: Dictionary,
	anchor_key: StringName,
	population_role: StringName,
	map_instance: Node
) -> void:
	if node == null:
		return
	var anchor: Variant = level_data.get(anchor_key)
	if not (anchor is Vector2i):
		_observe_population_placement(&"contract_population_placement_failed", level_data, {
			"population_role": population_role,
			"anchor_key": anchor_key,
			"reason": "missing_or_invalid_tile_anchor",
		})
		push_warning("[ContractWorldLoader] Missing Vector2i population anchor %s for %s" % [anchor_key, population_role])
		return
	if not map_instance.has_method("tile_to_global_position"):
		_observe_population_placement(&"contract_population_placement_failed", level_data, {
			"population_role": population_role,
			"anchor_key": anchor_key,
			"reason": "canonical_map_transform_unavailable",
		})
		push_warning("[ContractWorldLoader] Map lacks canonical tile_to_global_position for %s" % population_role)
		return
	node.global_position = map_instance.call("tile_to_global_position", anchor as Vector2i)
	_observe_population_placement(&"contract_population_placed", level_data, {
		"population_role": population_role,
		"anchor_key": anchor_key,
		"anchor_tile": anchor,
	})


func _observe_population_placement(event_name: StringName, level_data: Dictionary, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("log_event"):
		return
	var event_payload := payload.duplicate(true)
	event_payload["generation_id"] = level_data.get("generation_id", level_data.get("seed", "unknown"))
	observatory.call("log_event", event_name, event_payload)


func _position_item_anchors(level_data: Dictionary, map_instance: Node) -> void:
	var items_root := get_node_or_null(items_root_path)
	if items_root == null:
		return

	var random_floor_tiles_raw: Array = level_data.get("random_floor_tiles", [])
	var room_tiles_raw: Array = level_data.get("rooms_by_distance", [])
	var available_tiles: Array[Vector2i] = []
	for tile in random_floor_tiles_raw:
		if tile is Vector2i:
			available_tiles.append(tile as Vector2i)
	if available_tiles.is_empty():
		for tile in room_tiles_raw:
			if tile is Vector2i:
				available_tiles.append(tile as Vector2i)
	if available_tiles.is_empty():
		return

	available_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.x == b.x and a.y < b.y or a.x < b.x)

	var player_spawn: Variant = level_data.get("player_spawn")
	var target_tile := Vector2i.ZERO
	if player_spawn is Vector2i:
		target_tile = player_spawn as Vector2i

	var ordered_tiles := available_tiles.duplicate()
	if target_tile != Vector2i.ZERO:
		ordered_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(target_tile) < b.distance_squared_to(target_tile))

	var used_tiles: Dictionary = {}
	var tile_index := 0
	for child in items_root.get_children():
		if not (child is Node2D):
			continue
		while tile_index < ordered_tiles.size() and used_tiles.has(ordered_tiles[tile_index]):
			tile_index += 1
		if tile_index >= ordered_tiles.size():
			break
		var tile: Vector2i = ordered_tiles[tile_index]
		used_tiles[tile] = true
		(child as Node2D).global_position = _tile_to_world(map_instance, tile)
		tile_index += 1


func _position_tutorial_resource_nodes(level_data: Dictionary, map_instance: Node) -> void:
	var items_root := get_node_or_null(items_root_path)
	if items_root == null:
		return
	for child in items_root.get_children():
		if child.is_in_group("generated_tutorial_resource_node"):
			child.queue_free()
	if tutorial_resource_node_count <= 0:
		return

	var candidate_tiles := _build_tutorial_resource_candidate_tiles(level_data, map_instance)
	if candidate_tiles.is_empty():
		return

	var presets := _get_tutorial_resource_presets()
	var placed_tiles: Array[Vector2i] = []
	var max_nodes: int = mini(tutorial_resource_node_count, presets.size())
	for preset_index in range(max_nodes):
		var preset: Dictionary = presets[preset_index]
		var chosen_tile := _pick_tutorial_resource_tile(candidate_tiles, placed_tiles)
		if chosen_tile == Vector2i.ZERO:
			continue
		var node := _instantiate_generated_resource_node(
			items_root,
			preset,
			"TutorialResource_%s" % String(preset.get("node_kind", "resource")),
			"generated_tutorial_resource_node"
		)
		if node == null:
			continue
		node.global_position = _tile_to_world(map_instance, chosen_tile)
		placed_tiles.append(chosen_tile)


func _position_expedition_resource_nodes(level_data: Dictionary, map_instance: Node) -> void:
	var items_root := get_node_or_null(items_root_path)
	if items_root == null:
		return
	for child in items_root.get_children():
		if child.is_in_group("generated_expedition_resource_node"):
			child.queue_free()
	if expedition_resource_node_count <= 0:
		return

	var candidate_tiles := _build_expedition_resource_candidate_tiles(level_data, map_instance)
	if candidate_tiles.is_empty():
		return

	var presets := _get_expedition_resource_presets()
	if presets.is_empty():
		return

	var placed_tiles: Array[Vector2i] = []
	for preset_index in range(expedition_resource_node_count):
		var preset: Dictionary = presets[preset_index % presets.size()]
		var chosen_tile := _pick_expedition_resource_tile(candidate_tiles, placed_tiles, preset_index)
		if chosen_tile == Vector2i.ZERO:
			continue
		var node := _instantiate_generated_resource_node(
			items_root,
			preset,
			"ExpeditionResource_%02d_%s" % [preset_index + 1, String(preset.get("node_kind", "resource"))],
			"generated_expedition_resource_node"
		)
		if node == null:
			continue
		node.global_position = _tile_to_world(map_instance, chosen_tile)
		placed_tiles.append(chosen_tile)


func _instantiate_generated_resource_node(items_root: Node, preset: Dictionary, node_name: String, group_name: String) -> ResourceNode:
	var node := RESOURCE_NODE_SCENE.instantiate() as ResourceNode
	if node == null:
		return null
	node.name = node_name
	node.add_to_group(group_name)
	_apply_resource_node_preset(node, preset)
	items_root.add_child(node)
	return node


func _build_tutorial_resource_candidate_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	var raw_tiles: Array = level_data.get("floor_cells", [])
	if raw_tiles.is_empty():
		raw_tiles = level_data.get("random_floor_tiles", [])
	var player_spawn: Variant = level_data.get("player_spawn")
	var spawn_tile := player_spawn as Vector2i if player_spawn is Vector2i else Vector2i.ZERO
	var min_dist_sq := tutorial_resource_min_distance_tiles * tutorial_resource_min_distance_tiles
	var max_dist_sq := tutorial_resource_max_distance_tiles * tutorial_resource_max_distance_tiles
	var compound_rect: Rect2i = level_data.get("compound_rect", Rect2i()) as Rect2i

	for tile_variant in raw_tiles:
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if seen.has(tile):
			continue
		seen[tile] = true
		if _is_protected_world_presentation_tile(map_instance, tile):
			continue
		if not _is_walkable_floor_tile(map_instance, tile):
			continue
		if compound_rect.size.x > 0 and compound_rect.size.y > 0 and compound_rect.has_point(tile):
			continue
		var dist_sq := tile.distance_squared_to(spawn_tile)
		if dist_sq < min_dist_sq or dist_sq > max_dist_sq:
			continue
		if _count_walkable_neighbors(map_instance, tile) < 3:
			continue
		candidates.append(tile)

	if candidates.is_empty():
		for tile_variant in raw_tiles:
			if not tile_variant is Vector2i:
				continue
			var tile := tile_variant as Vector2i
			if _is_protected_world_presentation_tile(map_instance, tile):
				continue
			if _is_walkable_floor_tile(map_instance, tile):
				candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score := _stable_resource_tile_score(a, spawn_tile)
		var b_score := _stable_resource_tile_score(b, spawn_tile)
		if a_score == b_score:
			return a.x == b.x and a.y < b.y or a.x < b.x
		return a_score < b_score
	)
	return candidates


func _build_expedition_resource_candidate_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	var raw_tiles: Array = level_data.get("floor_cells", [])
	if raw_tiles.is_empty():
		raw_tiles = level_data.get("random_floor_tiles", [])
	var player_spawn: Variant = level_data.get("player_spawn")
	var spawn_tile := player_spawn as Vector2i if player_spawn is Vector2i else Vector2i.ZERO
	var min_dist_sq := expedition_resource_min_distance_tiles * expedition_resource_min_distance_tiles
	var compound_rect: Rect2i = level_data.get("compound_rect", Rect2i()) as Rect2i
	var road_tiles := _build_tile_lookup(level_data.get("main_road_tiles", []))
	var parking_tiles := _build_tile_lookup(level_data.get("parking_zone_tiles", []))

	for tile_variant in raw_tiles:
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if seen.has(tile):
			continue
		seen[tile] = true
		if not _is_expedition_resource_candidate(tile, spawn_tile, min_dist_sq, compound_rect, road_tiles, parking_tiles, map_instance):
			continue
		candidates.append(tile)

	if candidates.is_empty():
		seen.clear()
		for tile_variant in raw_tiles:
			if not (tile_variant is Vector2i):
				continue
			var tile := tile_variant as Vector2i
			if seen.has(tile):
				continue
			seen[tile] = true
			if _is_fallback_expedition_resource_candidate(tile, compound_rect, road_tiles, parking_tiles, map_instance):
				candidates.append(tile)

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score := _stable_expedition_resource_tile_score(a, spawn_tile)
		var b_score := _stable_expedition_resource_tile_score(b, spawn_tile)
		if a_score == b_score:
			return a.x == b.x and a.y < b.y or a.x < b.x
		return a_score < b_score
	)
	return candidates


func _is_expedition_resource_candidate(
	tile: Vector2i,
	spawn_tile: Vector2i,
	min_dist_sq: int,
	compound_rect: Rect2i,
	road_tiles: Dictionary,
	parking_tiles: Dictionary,
	map_instance: Node
) -> bool:
	if spawn_tile != Vector2i.ZERO and tile.distance_squared_to(spawn_tile) < min_dist_sq:
		return false
	if not _is_fallback_expedition_resource_candidate(tile, compound_rect, road_tiles, parking_tiles, map_instance):
		return false
	return _get_map_tile_intensity(map_instance, tile) >= expedition_resource_min_intensity


func _is_fallback_expedition_resource_candidate(
	tile: Vector2i,
	compound_rect: Rect2i,
	road_tiles: Dictionary,
	parking_tiles: Dictionary,
	map_instance: Node
) -> bool:
	if compound_rect.size.x > 0 and compound_rect.size.y > 0 and compound_rect.has_point(tile):
		return false
	if _is_protected_world_presentation_tile(map_instance, tile):
		return false
	if road_tiles.has(tile) or parking_tiles.has(tile):
		return false
	if _is_excluded_resource_region(_get_map_region_type(map_instance, tile)):
		return false
	if not _is_walkable_floor_tile(map_instance, tile):
		return false
	return _count_walkable_neighbors(map_instance, tile) >= 3


func _is_protected_world_presentation_tile(
	map_instance: Node,
	tile: Vector2i
) -> bool:
	return (
		map_instance != null
		and map_instance.has_method("is_sundered_keep_frontage_protected")
		and bool(map_instance.call("is_sundered_keep_frontage_protected", tile))
	)


func _pick_expedition_resource_tile(candidates: Array[Vector2i], placed_tiles: Array[Vector2i], preset_index: int) -> Vector2i:
	if candidates.is_empty():
		return Vector2i.ZERO
	var start_index := preset_index % candidates.size()
	for offset in range(candidates.size()):
		var tile: Vector2i = candidates[(start_index + offset) % candidates.size()]
		if not _is_far_enough_from_resource_tiles(tile, placed_tiles, expedition_resource_min_spacing_tiles):
			continue
		return tile
	for offset in range(candidates.size()):
		var tile: Vector2i = candidates[(start_index + offset) % candidates.size()]
		if _is_far_enough_from_resource_tiles(tile, placed_tiles, maxi(2, int(expedition_resource_min_spacing_tiles / 2))):
			return tile
	return Vector2i.ZERO


func _pick_tutorial_resource_tile(candidates: Array[Vector2i], placed_tiles: Array[Vector2i]) -> Vector2i:
	for tile in candidates:
		if not _is_far_enough_from_resource_tiles(tile, placed_tiles, tutorial_resource_min_spacing_tiles):
			continue
		return tile
	for tile in candidates:
		if _is_far_enough_from_resource_tiles(tile, placed_tiles, maxi(2, int(tutorial_resource_min_spacing_tiles / 2))):
			return tile
	return Vector2i.ZERO


func _is_far_enough_from_resource_tiles(tile: Vector2i, placed_tiles: Array[Vector2i], min_spacing: int) -> bool:
	var min_dist_sq := min_spacing * min_spacing
	for placed in placed_tiles:
		if tile.distance_squared_to(placed) < min_dist_sq:
			return false
	return true


func _stable_resource_tile_score(tile: Vector2i, anchor_tile: Vector2i) -> int:
	return WorldPlacementContext.stable_seed([
		tile.x, tile.y, anchor_tile.x, anchor_tile.y, tutorial_resource_node_count,
	])


func _stable_expedition_resource_tile_score(tile: Vector2i, anchor_tile: Vector2i) -> int:
	return WorldPlacementContext.stable_seed([
		tile.x, tile.y, anchor_tile.x, anchor_tile.y,
		expedition_resource_node_count, expedition_resource_min_distance_tiles,
	])


func _get_tutorial_resource_presets() -> Array[Dictionary]:
	return [
		{
			"node_kind": "blackwood_deadfall",
			"harvest_label": "CUT",
			"resource_id": "blackwood",
			"work_required": 5,
			"yield_amount": 6,
			"secondary_yields": {"ruin_scrap": 1},
			"standing_color": Color(0.16, 0.1, 0.075, 1.0),
			"depleted_color": Color(0.07, 0.055, 0.045, 1.0),
			"prompt_resource_label": "BLACKWOOD",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/blackwood_deadfall/blackwood_deadfall__node__depleted__1f__96.png",
			"idle_fx_sheet_path": "res://content/sprites/effects/harvesting_nodes/blackwood_deadfall/props__harvesting_nodes__blackwood_deadfall__node__fx_idle__5f__96.png",
			"strike_fx_sheet_path": "res://content/sprites/effects/harvesting_nodes/blackwood_deadfall/props__harvesting_nodes__blackwood_deadfall__node__fx_strike_idle__5f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "alloy_vein",
			"harvest_label": "MINE",
			"resource_id": "structural_alloy",
			"work_required": 4,
			"yield_amount": 5,
			"secondary_yields": {"ruin_scrap": 2},
			"standing_color": Color(0.25, 0.28, 0.31, 1.0),
			"depleted_color": Color(0.08, 0.085, 0.09, 1.0),
			"prompt_resource_label": "STRUCTURAL ALLOY",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/exposed_alloy_vein/exposed_alloy_vein__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/exposed_alloy_vein/exposed_alloy_vein__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "machine_wreckage",
			"harvest_label": "SALVAGE",
			"resource_id": "ruin_scrap",
			"work_required": 2,
			"yield_amount": 10,
			"secondary_yields": {"capacitor_dust": 1},
			"standing_color": Color(0.18, 0.18, 0.17, 1.0),
			"depleted_color": Color(0.07, 0.07, 0.065, 1.0),
			"prompt_resource_label": "RUIN SCRAP",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/collapsed_machine_shell/collapsed_machine_shell__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/collapsed_machine_shell/collapsed_machine_shell__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "fungal_resin_pod",
			"harvest_label": "CUT",
			"resource_id": "resin_clot",
			"work_required": 3,
			"yield_amount": 4,
			"secondary_yields": {"fiber_moss": 2},
			"standing_color": Color(0.28, 0.18, 0.09, 1.0),
			"depleted_color": Color(0.09, 0.06, 0.04, 1.0),
			"prompt_resource_label": "RESIN CLOT",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/fungal_resin_pod/fungal_resin_pod__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/fungal_resin_pod/fungal_resin_pod__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "ruptured_capacitor_bank",
			"harvest_label": "SALVAGE",
			"resource_id": "capacitor_dust",
			"work_required": 3,
			"yield_amount": 6,
			"secondary_yields": {"power_components": 1, "ruin_scrap": 1},
			"standing_color": Color(0.18, 0.2, 0.24, 1.0),
			"depleted_color": Color(0.06, 0.065, 0.075, 1.0),
			"prompt_resource_label": "CAPACITOR DUST",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/ruptured_capacitor_bank/ruptured_capacitor_bank__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/ruptured_capacitor_bank/ruptured_capacitor_bank__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "broken_signal_relay",
			"harvest_label": "EXTRACT",
			"resource_id": "signal_filament",
			"work_required": 4,
			"yield_amount": 1,
			"secondary_yields": {"capacitor_dust": 2, "ruin_scrap": 2},
			"standing_color": Color(0.1, 0.2, 0.24, 1.0),
			"depleted_color": Color(0.045, 0.06, 0.065, 1.0),
			"prompt_resource_label": "SIGNAL FILAMENT",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/broken_signal_relay/broken_signal_relay__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/broken_signal_relay/broken_signal_relay__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
		{
			"node_kind": "shattered_archive_terminal",
			"harvest_label": "EXTRACT",
			"resource_id": "memory_glass_fragment",
			"work_required": 4,
			"yield_amount": 2,
			"secondary_yields": {"signal_filament": 1},
			"standing_color": Color(0.15, 0.16, 0.24, 1.0),
			"depleted_color": Color(0.05, 0.052, 0.07, 1.0),
			"prompt_resource_label": "MEMORY GLASS",
			"idle_sheet_path": "res://content/sprites/props/harvesting_nodes/shattered_archive_terminal/shattered_archive_terminal__node__idle__5f__96.png",
			"depleted_sheet_path": "res://content/sprites/props/harvesting_nodes/shattered_archive_terminal/shattered_archive_terminal__node__depleted__1f__96.png",
			"sprite_playback_mode": "harvest_states",
		},
	]


func _get_expedition_resource_presets() -> Array[Dictionary]:
	return _get_tutorial_resource_presets()


func _apply_resource_node_preset(node: ResourceNode, preset: Dictionary) -> void:
	for key in preset.keys():
		node.set(String(key), preset[key])


func _position_arrn_relays(level_data: Dictionary, map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return
	var relay_root := world.get_node_or_null("ARRNRelays") as Node2D
	if relay_root == null:
		relay_root = Node2D.new()
		relay_root.name = "ARRNRelays"
		world.add_child(relay_root)
	for child in relay_root.get_children():
		child.queue_free()

	var relay_specs := [
		{"relay_id": &"R_NORTH", "sector_id": &"T_NORTH", "anchor": Vector2(0.50, 0.16)},
		{"relay_id": &"R_SOUTH", "sector_id": &"T_SOUTH", "anchor": Vector2(0.50, 0.84)},
		{"relay_id": &"R_ARCHIVE", "sector_id": &"ARCHIVE", "anchor": Vector2(0.18, 0.50)},
		{"relay_id": &"R_GATEWAY", "sector_id": &"GATEWAY", "anchor": Vector2(0.84, 0.50)},
	]
	var used_tiles: Dictionary = {}
	for spec in relay_specs:
		var tile := _pick_arrn_relay_tile(level_data, spec["anchor"], used_tiles)
		if tile == Vector2i.ZERO:
			continue
		used_tiles[tile] = true
		var relay := ARRN_RELAY_SCENE.instantiate() as Node2D
		relay.name = String(spec["relay_id"])
		relay.set("relay_id", spec["relay_id"])
		relay.set("sector_id", spec["sector_id"])
		relay.global_position = _tile_to_world(map_instance, tile)
		relay_root.add_child(relay)
		var arrn_manager := get_node_or_null("/root/ARRNManager")
		if arrn_manager != null and arrn_manager.has_method("set_relay_world_position"):
			arrn_manager.call("set_relay_world_position", spec["relay_id"], relay.global_position)


func _place_gothic_compound_connection(level_data: Dictionary, map_instance: Node) -> void:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return

	var connected_root := world.get_node_or_null("ConnectedMaps") as Node2D
	if connected_root == null:
		connected_root = Node2D.new()
		connected_root.name = "ConnectedMaps"
		world.add_child(connected_root)
	for child in connected_root.get_children():
		if child.is_in_group("generated_gothic_compound_connection"):
			child.queue_free()
	for child in world.get_children():
		if child.is_in_group("generated_gothic_compound_connection") and child.get_parent() == world:
			child.queue_free()

	var main_gate_tile := _pick_gothic_compound_gate_tile(level_data, map_instance)
	if main_gate_tile == Vector2i.ZERO:
		return
	var main_gate_position := _tile_to_world(map_instance, main_gate_tile)

	var gothic_map := GOTHIC_COMPOUND_MAP_SCRIPT.new() as Node2D
	if gothic_map == null:
		return
	gothic_map.name = "GothicCompoundMap"
	gothic_map.add_to_group("generated_gothic_compound_connection")
	gothic_map.global_position = _get_gothic_compound_world_offset(level_data, map_instance)
	gothic_map.call("configure_connection", map_instance, main_gate_position)
	connected_root.add_child(gothic_map)

	var main_gate := GOTHIC_COMPOUND_TRAVEL_GATE_SCRIPT.new() as Node2D
	if main_gate == null:
		return
	main_gate.name = "GothicCompoundTravelGate"
	main_gate.add_to_group("generated_gothic_compound_connection")
	main_gate.call("configure", gothic_map, 0, "ENTER CARROW YARD")
	main_gate.global_position = main_gate_position
	world.add_child(main_gate)


func _place_sundered_keep_connection(level_data: Dictionary, map_instance: Node) -> void:
	# Legacy non-registered fallback. Production uses the registered route and
	# places its world-map Vista through _place_registered_world_ingresses().
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return

	var connected_root := world.get_node_or_null("ConnectedMaps") as Node2D
	if connected_root == null:
		connected_root = Node2D.new()
		connected_root.name = "ConnectedMaps"
		world.add_child(connected_root)
	for child in connected_root.get_children():
		if child.is_in_group("generated_sundered_keep_connection"):
			child.queue_free()
	for child in world.get_children():
		if child.is_in_group("generated_sundered_keep_connection") and child.get_parent() == world:
			child.queue_free()

	var ingress_tile := _pick_sundered_keep_gate_tile(level_data, map_instance)
	if ingress_tile == Vector2i.ZERO:
		return
	var ingress_position := _tile_to_world(map_instance, ingress_tile)

	var ingress := WORLD_INGRESS_SITE_SCRIPT.new() as Area2D
	if ingress == null:
		return
	ingress.name = "SunderedKeepIngressSite"
	ingress.add_to_group("generated_sundered_keep_connection")
	var level_loader := _ensure_level_loader(world)
	if level_loader != null:
		ingress.call("configure_level", SUNDERED_KEEP_LEVEL_ID, map_instance)
		var definition: RefCounted = level_loader.call("get_definition", SUNDERED_KEEP_LEVEL_ID) as RefCounted
		if definition != null:
			ingress.call("apply_ingress_definition", definition.ingress)
		else:
			ingress.set("prompt_text", "APPROACH SUNDERED KEEP")
	else:
		ingress.set("prompt_text", "APPROACH SUNDERED KEEP")
	ingress.global_position = ingress_position
	world.add_child(ingress)

	if place_debug_sundered_keep_gateway:
		var keep_map := _create_debug_sundered_keep_map(connected_root, level_data, map_instance, ingress_position)
		if keep_map != null:
			_place_debug_sundered_keep_gateway(world, keep_map, level_data, map_instance, ingress_tile)

	if debug_start_near_sundered_keep_entrance:
		var operator := get_node_or_null(operator_path) as Node2D
		if operator != null:
			operator.global_position = ingress.global_position + debug_sundered_keep_start_offset


func _place_registered_world_ingresses(level_data: Dictionary, map_instance: Node) -> bool:
	var world := get_node_or_null(world_path) as Node2D
	if world == null:
		return false
	var spawner := world.get_node_or_null("WorldIngressSpawner")
	if spawner == null:
		spawner = WORLD_INGRESS_SPAWNER_SCRIPT.new()
		spawner.name = "WorldIngressSpawner"
		spawner.set("fallback_tile_size", fallback_tile_size)
		world.add_child(spawner)
	var loader := _ensure_level_loader(world)
	var placed_ingresses := (
		spawner.call(
			"place_all",
			level_data,
			map_instance,
			world,
			loader
		) as Array
	)
	var placements := spawner.call("get_last_placements") as Dictionary
	if not placements.has("forlorn_ritualant_underground"):
		var placement_errors := Array(spawner.call("get_last_errors"))
		push_error(
			"[ContractWorldLoader] Required Ritualant ingress missing "
			+ "after accepted-world placement"
		)
		_on_contract_generation_failed({
			"generation_failed": true,
			"failure_reason": "required_world_ingress_missing",
			"ingress_id": "forlorn_ritualant_underground",
			"placement_errors": placement_errors,
		})
		return false
	_place_sundered_keep_world_vista(
		world,
		placed_ingresses,
		map_instance,
		level_data
	)
	return true


func _place_sundered_keep_world_vista(
	world: Node2D,
	placed_ingresses: Array,
	map_instance: Node,
	level_data: Dictionary
) -> void:
	var landmarks := world.get_node_or_null("WorldLandmarks") as Node2D
	if landmarks == null:
		landmarks = Node2D.new()
		landmarks.name = "WorldLandmarks"
		landmarks.add_to_group(WORLD_ORIGIN_BRANCH_GROUP)
		world.add_child(landmarks)
	for child: Node in landmarks.get_children():
		if child.is_in_group("generated_sundered_keep_world_vista"):
			child.free()
	for node_variant: Variant in placed_ingresses:
		var ingress := node_variant as Node
		if (
			ingress == null
			or not ingress.is_in_group(
				"generated_sundered_keep_connection"
			)
		):
			continue
		var visual_spawner := (
			SUNDERED_KEEP_FRONTAGE_VISUAL_SPAWNER_SCRIPT.new()
		)
		var vista := visual_spawner.call(
			"spawn",
			landmarks,
			ingress,
			map_instance,
			level_data
		) as Node2D
		if vista == null:
			push_warning(
				"[ContractWorldLoader] Could not instantiate "
				+ "Sundered Keep procgen frontage presentation"
			)
			return
		return


func _ensure_level_loader(world: Node) -> Node:
	var existing := world.get_node_or_null("LevelLoader")
	if existing != null:
		return existing
	var loader := LEVEL_LOADER_SCRIPT.new()
	loader.name = "LevelLoader"
	world.add_child(loader)
	return loader


func _create_debug_sundered_keep_map(
	connected_root: Node2D,
	level_data: Dictionary,
	map_instance: Node,
	return_position: Vector2
) -> Node2D:
	var keep_map := SUNDERED_KEEP_MAP_SCRIPT.new() as Node2D
	if keep_map == null:
		return null
	keep_map.name = "SunderedKeepMap"
	keep_map.add_to_group("generated_sundered_keep_connection")
	keep_map.global_position = _get_sundered_keep_world_offset(level_data, map_instance)
	keep_map.call("configure_connection", map_instance, return_position)
	connected_root.add_child(keep_map)
	return keep_map


func _place_debug_sundered_keep_gateway(
	world: Node2D,
	keep_map: Node2D,
	level_data: Dictionary,
	map_instance: Node,
	fallback_gate_tile: Vector2i
) -> void:
	var debug_tile := _pick_sundered_keep_debug_gateway_tile(level_data, map_instance, fallback_gate_tile)
	if debug_tile == Vector2i.ZERO:
		return

	var debug_gate := GOTHIC_COMPOUND_TRAVEL_GATE_SCRIPT.new() as Node2D
	if debug_gate == null:
		return
	debug_gate.name = "DebugSunderedKeepTravelGate"
	debug_gate.add_to_group("generated_sundered_keep_connection")
	debug_gate.call("configure", keep_map, 0, "DEBUG: ENTER SUNDERED KEEP")
	debug_gate.global_position = _tile_to_world(map_instance, debug_tile)
	world.add_child(debug_gate)


func _pick_gothic_compound_gate_tile(level_data: Dictionary, map_instance: Node) -> Vector2i:
	var compound_rect_variant: Variant = level_data.get("compound_rect")
	var ingress_tiles: Array[Vector2i] = []
	for item in level_data.get("compound_ingress", []):
		if item is Vector2i:
			ingress_tiles.append(item as Vector2i)
	if compound_rect_variant is Rect2i and not ingress_tiles.is_empty():
		var compound_rect := compound_rect_variant as Rect2i
		var preferred_ingress := ingress_tiles[0]
		var direction := -_get_compound_ingress_direction(preferred_ingress, compound_rect)
		for depth in range(3, 10):
			var candidate: Vector2i = preferred_ingress + direction * depth
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return preferred_ingress

	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		var spawn_tile := player_spawn as Vector2i
		for offset in [Vector2i(0, 8), Vector2i(8, 0), Vector2i(-8, 0), Vector2i(0, -8)]:
			var candidate: Vector2i = spawn_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return spawn_tile
	return Vector2i.ZERO


func _pick_sundered_keep_gate_tile(level_data: Dictionary, map_instance: Node) -> Vector2i:
	var gothic_gate_tile := _pick_gothic_compound_gate_tile(level_data, map_instance)
	var offsets := [
		Vector2i(4, 0),
		Vector2i(-4, 0),
		Vector2i(0, 4),
		Vector2i(0, -4),
		Vector2i(6, 2),
		Vector2i(-6, 2),
	]
	if gothic_gate_tile != Vector2i.ZERO:
		for offset in offsets:
			var candidate: Vector2i = gothic_gate_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return gothic_gate_tile

	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		var spawn_tile := player_spawn as Vector2i
		for offset in [Vector2i(0, 12), Vector2i(12, 0), Vector2i(-12, 0), Vector2i(0, -12)]:
			var candidate: Vector2i = spawn_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		return spawn_tile
	return Vector2i.ZERO


func _pick_sundered_keep_debug_gateway_tile(level_data: Dictionary, map_instance: Node, fallback_gate_tile: Vector2i) -> Vector2i:
	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		var spawn_tile := player_spawn as Vector2i
		for offset in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3), Vector2i(5, 2), Vector2i(-5, 2)]:
			var candidate: Vector2i = spawn_tile + offset
			if _is_walkable_floor_tile(map_instance, candidate):
				return candidate
		if _is_walkable_floor_tile(map_instance, spawn_tile):
			return spawn_tile

	for offset in [Vector2i(2, 2), Vector2i(-2, 2), Vector2i(2, -2), Vector2i(-2, -2), Vector2i(4, 0), Vector2i(-4, 0)]:
		var fallback_candidate: Vector2i = fallback_gate_tile + offset
		if _is_walkable_floor_tile(map_instance, fallback_candidate):
			return fallback_candidate
	return fallback_gate_tile


func _get_gothic_compound_world_offset(level_data: Dictionary, map_instance: Node) -> Vector2:
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var tile_size := Vector2(fallback_tile_size, fallback_tile_size)
	if map_instance is ProcGenTilemap:
		tile_size = (map_instance as ProcGenTilemap).get_runtime_tile_size()
	var width_px := float(maxi(map_size.x, 96)) * tile_size.x
	return Vector2(width_px + 1800.0, 0.0)


func _get_sundered_keep_world_offset(level_data: Dictionary, map_instance: Node) -> Vector2:
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var tile_size := Vector2(fallback_tile_size, fallback_tile_size)
	if map_instance is ProcGenTilemap:
		tile_size = (map_instance as ProcGenTilemap).get_runtime_tile_size()
	var width_px := float(maxi(map_size.x, 96)) * tile_size.x
	return Vector2(width_px + 4700.0, 0.0)


func _pick_arrn_relay_tile(level_data: Dictionary, anchor: Vector2, used_tiles: Dictionary) -> Vector2i:
	var floor_tiles: Array[Vector2i] = []
	for tile in level_data.get("floor_cells", []):
		if tile is Vector2i:
			floor_tiles.append(tile as Vector2i)
	if floor_tiles.is_empty():
		for tile in level_data.get("rooms_by_distance", []):
			if tile is Vector2i:
				floor_tiles.append(tile as Vector2i)
	if floor_tiles.is_empty():
		return Vector2i.ZERO

	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	var target := Vector2i(
		int(round(float(map_size.x) * anchor.x)),
		int(round(float(map_size.y) * anchor.y))
	) if map_size != Vector2i.ZERO else floor_tiles[0]
	floor_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(target) < b.distance_squared_to(target))
	for tile in floor_tiles:
		if used_tiles.has(tile):
			continue
		return tile
	return floor_tiles[0]


func _position_vehicles(level_data: Dictionary, map_instance: Node) -> void:
	var vehicle_root := get_node_or_null(vehicle_root_path)
	if vehicle_root == null:
		return

	var vehicle_nodes: Array[Node2D] = []
	for child in vehicle_root.get_children():
		if child is Node2D and child.is_in_group("vehicle"):
			vehicle_nodes.append(child as Node2D)
	if vehicle_nodes.is_empty():
		return

	var parking_tiles := _filter_open_tiles(_get_parking_zone_tiles(level_data, map_instance), map_instance)
	if not parking_tiles.is_empty():
		_position_vehicle_nodes_on_tiles(vehicle_nodes, parking_tiles, level_data, map_instance)
		return

	var compound_tiles := _filter_open_compound_tiles(_get_compound_walkable_tiles(level_data, map_instance), map_instance)
	if compound_tiles.is_empty():
		compound_tiles = _get_compound_walkable_tiles(level_data, map_instance)
	if compound_tiles.is_empty():
		return

	var main_component := _get_main_playable_component(map_instance)
	var anchor_tile := _pick_compound_spawn_tile(
		level_data, map_instance, main_component
	)
	var player_spawn: Variant = level_data.get("player_spawn")
	if anchor_tile == Vector2i.ZERO and player_spawn is Vector2i:
		anchor_tile = player_spawn as Vector2i

	var ordered_tiles := compound_tiles.duplicate()
	if anchor_tile != Vector2i.ZERO:
		ordered_tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(anchor_tile) < b.distance_squared_to(anchor_tile))

	var used_tiles: Dictionary = {}
	for vehicle in vehicle_nodes:
		var chosen_tile := Vector2i.ZERO
		for tile in ordered_tiles:
			if used_tiles.has(tile):
				continue
			var dist_sq: int = tile.distance_squared_to(anchor_tile)
			if dist_sq < 16:
				continue
			chosen_tile = tile
			break
		if chosen_tile == Vector2i.ZERO:
			for tile in ordered_tiles:
				if not used_tiles.has(tile):
					chosen_tile = tile
					break
		if chosen_tile == Vector2i.ZERO:
			continue
		used_tiles[chosen_tile] = true
		vehicle.global_position = _tile_to_world(map_instance, chosen_tile)


func _position_vehicle_nodes_on_tiles(vehicle_nodes: Array[Node2D], tiles: Array[Vector2i], level_data: Dictionary, map_instance: Node) -> void:
	var anchor_tile := Vector2i.ZERO
	var player_spawn: Variant = level_data.get("player_spawn")
	if player_spawn is Vector2i:
		anchor_tile = player_spawn as Vector2i
	var ordered_tiles := tiles.duplicate()
	if anchor_tile != Vector2i.ZERO:
		ordered_tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var a_score := a.distance_squared_to(anchor_tile)
			var b_score := b.distance_squared_to(anchor_tile)
			if a_score == b_score:
				return a.x == b.x and a.y < b.y or a.x < b.x
			return a_score < b_score
		)
	var used_tiles: Dictionary = {}
	for vehicle in vehicle_nodes:
		var chosen_tile := Vector2i.ZERO
		for tile in ordered_tiles:
			if used_tiles.has(tile):
				continue
			if anchor_tile != Vector2i.ZERO and tile.distance_squared_to(anchor_tile) < 9:
				continue
			chosen_tile = tile
			break
		if chosen_tile == Vector2i.ZERO:
			for tile in ordered_tiles:
				if not used_tiles.has(tile):
					chosen_tile = tile
					break
		if chosen_tile == Vector2i.ZERO:
			continue
		used_tiles[chosen_tile] = true
		vehicle.global_position = _tile_to_world(map_instance, chosen_tile)


func _get_parking_zone_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile_variant in level_data.get("parking_zone_tiles", []):
		if tile_variant is Vector2i and _is_walkable_floor_tile(map_instance, tile_variant as Vector2i):
			tiles.append(tile_variant as Vector2i)
	if not tiles.is_empty():
		return tiles
	for tile_variant in level_data.get("main_road_tiles", []):
		if tile_variant is Vector2i and _is_walkable_floor_tile(map_instance, tile_variant as Vector2i):
			tiles.append(tile_variant as Vector2i)
	return tiles


func _project_ingress_to_edge(ingress: Vector2i, map_size: Vector2i) -> Vector2i:
	var left: int = ingress.x
	var right: int = (map_size.x - 1) - ingress.x
	var top: int = ingress.y
	var bottom: int = (map_size.y - 1) - ingress.y
	var best: int = min(min(left, right), min(top, bottom))
	var margin: int = 1
	if best == left:
		return Vector2i(margin, ingress.y)
	if best == right:
		return Vector2i(map_size.x - 1 - margin, ingress.y)
	if best == top:
		return Vector2i(ingress.x, margin)
	return Vector2i(ingress.x, map_size.y - 1 - margin)


func _tile_to_world(map_instance: Node, tile: Vector2i) -> Vector2:
	if map_instance is ProcGenTilemap:
		var pg: ProcGenTilemap = map_instance as ProcGenTilemap
		if pg.floor_tilemap != null:
			var tm: TileMapLayer = pg.floor_tilemap
			var local := tm.map_to_local(tile)
			return tm.to_global(local)
	if map_instance is Node2D:
		return (map_instance as Node2D).global_position + Vector2(tile) * fallback_tile_size
	return Vector2(tile) * fallback_tile_size


func _pick_closest_tile(tiles: Array[Vector2i], target_tile: Vector2i) -> Vector2i:
	if tiles.is_empty():
		return Vector2i.ZERO
	var best_tile: Vector2i = tiles[0]
	var best_distance := best_tile.distance_squared_to(target_tile)
	for tile in tiles:
		var dist := tile.distance_squared_to(target_tile)
		if dist < best_distance:
			best_distance = dist
			best_tile = tile
	return best_tile


func _is_inside_ingress_clearance(map_instance: Node, tile: Vector2i) -> bool:
	return (
		map_instance != null
		and map_instance.has_method("is_inside_world_ingress_dressing_clearance")
		and bool(map_instance.call("is_inside_world_ingress_dressing_clearance", tile))
	)


func _pick_compound_spawn_tile(
	level_data: Dictionary,
	map_instance: Node,
	main_component: Dictionary
) -> Vector2i:
	var selection := _pick_compound_spawn_result(
		level_data, map_instance, main_component
	)
	if selection.is_empty():
		return Vector2i.ZERO
	return selection["tile"] as Vector2i


func _pick_compound_spawn_result(
	level_data: Dictionary,
	map_instance: Node,
	main_component: Dictionary
) -> Dictionary:
	var walkable_tiles: Array[Vector2i] = []
	for tile in _get_compound_walkable_tiles(level_data, map_instance):
		if _is_safe_operator_spawn_tile(map_instance, tile, main_component):
			walkable_tiles.append(tile)
	if walkable_tiles.is_empty():
		return {}
	var open_tiles := _filter_open_compound_tiles(walkable_tiles, map_instance)
	var preferred_tiles := open_tiles if not open_tiles.is_empty() else walkable_tiles

	var compound_rect_variant: Variant = level_data.get("compound_rect")
	var ingress_tiles: Array[Vector2i] = []
	for item in level_data.get("compound_ingress", []):
		if item is Vector2i:
			ingress_tiles.append(item as Vector2i)

	if compound_rect_variant is Rect2i:
		var compound_rect := compound_rect_variant as Rect2i
		for ingress in ingress_tiles:
			var picked := _pick_ingress_adjacent_spawn_result(
				ingress, compound_rect, preferred_tiles, map_instance
			)
			if not picked.is_empty():
				return {"tile": picked["tile"], "source": "compound"}
		var closest := _closest_spawn_selection(
			preferred_tiles, Vector2i(compound_rect.get_center())
		)
		return {"tile": closest["tile"], "source": "compound"} if not closest.is_empty() else {}

	return {"tile": preferred_tiles[0], "source": "compound"}


func _closest_spawn_selection(
	tiles: Array[Vector2i], target_tile: Vector2i
) -> Dictionary:
	if tiles.is_empty():
		return {}
	var best_tile: Vector2i = tiles[0]
	var best_distance := best_tile.distance_squared_to(target_tile)
	for tile in tiles:
		var distance := tile.distance_squared_to(target_tile)
		if distance < best_distance or (
			distance == best_distance
			and (tile.y < best_tile.y or (tile.y == best_tile.y and tile.x < best_tile.x))
		):
			best_distance = distance
			best_tile = tile
	return {"tile": best_tile}


func _pick_ingress_adjacent_spawn_result(
	ingress: Vector2i,
	compound_rect: Rect2i,
	candidate_tiles: Array[Vector2i],
	map_instance: Node
) -> Dictionary:
	if candidate_tiles.is_empty():
		return {}
	var ingress_dir := _get_compound_ingress_direction(ingress, compound_rect)
	for depth in range(2, 7):
		var probe := ingress + ingress_dir * depth
		if candidate_tiles.has(probe):
			return {"tile": probe}
		if _is_walkable_floor_tile(map_instance, probe):
			var nearby := _closest_spawn_selection(candidate_tiles, probe)
			if (
				not nearby.is_empty()
				and (nearby["tile"] as Vector2i).distance_squared_to(probe) <= 4
			):
				return nearby
	var target := _get_compound_interior_tile(ingress, compound_rect)
	return _closest_spawn_selection(candidate_tiles, target)


func _get_compound_walkable_tiles(level_data: Dictionary, map_instance: Node) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var compound_rect_variant: Variant = level_data.get("compound_rect")
	if not (compound_rect_variant is Rect2i):
		return tiles

	var compound_rect := compound_rect_variant as Rect2i
	for x in range(compound_rect.position.x, compound_rect.end.x):
		for y in range(compound_rect.position.y, compound_rect.end.y):
			var tile := Vector2i(x, y)
			if _is_walkable_floor_tile(map_instance, tile):
				tiles.append(tile)
	return tiles


func _filter_open_compound_tiles(tiles: Array[Vector2i], map_instance: Node) -> Array[Vector2i]:
	return _filter_open_tiles(tiles, map_instance)


func _filter_open_tiles(tiles: Array[Vector2i], map_instance: Node) -> Array[Vector2i]:
	var open_tiles: Array[Vector2i] = []
	for tile in tiles:
		if _count_walkable_neighbors(map_instance, tile) >= 2:
			open_tiles.append(tile)
	return open_tiles


func _get_compound_interior_tile(ingress: Vector2i, compound_rect: Rect2i) -> Vector2i:
	var depth := 2
	if ingress.y <= compound_rect.position.y:
		return ingress + Vector2i.DOWN * depth
	if ingress.y >= compound_rect.end.y - 1:
		return ingress + Vector2i.UP * depth
	if ingress.x <= compound_rect.position.x:
		return ingress + Vector2i.RIGHT * depth
	return ingress + Vector2i.LEFT * depth


func _pick_ingress_adjacent_spawn_tile(ingress: Vector2i, compound_rect: Rect2i, candidate_tiles: Array[Vector2i], map_instance: Node) -> Vector2i:
	if candidate_tiles.is_empty():
		return Vector2i.ZERO
	var ingress_dir := _get_compound_ingress_direction(ingress, compound_rect)
	for depth in range(2, 7):
		var probe := ingress + ingress_dir * depth
		if candidate_tiles.has(probe):
			return probe
		if _is_walkable_floor_tile(map_instance, probe):
			var nearby := _pick_closest_tile(candidate_tiles, probe)
			if nearby != Vector2i.ZERO and nearby.distance_squared_to(probe) <= 4:
				return nearby
	var target := _get_compound_interior_tile(ingress, compound_rect)
	return _pick_closest_tile(candidate_tiles, target)


func _get_compound_ingress_direction(ingress: Vector2i, compound_rect: Rect2i) -> Vector2i:
	if ingress.y <= compound_rect.position.y:
		return Vector2i.DOWN
	if ingress.y >= compound_rect.end.y - 1:
		return Vector2i.UP
	if ingress.x <= compound_rect.position.x:
		return Vector2i.RIGHT
	return Vector2i.LEFT


func _is_walkable_floor_tile(map_instance: Node, tile: Vector2i) -> bool:
	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		if pg.walls_tilemap != null and pg.walls_tilemap.get_cell_source_id(tile) >= 0:
			return false
		if pg.floor_tilemap != null and pg.floor_tilemap.get_cell_source_id(tile) >= 0:
			if pg.has_method("is_hole_tile") and bool(pg.call("is_hole_tile", tile)):
				return false
			return true
	return false


func _build_tile_lookup(raw_tiles: Variant) -> Dictionary:
	var lookup := {}
	if not (raw_tiles is Array):
		return lookup
	for tile_variant in raw_tiles:
		if tile_variant is Vector2i:
			lookup[tile_variant as Vector2i] = true
	return lookup


func _get_map_region_type(map_instance: Node, tile: Vector2i) -> String:
	if map_instance != null and map_instance.has_method("get_region_type_at_tile"):
		return String(map_instance.call("get_region_type_at_tile", tile))
	return "exterior"


func _get_map_tile_intensity(map_instance: Node, tile: Vector2i) -> float:
	if map_instance != null and map_instance.has_method("get_intensity_at_tile"):
		return float(map_instance.call("get_intensity_at_tile", tile))
	return 0.0


func _is_excluded_resource_region(region_type: String) -> bool:
	return region_type in [
		"spawn_clearing",
		"main_road",
		"parking_zone",
		"soft_path",
		"compound_approach",
		"compound_connector_road",
		"compound_connector_elevated_road",
		"compound_connector_ramp",
		"interior_floor",
		"interior_wall",
		"interior_threshold",
	]


func _count_walkable_neighbors(map_instance: Node, tile: Vector2i) -> int:
	var count := 0
	for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if _is_walkable_floor_tile(map_instance, tile + offset):
			count += 1
	return count


func _deactivate_static_sectors(sectors_node: Node) -> void:
	if sectors_node == null:
		return

	for node in sectors_node.find_children("*"):
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is CollisionShape2D:
			(node as CollisionShape2D).set_deferred("disabled", true)
		elif node is CollisionPolygon2D:
			(node as CollisionPolygon2D).set_deferred("disabled", true)
		elif node is CollisionObject2D:
			var co := node as CollisionObject2D
			co.set_deferred("collision_layer", 0)
			co.set_deferred("collision_mask", 0)


func _disable_sector_runtime_shell(sector: Sector) -> void:
	if sector == null:
		return
	if sector.floor_rect:
		sector.floor_rect.visible = false
	if sector.walls:
		sector.walls.visible = false
	if sector.wall_collision:
		sector.wall_collision.set_deferred("collision_layer", 0)
		sector.wall_collision.set_deferred("collision_mask", 0)
		for child in sector.wall_collision.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", true)


func _get_sector_runtime_scale(map_instance: Node) -> Vector2:
	var runtime_tile_px := fallback_tile_size
	if map_instance is ProcGenTilemap:
		var pg := map_instance as ProcGenTilemap
		var tile_size := pg.get_runtime_tile_size()
		runtime_tile_px = max(tile_size.x, 1.0)
	var scale_factor := runtime_tile_px / SECTOR_TILE_PX
	return Vector2(scale_factor, scale_factor)
