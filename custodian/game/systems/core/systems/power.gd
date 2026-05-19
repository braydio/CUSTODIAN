extends Node

@export var total_power: float = 500.0
@export var max_power: float = 500.0
@export var emergency_repair_power_cost: float = 25.0
@export var emergency_repair_base_amount: float = 50.0
@export_range(0.1, 1.0, 0.05) var emergency_repair_min_fabrication_scale: float = 0.35

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
	_distribute_power()
	_drain_power(delta)


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
	var drain_rate := 0.0
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		if not bool(sector.powered):
			continue
		# Power nodes generate; they do not consume grid budget.
		if String(sector.sector_type) == "POWER":
			continue
		drain_rate += float(sector.power)

	power_consumption = drain_rate
	total_power = max(0.0, total_power - drain_rate * delta)


func _distribute_power() -> void:
	var available := total_power
	for sector in sectors:
		if not is_instance_valid(sector):
			continue

		if String(sector.sector_type) == "POWER":
			# Power nodes stay online unless destroyed.
			if sector.has_method("is_dead") and bool(sector.is_dead()):
				sector.apply_power_allocation(0.0)
			else:
				sector.apply_power_allocation(float(sector.standard_power_required))
			continue

	var consumers: Array = []
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		if String(sector.sector_type) == "POWER":
			continue
		if not bool(sector.powered):
			sector.apply_power_allocation(0.0)
			continue
		consumers.append(sector)

	consumers.sort_custom(func(a, b) -> bool:
		var a_priority := int(a.get_power_priority()) if a.has_method("get_power_priority") else 0
		var b_priority := int(b.get_power_priority()) if b.has_method("get_power_priority") else 0
		return a_priority > b_priority
	)

	for sector in consumers:
		var min_required := float(sector.min_power_required)
		if available >= min_required:
			sector.apply_power_allocation(min_required)
			available -= min_required
		else:
			sector.apply_power_allocation(0.0)

	for sector in consumers:
		if available <= 0.0:
			break
		if String(sector.power_tier) == "OFFLINE":
			continue
		var current_allocation := float(sector.power)
		var standard_required := float(sector.standard_power_required)
		var additional_required: float = max(0.0, standard_required - current_allocation)
		if additional_required <= 0.0:
			continue
		var granted: float = min(additional_required, available)
		sector.apply_power_allocation(current_allocation + granted)
		available -= granted

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


func set_sector_priority(sector_name: String, priority: int) -> bool:
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		if String(sector.sector_name).to_upper() != sector_name.to_upper():
			continue
		sector.power_priority = priority
		sector.apply_power_allocation(float(sector.power))
		return true
	return false


func get_emergency_repair_profile(sector_name: String) -> Dictionary:
	var sector = _find_sector_by_name(sector_name)
	if sector == null:
		return {"available": false, "reason": "UNKNOWN_SECTOR"}
	if sector.has_method("is_dead") and bool(sector.is_dead()):
		return {"available": false, "reason": "DESTROYED"}
	var current_health := float(sector.get("current_health")) if "current_health" in sector else 0.0
	var max_health_value := float(sector.get("max_health")) if "max_health" in sector else 0.0
	if max_health_value > 0.0 and current_health >= max_health_value:
		return {"available": false, "reason": "FULL_HEALTH"}
	var fabrication_output := _get_fabrication_effectiveness()
	var repair_scale := lerpf(emergency_repair_min_fabrication_scale, 1.0, fabrication_output)
	var repair_amount := emergency_repair_base_amount * repair_scale
	var effective_power_cost := emergency_repair_power_cost
	var arrn_manager := get_node_or_null("/root/ARRNManager")
	if arrn_manager != null and arrn_manager.has_method("get_repair_power_cost"):
		effective_power_cost = float(arrn_manager.call("get_repair_power_cost", emergency_repair_power_cost))
	return {
		"available": total_power >= effective_power_cost,
		"reason": "INSUFFICIENT_POWER" if total_power < effective_power_cost else "OK",
		"power_cost": effective_power_cost,
		"repair_amount": repair_amount,
		"fabrication_effectiveness": fabrication_output,
		"repair_scale": repair_scale,
	}


func apply_emergency_repair(sector_name: String) -> Dictionary:
	var profile := get_emergency_repair_profile(sector_name)
	if not bool(profile.get("available", false)):
		return profile
	var sector = _find_sector_by_name(sector_name)
	if sector == null:
		return {"available": false, "reason": "UNKNOWN_SECTOR"}
	total_power = max(0.0, total_power - float(profile.get("power_cost", emergency_repair_power_cost)))
	var repair_amount := float(profile.get("repair_amount", emergency_repair_base_amount))
	sector.heal(repair_amount)
	profile["available"] = true
	profile["reason"] = "APPLIED"
	profile["sector"] = String(sector.get("sector_name") if "sector_name" in sector else sector.name)
	return profile


func get_sector_power_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		snapshot.append({
			"name": String(sector.sector_name),
			"type": String(sector.sector_type),
			"priority": int(sector.power_priority),
			"powered": bool(sector.powered),
			"tier": String(sector.power_tier),
			"allocated": float(sector.power),
			"min_required": float(sector.min_power_required),
			"standard_required": float(sector.standard_power_required),
			"effective_output": float(sector.effective_output),
		})
	snapshot.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority := int(a.get("priority", 0))
		var b_priority := int(b.get("priority", 0))
		if a_priority == b_priority:
			return String(a.get("name", "")) < String(b.get("name", ""))
		return a_priority > b_priority
	)
	return snapshot


func _find_sector_by_name(sector_name: String) -> Node:
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		if String(sector.sector_name).to_upper() == sector_name.to_upper():
			return sector
	return null


func _get_fabrication_effectiveness() -> float:
	var best_output := -1.0
	for sector in sectors:
		if not is_instance_valid(sector):
			continue
		if String(sector.sector_type) != "FABRICATION":
			continue
		var output := float(sector.get_effective_output()) if sector.has_method("get_effective_output") else 0.0
		best_output = max(best_output, output)
	if best_output < 0.0:
		return 1.0
	return clamp(best_output, 0.0, 1.0)


func get_power_status() -> Dictionary:
	var net_rate := power_generation - power_consumption
	return {
		"total": total_power,
		"max": max_power,
		"consumed": power_consumption,
		"generated": power_generation,
		"net": net_rate,
		"available": total_power,
		"sectors": sectors.size(),
		"sector_status": get_sector_power_snapshot(),
	}
