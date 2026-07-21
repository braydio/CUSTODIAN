extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const HUD_SCENE := preload("res://game/ui/hud/custodian_hud.tscn")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node2D.new()
	world.name = "OperatorDodgeChargeFeedbackSmoke"
	get_root().add_child(world)
	current_scene = world
	var operator := OPERATOR_SCENE.instantiate()
	world.add_child(operator)
	await process_frame

	var feedback := operator.get_node_or_null("DodgeChargeFeedback")
	_assert(feedback != null, "Operator must instance the presentation-only dodge charge feedback scene")
	if feedback != null:
		_validate_assets(feedback)
		_validate_charge_presentation(operator, feedback)
		await _validate_cancellation(operator, feedback)
		_validate_rejection(operator, feedback)
	await _validate_hud_copy(world)

	Input.action_release("dodge")
	operator.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[OperatorDodgeChargeFeedbackSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[OperatorDodgeChargeFeedbackSmoke] %s" % error)
	quit(1)


func _validate_assets(feedback: Node) -> void:
	var meter := feedback.get_node("MeterSprite") as Sprite2D
	var ready := feedback.get_node("ReadySprite") as Sprite2D
	var release := feedback.get_node("ReleaseSprite") as Sprite2D
	var trail := feedback.get_node("TrailSprite") as Sprite2D
	_assert(meter.texture != null and meter.texture.get_size() == Vector2(768, 96), "meter must use the 8x96 runtime strip")
	_assert(meter.hframes == 8, "meter must expose eight ratio-selected frames")
	_assert(ready.texture != null and ready.texture.get_size() == Vector2(480, 96) and ready.hframes == 5, "ready latch must use five 96px frames")
	_assert(release.texture != null and release.texture.get_size() == Vector2(576, 96) and release.hframes == 6, "release burst must use six 96px frames")
	_assert(trail.texture != null and trail.texture.get_size() == Vector2(32, 16), "trail must use the 32x16 motion texture")


func _validate_charge_presentation(operator: Node, feedback: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 100.0)
	_assert(bool(operator.call("_begin_dodge_charge")), "charge should begin from neutral")
	var status: Dictionary = operator.call("get_dodge_charge_status")
	_assert(bool(status.get("active", false)), "read-only charge status must report active")
	_assert(is_zero_approx(float(status.get("ratio", -1.0))), "initial charge ratio must be zero")

	Input.action_press("dodge")
	operator.call("_handle_dodge_input", 0.05)
	var meter := feedback.get_node("MeterSprite") as Sprite2D
	_assert(not meter.visible, "tap-length holds must remain visually clean")
	operator.call("_handle_dodge_input", 0.05)
	_assert(meter.visible, "ring must appear after the visual delay")
	_assert(meter.frame == clampi(int(round((0.10 / 0.30) * 7.0)), 0, 7), "meter frame must be selected directly from charge ratio")
	_assert(float(operator.get("_dodge_charge_visual_compression")) >= 1.0, "active charge must apply a restrained body compression")

	operator.call("_handle_dodge_input", 0.20)
	status = operator.call("get_dodge_charge_status")
	_assert(bool(status.get("ready", false)), "committed threshold must latch ready")
	_assert((feedback.get_node("ReadySprite") as Sprite2D).visible, "ready transition must play the latch strip once")

	Input.action_release("dodge")
	operator.call("_handle_dodge_input", 0.0)
	_assert(bool(operator.get("_dodge_active")), "release must preserve the ordinary dodge execution")
	_assert((feedback.get_node("ReleaseSprite") as Sprite2D).visible, "release must start the origin burst")
	_assert((feedback.get_node("TrailSprite") as Sprite2D).visible, "release must start the charge-scaled trail")
	_assert(is_zero_approx(float(operator.get("_dodge_charge_visual_compression"))), "release must snap body compression back to neutral")


func _validate_rejection(operator: Node, feedback: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 0.0)
	_assert(not bool(operator.call("_begin_dodge_charge")), "insufficient stamina must reject charge")
	var meter := feedback.get_node("MeterSprite") as Sprite2D
	_assert(meter.visible, "stamina rejection must briefly expose broken ring feedback")
	_assert(meter.modulate.is_equal_approx(Color("#c94d42")), "stamina rejection must use danger red rather than charge cyan")


func _validate_cancellation(operator: Node, feedback: Node) -> void:
	_reset_operator(operator)
	operator.set("stamina", 100.0)
	_assert(bool(operator.call("_begin_dodge_charge")), "cancellation setup charge should begin")
	operator.set("_dodge_charge_timer", 0.10)
	operator.emit_signal("dodge_charge_changed", true, 0.10 / 0.30, false)
	var meter := feedback.get_node("MeterSprite") as Sprite2D
	_assert(meter.visible, "cancellation setup must have a visible ring")
	operator.call("_cancel_dodge_charge", &"incoming_hit")
	_assert(meter.visible, "cancellation must contract instead of disappearing immediately")
	await create_timer(0.10).timeout
	_assert(not meter.visible, "cancellation contraction must extinguish after approximately 0.08 seconds")


func _validate_hud_copy(world: Node) -> void:
	var hud := HUD_SCENE.instantiate()
	world.add_child(hud)
	await process_frame
	hud.call("set_stamina_status", "DODGE", 82.0, true)
	var label := hud.get_node("Root/TopLeftVitals/Margin/Content/StaminaLabel") as Label
	_assert(label.text == "STAMINA DODGE 82%", "charging HUD copy must reuse the stamina label")
	hud.call("set_stamina_status", "DODGE READY", 82.0, false)
	_assert(label.text == "STAMINA DODGE READY", "full charge HUD copy must stop showing percentages")
	hud.queue_free()


func _reset_operator(operator: Node) -> void:
	operator.call("_cancel_dodge")
	operator.set("_dodge_cooldown_remaining", 0.0)
	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.set("_melee_active", false)
	operator.set("_melee_heavy_anticipating", false)
	operator.set("_melee_fast_windup", false)
	operator.set("_melee_recovery_active", false)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
