extends Node
class_name NoiseEventBusSystem

const NoiseEventData = preload("res://game/systems/stealth/noise_event.gd")

signal noise_emitted(event: NoiseEvent)

@export var debug_noise_events: bool = false


func emit_noise(event: NoiseEvent) -> void:
	if event == null or event.radius_px <= 0.0:
		return
	event.timestamp_msec = Time.get_ticks_msec()
	if debug_noise_events:
		print("[NoiseEvent] %s radius=%.1f threat=%.2f at=%s" % [String(event.kind), event.radius_px, event.threat_value, event.position])
	noise_emitted.emit(event)


func emit_at(
	source: Node2D,
	position: Vector2,
	radius_px: float,
	kind: StringName = &"generic",
	threat_value: float = 1.0,
	loudness: float = 1.0,
	suppressed: bool = false,
	team: StringName = &"neutral"
) -> NoiseEvent:
	var event: NoiseEvent = NoiseEventData.create(source, position, radius_px, kind, threat_value, loudness, suppressed, team)
	emit_noise(event)
	return event
