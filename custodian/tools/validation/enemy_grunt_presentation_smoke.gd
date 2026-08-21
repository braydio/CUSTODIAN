extends SceneTree

const ANIMATION_SET: EnemyAnimationSet = preload(
	"res://game/actors/enemies/presentation/sets/enemy_grunt_animation_set.tres"
)
const CONTROLLER := preload(
	"res://game/actors/enemies/presentation/enemy_presentation_controller.gd"
)


func _init() -> void:
	var required_actions: Array[StringName] = [
		&"locomotion.relaxed_idle", &"locomotion.ready_idle",
		&"locomotion.walk", &"locomotion.run", &"posture.alert",
		&"posture.draw", &"combat.fast_01", &"combat.fast_02",
		&"combat.fast_03", &"reaction.flinch_01",
		&"reaction.flinch_02", &"reaction.stagger", &"reaction.death",
		&"reaction.knockdown_01", &"reaction.knockdown_02",
		&"reaction.stand_up", &"combat.falcon.windup",
		&"combat.falcon.inflight", &"combat.falcon.recovery",
		&"combat.falcon.collision", &"combat.falcon.collision_knockdown",
		&"reaction.falcon_reversal_victim",
	]
	for action in required_actions:
		assert(not ANIMATION_SET.resolve_clip(action, &"e").is_empty(), String(action))

	var reversal := ANIMATION_SET.resolve_clip(
		&"reaction.falcon_reversal_victim", &"e"
	)
	assert(reversal.get("frame_size") == Vector2i(156, 156))

	var first := _selection_fingerprint()
	var second := _selection_fingerprint()
	assert(first == second)
	assert(first.slice(0, 3) == [
		&"combat.fast_01", &"combat.fast_02", &"combat.fast_01",
	])
	assert(first.slice(3, 5) == [
		&"reaction.flinch_01", &"reaction.flinch_02",
	])
	var alternate: EnemyPresentationController = CONTROLLER.new()
	alternate.stable_spawn_ordinal = 1
	assert(alternate.select_normal_attack() == &"combat.fast_02")
	assert(alternate.select_flinch_for_severity(0.05) == &"reaction.flinch_01")
	assert(alternate.select_flinch_for_severity(0.20) == &"reaction.flinch_02")

	var fast := ANIMATION_SET.resolve_clip(&"combat.fast_01", &"e")
	assert(not String(fast.get("body_path", "")).is_empty())
	assert(not String(fast.get("fx_path", "")).is_empty())
	assert(float(fast.get("fps", 0.0)) > 0.0)
	assert(not fast.has("hit_frame"))
	assert(not fast.has("damage"))

	print("enemy_grunt_presentation_smoke: PASS actions=%d fingerprint=%s" % [
		required_actions.size(), str(first).sha256_text(),
	])
	quit(0)


func _selection_fingerprint() -> Array[StringName]:
	var controller: EnemyPresentationController = CONTROLLER.new()
	return [
		controller.select_normal_attack(),
		controller.select_normal_attack(),
		controller.select_normal_attack(),
		controller.select_flinch(),
		controller.select_flinch(),
		controller.select_flavor(),
	]
