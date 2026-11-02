class_name LevelPlaytestBootstrap
extends Node

@export var level_path := NodePath("../Level")
@export var operator_path := NodePath("../Operator")
@export_enum("movement", "combat", "full") var profile := "movement"
@export var spawn_id: StringName = &"Spawn_Main"


func _ready() -> void:
	var level := get_node_or_null(level_path)
	var actor := get_node_or_null(operator_path)
	if level == null or actor == null:
		push_error("[LevelPlaytestBootstrap] Level or Operator binding missing")
		return
	if level.has_method("enter_from_main_at_spawn"):
		if not bool(level.call("enter_from_main_at_spawn", actor, spawn_id)):
			push_error("[LevelPlaytestBootstrap] %s could not be activated" % spawn_id)
	elif level.has_method("enter_from_main"):
		level.call("enter_from_main", actor)
	set_meta("playtest_profile", profile)
