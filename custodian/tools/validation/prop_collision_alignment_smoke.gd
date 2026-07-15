extends SceneTree

const PROP_SCENE := preload("res://content/props/ruins/scenes/ProceduralProp.tscn")
const DEFINITIONS_DIR := "res://content/props/ruins/data/prop_definitions"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var audited := 0
	var collision_definitions := 0
	var files := DirAccess.get_files_at(DEFINITIONS_DIR)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		var resource_path := "%s/%s" % [DEFINITIONS_DIR, file_name]
		var definition := load(resource_path) as PropDefinition
		if definition == null:
			push_warning("[PropCollisionAlignmentSmoke] MISSING/INVALID definition: %s" % resource_path)
			continue
		audited += 1
		if definition.base_texture == null:
			push_warning("[PropCollisionAlignmentSmoke] MISSING base texture (non-blocking): %s" % resource_path)

		var prop := PROP_SCENE.instantiate() as ProceduralProp
		prop.definition = definition
		prop.generate_on_ready = false
		prop.force_collision_debug = true
		root.add_child(prop)
		prop.global_position = Vector2(160, 96)
		prop.generate_variant()
		var report := prop.get_collision_alignment_report()

		if definition.collision_shape_size.x > 0.0 and definition.collision_shape_size.y > 0.0:
			collision_definitions += 1
			if float(report.get("collision_bottom_y", 0.0)) > 4.0 and not definition.collision_allows_below_anchor:
				failures.append("%s collision extends %.2fpx below contact anchor" % [
					definition.id,
					float(report.get("collision_bottom_y", 0.0)),
				])
			if bool(report.get("collision_outside_visual_bounds", false)):
				failures.append("%s collision falls outside visual rect: %s" % [definition.id, report])
			if definition.collision_shape_offset.y > 4.0:
				failures.append("%s has suspicious positive collision offset: %s" % [
					definition.id,
					definition.collision_shape_offset,
				])
			var debug_root := prop.get_node_or_null("CollisionDebugRoot") as Node2D
			if debug_root == null or not debug_root.visible or debug_root.get_child_count() == 0:
				failures.append("%s force_collision_debug did not build a visible overlay" % definition.id)

		var local_rect := prop.get_collision_rect_root_local()
		var global_rect := prop.get_collision_rect_global()
		if bool(report.get("has_collision", false)) and not global_rect.position.is_equal_approx(local_rect.position + prop.global_position):
			failures.append("%s global collision rect does not follow prop root" % definition.id)
		root.remove_child(prop)
		prop.free()

	if audited == 0:
		failures.append("No PropDefinition resources were audited")
	if collision_definitions == 0:
		failures.append("No inline collision definitions were audited")

	if not failures.is_empty():
		for failure in failures:
			push_error("[PropCollisionAlignmentSmoke] %s" % failure)
		quit(1)
		return

	print("[PropCollisionAlignmentSmoke] ok definitions=%d inline_collisions=%d" % [audited, collision_definitions])
	quit(0)
