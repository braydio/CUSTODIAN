extends Node

@export var active_radius: float = 900.0
@export var nearby_radius: float = 1600.0
@export var background_radius: float = 3000.0
@export_range(0.05, 1.0, 0.05) var update_interval_sec: float = 0.20

var player: Node2D = null
var _update_accum := 0.0
var _has_classified := false


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return
	_update_accum += maxf(0.0, delta)
	if _has_classified and _update_accum < update_interval_sec:
		return
	_update_accum = 0.0
	_has_classified = true

	var counts := {
		"active": 0,
		"nearby": 0,
		"background": 0,
		"dormant": 0,
	}

	var active_sq := active_radius * active_radius
	var nearby_sq := nearby_radius * nearby_radius
	var background_sq := background_radius * background_radius
	for node in get_tree().get_nodes_in_group("interest_managed"):
		if not (node is Node2D):
			continue

		var distance_sq := player.global_position.distance_squared_to((node as Node2D).global_position)
		var tier := "dormant"
		if distance_sq <= active_sq:
			tier = "active"
		elif distance_sq <= nearby_sq:
			tier = "nearby"
		elif distance_sq <= background_sq:
			tier = "background"

		counts[tier] = int(counts.get(tier, 0)) + 1
		if node.has_method("set_simulation_tier"):
			node.call("set_simulation_tier", tier)

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		for key in counts.keys():
			observatory.call("set_gauge", "interest_%s" % key, counts[key])
