extends RefCounted
class_name SunderedKeepFrontageVisualSpawner

const PRESENTATION_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_procgen_vista_presentation.tscn"
)


func spawn(
	parent: Node2D,
	ingress: Node,
	map_instance: Node,
	level_data: Dictionary
) -> Node2D:
	if parent == null:
		return null
	var presentation := PRESENTATION_SCENE.instantiate() as Node2D
	if presentation == null:
		return null
	presentation.name = "SunderedKeepProcgenFrontagePresentation"
	presentation.add_to_group("generated_sundered_keep_world_vista")
	presentation.add_to_group("generated_sundered_keep_procgen_frontage")
	parent.add_child(presentation)
	if presentation.has_method("configure"):
		presentation.call(
			"configure",
			ingress,
			map_instance,
			level_data
		)
	return presentation
