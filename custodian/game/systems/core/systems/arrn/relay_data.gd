extends Resource
class_name ARRNRelayData

enum Status { UNKNOWN, LOCATED, UNSTABLE, STABLE, WEAK, DORMANT }
enum RiskProfile { TRANSIT, FRINGE, CORE }

@export var relay_id: StringName = &""
@export var sector_id: StringName = &""
@export var status: Status = Status.UNKNOWN
@export var stability: float = 40.0
@export var stability_ticks_required: int = 3
@export var risk_profile: RiskProfile = RiskProfile.TRANSIT
@export var last_stabilized_time: int = -1
@export var is_interactable: bool = false
@export var current_signal_strength: float = 0.0
@export var world_position: Vector2 = Vector2.ZERO


func configure(
	relay_id_value: StringName,
	sector_id_value: StringName,
	status_value: int,
	stability_value: float,
	risk_profile_value: int,
	ticks_required_value: int
) -> void:
	relay_id = relay_id_value
	sector_id = sector_id_value
	status = status_value
	stability = clampf(stability_value, 0.0, 100.0)
	risk_profile = risk_profile_value
	stability_ticks_required = maxi(1, ticks_required_value)
	current_signal_strength = stability / 100.0


func to_snapshot(scanned: bool) -> Dictionary:
	var visible := scanned or status != Status.UNKNOWN
	return {
		"relay_id": String(relay_id),
		"sector_id": String(sector_id),
		"status": status_to_string(status) if visible else "UNKNOWN",
		"raw_status": status_to_string(status),
		"stability": stability,
		"stability_ticks_required": stability_ticks_required,
		"risk_profile": risk_to_string(risk_profile),
		"last_stabilized_time": last_stabilized_time,
		"is_interactable": is_interactable,
		"current_signal_strength": current_signal_strength,
		"world_position": world_position,
		"visible": visible,
	}


static func status_to_string(value: int) -> String:
	match value:
		Status.UNKNOWN:
			return "UNKNOWN"
		Status.LOCATED:
			return "LOCATED"
		Status.UNSTABLE:
			return "UNSTABLE"
		Status.STABLE:
			return "STABLE"
		Status.WEAK:
			return "WEAK"
		Status.DORMANT:
			return "DORMANT"
		_:
			return "UNKNOWN"


static func risk_to_string(value: int) -> String:
	match value:
		RiskProfile.TRANSIT:
			return "TRANSIT"
		RiskProfile.FRINGE:
			return "FRINGE"
		RiskProfile.CORE:
			return "CORE"
		_:
			return "TRANSIT"
