extends Sector
class_name CommandPost

signal game_over(reason: String)


func _ready() -> void:
	super._ready()
	if not is_in_group("command_post"):
		add_to_group("command_post")
	# Command Post is the most important - give it 5x health
	max_health = 500.0
	current_health = max_health


func _on_destroyed() -> void:
	var reason := "Command Post destroyed"
	game_over.emit(reason)
	print("[GAME OVER] ", reason)

	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("trigger_game_over"):
		gs.trigger_game_over(reason)

	var tree = get_tree()
	if tree:
		tree.paused = true

	super._on_destroyed()
