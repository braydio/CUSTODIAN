extends SceneTree

const ENTRYPOINT_SCRIPT := preload("res://game/app/boot/runtime_entrypoint.gd")
const STARTUP_MODE_SCRIPT := preload("res://game/app/boot/startup_mode.gd")
const PENDING_GENERATOR_SCRIPT := preload(
	"res://tools/validation/fixtures/pending_world_contract_map.gd"
)
const AWAKENING_CONNECTOR_IMPORT := "res://content/levels/awakening/04_05_connector/awakening_reliquary_dust_lung_connector_full_plate_underlay_1502x2048.png.import"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var bootstrap := root.get_node_or_null("WorldContractBootstrap")
	_assert(bootstrap != null, "WorldContractBootstrap autoload is missing")
	if bootstrap == null:
		quit(1)
		return
	bootstrap.call("reset")
	_assert_connector_import_metadata()
	_assert(
		ProjectSettings.get_setting("application/run/main_scene")
		== "res://game/app/boot/runtime_entrypoint.tscn",
		"project main scene must be the App/Boot runtime entrypoint"
	)
	_assert_mode([], "awakening", null, "")
	_assert_mode(["--custodian-start=awakening"], "awakening", null, "")
	_assert_mode(["--custodian-start=twin-solaria"], "twin-solaria", null, "")
	_assert_mode(["--custodian-start=contract-sandbox"], "contract-sandbox", null, "")
	_assert_mode(
		["--custodian-start=contract-sandbox", "--contract-seed=123456"],
		"contract-sandbox", 123456, ""
	)
	_assert_mode(["--custodian-start=unknown"], "awakening", null, "Unknown")
	_assert_mode(
		["--custodian-start=awakening", "--custodian-start=twin-solaria"],
		"awakening", null, "Duplicate"
	)
	_assert_mode(
		["--custodian-start=contract-sandbox", "--contract-seed=bad"],
		"awakening", null, "Malformed"
	)
	_assert_mode(
		["--custodian-start=contract-sandbox", "--contract-seed"],
		"awakening", null, "Malformed"
	)
	_assert_mode(
		["--custodian-start=contract-sandbox", "--contract-seed=12", "--contract-seed=13"],
		"awakening", null, "Duplicate"
	)
	_assert_mode(
		["--custodian-start=twin-solaria", "--contract-seed=12"],
		"awakening", null, "requires contract-sandbox"
	)
	_assert_mode(
		["--custodian-start=contract-sandbox", "--contract-seed=0"],
		"awakening", null, "nonzero"
	)

	_assert_route([], "res://scenes/awakening_first_return.tscn")
	_assert_route(["--custodian-start=awakening"], "res://scenes/awakening_first_return.tscn")
	_assert_route(["--custodian-start=twin-solaria"], "res://scenes/twin_solaria_playtest.tscn")
	_assert_route(["--custodian-start=contract-sandbox"], "res://scenes/game.tscn")
	_assert_route(["--custodian-start=invalid-scene-path"], "res://scenes/awakening_first_return.tscn")
	_assert(int(bootstrap.call("get_metrics").get("generation_count", 0)) == 0,
		"parsing and routing Awakening/Twin/invalid modes must not start Contract generation")
	var entrypoint_scene := load("res://game/app/boot/runtime_entrypoint.tscn") as PackedScene
	var router := entrypoint_scene.instantiate()
	router.set("start_on_ready", false)
	root.add_child(router)
	router.call("start", PackedStringArray())
	await _wait_for_scene("res://scenes/awakening_first_return.tscn")
	_assert_current_scene("res://scenes/awakening_first_return.tscn",
		"no-override boot must enter Awakening")
	_assert(int(bootstrap.call("get_metrics").get("generation_count", 0)) == 0,
		"default Awakening boot must leave generation count at zero")
	router.call("start", PackedStringArray(["--custodian-start=twin-solaria"]))
	await _wait_for_scene("res://scenes/twin_solaria_playtest.tscn")
	_assert_current_scene("res://scenes/twin_solaria_playtest.tscn",
		"Twin startup must load the existing playtest wrapper")
	router.call("start", PackedStringArray(["--custodian-start=invalid-scene-path"]))
	await _wait_for_scene("res://scenes/awakening_first_return.tscn")
	_assert_current_scene("res://scenes/awakening_first_return.tscn",
		"invalid mode must load Awakening")

	var level_definition := JSON.parse_string(
		FileAccess.get_file_as_string("res://content/levels/hub/twin_solaria_v1.json")
	) as Dictionary
	_assert(level_definition.get("target_scene_path") == "res://game/world/levels/authored/hub/twin_solaria/twin_solaria.tscn",
		"Twin mode must use the production registered Hub level")
	_assert((level_definition.get("spawns", []) as Array).has("Spawn_CrownCauseway"),
		"Twin production level must expose Crown Causeway spawn")
	_assert(not (level_definition.get("tags", []) as Array).has("world_ingress"),
		"Twin must not be registered as a procgen world ingress")

	bootstrap.call("set_generator_scene_for_testing", _build_pending_generator_scene())
	router.call("start", PackedStringArray([
		"--custodian-start=contract-sandbox",
		"--contract-seed=123456",
	]))
	await _wait_for_scene("res://scenes/game.tscn")
	_assert_current_scene("res://scenes/game.tscn",
		"Contract sandbox startup must load the existing game scene")
	for _frame in range(5):
		await process_frame
	var metrics := bootstrap.call("get_metrics") as Dictionary
	_assert(int(metrics.get("generation_count", 0)) == 1,
		"Contract startup must start exactly one bootstrap generation")
	_assert(int(metrics.get("run_seed", 0)) == 123456,
		"fixed seed must reach WorldContractBootstrap unchanged")
	var proxy := get_current_scene().get_node_or_null("World/ContractMap")
	_assert(proxy != null and proxy.get_script() == load(
		"res://game/world/procgen/world_contract_proxy.gd"
	), "game.tscn must keep using WorldContractProxy")
	_assert(int(bootstrap.call("get_state")) == 1,
		"game.tscn must load while the same bootstrap generation is in flight")
	_assert(int(bootstrap.call("get_metrics").get("generation_count", 0)) == 1,
		"seeded bootstrap must not start a duplicate generation")
	bootstrap.call("reset")
	bootstrap.call("restore_generator_scene")

	if failures.is_empty():
		print("startup_world_entry_smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("startup_world_entry_smoke: %s" % failure)
		quit(1)


func _assert_connector_import_metadata() -> void:
	var import_text := FileAccess.get_file_as_string(AWAKENING_CONNECTOR_IMPORT)
	_assert(not import_text.is_empty(), "Awakening 04→05 connector import metadata is missing")
	_assert(not import_text.contains("valid=false"),
		"Awakening 04→05 connector import metadata regressed to valid=false")
	_assert(import_text.contains("path=\"res://.godot/imported/"),
		"Awakening 04→05 connector import metadata is missing its imported texture path")
	_assert(import_text.contains("dest_files=["),
		"Awakening 04→05 connector import metadata is missing imported destination metadata")


func _assert_mode(args: PackedStringArray, expected_mode: String, expected_seed: Variant, warning_fragment: String) -> void:
	var decision := STARTUP_MODE_SCRIPT.parse_args(args) as Dictionary
	_assert(String(decision.get("mode", "")) == expected_mode,
		"args %s resolved to unexpected mode %s" % [str(args), str(decision.get("mode"))])
	_assert(decision.get("seed") == expected_seed,
		"args %s resolved to unexpected seed %s" % [str(args), str(decision.get("seed"))])
	var warning := String(decision.get("warning", ""))
	if warning_fragment.is_empty():
		_assert(warning.is_empty(), "valid args %s produced a warning: %s" % [str(args), warning])
	else:
		_assert(warning.contains(warning_fragment),
			"args %s warning did not contain %s" % [str(args), warning_fragment])


func _assert_route(args: PackedStringArray, expected_scene: String) -> void:
	var decision := STARTUP_MODE_SCRIPT.parse_args(args) as Dictionary
	var actual_scene := ENTRYPOINT_SCRIPT.scene_for_mode(String(decision.get("mode", "")))
	_assert(actual_scene == expected_scene,
		"args %s routed to %s instead of %s" % [str(args), actual_scene, expected_scene])


func _wait_for_scene(expected_path: String) -> void:
	for _frame in range(8):
		if get_current_scene() != null and get_current_scene().scene_file_path == expected_path:
			return
		await process_frame


func _assert_current_scene(expected_path: String, message: String) -> void:
	var current := get_current_scene()
	_assert(current != null and current.scene_file_path == expected_path,
		"%s (got %s)" % [message, current.scene_file_path if current != null else "<none>"])


func _build_pending_generator_scene() -> PackedScene:
	var generator := Node2D.new()
	generator.set_script(PENDING_GENERATOR_SCRIPT)
	var packed := PackedScene.new()
	_assert(packed.pack(generator) == OK, "could not pack fake Contract generator")
	return packed


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
