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
	if not scene.has_method("trigger_intro"):
		push_error("Ash-Bell scene is missing trigger_intro().")
		quit(1)
		return

	scene.call("trigger_intro")
	scene.call("interact_with_ritualant")
	scene.call("touch_thread")
	scene.call("take_clapper")

	if "event_state" not in scene:
		push_error("Ash-Bell scene is missing event_state.")
		quit(1)
		return

	var event_state = scene.get("event_state")
	if event_state == null:
		push_error("Ash-Bell event_state was not initialized.")
		quit(1)
		return

	if not bool(event_state.get("has_clapper")):
		push_error("Ash-Bell clapper interaction did not update state.")
		quit(1)
		return

	print("[AshBellSmoke] scene loaded and core interactions updated state.")
	quit(0)
