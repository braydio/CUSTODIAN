extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const BEAM_COOKIE := "res://content/sprites/world/lighting/light_cookie_beam_96x192.png"
const GLOW_COOKIE := "res://content/sprites/world/lighting/light_cookie_radial_soft_128.png"
const WARM_COLOR := Color("e8d7b2")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var operator := OPERATOR_SCENE.instantiate()
	get_root().add_child(operator)
	await process_frame

	var flashlight_nodes := operator.find_children("OperatorFlashlight", "Node2D", true, false)
	_expect(flashlight_nodes.size() == 1, "production Operator must contain exactly one OperatorFlashlight")
	if flashlight_nodes.size() != 1:
		_finish()
		return

	var flashlight: Node2D = flashlight_nodes[0]
	var lights := flashlight.find_children("*", "PointLight2D", true, false)
	_expect(lights.size() == 2, "OperatorFlashlight must contain exactly two PointLight2D nodes")
	var beam := flashlight.get_node_or_null("BeamPivot/BeamLight") as PointLight2D
	var glow := flashlight.get_node_or_null("LocalGlow") as PointLight2D
	_expect(beam != null, "BeamLight missing")
	_expect(glow != null, "LocalGlow missing")
	if beam == null or glow == null:
		_finish()
		return

	_expect(not beam.enabled and not glow.enabled, "flashlight lights must start disabled")
	_expect(beam.texture != null and beam.texture.resource_path == BEAM_COOKIE, "beam cookie contract changed")
	_expect(glow.texture != null and glow.texture.resource_path == GLOW_COOKIE, "local glow cookie contract changed")
	_expect(beam.shadow_enabled, "beam shadows must be enabled")
	_expect(not glow.shadow_enabled, "local glow shadows must be disabled")
	_expect(beam.color.is_equal_approx(WARM_COLOR), "beam warm color contract changed")
	_expect(glow.color.is_equal_approx(WARM_COLOR), "local glow warm color contract changed")
	_expect(beam.is_in_group("render_point_light"), "beam is not registered as render_point_light")
	_expect(glow.is_in_group("render_point_light"), "local glow is not registered as render_point_light")

	flashlight.call("toggle_flashlight")
	_expect(beam.enabled and glow.enabled, "toggle ON must enable both lights")
	flashlight.call("toggle_flashlight")
	_expect(not beam.enabled and not glow.enabled, "toggle OFF must disable both lights")

	operator.aim_direction = Vector2.UP
	await process_frame
	var beam_direction := Vector2.DOWN.rotated(flashlight.get_node("BeamPivot").rotation)
	_expect(beam_direction.is_equal_approx(Vector2.UP), "beam does not follow parent aim_direction")
	var preserved_rotation: float = flashlight.get_node("BeamPivot").rotation
	operator.aim_direction = Vector2.ZERO
	await process_frame
	_expect(is_equal_approx(flashlight.get_node("BeamPivot").rotation, preserved_rotation), "zero aim reset the last valid beam direction")

	for presentation_state in [
		{"primary_weapon_equipped": false, "combat_loadout_mode": &"holstered"},
		{"primary_weapon_equipped": true, "combat_loadout_mode": &"melee"},
		{"primary_weapon_equipped": true, "combat_loadout_mode": &"ranged"},
	]:
		operator.primary_weapon_equipped = presentation_state.primary_weapon_equipped
		operator.combat_loadout_mode = presentation_state.combat_loadout_mode
		flashlight.call("toggle_flashlight")
		_expect(beam.enabled == glow.enabled, "weapon presentation state split flashlight light state")

	var component_source := FileAccess.get_file_as_string("res://game/actors/operator/components/operator_flashlight.gd").to_lower()
	var component_scene := FileAccess.get_file_as_string("res://game/actors/operator/components/operator_flashlight.tscn").to_lower()
	for forbidden_term in ["battery", "charge_meter", "durability", "resource_consumption"]:
		_expect(not component_source.contains(forbidden_term) and not component_scene.contains(forbidden_term), "flashlight contains forbidden resource state: %s" % forbidden_term)

	operator.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("OPERATOR_FLASHLIGHT_SMOKE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("OPERATOR_FLASHLIGHT_SMOKE: FAIL (%d)" % failures.size())
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
