extends SceneTree

const CONTRACT_MAP_SCENE := preload("res://game/world/procgen/custodian_contract_map.tscn")
const CONTRACT_MAP_SCRIPT := preload("res://game/world/procgen/custodian_contract_map.gd")
const TERMINAL_PREVIEW_SCRIPT := preload("res://game/ui/terminal/terminal_planet_preview.gd")
const UI_SCRIPT := preload("res://game/ui/hud/ui.gd")

# Captured from the pre-removal generator at origin/main 0d41ea4. The ordered
# fixed-seed tuples pin the old sorted-library RNG draw sequence; the profile
# digest covers every nested value, including vectors, colors and arrays.
const PROFILE_BASELINE_SHA256 := "2dfd67fda56392aeeeb96e5a57dc5a94ffe624e3a43704fb6be990e538cbb234"
const EXPECTED_PLANET_KEYS := ["gas_giant", "ice_world", "islands", "lava_world", "terran_dry", "terran_wet"]
const EXPECTED_SEED_OUTPUTS := [
	[0, "terran_wet", 1327520283, 692503688],
	[1, "lava_world", 683407368, 2033395789],
	[7, "terran_wet", 3706616521, 2188350268],
	[42, "terran_wet", 1919685028, 3561993920],
	[12345, "islands", 17539747, 3348728241],
	[2026, "lava_world", 3407118278, 3458149024],
	[424242, "ice_world", 820756337, 4134149008],
]

class PlanetGlobeHarness extends Node:
	const UI_SCRIPT := preload("res://game/ui/hud/ui.gd")
	var material_builder: Node
	var last_planet_key := ""
	var last_planet_seed := -1

	func _init() -> void:
		material_builder = UI_SCRIPT.new()

	func _build_terminal_planet_globe_material(planet_key: String, planet_seed: int) -> Material:
		last_planet_key = planet_key
		last_planet_seed = planet_seed
		return material_builder.call("_build_terminal_planet_globe_material", planet_key, planet_seed) as Material

	func _exit_tree() -> void:
		if is_instance_valid(material_builder):
			material_builder.free()

class EdgarContractHarness extends CustodianContractMap:
	func _init_edgar_systems() -> void:
		pass

	func _generate_edgar_layout() -> Dictionary:
		return {"rooms": [{"fixture": "valid_layout"}], "room_count": 1}

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_deterministic_planet_identity_and_profiles()
	_test_legacy_resources_are_absent()
	await _test_contract_and_terminal_globe_without_legacy_art()
	if _errors.is_empty():
		print("[PlanetContractRetirementSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[PlanetContractRetirementSmoke] %s" % error)
	quit(1)


func _test_deterministic_planet_identity_and_profiles() -> void:
	var profiles: Dictionary = CONTRACT_MAP_SCRIPT.PLANET_WORLD_PROFILES
	var keys: Array = profiles.keys()
	keys.sort()
	_check(keys == EXPECTED_PLANET_KEYS, "planet key set/order changed from the pre-removal sorted library")

	var profile_json := JSON.stringify(_normalize(profiles), "", true, true)
	var profile_hash := HashingContext.new()
	profile_hash.start(HashingContext.HASH_SHA256)
	profile_hash.update(profile_json.to_utf8_buffer())
	_check(
		profile_hash.finish().hex_encode() == PROFILE_BASELINE_SHA256,
		"one or more PLANET_WORLD_PROFILES values differ from the pre-removal baseline"
	)

	var contract_map := CONTRACT_MAP_SCRIPT.new() as CustodianContractMap
	for row in EXPECTED_SEED_OUTPUTS:
		var seed := int(row[0])
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var planet_key := contract_map._pick_planet_key(rng)
		var planet_seed := int(rng.randi())
		var map_seed := int(rng.randi())
		_check(
			planet_key == String(row[1])
				and planet_seed == int(row[2])
				and map_seed == int(row[3]),
			"planet key/planet seed/map seed changed for contract seed %d" % seed
		)
	contract_map.free()


func _test_legacy_resources_are_absent() -> void:
	var project_planets_path := ProjectSettings.globalize_path("res://Planets")
	_check(not DirAccess.dir_exists_absolute(project_planets_path), "the legacy Planets resource directory is still present")
	_check(not ResourceLoader.exists("res://Planets/Rivers/Rivers.tscn"), "the legacy terran_wet scene still resolves")
	var runtime_source := FileAccess.get_file_as_string("res://game/world/procgen/custodian_contract_map.gd")
	_check(not runtime_source.contains("res://Planets/"), "CustodianContractMap still contains a legacy scene path")
	_check(not runtime_source.contains("PLANET_LIBRARY"), "CustodianContractMap still has a duplicate legacy planet registry")
	_check(not runtime_source.contains("_instantiate_contracted_planet"), "legacy planet instantiation remains in CustodianContractMap")
	_check(not runtime_source.contains("_get_planet_scene_path"), "legacy scene-path lookup remains in CustodianContractMap")

	var scene := CONTRACT_MAP_SCENE.instantiate()
	_check(scene.get_node_or_null("PlanetRoot") == null, "contract scene still contains an unused PlanetRoot")
	_check(scene.get_node_or_null("MapRoot") != null, "contract scene lost the active MapRoot")
	scene.free()


func _test_contract_and_terminal_globe_without_legacy_art() -> void:
	var contract_map := CONTRACT_MAP_SCENE.instantiate() as CustodianContractMap
	contract_map.auto_generate_on_ready = false
	root.add_child(contract_map)
	await process_frame
	contract_map.generate_contract(424242)
	var frames := 0
	while contract_map.get_latest_contract().is_empty() and frames < 1800:
		frames += 1
		await process_frame

	var contract: Dictionary = contract_map.get_latest_contract()
	_check(not contract.is_empty(), "contract generation failed while PixelPlanets resources are absent")
	if contract.is_empty():
		contract_map.queue_free()
		await process_frame
		return

	var planet: Dictionary = contract.get("planet", {})
	var world_profile: Dictionary = contract.get("world_profile", {})
	var map: Dictionary = contract.get("map", {})
	_check(int(contract.get("contract_seed", -1)) == 424242, "contract seed changed")
	_check(String(planet.get("key", "")) == "ice_world", "fixed-seed planet identity changed")
	_check(int(planet.get("planet_seed", -1)) == 820756337, "fixed-seed planet seed changed")
	_check(int(map.get("map_seed", -1)) == 4134149008, "fixed-seed map seed changed")
	_check(planet.get("world_profile", {}) == world_profile, "planet and top-level world profiles diverged")
	_check(not planet.has("scene_path") and not planet.has("instance"), "contract still advertises the retired scene or instance")

	var edgar_map := EdgarContractHarness.new()
	edgar_map.auto_generate_on_ready = false
	var edgar_map_root := Node2D.new()
	edgar_map_root.name = "MapRoot"
	edgar_map.add_child(edgar_map_root)
	root.add_child(edgar_map)
	await process_frame
	var edgar_contract: Dictionary = await edgar_map.generate_edgar_contract(424242)
	var edgar_planet: Dictionary = edgar_contract.get("planet", {})
	_check(not edgar_contract.is_empty(), "Edgar contract generation failed without PixelPlanets resources")
	_check(String(edgar_planet.get("key", "")) == "ice_world", "Edgar contract planet identity changed")
	_check(int(edgar_planet.get("planet_seed", -1)) == 820756337, "Edgar contract planet seed changed")
	_check(not edgar_planet.has("scene_path") and not edgar_planet.has("instance"), "Edgar contract still advertises the retired scene or instance")
	edgar_map.queue_free()

	var harness := PlanetGlobeHarness.new()
	root.add_child(harness)
	var target := TextureRect.new()
	harness.add_child(target)
	var terminal_preview := TERMINAL_PREVIEW_SCRIPT.new() as TerminalPlanetPreview
	terminal_preview.init(harness, target)
	terminal_preview.render(harness, target, contract)
	await process_frame
	_check(harness.last_planet_key == String(planet.get("key", "")), "terminal globe did not receive the contract planet key")
	_check(harness.last_planet_seed == int(planet.get("planet_seed", -1)), "terminal globe did not receive the contract planet seed")
	_check(terminal_preview.globe != null and terminal_preview.globe.mesh is SphereMesh, "terminal globe sphere was not built")
	var material := terminal_preview.globe.material_override as StandardMaterial3D if terminal_preview.globe != null else null
	_check(material != null and material.albedo_texture != null, "terminal globe did not receive its seeded material texture")
	if material != null and material.albedo_texture is ImageTexture:
		var image := (material.albedo_texture as ImageTexture).get_image()
		_check(image.get_size() == Vector2i(1024, 512), "terminal globe texture dimensions changed")
	terminal_preview = null
	harness.queue_free()
	contract_map.queue_free()
	await process_frame


func _normalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var normalized := {}
			var keys: Array = value.keys()
			keys.sort()
			for key in keys:
				normalized[str(key)] = _normalize(value[key])
			return normalized
		TYPE_ARRAY:
			var normalized_array: Array = []
			for item in value:
				normalized_array.append(_normalize(item))
			return normalized_array
		TYPE_VECTOR2I:
			return ["Vector2i", value.x, value.y]
		TYPE_COLOR:
			return ["Color", value.r, value.g, value.b, value.a]
		_:
			return value


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
