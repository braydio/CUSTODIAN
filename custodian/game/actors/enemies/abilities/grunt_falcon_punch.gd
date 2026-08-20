extends RefCounted
class_name GruntFalconPunch

## First extracted Falcon Punch authority seam. This module owns launch
## eligibility and ally-lane validation; Enemy remains the execution host while
## the remaining phase machinery is migrated behind this interface.


func should_start(host: Node2D, target: Node2D) -> bool:
	if host == null or target == null or not target.is_in_group("player"):
		return false
	if not bool(host.call("_should_use_grunt_falcon_punch_attack")):
		return false
	var distance := host.global_position.distance_to(target.global_position)
	if distance < float(host.get("grunt_falcon_punch_launch_band_min")) \
			or distance > float(host.get("grunt_falcon_punch_launch_band_max")):
		return false
	if float(host.get("_grunt_falcon_punch_cooldown_timer")) > 0.0 \
			or float(host.get("_grunt_falcon_punch_recent_parry_timer")) > 0.0:
		return false
	if int(host.get("_grunt_falcon_punch_normal_attacks_since_special")) \
			< maxi(0, int(host.get("grunt_falcon_punch_after_normal_attacks_min"))):
		return false
	var chance := clampf(float(host.get("grunt_falcon_punch_chance")), 0.0, 1.0)
	if chance <= 0.0 or float(host.get("_grunt_falcon_punch_decision_credit")) < 1.0:
		return false
	return not bool(host.get("grunt_falcon_punch_requires_clear_lane")) \
		or is_lane_clear(host, target)


func is_lane_clear(host: Node2D, target: Node2D) -> bool:
	var to_target := target.global_position - host.global_position
	var lane_length := maxf(
		0.0,
		to_target.length() - float(host.get("grunt_falcon_punch_stop_short_px"))
	)
	if lane_length <= 0.0:
		return false
	var lane_direction := to_target.normalized()
	for candidate in host.get_tree().get_nodes_in_group("enemy"):
		if candidate == host or not (candidate is Node2D):
			continue
		var other := candidate as Node2D
		if bool(host.call("_is_target_destroyed", other)):
			continue
		var offset := other.global_position - host.global_position
		var forward := offset.dot(lane_direction)
		if forward <= 0.0 or forward >= lane_length:
			continue
		if absf(offset.cross(lane_direction)) \
				< float(host.get("grunt_falcon_punch_ally_lane_radius_px")):
			return false
	return true
