extends SceneTree

const PROFILE := preload("res://game/world/procgen/presentation/underlays/drowned_basilica_underlay.tres")
const BACKDROP := preload("res://game/world/procgen/presentation/procgen_depth_backdrop.gd")

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
	first.configure_from_chasm_cells([Vector2i(-2, -2), Vector2i(2, 2)])
	await process_frame
	assert(first.visible)
	assert(first.get_node("ChasmPresentationRoot/CameraDepthBackdrop").get_child_count() == 3)
	assert(first.z_index == -300 and not first.z_as_relative)
	print("drowned_basilica_underlay_smoke: PASS profile=%s variants=%s" % [PROFILE.profile_id, first.get_selected_variant_indices()])
	quit(0)
