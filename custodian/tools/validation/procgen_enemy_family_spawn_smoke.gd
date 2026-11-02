extends SceneTree

const SPAWNER_SCRIPT := preload(
	"res://game/systems/spawning/ambient_enemy_spawner.gd"
)
const CAMP_SCRIPT := preload(
	"res://game/systems/spawning/ambient_enemy_camp.gd"
)
const GRUNT_SCENE := preload(
	"res://game/actors/enemies/enemy_grunt.tscn"
)
const PURSUIT_SCENE := preload(
	"res://game/actors/enemies/pursuit_frame.tscn"
)


class WalkabilityProvider:
	extends Node

	var allow_spawn := false

	func find_safe_runtime_walkable_global(
		desired_position: Vector2,
		_radius_tiles: int
	) -> Vector2:
		return desired_position if allow_spawn else Vector2.INF


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)
	var provider := WalkabilityProvider.new()
	provider.add_to_group("procgen_walkability_provider")
	world.add_child(provider)
	var player := Node2D.new()
	player.add_to_group("player")
	world.add_child(player)
	var spawner := SPAWNER_SCRIPT.new() as AmbientEnemySpawner
	spawner.enemy_scene = GRUNT_SCENE
	spawner.enemy_scenes = [GRUNT_SCENE, PURSUIT_SCENE]
	game_root.add_child(spawner)

	for index in 2:
		var marker := Marker2D.new()
		marker.name = "Marker%d" % index
		marker.add_to_group("ambient_enemy_camp_marker")
		marker.set_meta("encounter_id", "encounter_%d" % index)
		world.add_child(marker)
		marker.global_position = Vector2(index * 800.0, 0.0)
	assert(spawner.spawn_from_markers() == 2)
	var camps := get_nodes_in_group("generated_procgen_ambient_camp")
	assert(camps.size() == 2)
	assert((camps[0] as AmbientEnemyCamp).enemy_scenes == [GRUNT_SCENE, PURSUIT_SCENE])
	assert((camps[1] as AmbientEnemyCamp).enemy_scenes == [GRUNT_SCENE, PURSUIT_SCENE])
	provider.allow_spawn = true
	(camps[0] as AmbientEnemyCamp).spawn_camp()
	await physics_frame
	await physics_frame
	await physics_frame
	assert(enemies.get_node_or_null("EnemyGrunt") is Enemy)
	assert(enemies.get_node_or_null("PursuitFrame") is Enemy)

	var retry_camp := CAMP_SCRIPT.new() as AmbientEnemyCamp
	retry_camp.enemy_scene = PURSUIT_SCENE
	retry_camp.enemy_count_min = 1
	retry_camp.enemy_count_max = 1
	retry_camp.spawn_radius_px = 0.0
	world.add_child(retry_camp)
	provider.allow_spawn = false
	retry_camp.spawn_camp()
	assert(retry_camp.get("_queued_or_spawned_count") == 0)
	assert(not bool(retry_camp.get("_spawned")))
	provider.allow_spawn = true
	retry_camp.spawn_camp()
	assert(retry_camp.get("_queued_or_spawned_count") == 1)
	assert(bool(retry_camp.get("_spawned")))
	await physics_frame
	await physics_frame
	var pursuit := enemies.get_node_or_null("PursuitFrame") as Enemy
	assert(pursuit != null)
	assert(pursuit.custom_enemy_animation_set == "pursuit_frame")
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"idle_s"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"draw_s"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"melee_e"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"intercept_windup_e"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"intercept_burst_w"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"intercept_recover_e"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"checkpoint_halt_s"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"patrol_scan_s"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"search_sweep_s"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"investigate_scan_s"))
	assert(pursuit.animated_sprite.sprite_frames.has_animation(&"return_to_route_s"))
	print("procgen_enemy_family_spawn_smoke: PASS")
	quit(0)
