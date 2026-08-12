extends SceneTree

const REPLAY_PLAYER := preload("res://game/systems/replay/instant_replay_player.gd")

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var fixture := Node2D.new()
	fixture.name = "InstantReplaySmokeRoot"
	root.add_child(fixture)
	current_scene = fixture
	var actor := Node2D.new()
	actor.name = "RecordedOperator"
	actor.add_to_group("player")
	var sprite := Sprite2D.new()
	sprite.texture = GradientTexture2D.new()
	actor.add_child(sprite)
	fixture.add_child(actor)
	var projectile := Node2D.new()
	projectile.name = "RecordedProjectile"
	projectile.add_to_group("projectiles")
	var projectile_sprite := Sprite2D.new()
	projectile_sprite.texture = GradientTexture2D.new()
	projectile.add_child(projectile_sprite)
	fixture.add_child(projectile)
	var recorder := root.get_node_or_null("InstantReplayRecorder")
	_expect(recorder != null, "InstantReplayRecorder autoload must exist")
	if recorder == null:
		quit(1)
		return
	recorder.clear_history()
	await process_frame

	actor.position = Vector2(10.0, 20.0)
	recorder.debug_record_now()
	actor.position = Vector2(40.0, 20.0)
	projectile.position = Vector2(80.0, 12.0)
	recorder.debug_record_now()
	var frames := recorder.get("_frames") as Array[Dictionary]
	_expect(frames.size() == 2, "manual sampling should retain two frames")
	_expect((frames[0]["entities"] as Array).size() == 2, "actor and projectile should be captured")
	var midpoint := REPLAY_PLAYER.sample_frames(frames, 0.05)
	var actor_sample := _find_entity(midpoint, actor.get_instance_id())
	_expect((actor_sample.get("position", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(25.0, 20.0)), "positions should interpolate between samples")

	var original_position := actor.position
	var original_visibility := actor.visible
	_expect(recorder.start_replay(), "two retained frames should start replay")
	_expect(paused, "replay must pause authoritative SceneTree")
	_expect(not actor.visible and not projectile.visible, "live recorded roots should hide")
	_expect(actor.position == original_position, "replay must not mutate live actor transform")
	var status: Dictionary = recorder.get_replay_status()
	_expect(bool(status.get("active", false)), "status should report active replay")
	recorder.finish_replay()
	_expect(not paused, "finish must restore prior unpaused state")
	_expect(actor.visible == original_visibility and projectile.visible, "finish must restore exact visibility")
	_expect(actor.position == original_position, "finish must preserve untouched actor state")

	paused = true
	_expect(recorder.start_replay(), "replay should also start from an already paused state")
	recorder.finish_replay()
	_expect(paused, "finish must restore an existing pause")
	paused = false

	fixture.free()
	if _failed:
		push_error("instant_replay_smoke failed")
		quit(1)
		return
	print("INSTANT_REPLAY_SMOKE: PASS")
	quit(0)


func _find_entity(frame: Dictionary, replay_id: int) -> Dictionary:
	for entity in frame.get("entities", []):
		if int(entity.get("id", 0)) == replay_id:
			return entity
	return {}


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
