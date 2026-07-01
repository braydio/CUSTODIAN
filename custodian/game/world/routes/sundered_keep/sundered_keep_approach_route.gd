extends LevelRoute
class_name SunderedKeepApproachRoute

const VISTA_ONE := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_vista_one.tscn")
const PRE_LEVEL := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_pre_level.tscn")
const GRAND_VISTA := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_grand_vista.tscn")
const CAUSEWAY := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_causeway_approach.tscn")
const FRONT_GATE := preload("res://game/world/sundered_keep/sundered_keep_map.tscn")


func _ready() -> void:
	initial_stage_id = &"vista_one"
	final_target_scene = FRONT_GATE

	super._ready()

	register_stage(&"vista_one", VISTA_ONE)
	register_stage(&"pre_level", PRE_LEVEL)
	register_stage(&"grand_vista", GRAND_VISTA)
	register_stage(&"causeway_approach", CAUSEWAY)
