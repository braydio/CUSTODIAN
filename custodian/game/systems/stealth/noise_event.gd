class_name NoiseEvent
extends RefCounted

var source: Node2D = null
var source_team: StringName = &"neutral"
var position: Vector2 = Vector2.ZERO
var radius_px: float = 0.0
var loudness: float = 1.0
var threat_value: float = 1.0
var kind: StringName = &"generic"
var timestamp_msec: int = 0
var suppressed: bool = false


static func create(
	noise_source: Node2D,
	noise_position: Vector2,
	noise_radius_px: float,
	noise_kind: StringName = &"generic",
	noise_threat: float = 1.0,
	noise_loudness: float = 1.0,
	is_suppressed: bool = false,
	team: StringName = &"neutral"
) -> RefCounted:
	var event: RefCounted = load("res://game/systems/stealth/noise_event.gd").new()
	event.source = noise_source
	event.position = noise_position
	event.radius_px = maxf(0.0, noise_radius_px)
	event.kind = noise_kind
	event.threat_value = maxf(0.0, noise_threat)
	event.loudness = maxf(0.0, noise_loudness)
	event.suppressed = is_suppressed
	event.source_team = team
	return event
