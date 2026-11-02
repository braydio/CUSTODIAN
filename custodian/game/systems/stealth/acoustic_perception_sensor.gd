class_name AcousticPerceptionSensor
extends RefCounted

static func evaluate_noise(
	event: NoiseEvent,
	receiver_position: Vector2,
	receiver: Node2D = null
) -> PerceptionObservation:
	if event == null or event.radius_px <= 0.0:
		return null
	if receiver != null and event.source == receiver:
		return null
	var distance := receiver_position.distance_to(event.position)
	if distance > event.radius_px:
		return null
	var distance_strength := clampf(1.0 - distance / event.radius_px, 0.0, 1.0)
	var observation := PerceptionObservation.new()
	observation.channel = PerceptionObservation.Channel.ACOUSTIC
	observation.stimulus_kind = event.kind
	observation.observed_position = event.position
	observation.source = event.source if is_instance_valid(event.source) else null
	observation.source_team = event.source_team
	observation.salience = maxf(0.05, event.threat_value * distance_strength)
	observation.certainty = distance_strength
	observation.radius_px = event.radius_px
	observation.loudness = event.loudness
	observation.threat_value = event.threat_value
	observation.suppressed = event.suppressed
	observation.event_timestamp_msec = event.timestamp_msec
	return observation
