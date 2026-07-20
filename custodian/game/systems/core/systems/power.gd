extends Node

@export var total_power: float = 500.0
@export var max_power: float = 500.0
@export var base_charge_rate: float = 250.0
@export var base_discharge_rate: float = 250.0
@export var emergency_repair_power_cost: float = 25.0
@export var emergency_repair_base_amount: float = 50.0
@export_range(0.1, 1.0, 0.05) var emergency_repair_min_fabrication_scale: float = 0.35

var power_consumption_rate: float = 0.0
var power_generation_rate: float = 0.0
var power_requested_rate: float = 0.0
var power_allocated_rate: float = 0.0

var _low_power_warned: bool = false
var _power_critical_warned: bool = false

var sectors: Array = []
var _registered_consumers: Array[Node] = []
var _registered_generators: Array[Node] = []
var _registered_storage: Array[Node] = []
var _base_storage_capacity: float = 500.0
var _effective_charge_rate: float = 250.0
var _effective_discharge_rate: float = 250.0
var _grid_refresh_requested: bool = true


func _ready() -> void:
	add_to_group("power_grid")
	_base_storage_capacity = maxf(0.0, max_power)
	_effective_charge_rate = maxf(0.0, base_charge_rate)
	_effective_discharge_rate = maxf(0.0, base_discharge_rate)
	var world = get_node_or_null("/root/GameRoot/World")
	if world:
		sectors = world.find_children("*", "Sector")
	print("Power system found ", sectors.size(), " sectors")


func _process(delta: float) -> void:
	_refresh_sectors_if_needed()
	_prune_registered_components()
	_recalculate_storage_profile()
	_generate_power(delta)
	_distribute_power(delta)
	_drain_power(delta)
	_grid_refresh_requested = false
	_update_grid_observability()


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
	power_generation_rate = get_total_power_output_rate()
	var accepted_rate := minf(power_generation_rate, _effective_charge_rate)
	total_power = min(max_power, total_power + accepted_rate * delta)


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
	for consumer in _registered_consumers:
		if not is_instance_valid(consumer):
			continue
		if consumer.has_method("is_power_consumer_enabled") \
		and not bool(consumer.call("is_power_consumer_enabled")):
			continue
		drain_rate += float(consumer.get("allocated_power"))

	power_consumption_rate = drain_rate
	power_allocated_rate = drain_rate
	total_power = max(0.0, total_power - power_consumption_rate * delta)


func _distribute_power(delta: float = 1.0 / 60.0) -> void:
	var reserve_supply_rate := minf(_effective_discharge_rate, total_power / maxf(delta, 0.0001))
	var available := power_generation_rate + reserve_supply_rate
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
	for consumer in _registered_consumers:
		if not is_instance_valid(consumer):
			continue
		if consumer.has_method("is_power_consumer_enabled") \
		and not bool(consumer.call("is_power_consumer_enabled")):
			consumer.call("apply_power_allocation", 0.0)
			continue
		consumers.append(consumer)

	consumers.sort_custom(func(a, b) -> bool:
		var a_priority := _get_consumer_priority(a)
		var b_priority := _get_consumer_priority(b)
		if a_priority == b_priority:
			return _get_consumer_stable_id(a) < _get_consumer_stable_id(b)
		return a_priority > b_priority
	)

	power_requested_rate = 0.0
	for consumer in consumers:
		power_requested_rate += _get_consumer_standard_power(consumer)
		var min_required := _get_consumer_minimum_power(consumer)
		if available >= min_required:
			consumer.call("apply_power_allocation", min_required)
			available -= min_required
		else:
			consumer.call("apply_power_allocation", 0.0)

	for consumer in consumers:
		if available <= 0.0:
			break
		var current_allocation := _get_consumer_allocation(consumer)
		if current_allocation + 0.0001 < _get_consumer_minimum_power(consumer):
			continue
		var standard_required := _get_consumer_standard_power(consumer)
		var additional_required: float = max(0.0, standard_required - current_allocation)
		if additional_required <= 0.0:
			continue
		var granted: float = min(additional_required, available)
		consumer.call("apply_power_allocation", current_allocation + granted)
		available -= granted

	for consumer in consumers:
		if available <= 0.0:
			break
		var overdrive_required := _get_consumer_overdrive_power(consumer)
		if overdrive_required <= 0.0:
			continue
		var current_allocation := _get_consumer_allocation(consumer)
		if current_allocation + 0.0001 < _get_consumer_standard_power(consumer):
			continue
		var granted := minf(maxf(0.0, overdrive_required - current_allocation), available)
		consumer.call("apply_power_allocation", current_allocation + granted)
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
	for generator in _registered_generators:
		if is_instance_valid(generator) and generator.has_method("get_power_output_rate"):
			total += float(generator.call("get_power_output_rate"))
	return total


func register_consumer(consumer: Node) -> void:
	if consumer != null and not _registered_consumers.has(consumer):
		_registered_consumers.append(consumer)
		request_grid_refresh()


func unregister_consumer(consumer: Node) -> void:
	_registered_consumers.erase(consumer)
	request_grid_refresh()


func register_generator(generator: Node) -> void:
	if generator != null and not _registered_generators.has(generator):
		_registered_generators.append(generator)
		request_grid_refresh()


func unregister_generator(generator: Node) -> void:
	_registered_generators.erase(generator)
	request_grid_refresh()


func register_storage(storage: Node) -> void:
	if storage != null and not _registered_storage.has(storage):
		_registered_storage.append(storage)
		request_grid_refresh()


func unregister_storage(storage: Node) -> void:
	_registered_storage.erase(storage)
	request_grid_refresh()


func request_grid_refresh() -> void:
	_grid_refresh_requested = true
	_recalculate_storage_profile()


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
	var registry := get_node_or_null("/root/InfrastructureRegistry")
	if registry != null and registry.has_method("has_service") \
	and bool(registry.call("has_service", &"FABRICATION")):
		return clampf(float(registry.call("get_service_output", &"FABRICATION")), 0.0, 2.0)
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
	var net_rate := power_generation_rate - power_consumption_rate
	return {
		"total": total_power,
		"max": max_power,
		"stored_energy": total_power,
		"storage_capacity": max_power,
		"generated_per_second": power_generation_rate,
		"requested_per_second": power_requested_rate,
		"allocated_per_second": power_allocated_rate,
		"consumed_per_second": power_consumption_rate,
		"net_per_second": net_rate,
		"charge_rate_limit": _effective_charge_rate,
		"discharge_rate_limit": _effective_discharge_rate,
		"available": total_power,
		"sectors": sectors.size(),
		"sector_status": get_sector_power_snapshot(),
		"infrastructure_consumers": _get_registered_consumer_snapshot(),
	}


func capture_grid_state() -> Dictionary:
	return {
		"schema": "custodian.power_grid_state.v2",
		"stored_energy": total_power,
		"base_storage_capacity": _base_storage_capacity,
	}


func restore_grid_state(state: Dictionary) -> void:
	if str(state.get("schema", "")) != "custodian.power_grid_state.v2":
		return
	_base_storage_capacity = maxf(0.0, float(state.get("base_storage_capacity", _base_storage_capacity)))
	_recalculate_storage_profile()
	total_power = clampf(float(state.get("stored_energy", total_power)), 0.0, max_power)
	request_grid_refresh()


func _recalculate_storage_profile() -> void:
	var previous_capacity := max_power
	var capacity := _base_storage_capacity
	var charge_rate := maxf(0.0, base_charge_rate)
	var discharge_rate := maxf(0.0, base_discharge_rate)
	for storage in _registered_storage:
		if not is_instance_valid(storage) or not storage.has_method("get_storage_profile"):
			continue
		var profile: Dictionary = storage.call("get_storage_profile")
		capacity += maxf(0.0, float(profile.get("capacity", 0.0)))
		charge_rate += maxf(0.0, float(profile.get("charge_rate", 0.0)))
		discharge_rate += maxf(0.0, float(profile.get("discharge_rate", 0.0)))
	max_power = capacity
	_effective_charge_rate = charge_rate
	_effective_discharge_rate = discharge_rate
	if total_power > max_power:
		var lost := total_power - max_power
		total_power = max_power
		var observatory := get_node_or_null("/root/DevObservatory")
		if observatory != null and observatory.has_method("log_event"):
			observatory.call("log_event", &"grid_reserve_clamped_capacity_loss", {
				"lost_energy": lost,
				"previous_capacity": previous_capacity,
				"new_capacity": max_power,
			})


func _prune_registered_components() -> void:
	_registered_consumers = _registered_consumers.filter(func(node: Node) -> bool:
		return node != null and is_instance_valid(node)
	)
	_registered_generators = _registered_generators.filter(func(node: Node) -> bool:
		return node != null and is_instance_valid(node)
	)
	_registered_storage = _registered_storage.filter(func(node: Node) -> bool:
		return node != null and is_instance_valid(node)
	)


func _get_consumer_priority(consumer: Node) -> int:
	return int(consumer.call("get_power_priority")) if consumer.has_method("get_power_priority") else int(consumer.get("power_priority"))


func _get_consumer_stable_id(consumer: Node) -> String:
	if consumer.has_method("get_stable_power_id"):
		return str(consumer.call("get_stable_power_id"))
	if "sector_name" in consumer:
		return str(consumer.get("sector_name"))
	return str(consumer.get_path())


func _get_consumer_minimum_power(consumer: Node) -> float:
	return float(consumer.call("get_minimum_power")) if consumer.has_method("get_minimum_power") else float(consumer.get("min_power_required"))


func _get_consumer_standard_power(consumer: Node) -> float:
	return float(consumer.call("get_standard_power")) if consumer.has_method("get_standard_power") else float(consumer.get("standard_power_required"))


func _get_consumer_overdrive_power(consumer: Node) -> float:
	return float(consumer.call("get_overdrive_power")) if consumer.has_method("get_overdrive_power") else 0.0


func _get_consumer_allocation(consumer: Node) -> float:
	return float(consumer.get("allocated_power")) if "allocated_power" in consumer else float(consumer.get("power"))


func _get_registered_consumer_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for consumer in _registered_consumers:
		if is_instance_valid(consumer) and consumer.has_method("get_power_snapshot"):
			snapshot.append(consumer.call("get_power_snapshot"))
	snapshot.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return snapshot


func _update_grid_observability() -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null or not observatory.has_method("set_gauge"):
		return
	observatory.call("set_gauge", &"grid_generation_rate", power_generation_rate)
	observatory.call("set_gauge", &"grid_requested_rate", power_requested_rate)
	observatory.call("set_gauge", &"grid_allocated_rate", power_allocated_rate)
	observatory.call("set_gauge", &"grid_net_rate", power_generation_rate - power_allocated_rate)
	observatory.call("set_gauge", &"grid_stored_energy", total_power)
	observatory.call("set_gauge", &"grid_storage_capacity", max_power)
	var offline := 0
	var degraded := 0
	for entry in _get_registered_consumer_snapshot():
		match String(entry.get("tier", "")):
			"offline":
				offline += 1
			"degraded":
				degraded += 1
	observatory.call("set_gauge", &"grid_offline_consumer_count", offline)
	observatory.call("set_gauge", &"grid_degraded_consumer_count", degraded)
