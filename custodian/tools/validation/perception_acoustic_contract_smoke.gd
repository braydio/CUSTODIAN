extends SceneTree

const BLACKBOARD := preload("res://game/actors/enemies/components/enemy_blackboard.gd")
const ENEMY_PROFILE := preload("res://game/actors/enemies/components/enemy_behavior_profile.gd")
const ENEMY_PERCEPTION := preload("res://game/actors/enemies/components/enemy_perception_component.gd")
const VAULTWING_CONTROLLER := preload("res://game/actors/ambient/vaultwing/vaultwing_behavior_controller.gd")
const NOISE_BUS := preload("res://game/systems/stealth/noise_event_bus.gd")
const NOISE_EVENT := preload("res://game/systems/stealth/noise_event.gd")
const ACOUSTIC_SENSOR := preload("res://game/systems/stealth/acoustic_perception_sensor.gd")
const RELATIONSHIPS := preload("res://game/systems/combat/actor_relationship_resolver.gd")

class BondedReceiver:
	extends CharacterBody2D

	func is_bonded() -> bool:
		return true


var _failures: Array[String] = []
var _last_emitted_event: NoiseEvent


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_root := get_root()
	var bus := scene_root.get_node_or_null("NoiseEventBus") as NoiseEventBusSystem
	if bus == null:
		bus = NOISE_BUS.new()
		bus.name = "NoiseEventBus"
		scene_root.add_child(bus)
	if not bus.noise_emitted.is_connected(_capture_noise_event):
		bus.noise_emitted.connect(_capture_noise_event)

	var enemy := Node2D.new()
	enemy.name = "AcousticEnemyReceiver"
	enemy.global_position = Vector2.ZERO
	scene_root.add_child(enemy)
	var blackboard := BLACKBOARD.new()
	enemy.add_child(blackboard)
	var perception := ENEMY_PERCEPTION.new()
	enemy.add_child(perception)
	perception._current_enemy = enemy
	perception._current_profile = ENEMY_PROFILE.create_profile(&"raider_marine")
	perception._current_blackboard = blackboard

	var wild_actor := CharacterBody2D.new()
	wild_actor.name = "WildVaultwingAcousticReceiver"
	wild_actor.global_position = Vector2.ZERO
	scene_root.add_child(wild_actor)
	var wild_controller := VAULTWING_CONTROLLER.new()
	wild_controller.actor = wild_actor
	scene_root.add_child(wild_controller)

	var bonded_actor := BondedReceiver.new()
	bonded_actor.name = "BondedVaultwingAcousticReceiver"
	bonded_actor.global_position = Vector2.ZERO
	scene_root.add_child(bonded_actor)
	var bonded_controller := VAULTWING_CONTROLLER.new()
	bonded_controller.actor = bonded_actor
	scene_root.add_child(bonded_controller)

	var source := Node2D.new()
	source.name = "AcousticSource"
	source.global_position = Vector2(500.0, 0.0)
	scene_root.add_child(source)
	await process_frame

	var in_range_event: NoiseEvent = NOISE_EVENT.create(
		source, Vector2(64.0, 0.0), 128.0, &"gunshot", 2.0, 0.8, false, &"neutral"
	)
	var enemy_observation: PerceptionObservation = ACOUSTIC_SENSOR.evaluate_noise(in_range_event, enemy.global_position, enemy)
	var vaultwing_observation: PerceptionObservation = ACOUSTIC_SENSOR.evaluate_noise(in_range_event, wild_actor.global_position, wild_actor)
	_expect(enemy_observation != null and vaultwing_observation != null, "in-range receivers did not observe the same event")
	if enemy_observation != null and vaultwing_observation != null:
		_expect(enemy_observation.observed_position == vaultwing_observation.observed_position, "receivers disagreed on observed position")
		_expect(is_equal_approx(enemy_observation.salience, vaultwing_observation.salience), "receivers disagreed on acoustic salience")
		_expect(enemy_observation.source_team == &"neutral", "observation lost the emitted source-team fact")
		_expect(enemy_observation.source == source, "observation lost the acoustic source identity")
		_expect(enemy_observation.stimulus_kind == &"gunshot", "observation lost the semantic stimulus kind")

	bus.emit_noise(in_range_event)
	_expect(_last_emitted_event == in_range_event, "typed NoiseEvent did not cross the bus")
	_expect(in_range_event.timestamp_msec > 0, "bus did not timestamp the typed event")
	_expect(blackboard.is_suspicious, "Enemy did not consume the in-range neutral acoustic event")
	_expect(blackboard.investigation_position == in_range_event.position, "Enemy did not preserve the heard position")
	_expect(not blackboard.is_alerted, "hearing a neutral event directly marked Enemy alerted")
	_expect(wild_controller.state == VAULTWING_CONTROLLER.State.CIRCLE_INTEREST, "wild Vaultwing did not consume the in-range event")
	_expect(wild_controller.target_position == in_range_event.position, "Vaultwing did not preserve the heard position")
	var operator := Node2D.new()
	operator.name = "OperatorSource"
	operator.add_to_group("player")
	scene_root.add_child(operator)
	var operator_event: NoiseEvent = NOISE_EVENT.create(operator, Vector2(40.0, 0.0), 128.0, &"gunshot", 1.0, 1.0, false, &"player")
	var operator_observation: PerceptionObservation = ACOUSTIC_SENSOR.evaluate_noise(operator_event, enemy.global_position, enemy)
	_expect(operator_observation != null and operator_observation.source == operator, "observation lost the Operator source identity")
	_expect(RELATIONSHIPS.resolve_allegiance(operator) == &"operator_allied", "post-sensing relationship query could not identify the Operator as allied")
	bus.emit_noise(operator_event)
	_expect(blackboard.operator_ref == operator, "Enemy did not preserve the identified Operator source")
	_expect(blackboard.investigation_position == operator_event.position, "Enemy did not preserve the Operator gunshot position")
	_expect(not blackboard.is_alerted, "hearing an Operator gunshot bypassed visual alert policy")
	_expect(bonded_controller.state == VAULTWING_CONTROLLER.State.HIGH_PATROL, "bonded Vaultwing reacquired hostile interest from Operator gunfire")

	blackboard.is_suspicious = false
	blackboard.investigation_position = Vector2.ZERO
	wild_controller.force_state(VAULTWING_CONTROLLER.State.HIGH_PATROL)
	var outside_event: NoiseEvent = NOISE_EVENT.create(source, Vector2(300.0, 0.0), 32.0, &"gunshot", 1.0, 1.0, false, &"neutral")
	bus.emit_noise(outside_event)
	_expect(not blackboard.is_suspicious, "Enemy consumed an event outside the source envelope")
	_expect(wild_controller.state == VAULTWING_CONTROLLER.State.HIGH_PATROL, "Vaultwing consumed an event outside the source envelope")
	_expect(ACOUSTIC_SENSOR.evaluate_noise(outside_event, enemy.global_position, enemy) == null, "shared sensor returned an out-of-range observation")

	var self_noise: NoiseEvent = NOISE_EVENT.create(enemy, Vector2.ZERO, 64.0, &"machinery", 1.0, 1.0, false, &"neutral")
	_expect(ACOUSTIC_SENSOR.evaluate_noise(self_noise, enemy.global_position, enemy) == null, "shared sensor returned a self-source observation")
	var vaultwing_self_noise: NoiseEvent = NOISE_EVENT.create(wild_actor, Vector2.ZERO, 64.0, &"creature_call", 1.0, 1.0, false, &"neutral")
	_expect(ACOUSTIC_SENSOR.evaluate_noise(vaultwing_self_noise, wild_actor.global_position, wild_actor) == null, "shared sensor returned a Vaultwing self-source observation")

	if _failures.is_empty():
		print("PERCEPTION_ACOUSTIC_CONTRACT_SMOKE: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _capture_noise_event(event: NoiseEvent) -> void:
	_last_emitted_event = event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
