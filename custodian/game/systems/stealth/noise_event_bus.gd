extends Node
class_name NoiseEventBusSystem

const NoiseEventData = preload("res://game/systems/stealth/noise_event.gd")

signal noise_emitted(event: Variant)

@export var debug_noise_events: bool = false


func emit_noise(event: Variant) -> void:
	if event == null or float(event.get("radius_px")) <= 0.0:
		return
	event.set("timestamp_msec", Time.get_ticks_msec())
	if debug_noise_events:
		print("[NoiseEvent] %s radius=%.1f threat=%.2f at=%s" % [String(event.get("kind")), float(event.get("radius_px")), float(event.get("threat_value")), event.get("position")])
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
) -> Variant:
	var event: Variant = NoiseEventData.create(source, position, radius_px, kind, threat_value, loudness, suppressed, team)
	emit_noise(event)
	return event
