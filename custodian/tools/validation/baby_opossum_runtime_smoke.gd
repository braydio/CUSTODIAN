extends SceneTree

## Baby Opossum production gate.
##
## Covers the runtime contract the actor must hold regardless of how much art
## is installed: spawn-home anchoring, deterministic wander, one-animation-per
## -transition sequencing, movement locks, flee termination, generic attack
## rejection, and layered body/prop presentation.
##
## Set OPOSSUM_REQUIRE_ART=1 to additionally fail when no runtime strip is
## installed (visual-completeness gate for release branches).

const SCENE := preload("res://game/actors/ambient/baby_opossum/baby_opossum.tscn")
const AttackRejection := preload("res://game/systems/combat/attack_rejection.gd")
const BULLET_SCENE := preload("res://game/actors/projectiles/bullet.tscn")
const ANIMATION_SET := preload("res://game/actors/ambient/baby_opossum/baby_opossum_animation_set.tres")
const STEP := 1.0 / 60.0

var _failures: PackedStringArray = PackedStringArray()

func _init() -> void:
	var opossum := SCENE.instantiate()
	if opossum == null:
		_fail("scene did not instantiate")
		_finish()
		return
	root.add_child(opossum)
	await physics_frame

	await _check_api(opossum)
	await _check_home_anchoring(opossum)
	_check_determinism()
	await _check_invulnerability(opossum)
	await _check_treat_sequence(opossum)
	await _check_movement_locks(opossum)
	await _check_flee_termination(opossum)
	await _check_attack_rejection(opossum)
	await _check_live_projectile_rejection(opossum)
	_check_layered_presentation(opossum)
	_check_art_coverage()
	_finish()

func _check_api(opossum: Node) -> void:
	for method in [
		"play_action", "take_damage", "set_passive_home_position", "set_ambient_seed",
		"reject_attack", "is_attack_rejector", "flee_from", "stop_fleeing",
		"receive_treat", "begin_play_dead", "end_play_dead", "enter_hide", "exit_hide",
		"search_for_target", "retrieve", "gift_drop", "get_state",
	]:
		if not opossum.has_method(method): _fail("ambient actor API missing: %s" % method)
	if not opossum.is_in_group("attack_rejector"): _fail("actor is not registered as an attack rejector")
	if not opossum.is_in_group("passive_target"): _fail("actor is not registered as a passive target")
	if opossum.play_action(&"missing_action"): _fail("missing action did not fail softly")
	await physics_frame

## `_ready` runs before the spawner places the actor, so wander must anchor on
## the post-spawn hook rather than on the position seen during `_ready`.
func _check_home_anchoring(opossum: Node) -> void:
	var placed := Vector2(512.0, -256.0)
	opossum.global_position = placed
	opossum.set_passive_home_position(placed)
	if opossum.get("home_position") != placed:
		_fail("set_passive_home_position did not anchor home (%s)" % str(opossum.get("home_position")))
	await physics_frame
	if opossum.global_position.distance_to(placed) > opossum.get("wander_radius") + 32.0:
		_fail("actor wandered outside its anchored home radius")

## Two actors given the same seed must make identical wander decisions; a
## different seed must actually diverge.
func _check_determinism() -> void:
	var samples := []
	for seed_value in [1234, 1234, 9876]:
		var actor := SCENE.instantiate()
		root.add_child(actor)
		actor.set_ambient_seed(seed_value)
		actor.set_passive_home_position(Vector2.ZERO)
		actor.global_position = Vector2.ZERO
		var trace: Array[Vector2] = []
		for i in 6:
			actor.call("_choose_wander_target")
			trace.append(actor.get("_wander_target"))
		samples.append(trace)
		actor.queue_free()
	if samples[0] != samples[1]: _fail("wander is not deterministic for a fixed seed")
	if samples[0] == samples[2]: _fail("distinct seeds produced identical wander traces")

func _check_invulnerability(opossum: Node) -> void:
	var result: Dictionary = opossum.take_damage(999.0)
	if float(result.get("applied_damage", -1.0)) != 0.0 or bool(result.get("lethal", true)):
		_fail("opossum accepted damage")
	if not bool(result.get("invulnerable", false)) or not bool(result.get("passive", false)):
		_fail("damage result does not report the passive/invulnerable contract")
	await physics_frame

## The treat reaction must be a timed sequence, not six clips in one tick.
func _check_treat_sequence(opossum: Node) -> void:
	_reset(opossum)
	var trust_before := int(opossum.get("trust_points"))
	if not opossum.receive_treat(): _fail("treat was refused from an ambient state")
	if int(opossum.get("trust_points")) != trust_before + 1: _fail("treat did not advance trust")
	if opossum.get_state() != BabyOpossum.State.TREAT_NOTICE:
		_fail("treat did not enter the notice state (got %d)" % opossum.get_state())
	var observed := {}
	for i in 420:
		observed[opossum.get_state()] = true
		if opossum.get_state() == BabyOpossum.State.IDLE and i > 4: break
		await physics_frame
	for expected in [BabyOpossum.State.TREAT_NOTICE, BabyOpossum.State.TREAT_APPROACH, BabyOpossum.State.TREAT_SNIFF, BabyOpossum.State.TREAT_TAKE, BabyOpossum.State.TREAT_EAT]:
		if not observed.has(expected): _fail("treat sequence skipped state %d" % expected)
	if opossum.get_state() != BabyOpossum.State.IDLE: _fail("treat sequence never returned to ambient behavior")

## Play-dead and hide must structurally suspend ambient movement.
func _check_movement_locks(opossum: Node) -> void:
	_reset(opossum)
	opossum.begin_play_dead()
	for i in 90:
		await physics_frame
		if opossum.velocity.length_squared() > 0.0001: _fail("actor moved while playing dead")
	if opossum.get_state() != BabyOpossum.State.PLAY_DEAD_HOLD: _fail("play dead did not settle into its hold state")
	if not bool(opossum.get("play_dead")): _fail("play_dead flag not reported while held")
	opossum.end_play_dead()
	for i in 120:
		await physics_frame
		if opossum.get_state() == BabyOpossum.State.IDLE: break
	if bool(opossum.get("play_dead")): _fail("play_dead flag survived the exit sequence")

	_reset(opossum)
	opossum.enter_hide()
	for i in 90:
		await physics_frame
		if opossum.velocity.length_squared() > 0.0001: _fail("actor moved while hidden")
	if opossum.get_state() != BabyOpossum.State.HIDE_HOLD: _fail("hide did not settle into its hold state")
	if not bool(opossum.get("is_hidden")): _fail("is_hidden flag not reported while hidden")
	opossum.exit_hide()
	for i in 120:
		await physics_frame
		if opossum.get_state() == BabyOpossum.State.IDLE: break
	if bool(opossum.get("is_hidden")): _fail("is_hidden flag survived the exit sequence")

## Flee must end on its own — by timeout or by reaching safe distance.
func _check_flee_termination(opossum: Node) -> void:
	_reset(opossum)
	opossum.flee_from(opossum.global_position + Vector2(24.0, 0.0))
	var fled := false
	for i in 600:
		await physics_frame
		if bool(opossum.get("fleeing")): fled = true
		elif fled: break
	if not fled: _fail("flee never engaged")
	if bool(opossum.get("fleeing")): _fail("flee never terminated")

func _check_attack_rejection(opossum: Node) -> void:
	_reset(opossum)
	if not AttackRejection.is_rejector(opossum): _fail("generic rejection helper does not recognize the opossum")
	var rejection := AttackRejection.reject(opossum, {"kind": &"projectile", "origin": opossum.global_position + Vector2(48.0, 0.0)})
	if rejection.is_empty() or not bool(rejection.get("rejected", false)): _fail("reject_attack did not report a rejection")
	if float(rejection.get("damage_applied", -1.0)) != 0.0: _fail("rejection reported damage")
	if opossum.get_state() != BabyOpossum.State.REJECT_HIT: _fail("rejection did not enter the reject-hit state")
	var saw_disapprove := false
	var saw_flee := false
	for i in 600:
		await physics_frame
		if opossum.get_state() == BabyOpossum.State.DISAPPROVE: saw_disapprove = true
		if bool(opossum.get("fleeing")): saw_flee = true
		if saw_flee and not bool(opossum.get("fleeing")): break
	if not saw_disapprove: _fail("rejection skipped the disapprove beat")
	if not saw_flee: _fail("rejection never escalated into a flee")
	_reset(opossum)
	opossum.reject_melee()
	if opossum.get_state() != BabyOpossum.State.REJECT_HIT: _fail("reject_melee did not enter the reject-hit state")
	_reset(opossum)

## A live player bullet must be consumed by the rejection path — the opossum is
## not in the `enemy` group, so without the passive-target route the shot would
## simply pass through and the creature would never react.
func _check_live_projectile_rejection(opossum: Node) -> void:
	_reset(opossum)
	opossum.global_position = Vector2.ZERO
	var bullet := BULLET_SCENE.instantiate()
	bullet.set("team", "player")
	bullet.set("terrain_ballistics_enabled", false)
	root.add_child(bullet)
	bullet.global_position = Vector2(-40.0, 0.0)
	bullet.call("set_direction", Vector2.RIGHT)
	# Kept well under the bullet's range/lifetime budget so only an actual
	# rejection can free it.
	var consumed := false
	for i in 15:
		await physics_frame
		if not is_instance_valid(bullet):
			consumed = true
			break
	if not consumed:
		_fail("player bullet was not consumed by the passive rejection path")
		bullet.queue_free()
	if opossum.get_state() != BabyOpossum.State.REJECT_HIT:
		_fail("live projectile hit did not trigger the rejection reaction (state %d)" % opossum.get_state())
	_reset(opossum)

## The prop layer must exist, own its own SpriteFrames, and stay hidden unless
## a prop clip is authored for the body's resolved action.
func _check_layered_presentation(opossum: Node) -> void:
	var prop := opossum.get_node_or_null("HideProp") as AnimatedSprite2D
	var body := opossum.get_node_or_null("Body") as AnimatedSprite2D
	if prop == null or body == null:
		_fail("actor is missing its body/prop presentation layers")
		return
	if body.sprite_frames == prop.sprite_frames and body.sprite_frames != null:
		_fail("body and prop layers share one SpriteFrames")
	opossum.play_action(&"hide_hold", true)
	var authored: bool = opossum.has_prop_layer_action(&"hide_hold")
	if prop.visible != authored:
		_fail("prop visibility (%s) does not match authored prop coverage (%s)" % [str(prop.visible), str(authored)])
	if authored and prop.animation != body.animation:
		_fail("prop layer is not synchronized with the body clip")
	var prop_clips: int = ANIMATION_SET.get_clip_count(&"barrel_prop")
	var body_clips: int = ANIMATION_SET.get_clip_count(&"body")
	for action in [&"hide_enter", &"hide_hold", &"hide_peek", &"hide_exit"]:
		var body_clip: Dictionary = ANIMATION_SET.resolve_clip(action, &"s", 0, &"body")
		var prop_clip: Dictionary = ANIMATION_SET.resolve_clip(action, &"s", 0, &"barrel_prop")
		if not prop_clip.is_empty() and String(prop_clip.get("layer", "")) != "barrel_prop":
			_fail("prop clip for %s lost its layer identity" % String(action))
		if not body_clip.is_empty() and String(body_clip.get("layer", "")) != "body":
			_fail("body clip for %s lost its layer identity" % String(action))
	print("baby_opossum_runtime_smoke: layers body=%d barrel_prop=%d" % [body_clips, prop_clips])

func _check_art_coverage() -> void:
	var installed: int = ANIMATION_SET.clips.size()
	print("baby_opossum_runtime_smoke: installed_runtime_clips=%d" % installed)
	if installed > 0: return
	var message := "no Baby Opossum runtime strips are installed; the family is fail-soft but not visually complete"
	if OS.get_environment("OPOSSUM_REQUIRE_ART") == "1": _fail(message)
	else: push_warning("baby_opossum_runtime_smoke: " + message)

func _reset(opossum: Node) -> void:
	opossum.set("trust_stage", 0)
	opossum.call("_enter_state", BabyOpossum.State.IDLE)

func _fail(message: String) -> void:
	_failures.append(message)
	push_error("baby_opossum_runtime_smoke: " + message)

func _finish() -> void:
	if _failures.is_empty():
		print("baby_opossum_runtime_smoke: PASS")
		quit(0)
		return
	print("baby_opossum_runtime_smoke: FAIL (%d)" % _failures.size())
	for message in _failures: print("  - %s" % message)
	quit(1)
