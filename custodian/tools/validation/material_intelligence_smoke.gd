extends SceneTree

const BULLET_SCENE := preload(
	"res://game/actors/projectiles/bullet.tscn"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var material_intelligence := root.get_node_or_null(
		"/root/MaterialIntelligence"
	)
	if material_intelligence == null:
		_fail("MaterialIntelligence autoload missing.")
		return

	for method_name in [
		"clear",
		"get_material_id_at",
		"get_material_at",
		"set_material_at",
		"set_material_cell",
		"report_contact",
		"get_summary",
	]:
		if not material_intelligence.has_method(method_name):
			_fail(
				"MaterialIntelligence missing required API: %s"
				% method_name
			)
			return

	var heatmap := root.get_node_or_null("/root/SectorHeatmap")
	var observatory := root.get_node_or_null("/root/DevObservatory")
	material_intelligence.call("clear")
	if heatmap != null and heatmap.has_method("clear"):
		heatmap.call("clear")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")

	var position := Vector2(128.0, 128.0)
	var before: Variant = material_intelligence.call(
		"get_material_id_at",
		position
	)
	if String(before) != "unknown":
		_fail("Default material should be unknown.")
		return

	material_intelligence.call(
		"set_material_at",
		position,
		&"metal_rusted"
	)
	var after: Variant = material_intelligence.call(
		"get_material_id_at",
		position
	)
	if String(after) != "metal_rusted":
		_fail("Material override failed.")
		return

	var profile: Variant = material_intelligence.call(
		"get_material_at",
		position
	)
	if (
		profile == null
		or String(profile.get("material_id")) != "metal_rusted"
		or float(profile.get("footstep_noise_mult")) <= 1.0
	):
		_fail("Material profile lookup did not return the rusted-metal profile.")
		return

	material_intelligence.call(
		"report_contact",
		position,
		&"bullet_impact",
		{"test": true}
	)
	var projectile_root := Node2D.new()
	projectile_root.name = "MaterialImpactFixture"
	root.add_child(projectile_root)
	var blocker := StaticBody2D.new()
	blocker.name = "MaterialImpactBlocker"
	projectile_root.add_child(blocker)
	var bullet := BULLET_SCENE.instantiate()
	projectile_root.add_child(bullet)
	bullet.call(
		"_handle_body_hit",
		blocker,
		position,
		Vector2.LEFT
	)

	var summary := material_intelligence.call("get_summary") as Dictionary
	if (
		String(summary.get("schema", ""))
		!= "custodian.material_intelligence.summary.v1"
	):
		_fail("MaterialIntelligence summary schema mismatch.")
		return
	if int(summary.get("override_cell_count", 0)) != 1:
		_fail("MaterialIntelligence summary did not count overrides.")
		return
	if int(summary.get("total_contacts", 0)) != 2:
		_fail("MaterialIntelligence summary did not count contacts.")
		return

	var contact_kinds := (
		summary.get("contact_counts_by_kind", {}) as Dictionary
	)
	if int(contact_kinds.get("bullet_impact", 0)) != 2:
		_fail("MaterialIntelligence did not aggregate contact kinds.")
		return

	if observatory == null:
		_fail("Developer Observatory autoload missing.")
		return
	var recent_events := observatory.call(
		"get_recent_events",
		10,
		&"material_contact"
	) as Array
	if recent_events.size() != 2:
		_fail("Material contact was not logged to Developer Observatory.")
		return

	if heatmap == null:
		_fail("SectorHeatmap autoload missing.")
		return
	if float(heatmap.call(
		"get_value",
		position,
		"material_bullet_impact"
	)) < 0.499:
		_fail("Material contact was not tagged in SectorHeatmap.")
		return

	var payload := observatory.call(
		"_build_export_payload",
		"user://material_intelligence_smoke.json"
	) as Dictionary
	var exported := payload.get("material_intelligence", {}) as Dictionary
	if int(exported.get("total_contacts", 0)) != 2:
		_fail("Observatory export omitted Material Intelligence summary.")
		return

	projectile_root.queue_free()
	await process_frame
	material_intelligence.call("clear")
	heatmap.call("clear")
	observatory.call("clear")
	print("MaterialIntelligence smoke passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
