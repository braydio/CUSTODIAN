extends SceneTree

const VAULTWING_SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")
const BondState := preload("res://game/actors/ambient/vaultwing/vaultwing_bond_state.gd")
var failures: PackedStringArray = PackedStringArray()

func _init() -> void:
	await _run()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({"schema":"custodian.headless_test.result.v1", "test":"vaultwing_bond_smoke", "passed":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	var vaultwing := VAULTWING_SCENE.instantiate()
	root.add_child(vaultwing)
	await physics_frame
	vaultwing.global_position = Vector2.ZERO
	player.global_position = Vector2(48.0, 0.0)
	vaultwing.behavior.force_state(VaultwingBehaviorController.State.GROUND_IDLE)
	await physics_frame
	var actor_id: int = vaultwing.get_instance_id()
	var behavior_id: int = vaultwing.behavior.get_instance_id()
	var health: float = float(vaultwing.health)
	if vaultwing.get_bond_stage() != BondState.WILD: _fail("new Vaultwing did not start WILD")
	if not vaultwing.offer_bait(&"vaultwing_bait", player): _fail("first valid bait was rejected")
	if vaultwing.get_bond_stage() != BondState.OBSERVING: _fail("first feed did not enter OBSERVING")
	for _i in range(3):
		if not vaultwing.offer_bait(&"vaultwing_bait", player): _fail("valid repeated bait was rejected")
	if vaultwing.get_bond_stage() != BondState.ACCEPTING: _fail("repeated peaceful feeding did not reach ACCEPTING")
	if vaultwing.offer_bait(&"invalid_bait", player): _fail("invalid bait was accepted")
	if not vaultwing.begin_bond_trial(): _fail("ACCEPTING Vaultwing did not begin bond trial")
	if not vaultwing.complete_bond_trial(&"vaultwing_bait", player): _fail("valid bond trial did not complete")
	if vaultwing.get_bond_stage() != BondState.BONDED: _fail("bond trial did not reach BONDED")
	if vaultwing.get_allegiance() != ActorAllegianceComponent.OPERATOR_ALLIED: _fail("BONDED Vaultwing did not become Operator-allied")
	if vaultwing.get_instance_id() != actor_id or vaultwing.behavior.get_instance_id() != behavior_id: _fail("bonding replaced the actor or behavior controller")
	if vaultwing.health != health: _fail("bonding changed health")
	var saved: Dictionary = vaultwing.to_save_dict()
	if str(saved.get("stable_creature_id", "")) == "": _fail("bond save omitted stable creature identity")
	var restored := VAULTWING_SCENE.instantiate()
	root.add_child(restored)
	await physics_frame
	if not restored.from_save_dict(saved): _fail("valid bond save did not restore")
	if restored.get_bond_stage() != BondState.BONDED or restored.get_allegiance() != ActorAllegianceComponent.OPERATOR_ALLIED: _fail("restored bond did not preserve stage/allegiance")
	var invalid: Dictionary = saved.duplicate(true); invalid["stage"] = "bogus"
	if restored.from_save_dict(invalid): _fail("invalid bond stage was accepted")
	vaultwing.queue_free(); restored.queue_free(); player.queue_free()

func _fail(message: String) -> void:
	failures.append(message)
