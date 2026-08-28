extends SceneTree

const NativeProp := preload("res://game/world/levels/presentation/semantic_native_prop_2d.gd")
const MANIFEST := "res://content/metadata/assets/meridian_civic_props_native.semantic.json"

const REPRESENTATIVES := [
	[&"meridian_civic_lighting", &"lantern_standard_a"],
	[&"meridian_civic_lighting", &"lantern_standard_amber"],
	[&"meridian_civic_bench", &"bench_wood_short"],
	[&"meridian_civic_utility", &"cabinet_tall_closed"],
	[&"meridian_civic_basin", &"octagonal_jet_fountain"],
	[&"meridian_civic_planter", &"planter_rect_small_a"],
	[&"meridian_civic_floor_hardware", &"rect_grate_large"],
	[&"meridian_civic_traffic_control", &"concrete_barrier_striped"],
	[&"meridian_civic_crate", &"cargo_crate_long"],
	[&"meridian_civic_debris", &"rubble_pile_a"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for contract: Array in REPRESENTATIVES:
		var prop := NativeProp.new() as SemanticNativeProp2D
		root.add_child(prop)
		assert(prop.configure(contract[0], contract[1]))
		assert(prop.runtime_family == contract[0])
		assert(prop.variant_key == contract[1])
		assert(prop.get_sprite() != null)
		assert(prop.get_sprite().scale == Vector2.ONE)
		assert(Vector2i(prop.get_sprite().texture.get_size()) == Vector2i(prop.metadata.crop_size[0], prop.metadata.crop_size[1]))
		assert(prop.native_size == Vector2i(prop.metadata.native_size[0], prop.metadata.native_size[1]))
		assert(prop.get_sprite().get_meta(&"collision_is_authoritative") == false)
		assert(prop.get_node_or_null("CollisionShape2D") == null)
		prop.free()

	var floor_overlay := NativeProp.new() as SemanticNativeProp2D
	root.add_child(floor_overlay)
	assert(floor_overlay.configure(&"meridian_civic_floor_hardware", &"rect_grate_large"))
	assert(floor_overlay.anchor_mode == &"floor_center")
	assert(floor_overlay.role == &"floor_overlay")
	assert(floor_overlay.collision_profile == &"none")
	assert(not floor_overlay.uses_y_sort and floor_overlay.z_index == -1)
	floor_overlay.free()

	for variant in [&"utility_rubble_compound", &"compound_salvage_cluster", &"compound_masonry_cluster"]:
		assert(not NativeProp.can_spawn_production(MANIFEST, &"meridian_civic_debris", variant))
		var blocked := NativeProp.new() as SemanticNativeProp2D
		root.add_child(blocked)
		assert(not blocked.configure(&"meridian_civic_debris", variant))
		assert(blocked.get_sprite() == null)
		blocked.free()

	print("meridian_civic_native_prop_smoke: PASS representatives=10 review_blocked=3")
	quit(0)
