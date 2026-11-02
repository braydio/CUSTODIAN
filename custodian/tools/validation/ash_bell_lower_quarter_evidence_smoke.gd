extends SceneTree

const LOWER := preload("res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn")
const WEST := preload("res://game/world/levels/authored/ash_bell/west_gate_works/west_gate_works.tscn")
const STATION := preload("res://game/world/levels/authored/ash_bell/station_ix/station_ix.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ids: Dictionary = {}
	for scene: PackedScene in [LOWER, WEST, STATION]:
		var level: Node = scene.instantiate()
		root.add_child(level)
		await process_frame
		for node in level.get_tree().get_nodes_in_group("interactable"):
			if node is WorldEvidenceInteractable2D and level.is_ancestor_of(node):
				assert(not ids.has(node.evidence_id), "duplicate evidence id %s" % node.evidence_id)
				ids[node.evidence_id] = true
		if level is AshBellWestGateWorks:
			var record := level.get_node("POIRoot/WestGateClosureOrder") as WorldEvidenceInteractable2D
			record.interact(null)
			assert(level.debug_is_closure_archive_read())
			var restored := WEST.instantiate() as AshBellWestGateWorks
			root.add_child(restored)
			await process_frame
			assert(restored.restore_route_state(level.capture_route_state()))
			assert(restored.debug_is_closure_archive_read())
			restored.free()
		if level is AshBellStationIX:
			var state := {"assembly_a_repaired": true, "assembly_b_repaired": true, "assembly_c_repaired": true, "station_isolated": true}
			assert(level.restore_route_state(state))
			var record := level.get_node("POIRoot/NinthAnswerAfterAction") as WorldEvidenceInteractable2D
			record.interact(null)
			assert(level.debug_is_answer_archive_recovered())
		level.free()
		await process_frame
	assert(ids.size() == 10)
	print("ash_bell_lower_quarter_evidence_smoke: PASS evidence=%d" % ids.size())
	quit(0)
