extends Enemy

@onready var shrumb_dropper: Node = get_node_or_null("ShrumbDropper")


func _ready() -> void:
	super._ready()
	add_to_group("drone_command_target")


func die() -> void:
	if dead:
		return
	if shrumb_dropper != null and shrumb_dropper.has_method("spawn_drop"):
		shrumb_dropper.call("spawn_drop", global_position, get_parent())
	super.die()
