extends Node

var weapon_ready := true
var fire_rate := 0.3  # Seconds between shots

func _ready():
	pass

func try_fire():
	if not weapon_ready:
		return
	
	var operator = get_operator()
	if not operator:
		return
	
	# Find nearest enemy
	var enemies = get_enemies()
	var nearest_enemy = null
	var nearest_dist := INF
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var dist = operator.global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = enemy
	
	if nearest_enemy:
		fire_at(nearest_enemy)
		start_cooldown()

func fire_at(target: Node2D):
	# Simple hitscan - instant damage
	if target.has_method("take_damage"):
		target.take_damage(15.0)  # Base damage
		print("Hit enemy: ", target.enemy_name)

func start_cooldown():
	weapon_ready = false
	await get_tree().create_timer(fire_rate).timeout
	weapon_ready = true

func get_operator():
	return get_node("/root/GameRoot/World/Operator")

func get_enemies():
	var world = get_node("/root/GameRoot/World")
	if world:
		return world.find_children("*", "Enemy")
	return []
