extends SceneTree

const LEVEL_SCENE := preload("res://game/world/levels/authored/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery.tscn")
const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := LEVEL_SCENE.instantiate()
	root.add_child(level)
	await process_frame
	var errors: Array[String] = []
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/data/dev/lords_of_pain/gallery_manifest.json"))
	var expected_semantics := ["warrior", "skeleton", "highlight", "loot_indicator", "gold_drop", "glint", "ground_stone"]
	var excluded := ["cursor_gauntlet", "rocks", "mushrooms"]
	var found_semantics: Array[String] = []
	var rows: Array = manifest.get("states", [])
	for row: Dictionary in rows:
		if not found_semantics.has(row.semantic): found_semantics.append(row.semantic)
		if not ResourceLoader.exists(row.runtime_path):
			errors.append("missing Asset V2 runtime output: %s" % row.runtime_path)
		var source_master := ProjectSettings.globalize_path("res://../" + str(row.get("source_master", "")))
		if str(row.get("source_master", "")).is_empty() or not FileAccess.file_exists(source_master):
			errors.append("missing immutable Asset V2 source master: %s" % row.get("source_master", ""))
	for semantic in expected_semantics:
		if not found_semantics.has(semantic): errors.append("manifest semantic missing: %s" % semantic)
	for semantic in excluded:
		if found_semantics.has(semantic): errors.append("user-excluded semantic unexpectedly staged: %s" % semantic)
	var excluded_rows: Array = manifest.get("excluded_by_user", [])
	if excluded_rows.size() != 3: errors.append("manifest must record all three user exclusions")
	var animation_entries: Array = manifest.get("animation_entries", [])
	for animation in ["warrior_armed_idle", "warrior_armed_walk", "skeleton_default_walk", "skeleton_special_death"]:
		if not animation_entries.has(animation): errors.append("animation missing: %s" % animation)
	for animation in animation_entries:
		var directions: Dictionary = {}
		for row: Dictionary in rows:
			if str(row.get("animation_name", "")) == animation: directions[str(row.get("direction", ""))] = true
		if directions.size() != 16: errors.append("animation %s has %d/16 directions" % [animation, directions.size()])
	if level.find_child("Operator", true, false) != null: errors.append("production level owns an Operator")
	if level.find_child("Camera2D", true, false) != null: errors.append("production level owns a camera")
	if level.find_child("PlayerController", true, false) != null: errors.append("production level owns a PlayerController")
	if level.get_node_or_null("Collision/PathBoundaryCollision") == null: errors.append("boundary root missing")
	if not level.has_method("has_spawn") or not bool(level.call("has_spawn", &"Spawn_Main")): errors.append("named spawn missing")
	if level.get_node_or_null("Exits/ReturnWorld") is not InteractableLevelExit2D: errors.append("return is not an InteractableLevelExit2D")
	if level.get_node_or_null("PropsRoot/dev_lop_glint_glint") == null: errors.append("Glint display missing")
	if level.get_node_or_null("PropsRoot/dev_lop_gold_drop_idle_s") == null: errors.append("Gold Drop display missing")
	if level.get_node_or_null("GalleryInstructions/dev_lop_highlight") == null: errors.append("Highlight UI sample missing")
	if level.get_node_or_null("GalleryInstructions/dev_lop_loot_indicator") == null: errors.append("Loot Indicator UI sample missing")
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/levels/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery.json"))
	if str(definition.get("ingress", {}).get("site_scene_path", "")).is_empty(): errors.append("custom registered ingress presentation missing")
	var ingress_pack := load(definition.ingress.site_scene_path) as PackedScene
	if ingress_pack == null:
		errors.append("ingress presentation scene missing")
	else:
		var ingress_site := ingress_pack.instantiate()
		if not ingress_site is WorldIngressSite: errors.append("ingress presentation must extend WorldIngressSite")
		ingress_site.free()
	var right := InputEventKey.new()
	right.pressed = true
	right.keycode = KEY_RIGHT
	var ordered_directions: Array[String] = ["nne", "ne", "nee", "e", "see", "se", "sse", "s", "ssw", "sw", "sww", "w", "nww", "nw", "nnw", "n"]
	for step in range(16):
		level.call("_unhandled_input", right)
		var direction: String = ordered_directions[step]
		var warrior_sprite := level.get_node_or_null("PlayableRoot/WARRIORDisplay/ActorSprite") as AnimatedSprite2D
		var frame := warrior_sprite.sprite_frames.get_frame_texture("sample", 0) as AtlasTexture if warrior_sprite != null else null
		if frame == null or frame.atlas.resource_path != _runtime_path(rows, "dev_lop_warrior", "armed_idle_%s" % direction):
			errors.append("Warrior direction selector failed at %s" % direction)
			break
	var down := InputEventKey.new()
	down.pressed = true
	down.keycode = KEY_DOWN
	level.call("_unhandled_input", down)
	var walking := level.get_node_or_null("PlayableRoot/WARRIORDisplay/ActorSprite") as AnimatedSprite2D
	var walking_frame := walking.sprite_frames.get_frame_texture("sample", 0) as AtlasTexture if walking != null else null
	if walking_frame == null or walking_frame.atlas.resource_path != _runtime_path(rows, "dev_lop_warrior", "armed_walk_n"):
		errors.append("Warrior animation selector did not choose armed_walk")
	var skeleton := level.get_node_or_null("PlayableRoot/SKELETONDisplay/ActorSprite") as AnimatedSprite2D
	var skeleton_frame := skeleton.sprite_frames.get_frame_texture("sample", 0) as AtlasTexture if skeleton != null else null
	if skeleton_frame == null or skeleton_frame.atlas.resource_path != _runtime_path(rows, "dev_lop_skeleton", "special_death_n"):
		errors.append("Skeleton animation selector did not choose special_death")
	var gold := level.get_node_or_null("PropsRoot/dev_lop_gold_drop_idle_s") as AnimatedSprite2D
	if gold != null:
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = KEY_E
		level.call("_unhandled_input", event)
		if gold.visible: errors.append("Gold Drop collect control did not hide sample")
		level.call("_unhandled_input", event)
		if not gold.visible: errors.append("Gold Drop reset did not restore sample")
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "lords_of_pain_gallery", &"gameplay", &"Spawn_Main")
	var loader: Node = fixture.loader
	loader.set("_registry", null)
	loader.registry_index_path = "res://content/levels/levels.json"
	var ingress: Node = fixture.ingress
	ingress.call("configure_level", &"lords_of_pain_test_gallery", fixture.procgen)
	if loader.call("get_definition", &"lords_of_pain_test_gallery") == null:
		errors.append("real gallery definition is unavailable to the lifecycle loader")
	var actor: Node2D = fixture.actor
	var origin_position := actor.global_position
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	await process_frame
	var first_level: Node = loader.call("get_active_level_instance") as Node
	if first_level == null:
		errors.append("registered ingress failed to enter the gallery")
	else:
		if first_level.name != "LordsOfPainTestGallery": errors.append("ingress loaded the wrong destination scene")
		first_level.call("return_to_main", actor)
		await process_frame
		if not actor.global_position.is_equal_approx(origin_position): errors.append("gallery return did not restore the procgen origin")
		if loader.call("get_active_level_instance") != null: errors.append("gallery return retained an active level")
		if bool(ingress.call("is_triggered")): errors.append("gallery return left ingress locked")
		if fixture.actor != actor or fixture.camera.get_parent() != fixture.world: errors.append("gallery lifecycle replaced or detached the persistent Operator/camera")
		ingress.set("_triggered", true)
		ingress.call("_enter_approach", actor)
		await process_frame
		var second_level: Node = loader.call("get_active_level_instance") as Node
		if second_level == null: errors.append("procgen re-entry did not activate the gallery")
		elif second_level == first_level: errors.append("reset-on-entry re-entry reused the prior gallery instance")
		if second_level != null:
			second_level.call("return_to_main", actor)
			await process_frame
	fixture.game_root.free()
	if errors.is_empty():
		print("[LordsOfPainTestGallerySmoke] PASS")
		level.free()
		quit(0)
	else:
		for error in errors: push_error(error)
		level.free()
		quit(1)


func _runtime_path(rows: Array, family_id: String, state_id: String) -> String:
	for row: Dictionary in rows:
		if str(row.get("family_id", "")) == family_id and str(row.get("state_id", "")) == state_id:
			return str(row.get("runtime_path", ""))
	return ""
