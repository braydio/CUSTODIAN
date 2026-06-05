extends SceneTree

const MinimapFrameScene := preload("res://game/ui/components/black_reliquary_minimap_frame.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := Node2D.new()
	player.name = "SmokePlayer"
	player.global_position = Vector2(160, 220)
	player.add_to_group("player")
	root.add_child(player)

	var enemy := Node2D.new()
	enemy.name = "SmokeEnemy"
	enemy.global_position = Vector2(420, 260)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var objective := Node2D.new()
	objective.name = "SmokeObjective"
	objective.global_position = Vector2(360, 120)
	objective.add_to_group("objective")
	root.add_child(objective)

	var frame := MinimapFrameScene.instantiate()
	if frame == null:
		push_error("[BlackReliquaryLiveMinimapSmoke] minimap frame did not instantiate")
		quit(1)
		return
	root.add_child(frame)
	await process_frame
	await process_frame

	if not frame.has_method("get_live_minimap"):
		push_error("[BlackReliquaryLiveMinimapSmoke] minimap frame does not expose live minimap")
		quit(1)
		return
	var live_minimap: Node = frame.call("get_live_minimap")
	if live_minimap == null:
		push_error("[BlackReliquaryLiveMinimapSmoke] live minimap was not mounted")
		quit(1)
		return
	if live_minimap.has_method("refresh_now"):
		live_minimap.call("refresh_now")
	await process_frame
	await process_frame

	if not live_minimap.has_method("get_status_summary"):
		push_error("[BlackReliquaryLiveMinimapSmoke] live minimap status API missing")
		quit(1)
		return
	var status: Dictionary = live_minimap.call("get_status_summary")
	if not bool(status.get("has_player", false)):
		push_error("[BlackReliquaryLiveMinimapSmoke] live minimap did not track player")
		quit(1)
		return
	if int(status.get("enemies", 0)) < 1:
		push_error("[BlackReliquaryLiveMinimapSmoke] live minimap did not track enemy")
		quit(1)
		return
	if int(status.get("objectives", 0)) < 1:
		push_error("[BlackReliquaryLiveMinimapSmoke] live minimap did not track objective")
		quit(1)
		return
	var map_size: Vector2i = status.get("map_size", Vector2i.ZERO)
	if map_size == Vector2i.ZERO:
		push_error("[BlackReliquaryLiveMinimapSmoke] live minimap did not establish dynamic map bounds")
		quit(1)
		return

	print("[BlackReliquaryLiveMinimapSmoke] PASS")
	quit(0)
