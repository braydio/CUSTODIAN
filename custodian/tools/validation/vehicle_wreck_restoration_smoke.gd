extends SceneTree

const VehicleRegistryScript := preload("res://game/vehicles/vehicle_registry.gd")
const VehicleResolverScript := preload("res://game/vehicles/vehicle_spawn_resolver.gd")
const VehicleScript := preload("res://game/vehicles/pilotable_vehicle.gd")
const OperatorScript := preload("res://game/actors/operator/operator.gd")
const InputFrameScript := preload("res://game/actors/operator/input/operator_input_frame.gd")
const ARCHETYPES_PATH := "res://content/vehicles/vehicle_archetypes.json"
const PROFILE_ID := "field_scout_recovery_light"
const COST := {"ruin_scrap": 12, "structural_alloy": 6, "power_components": 1}

var _errors: Array[String] = []
var _destruction_events := [0]
var _restoration_events := [0]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ledger := root.get_node_or_null("ResourceLedger")
	_expect(ledger != null, "ResourceLedger autoload must be available")
	if ledger == null:
		quit(1)
		return
	ledger.call("clear")
	var world := Node2D.new()
	world.name = "VehicleWreckRestorationSmokeWorld"
	root.add_child(world)
	var resolver := VehicleResolverScript.new()
	world.add_child(resolver)
	var resolved_vehicle := resolver.spawn_vehicle("custodian_ground_buggy_scout_light", world, Vector2.ZERO) as PilotableVehicle
	_expect(resolved_vehicle != null, "resolver spawn must produce the Scout")
	if resolved_vehicle != null:
		await process_frame
		await _check_initial_wreck(resolved_vehicle, ledger, "resolver")
		await _check_full_recovery_loop(resolved_vehicle, ledger)
	var direct_scene := load("res://game/actors/vehicles/light_buggy.tscn") as PackedScene
	var direct_vehicle := direct_scene.instantiate() as PilotableVehicle if direct_scene != null else null
	_expect(direct_vehicle != null, "direct fallback scene must instantiate")
	if direct_vehicle != null:
		direct_vehicle.position = Vector2(400.0, 0.0)
		world.add_child(direct_vehicle)
		await process_frame
		await _check_initial_wreck(direct_vehicle, ledger, "direct scene fallback")
		_expect(direct_vehicle.restoration_profile.get("initial_state") == "WRECKAGE", "direct fallback must resolve the restoration profile")
		_expect(direct_vehicle.is_in_group("vehicle") and direct_vehicle.is_in_group("vehicles"), "wreck must retain generic vehicle identity groups")
		_expect(not direct_vehicle.is_in_group("pilotable_vehicles") and not direct_vehicle.is_in_group("interactable"), "wreck must not expose operational groups")
		_expect(direct_vehicle.restoration_interaction != null and direct_vehicle.restoration_interaction.is_in_group("interactable"), "direct fallback must expose exactly its restoration interaction")
		_expect(direct_vehicle.get_children().filter(func(child): return child.is_in_group("interactable")).size() == 1, "wreck must expose exactly one child restoration interaction")
		direct_vehicle.queue_free()
	if resolved_vehicle != null:
		resolved_vehicle.queue_free()
	world.queue_free()
	await process_frame
	ledger.call("clear")
	if _errors.is_empty():
		print("[VehicleWreckRestorationSmoke] PASS")
		quit(0)
		return
	push_error("VehicleWreckRestorationSmoke failed (%d error(s))" % _errors.size())
	quit(1)


func _check_initial_wreck(vehicle: PilotableVehicle, ledger: Node, route: String) -> void:
	var prior_destruction_events: int = int(_destruction_events[0])
	vehicle.vehicle_destroyed.connect(func(): _destruction_events[0] += 1)
	vehicle.vehicle_restored.connect(func(): _restoration_events[0] += 1)
	_expect(vehicle.is_wreckage(), "%s spawn must enter WRECKAGE" % route)
	_expect(vehicle.current_health == 0.0 and vehicle.is_destroyed and vehicle.control_state == PilotableVehicle.ControlState.DISABLED, "%s wreck must have zero health and disabled/destroyed lifecycle" % route)
	_expect(not vehicle.is_in_group("pilotable_vehicles"), "%s wreck must be absent from pilotable_vehicles" % route)
	_expect(_destruction_events[0] == prior_destruction_events, "initial wreck setup must not emit vehicle_destroyed")
	var interaction := vehicle.restoration_interaction as VehicleRestorationInteraction
	_expect(interaction != null and interaction.can_interact(null), "%s wreck must expose an available restoration interaction" % route)
	_expect(interaction != null and interaction.get_interaction_prompt().contains("RESTORE"), "%s interaction prompt must identify restoration" % route)
	if interaction == null:
		return
	ledger.call("clear")
	var empty_snapshot: Dictionary = ledger.call("get_snapshot")
	var actor := Node2D.new()
	actor.global_position = vehicle.global_position
	vehicle.add_child(actor)
	_expect(not vehicle.can_enter(actor), "%s wreck must reject entry" % route)
	interaction.interact(actor)
	_expect(not interaction.is_restoration_active(), "insufficient resources must refuse to start restoration")
	_expect(ledger.call("get_snapshot") == empty_snapshot, "insufficient resources must not mutate any ledger resource")
	actor.queue_free()
	await process_frame


func _check_full_recovery_loop(vehicle: PilotableVehicle, ledger: Node) -> void:
	var interaction := vehicle.restoration_interaction as VehicleRestorationInteraction
	var actor := Node2D.new()
	actor.global_position = vehicle.global_position
	root.add_child(actor)
	ledger.call("debug_grant", COST)
	var initial_snapshot: Dictionary = ledger.call("get_snapshot")
	interaction.set_physics_process(false)
	var operator := OperatorScript.new() as Node2D
	operator.global_position = vehicle.global_position
	operator.set("interaction_target", interaction)
	_set_operator_interact_frame(operator, true, true)
	operator.call("_dispatch_interact_input")
	_expect(interaction.is_restoration_active(), "production Operator press must start a funded in-range hold")
	_expect(operator.get("_held_restoration_interaction") == interaction, "Operator must retain the active restoration target")
	_set_operator_interact_frame(operator, false)
	operator.call("_update_held_restoration_input", true)
	_expect(not interaction.is_restoration_active() and ledger.call("get_snapshot") == initial_snapshot, "production Operator release must cancel without spending")
	_set_operator_interact_frame(operator, true, true)
	operator.call("_dispatch_interact_input")
	operator.set("interaction_target", null)
	_set_operator_interact_frame(operator, true)
	operator.call("_update_held_restoration_input", true)
	_expect(not interaction.is_restoration_active() and ledger.call("get_snapshot") == initial_snapshot, "losing the active target must cancel without spending")
	operator.set("interaction_target", interaction)
	actor.global_position = vehicle.global_position + Vector2(1000.0, 0.0)
	interaction.interact(actor)
	interaction._physics_process(0.1)
	_expect(not interaction.is_restoration_active() and ledger.call("get_snapshot") == initial_snapshot, "out-of-range cancellation must spend nothing")
	actor.global_position = vehicle.global_position
	_set_operator_interact_frame(operator, true, true)
	operator.call("_dispatch_interact_input")
	_expect(interaction.is_restoration_active(), "restoration can restart after cancellation")
	_set_operator_interact_frame(operator, true)
	operator.call("_update_held_restoration_input", true)
	interaction._physics_process(float(vehicle.restoration_profile.get("hold_duration", 4.0)) + 0.01)
	_expect(vehicle.current_health == 40.0 and not vehicle.is_destroyed and vehicle.control_state == PilotableVehicle.ControlState.UNOCCUPIED, "successful restore must return the same instance at 40 HP")
	var paid_snapshot: Dictionary = ledger.call("get_snapshot")
	interaction.call("_complete_restoration")
	_expect(ledger.call("get_snapshot") == paid_snapshot and _restoration_events[0] == 1, "reentrant completion after restore must not double-charge or emit twice")
	_expect(vehicle.can_enter(actor) and vehicle.enter_vehicle(actor), "restored vehicle must permit actual entry")
	_expect(vehicle.exit_vehicle(), "restored vehicle must allow exit after entry")
	_expect(ledger.call("get_amount", "ruin_scrap") == 0 and ledger.call("get_amount", "structural_alloy") == 0 and ledger.call("get_amount", "power_components") == 0, "successful restore must spend the exact configured cost once")
	_expect(_restoration_events[0] == 1, "successful restore must emit one vehicle_restored event")
	vehicle.take_damage(40.0)
	_expect(vehicle.is_wreckage() and vehicle.current_health == 0.0, "later lethal damage must return the same instance to WRECKAGE")
	_expect(_destruction_events[0] == 1, "later lethal damage must emit one real vehicle_destroyed event")
	_expect(vehicle.restoration_interaction.is_in_group("interactable") and not vehicle.is_in_group("pilotable_vehicles"), "destroyed wreck must reactivate restoration and leave pilotable discovery")
	ledger.call("debug_grant", COST)
	interaction.interact(actor)
	interaction._physics_process(float(vehicle.restoration_profile.get("hold_duration", 4.0)) + 0.01)
	_expect(vehicle.current_health == 40.0 and not vehicle.is_destroyed, "wreck must support repeat restoration")
	_expect(_restoration_events[0] == 2, "repeat restoration must emit one event per successful transition")
	operator.free()
	actor.queue_free()
	await process_frame


func _set_operator_interact_frame(operator: Node, held: bool, just_pressed: bool = false) -> void:
	var pressed := {&"interact": true} if held else {}
	var just_pressed_actions := {&"interact": true} if just_pressed else {}
	operator.set(
		"_input_frame",
		InputFrameScript.build(
			pressed,
			just_pressed_actions,
			{},
			Vector2.ZERO,
			Vector2.ZERO,
			Vector2.ZERO,
			false,
			false
		)
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_errors.append(message)
	push_error("[VehicleWreckRestorationSmoke] " + message)
