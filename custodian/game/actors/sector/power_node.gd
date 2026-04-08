extends Sector
class_name PowerNode

@export var node_name: String = "Power Node"
@export var power_output: float = 120.0

const EFFICIENCY_BY_STATE := {
	"operational": 1.0,
	"damaged": 0.6,
	"critical": 0.3,
	"destroyed": 0.0,
}


func _ready() -> void:
	super._ready()
	if not is_in_group("power_node"):
		add_to_group("power_node")


func get_power_output() -> float:
	if is_dead():
		return 0.0
	var health_pct: float = get_efficiency()
	var output_ratio: float = clamp(0.2 + health_pct * 0.8, 0.0, 1.0)
	return power_output * output_ratio


func _on_state_changed(new_state: String) -> void:
	super._on_state_changed(new_state)
	match new_state:
		"operational":
			print("[PowerNode] ", node_name, " operational - 100% output")
		"damaged":
			print("[PowerNode] ", node_name, " damaged - 60% output")
		"critical":
			print("[PowerNode] ", node_name, " critical - 30% output")
		"destroyed":
			print("[PowerNode] ", node_name, " destroyed - offline")


func _on_destroyed() -> void:
	super._on_destroyed()
	var power_system = get_node_or_null("/root/GameRoot/Power")
	if power_system and power_system.has_method("on_power_node_destroyed"):
		power_system.on_power_node_destroyed(self)
