extends SceneTree

const PROFILE := preload("res://game/world/procgen/presentation/underlays/drowned_basilica_underlay.tres")
const ENDLESS := preload("res://game/world/procgen/presentation/underlays/endless_forest_underlay.tres")
const BACKDROP := preload("res://game/world/procgen/presentation/procgen_depth_backdrop.gd")
const MAP := preload("res://game/world/procgen/proc_gen_map.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(PROFILE.is_valid())
	assert(PROFILE.validate_dimensions())
	assert(PROFILE.far_variants.size() == 2)
	assert(PROFILE.middle_variants.size() == 2)
	assert(PROFILE.near_variants.size() == 2)
	var first := BACKDROP.new() as ProcgenDepthBackdrop
	var second := BACKDROP.new() as ProcgenDepthBackdrop
	root.add_child(first); root.add_child(second)
	first.set_underlay_profile(PROFILE, 42)
	second.set_underlay_profile(PROFILE, 42)
	assert(first.get_selected_variant_indices() == second.get_selected_variant_indices())
	var differs := false
	for seed_value in range(43, 64):
		first.set_variant_seed(seed_value)
		if first.get_selected_variant_indices() != second.get_selected_variant_indices():
			differs = true
			break
	assert(differs)
	first.set_underlay_profile(PROFILE, 42)
	first.configure_from_chasm_cells([Vector2i(-2, -2), Vector2i(2, 2)])
	await process_frame
	assert(first.visible)
	var stack := first.get_node("ChasmPresentationRoot/CameraDepthBackdrop") as Node2D
	assert(stack.get_child_count() == 3)
	assert(stack.get_node("Far") is Sprite2D)
	assert(stack.get_node("Middle") is Sprite2D)
	assert(stack.get_node("Near") is Sprite2D)
	var old_far := stack.get_node("Far") as Sprite2D
	var old_middle := stack.get_node("Middle") as Sprite2D
	var old_near := stack.get_node("Near") as Sprite2D
	first.set_underlay_profile(ENDLESS, 42)
	assert(first.get_underlay_profile_id() == &"endless_forest")
	assert(old_far.texture == ENDLESS.far_variants[first.get_selected_variant_indices()["far"]])
	assert(old_middle.texture == ENDLESS.middle_variants[first.get_selected_variant_indices()["middle"]])
	assert(old_near.texture == ENDLESS.near_variants[first.get_selected_variant_indices()["near"]])
	assert(is_equal_approx(old_far.modulate.a, ENDLESS.far_alpha))
	assert(is_equal_approx(old_middle.modulate.a, ENDLESS.middle_alpha))
	assert(is_equal_approx(old_near.modulate.a, ENDLESS.near_alpha))
	assert(first.visible)
	assert(stack.get_child_count() == 3)
	assert(first.get_node("ChasmPresentationRoot/CameraDepthBackdrop/Far") == old_far)
	var map := MAP.instantiate()
	root.add_child(map)
	await process_frame
	var procgen := map.get_node("ProcGen2")
	procgen.seed = 271828
	var tilemap_count := map.get_node("NavigationRegion2D").get_child_count()
	var tilemap := map as ProcGenTilemap
	assert(tilemap.get_underlay_profile_override() == "DEFAULT")
	tilemap.set_underlay_profile_override("DROWNED_BASILICA")
	var map_backdrop := map.get_node("DepthBackdrop") as ProcgenDepthBackdrop
	var expected_seed_backdrop := BACKDROP.new() as ProcgenDepthBackdrop
	root.add_child(expected_seed_backdrop)
	expected_seed_backdrop.set_underlay_profile(PROFILE, 271828)
	assert(map_backdrop.variant_seed == 271828)
	assert(map_backdrop.get_underlay_profile_id() == &"drowned_basilica")
	assert(map_backdrop.get_selected_variant_indices() == expected_seed_backdrop.get_selected_variant_indices())
	assert(map.get_node("NavigationRegion2D").get_child_count() == tilemap_count)
	map_backdrop.configure_from_chasm_cells([Vector2i(-1, -1), Vector2i(1, 1)])
	await process_frame
	assert(map_backdrop.get_node_or_null("ChasmPresentationRoot/CameraDepthBackdrop/Far") != null)
	assert(map_backdrop.get_node("ChasmPresentationRoot/CameraDepthBackdrop").get_child_count() == 3)
	tilemap.set_underlay_profile_override("DEFAULT")
	assert(map_backdrop.get_underlay_profile_id() == &"endless_forest")
	assert(map.get_node("NavigationRegion2D").get_child_count() == tilemap_count)
	map.queue_free()
	expected_seed_backdrop.queue_free()
	assert(first.z_index == -300 and not first.z_as_relative)
	print("drowned_basilica_underlay_smoke: PASS profile=%s variants=%s" % [PROFILE.profile_id, first.get_selected_variant_indices()])
	quit(0)
