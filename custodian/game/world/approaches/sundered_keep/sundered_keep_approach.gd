extends Node2D
class_name SunderedKeepApproach

var _ingress_config: Dictionary = {}


func _ready() -> void:
	add_to_group("sundered_keep_approach")
	add_to_group("world_ingress_approach")


func configure_ingress(config: Dictionary) -> void:
	_ingress_config = config.duplicate(true)

	var trigger := get_node_or_null("ExitTransitionTrigger")
	if trigger != null:
		if config.has("target_scene_path"):
			trigger.set("target_scene_path", String(config["target_scene_path"]))
		if config.has("target_spawn_id"):
			trigger.set("target_spawn_id", config["target_spawn_id"])
		if config.has("return_world_position"):
			trigger.set("return_world_position", config["return_world_position"])


func get_entry_position() -> Vector2:
	var entry := get_node_or_null("EntrySpawn") as Node2D
	if entry != null:
		return entry.global_position
	return global_position


func get_ingress_config() -> Dictionary:
	return _ingress_config.duplicate(true)
