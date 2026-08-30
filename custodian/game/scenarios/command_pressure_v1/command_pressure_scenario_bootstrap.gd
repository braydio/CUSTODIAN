extends Node
class_name CommandPressureScenarioBootstrap

const SCENARIO_ID := "command_pressure_v1"
const SCENARIO_SCENE := preload(
	"res://game/scenarios/command_pressure_v1/command_pressure_scenario_root.tscn"
)


static func requested_scenario_id(args: PackedStringArray = OS.get_cmdline_user_args()) -> String:
	for index in range(args.size()):
		var arg := String(args[index])
		if arg.begins_with("--scenario="):
			return arg.trim_prefix("--scenario=").strip_edges()
		if arg == "--scenario" and index + 1 < args.size():
			return String(args[index + 1]).strip_edges()
	return ""


func _ready() -> void:
	if requested_scenario_id() != SCENARIO_ID:
		return
	var game_root := get_parent()
	game_root.set_meta("command_pressure_scenario_active", true)
	_isolate_production_cadence(game_root)
	var scenario := SCENARIO_SCENE.instantiate()
	scenario.name = "CommandPressureScenarioRoot"
	game_root.add_child.call_deferred(scenario)


func _isolate_production_cadence(game_root: Node) -> void:
	var tutorial := game_root.get_node_or_null("CommandTerminalTutorial")
	if tutorial != null:
		tutorial.process_mode = Node.PROCESS_MODE_DISABLED
	var loader := game_root.get_node_or_null("ContractWorldLoader")
	if loader != null:
		loader.process_mode = Node.PROCESS_MODE_DISABLED
	var ambient_enemy := game_root.get_node_or_null("AmbientEnemySpawner")
	if ambient_enemy != null:
		ambient_enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var critters := game_root.get_node_or_null("AmbientCritterManager")
	if critters != null:
		critters.set("ambient_spawn_enabled", false)
		critters.process_mode = Node.PROCESS_MODE_DISABLED
	var drops := game_root.get_node_or_null("SupplyDropManager")
	if drops != null and drops.has_method("set_active"):
		drops.call("set_active", false)
	var waves := game_root.get_node_or_null("WaveManager")
	if waves != null:
		waves.set("automatic_cadence_enabled", false)
		waves.set("procedural_enemy_variants_enabled", false)
	var bootstrap := game_root.get_node_or_null("/root/WorldContractBootstrap")
	if bootstrap != null and bootstrap.has_method("reset"):
		bootstrap.call("reset")
