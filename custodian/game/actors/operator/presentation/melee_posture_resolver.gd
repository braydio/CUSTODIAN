class_name MeleePostureResolver
extends RefCounted

enum Posture { SHEATHED, READY, RELAXED }

const DEFAULT_DRAW_GRACE_SEC := 3.0

var posture: Posture = Posture.SHEATHED
var draw_grace_remaining := 0.0


func begin_draw_grace(duration_sec: float = DEFAULT_DRAW_GRACE_SEC) -> void:
	draw_grace_remaining = maxf(draw_grace_remaining, maxf(0.0, duration_sec))
	posture = Posture.READY


func mark_sheathed() -> void:
	posture = Posture.SHEATHED
	draw_grace_remaining = 0.0


func resolve(delta: float, melee_equipped: bool, engagement_active: bool, presentation_locked: bool) -> Posture:
	draw_grace_remaining = maxf(0.0, draw_grace_remaining - maxf(0.0, delta))
	if not melee_equipped:
		posture = Posture.SHEATHED
		return posture
	if presentation_locked:
		return posture
	posture = Posture.READY if engagement_active or draw_grace_remaining > 0.0 else Posture.RELAXED
	return posture


func get_animation_action() -> StringName:
	return &"idle_ready_01" if posture == Posture.READY else &"idle_relaxed_01"


func attack_action_bypasses_ready_up() -> bool:
	return true
