extends Node
class_name TwinSolariaPresentation

const Layout := preload("res://game/world/levels/authored/hub/twin_solaria/twin_solaria_layout.gd")


func build(underlay_root: Node2D, plate_root: Node2D) -> void:
	var underlay := Sprite2D.new()
	underlay.name = "FidelityUnderlay"
	underlay.centered = true
	underlay.texture = load(Layout.FIDELITY_UNDERLAY_PATH) as Texture2D
	underlay.z_index = -10
	underlay_root.add_child(underlay)
	if OS.is_debug_build() and underlay.texture != null \
			and Vector2i(underlay.texture.get_size()) != Layout.MASTER_SIZE:
		push_error("TwinSolariaPresentation: fidelity underlay dimensions drifted")

	for registration in Layout.PLATES:
		var plate := Sprite2D.new()
		plate.name = String(registration["node"])
		plate.centered = true
		plate.texture = load(String(registration["path"])) as Texture2D
		plate.position = registration["position"] as Vector2
		plate.scale = Vector2.ONE
		plate_root.add_child(plate)
		if OS.is_debug_build() and plate.texture != null \
				and Vector2i(plate.texture.get_size()) != registration["size"]:
			push_error("TwinSolariaPresentation: %s dimensions drifted" % plate.name)
