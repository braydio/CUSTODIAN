extends SceneTree

const OperatorScene := preload("res://game/actors/operator/operator.tscn")
const InputFrameScript := preload("res://game/actors/operator/input/operator_input_frame.gd")
const VehicleRegistryScript := preload("res://game/vehicles/vehicle_registry.gd")
const VehicleResolverScript := preload("res://game/vehicles/vehicle_spawn_resolver.gd")
const VehicleDefinitionScript := preload("res://game/vehicles/vehicle_definition.gd")
const DamageableScript := preload("res://game/systems/core/systems/damageable.gd")
const SCOUT_ID := "custodian_ground_buggy_scout_light"

var _errors: Array[String] = []
var _last_scan: Array[Dictionary] = []


class StructureProbe:
	extends Damageable


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var knowledge := root.get_node_or_null("VehicleKnowledgeState")
	var ledger := root.get_node_or_null("ResourceLedger")
	var inventory := root.get_node_or_null("InventoryManager")
	_expect(knowledge != null, "VehicleKnowledgeState autoload must be registered")
	_expect(ledger != null and inventory != null, "resource and inventory authorities must be available")
	if knowledge == null or ledger == null or inventory == null:
		quit(1)
		return
	knowledge.call("reset_for_validation")
	var world := Node2D.new()
	world.name = "VehicleDiagnosisKnowledgeSmoke"
	root.add_child(world)
	var resolver := VehicleResolverScript.new()
	world.add_child(resolver)
	await process_frame
	var registry: VehicleRegistry = resolver.get("registry")
	_expect(registry != null and registry.has_vehicle(SCOUT_ID), "registry must load the Scout")
	if registry == null or not registry.has_vehicle(SCOUT_ID):
		world.queue_free()
		quit(1)
		return
	var definition: VehicleDefinition = registry.get_vehicle(SCOUT_ID)
	_expect(definition.scan_profile == "field_scout_service_v1", "Scout must reference its scan profile")
	_expect(not definition.scan_profile_data.is_empty(), "registry must resolve scan-profile data")
	var progression_root: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/vehicles/vehicle_knowledge_progression.json"))
	var scan_root: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/vehicles/vehicle_scan_profiles.json"))
	_expect(progression_root is Dictionary and scan_root is Dictionary, "progression and scan profile data must parse")
	var operator := OperatorScene.instantiate() as Node2D
	operator.name = "Operator"
	operator.set("interaction_range", 64.0)
	operator.set_physics_process(false)
	operator.set_process(false)
	world.add_child(operator)
	operator.connect("vehicle_scan_result", func(result: Dictionary): _last_scan.append(result.duplicate(true)))
	await process_frame
	var first := resolver.spawn_vehicle(SCOUT_ID, world, Vector2.ZERO) as PilotableVehicle
	var second := resolver.spawn_vehicle(SCOUT_ID, world, Vector2(160.0, 0.0)) as PilotableVehicle
	var third := resolver.spawn_vehicle(SCOUT_ID, world, Vector2(320.0, 0.0)) as PilotableVehicle
	await process_frame
	_expect(first != null and second != null and third != null, "resolver must create three distinct Scout instances")
	if first == null or second == null or third == null:
		world.queue_free()
		quit(1)
		return
	_expect(first.is_in_group("vehicle_scannable") and second.is_in_group("vehicle_scannable") and third.is_in_group("vehicle_scannable"), "wrecks must remain scanner-discoverable")
	_expect(first.get_vehicle_scan_snapshot().get("condition") == "WRECKAGE", "fresh Scout must expose wreck condition")
	_expect(first.restore_from_wreck(1.0), "first fixture must transition to operational for a full scan")
	_expect(second.restore_from_wreck(1.0), "second fixture must restore before disabled-state scan")
	second.disable_vehicle("diagnosis_smoke")
	_expect(second.get_vehicle_scan_snapshot().get("condition") == "DISABLED", "healthy disabled Scout must expose disabled condition")
	_expect(third.get_vehicle_scan_snapshot().get("condition") == "WRECKAGE", "third fixture remains wreckage")
	var health_before := [first.current_health, second.current_health, third.current_health]
	var ledger_before: Dictionary = ledger.call("get_snapshot")
	var inventory_before: Dictionary = inventory.call("to_save_dict")
	operator.set("global_position", first.global_position)
	_press_service(operator, true, true)
	operator.call("_try_repair", 0.1)
	_expect(_last_scan.size() == 1 and bool(_last_scan[-1].get("accepted", false)), "fresh service press must scan through the production Operator seam")
	_expect(_last_scan[-1].get("condition") == "OPERATIONAL", "scan result must report operational condition")
	var operational_mobility := int(_last_scan[-1].get("xp_gained", {}).get("MOBILITY", 0))
	_expect(operational_mobility > 0, "operational Scout must grant configured domain XP")
	var first_fingerprint := String(first.get_vehicle_scan_snapshot().get("fingerprint", ""))
	_expect(knowledge.call("has_scanned", first_fingerprint), "successful scan fingerprint must be recorded")
	_press_service(operator, true, false)
	operator.call("_try_repair", 0.1)
	_expect(_last_scan.size() == 1, "held repair input must not repeat the scan")
	_press_service(operator, true, true)
	operator.call("_try_repair", 0.1)
	_expect(_last_scan.size() == 2 and _last_scan[-1].get("reason") == "ALREADY_SCANNED", "same-instance rescan must be rejected")
	var profiles: Dictionary = Dictionary(scan_root.get("profiles", {})) if scan_root is Dictionary else {}
	var repeated_profile_data: Dictionary = Dictionary(profiles.get("field_scout_repeated_example_fixture_v1", {})).duplicate(true)
	var repeated_definition: VehicleDefinition = VehicleDefinitionScript.from_dict(definition.source_data)
	repeated_definition.durability_profile_data = definition.durability_profile_data.duplicate(true)
	repeated_definition.restoration_profile_data = definition.restoration_profile_data.duplicate(true)
	repeated_definition.scan_profile = "field_scout_repeated_example_fixture_v1"
	repeated_definition.scan_profile_data = repeated_profile_data
	second.vehicle_definition = repeated_definition
	operator.set("global_position", second.global_position)
	_press_service(operator, true, true)
	operator.call("_try_repair", 0.1)
	_expect(_last_scan.size() == 3 and bool(_last_scan[-1].get("accepted", false)), "distinct same-archetype disabled scan must be accepted")
	_expect(_last_scan[-1].get("condition") == "DISABLED", "scan result must report disabled condition")
	var disabled_mobility := int(_last_scan[-1].get("xp_gained", {}).get("MOBILITY", 0))
	var conditions: Dictionary = Dictionary(progression_root.get("condition_multipliers", {})) if progression_root is Dictionary else {}
	var repeat_multipliers: Array = Array(progression_root.get("archetype_diminishing_multipliers", [])) if progression_root is Dictionary else []
	var scout_base_mobility := int(definition.scan_profile_data.get("base_xp", {}).get("MOBILITY", 0))
	var repeated_base_mobility := int(repeated_profile_data.get("base_xp", {}).get("MOBILITY", 0))
	var expected_operational := _expected_xp(scout_base_mobility, "OPERATIONAL", 0, conditions, repeat_multipliers, int(progression_root.get("minimum_xp_gain", 0)))
	var expected_disabled := _expected_xp(repeated_base_mobility, "DISABLED", 1, conditions, repeat_multipliers, int(progression_root.get("minimum_xp_gain", 0)))
	_expect(operational_mobility == expected_operational, "first-scan XP must match progression/profile data")
	_expect(disabled_mobility == expected_disabled and disabled_mobility < operational_mobility, "repeat and disabled multipliers must match progression data")
	_expect(knowledge.call("get_pattern_evidence", &"fixture_new_disabled_pattern") == 2, "unseen observable pattern on repeated archetype must grant evidence")
	var before_wreck_pattern := int(knowledge.call("get_pattern_evidence", &"electrohydraulic_steering_rack"))
	operator.set("global_position", third.global_position)
	_press_service(operator, true, true)
	operator.call("_try_repair", 0.1)
	_expect(_last_scan.size() == 4 and bool(_last_scan[-1].get("accepted", false)), "distinct wreck scan must be accepted")
	_expect(_last_scan[-1].get("condition") == "WRECKAGE", "scan result must report wreck condition")
	_expect(int(knowledge.call("get_pattern_evidence", &"electrohydraulic_steering_rack")) == before_wreck_pattern, "wreck must not teach destroyed/unobservable steering pattern")
	var expected_wreck := _expected_xp(scout_base_mobility, "WRECKAGE", 2, conditions, repeat_multipliers, int(progression_root.get("minimum_xp_gain", 0)))
	_expect(int(_last_scan[-1].get("xp_gained", {}).get("MOBILITY", 0)) == expected_wreck and expected_wreck < disabled_mobility, "wreck condition multiplier must match progression data")
	_expect(first.current_health == health_before[0] and second.current_health == health_before[1] and third.current_health == health_before[2], "scanning must not mutate vehicle HP")
	_expect(ledger.call("get_snapshot") == ledger_before, "scanning must not mutate resource ledger")
	_expect(inventory.call("to_save_dict") == inventory_before, "scanning must not mutate physical inventory")
	var save_data: Dictionary = knowledge.call("to_save_dict")
	var saved_xp := save_data.duplicate(true)
	var requirements := {"domains": [{"domain": "MOBILITY", "level": 0}], "patterns": [{"pattern_id": "fixture_new_disabled_pattern", "evidence": 2}]}
	var status_before: Dictionary = knowledge.call("get_requirement_status", requirements)
	_expect(knowledge.call("meets_requirements", requirements), "learned knowledge and pattern must satisfy query")
	_expect(not knowledge.call("meets_requirements", {"domains": [{"domain": "MOBILITY", "level": 1}], "patterns": []}), "unmet domain threshold must remain locked")
	_expect(knowledge.call("to_save_dict") == saved_xp, "requirement queries must be side-effect free")
	knowledge.call("reset_for_validation")
	knowledge.call("from_save_dict", save_data)
	_expect(knowledge.call("to_save_dict") == save_data, "knowledge serialization must round-trip exactly")
	_press_service(operator, true, true)
	operator.call("_try_repair", 0.1)
	_expect(_last_scan.size() == 5 and _last_scan[-1].get("reason") == "ALREADY_SCANNED", "round-trip must preserve anti-farming fingerprints")
	_expect(knowledge.call("get_requirement_status", requirements) == status_before, "round-trip must preserve requirement results")
	_expect(first.get_vehicle_scan_snapshot().get("fingerprint") != second.get_vehicle_scan_snapshot().get("fingerprint"), "distinct spawn origins must produce stable distinct fingerprints")
	await _test_field_repair_precedence(operator, resolver, world, knowledge)
	_expect(ledger.call("get_snapshot") == ledger_before and inventory.call("to_save_dict") == inventory_before, "all scan and contested-action paths must leave physical resources unchanged")
	knowledge.call("reset_for_validation")
	world.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[VehicleDiagnosisKnowledgeSmoke] PASS")
		quit(0)
		return
	for error: String in _errors:
		push_error("[VehicleDiagnosisKnowledgeSmoke] " + error)
	quit(1)


func _test_field_repair_precedence(operator: Node2D, resolver: VehicleSpawnResolver, world: Node, knowledge: Node) -> void:
	var vehicle := resolver.spawn_vehicle(SCOUT_ID, world, Vector2(480.0, 0.0)) as PilotableVehicle
	await process_frame
	if vehicle == null:
		_expect(false, "contested-action Scout must spawn")
		return
	var structure := StructureProbe.new() as Damageable
	structure.name = "RepairPriorityStructure"
	structure.current_health = 40.0
	structure.global_position = vehicle.global_position
	structure.add_to_group("structure")
	world.add_child(structure)
	operator.set("global_position", vehicle.global_position)
	var before_health := structure.current_health
	_press_service(operator, true, true)
	operator.call("_try_repair", 0.5)
	_expect(structure.current_health > before_health, "valid structure repair must retain precedence over vehicle scan")
	_expect(not knowledge.call("has_scanned", vehicle.get_vehicle_scan_snapshot().get("fingerprint", "")), "contested repair must not record vehicle knowledge")
	structure.queue_free()
	vehicle.queue_free()
	await process_frame


func _press_service(operator: Node, held: bool, edge: bool) -> void:
	var pressed := {&"repair": true} if held else {}
	var just_pressed := {&"repair": true} if edge else {}
	operator.set("_input_frame", InputFrameScript.build(pressed, just_pressed, {}, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, false, false))


func _expected_xp(base: int, condition: String, repeat_index: int, conditions: Dictionary, repeats: Array, minimum: int) -> int:
	if base <= 0 or conditions.is_empty() or repeats.is_empty():
		return 0
	var multiplier := float(conditions.get(condition, 0.0)) * float(repeats[mini(repeat_index, repeats.size() - 1)])
	var amount := int(round(float(base) * multiplier))
	return maxi(amount, minimum) if multiplier > 0.0 else 0


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
