extends SceneTree

const SITE_SCENE := preload("res://game/world/events/ash_bell/forlorn_ritualant_site.tscn")
const LEVEL_SCENE := preload("res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var site := SITE_SCENE.instantiate()
	root.add_child(site)
	var hazard := site.get_node("Props/WhiteThreadHazard") as WhiteThreadHazard
	var left := hazard.get_node("TelegraphLeft") as EncounterHazardTelegraph2D
	var right := hazard.get_node("TelegraphRight") as EncounterHazardTelegraph2D
	_assert_true(left.position == Vector2(-240, 0) and right.position == Vector2(240, 0), "telegraphs align to mechanical segment centers")
	for telegraph in [left, right]:
		_assert_true(telegraph.get_node("Decal").texture.get_size() == Vector2(384, 96), "decal is 384x96")
		_assert_true(_contains_no_collision(telegraph), "telegraph owns no collision")
		telegraph.set_presentation_state(EncounterHazardTelegraph2D.State.DORMANT)
		_assert_true(is_equal_approx(telegraph.decal.modulate.a, 0.18), "dormant alpha")
		telegraph.set_presentation_state(EncounterHazardTelegraph2D.State.WARNING)
		_assert_true(telegraph.warning_sprite.visible and telegraph.warning_sprite.is_playing(), "warning loop starts")
		telegraph.set_presentation_state(EncounterHazardTelegraph2D.State.ACTIVE)
		_assert_true(telegraph.activation_sprite.visible and telegraph.activation_sprite.is_playing(), "active transition starts burst")
		telegraph.activation_sprite.frame = 5
		telegraph.set_presentation_state(EncounterHazardTelegraph2D.State.ACTIVE)
		_assert_true(telegraph.activation_sprite.frame == 5, "active does not retrigger every update")
		telegraph.set_presentation_state(EncounterHazardTelegraph2D.State.SUPPRESSED)
		_assert_true(is_equal_approx(telegraph.decal.modulate.a, 0.06), "suppressed alpha")

	var left_shape := hazard.get_node("LeftCollisionShape2D") as CollisionShape2D
	var right_shape := hazard.get_node("RightCollisionShape2D") as CollisionShape2D
	_assert_true((left_shape.shape as RectangleShape2D).size == Vector2(288, 64), "left gameplay hazard remains 288x64")
	_assert_true((right_shape.shape as RectangleShape2D).size == Vector2(288, 64), "right gameplay hazard remains 288x64")
	site.queue_free()
	await process_frame

	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	var seal := level.get_node("OcclusionRoot/LowerQuarterSeal") as Sprite2D
	_assert_true(seal.visible and is_equal_approx(seal.modulate.a, 1.0), "seal begins visible")
	level.call("_on_ritualant_encounter_completed", 0)
	await create_timer(1.45).timeout
	_assert_true(seal.modulate.a <= 0.01, "seal fades after completion")
	level.queue_free()
	await process_frame
	print("[ritualant_hazard_telegraph_smoke] PASS")
	quit(0)


func _contains_no_collision(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D:
		return false
	for child in node.get_children():
		if not _contains_no_collision(child):
			return false
	return true


func _assert_true(value: bool, label: String) -> void:
	if value:
		return
	push_error("[ritualant_hazard_telegraph_smoke] Assertion failed: %s" % label)
	quit(1)
