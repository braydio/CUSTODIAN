extends SceneTree

const SCENE_PATH := "res://game/world/events/ash_bell/forlorn_ritualant_site.tscn"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Unable to load Ash-Bell scene: %s" % SCENE_PATH)
		quit(1)
		return

	var scene := packed.instantiate()
	if scene == null:
		push_error("Unable to instantiate Ash-Bell scene: %s" % SCENE_PATH)
		quit(1)
		return

	root.add_child(scene)
	await process_frame

	var dialogue_callback := Callable(scene, "_on_request_dialogue")
	if scene.request_dialogue.is_connected(dialogue_callback):
		scene.request_dialogue.disconnect(dialogue_callback)

	if not scene.has_method("trigger_intro"):
		push_error("Ash-Bell scene is missing trigger_intro().")
		quit(1)
		return

	scene.call("trigger_intro")
	scene.call("interact_with_ritualant")
	scene.call("touch_thread")
	scene.call("take_stilling_pin")
	scene.call("set_stilling_pin")

	if "event_state" not in scene:
		push_error("Ash-Bell scene is missing event_state.")
		quit(1)
		return

	var event_state: AshBellEventState = scene.get("event_state") as AshBellEventState
	if event_state == null:
		push_error("Ash-Bell event_state was not initialized.")
		quit(1)
		return

	if not event_state.has_thread_knot:
		push_error("Ash-Bell thread interaction did not update state.")
		quit(1)
		return

	if not event_state.has_stilling_pin:
		push_error("Ash-Bell stilling pin pickup did not update state.")
		quit(1)
		return

	if event_state.resolution != AshBellEventState.Resolution.SET_STILLING_PIN:
		push_error("Ash-Bell stilling pin placement did not update resolution.")
		quit(1)
		return

	print("[AshBellSmoke] scene loaded and current core interactions updated state.")
	root.remove_child(scene)
	scene.free()
	await process_frame
	quit(0)
