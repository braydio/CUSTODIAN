extends SceneTree

const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")


func _init() -> void:
	var loader := LEVEL_LOADER_SCRIPT.new()
	root.add_child(loader)
	var level := Node2D.new()
	var markers := Node2D.new()
	markers.name = "Markers"
	level.add_child(markers)
	var spawn := Marker2D.new()
	spawn.name = "Spawn_Main"
	spawn.position = Vector2(144.0, -72.0)
	markers.add_child(spawn)
	root.add_child(level)
	var actor := Node2D.new()
	root.add_child(actor)
	var errors: Array[String] = []
	if not bool(loader.call("_enter_actor_at_spawn", level, actor, &"Spawn_Main")):
		errors.append("valid named spawn was rejected")
	if not actor.global_position.is_equal_approx(spawn.global_position):
		errors.append("actor did not reach the named spawn")
	var before := actor.global_position
	if bool(loader.call("_enter_actor_at_spawn", level, actor, &"MissingSpawn")):
		errors.append("missing named spawn was accepted")
	if not actor.global_position.is_equal_approx(before):
		errors.append("failed spawn resolution mutated actor position")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelNamedSpawnSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[LevelNamedSpawnSmoke] %s" % error)
	quit(1)
