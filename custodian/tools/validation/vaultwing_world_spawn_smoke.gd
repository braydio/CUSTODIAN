extends SceneTree

const SPAWNER_SCRIPT := preload("res://game/systems/spawning/vaultwing_spawner.gd")
const LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")
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
	var spawner := SPAWNER_SCRIPT.new(); spawner.name = "VaultwingSpawner"; spawner.vaultwing_container_path = NodePath("/root/GameRoot/World/Ambient"); spawner.max_active_vaultwings = 1; root_node.add_child(spawner)
	var loader := LOADER_SCRIPT.new(); loader.name = "ContractWorldLoaderFixture"; loader.vaultwing_spawner_path = NodePath("/root/GameRoot/VaultwingSpawner"); loader.process_mode = Node.PROCESS_MODE_DISABLED; root_node.add_child(loader)
	var candidates: Array[Vector2i] = [Vector2i(20, 20), Vector2i(32, 20), Vector2i(20, 34)]
	await process_frame
	loader.place_vaultwing_markers_for_candidates(candidates, world)
	await physics_frame
	await process_frame
	var generated_spawns: Array[Node] = root.get_tree().get_nodes_in_group("vaultwing_spawn_marker")
	var generated_perches: Array[Node] = root.get_tree().get_nodes_in_group("vaultwing_perch")
	if generated_spawns.size() != 1: failures.append("production marker bridge did not create one spawn marker")
	if generated_perches.is_empty(): failures.append("production marker bridge did not create perch markers")
	var count := spawner.get_active_count()
	if count != 1: failures.append("marker spawn did not create exactly one Vaultwing")
	var duplicate_count := spawner.spawn_from_markers()
	if duplicate_count != 0 or spawner.get_active_count() != 1: failures.append("duplicate marker processing created another Vaultwing")
	if ambient.get_child_count() != 1: failures.append("Vaultwing was not placed under World/Ambient")
	if not generated_perches.is_empty() and not generated_spawns.is_empty() and generated_spawns[0].global_position.distance_to(generated_perches[0].global_position) < 320.0: failures.append("production perch spacing requirement was not honored")
	spawner.reset_for_world()
	await process_frame
	loader.place_vaultwing_markers_for_candidates(candidates, world)
	await process_frame
	var replacement_count := spawner.spawn_from_markers()
	if spawner.get_active_count() != 1:
		failures.append("world reset did not permit a clean replacement population count=%d active=%d" % [replacement_count, spawner.get_active_count()])
	spawner.despawn_all()
	print("CUSTODIAN_TEST_RESULT_JSON:" + JSON.stringify({"schema":"custodian.headless_test.result.v1","test":"vaultwing_world_spawn_smoke","passed":failures.is_empty(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
