extends SceneTree

const PIP_SCENE := preload("res://game/ui/hud/components/ranged_ballistic_pip.tscn")
const RETICLE_SCENE := preload("res://game/ui/hud/components/ranged_reticle.tscn")


func _init() -> void:
	var failures: Array[String] = []
	var hud := Control.new()
	root.add_child(hud)
	var intent := RETICLE_SCENE.instantiate() as Control
	var pip := PIP_SCENE.instantiate() as Control
	hud.add_child(intent)
	hud.add_child(pip)
	await process_frame
	intent.position = Vector2(300.0, 200.0)
	intent.call("set_weapon_status", {
		"ranged_posture": "ready",
		"ranged_transition_ratio": 1.0,
		"ranged_aim_accuracy_ratio": 1.0,
	})
	pip.position = Vector2(240.0, 200.0)
	pip.visible = true
	pip.call("set_weapon_status", {
		"ranged_ballistic_alignment_ratio": 0.4,
		"ranged_aim_error_degrees": 18.0,
		"ranged_ballistic_obstructed": false,
	})
	if intent.position == pip.position:
		failures.append("misaligned intent reticle and ballistic pip did not separate")
	var intent_before := intent.position
	pip.position = intent.position + (intent.size - pip.size) * 0.5
	pip.call("set_weapon_status", {
		"ranged_ballistic_alignment_ratio": 1.0,
		"ranged_aim_error_degrees": 0.0,
		"ranged_ballistic_obstructed": false,
	})
	if intent.position != intent_before:
		failures.append("ballistic pip mutated intent reticle position")
	var state: Dictionary = pip.call("get_presentation_state")
	if bool(state.obstructed) or float(state.aim_error_degrees) > 0.01:
		failures.append("aligned pip presentation state was incorrect")
	pip.call("set_weapon_status", {
		"ranged_ballistic_alignment_ratio": 0.2,
		"ranged_aim_error_degrees": 24.0,
		"ranged_ballistic_obstructed": true,
	})
	state = pip.call("get_presentation_state")
	if not bool(state.obstructed):
		failures.append("obstructed solution did not switch pip state")
	intent.visible = false
	pip.visible = false
	if intent.visible or pip.visible:
		failures.append("HUD hiding did not hide both ranged cues")
	if pip.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("ballistic pip can intercept input or mutate Operator state")
	hud.queue_free()
	await process_frame
	if failures.is_empty():
		print("ranged_ballistic_reticle_smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
