extends Node

const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")

var weapon_ready := true
var fire_rate := 0.3


func try_fire() -> void:
	if not weapon_ready:
		return

	var operator := get_operator()
	if operator == null:
		return

	var nearest_enemy: Node2D = null
	var nearest_dist := INF

	for enemy in get_enemies():
		if enemy is Node2D and is_instance_valid(enemy):
			var enemy_node := enemy as Node2D
			var dist := operator.global_position.distance_to(enemy_node.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = enemy_node

	if nearest_enemy != null:
		fire_at(nearest_enemy)
		start_cooldown()


func fire_at(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(15.0, CombatConstants.HitStrength.LIGHT)
		var target_name := target.name
		var enemy_name_variant = target.get("enemy_name")
		if enemy_name_variant != null:
			target_name = str(enemy_name_variant)
		print("Hit enemy: ", target_name)


func start_cooldown() -> void:
	weapon_ready = false
	await get_tree().create_timer(fire_rate).timeout
	weapon_ready = true


func get_operator() -> Node2D:
	return get_node_or_null("/root/GameRoot/World/Operator") as Node2D


func get_enemies() -> Array:
	var world := get_node_or_null("/root/GameRoot/World")
	if world == null:
		return []
	return world.find_children("*", "Enemy")
