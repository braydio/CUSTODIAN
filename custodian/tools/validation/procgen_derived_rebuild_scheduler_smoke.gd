extends SceneTree

const SCHEDULER_SCRIPT := preload("res://game/world/procgen/derived_rebuild_scheduler.gd")


func _init() -> void:
	var scheduler := SCHEDULER_SCRIPT.new()
	assert(scheduler.request(&"collision", "first", Rect2i(1, 2, 3, 4), 17))
	assert(not scheduler.request(&"collision", "second", Rect2i(3, 4, 3, 4), 17))
	var before_commit: Dictionary = scheduler.get_snapshot()
	var collision: Dictionary = before_commit["systems"]["collision"]
	assert(collision["requested"] == 2)
	assert(collision["coalesced"] == 1)
	assert(collision["committed"] == 0)
	assert(before_commit["pending"].size() == 1)
	var entry: Dictionary = before_commit["pending"][0]
	assert(entry["reasons"] == ["first", "second"])
	assert(entry["region"] == Rect2i(1, 2, 5, 6))
	scheduler.commit(&"collision", 23, 17)
	var after_commit: Dictionary = scheduler.get_snapshot()
	collision = after_commit["systems"]["collision"]
	assert(collision["committed"] == 1)
	assert(collision["duration_usec_total"] == 23)
	assert(after_commit["pending"].is_empty())
	print("procgen_derived_rebuild_scheduler_smoke: PASS")
	quit(0)
