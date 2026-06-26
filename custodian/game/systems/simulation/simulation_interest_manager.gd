extends Node

@export var active_radius: float = 900.0
@export var nearby_radius: float = 1600.0
@export var background_radius: float = 3000.0

var player: Node2D = null


func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return

	var counts := {
		"active": 0,
		"nearby": 0,
		"background": 0,
		"dormant": 0,
	}

	for node in get_tree().get_nodes_in_group("interest_managed"):
		if not (node is Node2D):
			continue

		var distance := player.global_position.distance_to((node as Node2D).global_position)
		var tier := "dormant"
		if distance <= active_radius:
			tier = "active"
		elif distance <= nearby_radius:
			tier = "nearby"
		elif distance <= background_radius:
			tier = "background"

		counts[tier] = int(counts.get(tier, 0)) + 1
		if node.has_method("set_simulation_tier"):
			node.call("set_simulation_tier", tier)

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		for key in counts.keys():
			observatory.call("set_gauge", "interest_%s" % key, counts[key])
