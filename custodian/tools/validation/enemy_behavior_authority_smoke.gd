extends SceneTree

const ENEMY := preload("res://game/actors/enemies/enemy.gd")

func _init() -> void:
	var actor := ENEMY.new()
	actor.behavior_state_machine_enabled = false
	assert(actor.get_behavior_authority_snapshot().authority == "legacy_assault")
	var behavior := Node.new(); actor.behavior_state_machine = behavior; actor.behavior_state_machine_enabled = true
	assert(actor.get_behavior_authority_snapshot().authority == "behavior_state_machine")
	assert(FileAccess.get_file_as_string("res://game/actors/enemies/enemy_grunt.tscn").find("behavior_state_machine_enabled = true") >= 0)
	assert(FileAccess.get_file_as_string("res://game/actors/enemies/enemy_marine.tscn").find("behavior_profile_id = &\"raider_marine\"") >= 0)
	assert(FileAccess.get_file_as_string("res://game/actors/enemies/enemy_savage.tscn").find("behavior_state_machine_enabled = true") >= 0)
	print("enemy_behavior_authority_smoke: PASS")
	actor.free()
	behavior.free()
	quit(0)
