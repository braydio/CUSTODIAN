extends "res://game/world/procgen/proc_gen_tilemap.gd"


func _ready() -> void:
	# Keep the inherited fixture's required layers while simulating an invalid
	# ProcGen owner dependency without running the production map's auto-discovery.
	procgen_node = null
