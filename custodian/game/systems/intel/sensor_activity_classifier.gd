extends RefCounted
class_name SensorActivityClassifier


static func classify(behavior_state: String, objective_type: String = "", carrying_loot: bool = false) -> StringName:
	var state := behavior_state.strip_edges().to_lower()
	var objective := objective_type.strip_edges().to_lower()
	if carrying_loot or state == "escape_with_loot":
		return &"EXFILTRATING"
	match state:
		"idle": return &"IDLE"
		"ambient_activity": return &"LOITERING"
		"patrol", "return_home", "seek_objective", "open_storage": return &"MOVING THROUGH"
		"investigate", "notice", "search": return &"SEARCHING"
		"engage_operator": return &"ENGAGING"
		"steal_resources": return &"STEALING"
		"sabotage_storage": return &"VANDALIZING"
		"flee": return &"WITHDRAWING"
		"stunned": return &"DISRUPTED"
	if objective.contains("sabotage"):
		return &"VANDALIZING"
	if objective.contains("storage"):
		return &"MOVING THROUGH"
	return &"IDLE"
