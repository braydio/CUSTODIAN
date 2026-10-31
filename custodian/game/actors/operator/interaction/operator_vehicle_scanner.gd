class_name OperatorVehicleScanner
extends RefCounted
## Turns one sampled service-intent edge into a deterministic nearby vehicle scan.

signal scan_completed(result: Dictionary)

const SCAN_RANGE_PX := 64.0


func scan_nearest(operator: Node2D, input_frame: OperatorInputFrame, knowledge: Node) -> Dictionary:
	if operator == null or not is_instance_valid(operator):
		return _reject("INVALID_OPERATOR")
	if input_frame == null or not input_frame.just_pressed(&"repair"):
		return _reject("NO_SERVICE_PRESS")
	var target := _find_nearest_scannable(operator)
	if target == null:
		return _reject("NO_SCANNABLE_VEHICLE_IN_RANGE")
	if not target.has_method("get_vehicle_scan_snapshot"):
		return _reject("MISSING_SCAN_SNAPSHOT")
	var snapshot: Dictionary = target.call("get_vehicle_scan_snapshot")
	if not bool(snapshot.get("scannable", false)):
		return _reject("VEHICLE_UNAVAILABLE")
	if knowledge == null or not knowledge.has_method("record_vehicle_scan"):
		return _reject("KNOWLEDGE_AUTHORITY_UNAVAILABLE")
	var result: Dictionary = knowledge.call("record_vehicle_scan", snapshot)
	result["vehicle_name"] = String(snapshot.get("display_name", "Vehicle"))
	result["vehicle_id"] = String(snapshot.get("archetype_id", ""))
	result["condition"] = String(snapshot.get("condition", ""))
	scan_completed.emit(result.duplicate(true))
	return result


func _find_nearest_scannable(operator: Node2D) -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := SCAN_RANGE_PX + 0.001
	for candidate: Node in operator.get_tree().get_nodes_in_group("vehicle_scannable"):
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var node := candidate as Node2D
		if not node.has_method("get_vehicle_scan_snapshot"):
			continue
		var snapshot: Dictionary = node.call("get_vehicle_scan_snapshot")
		if not bool(snapshot.get("scannable", false)):
			continue
		var distance := operator.global_position.distance_to(node.global_position)
		if distance <= SCAN_RANGE_PX and distance < nearest_distance:
			nearest = node
			nearest_distance = distance
	return nearest


func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "learned_any": false}
