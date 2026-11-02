extends SceneTree

const GENERATOR_SCRIPT := preload("res://tools/level_authoring/level_scaffold_generator.gd")
const OUTPUT_ROOT := "user://level_scaffold_generator_smoke"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var generator: RefCounted = GENERATOR_SCRIPT.new()
	generator.call("_remove_tree", ProjectSettings.globalize_path(OUTPUT_ROOT))
	var errors: Array[String] = []
	var request := _request("smoke_level_alpha", "Smoke Level Alpha")
	request.dry_run = true
	var dry := generator.call("generate", request) as Dictionary
	if not bool(dry.get("ok", false)) or not bool(dry.get("dry_run", false)):
		errors.append("dry run failed")
	request.dry_run = false
	var generated := generator.call("generate", request) as Dictionary
	if not bool(generated.get("ok", false)):
		errors.append("clean generation failed: %s" % str(generated.get("errors", [])))
	else:
		var scene_path := "user://level_scaffold_generator_smoke/custodian/game/world/levels/authored/smoke/smoke_level_alpha/smoke_level_alpha.tscn"
		var scene := load(scene_path) as PackedScene
		if scene == null:
			errors.append("generated production scene did not load")
		else:
			var level := scene.instantiate()
			root.add_child(level)
			await process_frame
			if level.find_child("Operator", true, false) != null: errors.append("production scene contains Operator")
			if level.get_node_or_null("Collision/PathBoundaryCollision") == null: errors.append("production boundary root missing")
			if not bool(level.call("has_spawn", &"Spawn_Main")): errors.append("generated named spawn missing")
			level.queue_free()
			await process_frame
	var duplicate := generator.call("generate", request) as Dictionary
	if bool(duplicate.get("ok", false)): errors.append("duplicate generation was not rejected")
	request.force_generated = true
	var forced := generator.call("generate", request) as Dictionary
	if not bool(forced.get("ok", false)): errors.append("managed force regeneration failed")
	var second := _request("smoke_level_beta", "Smoke Level Beta")
	second.playtest_profile = "full"
	var second_result := generator.call("generate", second) as Dictionary
	if not bool(second_result.get("ok", false)): errors.append("second registered generation failed")
	else:
		var full_scene := load("user://level_scaffold_generator_smoke/custodian/game/world/levels/authored/smoke/smoke_level_beta/smoke_level_beta_playtest.tscn") as PackedScene
		if full_scene == null:
			errors.append("full playtest scene did not load")
		else:
			var full_wrapper := full_scene.instantiate()
			if full_wrapper.get_node_or_null("Combat") == null or full_wrapper.get_node_or_null("NavigationSystem") == null or full_wrapper.get_node_or_null("EnemyDirector") == null:
				errors.append("full profile omitted combat systems")
			var wave := full_wrapper.get_node_or_null("WaveManager")
			if wave == null or bool(wave.get("debug_spawn_grunt_on_start")):
				errors.append("full profile WaveManager is missing or debug spawn is enabled")
			full_wrapper.free()
	var registry_path := ProjectSettings.globalize_path(OUTPUT_ROOT + "/custodian/content/levels/levels.json")
	var registry_file := FileAccess.open(registry_path, FileAccess.READ)
	if registry_file == null:
		errors.append("alternate registry missing")
	else:
		var registry := JSON.parse_string(registry_file.get_as_text()) as Dictionary
		var definitions: Array = registry.get("definitions", [])
		var sorted := definitions.duplicate()
		sorted.sort()
		if definitions != sorted: errors.append("registry definitions are not sorted")
	var unmanaged := _request("unmanaged_level", "Unmanaged Level")
	var unmanaged_path := ProjectSettings.globalize_path(OUTPUT_ROOT + "/custodian/game/world/levels/authored/smoke/unmanaged_level/unmanaged_level.gd")
	DirAccess.make_dir_recursive_absolute(unmanaged_path.get_base_dir())
	var unmanaged_file := FileAccess.open(unmanaged_path, FileAccess.WRITE)
	unmanaged_file.store_string("extends Node2D\n")
	unmanaged_file.close()
	if bool((generator.call("generate", unmanaged) as Dictionary).get("ok", false)):
		errors.append("unmanaged overwrite was accepted")
	generator.call("_remove_tree", ProjectSettings.globalize_path(OUTPUT_ROOT))
	_finish(errors)


func _request(level_id: String, display_name: String) -> Dictionary:
	return {
		"level_id": level_id,
		"display_name": display_name,
		"region": "smoke",
		"output_root": OUTPUT_ROOT,
		"register_level": true,
		"canvas_size": Vector2i(640, 480),
	}


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelScaffoldGeneratorSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[LevelScaffoldGeneratorSmoke] %s" % error)
	quit(1)
