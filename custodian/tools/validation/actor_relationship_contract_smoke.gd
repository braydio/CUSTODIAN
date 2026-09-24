extends SceneTree

const VAULTWING_SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")
const BULLET_SCENE := preload("res://game/actors/projectiles/bullet.tscn")
const ENEMY_SCENE := preload("res://game/actors/enemies/enemy.tscn")
const RESOLVER := preload("res://game/systems/combat/actor_relationship_resolver.gd")

var failures: PackedStringArray = PackedStringArray()

func _init() -> void:
	await _run()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({"schema":"custodian.headless_test.result.v1", "test":"actor_relationship_contract_smoke", "passed":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	var ordinary_enemy := ENEMY_SCENE.instantiate()
	root.add_child(ordinary_enemy)
	ordinary_enemy.position = Vector2(500.0, 500.0)
	await process_frame
	if RESOLVER.resolve_allegiance(ordinary_enemy) != ActorAllegianceComponent.HOSTILE:
		_fail("legacy Enemy group fallback did not resolve HOSTILE")
	if not RESOLVER.can_target(player, ordinary_enemy, &"player"):
		_fail("player cannot target ordinary Enemy through legacy fallback")
	var neutral_bullet := BULLET_SCENE.instantiate()
	neutral_bullet.team = "neutral"
	neutral_bullet.shooter = player
	root.add_child(neutral_bullet)
	neutral_bullet.position = Vector2(-500.0, -500.0)
	if not neutral_bullet.call("_can_hit", ordinary_enemy):
		_fail("neutral projectile lost legacy permissive targeting")
	var vaultwing := VAULTWING_SCENE.instantiate()
	root.add_child(vaultwing)
	await physics_frame
	if vaultwing.get_allegiance() != ActorAllegianceComponent.HOSTILE: _fail("Vaultwing default allegiance is not HOSTILE")
	if not vaultwing.is_in_group("enemy"): _fail("HOSTILE compatibility group missing")
	if not RESOLVER.are_hostile(vaultwing, player, &"enemy"): _fail("HOSTILE Vaultwing is not hostile to Operator")
	if RESOLVER.can_target(player, vaultwing, &"player"): _fail("HIGH Vaultwing is incorrectly targetable")
	var bullet := BULLET_SCENE.instantiate()
	bullet.team = "player"
	bullet.shooter = player
	root.add_child(bullet)
	if bullet.call("_can_hit", vaultwing): _fail("real player projectile qualification accepted HIGH Vaultwing")
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	vaultwing.request_dive(player.global_position, player)
	await physics_frame
	if vaultwing.get_altitude_band_name() != &"attack": _fail("Vaultwing did not enter ATTACK band")
	if not RESOLVER.can_target(player, vaultwing, &"player"): _fail("ATTACK Vaultwing is not targetable")
	if not bullet.call("_can_hit", vaultwing): _fail("real player projectile qualification rejected ATTACK Vaultwing")
	var health_before: float = vaultwing.health
	bullet.call("_handle_body_hit", vaultwing, vaultwing.global_position, Vector2.ZERO)
	if vaultwing.health >= health_before: _fail("real projectile hit path did not damage ATTACK Vaultwing (health=%s before=%s result=%s)" % [vaultwing.health, health_before, str(bullet.call("_can_hit", vaultwing))])
	var behavior_id: int = vaultwing.behavior.get_instance_id()
	var actor_id: int = vaultwing.get_instance_id()
	var health_after: float = vaultwing.health
	vaultwing.set_allegiance(ActorAllegianceComponent.OPERATOR_ALLIED)
	if vaultwing.get_instance_id() != actor_id or vaultwing.behavior.get_instance_id() != behavior_id: _fail("allegiance mutation replaced Vaultwing identity or behavior")
	if vaultwing.health != health_after: _fail("allegiance mutation changed health")
	if vaultwing.is_in_group("enemy") or not vaultwing.is_in_group("ally"): _fail("allied compatibility groups were not synchronized")
	if RESOLVER.can_target(player, vaultwing, &"player"): _fail("allied Vaultwing remains targetable by player")
	if vaultwing.set_allegiance(&"operator_allyed"):
		_fail("invalid allegiance value was accepted")
	if vaultwing.get_allegiance() != ActorAllegianceComponent.OPERATOR_ALLIED:
		_fail("invalid allegiance value changed the current allegiance")
	vaultwing.set_allegiance(ActorAllegianceComponent.HOSTILE)
	if not vaultwing.is_in_group("enemy") or vaultwing.is_in_group("ally"): _fail("HOSTILE compatibility restoration failed")
	vaultwing.queue_free(); bullet.queue_free(); neutral_bullet.queue_free(); ordinary_enemy.queue_free(); player.queue_free()

func _fail(message: String) -> void:
	failures.append(message)
