extends SceneTree

const EXPECTED_KINDS := {
	"blackwood_deadfall": true,
	"alloy_vein": true,
	"machine_wreckage": true,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var error := change_scene_to_file("res://scenes/game.tscn")
	if error != OK:
		push_error("[ResourceNodeSmoke] Failed to load game scene: %d" % error)
		quit(1)
		return

	for _index in range(90):
		await process_frame

	var nodes := get_nodes_in_group("generated_tutorial_resource_node")
	var kinds := {}
	for node in nodes:
		if "node_kind" in node:
			kinds[String(node.get("node_kind"))] = true
	print("[ResourceNodeSmoke] generated=%d kinds=%s" % [nodes.size(), kinds.keys()])
	for expected_kind in EXPECTED_KINDS.keys():
		if not kinds.has(expected_kind):
			push_error("[ResourceNodeSmoke] Missing tutorial resource node kind: %s" % expected_kind)
			quit(2)
			return
	quit(0)
