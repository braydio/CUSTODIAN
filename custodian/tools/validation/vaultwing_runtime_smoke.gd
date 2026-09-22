extends SceneTree

## Slice A gate for the wild Common Vaultwing. Published art is discovered
## semantically when present; behavior remains valid while optional states are
## still pending.

const SCENE := preload("res://game/actors/ambient/vaultwing/vaultwing.tscn")
const SPAWNER_SCRIPT := preload("res://game/systems/spawning/vaultwing_spawner.gd")
const STEP := 1.0 / 60.0

var _failures: PackedStringArray = PackedStringArray()

func _init() -> void:
	await _run()
	if _failures.is_empty():
		print("PASS vaultwing_runtime_smoke: deterministic wild flight, published semantic art, dive commitment, altitude presentation, damage, stagger, retreat, and optional-art fallback")
		quit(0)
	else:
		for failure in _failures: push_error(failure)
		quit(1)

func _run() -> void:
	var actor := SCENE.instantiate() as Node2D
	if actor == null:
		_fail("Vaultwing scene did not instantiate")
		return
	root.add_child(actor)
	await physics_frame
	if not actor.is_in_group("vaultwing"): _fail("actor missing vaultwing group")
	if actor.get_altitude_band_name() != &"high": _fail("initial band is not HIGH")
	for action in [&"glide", &"flap", &"dive_windup", &"dive_strike", &"climb_out", &"land", &"takeoff", &"ground_idle", &"bite_attack"]:
		if not actor.has_action(action): _fail("published Vaultwing action was not discovered: %s" % String(action))
	for action in [&"perch_idle", &"ground_walk", &"air_stagger", &"hurt", &"death"]:
		if actor.has_action(action): _fail("pending Vaultwing action unexpectedly resolved: %s" % String(action))
	_check_api(actor)
	await _check_determinism()
	await _check_spawn_authority()
	await _check_dive(actor)
	await _check_damage(actor)
	_check_asset_contract()
	actor.queue_free()

func _check_api(actor: Node) -> void:
	for method in ["set_ambient_seed", "request_interest", "request_dive", "request_land", "request_takeoff", "take_damage", "get_state_name", "get_altitude_band_name", "apply_visual_altitude"]:
		if not actor.has_method(method): _fail("missing actor API: %s" % method)

func _check_determinism() -> void:
	var traces: Array = []
	for seed_value in [111, 111, 222]:
		var actor := SCENE.instantiate() as Node2D
		root.add_child(actor)
		actor.collision_layer = 0
		actor.collision_mask = 0
		actor.set_ambient_seed(seed_value)
		var trace: Array[Dictionary] = []
		for _i in 120:
			await physics_frame
			trace.append(actor.get_behavior_trace_state())
		traces.append(trace)
		actor.queue_free()
	if traces[0] != traces[1]: _fail("same seed produced different Vaultwing trace")
	if traces[0] == traces[2]: _fail("different seeds produced identical Vaultwing trace")

func _check_spawn_authority() -> void:
	var spawner := SPAWNER_SCRIPT.new()
	spawner.vaultwing_container_path = NodePath("/")
	spawner.max_active_vaultwings = 1
	root.add_child(spawner)
	var spawned := spawner.spawn_at(Vector2(32.0, 48.0), 707)
	if spawned == null: _fail("focused Vaultwing spawner failed to create actor")
	if spawner.get_active_count() != 1: _fail("Vaultwing spawner active count is incorrect")
	if spawned != null and spawned.get_altitude_band_name() != &"high": _fail("spawned Vaultwing did not begin in HIGH")
	spawner.despawn_all()
	spawner.queue_free()
	await process_frame

func _check_dive(actor: Node) -> void:
	actor.global_position = Vector2.ZERO
	actor.set_ambient_seed(99)
	actor.request_dive(Vector2(160.0, 0.0))
	var states := {}
	var saw_altitude_lift := false
	for _i in 180:
		await physics_frame
		states[actor.get_state_name()] = true
		if actor.get_node("Body").position.y < -1.0: saw_altitude_lift = true
	if not states.has(&"dive_windup"): _fail("dive skipped windup")
	if not states.has(&"dive_strike"): _fail("dive skipped committed strike")
	if not states.has(&"climb_out"): _fail("dive skipped climb-out")
	if not saw_altitude_lift: _fail("visual altitude never lifted body above shadow")
	if actor.get_altitude_band_name() != &"high": _fail("dive did not terminate in HIGH patrol")

func _check_damage(actor: Node) -> void:
	var before: float = actor.health
	var result: Dictionary = actor.take_damage(20.0)
	if float(result.get("applied_damage", 0.0)) != 20.0: _fail("Vaultwing did not accept valid damage")
	if actor.health >= before: _fail("Vaultwing health did not decrease")
	actor.request_dive(Vector2(120.0, 0.0))
	await physics_frame
	actor.take_damage(30.0)
	if actor.get_state_name() != &"air_stagger": _fail("large aerial interruption did not enter AIR_STAGGER")
	for _i in 60: await physics_frame
	if actor.get_altitude_band_name() not in [&"ground", &"high"]: _fail("air stagger did not reach a grounded/high recovery")
	actor.take_damage(9999.0)
	if not bool(actor.get("_dead")): _fail("lethal damage did not terminate Vaultwing")

func _check_asset_contract() -> void:
	var file := FileAccess.open("res://content/metadata/assets/families/ambient_vaultwing_common.asset.json", FileAccess.READ)
	if file == null:
		_fail("Vaultwing Asset V2 family contract is missing")
		return
	var payload: Variant = JSON.parse_string(file.get_as_text())
	if not payload is Dictionary or payload.get("id", "") != "ambient_vaultwing_common":
		_fail("invalid Vaultwing family contract")
		return
	var canvas: Dictionary = payload.get("canvas", {})
	if canvas.get("width", 0) != 256 or canvas.get("height", 0) != 256: _fail("Vaultwing family canvas is not 256x256")

func _fail(message: String) -> void:
	_failures.append(message)
