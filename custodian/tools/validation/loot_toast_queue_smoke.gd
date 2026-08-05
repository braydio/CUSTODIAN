extends SceneTree

const QUEUE_SCENE := preload("res://game/ui/loot/loot_toast_queue.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var queue := QUEUE_SCENE.instantiate()
	root.add_child(queue)
	queue.call("push_pickup", &"parts", "Recovered Parts", 3, Color.GOLD)
	queue.call("push_pickup", &"parts", "Recovered Parts", 7, Color.GOLD)
	_assert(queue.is_in_group("loot_toast_queue"), "loot queue group registration missing")
	_assert((queue.get("_entries") as Array).size() == 1, "same-item pickup did not merge")
	_assert(int((queue.get("_entries") as Array)[0].get("quantity", 0)) == 10, "merged pickup quantity drifted")
	queue.call("push_pickup", &"ammo", "Ammo Recovered", 4, Color.GREEN)
	_assert((queue.get("_entries") as Array).size() == 2, "different pickup categories merged")
	print("[LootToastQueueSmoke] PASS")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("[LootToastQueueSmoke] %s" % message)
		quit(1)
