extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const WORLD_ORIGIN_BRANCH_GROUP := &"world_origin_branch"
const REQUIRED_ORIGIN_BRANCHES := [
	"DebugDraw",
	"InspectorProbe",
	"NavigationDebug",
	"Sectors",
	"Enemies",
	"SpawnNodes",
	"Projectiles",
	"Allies",
	"Items",
	"ContractMap",
	"AmbientHostileCampEast",
	"AmbientHostileCampWest",
	"LightBuggy",
	"WallPlacer",
	"WallBuildSystem",
	"TurretPlacement",
	"TerminalDeployment",
	"DroneManager",
	"CommandTerminal",
	"FieldFabricatorMk1",
]
const PERSISTENT_WORLD_NODES := [
	"LevelLoader",
	"RouteTraversalManager",
	"CanvasModulate",
	"DirectionalLight2D",
	"WorldLightingDirector",
	"Operator",
	"PlayerController",
	"Camera2D",
]


func _init() -> void:
	var errors: Array[String] = []
	var state := GAME_SCENE.get_state()
	var direct_world_children: Dictionary = {}

	for index in range(state.get_node_count()):
		var node_path := String(state.get_node_path(index))
		var path_parts := node_path.split("/")
		var world_index := path_parts.find("World")
		if world_index < 0 or path_parts.size() != world_index + 2:
			continue
		var relative_path := path_parts[world_index + 1]
		var groups := state.get_node_groups(index)
		var classified := groups.has(WORLD_ORIGIN_BRANCH_GROUP)
		direct_world_children[relative_path] = classified

		var expected_origin := REQUIRED_ORIGIN_BRANCHES.has(relative_path)
		var expected_persistent := PERSISTENT_WORLD_NODES.has(relative_path)
		if not expected_origin and not expected_persistent:
			errors.append("unclassified direct World child lacks a contract: %s" % relative_path)
		if expected_origin and not classified:
			errors.append("%s is missing world_origin_branch" % relative_path)
		if expected_persistent and classified:
			errors.append("%s must remain persistent and unclassified" % relative_path)

		var instance := state.get_node_instance(index)
		if instance is PackedScene:
			var scene_path := (instance as PackedScene).resource_path
			if scene_path.contains("/approaches/sundered_keep/") \
			or scene_path.contains("/return_causeway/") \
			or scene_path.ends_with("/sundered_keep_map.tscn"):
				errors.append("route scene is pre-authored beneath World: %s" % scene_path)

	for branch_name in REQUIRED_ORIGIN_BRANCHES:
		if not direct_world_children.has(branch_name):
			errors.append("required base-world branch is missing: %s" % branch_name)
	for persistent_name in PERSISTENT_WORLD_NODES:
		if not direct_world_children.has(persistent_name):
			errors.append("required persistent World node is missing: %s" % persistent_name)

	for critical_name in ["Sectors", "Operator", "Camera2D", "LevelLoader", "RouteTraversalManager"]:
		if not direct_world_children.has(critical_name):
			errors.append("critical World child is missing: %s" % critical_name)
	if direct_world_children.get("Sectors", false) != true:
		errors.append("Sectors must be classified as world_origin_branch")
	for persistent_name in ["Operator", "Camera2D", "LevelLoader", "RouteTraversalManager"]:
		if direct_world_children.get(persistent_name, true) != false:
			errors.append("%s must remain outside world_origin_branch" % persistent_name)

	if errors.is_empty():
		print("[WorldOriginBranchContractSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[WorldOriginBranchContractSmoke] %s" % error)
	quit(1)
