extends SceneTree

const SPAWNER_SCRIPT := preload("res://game/systems/spawning/vaultwing_spawner.gd")
const SCENE_TEXT := "res://scenes/game.tscn"
var failures: PackedStringArray = PackedStringArray()

func _init() -> void:
	var text := FileAccess.get_file_as_string(SCENE_TEXT)
	if not text.contains("[node name=\"Ambient\" type=\"Node2D\" parent=\"World\""):
		failures.append("game.tscn lacks production World/Ambient container")
	if not text.contains("[node name=\"VaultwingSpawner\" type=\"Node\" parent=\".\"]"):
		failures.append("game.tscn lacks production VaultwingSpawner")
	var root_node := Node2D.new()
	root_node.name = "GameRoot"
	root.add_child(root_node)
	var world := Node2D.new(); world.name = "World"; root_node.add_child(world)
	var ambient := Node2D.new(); ambient.name = "Ambient"; world.add_child(ambient)
	var player := Node2D.new(); player.name = "Player"; player.add_to_group("player"); player.position = Vector2(-1000, -1000); world.add_child(player)
	var marker := Marker2D.new(); marker.name = "VaultwingSpawn"; marker.add_to_group("vaultwing_spawn_marker"); marker.position = Vector2(600, 0); world.add_child(marker)
	var perch := Marker2D.new(); perch.name = "VaultwingPerch"; perch.add_to_group("vaultwing_perch"); perch.position = Vector2(620, 0); world.add_child(perch)
	var spawner := SPAWNER_SCRIPT.new(); spawner.name = "VaultwingSpawner"; spawner.vaultwing_container_path = NodePath("/root/GameRoot/World/Ambient"); spawner.max_active_vaultwings = 1; root_node.add_child(spawner)
	await physics_frame
	await process_frame
	var count := spawner.get_active_count()
	if count != 1: failures.append("marker spawn did not create exactly one Vaultwing")
	var duplicate_count := spawner.spawn_from_markers()
	if duplicate_count != 0 or spawner.get_active_count() != 1: failures.append("duplicate marker processing created another Vaultwing")
	if ambient.get_child_count() != 1: failures.append("Vaultwing was not placed under World/Ambient")
	if perch.get_parent() == null or marker.global_position.distance_to(perch.global_position) < 10.0: failures.append("perch marker was not distinct from spawn marker")
	spawner.reset_for_world()
	await process_frame
	var replacement_count := spawner.spawn_from_markers()
	if replacement_count != 1 or spawner.get_active_count() != 1:
		failures.append("world reset did not permit a clean replacement population count=%d active=%d consumed=%s" % [replacement_count, spawner.get_active_count(), str(marker.get_meta("vaultwing_spawned", false))])
	spawner.despawn_all()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({"schema":"custodian.headless_test.result.v1","test":"vaultwing_world_spawn_smoke","passed":failures.is_empty(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
