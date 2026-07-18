extends SceneTree

const ATMOSPHERE_SCENE := preload("res://game/world/lighting/world_atmosphere_2d.tscn")
const GAME_SCENE := preload("res://scenes/game.tscn")
const LIGHTING_PROFILE := preload("res://content/lighting/profiles/sundered_keep_exterior.tres")
const FOLIAGE_SHADER := preload("res://game/world/procgen/foliage_life.gdshader")
const FOLIAGE_SPAWNER_SCRIPT := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")
const PROCGEN_TILEMAP_SCRIPT := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const PROCEDURAL_PROP_SCENE := preload("res://content/props/ruins/scenes/ProceduralProp.tscn")
const PORTAL_DEFINITION := preload("res://content/props/ruins/data/prop_definitions/portal_ring_01.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "AtmosphereSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root

	var world := Node2D.new()
	world.name = "World"
	scene_root.add_child(world)
	var canvas_modulate := CanvasModulate.new()
	canvas_modulate.name = "CanvasModulate"
	world.add_child(canvas_modulate)
	var directional_light := DirectionalLight2D.new()
	directional_light.name = "DirectionalLight2D"
	world.add_child(directional_light)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	var director := WorldLightingDirector.new()
	director.name = "WorldLightingDirector"
	director.canvas_modulate_path = NodePath("../CanvasModulate")
	director.directional_light_path = NodePath("../DirectionalLight2D")
	director.default_profile = LIGHTING_PROFILE
	world.add_child(director)

	var atmosphere := ATMOSPHERE_SCENE.instantiate() as WorldAtmosphere2D
	scene_root.add_child(atmosphere)
	await process_frame

	assert(atmosphere != null, "WorldAtmosphere2D did not instantiate.")
	assert(atmosphere.post_process != null, "WorldAtmosphere2D is missing PostProcess.")
	var atmosphere_material := atmosphere.get_atmosphere_material()
	assert(atmosphere_material != null, "PostProcess did not retain a ShaderMaterial.")
	var atmosphere_uniforms := _uniform_names(atmosphere_material.shader)
	for uniform_name in [
		"viewport_size",
		"camera_world_position",
		"camera_zoom",
		"grade_tint",
		"fog_color",
		"fog_alpha",
		"cosmic_alpha",
		"vignette_strength",
		"grain_strength",
	]:
		assert(atmosphere_uniforms.has(uniform_name), "Atmosphere shader missing uniform: %s" % uniform_name)
	assert(director.canvas_modulate == canvas_modulate, "WorldLightingDirector did not resolve CanvasModulate.")
	assert(director.directional_light == directional_light, "WorldLightingDirector did not resolve DirectionalLight2D.")
	assert(is_equal_approx(float(atmosphere_material.get_shader_parameter("fog_alpha")), director.fog_alpha), "Director fog_alpha did not reach atmosphere material.")
	director.apply_world_profile_overrides({
		"fog_alpha": 0.16,
		"cosmic_underlay_alpha": 0.04,
	}, true)
	await process_frame
	assert(is_equal_approx(float(atmosphere_material.get_shader_parameter("fog_alpha")), 0.16), "Planet fog override did not reach atmosphere material.")
	assert(is_equal_approx(float(atmosphere_material.get_shader_parameter("cosmic_alpha")), 0.04), "Planet cosmic override did not reach atmosphere material.")

	var foliage_parent := Node2D.new()
	foliage_parent.name = "FoliageLayer"
	world.add_child(foliage_parent)
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var foliage_nodes: Dictionary = {}
	var spawner := FOLIAGE_SPAWNER_SCRIPT.new()
	var placed: bool = spawner.call("_place_foliage", {
		"foliage_parent": foliage_parent,
		"foliage_nodes": foliage_nodes,
		"foliage_textures": [texture],
		"tile_noise_hash": Callable(self, "_tile_hash"),
		"tile_to_world_position": Callable(self, "_tile_to_world"),
		"get_planet_profile_color": Callable(self, "_profile_color"),
		"enable_fruit_spawning": false,
		"foliage_probabilistic_tree_collision": false,
		"foliage_wind_enabled": true,
		"foliage_wind_speed": 1.1,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
	}, Vector2i(4, 7))
	assert(placed and foliage_nodes.has(Vector2i(4, 7)), "Foliage spawner did not create smoke foliage.")
	var foliage_sprite := foliage_nodes[Vector2i(4, 7)].get("node") as Sprite2D
	var foliage_material := foliage_sprite.material as ShaderMaterial
	assert(foliage_material != null and foliage_material.shader == FOLIAGE_SHADER, "Generated foliage did not use foliage_life shader.")
	var foliage_uniforms := _uniform_names(foliage_material.shader)
	for uniform_name in [
		"wind_enabled", "wind_strength_px", "wind_speed", "wind_phase", "gust_amount", "top_flex_power",
		"bubble_enabled", "bubble_center", "bubble_count", "bubble_radius", "bubble_softness", "bubble_alpha",
		"bubble_center_0", "bubble_center_1", "bubble_center_2", "bubble_center_3",
		"bubble_center_4", "bubble_center_5", "bubble_center_6", "bubble_center_7",
	]:
		assert(foliage_uniforms.has(uniform_name), "Foliage-life shader missing uniform: %s" % uniform_name)
	assert(is_equal_approx(float(foliage_material.get_shader_parameter("wind_speed")), 1.1))
	var foliage_kind := str((foliage_nodes[Vector2i(4, 7)] as Dictionary).get("kind", "shrub"))
	var expected_wind_strength := 1.35 if foliage_kind == "tree" else 0.70
	assert(is_equal_approx(float(foliage_material.get_shader_parameter("wind_strength_px")), expected_wind_strength))
	assert(is_equal_approx(float(foliage_material.get_shader_parameter("gust_amount")), 0.42))

	var live_game := GAME_SCENE.instantiate()
	var live_atmosphere := live_game.get_node_or_null("WorldAtmosphere2D") as CanvasLayer
	var live_ui := live_game.get_node_or_null("UI") as CanvasLayer
	assert(live_game.get_node_or_null("World/CanvasModulate") is CanvasModulate)
	assert(live_game.get_node_or_null("World/DirectionalLight2D") is DirectionalLight2D)
	assert(live_game.get_node_or_null("World/WorldLightingDirector") is WorldLightingDirector)
	assert(live_game.get_node_or_null("World/CommandTerminal/TerminalLightRig") is LightRig2D)
	assert(live_game.get_node_or_null("World/Sectors/POWER/PowerNodeLightRig") is LightRig2D)
	var power_sector := live_game.get_node("World/Sectors/POWER")
	assert(power_sector.get("size_tiles") == Vector2i(28, 26), "Power-sector dimensions were displaced onto its light rig.")
	assert(live_atmosphere != null and live_ui != null and live_ui.layer > live_atmosphere.layer, "Live UI must render above atmosphere pass.")
	var live_ui_layer := live_ui.layer
	live_game.free()

	var portal_prop := PROCEDURAL_PROP_SCENE.instantiate() as ProceduralProp
	portal_prop.definition = PORTAL_DEFINITION
	var procgen_host := PROCGEN_TILEMAP_SCRIPT.new()
	procgen_host.call("_attach_portal_light_rig", portal_prop, PORTAL_DEFINITION)
	var portal_light := portal_prop.get_node_or_null("PortalLightRig") as LightRig2D
	assert(portal_light != null and portal_light.pulse_enabled, "Generated portal did not receive its pulsing light rig.")
	assert(portal_light.position.is_equal_approx(PORTAL_DEFINITION.portal_platform_trigger_offset), "Portal light did not use the authored platform trigger offset.")
	portal_prop.free()
	procgen_host.free()

	print("[WorldAtmosphereSmoke] ok fog=%.2f foliage_uniforms=%d ui_layer=%d" % [
		director.fog_alpha,
		foliage_uniforms.size(),
		live_ui_layer,
	])
	quit(0)


func _uniform_names(shader: Shader) -> Array[String]:
	var names: Array[String] = []
	if shader == null:
		return names
	for entry_variant in shader.get_shader_uniform_list():
		var entry := entry_variant as Dictionary
		names.append(str(entry.get("name", "")))
	return names


func _tile_hash(pos: Vector2i) -> int:
	return absi(pos.x * 73856093 ^ pos.y * 19349663)


func _tile_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos * 16)


func _profile_color(_key: String, fallback: Color) -> Color:
	return fallback
