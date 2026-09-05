extends SceneTree

const ENVIRONMENT := preload("res://game/world/environment/world_environment_director.gd")
const LIGHTING := preload("res://game/world/lighting/world_lighting_director.gd")
const PROFILE := preload("res://game/world/lighting/lighting_profile.gd")
const PROCGEN_MAP := preload("res://game/world/procgen/proc_gen_tilemap.gd")
const FOLIAGE_SPAWNER := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")

class TestEnvironmentProvider:
	extends Node
	var owned_rect := Rect2(Vector2(-32, -32), Vector2(64, 64))

	func get_environment_region_at_global(world_position: Vector2) -> Dictionary:
		if not owned_rect.has_point(world_position):
			return {}
		return {"contains":true,"indoor":true,"environment_exposure":0.10,"weather_exposure":0.0}

var _failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var contract := {"contract_seed":741,"map":{"map_seed":82},"world_profile":{"profile_seed":19,"day_start_hour_min":9.0,"day_start_hour_max":9.0,"weather_weights":{"clear":0.5,"overcast":0.5}}}
	var a := ENVIRONMENT.new(); var b := ENVIRONMENT.new()
	a.configure_from_contract(contract,null); b.configure_from_contract(contract,null)
	_require(a.debug_get_state() == b.debug_get_state(),"same contract produced different initial environment")
	a.debug_set_hour(9.0); a.advance_environment(60.0); _require(is_equal_approx(a.current_hour,10.0),"60 seconds did not advance one hour")
	a.debug_set_hour(9.0); a.advance_environment(1440.0); _require(is_equal_approx(a.current_hour,9.0),"day did not wrap")
	a.configure_from_contract(contract,null); b.configure_from_contract(contract,null)
	for _step in 300: a.advance_environment(1.0); b.advance_environment(1.0)
	_require(a.debug_get_state() == b.debug_get_state(),"deterministic weather sequence diverged")
	a.debug_force_weather("heavy_rain"); _require(float(a.get_presentation_state().precipitation_alpha) > 0.9,"rain presentation missing")
	_require(is_equal_approx(a._exposure_for_indoor(false),1.0),"exterior exposure was not full")
	_require(is_equal_approx(a._exposure_for_indoor(true),0.12),"interior exposure was not suppressed")
	a.set("_weather_exposure",0.12); _require(float(a.get_presentation_state().precipitation_alpha) <= 0.12,"indoor precipitation was not suppressed")
	var operator := Node2D.new(); operator.position = Vector2.ZERO; root.add_child(operator); root.add_child(a); a.operator = operator
	var provider := TestEnvironmentProvider.new(); root.add_child(provider); provider.add_to_group("environment_region_provider")
	await process_frame
	var region := a._resolve_environment_region(); _require(bool(region.contains),"provider region was not resolved"); _require(is_equal_approx(float(region.environment_exposure),0.10),"provider environment exposure was ignored"); _require(is_zero_approx(float(region.weather_exposure)),"provider weather exposure was ignored")
	var spawner := FOLIAGE_SPAWNER.new(); var materials := spawner.get_shared_materials(); materials["shrub"] = ShaderMaterial.new(); materials["tree"] = ShaderMaterial.new()
	var map := PROCGEN_MAP.new(); map.set("_foliage_spawner",spawner); map.set_environment_wind_multipliers(1.6,1.7)
	_require(materials.keys().size() == 2 and materials.has("shrub") and materials.has("tree"),"weather changed shared foliage material categories")
	var lighting := LIGHTING.new(); var profile := PROFILE.new(); profile.ambient_color = Color(0.5,0.5,0.5,1); lighting.apply_profile(profile,true)
	var before := lighting.resolved_ambient_color; lighting.set_environment_modifiers({"ambient_multiplier":Color(0.5,0.5,0.5,1)},{})
	_require(lighting.active_profile == profile,"environment replaced authored profile")
	_require(lighting.resolved_ambient_color != before,"day modifier did not affect composite")
	profile.environment_influence = 0.0; profile.weather_influence = 0.0; lighting.apply_profile(profile,true); lighting.set_environment_modifiers({"ambient_multiplier":Color.BLACK},{"ambient_multiplier":Color.BLACK})
	_require(lighting.resolved_ambient_color == profile.ambient_color,"zero-influence profile changed")
	if _failed: quit(1); return
	print("world_environment_smoke: PASS weather=%s" % a.debug_get_state().weather_current); map.free(); a.queue_free(); b.free(); lighting.free(); provider.queue_free(); operator.queue_free(); quit(0)

func _require(condition: bool, message: String) -> void:
	if condition: return
	_failed = true
	push_error("world_environment_smoke: " + message)
