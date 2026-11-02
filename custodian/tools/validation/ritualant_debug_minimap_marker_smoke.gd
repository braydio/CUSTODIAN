extends SceneTree

const SITE_SCRIPT := preload("res://game/world/approaches/ash_bell/ash_bell_lift_ingress_site.gd")
const CONTROLLER_SCRIPT := preload("res://game/ui/minimap/minimap_controller.gd")
const VIEW_SCRIPT := preload("res://game/ui/minimap/minimap_view.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node.new()
	root.add_child(host)
	var view := VIEW_SCRIPT.new()
	view.name = "MinimapView"
	view.set_level_data({"map_size": Vector2i(16, 16), "tile_size": Vector2(32, 32)})
	var controller := CONTROLLER_SCRIPT.new()
	controller.minimap_view_path = NodePath("MinimapView")
	controller.add_child(view)
	host.add_child(controller)
	var marker := Node2D.new()
	marker.global_position = Vector2(96, 128)
	marker.add_to_group("debug_minimap_ritualant_ingress")
	host.add_child(marker)
	controller.call("_refresh_dynamic_nodes")
	if OS.is_debug_build():
		assert((view.debug_marker_nodes as Array).has(marker))
		assert(String(view.call("_get_dynamic_signature")).contains("d:"))
	else:
		assert((view.debug_marker_nodes as Array).is_empty())
	var source := FileAccess.get_file_as_string("res://game/world/approaches/ash_bell/ash_bell_lift_ingress_site.gd")
	assert(source.contains("super._ready()"))
	assert(source.contains("debug_minimap_ritualant_ingress"))
	assert(SITE_SCRIPT != null)
	print("ritualant_debug_minimap_marker_smoke: PASS")
	quit(0)
