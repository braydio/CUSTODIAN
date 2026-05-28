extends SceneTree

const EXPECTED_KINDS := {
	"blackwood_deadfall": true,
	"alloy_vein": true,
	"machine_wreckage": true,
}

const RESOURCE_NODE_SCENE := preload("res://game/resources/resource_node.tscn")

const EXPECTED_VISUAL_KINDS := {
	"blackwood_deadfall": "blackwood",
	"alloy_vein": "structural_alloy",
	"machine_wreckage": "ruin_scrap",
	"fungal_resin_pod": "resin_clot",
	"ruptured_capacitor_bank": "capacitor_dust",
	"broken_signal_relay": "signal_filament",
	"shattered_archive_terminal": "memory_glass_fragment",
}

const EXPECTED_EXPEDITION_MIN_COUNT := 7


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
	for node in nodes:
		if not _node_has_runtime_sprites(node):
			push_error("[ResourceNodeSmoke] Generated node missing runtime sprites: %s" % node.name)
			quit(3)
			return
	var expedition_nodes := get_nodes_in_group("generated_expedition_resource_node")
	var expedition_kinds := {}
	for node in expedition_nodes:
		if "node_kind" in node:
			expedition_kinds[String(node.get("node_kind"))] = true
		if not _node_has_runtime_sprites(node):
			push_error("[ResourceNodeSmoke] Expedition node missing runtime sprites: %s" % node.name)
			quit(4)
			return
	print("[ResourceNodeSmoke] expedition=%d kinds=%s" % [expedition_nodes.size(), expedition_kinds.keys()])
	if expedition_nodes.size() < EXPECTED_EXPEDITION_MIN_COUNT:
		push_error("[ResourceNodeSmoke] Expected at least %d expedition resource nodes" % EXPECTED_EXPEDITION_MIN_COUNT)
		quit(5)
		return
	for expected_kind in EXPECTED_VISUAL_KINDS.keys():
		if not expedition_kinds.has(expected_kind):
			push_error("[ResourceNodeSmoke] Missing expedition resource node kind: %s" % expected_kind)
			quit(6)
			return
	for visual_kind in EXPECTED_VISUAL_KINDS.keys():
		var probe := RESOURCE_NODE_SCENE.instantiate()
		probe.set("node_kind", visual_kind)
		probe.set("resource_id", EXPECTED_VISUAL_KINDS[visual_kind])
		root.add_child(probe)
		await process_frame
		if not _node_has_runtime_sprites(probe):
			push_error("[ResourceNodeSmoke] Default visual preset failed for: %s" % visual_kind)
			quit(7)
			return
		probe.queue_free()
	quit(0)


func _node_has_runtime_sprites(node: Node) -> bool:
	var sprite := node.get_node_or_null("NodeSprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return false
	if not sprite.sprite_frames.has_animation("idle"):
		return false
	if not sprite.sprite_frames.has_animation("depleted"):
		return false
	return sprite.sprite_frames.get_frame_count("idle") > 0 and sprite.sprite_frames.get_frame_count("depleted") > 0
