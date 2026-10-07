extends SceneTree

const HUD_SCENE := preload("res://game/ui/hud/custodian_hud.tscn")

var _failures: Array[String] = []


func _init() -> void:
	var hud := HUD_SCENE.instantiate() as CustodianHUD
	root.add_child(hud)
	var owner := Node.new()
	root.add_child(owner)
	for i in 5:
		await process_frame
	var prompt := hud.get_node("Root/BottomLeftPrompt/BlackReliquaryPrompt") as Control

	hud.show_interaction("LEASE CHECK", "Ordinary prompt")
	hud.set("_last_prompt_frame", Engine.get_process_frames() - 3)
	hud.call("_process", 0.0)
	if prompt.visible:
		_fail("ordinary one-shot prompt no longer expires under the two-frame lease")

	for i in 120:
		await process_frame
		hud.show_proximity_interaction("TARGET", "Interact", &"interact", owner)
	if not prompt.visible:
		_fail("valid frame-refreshed proximity prompt did not survive 120 frames")

	hud.show_latched_interaction("READOUT", "Long form text", "G", "", owner, 4.0)
	for i in 3:
		hud.call("_process", 1.0)
		hud.show_proximity_interaction("TARGET", "Interact", &"interact", owner)
		hud.show_action_interaction("OTHER", "Other prompt", &"interact")
	if not prompt.visible or hud.get("_latched_readout_remaining") <= 0.0:
		_fail("proximity or ordinary prompt replaced the latched readout before four seconds")
	var body_label := hud.get_node("Root/BottomLeftPrompt/BlackReliquaryPrompt/Stack/BodyPlaque/BodyRow/Body") as Label
	if body_label.text != "Long form text":
		_fail("latched readout body was overwritten during its dwell")
	hud.call("_process", 1.0)
	hud.show_proximity_interaction("TARGET", "Interact", &"interact", owner)
	if body_label.text != "Interact":
		_fail("proximity prompt did not return after the readout dwell expired")

	hud.show_latched_interaction("SUPPRESSED", "Must clear", "G", "", owner, 4.0)
	hud.set_external_overlay_hidden(true)
	if prompt.visible or hud.get("_latched_readout_remaining") != 0.0:
		_fail("external overlay suppression did not hide and clear a latched prompt")
	hud.set_external_overlay_hidden(false)
	hud.show_latched_interaction("OWNER RELEASE", "Temporary", "G", "", owner, 4.0)
	owner.queue_free()
	await process_frame
	hud.call("_process", 0.0)
	if prompt.visible or hud.get("_latched_readout_remaining") != 0.0:
		_fail("freed target owner did not release its latched prompt")

	var passed := _failures.is_empty()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({
		"schema": "custodian.headless_test.result.v1",
		"test": "hud_interaction_prompt_lease_smoke",
		"passed": passed,
		"failure_count": _failures.size(),
		"failures": _failures,
	}))
	if passed:
		print("hud_interaction_prompt_lease_smoke: PASS")
		quit(0)
		return
	for message in _failures:
		push_error("hud_interaction_prompt_lease_smoke: " + message)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)
