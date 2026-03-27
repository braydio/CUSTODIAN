extends Node

@export var total_power: float = 500.0
@export var max_power: float = 500.0

var power_consumption: float = 0.0
var power_generation: float = 0.0

var _low_power_warned: bool = false
var _power_critical_warned: bool = false

var sectors: Array = []


func _ready() -> void:
	var world = get_node_or_null("/root/GameRoot/World")
	if world:
		sectors = world.find_children("*", "Sector")
	print("Power system found ", sectors.size(), " sectors")


func _process(delta: float) -> void:
	_refresh_sectors_if_needed()
	_generate_power(delta)
	_drain_power(delta)
	_distribute_power()


func _refresh_sectors_if_needed() -> void:
	var needs_refresh := false
	for sector in sectors:
		if not is_instance_valid(sector):
			needs_refresh = true
			break
	if needs_refresh:
		var world = get_node_or_null("/root/GameRoot/World")
		if world:
			sectors = world.find_children("*", "Sector")


func _generate_power(delta: float) -> void:
	var generation_rate := get_total_power_output_rate()
	power_generation = generation_rate * delta
	total_power = min(max_power, total_power + power_generation)


func _drain_power(delta: float) -> void:
	var drain := 0.0
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		if not bool(sector.powered):
			continue
		# Power nodes generate; they do not consume grid budget.
		if String(sector.sector_type) == "POWER":
			continue
		drain += float(sector.power_cost) * delta

	total_power = max(0.0, total_power - drain)
	power_consumption = drain


func _distribute_power() -> void:
	var available = total_power
	for sector in sectors:
		if not is_instance_valid(sector):
			continue

		if String(sector.sector_type) == "POWER":
			# Power nodes stay online unless destroyed.
			if sector.has_method("is_dead") and bool(sector.is_dead()):
				sector.set_power(0.0)
			else:
				sector.set_power(float(sector.max_power))
			continue

		if available >= float(sector.power_cost):
			sector.set_power(float(sector.max_power))
			available -= float(sector.power_cost)
		else:
			var ratio = available / float(sector.power_cost) if float(sector.power_cost) > 0.0 else 0.0
			sector.set_power(float(sector.max_power) * ratio)
			available = 0.0

	if total_power < 50.0 and not _low_power_warned:
		print("WARNING: Low power! ", total_power, " remaining")
		_low_power_warned = true
	elif total_power >= 50.0:
		_low_power_warned = false

	if total_power < 10.0 and not _power_critical_warned:
		print("CRITICAL: Power nearly depleted! ", total_power, " remaining")
		_power_critical_warned = true
	elif total_power >= 10.0:
		_power_critical_warned = false


func get_total_power_output_rate() -> float:
	var total := 0.0
	for node in get_tree().get_nodes_in_group("power_node"):
		if not is_instance_valid(node):
			continue
		if node.has_method("get_power_output"):
			total += float(node.get_power_output())
	return total


func on_power_node_destroyed(node: Node) -> void:
	print("[Power] Node destroyed: ", node.name)
	_refresh_sectors_if_needed()


func toggle_sector_power(sector_name: String) -> bool:
	for sector in sectors:
		if is_instance_valid(sector) and String(sector.sector_name) == sector_name:
			sector.toggle_power()
			return true
	return false


func get_power_status() -> Dictionary:
	return {
		"total": total_power,
		"max": max_power,
		"consumed": power_consumption,
		"generated": power_generation,
		"available": total_power,
		"sectors": sectors.size(),
	}
